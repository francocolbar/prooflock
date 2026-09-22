# Fase 3 — Diseño: la cadena de protección de JET (RTPS + PTN) bajo ley

Fecha: 2026-09-19, **revisión 4**. Estado: **implementado y cerrado**. El código es `v3/`; este documento es la
especificación desde la que se escribieron el modelo Bend (`jetprot.bend`) y el modelo Python de referencia
(`pymodel/jetprot_ref.py`), y se mantiene sincronizado con ellos. Cinco rondas de revisión adversarial (propia + seis
revisores independientes por perspectiva); registro de hallazgos en §9, con los que cambiaron el conjunto de leyes en
§9b. Fuente y
registro de hipótesis: `fase3-fuente.md` (**R-n**, **A-n**). Peligros, requisitos de seguridad y límites de la
evidencia: `fase3-seguridad.md`. Patrón: `v2/seq3/` (control finito + comandos a contadores + certificado por cómputo +
reflexión). Mismo estándar que la v2: instanciación exhaustiva antes de probar, un agente probador por archivo, test
negativo, gate único `py -3.14 bend-spike/v3/run.py`.

**Qué es el modelo.** El *Stop Selector* del RTPS de JET ([S1]: "the state machine and alarm processing logic") más la
interfaz al PTN y la secuencia de armado del DMS; no el *Stop Manager* (las formas de onda de sobreescritura). Certifica
la **regla** de escalada para cualquier configuración (matriz primaria, conexión del DMS), y la **instancia** publicada
por conformidad.

## 1. El modelo (`v3/jetprot.bend`)

### Control finito `Fin`

| Campo | Valores | Fuente |
|---|---|---|
| `prog` | `Breakdown < IpRise < Limiter < Xpoint < Heating1 < Heating2 < Termination` (instancia; orden total por A-5): la fase de **programa** de Level-1, la que indexa la Tabla 1 y que solo `Advance` mueve | R-1, R-5, A-5, A-24 |
| `jtt` | `Bool`: el JTT ya conmutó a las formas de onda de terminación; la fase de **onda** es `wave = jtt ? Termination : prog` (la leen el permisivo, la ventana del DMV, el fin de pulso, I2/I3) | R-4, [S2] §3.4, A-24 |
| `level` | `LNone < LJtt < LRtps < LPtn` (autoridad/irreversibilidad; PTN arriba por R-0, JTT/RTPS por A-1) | R-3, R-0, A-1 |
| `dms` | `DmsIdle < DmsArmed < DmsFired` | R-11, A-11 |
| `plasma_ok` | `Bool` | R-12, A-8 |
| `ip` | `Bool`: corriente de plasma sobre el umbral del DMV; gatea el **armado** del DMS | R-14, [S6], (A-22 retirada) |
| `nb`, `rf` | `Unit = Off | Ramping | Reduced | On` (`Reduced` = potencia parcial: un PINI/antena fuera, R-9; `Inhibited` retirado, A-26) | R-9, A-6, A-9, A-26 |

**10 752 estados** (revisión 2026-09-21; eran 2 688). `init() = Fin{Breakdown, jtt = False, LNone, DmsIdle, plasma_ok = False,
ip = False, Off, Off}`, `hb = 0`, `t_ack = 0`.

Contadores (fuera del control, con comandos `CKeep/CReset/CInc` como en seq3): `hb` (ticks sin heartbeat, límite
`hb_max = 3`, A-12) y `t_ack` (ticks esperando el acuse del DMS, límite `ack_max = 2`, A-11). Veredictos: `bh = (1+hb <
hb_max)`, `bt = (1+t_ack < ack_max)`. **Entran solo al brazo `Tick` de `step_fin`** (los demás brazos no los reciben):
verificado mecánicamente que ningún brazo no-`Tick` depende de ellos ni emite `CInc` (H13).

### Dos capas: alfabeto abstracto y alfabeto concreto

La configuración (qué respuesta pide cada disparador en cada fase, qué paradas arman el DMS) **no está dentro de
`step_fin`**: entra como carga del evento. Así las leyes valen para **toda** configuración, y la instancia entra por
una capa concreta de una línea por evento más las leyes de conformidad.

**Abstracto (28 variantes)**: `Advance` · `Stop{req: Level, dms: Bool}` ×8 · `Local{u}` ×2 · `HeatOn{u}` ×2 ·
`HeatOff{u}` ×2 · `Plasma{ok}` ×2 · `Ip{ok}` ×2 · `CommFault{dms, en}` ×4 (`en`: el chequeo está habilitado en la
instancia, A-21) · `Heartbeat` · `Tick{dms}` ×2 · `HeatAck` · `Reset`.

**Concreto (22 eventos)**: `Alarm{t}` con `t ∈ {Slow, Fast, Mhd, MhdB, Mchs, Dhs, BothHs, Blind}` ↦ `Stop{masked_table(i,
prog, t), dms_req(wave, t)}` (la tabla se lee en la fase de **programa**, la ventana del DMV en la de **onda**; `Blind`
sin respuesta si la máscara lo deshabilita); `CommFault` ↦ `CommFault{dms_on_commfault, mask(i).comm}`; `Tick` ↦
`Tick{dms_on_watchdog}`; `Ip{ok}` ↦ `Ip{ok}`; el resto, identidad. `step_c(i, s, e) = step(s, concretize(i, fin(s), e))`.

**Configuración (instancia 1, "Tabla 1 publicada")**: `table1` = R-5 + A-4; `dms_req(p, t) = t ∈ {Fast, Mhd, MhdB} ∧
dms_window(p)`, `dms_window = p ∈ {Xpoint, Heating1, Heating2, Termination}` (R-14); `dms_on_commfault = False`;
`dms_on_watchdog = False`; `heat_allowed(u, p) = p ∈ {Heating1, Heating2}`; `mask = {comm: True, blind: True}`. **Instancia
2, "MHD al PTN"**: igual, con `table1(p, Mhd) = table1(p, MhdB) = LPtn` para `p ≥ Xpoint` (para ejercitar el camino DMS que
[S6]/[S7] describen). **Instancia 3, "chequeos deshabilitados"**: la Tabla 1 con `mask = {False, False}` (A-21: una falla de
comunicación y una alarma ciega no hacen nada; certificada igual que las otras dos).

### Helpers compartidos

