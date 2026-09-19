# Fase 0 — Reevaluación de la pregunta con conocimiento real de Bend 2

Fecha: 2026-09-18. Bend 2.0.6 (fuente commit `67692d7f`, corrido con bun 1.3.11 en Windows 11 sin WSL ni clang). Todo lo afirmado sobre el lenguaje está verificado en esta máquina o citado de la guía oficial / paper del runtime (copiados en mis skills `bend2` y `bend2-laws`); lo que no pude verificar acá lo marco como **[no verificado acá]**.

## Correcciones al prompt (donde gana lo que sé del lenguaje real)

Antes de la auditoría, cuatro premisas del prompt que no coinciden con Bend 2 tal como existe hoy:

1. **Bend 2 no corre sobre redes de interacción.** Eso era Bend 1 / HVM2. El runtime de Bend 2 (BendRT) es una máquina compilada con semántica de movimiento: cada def se corta en segmentos `tail / cut / fork`, los valores tienen un único dueño (por eso no hay GC), y el paralelismo es fork-join sobre un scheduler fijo ("el cubo": 2^14 anillos, sin work stealing, sin cola compartida). "HVM5" existe, pero como *demo escrito en Bend* (`demos/pure_hvm5_mini`), no como runtime. Consecuencia: el argumento "las redes de interacción son buenas para cómputo irregular tipo árbol" no aplica. Lo que sí aplica es lo contrario: el scheduler **nunca rebalancea**, así que los árboles de búsqueda desbalanceados (poda) son el peor caso documentado (queens: GPU 0.93 s vs 16 cores 0.46 s).
2. **`Nat` no es ilimitado.** Es un inmediato de 48 bits en runtime: pasar 2^48−1 aborta con `bend: a Nat past the largest immediate 2^48-1`. Lo verifiqué en los tres evaluadores: runtime JS in-process, JS emitido corrido con node, y el normalizador del checker (que expande literales en unario y revienta el stack). No hay bignum en Base. El punto 2 tal como está escrito no es implementable.
3. **"Síntesis" no existe en 2.0.6.** El compilador tiene `?nombre` (imprime el objetivo y falla) y `?TODO` (deja el hueco abierto), pero no rellena pruebas ni programas. No hay tácticas, no hay búsqueda de pruebas, no hay inferencia de casi nada (cada literal, cada bind de `do`, cada operador lleva su tipo).
4. **"Single-thread mucho más lento que C" es demasiado pesimista.** Según el paper del runtime, la ejecución secuencial nativa está en 0.8–1.5× del gemelo en C (pointer-chasing y strings 2–4× peor). Lo que sí es cierto: solo `F32` (nada de F64), arrays de un solo dueño, y en Windows ni siquiera existe el backend nativo. El veredicto sobre la capa caliente no cambia: Bend 2 no compite ahí. Pero por las razones correctas: F32 y falta de ecosistema, no por velocidad secuencial.

Dos premisas que sí son correctas: arrays afines no compartibles (son `Type`-kinded, un dueño, `Array.clone` explícito) y `F32` como único flotante (además axiomático: nada es demostrable sobre floats).

---

## 1. Reformulación de la pregunta

Pregunta original: *"¿cómo se innova en fusión (o simulación física en general) usando Bend 2 como complemento del stack actual?"*

Reformulada con lo que Bend 2 es: **¿qué partes de un pipeline de simulación se benefician de estar escritas en un lenguaje total (terminación obligatoria), con tipos dependientes y pruebas chequeadas en compilación, cuyo output puede ser texto (código generado), JS importable, o C POSIX, y cuya aritmética se limita a `Nat < 2^48`, `U32` y `F32`?** La respuesta no está en el runtime (que en esta máquina ni existe en modo nativo) sino en el **checker**: es el único componente de Bend 2 que hace algo que JAX + Python + sympy no hacen.

Propiedad por propiedad, para este dominio:

