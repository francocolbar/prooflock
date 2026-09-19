# Fase 2 — Hallazgos: secuenciador de descarga verificado + testing diferencial

Fecha: 2026-09-18. Reproducir: `py -3.14 bend-spike/v2/seq/run.py` → `all gates and checks ok: True` (unos 20 s; números en `v2/seq/results.json`). Diseño y revisión de las leyes en `fase2-diseno.md`.

## Qué se construyó (`bend-spike/v2/seq/`)

| Pieza | Archivo | Líneas (código) |
|---|---|---|
| Modelo: 7 fases, 15 eventos, controlador con interlocks, 6 invariantes decidibles, `run` | `seq.bend` | 449 (323) |
| Enumerador exhaustivo del espacio finito | `seq_enum.bend` | 139 (106) |
| Leyes: 11 (preservación por componente, teorema de trazas, corolario, dos de nivel de paso) + 1 certificado finito | `LAWS_SEQ.bend`, `LAWS_SEQ_FINITE.bend` | 119 (84) |
| Pruebas L1–L3 (agente, 70 defs, 2 iteraciones, el archivo completo pasó a la primera) | `PROOF_SEQ_A.bend` | 856 (750) |
| Pruebas L4–L6 (agente, 69 defs, 4 iteraciones) | `PROOF_SEQ_B.bend` | 843 (741) |
| Pegamento: hechos de `Bool`, `inv_init`, corolario, disrupción/abort, **teorema de trazas** (a mano, 2 iteraciones) | `PROOF_SEQ.bend` | 132 (96) |
| Certificado finito por cómputo: `{==}` | `PROOF_SEQ_FINITE.bend` | 8 (6) |
| Puente al loader JS de Bend (modelo de referencia como servicio JSON) | `bridge.mjs` | 38 (27) |
| Implementación "de producción" en Python con dos bugs plantados | `prod/sequencer_prod.py` | 113 (90) |
| Driver: gates + Hypothesis (2 generadores × 4 configuraciones × 2 oráculos) | `run.py` | 171 (143) |
| Instanciación exhaustiva y test negativo | `tests/laws_seq_smoke.bend`, `tests/seq_bug_PROOF.bend` | 62 (44) |

Total Bend: 2106 líneas de código, de las cuales 1593 son pruebas (12 leyes, 152 definiciones de prueba). Chequeo: 0.3 s el teorema, 5.5 s el certificado finito.

## Qué cerró

1. **El teorema de trazas.** `∀ trace: inv_all(run(trace, init())) == True`: ninguna secuencia de eventos, de ningún largo, con cualquier valor de los contadores, saca al sistema del conjunto seguro. Gas o plasma solo con vacío y campo; calentamiento solo en flat-top con densidad; solenoide y válvula solo en sus fases; flat-top acotado; watchdog acotado. Más: en `Shutdown` todo apagado (corolario), y disrupción o abort llevan a `Shutdown` desde **todo** estado, alcanzable o no.
2. **El certificado por cómputo.** 1792 estados × 18 eventos (unas 32 000 evaluaciones del paso más los invariantes) decididos por el evaluador del checker en 5.5 s con una prueba de una línea. Antes, la instanciación en runtime sobre 7168 × 18 corrió en 0.6 s: la misma técnica sirve para revisar leyes antes de probarlas y para certificar espacios finitos sin escribir inducciones.
3. **El test negativo.** La variante con el bug de `RampDown` (el mismo que producción) es rechazada por el checker con el contraejemplo explícito: `expected False{} / observed True{}` en el estado `RampDown` con vacío perdido.
4. **Testing diferencial.** El modelo Bend, cargado en node con el loader JS, atiende ~1 ms por consulta. Contra la implementación Python con bugs plantados, Hypothesis con 3000 ejemplos por configuración:

| Configuración | Generador aleatorio | Generador guiado (prefijo del camino feliz) |
|---|---|---|
| sin bugs | sin contraejemplo | sin contraejemplo |
| `watchdog_off_by_one` | **encontrado**, traza mínima de 5 eventos: `Vac+ CmdCharge Tick Tick Tick` → `Charged` con `hb = 3` | encontrado, misma traza |
| `rampdown_not_plasma` | **no encontrado en 3000 trazas** | **encontrado**, traza mínima de 7 eventos: `Vac+ CmdCharge Tf+ CmdPuff CmdBreakdown CmdRampDown Vac-` → `RampDown` con `vac = False` |
| ambos | encontrado el del watchdog | encontrados ambos |