- `deenergize(u)`: `On | Reduced | Ramping → Off`.
- `ramp(u)`: `On | Reduced → Ramping`; el resto sin cambio.
- `reduce(u)`: `On → Reduced`; el resto sin cambio (una alarma local saca un PINI: potencia parcial, R-9).
- `to_ptn(f)`: `level := LPtn`; `nb, rf := deenergize`. Lo usan las reglas 1, 7 y 8; ningún camino a PTN pasa por otro lado.
- `arm_dms(f)`: si `dms = DmsIdle` **y `ip`**: `dms := DmsArmed` y `CReset` a `t_ack`; si no, sin cambio y `CKeep` (H6, P18, R-14).
- `soft_stop(f, req)`: `level := req`; `nb, rf := ramp`; si `req = LJtt`: `jtt := True` (la fase de programa no se mueve, A-24).

### Reglas (cada una un helper de un solo `match`; veredictos como parámetros booleanos)

1. `Stop{req, d}`: si `req = LPtn` → `to_ptn`, y `arm_dms` si `d` (también si `level` ya era PTN: una parada con DMS
   después de un PTN por falla de comunicación sí arma). Si no, si `req > level` → `soft_stop(req)`. Si no, sin cambio.
2. `Local{u}`: `u := reduce(u)`. Nada más cambia; contadores `CKeep` (R-9, F2).
3. `HeatOn{u}`: aceptado solo si `u = Off ∧ heat_allowed(u, wave) ∧ plasma_ok ∧ level = LNone` → `On`. Si no, sin cambio.
4. `HeatOff{u}`: `u := deenergize(u)`.
5. `Plasma{ok}`: `plasma_ok := ok`; si `¬ok`, unidades `deenergize`. 5b. `Ip{ok}`: `ip := ok` (R-14).
6. `Advance`: si `level = LPtn` o `phase = Termination`: identidad (sin re-rampa). Si no, fase siguiente; al entrar a
   `Termination`, unidades `ramp` (el fin natural del programa baja el calentamiento); al entrar a una fase `p` con
   `¬heat_allowed(u, p)` y `u = On`, `deenergize(u)` (la ventana se cerró). Con la instancia 1 solo ocurre el primer caso.
7. `CommFault{d, en}`: si `en`: `to_ptn` y `arm_dms` si `d`; si no, identidad, contadores `CKeep` (A-13, A-21, F3).
8. `Tick{d}`: **primero** el watchdog: si `¬bh ∧ level ≠ LPtn` → `to_ptn`, `arm_dms` si `d`; **si no**, el timeout del
   acuse: si `dms = DmsArmed ∧ ¬bt` → `DmsFired`. Las dos cláusulas son excluyentes (A5 de la revisión: solo se
   solapan en estados que violan I4).
9. `Heartbeat`: `CReset` a `hb`.
10. `HeatAck`: si `dms = DmsArmed` → `DmsFired`.
11. `Reset`: aceptado solo si `(level = LPtn ∨ wave = Termination) ∧ dms ≠ DmsArmed` → `init()`, contadores `CReset`
    (A-14). Si no: control **y contadores** sin cambio (`CKeep`).

Comandos a los contadores: `hb`: `CInc` en `Tick` mientras `bh ∧ level ≠ LPtn` (nivel del estado previo), `CReset` en
`Heartbeat` y `Reset` aceptado, `CKeep` en el resto; `t_ack`: `CReset` solo cuando `arm_dms` **transiciona** desde
`Idle`, `CInc` en `Tick` si `DmsArmed ∧ bt`, `CReset` en `Reset` aceptado, `CKeep` en el resto.

## 2. Las leyes (`LAWS_JETPROT.bend`, 75 + `LAWS_JETPROT_CONF.bend`, 137)

*Revisión 2026-09-21 (bloqueante 4): 64 → 75 leyes (P8 y E1 se retiraron con `Inhibited`; entraron F1a–F1e, F2a, F2d, F3b, F4,
IP1–IP4; ver la tabla al final de esta sección) y 117 → 137 de conformidad (la fila `Blind`, la instancia 3 y las máscaras).
Las filas marcadas “(b4)” cambiaron de enunciado.*

Formato de la Fase 2: enunciado, intención, límites. Notación: `s2 = step(s, e)`; `u2` la unidad `u` en `s2`. Las leyes
universales sobre `Ord × Fin × Ev × Bool × Bool` se prueban por reflexión sobre el certificado; las de contadores con el
lema genérico `cnt_go`; `traces_safe` por inducción en la traza.

**La regla que ya costó tres hallazgos (H3, H12, y otra vez en la ronda 2).** Las leyes de *preservación* llevan
`inv(s)` como hipótesis y en un estado inalcanzable son trivialmente ciertas. Las leyes de *paso* no la llevan: **deben
valer también en estados inalcanzables**, porque el certificado las decide en todo el dominio. Una ley de paso de la
forma "X(s2) implica Y(s2)" es sospechosa: casi siempre lo que se quiere es "no X(s) y X(s2) implica Y(s2)".

**Y la regla que costó la ronda 2 entera.** Un conjunto de leyes puede ser todo *negativo*: decir qué no puede pasar y
nunca qué tiene que pasar. Ese conjunto lo satisface el modelo que no hace nada. La mitad de las leyes de abajo existen
porque una revisión adversarial construyó ese modelo y lo hizo pasar (§9b).

### Invariante de estado `inv_all = I1 ∧ I2 ∧ I3 ∧ I4 ∧ I5 ∧ I6`, preservado por todo paso (teorema T)

| # | Ley | Enunciado | Intención | Límites |
|---|---|---|---|---|
| I0 | `inv_init` | `inv_all(init())` | El estado inicial es seguro. | — |
| I1 | `full_power_window` | `u ∈ {On, Reduced}` implica ventana de habilitación (fase de onda), `plasma_ok` y `level = LNone` (b4) | Una unidad que entrega potencia, plena o parcial, está en la ventana, con condiciones de plasma y sin ninguna parada en curso. | La ventana es la abstracción de PEWS plegada al secuenciador (A-5), no la ventana temporal por PINI real. |
| I2 | `ramping_context` | `u = Ramping` implica `plasma_ok`, `level ≠ LPtn`, y parada blanda o terminación | Solo se rampa bajo una parada blanda o en la terminación natural, nunca bajo PTN. | No dice cuánto baja ni en cuánto tiempo (A-15, A-19). |
| I3 | `jtt_in_termination` | `level = LJtt` implica `wave = Termination` (b4) | Un JTT en curso implica que las formas de onda de terminación están en marcha. | Una sola celda de la matriz produce JTT; C2 lo reporta. |
| I4 | `dms_only_under_ptn` | `dms ≠ DmsIdle` implica `level = LPtn` | El DMS solo se arma o dispara con el PTN activo, y por I1/I2 sin unidad con potencia. | Predicado de estado: armar y des-energizar son el mismo paso atómico; **no** verifica el acuse como secuencia (A-11). |
| I5 | `ack_bounded` | `dms = DmsArmed` implica `t_ack < ack_max` | La espera del acuse está acotada en ticks. | No dice que dispare (vivacidad) ni cuánto tarda. |
| I6 | `watchdog_bounded` | `level ≠ LPtn` implica `hb < hb_max` | Un RTPS mudo no deja la máquina sin protección. | No cubre fallas del propio PTN (A-17). |