| Propiedad | Qué es realmente | Valor para simulación física |
|---|---|---|
| Semántica afín | Toda variable se usa ≤ 1 vez; `+x` permite reuso solo en tipos `Data` (nunca en funciones, arrays, handles). Clausuras se llaman una sola vez. | **Neutra en la capa simbólica** (los árboles de expresiones son `Data`, se copian con `+`). **Contraproducente para numérica** (no hay aliasing de arrays; `Array<T>` es de un dueño). Es lo que permite consistencia lógica con `Type : Type` y runtime sin GC, o sea: es el precio de las pruebas, no un feature de dominio. |
| Terminación obligatoria | Cada llamada recursiva debe decrecer estructuralmente en un argumento (el primero que cambia). Sin recursión mutua. `@unsafe` la salta pero anula las garantías. | **Alta para lógica supervisora** (todo termina, todo `match` es exhaustivo: las propiedades que piden las normas de código crítico). **Costo para búsqueda** (hay que enhebrar un `Nat` de combustible). Irrelevante para numérica. |
| Tipos dependientes | Tipos indexados por valores (GADTs vía el "truco de Ford": campos `eq: {TNum{} == t : Ty}`), predicados como tipos (`LE`, `Sorted`), `Sigma`, igualdad proposicional `{a == b : T}`. | **Alta**: IR de expresiones bien tipado por construcción, procedencia como índice, certificados como valores. Verificado hoy: `Field<3n, 7n>` vs `Field<3n, 8n>` es error de tipo. |
| Pruebas en compilación | `law` (enunciado) + `def` (prueba). Primitivas: `{==}` (reflexividad tras desplegar definiciones), `match` (inducción/casos), `%e : P` (reescritura), `Equal.sym/trans/cong`, refutación por motivo. Sin tácticas. | **La propiedad central.** Dos modos: (a) inducción estructural sobre IR/trazas (las pruebas del demo `proof_typed_eval`: 59 líneas para un optimizador de 3 reglas); (b) **prueba por cómputo**: si el enunciado es cerrado y decidible, el checker lo normaliza y `{==}` lo cierra (idioma `T(check_all()) := Unit{}`). Sobre floats: nada (F32 axiomático). Sobre `Nat`: todo, pero unario en el checker (literales grandes cuestan). |
| HVM / paralelismo | Fork-join estático (`a b = f(x) g(y)`), balance a cargo del programa, GPU solo para trabajo uniforme (mandelbrot/nbody 60–120× vs secuencial; búsqueda divergente pierde contra 16 cores). Requiere clang ≥ 14 y POSIX. | **Irrelevante para este spike** (no existe en Windows) y **débil para búsqueda con poda** por diseño del scheduler. Donde brillaría (kernels uniformes) es justo la capa caliente que descartamos por F32. |
| Síntesis | No existe. | — |
| I/O e interop | Mónada `IO` con efectos: print, archivos (solo escritura en Windows), env vars, canales. Efectos foráneos en C o JS (no Python). Loader JS: `import X from "./x.bend"` expone las defs puras como funciones JS. Emite C (POSIX) y JS. Sin argv, sin stdin. | **Suficiente** para emitir código y datos como texto y para exponer funciones puras a node. Verificado hoy: tres rutas (stdout → .py, `File.write` con ruta por `BEND_OUT`, y `node --import` del loader). No hay FFI hacia Python; la integración es por subprocess + texto/JSON. |
| Sistema de números | `Nat < 2^48` (unario en el checker), `U32`, `F32`. No F64, no enteros con signo, no bignum, no racionales. `U32` es opaco para el checker salvo por cómputo sobre literales. | **El límite duro del spike.** Oráculo exacto: o bignum a mano (limbs `Nat` base 2^16) o instancias que entren en 48 bits. Las pruebas van sobre `Nat`; el float es solo código generado. |
| Paquetes por hash | `import 0x<hash>/main.bend` descarga y verifica por hash de contenido; `--publish` sube. **[no verificado acá]** | Procedencia del código simbólico a nivel de módulo, gratis. |

Resumen: para este dominio, Bend 2 vale por **checker + tipos dependientes + emisión de texto**. El runtime paralelo y la afinidad son irrelevantes o costo. La aritmética es la restricción que hay que diseñar alrededor.

---

## 2. Auditoría de los 5 puntos

### Punto 1 — Front-end simbólico que emite kernels JAX/CUDA

**¿Existe el mecanismo?** Sí. Tres rutas verificadas hoy con un hello-world real (`env/hello/`, log en `env/check_env.log`):
- A: `IO.write(src)` → stdout → redirigido a `.py` → `py -3.14` lo corre. (Es la que voy a usar: sin rutas, sin estado.)
- B: `File.open/write/close` con la ruta leída de `IO.get_env("BEND_OUT")` (Bend no tiene argv). Funciona en Windows.
- C: loader JS: `node --import file:///…/bend2/main.ts app.mjs` con `import Lib from "./lib.bend"`; las defs puras se llaman desde JS y los constructores llegan como `{$: "Add", a, b}`. Útil para que Python llame funciones Bend vía subprocess+JSON sin escribir un `main`.

