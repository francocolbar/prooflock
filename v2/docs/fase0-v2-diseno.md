# Fase 0 (v2) — Diseño de la base numérica y revisión de las especificaciones

Fecha: 2026-09-18. Reemplaza la elección de PoC de `../../docs/fase0-reevaluacion.md` (v1) con una versión sin los atajos que la v1 necesitó: sin `Nat` como semántica, sin esquemas restringidos a pesos no negativos, sin bignum testeado-pero-no-probado. Todo lo que hay en `v2/` está bajo una ley o es I/O trivial.

## 1. Qué estaba flojo en la v1 y qué lo reemplaza

| Debilidad v1 | Consecuencia | Solución v2 | Archivo |
|---|---|---|---|
| Semántica exacta sobre `Nat` | Solo esquemas con pesos ≥ 0; la resta no existe; `r ≤ 1/2` elegido para esquivar el signo | Enteros canónicos `Z` (`Zero`, `Pos{n}` = n+1, `Neg{n}` = −(n+1)) con leyes de anillo probadas | `num/z.bend`, `LAWS_Z_ADD/MUL` |
| `weights_sum` como "certificado CFL" por saturación de `Nat.sub` | Un truco: la ley era verdadera por un efecto colateral de la aritmética, no por el enunciado | Certificado explícito `weights_nonneg` (todos los pesos ≥ 0 ⇔ combinación convexa ⇔ `r ≤ 1/2`) y un test negativo que debe ser rechazado | `LAWS_HEAT`, `tests/cfl_violation_PROOF.bend` |
| Stencil construido ya con los pesos calculados (`[p, D−2p, p]`) | El "simplificador" solo sacaba `·1` y `+0`; la resta la hacía el constructor | El stencil se escribe como la física: `D·u_i + p·(u_{i−1} + (−2)·u_i + u_{i+1})`; un **normalizador** a forma lineal recolecta los coeficientes; su corrección es la ley central | `heat/ir.bend`, `lin_sound` |
| IR con `Mul` general | Términos no lineales representables y sin sentido para un stencil | IR **lineal por construcción**: `Scale{c, e}` es el único producto | `heat/ir.bend` |
| Bignum de limbs base 2^16 con `Nat.div/mod` | Testeado contra Python, no probado (dividir es opaco para el checker) | Naturales como listas de bits con significado estructural `to_nat`; sumador con acarreo **probado**; enteros grandes como par `p − n` (sin préstamos ni signo) | `num/big.bend`, `num/bigz.bend`, `LAWS_BIG`, `LAWS_BIGZ` |
| Oráculo = "mismo `eval`" solo hasta 13 pasos | Sin conexión probada entre el oráculo a escala y la semántica | `eval_big` espeja `eval` constructor por constructor y la ley `eval_big_sound` los iguala vía `to_z` | `heat/oracle_core.bend`, `LAWS_ORACLE` |
| Leyes escritas y probadas sin instanciación previa | La v1 tuvo una ley falsa (`fire_guard`) que solo apareció al probar | Cada ley se instancia en una grilla de valores **antes** de intentar la prueba (`tests/laws_*_smoke.bend`); una ley falsa aparece en segundos como `FALSE` | `tests/` |

Lo que sigue igual: los floats quedan afuera de Bend (nada es demostrable sobre `F32`); el kernel JAX se genera como texto; la comparación numérica la hace Python con `Fraction`.

## 2. Decisiones de diseño que hacen las pruebas posibles