**Corolarios probados** (lo que lee una revisión de seguridad): `ptn_no_heat`, `dms_no_heat`, `stop_no_full_power`,
`termination_no_full_power`. **Estado seguro**: PTN enclavado, ninguna unidad con potencia, sin mitigación a medio camino.

### Leyes de paso: qué no puede pasar (P1–P21)

| # | Ley | Qué garantiza |
|---|---|---|
| P1 | `latched` | Las paradas nunca se degradan. |
| P2 | `ptn_deenergizes` | **El paso que llega al PTN des-energiza**, por cualquier camino. Ley de cabecera. |
| P3 | `stop_reduces_power` | El paso que inicia una parada blanda saca a toda unidad de potencia, plena o parcial (b4). |
| P4 | `ramping_never_returns` | Una unidad en rampa no vuelve a entregar potencia en el pulso (b4). *(Derivada: implicada por P5 y P7.)* |
| P5 | `heat_permissive` | El permisivo de encendido: solo desde `Off`, en ventana, con plasma y sin parada. |
| P6 | `stop_overrides_heat` | Con una parada en curso ninguna unidad adquiere potencia (b4). *(Derivada: P5 y P7.)* |
| P7 | `heat_frame` | Ninguna unidad adquiere potencia sin su orden (b4). |
| ~~P8~~ | ~~`inhibit_latched`~~ | Retirada con `Inhibited` (A-26): ningún evento del pulso lo producía; habría quedado vacua. |
| P9 | `local_is_local` | Una alarma local **reduce** su unidad (`On → Reduced`, lo demás igual) y no toca nada más, contadores incluidos (b4; F2b). |
| P10 | `no_spurious_stop` | El nivel solo cambia por alarma, falla de comunicación, fin de pulso o watchdog vencido. |
| P12 | `commfault_ptn` | Perder la comunicación es una parada, desde cualquier estado, **cuando el chequeo está habilitado** (b4; F3a). |
| P14, P15 | `phase_monotone`, `dms_monotone` | Ni la fase de programa ni la de onda rebobinan (b4); el DMS no se desarma ni se "des-dispara". |
| P16, P17 | `dms_armed_on_demand`, `dms_frame` | El DMS se arma cuando una parada marcada llega al PTN con la corriente sobre el umbral, **y solo entonces** (b4). |
| P18 | `tack_frame` | Una alarma repetida no reinicia la espera del acuse. |
| P19 | `advance_frozen` | Bajo PTN el programa no avanza. |
| P20, P21 | `reset_guarded`, `reset_refused_mid_pulse` | El fin de pulso se acepta solo con el pulso terminado y sin mitigación armada. *(P20 está expresada con la guarda del propio modelo y por eso no detecta una guarda equivocada; P21 y D10 la escriben literalmente. Ver §9b.)* |
| T | `traces_safe`, `traces_safe_concrete` | **El teorema**: ninguna secuencia de eventos, sobre el alfabeto abstracto (cualquier configuración) o el concreto (cualquiera de las dos instancias), saca al sistema de I1–I6. |

### Leyes de demanda y de marco: qué **tiene** que pasar (D1–D18, E2–E11, V1)

Sin estas, el conjunto entero lo satisface un modelo que ignora casi todo. Cada una nació de un mutante que sobrevivía.

| # | Ley | Qué demanda | Mutante que la motivó |
|---|---|---|---|
| D1 | `stop_honoured` | El nivel pasa a ser el máximo entre el actual y el pedido: **una petición de parada se honra**. Dos lados, donde P1 tenía uno solo. | una parada PTN ignorada si no está cableada al DMS: convertía en no-op casi toda la Tabla 1 |
| D2 | `soft_stop_ramps` | Una parada blanda aceptada pasa a rampa toda unidad que entrega potencia, plena o parcial (R-4; b4). | la parada blanda que **corta** en vez de rampar |
| D3 | `advance_to_termination_ramps` | El fin natural del programa también rampa. *(Derivada de E4.)* | — |
| D4 | `watchdog_latches` | El watchdog enclava el PTN **independientemente** de si la instancia lo cablea al DMS. | el watchdog que solo actúa si está cableado |
| D5 | `hb_counts` | El contador del heartbeat corre mientras el PTN no está enclavado. *(Derivada de E6.)* | — |
| D6 | `hb_frame` | Solo un heartbeat o el fin de pulso aceptado resetean el watchdog. | cualquier evento reseteando el watchdog |
| D7, D8 | `ack_timeout_fires`, `ack_counts` | El timeout dispara el DMS y la espera cuenta. | el DMS que nunca dispara |
| D9 | `heatack_fires` | El acuse de la planta dispara el DMS. *(Derivada de E11.)* | el acuse ignorado |
| D10 | `reset_accepted_when_safe` | El fin de pulso **se acepta** con el pulso terminado y sin mitigación armada, **con la guarda escrita literalmente**. *(Puntualmente implicada por P20; su trabajo es romper la auto-referencia de P20.)* | una guarda de reset que también rechaza con el DMS disparado |
| D11 | `advance_is_one_step` | El programa avanza exactamente una fase. | el avance que salta dos |
| D12 | `phase_frame` | Nada más que `Advance` o `Reset` mueve la fase de **programa** (b4; el JTT mueve la de onda: F1d). | un RTPS stop que salta a terminación |
| D13, D14 | `plasma_is_input`, `plasma_frame` | Las condiciones de plasma son una entrada, y solo esa entrada las mueve. | la pérdida de plasma que no baja el flag |
| D15–D18 | `heatoff_is_local`, `heaton_is_local`, `heatack_frame`, `heartbeat_frame` | Cada comando toca lo suyo y nada más. | `HeatOff` que apaga las dos unidades |
| ~~E1~~ | ~~`inhibit_source`~~ | Retirada con `Inhibited` (A-26). El mutante que la motivó (la pérdida de plasma que *enclavaba* las unidades) hoy es N08, "la pérdida de plasma deja las unidades a potencia parcial", y lo atrapa I1. |
| E2 | `dms_fire_frame` | El DMS dispara solo por el acuse o por el timeout. | — |
| E3 | `stop_phase_exact` | Una parada mueve la fase de **onda** a Termination exactamente cuando un JTT aceptado lo pide (b4). | — |
| E4 | `advance_units` | Las unidades tras un `Advance` quedan completamente determinadas, en las seis transiciones y no en una. | el avance a una fase sin ventana que no cierra el calentamiento |
| E5 | `heartbeat_resets_hb` | **Un heartbeat siempre reinicia el contador del watchdog.** | el heartbeat ignorado bajo PTN: nada lo exigía, D18 enmarcaba el control y el otro contador, y D6 solo lo *permitía* |
| E6 | `hb_tick_exact` | El contador del watchdog en un `Tick` está exactamente determinado. | el contador que pasa de largo su límite sin que ninguna ley lo vea |
| E7, E8 | `tack_inc_frame`, `tack_reset_frame` | Solo lo que debe incrementa o reinicia la espera del acuse. | — |
| E11 | `heatack_exact` | El acuse es de dos lados. | — |
| V1 | `verdict_frame_step/_hb/_tack` | **Fuera del brazo `Tick` nada lee los veredictos de los contadores.** Convierte en teorema la suposición que legitima que el certificado chequee 23 de sus 28 columnas con un solo par de veredictos. | dos mutantes que vivían enteros en las esquinas de veredictos no examinadas |

