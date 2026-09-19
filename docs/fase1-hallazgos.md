# Fase 1 — Hallazgos: ecuación de calor 1D, simbólico → generado → numérico → verificado

Fecha: 2026-09-18. Todo lo que sigue se reproduce con `py -3.14 bend-spike/heat/run.py` (los números salen de `heat/results.json`). Entorno: Bend 2.0.6 vía bun en Windows, JAX 0.11.2 float64 en Python 3.14 (ver `env/SETUP.md`).

## Qué se construyó (`bend-spike/heat/`)

| Archivo | Qué es | Líneas (código sin comentarios) |
|---|---|---|
| `ir.bend` | IR de expresiones (`Var/Const/Add/Mul`), semántica exacta `eval` sobre `Nat`, simplificador (plegado de constantes, `x+0`, `0+x`, `1·x`, `x·1`, `0·x`, `x·0`), esquema `r = p/2^q`, pesos, árbol del stencil, printers a IR y a Python/JAX | 155 |
| `LAWS.bend` | 4 leyes: `simplify_sound` (inducción), `weights_sum` y `weights_symmetric` (por cómputo), `linear_exact` (álgebra sobre `Nat` simbólico) | 14 |
| `PROOF.bend` | Las pruebas: 3 lemas de `Nat` + 10 lemas espejo de los helpers del simplificador + 4 lemas de suma para `linear_exact` | 167 |
| `emit.bend` | `main` que imprime a stdout el módulo Python/JAX con `step(u)` generado del árbol simplificado | 27 |
| `oracle.bend` | Plan A: el mismo `IR.eval` sobre el árbol **crudo**, numeradores `Nat` (< 2^48), entrada por variables de entorno | 58 |
| `big.bend` | Plan B: bignum propio (limbs base 2^16): `add`, `mul`, `mul_small`, `from_nat`, `dump` | 56 |
| `oracle_big.bend` | Plan B: `eval_big` (espejo de `IR.eval` sobre `Big`) y la misma iteración | 77 |
| `run.py` | Orquestador: gate de pruebas, emisión, JAX f64 y f32, oráculos, comparación, `results.json` | 154 |
| `tests/` | `smoke.bend`, `big_test.bend` + `run_big_test.py` (bignum vs `int` de Python), `sympy_equivalent.py` (la misma pipeline en Python sin pruebas, para comparar tamaño) | — |

Circuito: `run.py` corre `bend PROOF.bend` (gate), `bend emit.bend > kernel_heat.py`, importa el kernel y lo corre en JAX, corre `bend oracle.bend` y `bend oracle_big.bend` con la condición inicial en `BEND_IC` y los pasos en `BEND_N`, parsea los numeradores a `fractions.Fraction` y compara.

## Qué cerró

Los cinco puntos del enunciado, más el plan B:

1. **PDE + discretización como árbol, con transformación real.** `stencil(Scheme{1n, 2n})` produce el árbol crudo `Add(Mul(Const 1, Var 0), Add(Mul(Const 2, Var 1), Add(Mul(Const 1, Var 2), Const 0)))`; `simplify` lo deja en `Add(Var 0, Add(Mul(Const 2, Var 1), Var 2))`: dos multiplicaciones por 1 y una suma de 0 eliminadas. Para `r = 1/2` el peso central es 0 y el simplificador borra el término entero (`Add(Var 0, Var 2)`). No hay CSE: un stencil de 3 puntos no tiene subexpresiones comunes; no lo forcé.
2. **Emisión del kernel.** Ruta A (stdout). 19 líneas de Python con `@jax.jit def step(u)`, `inner = (u[:-2] + ((2.0 * u[1:-1]) + u[2:])) / D`, más el árbol crudo y el simplificado como comentario.
3. **Corrida en JAX float64.** 10 puntos, Dirichlet 0, condición inicial `sin(πx)` cuantizada a 2^-21 (exacta en float64, verificado con un `assert`), `r = 1/4`, `dx = 1/9`, `dt = r·dx²`. Se corrió también en float32 para contraste.
4. **Oráculo exacto.** Plan A: 13 pasos (el máximo con `Nat < 2^48`: los numeradores finales usan 47 bits). Plan B: 200 pasos con el bignum propio; numeradores de 413 bits; **coincide bit a bit con `Fraction` de Python** sobre el mismo esquema (`assert` en `run.py`).
5. **Comparación.** Ver tabla.
6. **Las cuatro leyes probadas**: `bend PROOF.bend` → `All terms check.` en 0.2 s.

### Números