No hay FFI a Python ni export de módulos Python. `String` es una lista enlazada de chars (un nodo por carácter): generar unos KB de kernel es trivial, generar MBs no.

**Cómo lo haría alguien que conoce Bend 2 vs cómo está descrito.** Tal como está descrito (Bend como "generador de código que corre una vez"), es un sympy peor: sin álgebra, sin simplificación incorporada, con strings lentos y sin bignum. La versión de alguien que conoce el lenguaje es la del demo `proof_typed_eval`: un IR **intrínsecamente tipado** (`type Expr<-t: Ty>` con el truco de Ford, imposible construir un término mal tipado), un evaluador de referencia `eval : Expr<t> -> Val(t)` sobre semántica exacta (`Nat`), un pase de transformación `opt`, y la ley `eval(opt(e)) == eval(e)` **probada** por inducción sobre el IR. El printer a Python/JAX es un `show` trivial. Es decir: el punto 1 solo tiene sentido en Bend si viene con el punto A de la sección 3 (transformaciones probadas). Sin eso, no aporta nada sobre sympy.

**Veredicto: viable hoy**, pero el valor está en el par "generador + ley de corrección", no en el generador.

### Punto 2 — Oráculo exacto en aritmética racional sobre `Nat` ilimitado

**¿Existe el mecanismo?** **No como está enunciado.** `Nat` aborta en 2^48−1 (verificado en checker, runtime y JS emitido). No hay bignum ni racionales en Base. Tampoco enteros con signo: `Nat.sub` satura en 0, `U32.sub` da la vuelta.

**Cómo lo haría alguien que conoce Bend 2.** Tres salidas, de menor a mayor esfuerzo:
1. **Diseñar la instancia para que entre en 48 bits.** El esquema de calor con r = α·dt/dx² = 1/4 es `u_i' = (2u_i + u_{i-1} + u_{i+1}) / 4`: coeficientes no negativos (evita el signo) y diádicos (denominador 2^e, evita el gcd). Si la condición inicial se cuantiza a m bits (valores k/2^m, exactamente representables en float64), tras N pasos los numeradores tienen ≤ m + 2N bits. Con m = 21 y N = 13 entra en 47 bits. **El oráculo es entonces literalmente la misma función `eval` sobre la que se prueba la ley del simplificador**: no hay nada extra que verificar.
2. **Bignum a mano**: numeradores como `List<&2, Nat>` de limbs base 2^16 (hay que usar `Nat`, no `U32`, si se quiere probar algo: `U32` es opaco para el checker). Para este esquema solo hacen falta suma y duplicación (el denominador es un exponente `Nat` aparte). ~40–60 líneas; testeable contra `int` de Python; probar `to_nat(add(a,b)) == to_nat(a) + to_nat(b)` con acarreo es nivel "firm/hard" del cookbook.
3. **Otra herramienta**: `fractions.Fraction` de Python hace el oráculo en 5 líneas, sin límite, y es lo que cualquiera usa. Bend solo gana si el oráculo es *el mismo IR* que generó el kernel (así se prueba que kernel y oráculo implementan el mismo esquema). Ese es el único argumento a favor.

**Veredicto:** como está escrito, **no viable**. Reformulado como "oráculo = evaluador exacto del mismo IR, en instancias que entran en 48 bits (o con bignum propio)", **viable hoy**. Si solo se quiere un oráculo, **la idea sirve pero con otra herramienta: `fractions.Fraction`**.

### Punto 3 — Exploración combinatoria del espacio de diseño (enumerar + podar topologías)

**¿Qué implica la afinidad para una búsqueda en árbol con poda?** Poco si los candidatos son `Data` (`+cand` los copia; una lista o árbol con `+` pasa a ser reference-counted en todo el programa, aceptable). La recursión sobre el árbol de búsqueda es natural. Lo que sí implica:
- **Terminación**: la profundidad va como `Nat` estructural (primer parámetro). Normal.
- **Sin estado compartido**: branch-and-bound clásico (cota incumbente global que poda ramas hermanas) **no existe**: o se enhebra la cota secuencialmente (adiós paralelismo) o cada subárbol poda solo con cotas locales. La poda estática (factibilidad) sí funciona.
- **Paralelismo**: el scheduler no rebalancea; un árbol podado es desbalanceado por definición. La documentación de rendimiento lo pone como el anti-patrón principal ("cube never rebalances: lanes idle until the slow child ends"). En esta máquina además no hay backend nativo: cero paralelismo medible.
- Lo que Bend sí daría y nadie más: **probar que el enumerador es completo** (toda topología válida aparece) o que el podador es sano (nunca descarta una factible), por inducción. Es una prueba nivel "hard/hell" del cookbook (decision procedures sound+complete: 333–840 líneas en los evals).