### Leyes de fidelidad (bloqueante 4, 2026-09-21: F1–F3, IP)

Nacieron de la auditoría de fidelidad a [S1]/[S2]/[S6] (`docs/PLAN_MEJORAS_2026-09-21.md`): tres puntos donde el modelo
decía lo contrario de la fuente, más el umbral del DMV. F1b, F1d, F2a, F2d, F3b, IP1, IP3, IP4 son leyes de celda
(grupo `g_f` del certificado); F1a, F1c e IP2 se prueban directamente.

| # | Ley | Qué demanda | De dónde sale |
|---|---|---|---|
| F1a | `f1a_table_reads_prog` | Una alarma concreta lee la Tabla 1 en la fase de **programa**, sea cual sea `jtt` y el resto del estado; contra la transcripción independiente de la matriz y las máscaras del enumerador. | [S2] §3.4 "two views of time": el JTT re-etiquetaba la única fase y un `Slow` posterior leía la fila Termination (PTN no publicado) |
| F1b | `f1b_stop_keeps_prog` | Una parada nunca mueve la fase de programa. | ídem |
| F1c | `f1c_wave_ahead` | `wave ≥ prog` siempre (I7; por construcción de `wave`). | ídem |
| F1d | `f1d_wave_frame` | La fase de onda solo se mueve con `Advance`, un JTT aceptado o el fin de pulso. | ídem |
| F1e | `f1e_jtt_exact` | El flag de onda está exactamente determinado: lo enciende un JTT aceptado, lo apaga el fin de pulso, nada más lo toca. | la métrica de ajuste: con `prog = Termination`, dos estados que solo difieren en `jtt` son bisimilares y nada fijaba el flag (H36) |
| F2a | `f2a_local_reduces` | Una alarma local lleva una unidad a potencia plena a potencia **parcial**, nunca a apagada. | R-9: "the relevant PINI should be turned off [...] This should not preclude the neutral-beam system as a whole from continuing to deliver" |
| F2d | `f2d_reduced_never_returns` | Una unidad a potencia parcial no vuelve a potencia plena en el pulso. | sin ella, un `Plasma{True}` que restaurara `On` pasaba todas las leyes (hallado al validar el conjunto nuevo en Python) |
| F4 | `f4_units_frame` | Si el nivel de respuesta no cambia y el evento no es un comando de unidad, pérdida de plasma, `Advance`, `Reset`, parada PTN ni falla de comunicación habilitada, las dos unidades quedan como estaban. | la métrica de ajuste: ante `Ip` o `Plasma{True}` ninguna ley enmarcaba las unidades (antes lo hacían P8 y los cuatro valores de `Heat`) (H36) |
| F3b | `f3b_commfault_masked_is_noop` | Una falla de comunicación cuyo chequeo la instancia deshabilita es la identidad, contadores incluidos. | R-13 "*can* trigger the PTN", "features [...] not in use cannot cause problems"; [S6] las 5 disrupciones perdidas por inhibits |
| IP1 | `ip1_low_never_arms` | Por debajo del umbral de corriente el DMS no se arma, con ningún evento. | R-14; 7 de las 16 disrupciones perdidas de R-15 |
| IP2 | `ip2_arms_on_demand` | Con corriente, DMS ocioso y una alarma concreta que la instancia mapea a PTN y cablea al DMS dentro de la ventana, la alarma arma en el mismo paso (forma concreta de P16). | R-14, [S6] |
| IP3, IP4 | `ip3_ip_is_input`, `ip4_ip_frame` | El veredicto de corriente es una entrada y solo esa entrada (o el fin de pulso) lo mueve. | como D13/D14 para el plasma |

### Conformidad de la configuración (`LAWS_JETPROT_CONF.bend`, 137)

Las 28 celdas publicadas de la Tabla 1 (15 impresas + 13 por marca de ídem) y las 21 supuestas por A-4, separadas; la fila
`Blind` (A-25, 14 leyes); la instancia 2; la instancia 3 y las máscaras (`inst3_uses_table1`, `mask_inst*`,
`blind_masked_no_response`); el cableado del DMS; `fast_ptn` (tres instancias); y dos leyes sobre la capa concreta:

- `concretize_is_the_table`: `concretize` es la configuración **valor por valor**, contra una transcripción literal de
  la matriz como constantes propias. La primera versión de esta ley era **auto-referencial** — comparaba `concretize`
  contra una expectativa construida con la misma `table()` — así que detectaba una columna mal cableada pero no un
  valor equivocado ni una ventana corrida.