| | Plan A, N = 13 (t = 0.040, amplitud 0.67) | Plan B, N = 200 (t = 0.617, amplitud 2.2e-3) |
|---|---|---|
| JAX f64 vs oráculo exacto, error abs máx | **0** (exacto) | 5.8e-19 |
| ídem, relativo a max\|u\| | 0 | 2.7e-16 (≈ 1.2 ε₆₄) |
| Cota trivial N·ε₆₄ | 2.9e-15 | 4.4e-14 |
| JAX f32 vs oráculo exacto, relativo | 1.2e-7 (≈ 1 ε₃₂) | 1.0e-7 (≈ 0.8 ε₃₂) |
| JAX f64 vs analítica `e^{-π²t} sin(πx)` | 1.34e-3 | 6.8e-5 (3% relativo) |
| Oráculo vs analítica | 1.34e-3 | 6.8e-5 |
| Oráculo vs forma cerrada del esquema discreto `g^N sin(πx_i)`, `g = 1 − 4r sin²(πdx/2)` | 3.7e-8 | 1.1e-10 |

Lectura:

- **El error float64 está donde dice la teoría, y un poco mejor.** El esquema es una combinación convexa (pesos no negativos que suman 1), no expansivo en norma máxima, así que el redondeo acumulado está acotado por N·ε·max\|u\|; lo observado es ~1 ulp en ambas precisiones, muy por debajo de la cota. En el plan A el error es **exactamente cero**: con 47 bits de numerador todo entra en la mantisa de 53 de float64 y ninguna operación redondea. Lo anticipé en la Fase 0 ("si sale 0 exacto, es porque los diádicos chicos son exactos en f64"), y es la razón de fondo por la que el plan A no alcanza para medir redondeo: para verlo hacen falta más de 53 bits, o sea más pasos de los que `Nat` permite.
- **La diferencia contra la analítica es discretización, no redondeo.** JAX y el oráculo dan el mismo número contra la analítica hasta el último dígito reportado. En N = 13 la Fase 0 predijo ~1e-3 (dominado por O(dx²) con dx = 1/9): salió 1.34e-3. En N = 200 el 3% relativo es el error en la tasa de decaimiento del modo `sin(πx)` acumulado durante 6 tiempos característicos. El oráculo coincide con la forma cerrada del esquema discreto hasta el nivel de cuantización de la condición inicial (2^-22 ≈ 2.4e-7, atenuado por el decaimiento): el oráculo calcula exactamente lo que el esquema dice, y el esquema difiere de la PDE lo que la teoría dice.
- **El oráculo de Bend vale como oráculo**: coincide con `Fraction` en 200 pasos. Pero ese chequeo lo hizo Python; la corrección del bignum está **testeada, no probada**.

## Qué no cerró o cerró distinto

- **"Racionales sobre `Nat` ilimitado"**: no existe. Plan A tapa hasta 13 pasos (47 bits). Plan B necesitó 56 líneas de bignum sin pruebas. Probar `to_nat(add(a,b)) == add(to_nat a, to_nat b)` con acarreo en base 2^16 es un proyecto aparte (`Nat.divmod` con divisor 65536 es opaco salvo por cómputo: la prueba sería sobre `Nat.div`/`Nat.mod` simbólicos, nivel "hard" del cookbook). No lo intenté.
- **Racionales con signo**: evitados por diseño (`r ≤ 1/2` da pesos no negativos). Cualquier esquema con pesos negativos (upwind de orden alto, Runge-Kutta con coeficientes negativos, Laplaciano como tal) rompe la semántica en `Nat` y obliga a un tipo `Z` propio con su álgebra y sus lemas. Es el límite real del enfoque, no los 48 bits.
- **F32 no participa de nada**: las leyes hablan de la semántica exacta; sobre el float generado no se prueba ni se puede probar nada en Bend. La conexión kernel ↔ oráculo es "mismo árbol, semántica exacta probada igual"; el paso de esa semántica a float64 lo garantiza la cuantización diádica y el test, no el checker.

## Dónde dolió (cada punto costó al menos una vuelta del checker)

