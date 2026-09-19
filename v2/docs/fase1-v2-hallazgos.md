# Fase 1 (v2) — Hallazgos: el circuito completo sobre una base numérica probada

Fecha: 2026-09-18. Reproducir: `py -3.14 bend-spike/v2/heat/run.py` (los números salen de `v2/heat/results.json`). Diseño y revisión de las leyes en `fase0-v2-diseno.md`.

## Qué se construyó (`bend-spike/v2/`)

| Capa | Archivos | Contenido |
|---|---|---|
| Enteros | `num/z.bend`, `LAWS_Z_ADD` (13), `LAWS_Z_MUL` (9), `PROOF_Z_ADD`, `PROOF_Z_MUL` | `Z` canónico por `succ`/`pred`; anillo conmutativo completo probado |
| Naturales grandes | `num/big.bend`, `LAWS_BIG` (5), `PROOF_BIG` | listas de bits; sumador con acarreo, `inc`, `from_nat`, todos probados contra `to_nat` |
| Enteros grandes | `num/bigz.bend`, `LAWS_BIGZ` (5), `PROOF_BIGZ` | pares `p − n`; `add`, `neg`, `scale`, `from_z`, `zero` probados contra `to_z` |
| IR de calor | `heat/ir.bend`, `LAWS_HEAT` (7), `PROOF_HEAT` | IR lineal por construcción; normalizador a coeficientes probado; certificados del esquema |
| Oráculo | `heat/oracle_core.bend`, `LAWS_ORACLE` (4), `PROOF_ORACLE` | evaluación y paso temporal sobre `BigZ`, probados iguales a la especificación en `Z` |
| I/O | `heat/emit.bend`, `heat/oracle.bend` | kernel JAX a stdout; oráculo por variables de entorno (bits) |
| Driver | `heat/run.py` | gates (pruebas, grillas, test negativo), 2 esquemas × 2 horizontes, comparación con `Fraction` |
| Revisión | `tests/laws_z_smoke.bend`, `tests/laws_heat_smoke.bend`, `tests/cfl_violation_PROOF.bend`, `tests/big_smoke.bend` + `run_big_smoke.py` | instanciación de cada ley antes de probarla; test negativo; bignum vs `int` |

Total: 43 leyes, 43 probadas. `py -3.14 v2/heat/run.py` → `all gates and checks ok: True`.

| Archivo de prueba | Leyes | Líneas (código) | Defs | Iteraciones del checker hasta `All terms check.` | Quién |
|---|---|---|---|---|---|
| `PROOF_Z_ADD.bend` | 13 | 397 (310) | 46 | 2 | agente probador |
| `PROOF_Z_MUL.bend` | 9 | 300 (215) | 34 | 1 (el archivo completo pasó a la primera) | agente probador |
| `PROOF_BIG.bend` | 5 | 237 (173) | 26 | 4 (+14 sondas de una regla del `match`) | agente probador |
| `PROOF_BIGZ.bend` | 5 | 125 (83) | 12 | 1 | agente probador |
| `PROOF_HEAT.bend` | 7 | 164 (109) | 15 | 2 | agente probador |
| `PROOF_ORACLE.bend` | 4 | 90 (72) | 9 | 1 | escrita a mano antes de que existiera `PROOF_BIGZ`, pasó al activar el import |
| **Total** | **43** | **1313 (962)** | **142** | | |

Cada archivo de prueba corre en ~0.2 s. Ninguna ley se relajó, ninguna quedó `?TODO`, no hay `@unsafe`.

## Resultados numéricos (idénticos antes y después de cerrar las pruebas: las pruebas no cambian el código, lo garantizan)

Grilla de 10 puntos, Dirichlet 0, condición inicial `sin(πx)` cuantizada a 21 bits (exacta en float64), α = 1, `dx = 1/9`, `dt = r·dx²`.

| Esquema | N | t | max\|u\| | bits del numerador | JAX f64 vs exacto (rel) | JAX f32 vs exacto (rel) | ambos vs analítica | exacto vs forma cerrada discreta |
|---|---|---|---|---|---|---|---|---|
| r = 1/4 | 13 | 0.040 | 0.66 | 47 | **0** | 1.3e-7 | 1.34e-3 | 3.7e-8 |
| r = 1/4 | 200 | 0.617 | 2.2e-3 | 413 | 2.7e-16 | 1.0e-7 | 6.8e-5 | 1.1e-10 |
| r = 3/8 | 13 | 0.060 | 0.54 | 60 | 6.3e-17 | 6.9e-8 | 4.2e-3 | 2.8e-8 |
| r = 3/8 | 200 | 0.926 | 9.4e-5 | 608 | 3.0e-16 | 5.3e-8 | 1.2e-5 | 4.8e-12 |