- **`Z` por `succ`/`pred`.** `Z.add(Pos{n}, b)` es `succ` aplicado n+1 veces; `Z.mul(Pos{n}, b)` es `b` sumado n+1 veces; los negativos son `neg` de los positivos. Cada ley se prueba por inducción estructural sobre el `Nat` interior, sin `Nat.sub` ni comparaciones. Precio: `Z.add` es O(|a|) en runtime. `Z` es el **significado** de los programas; la ejecución a escala va por `BigZ`. Los únicos `Z` que se ejecutan son los coeficientes del esquema (≤ 16).
- **Forma canónica.** Un solo término por entero, así `{a == b : Z}` es igualdad estructural y `{==}` cierra objetivos. Un `Z` como par de `Nat` habría obligado a leyes "módulo equivalencia" y a lemas de congruencia a mano para cada reescritura.
- **Bignum como bits, no como limbs.** `to_nat(b <> t) = bit(b) + 2·to_nat(t)` es estructural; el sumador es el sumador binario de libro y su corrección es una inducción con 8 casos por bit. Con limbs base 2^16 la corrección necesita `div`/`mod` simbólicos (nivel "hard"). Precio: un nodo por bit; irrelevante para un oráculo (200 pasos, 10 puntos: 1.8 s).
- **Enteros grandes como `p − n` sin canonicalizar.** `BigZ.add` es componente a componente y `BigZ.neg` es un intercambio: cero lógica de signo, cero préstamos. La representación no es única (`BZ{[1],[1]}` también es 0): por eso **todas** las leyes de `BigZ` se enuncian a través de `to_z`, nunca sobre la representación.
- **El escalado espeja la multiplicación.** `BigZ.scale(Pos{k}, v)` es `v` sumado k+1 veces, exactamente como `Z.mul_pos`. Así `scale_sound` se prueba con `add_sound` y una inducción, sin multiplicación de bignums.
- **Cada helper hace `match` sobre un solo parámetro** y tiene un lema espejo. Es la disciplina que en la v1 hizo cerrar `simplify_sound` al primer intento; acá se aplica a `zip_add`, `scale_list`, `dot`, `lookup`, `unit`.
- **Convención de reescritura.** Todo lema se enuncia con el término a eliminar a la derecha (`%e : P` reemplaza el lado derecho de `e`). Los agentes probadores reportaron que esta es la fuente principal de iteraciones; se fija como regla del proyecto.

## 3. Las leyes, una por una, con su revisión

Formato: **enunciado** (tal cual está en el archivo, en notación Bend) · *qué garantiza* · *qué NO garantiza* · *validación previa*. La validación previa es la instanciación en grilla de `tests/laws_z_smoke.bend` (7 valores de Z, hasta 343 ternas por ley) y `tests/laws_heat_smoke.bend` (11 expresiones × 4 ventanas; 35 esquemas; 25 pares (a,b)). Ninguna ley resultó falsa en la v2; las dos revisiones que sí cambiaron enunciados están en §4.

### 3.1 `LAWS_Z_ADD.bend` (13 leyes) — probadas, 397 líneas, 2 iteraciones del checker

| Ley | Enunciado | Qué garantiza / qué no |
|---|---|---|
| `succ_pred`, `pred_succ` | `succ(pred(a)) == a`, `pred(succ(a)) == a` | `Z` es un grupo cíclico discreto sin extremos. No dice nada de `add`. |
| `add_zero_r` | `add(a, Zero) == a` | Neutro a derecha; a izquierda es definicional. |
| `add_succ_r/l`, `add_pred_r/l` | `add(a, succ(b)) == succ(add(a, b))` y simétricas | Los lemas de "corrimiento" que hacen todas las inducciones. |
| `add_comm`, `add_assoc` | conmutatividad y asociatividad | Con `add_zero_r`: `(Z, +)` es un monoide conmutativo. |
| `neg_neg`, `add_neg_r`, `neg_add` | `neg(neg(a)) == a`, `add(a, neg(a)) == Zero`, `neg(a + b) == neg(a) + neg(b)` | Inversos: `(Z, +)` es un grupo abeliano. `add_neg_l` no está enunciada: se obtiene de `add_comm`. |
| `from_nat_add` | `from_nat(a + b) == add(from_nat(a), from_nat(b))` | La inclusión `Nat → Z` respeta la suma. Hace falta para `BigZ.add_sound`. No dice nada de `mul` (`from_nat_mul` no se necesita). |

### 3.2 `LAWS_Z_MUL.bend` (9 leyes) — en prueba