**Cómo lo haría alguien que conoce Bend 2.** Enumeración por índice sobre un espacio potencia de dos con test de factibilidad en la hoja (así el fork es balanceado), sin cota global, y solo si la propiedad "sano y completo" justifica el esfuerzo de prueba. Para exploración real de diseño (bobinas, topologías de divertor) la herramienta es un solver (OR-tools, Z3) o Python + numba; la parte continua ya es JAX.

**Veredicto: viable con trabajo, valor bajo con Bend actual.** La idea sirve pero con otra herramienta (Z3/OR-tools para poda con cotas; JAX para lo continuo). El único ángulo propio de Bend es la prueba de completitud, y es caro.

### Punto 4 — Lógica supervisora de control verificada (máquinas de estado, interlocks)

**¿Qué se puede probar realmente y con cuánto esfuerzo sin tácticas?** Lo medí hoy con un interlock de juguete (`env/interlock/`): 3 estados (Idle/Armed/Firing), 3 eventos (Arm/Fire{permit}/Abort), `step`, `run` sobre trazas, y dos leyes:
- `fire_guard`: "Firing solo se entra desde Armed con permiso". Prueba: `match s e` con los 12 casos, cada uno `{==}` (el checker despliega `step` y compara). **Cerró en minutos.** Y antes de cerrar **encontró un error en la especificación**: la primera versión decía "no estar en Firing tras el paso salvo el caso Armed+Fire{True}", y el checker devolvió el contraejemplo exacto (`case Firing{} Arm{}`: quedarse en Firing no es entrar). Ese es el valor concreto: el contraejemplo sale gratis del caso que no reduce a `True{}`.
- `never_firing`: "desde Idle, ninguna traza sin `Fire{True}` llega a Firing". Prueba por inducción sobre la traza, generalizada a cualquier estado inicial no-Firing, con refutación de la hipótesis `{False{} == True{}}` por motivo. **52 líneas, 2 iteraciones del checker, ~2 minutos de un subagente** (bend-prover). Total: programa 60 líneas, leyes 12, pruebas 83. Checker: < 0.5 s.

Lo que se puede probar: invariantes de seguridad sobre todas las trazas, determinismo, ausencia de transiciones prohibidas, propiedades de alcanzabilidad de espacios finitos **por cómputo** (`{check_all() == True{} : Bool}` cerrado con `{==}`, sin inducción: el checker enumera). Lo que no: tiempo real, dinámica híbrida (nada continuo: F32 axiomático), vivacidad no acotada (no hay coinducción), nada sobre el código que realmente corre en el PLC.

**Cómo lo haría alguien que conoce Bend 2 vs cómo está descrito.** Igual que lo describiste, con dos precisiones: (i) preferir la prueba por cómputo cuando el espacio es finito (más barata que la inducción; escala mal solo porque el checker es unario en `Nat`); (ii) el C que emite Bend es POSIX, reserva 8 TiB de espacio virtual y trae su runtime: **no va a un PLC**. El rol realista es **modelo de referencia ejecutable** (golden model) con propiedades probadas, contra el que se testea diferencialmente la implementación real (ver punto C).

**Alternativas**: TLA+/Apalache, nuXmv (model checking es el estándar de la industria para interlocks y escala mejor que un checker unario). La ventaja de Bend es que la especificación, la prueba y el modelo ejecutable son el mismo archivo, y que el modelo se puede llamar desde node/Python.

**Veredicto: viable hoy.** Es la hipótesis con mejor relación valor/riesgo del lote.

### Punto 5 — Procedencia tipada

**¿El sistema de tipos permite indexar un tipo por un valor?** Sí, verificado (`env/provenance/`): `type Field<-ver: Nat, -geom: Nat> is Data` con índices borrados (`-`: cero costo en runtime), `solve(-g, seed) -> Field<3n, g>`, y un diagnóstico que exige `Field<3n, geom_a()>` rechaza `solve(geom_b(), …)` con `expected : Field<3n, 7n> / observed : Field<3n, 8n>`.