En las cuatro corridas el oráculo de Bend coincide **exactamente** con `fractions.Fraction` de Python sobre el mismo esquema, y el test negativo (`r = 3/4`, peso central −2) es **rechazado** por el checker.

Lectura:

- **Redondeo float64 ≈ 1 ulp en todos los casos** (`ε₆₄ = 2.2e-16`), muy por debajo de la cota `N·ε`. Con `r = 3/8` y 13 pasos los numeradores ya tienen 60 bits y float64 redondea (6e-17): confirma que el "error cero" de la v1 era solo que 47 bits entran en la mantisa de 53.
- **Float32 ≈ 1 ulp** (`ε₃₂ = 1.2e-7`) en los cuatro casos. El esquema es una combinación convexa (`weights_nonneg`) y no amplifica el redondeo; esa propiedad está probada, no observada.
- **La distancia a la analítica es discretización** y es la misma para JAX y para el oráculo: el oráculo coincide con la forma cerrada del esquema discreto `g^N sin(πx_i)` hasta el nivel de cuantización de la condición inicial.

## Qué cambió respecto de la v1 (y qué costó)

| | v1 | v2 |
|---|---|---|
| Semántica exacta | `Nat` (sin signo) | `Z` canónico con anillo probado |
| Stencil | pesos precalculados `[p, D−2p, p]` | la física textual `D·u_i + p·(u_{i−1} + (−2)·u_i + u_{i+1})`, normalizada por `lin` |
| Transformación probada | plegado de constantes (6 reglas) | normalización a forma lineal (recolección de coeficientes) |
| Certificado de estabilidad | `Nat.sub` saturando (un truco) | `weights_nonneg` explícito + test negativo rechazado |
| Bignum | limbs base 2^16, testeado | bits, sumador **probado**; enteros grandes como `p − n` con leyes vía `to_z` |
| Oráculo bajo ley | solo `eval` en 13 pasos | `eval_big`, `step`, `iterate`: toda la corrida salvo parse/print |
| Esquemas corridos | r = 1/4 | r = 1/4 y r = 3/8 (cualquier `p/2^q`) |
| Leyes | 4 | 43 |
| Líneas de Bend (código) | 554 (373 programa + 181 leyes y pruebas) | 1666 (528 programa + 176 leyes + 962 pruebas) + 244 de grillas de instanciación |
| Leyes falsas detectadas antes de probar | — (la v1 no instanciaba) | 0 en 43, sobre grillas de hasta 343 ternas por ley |

## Dónde dolió

1. **Una ley sin prueba es "un reclamo muerto".** El checker no deja usar como lema una ley abierta (`an unfilled law is a dead claim: live code cannot use it`). Eso obliga a probar en el orden estricto del grafo de dependencias y a que cada archivo de prueba importe los archivos de **prueba** de los que depende, no solo las leyes. Es lo que impidió lanzar los seis probadores a la vez: fueron dos tandas de dos y una de uno, más el oráculo a mano.
2. **La orientación de las reescrituras.** Los seis reportes dicen lo mismo: `%e : P` reemplaza el lado **derecho** de `e`, y los objetivos casi siempre muestran el lado izquierdo de la ley natural (`to_z(add(..))`, `mul(succ a, x)`). Cada archivo termina con una colección de gemelos volteados por `Equal.sym` (`add_flip`, `neg_add_f`, `big_add_f`, ...). Es el costo fijo de no tener tácticas: se paga una vez por lema, es mecánico, y se estabilizó como convención (`fase0-v2-diseno.md` §4.7).
3. **Reglas del `match` que no están en la guía.** Para partir los tres bits del sumador, el agente descubrió que un `match` interno sobre campos ligados por un `case` multi-scrutinio se rechaza ("match scrutinees in binder order"): hubo que reordenar parámetros y hacer un solo `match xs c ys` con patrones anidados de 8 filas. Y una fila comodín con `+x` encima de filas con constructores falla con `cannot infer False{}`. Catorce sondas del checker para dos reglas.
4. **`Z` no se puede ejecutar.** La aritmética por `succ`/`pred` es unaria y no-tail: tres pasos de la especificación `iterate_z` en la grilla de instanciación reventaron la pila de JS (`memory fault`). La grilla quedó en 1–2 pasos con valores chicos. Es la división de trabajo de la v2: `Z` es el significado, `BigZ` es el motor, y la ley que los une es la que se ejecuta.
5. **Anotaciones que el checker no infiere.** Un `let` de un constructor con argumentos calculados necesita su tipo (`+s = {IR.Scheme{..} : IR.Scheme}`); un selector `Nat` usado en dos ramas necesita `+`; el orden de declaración manda (una función auxiliar usada antes de definirse es `a defined name`). Cada uno costó una vuelta del checker; ninguno un razonamiento.
6. **Lo que NO dolió.** Ninguna ley resultó falsa: la instanciación previa en grilla no encontró nada, y las pruebas cerraron con 1–4 iteraciones cada una. La disciplina "un `match` por helper, un lema espejo por helper" convirtió 43 leyes en trabajo mecánico distribuible entre agentes. Comparado con la v1 (una ley falsa encontrada recién al probar), el cambio de proceso es el hallazgo: **diseñar la especificación y revisarla por instanciación antes de probar** es lo que hace que la prueba sea rutina.