- `step_c_is_the_concrete_step`: `step_c` usa la instancia que le pasan, el orden de urgencia declarado y **la fase
  anterior a la transición**. En Bend resulta definicional (una línea con `{==}`) porque es la definición; en el modelo
  Python de referencia **no lo es**, y ahí viven los tres mutantes que la motivaron: leer siempre la matriz de la
  instancia 1 (desactiva en silencio la razón de existir de la instancia 2), leerla en la fase siguiente, o correr el
  paso bajo el otro orden de urgencia. Ninguno de los tres cambia el conjunto alcanzable, así que el teorema de trazas
  es ciego a los tres.

Leyes que se **enuncian y no se prueban** (límites declarados): la corrección de las alarmas (VTM/WALLS); los tiempos y
las formas de las rampas; la planta que acusa; independencia y diversidad entre las capas (A-17); entradas inválidas
(A-18); la respuesta secundaria (R-6, A-16); el bypass de las entradas y salidas del PTN y la ventana mal configurada (A-21;
las máscaras de los dos chequeos de fiabilidad sí se modelan). El umbral de corriente del DMV dejó de ser un límite
(A-22 retirada, IP1–IP4).

## 3. Tests negativos (`tests/jetprot_bug*.bend`, el checker debe rechazar con contraejemplo)

Cada uno planta un defecto o enuncia una ley falsa y el gate exige que el checker lo rechace **por refutar un `Bool`**
(no por un error de tipos, que imprimiría las mismas palabras) **y** citando el nombre de la ley del archivo.

| # | Archivo | Qué planta | Ley que lo atrapa |
|---|---|---|---|
| 1 | `bug1_deescalation` | una petición blanda reemplaza la respuesta sin comparar urgencia | P1 `latched` |
| 2 | `bug2_jtt_no_ramp` | el JTT mueve la fase a Termination sin sacar las unidades de potencia plena | preservación de I1 |
| 3 | `bug3_commfault_no_deenergize` | la falla de comunicación enclava el PTN sin des-energizar | P2 `ptn_deenergizes` |
| 4 | `bug4_dms_without_ptn` | una parada blanda arma el DMS | preservación de I4 |
| 5 | `bug5_law_p2_unconditional` | **una ley falsa sobre el modelo correcto**: P2 sin su condición "de llegada" | el propio checker, en 11 592 celdas espurias |
| 6 | `bug6_rearm_restarts_ack` | una alarma repetida reinicia la espera del acuse | P18 `tack_frame` |
| 7 | `bug7_rtps_keeps_full_power` | un RTPS stop sin efecto sobre el calentamiento | P3 `stop_reduces_power` |
| 8 | `bug8_certificate_false` | **el certificado afirmado falso**: obliga al checker a evaluarlo (38 s) | muestra que `{==}` se computa, no se saltea |
| 9 | `bug9_stop_is_noop` | una parada que llega al PTN se ignora si la instancia no la cablea al DMS (mutante M26 del banco adversarial) | D1 `stop_honoured` |
| 10 | `bug10_soft_stop_trips` | una parada blanda **corta** el calentamiento en vez de ramparlo (mutante M04; infidelidad a R-4) | D2 `soft_stop_ramps` |

Los negativos 1–4 y 6–7 son además regresiones de defectos que este proyecto tuvo de verdad (§9 H2, H6, H15, H16).

## 4. Testing diferencial (`v3/prod/jetprot_prod.py`, `v3/bridge.mjs`)

Implementación Python escrita desde `fase3-fuente.md` (no desde el `.bend`), con bugs plantados del tipo que sobrevive
a una revisión: `deescalation` (P1), `commfault_leaves_heating` (P2), `rtps_keeps_full_power` (P3), `plasma_ok_clears_inhibit`
(P8), `watchdog_off_by_one` (I6), `repeated_alarm_restarts_ack` (P18). Dos oráculos (trayectoria e invariantes de Bend
sobre estados ajenos), dos generadores (aleatorio y guiado por el camino feliz: `Advance`×4, `Plasma{ok}`, `HeatOn{Nb}`),
Hypothesis con reducción al contraejemplo mínimo. Igual que `v2/seq/run.py`. Además: cobertura de celdas del
certificado por generador (alimenta C2).

## 5. Gates de método

| # | Gate | Qué decide |
|---|---|---|
| C1 | `finite_check` / `finite_check_alt` | El certificado por cómputo: `cell_ok` sobre todo el dominio abstracto, **2 688 estados × 39 columnas = 104 832 celdas por orden de urgencia**, los dos órdenes. Cada celda calcula `step_fin` una vez y evalúa sobre ese resultado la preservación del invariante, las formas de los dos contadores y las 48 leyes de paso. Los veredictos se enumeran en las 5 columnas donde el checker no puede descartarlos simbólicamente (los dos `Tick`, `Reset`, `CommFault{True}`, `Stop{LPtn,True}`); que las otras 19 no los lean dejó de ser una suposición y es la ley `verdict_frame` (V1). |
| C2 | `vacuity` y **ajuste** | Por ley: celdas del certificado y estados alcanzables donde la hipótesis vale; falla en cero y avisa bajo umbral. Y la medida que reemplazó a una que era **cero por construcción**: sobre una muestra de 400 celdas alcanzables con semilla fija, en cuántas el conjunto de leyes **fija el estado siguiente de forma única** entre los 2 688 posibles, y lo mismo para los 9 pares de comandos a los contadores. Un conjunto de leyes que admite muchos sucesores prueba poco, por muchas leyes que tenga. |
| C3 | `sensitivity` (A-1) | El orden de urgencia entre las dos respuestas blandas es un **parámetro del modelo**, no una constante: toda ley se prueba para los dos órdenes (`finite_check` y `finite_check_alt`), y el gate reporta la diferencia de comportamiento. |
| C5 | `independent_recheck` | Todas las celdas del certificado calculadas por Bend (vía `bridge.mjs`) comparadas contra el modelo Python, y cada ley re-evaluada en Python **sobre el estado siguiente que produjo Bend**; más la capa concreta y la alcanzabilidad concreta `(Fin, hb, tack)`. |
| C6 | `mutation_score` | El **banco adversarial** de 62 defectos (`pymodel/mutants.py`), escrito por dos revisiones independientes cuyo encargo era romper el conjunto de leyes, más los 17 flags que se escribieron junto con las leyes. El segundo número es la medida débil y se reporta como tal: un banco elegido para calzar con las leyes siempre puntúa bien. |

Los tres certificados (`PROOF_JETPROT_FIN`, `_FIN_ALT`, `_COR`) son **bibliotecas, no gates**: cada uno descarga una
sola ley del archivo y por construcción reporta "TODOs" si se corre solo. `PROOF_JETPROT.bend` los importa y suministra
las demás; es el único que puede dar verde.