**Límite que un outsider no ve.** Los índices son términos **cerrados conocidos en compilación**. La procedencia real (hash de un archivo de geometría leído en runtime, versión de una biblioteca de datos) no se puede levantar al tipo sin un chequeo en runtime que produzca una `Sigma`/GADT, o sea: lo mismo que un `dataclass` con `assert` en Python. Lo que el tipo garantiza en compilación es el **cableado interno del código Bend** (que ningún camino del programa conecte un resultado de la geometría A con un consumidor de la B). Útil dentro de un pipeline escrito en Bend; inútil como contrato hacia afuera, porque hacia afuera todo es texto.

**Cómo lo haría alguien que conoce Bend 2.** Con paquetes por hash de contenido (`import 0x<hash>/…`): la identidad del código simbólico es criptográfica y la impone el compilador. El kernel emitido lleva el hash del generador en un comentario, y la procedencia de datos se maneja donde vive (manifiestos, DVC). **[no verificado acá: requiere `--publish` y red]**

**Veredicto: viable hoy, valor bajo.** La idea sirve pero con otra herramienta para datos (manifiestos con hashes / DVC); para código, los paquetes por hash de Bend son mejores que un SHA de git.

---

## 3. Puntos que no viste

### A. Pases de transformación probados sobre el IR de discretización

**Feature**: GADTs por truco de Ford + desplegado definicional + reescritura `%e`. El demo `proof_typed_eval` (136 líneas de programa, 19 de leyes, 59 de pruebas) prueba `eval(opt(e)) == eval(e)` y `opt(e) == lit(eval(e))` para un plegado de constantes con 3 reglas. Un generador de kernels de diferencias finitas es esto mismo: IR (`Var` con offset, `Const`, `Add`, `Mul`), un simplificador (plegado, identidades, CSE), un printer. La ley "el simplificador no cambia el significado exacto" convierte al generador en algo que sympy no puede ser: un compilador de esquemas con corrección demostrada. Es lo que hacen a mano (y sin pruebas) Devito, PSyclone, Firedrake/UFL. Es la razón por la que el punto 1 vale la pena en Bend.

### B. Certificados discretos por cómputo (reflexión)

**Feature**: el checker normaliza términos cerrados; `def T(b: Bool) -> Data` (True→Unit, False→Empty) y `T(check()) := Unit{}` es una prueba. Sirve para cualquier propiedad decidible de un objeto finito: que los pesos del stencil generado sumen el denominador (consistencia de orden 0), que los momentos impares se cancelen (orden 2, expresable sin signo como Σ_{k>0} c_k·k == Σ_{k<0} c_k·|k|), que una matriz de coeficientes sea simétrica, que todas las 3^k combinaciones de un interlock sean seguras. Cuesta una línea por certificado y el checker tarda milisegundos. Limitación: `Nat` unario en el checker, así que los números del certificado tienen que ser chicos (cientos, no millones).

### C. Modelo de referencia total + testing diferencial contra el código de producción

**Feature**: totalidad (terminación + `match` exhaustivo + sin null ni excepciones) + loader JS. Un programa Bend que chequea es una función total sobre sus tipos: sin caminos no definidos. Expuesto vía `node --import` (verificado), se puede llamar desde Python con inputs aleatorios (Hypothesis) y comparar contra el código real (Fortran/C++ de un sistema de protección, o la lógica de secuenciamiento de un tokamak). Es V&V clásico con un oráculo que además tiene sus propiedades probadas. No reemplaza nada: se agrega al lado.

### D. Identidad criptográfica del generador de código

**Feature**: `import 0x<hash>/main.bend` (hub por hash de contenido). Cada kernel emitido puede llevar el hash del generador que lo produjo, y ese hash lo verifica el compilador al importar, no un script. Procedencia de código, no de datos. Esfuerzo mínimo; **[no verificado acá]**.

---

## 4. Ranking

(a) valor potencial para el dominio (fusión: control, MPS/interlocks, V&V de códigos de seguridad, generación de kernels); (b) probabilidad de que la PoC cierre en un fin de semana **en esta máquina** (Windows, bun, sin nativo).