1. **Destructurar un valor calculado está prohibido**: `(d, m) = Nat.divmod(x, b)` falla con "a match cannot scrutinize a computed value". La salida oficial (pasar el par a un helper que lo destructure) crea recursión mutua con el bignum, también prohibida. Solución: `Nat.div` y `Nat.mod` por separado sobre un `+t` compartido. Mismo problema en el `do` de IO: `(f, r) : File & Result <- File.write(...)` no parsea; hay que ligar a un nombre y pasarlo a un helper.
2. **Afinidad**: `k` usado en `Var{k}` y en `1n+k` → `+k`; la ruta leída de `IO.get_env` usada dos veces (abrir e imprimir) → error; `+s`, `+e`, `+simp` en el emisor. Cada uno es trivial de arreglar y el mensaje es claro (`consumed more than once`), pero no se ve venir sin el checker.
3. **Casi nada se infiere**: lets dentro de `do` necesitan `x : T = v`; `List.show` exige `~&2, ~Nat, ~Nat.show` (tres templates, todos con `~`); literales grandes de `Nat` se expanden en unario en el parser, así que la base del bignum es `U32.to_nat(65536)`.
4. **Recursión sobre dos listas** (suma con acarreo): la primera que decrece tiene que ser el primer parámetro y no se puede "reconstruir" un argumento (`Big.add_go(Nil{}, yt, d)` no pasa el chequeo de terminación). Salida: una función aparte para propagar el acarreo sobre la lista que sobra.
5. **Diseñar para el checker**: el simplificador se escribió como 10 helpers que hacen `match` sobre UN parámetro cada uno, para que cada lema de corrección sea un espejo exacto del helper. Con esa disciplina, `simplify_sound` (14 lemas, 105 líneas) **cerró al primer intento**; las dos leyes por cómputo cerraron con `{==}`. `linear_exact` la cerró el agente probador en 2 iteraciones con 4 lemas de suma (~30 líneas); lo difícil fue ver el objetivo reducido exacto (`?goal`) antes de escribir los motivos de reescritura, y la orientación (el término a eliminar va a la derecha del lema).
6. **Rendimiento del backend JS**: 0.2–0.3 s por invocación (arranque de bun + chequeo), 4.3 s para el oráculo bignum de 200 pasos sobre listas enlazadas. Irrelevante para un oráculo; inaceptable para cualquier otra cosa. No hay backend nativo en Windows.

## Cuánto código: Bend vs Python + sympy

| | Bend | Python + sympy + `Fraction` (`tests/sympy_equivalent.py`) |
|---|---|---|
| Pipeline sin pruebas (IR, simplificador, esquema, printer, oráculo, bignum) | 373 líneas de código | 41 líneas de código |
| Leyes + pruebas | 181 líneas | no existe el equivalente |
| Total | 554 | 41 |

La relación es ~9× sin contar pruebas y ~13× con ellas. Lo que explica la diferencia: sympy trae simplificación, impresión y aritmética racional ilimitada de fábrica; Bend no trae nada de eso y además obliga a escribir el simplificador con una estructura que el checker pueda seguir. **Lo que compran las 181 líneas de leyes y pruebas es lo único que sympy no puede dar**: la garantía chequeada por máquina de que `simplify` no cambia el significado exacto de ningún árbol, que el stencil suma al denominador (CFL), que es simétrico, y que es exacto sobre perfiles lineales para todo `a, b`, no para valores testeados. `sp.simplify` es una caja negra que se confía.

## Veredicto de la hipótesis 1 + A + 2'

**Viable hoy, y cerró en un día de trabajo.** La PoC prueba que Bend 2 puede ser el front-end simbólico de un generador de kernels con transformaciones demostradas y con oráculo exacto del mismo IR. El valor está en las pruebas; sin ellas es un sympy peor, y con ellas es algo que ninguna herramienta del stack Python ofrece.

Lo que la PoC **no** prueba, y hay que decir antes de extrapolar a fusión:

- Escala del simplificador: 16 casos por operador binario con el patrón de smart constructors. Normalización asociativa-conmutativa, CSE con sharing, dos y tres dimensiones, condiciones de borde no triviales y coeficientes variables multiplican los casos y las leyes. El demo oficial más grande de este tipo (`proof_typed_eval`) tiene 3 reglas; el eval "hell" del cookbook llega a 840 líneas de prueba por programa.
- Semántica exacta con signo y división: obligatoria para cualquier esquema real. Es un tipo `Z`/`Q` propio con su álgebra probada antes de poder enunciar nada.
- Nada sobre floats: el generador certifica el esquema, no el kernel compilado por XLA.

## Siguiente paso propuesto (Fase 2, pendiente de confirmación)

La hipótesis siguiente del ranking de Fase 0 que la Fase 1 no cubre es la **4** (lógica supervisora verificada), ampliada con **B** (certificados por cómputo) y **C** (modelo de referencia total llamado desde Python para testing diferencial): un secuenciador de descarga de tokamak en miniatura, con invariantes de seguridad probados sobre todas las trazas, decisiones sobre el espacio finito por cómputo, y el modelo expuesto vía loader JS a una suite de Hypothesis que lo compare contra una implementación "de producción" en Python con un bug plantado. Mismo tamaño y mismo estándar de medición que esta fase.