## 6. Instancias certificadas

| Instancia | `table1` | `dms_req` | Para qué |
|---|---|---|---|
| 1 "Tabla 1 publicada" | R-5 + A-4 | `Fast, Mhd, MhdB` × ventana `Xpoint..Termination` | conformidad P11; el DMS solo se arma por `Fast` (celda supuesta): C2 lo dice |
| 2 "MHD al PTN" | ídem, con `Mhd, MhdB → LPtn` para `prog ≥ Xpoint` | ídem | el camino que JET operó ([S6], [S7]): el DMS se arma por una celda **con base publicada** |
| 3 "chequeos deshabilitados" (2026-09-21) | = instancia 1, `mask = {comm: False, blind: False}` | ídem | la configuración de A-21: una falla de comunicación y una alarma ciega no hacen nada, y el resto sigue certificado |

Las leyes de paso, demanda, marco y fidelidad se prueban una vez sobre el alfabeto abstracto y valen para las tres
instancias; solo la conformidad (P11/P13, C1, `mask_*`) y C2 se corren por instancia. Registro de configuración por instancia: hash del modelo, de las matrices,
de las leyes, versión del checker, salida del gate, fecha (A-23).

## 7. Plan de pruebas

```
PROOF_JETPROT_FIN (C1, {==})  ──> PROOF_JETPROT (reflexión: I1-I4, P1-P19; contadores: I5, I6; I0, P20, P21)
PROOF_JETPROT_CONF_1/2 (P11 por instancia, {==} por celda)
tests/laws_jetprot_smoke.bend  (instanciación exhaustiva en runtime + C2, ANTES de probar)
tests/jetprot_bug_*.bend       (negativos, §3)
PROOF_JETPROT_FIN_ALT (C3), PROOF_JETPROT_FIN_LC (C4)
recheck.py (C5), mutants.py (C6)
```
Un agente bend-prover para `PROOF_JETPROT.bend` (escalera de seq3: un nivel por campo de `Fin` y por constructor de
evento; los 22 brazos no-`Tick` cierran por reducción). Presupuesto de checker: C1 ≈ 90 s, re-evaluado en cada archivo
que lo importa: gate total estimado 6–8 min más C3/C4.

### Tamaño y costo

| | Estados | Columnas | Celdas por orden | Producto completo |
|---|---|---|---|---|
| Certificado (`check_fin`), hasta 2026-09-21 | 2 688 | 39 | **104 832** | 2 688 × 24 × 4 = 258 048 |
| Certificado (`check_fin`), bloqueante 4 | 10 752 | 43 | **462 336** | 10 752 × 28 × 4 = 1 204 224 |
| Fase 2b (referencia) | 448 | 18 × 4 | 32 256 | — |

Los veredictos se enumeran en 5 de las 28 columnas (los dos `Tick`, `Reset`, `CommFault{True, True}`,
`Stop{LPtn,True}`), exactamente aquellas donde `reset_if` o `arms_now` quedan trabados sobre un `Fin` simbólico; que las
otras 23 no los lean es la ley V1. Tiempos de la revisión: ver `docs/STATUS_2026-09-21.md` §4.4.

| Artefacto | Líneas de código | |
|---|---|---|
| `jetprot.bend` | 1 116 | modelo + los predicados de las 48 leyes de paso |
| `enum_jetprot.bend` | 446 | certificado y escalera de cuantificadores |
| `LAWS_JETPROT.bend` + `LAWS_JETPROT_CONF.bend` | 409 + 242 | 64 + 117 leyes |
| `PROOF_JETPROT.bend` + `PROOF_JETPROT_CONF.bend` | 1 034 + 330 | reflexión, inducción y conformidad |
| `pymodel/jetprot_ref.py` | 485 | modelo de referencia y las leyes como predicados |
| `pymodel/mutants.py` | 526 | el banco adversarial de 62 defectos |
| `prod/jetprot_prod.py` | 132 | implementación de producción con 6 bugs plantados |
| `recheck.py`, `run.py`, `bridge.mjs`, `bridge_client.py` | 284 + 145 + 92 + 25 | gates y puente |

Costo en el checker: el certificado se re-evalúa en cada archivo que lo importa. `PROOF_JETPROT.bend` ≈ 140–160 s (era
83–113 s antes de las leyes de demanda); `PROOF_JETPROT_CONF.bend` 0,3 s; los tres certificados solos 14–19 s (`_COR`
0,3 s); el humo en runtime 5,6 s; el negativo del certificado 38 s, que es la evidencia de que `{==}` se computa y no
se saltea. Gate completo (`run.py`) ≈ 5–6 min.

## 8. Qué cuenta como "cerró"

`py -3.14 bend-spike/v3/run.py` → `all gates and checks ok: True`: (1) los PROOF imprimen `All terms check.`; (2) la
grilla exhaustiva sin `FALSE` y C2 sin ninguna ley vacía; (3) los seis negativos rechazados; (4) sin bugs, ningún
contraejemplo; cada bug plantado encontrado por algún generador con traza mínima y los dos oráculos disparando; (5) C5
coincide con C1 celda por celda y la alcanzabilidad concreta está contenida en `inv_all`; (6) C6 reportado; (7) C3 y
C4 corridos con su diferencia de comportamiento; (8) `fase3-trazabilidad.md` con la cadena peligro → función →
requisito → hipótesis → ley → prueba → negativo → diferencial → límite (`fase3-seguridad.md`), con R-6, R-11 (parcial),
R-14 (parcial) y R-15 marcados fuera de alcance con la razón.

## 9. Registro de las revisiones adversariales

Cinco rondas sobre el diseño y sobre el código. **Nota de independencia**: son pasadas automatizadas de la misma
familia de modelos que escribió el diseño; **no** constituyen evaluación independiente en sentido regulatorio, y no ha
habido evaluación humana independiente (ver `fase3-seguridad.md` §0). Todos los hallazgos quedaron como tests
negativos, gates, leyes o límites declarados; ninguno se resolvió debilitando una ley.

| Ronda | Perspectivas |
|---|---|
| 1 (2026-09-18) | propia + un revisor sobre el diseño |
| 2 (2026-09-19) | propia + cuatro revisores: bibliografía y citas, modelo ejecutable, seguridad funcional (IEC 61508/61513), operaciones de tokamak |
| 3 | verificación de gates, equivalencia de los cuatro modelos, afirmaciones documentadas, adversarial |
| 4 | segunda pasada adversarial sobre las leyes de demanda recién agregadas |
| 5 | verificación de la transcripción a Bend y del cierre de cada agujero |