En cada hallazgo disparan los **dos** oráculos: la trayectoria difiere del modelo, y los invariantes de Bend evaluados sobre los estados de producción fallan. El segundo oráculo es el importante: no exige que producción sea "igual" al modelo, exige que cumpla la especificación.

## Hallazgos

- **El testing aleatorio no llega a los estados profundos; la prueba sí.** El bug del watchdog está a 3 eventos del inicio y el generador aleatorio lo encuentra en segundos. El bug de `RampDown` necesita seis eventos en orden sin que se cuele un abort, una disrupción o tres ticks sin heartbeat: 3000 trazas aleatorias no lo tocan. Con un generador guiado (estado consciente) aparece en 200 consultas. `pres_l1`, en cambio, lo cubre para todo estado sin generar nada: el test negativo lo muestra en un solo `{==}`. Es la división de trabajo correcta: la prueba para la especificación, el testing diferencial para la implementación que no está en Bend.
- **El costo de las pruebas es la explosión de casos, literal.** Los dos archivos de preservación suman 1500 líneas para seis invariantes porque el checker no especializa un `case s2:` comodín sobre los campos anidados de un registro: cada handler necesitó sus 7 brazos por fase y sus brazos por booleano, escritos uno por uno. Sin tácticas, "por casos" quiere decir "todos los casos, a mano". Los agentes lo hicieron en 2 y 4 iteraciones porque el código estaba escrito para eso, pero la relación pruebas/modelo es 5×, contra 1.8× en la Fase 1.
- **La alternativa híbrida está a la vista.** El certificado por cómputo cubre la parte finita del estado en una línea; lo único que necesita inducción son los contadores (L5, L6). Un diseño que separe el registro en parte finita y contadores, con el certificado para la primera y dos lemas para los segundos, bajaría las 1500 líneas a menos de 200. Queda como siguiente iteración: acá se prefirió el teorema universal completo para medir su costo real.
- **Veredicto con evidencia.** Las decisiones sobre contadores (`Nat.is_lt(1+hb, hb_max)`) no se pueden `match`ear en una prueba; se pasan como `Bool` con una ecuación que las ata al estado. Para L6 la evidencia tuvo que enunciarse como `l6_hb` del estado ya incrementado, no como la comparación cruda, para poder entregarla al lema genérico del contador de flat-top. Es el idioma que hace probables las propiedades con aritmética sin tener aritmética en la prueba.
- **El interlock rompe el patrón "preservar la hipótesis".** Para L1, tras `Vac{False}` en una fase con plasma, el estado intermedio (antes del interlock) viola L1 y no hay hipótesis que preservar: el lema tuvo que cuantificar sobre los booleanos calculados con ecuaciones `p == is_plasma(phase)`, `ok == Bool.and(vac, tf)` y reescribir. Fue el paso más difícil del agente A.
- **Las leyes obligaron a arreglar el diseño dos veces antes de probar nada**: el watchdog no puede correr en `Idle` (o L6 es falsa al cargar las bobinas) y `RampDown` es una fase con plasma. Las dos salieron de escribir la ley y preguntarse si era verdad, no del checker.
- **Cosas chicas que cuestan una vuelta**: literales `Nat` grandes (`7168n`) revientan el parser (`U32.to_nat`); un evento usado dos veces en la inducción de trazas necesita `+e`; una hipótesis de igualdad sí se puede marcar `+` y usar seis veces.

## Veredicto (hipótesis 4, B y C)

**Viable hoy y sólido.** Un secuenciador con interlocks de protección de máquina, con todos sus invariantes de seguridad probados para toda traza, que además corre como modelo de referencia desde Python y detecta bugs plantados en una implementación independiente. Costo: 2106 líneas de Bend, 1593 de pruebas; dos agentes probadores y un pegamento a mano; unas cuatro horas de reloj. Lo que no cubre: tiempo real, vivacidad, la física de los sensores. Lo que cambiaría en la siguiente vuelta: la separación finito/contadores para que el certificado por cómputo haga el 90 % del trabajo.

Para el proyecto de fusión: esto es lo que un equipo de protección de máquina querría tener por cada interlock: la especificación ejecutable, la prueba de que la especificación es segura, y el oráculo contra el que se prueba el PLC real. Los tres salen del mismo archivo `.bend`.
