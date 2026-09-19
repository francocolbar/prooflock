# Fase 2 — Diseño: secuenciador de descarga verificado + testing diferencial

Fecha: 2026-09-18. Hipótesis cubiertas: **4** (lógica supervisora verificada), **B** (certificados por cómputo) y **C** (modelo de referencia total llamado desde Python para testing diferencial). Mismo estándar que la v2: especificación diseñada para el checker, leyes revisadas por instanciación exhaustiva antes de probar, un agente probador por archivo, test negativo, y un gate único (`py -3.14 v2/seq/run.py`).

## 1. El sistema (abstracción discreta de un pulso)

Un controlador de secuencia de descarga con interlocks de protección de máquina (MPS), reducido a lo discreto:

- **Fases**: `Idle → Charged` (bobinas TF a campo) `→ Prefill` (gas) `→ Breakdown` (rampa del solenoide central, iniciación) `→ FlatTop → RampDown → Idle`, más `Shutdown` (estado seguro) alcanzable desde cualquier fase.
- **Sensores** (booleanos en el estado, actualizados por eventos): `vac` (vacío ok), `tf` (campo toroidal nominal), `dens` (densidad en ventana).
- **Actuadores**: `gas` (válvula de prefill), `cs` (solenoide energizado), `heat` (calentamiento auxiliar).
- **Contadores**: `t_flat` (ticks en flat-top; límite `t_max = 4`: calentamiento de bobinas), `hb` (ticks sin heartbeat del PCS; límite `hb_max = 3`: watchdog).
- **Eventos** (15): `Tick`, `Heartbeat`, `Vac{ok}`, `Tf{ok}`, `Dens{ok}`, `CmdCharge`, `CmdPuff`, `CmdBreakdown`, `CmdFlatTop`, `CmdHeatOn`, `CmdHeatOff`, `CmdRampDown`, `Disruption`, `Abort`, `Reset`.

Reglas del controlador (`seq.bend`): cada comando se acepta solo en su fase y con sus permisivos (cargar solo con vacío; gas solo con bobinas cargadas, vacío y campo; breakdown solo tras prefill; calentar solo en flat-top con densidad); tras cada actualización de sensor se reevalúa el interlock (fase con gas o plasma sin vacío o campo ⇒ `Shutdown`; sin densidad ⇒ calentamiento apagado); en cada `Tick` corre el watchdog en las fases vigiladas (todas menos `Idle` y `Shutdown`) y el contador de flat-top; `Disruption` y `Abort` llevan a `Shutdown` desde cualquier estado; `Reset` vuelve a `Idle` desde `RampDown` o `Shutdown`.

**Escrito con forma de prueba**: cada handler hace `match` sobre una cosa; cada decisión que depende de un valor calculado (`is_plasma(phase)`, `Bool.and(vac, tf)`, `Nat.is_lt(1+hb, hb_max)`) se pasa a un helper como parámetro `Bool`, para que la prueba pueda hacer `match` sobre el mismo booleano ("veredicto con evidencia"). Sin IO: el mismo archivo se carga desde JavaScript como modelo de referencia.

## 2. Las leyes (`LAWS_SEQ.bend`, `LAWS_SEQ_FINITE.bend`) y su revisión

Cada invariante es una función `Bool` sobre el estado que lee un solo grupo de campos:

| Ley | Enunciado | Qué garantiza / qué no |
|---|---|---|
| `inv_init` (cómputo) | `inv_all(init()) == True` | El estado inicial es seguro. |
| `pres_l1` | `∀ s, e: l1..l6(s) ⇒ l1_field(step(s, e))` | **Gas o plasma solo con vacío y campo.** Cubre la pérdida de un sensor en cualquier fase con plasma, incluida `RampDown`. |
| `pres_l2` | ídem para `l2_heat` | **Calentamiento solo en flat-top con densidad en ventana.** Cubre `Dens{False}` durante el calentamiento y la salida de flat-top por cualquier vía. |
| `pres_l3` | ídem para `l3_cs` | **Solenoide energizado solo en breakdown / flat-top / ramp-down.** |
| `pres_l4` | ídem para `l4_gas` | **Válvula de gas abierta solo en prefill.** |
| `pres_l5` | ídem para `l5_flat` | **En flat-top, `t_flat < t_max`**: el pulso termina solo, para todo valor del contador (no solo los de la grilla). |
| `pres_l6` | ídem para `l6_hb` | **En fase vigilada, `hb < hb_max`**: tres ticks sin heartbeat nunca dejan la máquina en una fase con plasma. |
| `traces_safe` | `∀ trace: inv_all(run(trace, init())) == True` | **El teorema**: ninguna secuencia de eventos, de ningún largo, saca al sistema del conjunto seguro. Es lo que un operador quiere que sea verdad. |
| `shutdown_safe` | `l2, l3, l4 ⇒ l7_safe(s)` | Corolario: en `Shutdown` todo actuador está apagado. Se enuncia porque es lo que se lee en una revisión de seguridad; se prueba desde los otros. |
| `disruption_shuts_down`, `abort_shuts_down` | `∀ s: phase(step(s, Disruption)) == Shutdown` | Nivel de paso, para **todo** estado (no solo los alcanzables): la disrupción y el abort no tienen precondición. |
| `finite_check` (cómputo) | `check_small() == True` | Certificado por cómputo: 1792 estados (toda fase × toda combinación de sensores y actuadores × contadores en 0 y en el límite−1) × 18 eventos; el checker lo decide en 5.5 s. Más débil que `traces_safe` (contadores no universales) pero es una línea. |