## Lo que sigue sin estar bajo ley (y por qué se acepta)

- `Big.parse` / `Big.show` / `BigZ.show` (texto ↔ bits) y el `run.py` de Python: son traducciones triviales y `run.py` compara el resultado completo con `Fraction`.
- La generación de texto del kernel (`py_lin`): que `"(2.0) * u[1:-1]"` sea lo que JAX interpreta como 2·u_i no es demostrable en Bend. Lo cubre la comparación numérica.
- Todo lo que pasa en float: por diseño.

## Veredicto

**La hipótesis "generador de kernels con transformaciones probadas + oráculo exacto del mismo IR" es viable hoy, y en la v2 es sólida**: todo lo que no es I/O ni float está bajo una ley chequeada por máquina, desde el anillo de los enteros hasta el paso temporal del oráculo. Cerró en un día con seis agentes probadores.

Lo que cuesta, en números: 1666 líneas de Bend (58% son pruebas) contra 41 de Python + sympy + `Fraction` sin ninguna garantía. Las 962 líneas de pruebas son el precio de que "el kernel y el oráculo implementan el mismo esquema, para toda ventana y todo `r` diádico" sea un teorema y no una afirmación. La base numérica (`num/`, 32 leyes) es reutilizable para cualquier capa discreta futura: un secuenciador, un interlock con contadores, certificados de tableaus de Runge-Kutta.

Qué queda fuera y cuánto costaría entrar:

- **Denominadores no diádicos** (`1/3`, `1/6` de RK4): el IR y las leyes no dependen de que `D` sea potencia de 2; solo `Scheme{p, q}` lo construye así. Cambiar `den_nat` a un `D` arbitrario es una línea y ninguna prueba nueva.
- **Dos y tres dimensiones**: `Var{k}` indexa una ventana aplanada; el normalizador y `lin_sound` no cambian. Cambia el printer y el oráculo (ventanas más grandes).
- **Coeficientes variables** (`α(x)`): el IR necesitaría constantes por punto en el entorno; `lin_sound` se generaliza con la misma estructura.
- **Términos no lineales** (`u·u_x`): fuera del IR lineal **por diseño**; entrar exige un IR polinomial y una forma normal de polinomios con sus leyes: es otro proyecto, no una extensión.
- **Floats**: nunca. La frontera queda donde estaba: exacto en Bend, float en JAX, puente por entradas diádicas exactas y comparación numérica.

Sobre la pregunta de fondo ("¿Bend cumple su propósito de que la IA no se equivoque?"): en la v2 el checker no encontró ningún error semántico porque el proceso lo evitó antes: las 43 leyes se instanciaron en grilla y ninguna era falsa. Lo que sí atrapó fueron los errores de forma (afinidad, orden, anotaciones) y lo que sí garantiza es que **nadie**, humano o IA, puede cambiar `lin`, `Z.mul` o `step` sin que `run.py` deje de decir `True`. Esa es la utilidad real: no que la IA no se equivoque al escribir, sino que ninguna equivocación futura pase en silencio.