| Ley | Enunciado | Qué garantiza / qué no |
|---|---|---|
| `mul_zero_r` | `mul(a, Zero) == Zero` | A izquierda es definicional. |
| `mul_one_l`, `mul_one_r` | `mul(Pos{0n}, b) == b`, `mul(a, Pos{0n}) == a` | `Pos{0n}` es 1. |
| `mul_neg_l`, `mul_neg_r` | `mul(neg(a), b) == neg(mul(a, b))` y simétrica | Regla de signos. |
| `dist_l`, `dist_r` | `mul(c, x + y) == mul(c, x) + mul(c, y)` y `mul(a + b, x) == mul(a, x) + mul(b, x)` | Las dos distributividades; ambas se usan en `lin_sound` (la izquierda al escalar una forma lineal, la derecha al sumar coeficientes). |
| `mul_assoc`, `mul_comm` | asociatividad y conmutatividad | Con lo anterior: `Z` es un anillo conmutativo. `mul_comm` no la usa ninguna ley posterior; está porque un anillo sin ella es una afirmación a medias. |

### 3.3 `LAWS_BIG.bend` (5 leyes) — en prueba

| Ley | Enunciado | Qué garantiza / qué no |
|---|---|---|
| `add_carry_sound` | `to_nat(add_carry(xs, c)) == to_nat(xs) + bit(c)` | Propagar un acarreo suma exactamente ese bit. |
| `add_go_sound` | `to_nat(add_go(xs, ys, c)) == (to_nat(xs) + to_nat(ys)) + bit(c)` | El sumador con acarreo de entrada es correcto **sin cota de ancho**: no hay overflow porque la lista crece. |
| `add_sound` | `to_nat(add(xs, ys)) == to_nat(xs) + to_nat(ys)` | La ley que usa todo lo demás. |
| `inc_sound`, `from_nat_sound` | `to_nat(inc(xs)) == 1 + to_nat(xs)`, `to_nat(from_nat(n)) == n` | Las constantes del IR entran bien al bignum. **No** hay ley para `parse` (bits desde texto): es una traducción carácter a bit que se lee de un vistazo, y `run.py` compara de todos modos con `Fraction`. |

### 3.4 `LAWS_BIGZ.bend` (5 leyes) — pendiente (depende de 3.1 y 3.3)

| Ley | Enunciado | Qué garantiza / qué no |
|---|---|---|
| `add_sound` | `to_z(add(a, b)) == Z.add(to_z(a), to_z(b))` | Sumar pares es sumar enteros. |
| `neg_sound` | `to_z(neg(a)) == Z.neg(to_z(a))` | Intercambiar es negar. |
| `scale_sound` | `to_z(scale(c, v)) == Z.mul(c, to_z(v))` | Escalar por una constante `Z` es multiplicar. Es la única multiplicación que el oráculo necesita. |
| `from_z_sound`, `zero_sound` | `to_z(from_z(c)) == c`, `to_z(zero()) == Zero` | Las constantes entran bien. |

Lo que estas leyes **no** dicen: nada sobre el tamaño de la representación (`p` y `n` crecen sin cancelarse). Es un hecho de rendimiento, no de corrección, y en 200 pasos los numeradores tienen 608 bits.

### 3.5 `LAWS_HEAT.bend` (7 leyes) — pendiente (depende de 3.2)