| # | Hipótesis | (a) Valor | (b) Cierra en un finde | Por qué |
|---|---|---|---|---|
| 1 | **1 + A + 2'**: generador de kernel con simplificador probado, más oráculo exacto = el mismo IR evaluado en `Nat` | Alto | Media-alta | El patrón existe (typed_eval). Riesgos: la prueba del simplificador si tiene más de 4–5 reglas; el oráculo entra en 48 bits solo con N ≈ 13 pasos (bignum como stretch). |
| 2 | **4**: interlock verificado (invariantes sobre trazas + certificados por cómputo) | Alto | Alta | Ya cerró en miniatura hoy: 155 líneas, contraejemplo encontrado por el checker, 2 iteraciones. |
| 3 | **C**: golden model total + testing diferencial vía loader | Medio-alto | Alta | Loader verificado; el trabajo es Python (Hypothesis) más que Bend. |
| 4 | **B**: certificados del stencil por cómputo | Medio | Alta | Una línea por certificado; se pega a la PoC 1 sin costo. |
| 5 | **3**: exploración combinatoria | Medio | Media | Sin paralelismo medible acá; sin cota global; el ángulo propio (completitud probada) es caro. |
| 6 | **D**: hash del generador | Bajo-medio | Alta (pero requiere red y `--publish`) | Trivial; no lo verifiqué. |
| 7 | **5**: procedencia tipada | Bajo | Alta | Mecanismo verificado; solo protege el cableado interno de Bend. |
| 8 | **2** tal como está escrito (`Nat` ilimitado) | — | Nula | `Nat < 2^48`. |