### 9a. Hallazgos sobre el modelo y la especificación

| # | Hallazgo | Sev. | Resolución |
|---|---|---|---|
| H1 | `sec` (primaria/secundaria) **inalcanzable**: la única celda JTT está en `Heating2`, JTT salta a `Termination`, y esa fila no tiene RTPS. Su ley era vacua. | alta | Campo y ley eliminados; R-6 fuera de alcance (A-16); nació el gate C2. |
| H2 | `inv_all` **no inductivo** por tres caminos: JTT movía la fase sin tocar unidades; `Local{u}` bajo PTN dejaba `Inhibited` y la ley decía `= Off`; `CommFault` y watchdog llegaban al PTN sin apagar. | alta | `to_ptn` único con `deenergize` que preserva `Inhibited`; P2 como ley de paso. Negativos 2 y 3. |
| H3 | Ley de paso falsa en celdas espurias. | alta | El principio de §2, primera regla. |
| H4 | Aritmética del dominio equivocada. | media | §5 y §7 recalculados y verificados por dos revisores. |
| H5 | Camino muerto: con la Tabla 1, MHD nunca llega al PTN. | media | Reinterpretado con [S6]/[S7]: "None" es "sin respuesta primaria del RTPS", no "sin protección". Nació la instancia 2. |
| H6 | El DMS se re-armaba desde `Fired` y una alarma repetida reiniciaba la espera. | media | `arm_dms` solo desde `Idle`; P15, P18. Negativo 6. |
| H7 | `Reset` incondicional y `LocalClear` sin base textual: dos formas de desactivar una protección enclavada sin condición. | media | P20 con guarda; `LocalClear` eliminado (A-7). |
| H8 | `Advance` corría bajo PTN, contra R-0. | media | P19. |
| H9, H13 | Los veredictos a todos los brazos encarecían la reflexión; la irrelevancia fuera de `Tick` era un chequeo mecánico único. | media | Solo al brazo `Tick`; y en la ronda 3 dejó de ser suposición: es la ley V1. |
| H10 | Intenciones que sobre-afirmaban. | baja | Reescritas. |
| H11 | La única elección libre de A-1 es JTT vs RTPS; el orden ordena **autoridad**, no seguridad. | baja | A-1 con contra-hipótesis; el orden es un parámetro del modelo y toda ley se prueba para los dos. |
| **H12** | **P2 falsa en 11 592 celdas espurias**: el mismo error de H3 en una ley nueva. | alta | P2 en forma "el paso que llega a PTN"; **negativo 5**, que es una ley falsa sobre el modelo correcto. |
| H14 | El DMS estaba restringido solo negativamente: un modelo que nunca lo arma pasaba todas las leyes. | alta | P16, P17, P18. |
| H15 | **El peligro principal de la fuente no tenía ley**: un hotspot en calentamiento dispara un RTPS stop, y un RTPS stop no cambiaba nada observable. | alta | Unidad con estado `Ramping`; P3, P4, I2. Negativo 7. |
| H16 | **El JTT des-energizaba en el mismo paso**: contradice R-4 (el JTT *rampa*) y hacía al JTT más duro que el RTPS stop, contra el propio orden A-1. | alta | JTT y RTPS rampan; D2. Negativo 10. |
| H17 | Fidelidad de fuentes: una cita fabricada, un typo del original reparado en silencio, el argumento del PTN anclado a la cita más débil, 13 de 28 celdas por marca de ídem (no 6), un autor inexistente, licencias y DOIs faltantes, un derivado sin atribución. | media | `fase3-fuente.md` rev. 3; `sources/NOTICE`. |
| H18 | Encuadre: protección de máquina, no función de seguridad nuclear; Stop Selector, no Stop Manager; faltaban el análisis de peligros y la capa de requisitos entre las citas y las leyes; seis hipótesis implícitas. | alta | Encabezado de `fase3-fuente.md`; A-18…A-23; `fase3-seguridad.md`. |
| H19 | Operaciones: fases y ventana son instancia; el armado del DMS es configuración con ventana y umbral; la razón real del apagado previo al DMV es la presión del ducto y las líneas de antena; el mode lock sí protege en JET. | media | Capa abstracta/concreta; A-10, A-22; R-14, R-15; instancia 2. |
| H20 | C3 no tenía señal ("sobreviven todas"). | media | Reporta la diferencia de comportamiento; y el orden pasó a ser parámetro probado. |
| H21 | `check_env.sh` roto al vendorizar el runner (un espacio en la ruta del repo partía la variable sin comillas): 9 fallas de 11. | alta | Array `BEND=(bash "$HERE/bend.sh")`. 11 PASS / 0 FAIL. |
| H22 | Tres gates más flojos de lo que parecían: `run.py` aceptaba un error de tipos como rechazo válido, el criterio del humo era una subcadena, y C3 no podía fallar. | media | Criterios estrictos: refutación de un `Bool` **y** el nombre de la ley del archivo; conteo de líneas; C3 reporta diferencia. |
| H23 | El modelo Python "independiente" era un port del Bend, no una lectura del documento: tenía una ley que el documento no contiene y copiaba descomposiciones internas del `.bend`. | alta | Afirmación degradada en todos lados; C5 se describe como **re-ejecución en otro lenguaje**, no como diversidad N-versión; una implementación genuinamente independiente desde el documento (producida por la auditoría) confirmó el resultado. |
| H24 | El documento y los tres modelos divergían en dos puntos (ambos inalcanzables) y había una ambigüedad real en la precedencia al entrar a `Termination`. | media | Documento corregido; la precedencia escrita. |
| H25 | `fast_ptn` (P13) estaba citada como ley en el diseño, la trazabilidad y un requisito de seguridad, **y no existía**. | alta | Escrita y probada (42 brazos: 7 fases × 3 estados del DMS × 2 instancias). |
| H26 | Colisión de numeración: P21 significaba dos leyes distintas en cuatro documentos y el código. | media | El teorema es **T**; P21 es `reset_refused_mid_pulse`. |
| H27 | Números viejos en los documentos y un `results.json` citado que no existía. | media | Todos medidos de nuevo; §7. |

### 9b. Hallazgos que cambiaron el conjunto de leyes

Los tres más importantes del proyecto, porque no son errores de transcripción sino del **método**.