| Ley | Enunciado | Qué garantiza / qué no |
|---|---|---|
| `lin_sound` | `∀ e, env: eval_lin(lin(e), env) == eval(e, env)` | **La ley central.** El normalizador que produce los coeficientes del kernel no cambia el significado exacto de ningún árbol bajo ninguna ventana (incluidas ventanas más cortas o más largas que el stencil). No dice nada del float que JAX calcula con esos coeficientes. |
| `weights_sum` (por cómputo) | `sum(weights(heat_scheme())) == den(heat_scheme())` | Un perfil constante es punto fijo: consistencia de orden 0. Solo para `r = 1/4`. |
| `weights_symmetric` (por cómputo) | `w_{−1} == w_{+1}` | Primer momento nulo: consistencia de segundo orden. Solo para `r = 1/4`. |
| `weights_nonneg` (por cómputo) | `all_nonneg(weights) == True` | Combinación convexa ⇒ principio del máximo ⇒ estabilidad. Equivale a `r ≤ 1/2`. **Es falsa para `r = 3/4`** y `tests/cfl_violation_PROOF.bend` verifica que el checker la rechaza. |
| `no_source` (por cómputo) | `const_of(lin(stencil)) == Zero` | La ecuación es homogénea. |
| `weights_sum_all` | `∀ p, q: sum(weights(Scheme{p, q})) == den(Scheme{p, q})` | La consistencia de orden 0 vale para **todo** `r` diádico, no es una coincidencia de 1/4. Requiere el anillo de `Z` con `p` y `q` simbólicos. |
| `linear_exact` | `∀ a, b: eval(stencil, [a, a+b, a+2b]) == D·(a+b)` | Un perfil lineal (`u_xx = 0`) se preserva exactamente para todo `a, b` enteros. Solo `r = 1/4`. |

### 3.6 `LAWS_ORACLE.bend` (2 leyes) — pendiente (depende de 3.4)

| Ley | Enunciado | Qué garantiza / qué no |
|---|---|---|
| `lookup_big_sound` | `to_z(lookup_big(k, env)) == lookup(k, map_to_z(env))` | Leer la ventana grande es leer la ventana `Z`, incluso fuera de rango (ambas dan 0). |
| `eval_big_sound` | `∀ e, env: to_z(eval_big(e, env)) == eval(e, map_to_z(env))` | El oráculo a escala calcula exactamente la semántica `Z` del árbol crudo. Con `lin_sound`: el kernel (forma normal) y el oráculo (árbol crudo) implementan el mismo esquema. |
| `step_sound` | `∀ xs, e, d: map_to_z(step(xs, e, d)) == step_z(map_to_z(xs), e, d)` | Un paso temporal sobre enteros grandes (ventanas de 3, bordes Dirichlet escalados por `D`) es el paso temporal de la especificación en `Z`. `step_z` es la misma función escrita sobre `Z`: es la definición de "un paso del esquema", legible en 20 líneas. |
| `iterate_sound` | `∀ n, xs, e, d: map_to_z(iterate(n, xs, e, d)) == iterate_z(n, map_to_z(xs), e, d)` | `n` pasos son `n` pasos. Con esto, **toda la corrida del oráculo** está bajo ley; afuera quedan solo `parse` (texto → bits) y `show` (bits → texto), y `run.py` los cubre comparando con `Fraction` (4 corridas, coincidencia exacta). |

Nota de implementación (revisión 5, §4): la especificación `step_z`/`iterate_z` **no se puede ejecutar** más que sobre valores diminutos, porque la aritmética de `Z` es unaria y recursiva no-tail: la primera grilla de instanciación de `iterate_sound` con 3 pasos reventó la pila de JS (`memory fault`). La grilla usa 1 paso con `d = 4` y `d = −3`, y 2 pasos con `d = 2`. Es el precio de tener un `Z` sobre el que las pruebas son inducciones simples.

## 4. Revisiones que cambiaron algo