**Trade-off explícito**: las dos hipótesis de mayor valor (1+A+2' y 4) están casi empatadas; 4 es más segura, 1+A+2' prueba más cosas a la vez (emisión, interop, pruebas por inducción, oráculo, comparación numérica) y es la que responde la tesis "capa simbólica sobre capa numérica". Elijo 1+A+2' para Fase 1 y dejo 4 (ampliado con B y C) como candidata natural de Fase 2. Si la Fase 1 se traba en la prueba del simplificador, el fallback es reducir reglas hasta que cierre, no saltar a `@unsafe`.

---

## 5. Elección de la PoC de Fase 1

**Mantengo la ecuación de calor 1D**, con dos cambios respecto a lo descrito, ambos forzados por lo verificado arriba:

1. **Se agrega la ley del simplificador** (`eval(simplify(e), env) == eval(e, env)` sobre `Nat`, probada por inducción). Sin ella, la PoC produciría por construcción la conclusión "Bend no aporta nada sobre sympy". Con ella prueba la hipótesis más fuerte del ranking.
2. **El oráculo no es "racionales sobre `Nat` ilimitado"** sino diádicos no negativos dentro de 48 bits (plan A), con bignum propio como stretch (plan B).

### Qué se construye (`bend-spike/heat/`)

- `ir.bend`: `type Expr is Data: Var{k: Nat} | Const{c: Nat} | Add{a, b} | Mul{a, b}` (los offsets del stencil se codifican como índices sobre el vector de entorno; el denominador 2^e queda como un `Nat` fuera del árbol porque el esquema es lineal con coeficientes enteros no negativos: `u_i' = (2u_i + u_{i-1} + u_{i+1}) / 4` para r = 1/4). `eval(e, env: List<&2, Nat>) -> Nat`. `simplify`: plegado de constantes, `Mul(Const 1, x) → x`, `Add(Const 0, x) → x`, `Mul(Const 0, x) → Const 0`, y una CSE trivial si el tiempo alcanza. `build_stencil(r)` genera el árbol del paso desde la PDE discretizada.
- `LAWS.bend`: `simplify_sound` (inducción); `stencil_sum` (Σ c_k == 2^e, por cómputo con `{==}`); `stencil_symmetric` (Σ_{k>0} c_k·k == Σ_{k<0} c_k·|k|, por cómputo). `PROOF.bend` con las pruebas; gate `All terms check.`.
- `emit.bend`: `main` que imprime a stdout el módulo Python: `step(u)` en JAX (vectorizado con slices, `jnp.float64`), constantes como `c_k / 2**e`, y un comentario con el árbol simplificado. Ruta A de interop.
- `oracle.bend`: `main` que corre N pasos de `eval` por punto sobre numeradores `Nat` (exponente `Nat` común), grilla de 10 puntos con Dirichlet (bordes en 0), condición inicial cuantizada a m = 21 bits, e imprime una línea por paso con los numeradores y el exponente (decimal). Plan A: N = 13 (m + 2N ≤ 47). Plan B (stretch): `Big` con limbs `Nat` base 2^16, N = 200, testeado contra `int` de Python (no probado).
- `run.py`: invoca Bend (portable), guarda `kernel_heat.py`, lo importa, corre N pasos en JAX float64 con la **misma** condición inicial cuantizada (exacta en float64), parsea el oráculo a `fractions.Fraction`, y reporta.

### Qué se mide

| Métrica | Cómo | Qué cuenta como "cerró" |
|---|---|---|
| `bend PROOF.bend` | línea literal `All terms check.` | Las tres leyes cerradas sin `@unsafe` ni `?TODO`. |
| Kernel emitido corre | `run.py` importa `kernel_heat.py`, `jnp.float64` | N pasos sin error, dtype float64 verificado. |
| JAX f64 vs oráculo exacto | max abs error sobre los 10 puntos tras N pasos | ≤ ~N × 2·10⁻¹⁶ (error de redondeo acumulado; con N = 13 esperable ~10⁻¹⁵). Si sale 0 exacto, es porque los diádicos chicos son exactos en f64 y hay que decirlo. |
| Ambos vs analítica `e^{-απ²t} sin(πx)` | max abs error | Dominado por discretización espacial O(dx²) con dx = 1/9: esperable ~10⁻³ (el autovalor discreto (2/dx²)(1−cos π dx) es ~1% menor que π²), más O(dt) de Euler. El oráculo y JAX deben dar el **mismo** número a 10⁻¹⁵. |
| Tamaño de código | líneas de Bend (IR + leyes + pruebas + emisor + oráculo) vs un equivalente en Python con sympy + `Fraction` sin pruebas | Se reporta, sin objetivo: es información para el README. |

Si la prueba de `simplify_sound` no cierra con todas las reglas, se reduce el conjunto de reglas hasta que cierre y se documenta cuál quedó afuera y por qué. Si el bignum (plan B) no cierra, la PoC cierra igual con plan A.

---

## 6. Verificación de entorno

Corrida de referencia: `bash bend-spike/env/check_env.sh` (log completo en `env/check_env.log`, versiones pinneadas en `env/SETUP.md`).

| Ítem | Estado | Evidencia |
|---|---|---|
| Bend instalado | **2.0.6** vía bun 1.3.11 desde `~/.bend-src` (commit `67692d7f`, 2026-09-18). Sin binario nativo: Windows sin clang ni WSL. | `bend --version` → `bend 2.0.6`. La guía 2.0.6 difiere de la 2.0.5 de mi skill en una sola línea (descripción del comando `bend file.bend`): la skill sigue vigente. |
| JAX float64 | **jax 0.11.2, numpy 2.4.3, Python 3.14.3**, `jax_enable_x64` → dtype `float64`, CPU. Instalado hoy con `py -3.14 -m pip install jax`. | `PASS jax float64 enabled` |
| Interop A (stdout → .py) | **Probado**: `emit_hello.bend` imprime un kernel numpy, Python lo corre e imprime `[0.5]`. | `PASS interop A` |
| Interop B (`File.write`) | **Probado**: ruta por `BEND_OUT`; escribe el archivo; Python lo corre. | `PASS interop B` |
| Interop C (loader JS) | **Probado**: `node --import file:///…/main.ts app.mjs` importa `lib.bend`, llama `show(sample())` → `((2 * x) + 3)`. Con node hay que pasar la URL `file:///`; con bun `--preload` alcanza. | `PASS interop C` |
| Tope de `Nat` | **Confirmado** en runtime (`a Nat past the largest immediate 2^48-1`) y en el checker (stack overflow al expandir). | `PASS Nat capped` ×2 |
| Pruebas | Interlock: `All terms check.` en < 0.5 s. Procedencia: mismatch rechazado por tipo. | `PASS interlock`, `PASS provenance` |

Lo que **no** se puede hacer en esta máquina y afecta al spike: binarios nativos, GPU, paralelismo real, `File.read`, sockets, `IO.sleep`, y cualquier camino `Fail` de un efecto (llama a libc por `bun:ffi`). Nada de eso lo necesita la Fase 1 elegida.

---

**Estado: Fase 0 terminada. Espero confirmación de la PoC (calor 1D con ley del simplificador y oráculo diádico en 48 bits, plan A/B) antes de arrancar la Fase 1.**