| # | Hallazgo | Cómo se encontró | Resolución |
|---|---|---|---|
| **H28** | **El conjunto de leyes era todo negativo.** Decía qué no puede pasar y nunca qué tiene que pasar, así que lo satisfacía un modelo degenerado: ignorar toda parada no cableada al DMS, cortar en vez de rampar, no contar el watchdog y no aceptar nunca el fin de pulso. Ese modelo pasaba **las leyes y el gate de vacuidad juntos**. 16 de 37 mutantes plausibles sobrevivían. | una revisión adversarial construyó el modelo degenerado y lo hizo pasar | 18 leyes de demanda y de marco (D1–D18). Banco 21/37 → 36/37; ajuste 12 % → 46 %. |
| **H29** | Las leyes de demanda dejaban **ocho agujeros**, y 11 de 25 mutantes nuevos sobrevivían. Los peores: nada exigía que un heartbeat reseteara el watchdog; el contador podía pasar de largo su límite sin que ninguna ley lo viera; y **nada restringía `step_c`**, de modo que leer siempre la matriz de la instancia 1 desactivaba en silencio la instancia 2 sin cambiar el conjunto alcanzable. | segunda pasada adversarial, con 25 mutantes apuntados a las costuras de las leyes nuevas | E1–E11, `step_c_is_the_concrete_step`, V1. Banco 50/62 → **61/62**; ajuste 46 % → **95 %**. |
| **H30** | Dos leyes **auto-referenciales**: P20 expresa la guarda del fin de pulso con la guarda del propio modelo (así que la satisface cualquier guarda), y la primera ley de `concretize` comparaba la función contra una expectativa construida con la misma tabla (así que no detectaba un valor equivocado). | análisis de fuerza de cada ley, quitando una guarda por vez y buscando contraejemplos | D10 y E8 escriben la guarda literalmente; la matriz va transcrita como constantes propias. |
| H31 | La métrica de cobertura de C2 era **cero por construcción**: `P1`, `P14` y `P15` tienen hipótesis `e ≠ Reset`, así que toda celda quedaba "cubierta". Y el banco de 17 mutantes estaba elegido para calzar con las leyes. | la misma revisión | Métrica de **ajuste** (cuántos de los 2 688 sucesores admite el conjunto de leyes, más los 9 pares de comandos), y banco adversarial de 62 escrito por revisores cuyo encargo era romper. |
| H32 | Una ley propuesta por la auditoría (`dms ≠ DmsIdle ⇒ plasma_ok`) es **físicamente falsa y no inductiva**: perder el plasma con el DMS armado la viola en un paso, y ese paso es justamente para lo que existe la mitigación. | la propia auditoría, al verificarla antes de recomendarla | No se agregó; la preocupación subyacente (estados alcanzables con el DMS disparado y sin plasma) queda como límite declarado. |
| **H33** | **Fidelidad, ronda 6 (2026-09-21, seis auditores + revisión directa):** el JTT re-etiquetaba la única fase y `concretize` leía después la fila Termination de la Tabla 1 (un `Slow` posterior escalaba a PTN sin base publicada); la protección local apagaba la unidad entera cuando R-9 dice *un PINI*; `CommFault` era PTN incondicional cuando [S1] dice "*can* trigger" y [S6] documenta disrupciones perdidas por inhibits; el umbral de corriente del DMV quedaba fuera (7/16 misses de R-15). | auditoría de fidelidad contra [S1]/[S2]/[S6] | Bloqueante 4: `prog`/`jtt` (A-24), `Reduced` (A-6/A-7), `CommFault{dms, en}` + `Blind` + máscaras (A-13/A-21/A-25), `ip` (A-22 retirada); leyes F1a–F1d, F2a, F2d, F3b, IP1–IP4. |
| H34 | Con la protección local reduciendo, `Inhibited` quedó **inalcanzable**: P8 tenía 0 celdas alcanzables (vacua por construcción, lo que C2 rechaza) y el diseño proponía conservarlo "para R-10". | al validar el dominio nuevo en Python antes de tocar Bend | Se retiró el valor (A-26) y con él P8 y E1; el certificado bajó de 16 800 a 10 752 estados. |
| H35 | Un `Plasma{True}` que devolviera una unidad de `Reduced` a `On` pasaba **todas** las leyes: I1 ya se cumplía, P7 solo mira unidades sin potencia y ninguna ley enmarcaba las unidades ante `Plasma{True}`. | la misma validación | F2d (`reduced_never_returns`); el bug plantado `plasma_ok_restores_reduced` en `prod/`. |
| H36 | La métrica de **ajuste** cayó de 93 % a 82 % con el modelo nuevo: sin P8 y con `Reduced`, nada enmarcaba las unidades ante los eventos que no las tocan (`Ip`, `Plasma{True}`, un `Tick` sin watchdog, una parada rechazada), y `jtt` quedaba libre con `prog = Termination`. | la primera corrida `all` del bloqueante 4, y un diagnóstico de qué campos variaban entre sucesores admisibles | F4 (`units_frame`) y F1e (`jtt_exact`): ajuste 99 %, media 1,01 admisibles. Lección: la métrica de ajuste vale más que el conteo de leyes; una revisión de tipos deja huecos que ninguna ley existente ve. |

### 9c. Lecciones sobre el método, para el preprint

1. **Un certificado no es cobertura.** Decir "104 832 celdas decididas" suena a exhaustividad y no dice nada sobre si las leyes exigen algo. La medida honesta es el **ajuste**: cuántos sucesores admite el conjunto. Empezó en 15 de 2 688 y terminó en 1,08.
2. **Un puntaje de mutación solo vale si el banco es adversarial.** Con el banco escrito junto a las leyes: 17/17 desde el principio. Con bancos escritos para romperlas: 21/37.
3. **Las leyes de paso valen en todo el dominio, también en lo inalcanzable.** Tres veces el mismo error.
4. **Una ley no debe citar al modelo en su conclusión.** Si la guarda del modelo aparece en la ley, la ley no puede detectar una guarda equivocada.
5. **El patrón de seq3 no escala tal cual.** Bend compara formas normales completas: proyectar desde el certificado entero con argumentos simbólicos costaba 15–30 minutos. Rebanarlo en 56 piezas lo bajó a minutos.
6. **Lo que en Bend es definicional, en otra implementación no lo es.** `step_c_is_the_concrete_step` cierra con `{==}` en Bend porque es la definición; en el modelo Python de referencia es una obligación real, y ahí viven los mutantes que la motivaron. Por eso la mutación y el testing diferencial operan del lado que puede desviarse.