1. **Lado del coeficiente en `Scale`.** Primera versión de `eval`: `Scale{c, e} ↦ mul(eval(e), c)`. Al escribir `lin_sound` en papel, la prueba de `scale_list` pedía `mul(mul(x, a), c) == mul(x, mul(a, c))` y la de `zip_add` pedía la distributiva izquierda; con el coeficiente a la izquierda (`mul(c, eval(e))`) y `dot` como `Σ mul(c_k, x_k)`, `scale_list` usa `mul_assoc` directo y `zip_add` usa `dist_r`. Se eligió la segunda para que cada helper necesite una sola ley. No cambia el significado, cambia cuántos lemas hacen falta.
2. **"CFL por saturación" → `weights_nonneg`.** En v1, `weights_sum` era verdadera para `r ≤ 1/2` y falsa para `r > 1/2` solo porque `Nat.sub` satura en 0; el enunciado no hablaba de estabilidad. En v2 la suma da `D` para todo `r` (`weights_sum_all`, verdadera para 35 esquemas incluidos los inestables) y la estabilidad tiene su propia ley, con su propio test negativo.
3. **`lookup` fuera de rango.** `eval(Var{5n}, [a, b, c])` da 0 por definición. Se agregó `Var{5n}` y ventanas de largo 0, 1, 3 y 5 a la grilla de `lin_sound` y `eval_big_sound` para que la ley se instancie también donde `dot`, `unit` y `zip_add` tienen largos distintos: es donde una prueba por inducción sobre dos listas suele fallar.
4. **`from_nat_add` con valores negativos.** La ley es sobre `Nat`; la grilla la instancia con `abs(a)`, `abs(b)`. Se documenta para que nadie lea "probado sobre la grilla de Z" como "probado con negativos".
5. **El paso temporal entraba sin ley.** La primera versión de `LAWS_ORACLE` cubría `eval_big` y dejaba `step`/`iterate` (ventanas, bordes escalados) validados solo contra Python. Se agregó la especificación `step_z`/`iterate_z` sobre `Z` y las leyes `step_sound`/`iterate_sound`. Al instanciarlas apareció el límite de ejecución de `Z` (nota en §3.6).
6. **Una ley abierta es "un reclamo muerto".** El checker rechaza usar como lema una ley que todavía no tiene prueba (`an unfilled law is a dead claim: live code cannot use it`). Consecuencia para el plan: las pruebas se hacen en el orden estricto del grafo de §5 y cada archivo de prueba importa los archivos de prueba de los que depende, no solo sus leyes. No se puede "probar en paralelo asumiendo lo de abajo".
7. **Orientación de los lemas.** Los tres agentes probadores de la v1/v2 reportaron lo mismo: la mayoría de las iteraciones se van en la dirección de reescritura. Regla fijada: cada ley se enuncia en su forma natural (`to_z(op(..)) == Z.op(..)`), y cada archivo de prueba define versiones "volteadas" con `Equal.sym` (`add_flip`, `scale_flip`, `eval_flip`) para eliminar el lado izquierdo de un objetivo.

## 5. Plan de pruebas y dependencias

```
LAWS_Z_ADD ──┬──> LAWS_Z_MUL ──> LAWS_HEAT (lin_sound, weights_sum_all, linear_exact)
             └──> LAWS_BIGZ  ──> LAWS_ORACLE
LAWS_BIG   ──────> LAWS_BIGZ
```
Un agente probador por archivo, en paralelo cuando las dependencias lo permiten. Cada uno recibe: el archivo de leyes (intocable), el plan de lemas, la convención de orientación, el comando exacto del checker, y un tope de iteraciones. Ninguna ley se relaja para que cierre: si una no cierra, queda `?TODO` y se reporta.

## 6. Qué cuenta como "cerró" en la Fase 1 v2

`py -3.14 v2/heat/run.py` termina con `all gates and checks ok: True`, que exige:

1. Los seis `PROOF_*.bend` imprimen `All terms check.` (41 leyes, sin `@unsafe`, sin `?TODO`).
2. Las dos grillas de instanciación no tienen ninguna línea `FALSE`.
3. `tests/cfl_violation_PROOF.bend` es **rechazado** por el checker.
4. Para `r = 1/4` y `r = 3/8`, con 13 y 200 pasos: el kernel emitido corre en JAX float64; el oráculo de Bend coincide **exactamente** con `Fraction` de Python; el error float64 contra el oráculo está por debajo de `N·ε`; JAX y oráculo dan el mismo error contra la solución analítica; el oráculo coincide con la forma cerrada del esquema discreto hasta la cuantización de la condición inicial.

Resultado numérico ya obtenido (antes de las pruebas pendientes, `heat/results.json`): las cuatro corridas cumplen el punto 4. Con `r = 3/8` y 13 pasos los numeradores tienen 60 bits y float64 ya redondea (error relativo 6e−17), lo que confirma la lectura de la v1: "error cero" era un artefacto de los 47 bits.
