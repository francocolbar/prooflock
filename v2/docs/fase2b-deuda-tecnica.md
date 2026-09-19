# Fase 2b — Deuda técnica: el secuenciador rediseñado para pruebas baratas

Fecha: 2026-09-18. Reproducir: `py -3.14 bend-spike/v2/seq3/run.py` → `all gates and checks ok: True`.

## El problema

En la Fase 2 las seis leyes de preservación costaron 1593 líneas de prueba para 323 de modelo (5×), porque el checker no especializa un `case` comodín sobre los campos anidados de un registro: cada handler necesitó todos sus brazos por fase y por booleano, escritos uno por uno.

## El rediseño (`v2/seq3/seq3.bend`)

El estado se parte en **control finito** `Fin{phase, vac, tf, dens, gas, cs, heat}` y **dos contadores**. Toda decisión es finita: las dos comparaciones sobre los contadores entran al control como veredictos booleanos (`bt`, `bh`), y el control devuelve **comandos** a los contadores (`CKeep`, `CReset`, `CInc`) en vez de tocarlos. Entonces:

- `step_fin(f, e, bt, bh)` es una función sobre un dominio finito (448 estados × 18 eventos × 4 veredictos). Todo lo que se diga de ella lo decide el checker por cómputo, y como `bt`/`bh` recorren `Bool`, el certificado cubre **todo** valor de los contadores, no una grilla.
- Las dos "formas" de actualización (`t_shape`, `hb_shape`: si el próximo control corre un contador, el comando es `Reset`, o `Keep` desde un estado que ya lo corría, o `Inc` con veredicto "por debajo del límite") también son finitas.
- Lo único que necesita razonamiento simbólico es un lema genérico: `cnt_go(fl, apply(u, n), lim)` a partir de la forma y de la cota anterior. Un lema, tres casos, sirve para los dos contadores.
- Las leyes universales se obtienen del certificado por **reflexión**: una escalera de lemas chicos (uno por nivel de cuantificación: 7 fases, 6 booleanos, 18 eventos, 2 veredictos) que extraen de `check_fin() == True` la celda `prop(f, e, bt, bh) == True` para `f`, `e`, `bt`, `bh` arbitrarios.

Además: `same_as_old`, certificado por cómputo de que el nuevo modelo da exactamente los mismos estados que `seq/seq.bend` en 7168 estados × 18 eventos en runtime (0.6 s) y en 1792 × 18 en el checker (34 s, comparación estructural; con strings tardaba 5 minutos).

## Resultado

| | Fase 2 (`seq/`) | Fase 2b (`seq3/`) |
|---|---|---|
| Modelo (código) | 323 | 425 (los comandos y las formas suman ~100) |
| Enumerador / certificados | 106 | 223 |
| Leyes | 12 | 11 (las mismas garantías; L1–L4 en una sola ley `pres_fin`) + equivalencia |
| **Pruebas (código)** | **1593** | **323** (311 reflexión y pegamento + 12 certificados) |
| Pruebas / modelo | 4.9× | 0.76× |
| Iteraciones del probador | 2 + 4 + 2 | 5 (todas de sintaxis, ninguna de lógica) |
| Tiempo de chequeo | 0.3 s + 5.5 s | 34 s + 34 s |
| Testing diferencial | 2 bugs encontrados | idénticos (mismo puente, misma implementación de producción) |

Las 1593 líneas bajaron a 323: **cinco veces menos**, con las mismas garantías, y con un certificado extra de que el modelo no cambió de comportamiento.

## Lo que se aprendió

- **Diseñar para el certificado, no para la inducción.** Cuando todas las decisiones son finitas y la aritmética queda encapsulada en `apply`, el checker hace el trabajo de caso por caso solo; la prueba humana (o del agente) es la escalera de reflexión, que es genérica y no crece con el número de handlers. Agregar un evento o una fase agrega un brazo a un lema de nivel, no 7×64 casos.
- **El precio es tiempo de checker, no líneas.** El certificado se re-evalúa cada vez que se chequea el archivo (34 s), incluso importado. Para un modelo más grande hay que vigilar el tamaño del dominio: unas 10⁵ celdas es el techo práctico hoy.
- **Un `case _` comodín no refina el escrutinado en la hipótesis ni en el objetivo**: la única fricción del probador fue esa y la anotación de un `let` de constructor; cero iteraciones de lógica.
- **La equivalencia con el modelo anterior es barata y vale**: es lo que permite refactorizar un modelo verificado sin miedo. Debería ser un gate en cualquier rediseño.

## Veredicto

Deuda saldada. Con este diseño, modelar un interlock real (Fase 3 candidata) cuesta escribir el control finito y los comandos; las pruebas son casi las mismas 300 líneas para cualquier tamaño de control, y el checker decide el resto.