Lo que las leyes **no** dicen: nada de tiempo real (los ticks son abstractos), nada de vivacidad (que el pulso *progrese*), nada de la planta física (los sensores son entradas arbitrarias: las leyes valen también para secuencias de sensores físicamente imposibles, lo cual es lo correcto para protección).

### Validación previa (instanciación exhaustiva)

`tests/laws_seq_smoke.bend` evalúa en runtime la preservación de las seis componentes, las dos leyes de paso y el corolario sobre **7168 estados × 18 eventos** (contadores en {0, 2, 3, 4}), en 0.6 s. Resultado: ninguna ley falsa; 452 de los 7168 estados satisfacen `inv_all`.

### Revisiones que cambiaron el diseño antes de probar

1. **Watchdog en `Idle`.** Primera versión: el heartbeat se contaba en toda fase. Consecuencia: `hb` crece sin límite en `Idle` y al cargar las bobinas la máquina entraría a una fase vigilada ya violando L6. Decisión: el watchdog corre solo en fases vigiladas (`is_watched`) y `CmdCharge` entra a `Charged` con `hb = 0`. Es un caso de "la ley correcta obliga a arreglar el diseño", no la ley.
2. **`RampDown` es fase con plasma.** Al escribir `is_plasma` la pregunta fue si la rampa de bajada necesita el interlock de vacío y campo. Sí: hay plasma hasta que la corriente llega a cero. Es exactamente el bug plantado en la implementación de producción (`rampdown_not_plasma`), y el test negativo `tests/seq_bug_PROOF.bend` muestra que el checker rechaza la ley para esa variante con el contraejemplo explícito.
3. **L7 derivado, no axioma.** "En `Shutdown` todo apagado" salió primero como componente del invariante; es consecuencia de L2–L4 y se dejó como corolario probado, para no tener dos verdades sobre lo mismo.
4. **Hipótesis por componente.** `inv_all` como una sola conjunción hacía que ninguna hipótesis redujera sin partir todos los campos (`Bool.and` reduce por su primer argumento). Cada ley de preservación recibe las seis componentes como hipótesis separadas y gasta solo las que necesita; `traces_safe` las junta con `and_l`/`and_r`/`and_intro`.
5. **Literales grandes.** `7168n` y `1792n` en el enumerador reventaron el parser ("a literal too large to expand"): los `Nat` literales se expanden en unario. Pasan a `U32.to_nat(7168)`.

## 3. Testing diferencial (hipótesis C)

- **Puente**: `bridge.mjs` carga `seq.bend` con el loader JS de Bend (`node --import file:///…/bend2/main.ts`) y atiende JSON por stdin: una traza → la trayectoria de estados y `inv_all` en cada paso; una lista de estados ajenos → `inv_all` sobre ellos. Un proceso persistente: ~1 ms por llamada.
- **Implementación de producción** (`prod/sequencer_prod.py`): escrita en Python desde la misma especificación en lenguaje natural, no desde el `.bend`, con dos bugs plantados del tipo que sobrevive a una revisión de código: `watchdog_off_by_one` (`>` en vez de `>=`: `hb` llega a `hb_max` en fase vigilada) y `rampdown_not_plasma` (perder vacío o campo en `RampDown` no apaga).
- **Dos oráculos**: (a) la trayectoria completa de producción es igual a la del modelo Bend; (b) los invariantes de Bend, evaluados por Bend sobre los estados que produce producción, valen. El segundo no necesita que el modelo sea "igual": detecta violaciones de la especificación directamente.
- **Dos generadores** (Hypothesis, 3000 ejemplos, con reducción al contraejemplo mínimo): trazas aleatorias puras, y trazas "guiadas" que arrancan con un prefijo del camino feliz y siguen al azar.
- **Configuraciones**: sin bugs (debe pasar), cada bug solo, ambos.

## 4. Plan de pruebas

```
PROOF_SEQ_A (pres_l1..l3) ─┐
PROOF_SEQ_B (pres_l4..l6) ─┴─> PROOF_SEQ (inv_init, traces_safe, shutdown_safe, disruption/abort)
PROOF_SEQ_FINITE (finite_check por cómputo)
```
Dos agentes en paralelo (cada uno tres leyes de preservación, un lema espejo por handler y por invariante), y las leyes de pegamento a mano. Una ley abierta no se puede usar como lema, así que `PROOF_SEQ` importa `A` y `B`.

## 5. Qué cuenta como "cerró"

`py -3.14 v2/seq/run.py` termina con `all gates and checks ok: True`:

1. `PROOF_SEQ.bend` y `PROOF_SEQ_FINITE.bend` imprimen `All terms check.` (12 leyes).
2. La grilla exhaustiva no tiene ninguna línea `FALSE`.
3. `tests/seq_bug_PROOF.bend` es rechazado.
4. Sin bugs: ningún contraejemplo en 3000 trazas con ninguno de los dos generadores. Cada bug plantado: encontrado por al menos un generador, con traza mínima y con los dos oráculos disparando.
