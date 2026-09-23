# Catálogo de leyes del caso JET (RTPS + PTN) — código, explicación y origen

Fecha: 2026-09-22; revisado el 2026-09-23 (dos veces). Cubre los cuatro archivos de leyes de `v3/`:

| Archivo | Leyes | Qué prueba |
|---|---|---|
| `LAWS_JETPROT.bend` | 81 | invariantes, leyes de paso (P), de demanda y marco (D, E), de fidelidad (F, IP), leyes con nombre para lo que P1 y D1 dicen sobre el PTN y el stop primario (revisión 4), corolarios |
| `LAWS_JETPROT_CONF.bend` | 143 | conformidad de las cuatro instancias de configuración con la Tabla 1 publicada, las celdas asumidas y las tablas secundarias |
| `LAWS_JETPROT_LIVE.bend` | 2 | respuesta acotada sobre trazas (watchdog y DMS) |
| `LAWS_JETPROT_SOUND.bend` | 8 | solidez (soundness) de los predicados Bool de igualdad |
| **Total** | **234** | |

Fuentes de origen: `docs/phase3-sources.md` (citas textuales **R-0…R-15** de [S1] Stephen 2011, [S2] Waterhouse 2025, [S3] Edwards 2019, [S6] Reux 2013, [S7] Stuart 2021; desde la revisión 4 también [N1] De Tommasi 2013, citado con páginas del PDF del preprint; hipótesis **A-1…A-35**) y `docs/phase3-traceability.md`.

**Revisión 4 (2026-09-22).** Seis leyes nuevas en `LAWS_JETPROT.bend` (cinco leyes con nombre propio para lo que P1 y D1 dicen sobre el PTN y el stop primario, §2.10: `p1a_ptn_latched` y `d1b_primary_honoured` reformulan fuentes de JET, sobre todo [N1]; `d1a_ptn_honoured`, `p1b_stop_never_cleared` y `piw_after_ptn_is_noop` juntan un enunciado de JET con una formalización nuestra; y `inst4_second_alarm_ptn`) y seis en `LAWS_JETPROT_CONF.bend` (la instancia 4 y las tablas secundarias, §3.10). Además, varias etiquetas de origen dicen ahora qué parte de la ley es **hecho de JET** y qué parte es **política nuestra**. Una auditoría posterior del mismo día pasó a MIXTA diez leyes que figuraban como JET, porque cada una afirma algo que ninguna fuente dice (§0): `p1b_stop_never_cleared`, `d1a_ptn_honoured`, `piw_after_ptn_is_noop`, `dms_window_Termination` y, en una segunda pasada con la misma regla, `ptn_deenergizes`, `ptn_no_heat`, `stop_reduces_power`, `d2_soft_stop_ramps`, `heat_permissive` y `advance_frozen`. También marcó como derivadas P4 y P6 (§6.5); el resto conserva su categoría. Una revisión del 2026-09-23 aplicó la misma regla a cuatro leyes más: `dms_no_heat` pasó de JET a MIXTA (que el calentamiento siga apagado después de la inyección es A-9), y `dms_monotone`, `dms_frame` y `f3b_commfault_masked_is_noop` pasaron de HIP a MIXTA, porque además de su parte nuestra enuncian algo que JET publica ([S6], R-14, [S1]; §0).

## 0. Criterio de clasificación del origen

Cada ley lleva una etiqueta:

- **JET** — el contenido de la ley es una cita textual R-n, una frase de [N1] o una celda impresa de la Tabla 1. Si la cita desapareciera, la ley perdería su justificación. Una salvedad declarada en la entrada que no agrega contenido (por ejemplo, la identificación de la columna "Slow", A-31) no cambia la categoría, y tampoco la cambia la abstracción sin tiempo del modelo (A-15: todo efecto de un evento ocurre en un paso y los plazos se cuentan en ticks), que es común a todas las leyes. Si la ley afirma algo que ninguna fuente dice, es MIXTA: una extensión (por ejemplo, el apagado del calentamiento en todo camino al PTN, cuando la fuente lo documenta sólo para las salidas que disparan el DMS) o una formalización (por ejemplo, qué comando recibe cada contador).
- **HIP** — el contenido es una decisión de modelado nuestra (A-n). Puede estar *motivada* por una cita, pero lo que la ley afirma no está escrito en la documentación de JET. Lo que agrega una ley de marco (frame, "nada más se mueve") es siempre nuestro: JET no publica "y nada más pasa". Una ley que es sólo marco es HIP; si además enuncia algo que JET publica, es MIXTA (`local_is_local`, `advance_frozen`, `piw_after_ptn_is_noop`, `dms_frame`, `f3b_commfault_masked_is_noop`). `e2_dms_fire_frame` se llama "frame" pero no es un marco en este sentido: su "sólo" lo publica R-11 (§2.5).
- **MIXTA** — la mitad positiva viene de una cita y la forma exacta (orden, política, qué fase se lee, a qué caminos o unidades se extiende) es nuestra.
- **TÉCNICA** — existe por la mecánica de la prueba (certificado, reducción de columnas, solidez de predicados). No dice nada sobre JET.

Recuento final (detalle en §6):

| Origen | LAWS_JETPROT | CONF | LIVE | SOUND | Total |
|---|---|---|---|---|---|
| JET | 10 | 34 | 0 | 0 | **44** |
| HIP | 39 | 101 | 0 | 0 | **140** |
| MIXTA | 24 | 6 | 2 | 0 | **32** |
| TÉCNICA | 8 | 2 | 0 | 8 | **18** |

## 1. Anatomía de una ley de celda (se explica una vez, vale para 59 de las 81: las que tienen exactamente los cinco cuantificadores de abajo)

Casi todas las leyes de `LAWS_JETPROT.bend` tienen esta forma:

```bend
law nombre:                                   # (1)
  for +o: S.Ord                               # (2)
  for +f: S.Fin                               # (3)
  for +e: S.Ev                                # (4)
  for +bt: Bool                               # (5)
  for +bh: Bool                               # (6)
  {Spec.pr_xx(..., S.step_fin(o, f, e, bt, bh)) == True{} : Bool}   # (7)
```

1. `law nombre:` declara un enunciado que `PROOF_*.bend` debe probar. El nombre es el que citan los negativos `tests/jetprot_bug*.bend` al refutar.
2. `for +o: S.Ord` — universal sobre el **orden de urgencia** de las respuestas: `Ord1` = None < JTT < RTPS < PTN (elegido, A-1) y `Ord2` = None < RTPS < JTT < PTN (la sensibilidad C3). El `+` marca el argumento como *sin restricción de linealidad* (puede usarse varias veces en el cuerpo).
3. `for +f: S.Fin` — universal sobre el **estado de control finito** de ocho campos: `Fin{prog, jtt, level, dms, plasma, ip, nb, rf}` = fase del programa, bandera "forma de onda de terminación", nivel de respuesta en vigor, estado del DMS, condiciones de plasma, veredicto de habilitación del DMV (corriente o energía almacenada por encima del umbral, A-22), unidad NB, unidad RF. Son 10 752 estados. No se pide `inv_fin(f)`: la ley debe valer también en estados espurios.
4. `for +e: S.Ev` — universal sobre el **alfabeto abstracto** de 28 variantes: `Advance`, `Stop{req, dms}`, `Local{u}`, `HeatOn{u}`, `HeatOff{u}`, `Plasma{ok}`, `Ip{ok}`, `CommFault{dms, en}`, `Heartbeat`, `Tick{dms}`, `HeatAck`, `Reset`. La configuración (qué respuesta pide la alarma, si va cableada al DMS, si el chequeo está habilitado) viaja como carga del evento, así la ley vale para toda configuración.
5. `for +bt: Bool` — el **verdicto del contador de espera del DMS**: `True` si `tack + 1 < ack_max` (aún puede incrementar), `False` si expiró. Entra como Bool para que la ley no dependa del valor concreto del contador.
6. `for +bh: Bool` — ídem para el **watchdog**: `True` si `hb + 1 < hb_max`.
7. La meta: el predicado `pr_xx` de `spec_jetprot.bend`, evaluado en la celda `(o, f, e, bt, bh)` y en el estado siguiente `f2 = step_fin(o, f, e, bt, bh)`, es `True`. Se prueba por **reflexión**: el certificado `E.check_fin(o)` recorre las 462 336 celdas por orden y `PROOF_JETPROT.bend` deduce cada ley universal del certificado más el lema de que `check_fin` es la conjunción de todas las celdas.

Cuando una ley se aparta del molde (menos cuantificadores, hipótesis extra, meta de igualdad `==` en vez de `Bool`), se explica línea a línea en su entrada. Para las demás, la explicación "línea a línea" es la del **cuerpo del predicado** `pr_xx`, que es donde está el contenido.

Vocabulario del modelo usado en las explicaciones:

- `is_hot(u)` = la unidad entrega potencia (`On` o `Reduced`); `unpowered(u)` = `Off` exactamente; `is_ramping(u)` = bajando bajo un stop; `is_reduced(u)` = potencia parcial (un PINI afuera, R-9).
- `is_soft(l)` = `LJtt` o `LRtps` (los dos stops programables); `is_ptn(l)` = `LPtn`; `is_none(l)` = sin stop.
- `prog_of(f)` = fase del programa Level-1 (la que indexa la Tabla 1); `wave_of(f)` = fase de la forma de onda = `Termination` si `jtt`, si no `prog` (A-24).
- `upd_hb(f, e, bh)` / `upd_tack(f, e, bt, bh)` = el **comando** que el paso da a cada contador: `CKeep`, `CReset` o `CInc`. Las leyes hablan del comando, no del valor, para ser universales en `hb_max`/`ack_max`.
- `reset_ok(f)` = `(PTN activo ∨ wave = Termination) ∧ DMS no armado`, la guarda de fin de pulso (A-14).
- `demands_dms(e, bh, l)` = el evento pide el DMS: un `Stop{PTN, dms=True}`, un `CommFault{dms=True, en=True}` o un `Tick{dms=True}` con watchdog expirado y PTN aún no activo.

## 2. `LAWS_JETPROT.bend` — 81 leyes

### 2.1 Certificados decididos por cómputo (3) — TÉCNICA

```bend
law finite_check:
  {E.check_fin(S.Ord1{}) == True{} : Bool}
```
- Línea 1: nombre. Línea 2: la función `check_fin` del enumerador (`enum_jetprot.bend`), con el orden `Ord1`, devuelve `True`. `check_fin` recorre 10 752 estados × 43 columnas de evento y en cada celda evalúa la preservación de I1–I4, la forma de los comandos de contador y todos los `pr_*` de las leyes de celda.
- **Origen: TÉCNICA.** Es el método (certificado por reflexión). Se prueba en `PROOF_JETPROT_FIN.bend` dejando que Bend normalice el cómputo.

```bend
law finite_check_alt:
  {E.check_fin(S.Ord2{}) == True{} : Bool}
```
- Lo mismo con el orden invertido JTT/RTPS. Existe porque A-1 (el orden) es hipótesis nuestra: así toda ley de celda queda probada para ambos órdenes y C3 (la sensibilidad) es un teorema, no una tabla.
- **Origen: TÉCNICA** (motivada por A-1).

```bend
law corollaries_check:
  {E.check_cor() == True{} : Bool}
```
- `check_cor` recorre los 10 752 estados y verifica los cuatro corolarios de estado (§2.9) bajo `inv_fin`.
- **Origen: TÉCNICA.**

### 2.2 Invariantes y teorema de trazas (6)

```bend
law inv_init:
  {S.inv_all(S.init()) == True{} : Bool}
```
- El estado inicial `St{Fin{Breakdown, False, LNone, DmsIdle, False, False, Off, Off}, 0, 0}` cumple el invariante completo (control + dos contadores).
- **Origen: HIP** (A-5: el pulso empieza en Breakdown; A-12: el watchdog corre desde el inicio con `hb = 0`; todo apagado y sin stop es nuestra elección de estado inicial).

```bend
law pres_fin:
  for +o: S.Ord
  for +s: S.St
  for +h: {S.inv_all(s) == True{} : Bool}
  for +e: S.Ev
  {S.inv_fin(S.fin_of(S.step_o(o, s, e))) == True{} : Bool}
```
- Línea 2: todo orden. Línea 3: todo estado **completo** `St{fin, hb, tack}` (con contadores, a diferencia del molde). Línea 4: hipótesis `h`: el estado cumple `inv_all`. Línea 5: todo evento. Línea 6: la parte de control del estado siguiente cumple `inv_fin`, que es la conjunción de:
- **I1** `on_ok`: una unidad `On`/`Reduced` sólo si la ventana de calentamiento está abierta (en `wave`), hay plasma y no hay stop;
- **I2** `ramp_ok`: una unidad `Ramping` sólo bajo un stop blando o en Termination;
- **I3** `nivel = LJtt ⇒ wave = Termination` (un JTT en vigor implica que ya corren las formas de onda de terminación; en el código, `implies(is_jtt(l), is_term(w))`, sobre el **nivel** `l` y no sobre el flag `jtt`, con el que sería una tautología, porque `wave` vale Termination cuando `jtt` es verdadero);
- **I4** `DMS no Idle ⇒ nivel = PTN`.
- **Origen: MIXTA.** I1 es R-12 (PEWS) abstraído por A-5/A-8/A-9; I2 es A-9; I3 es A-24; I4 es R-11 ("these triggers first cause the heating systems to be turned off", traducción nuestra: estos disparos primero apagan el calentamiento).

```bend
law pres_i5:
  for +o: S.Ord
  for +s: S.St
  for +h: {S.inv_all(s) == True{} : Bool}
  for +e: S.Ev
  {S.i5_ack(S.step_o(o, s, e)) == True{} : Bool}
```
- Igual estructura; la meta es **I5**: mientras el DMS está armado, `tack < ack_max`.
- **Origen: MIXTA.** El mecanismo de espera con timeout es R-11; el contador de espera `tack` y su tope `ack_max` son formalización nuestra, A-11; contar en ticks es A-15, común a todas las leyes (§0).

```bend
law pres_i6:
  for +o: S.Ord
  for +s: S.St
  for +h: {S.inv_all(s) == True{} : Bool}
  for +e: S.Ev
  {S.i6_hb(S.step_o(o, s, e)) == True{} : Bool}
```
- Meta **I6**: mientras el PTN no está enclavado, `hb < hb_max`.
- **Origen: MIXTA.** R-13 (watchdog hardware al PTN) + A-12 (contador de ticks desde Breakdown, guarda por nivel).

```bend
law traces_safe:
  for +o: S.Ord
  for +trace: List<&2, S.Ev>
  {S.inv_all(S.run_o(o, trace, S.init())) == True{} : Bool}
```
- Línea 2: todo orden. Línea 3: toda lista de eventos abstractos (`List<&2, _>` es la lista de Base con multiplicidad afín). Línea 4: correr la traza desde `init` deja un estado que cumple `inv_all`. Se prueba por inducción sobre la lista con `inv_init` como base y `pres_*` como paso.
- **Origen: TÉCNICA** (el teorema T del diseño; su contenido son los invariantes de arriba).

```bend
law traces_safe_concrete:
  for +i: S.Inst
  for +trace: List<&2, S.CEv>
  {S.inv_all(S.run_c(i, trace, S.init())) == True{} : Bool}
```
- Lo mismo sobre el alfabeto **concreto** (`XAlarm{t}`, `XTick`, …) pasando por la instancia `i` de configuración (las cuatro, desde la revisión 4). Se deduce de `traces_safe` y `step_c_is_the_concrete_step`.
- **Origen: TÉCNICA.**

### 2.3 Leyes de paso P1–P21 (18)

**P1 `latched`** — código en molde; meta `Spec.pr_p1(o, f, e, f2)`.
```bend
def pr_p1(+o: S.Ord, +f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.not(is_reset(e)), lvl_le(o, S.level_of(f), S.level_of(f2)))
```
- Si el evento no es `Reset`, el nivel siguiente es ≥ el nivel actual bajo el orden `o` (`lvl_le` compara rangos). Un stop nunca se degrada.
- **Origen: HIP (A-1, A-2).** R-0 fuerza que el PTN esté arriba (salida enclavada), pero el orden total y la política "escalar por máximo" son nuestras; R-6 dice que JET *puede* suprimir una escalación. Separando las partes (revisión 4): "el PTN queda trabado" es **HECHO JET** (R-0; [N1] p.14 del PDF) y tiene ley propia, `p1a_ptn_latched`; "un stop nunca vuelve a None" es **MIXTA** (el PTN trabado es R-0; para los stops suaves es lectura nuestra, A-14) y tiene ley propia, `p1b_stop_never_cleared` (§2.10); el orden entre los dos stops suaves (suave sobre suave) es **POLÍTICA NUESTRA** (A-1, A-2).

**P2 `ptn_deenergizes`** — meta `pr_p2(f, f2)`.
```bend
def pr_p2(+f: S.Fin, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(Bool.not(S.is_ptn(S.level_of(f))), S.is_ptn(S.level_of(f2))),
            Bool.and(S.unpowered(S.nb_of(f2)), S.unpowered(S.rf_of(f2))))
```
- Antecedente: el paso *alcanza* el PTN (no lo tenía, lo tiene). Consecuente: ambas unidades quedan `Off` en el mismo paso.
- **Origen: MIXTA (R-0, R-11 + A-9).** "The PTN output is a latched stop signal [...] fixed shutdown sequence"; "these triggers first cause the heating systems to be turned off". Que las dos unidades queden en `Off` es A-9: el apagado del calentamiento está documentado para las salidas del PTN que disparan el DMS (R-11); para las demás, sólo como la "fixed shutdown sequence" que ejecuta cada sistema de control (R-0). Es la misma parte que hace MIXTA a `d1a_ptn_honoured`. Que ocurra en el mismo paso es la abstracción sin tiempo del modelo (A-15): en la planta NBI tarda 2 ms y RF unos 38 ms ([S6]).

**P3 `stop_reduces_power`** — meta `pr_p3(f, f2)`.
```bend
def pr_p3(+f: S.Fin, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(S.is_none(S.level_of(f)), S.is_soft(S.level_of(f2))),
            Bool.and(Bool.not(S.is_hot(S.nb_of(f2))), Bool.not(S.is_hot(S.rf_of(f2)))))
```
- Antecedente: se pasa de "sin stop" a un stop blando (RTPS o JTT). Consecuente: ninguna unidad sigue entregando potencia (ni plena ni parcial).
- **Origen: MIXTA (R-3, R-4 + A-9).** Los overrides RTPS bajan la referencia (R-3: "the new reference could be set to 6MW") y el RTPS podía tomar las formas de onda de NB y RF "to ramp down the plasma current and heating power" (R-4). Que **todo** stop suave saque de potencia a las **dos** unidades, también a la que está a potencia parcial, es A-9: [S1] describe los stops RTPS como overrides "fully programmable" y no dice que cada uno baje las dos unidades. "Ni parcial" es la misma parte A-9 que hace MIXTA a `stop_no_full_power`.

**P4 `ramping_never_returns`** — meta `pr_p4(f, e, f2)`. *Derivada* (implicada por P5 y P7, §6.5).
```bend
def p4_unit(u: S.Heat, u2: S.Heat, e: S.Ev) -> Bool:
  S.implies(Bool.and(S.is_ramping(u), Bool.not(is_reset(e))), Bool.not(S.is_hot(u2)))
def pr_p4(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  Bool.and(p4_unit(S.nb_of(f), S.nb_of(f2), e), p4_unit(S.rf_of(f), S.rf_of(f2), e))
```
- `p4_unit`: si la unidad estaba `Ramping` y no hay `Reset`, no vuelve a entregar potencia. `pr_p4` lo aplica a NB y RF.
- **Origen: HIP (A-9).** "Ramping never returns to On" es política nuestra (conservadora).

**P5 `heat_permissive`** — meta `pr_p5(f, e, f2)`.
```bend
def p5_unit(+ok: Bool, +u: S.Heat, +u2: S.Heat) -> Bool:
  +acc = Bool.and(ok, S.is_off(u))
  Bool.and(beq(S.is_on(u2), Bool.or(acc, Bool.and(S.is_on(u), Bool.not(acc)))),
           S.implies(Bool.not(acc), unit_eq(u2, u)))
def pr_p5(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  Bool.and(S.implies(is_heaton_of(e, S.Nb{}), p5_unit(S.permit(f), S.nb_of(f), S.nb_of(f2))),
           S.implies(is_heaton_of(e, S.Rf{}), p5_unit(S.permit(f), S.rf_of(f), S.rf_of(f2))))
```
- `acc` = el comando se acepta: permisivo `ok` y la unidad estaba `Off`. Línea siguiente: la unidad queda `On` **si y sólo si** se aceptó o ya estaba `On`; y si no se aceptó, no cambia. `pr_p5` lo aplica al `HeatOn` de la unidad correspondiente con `permit(f)` = ventana abierta en `wave` ∧ plasma ∧ sin stop.
- **Origen: MIXTA (R-12 + A-5, A-8, A-9).** El permisivo es R-12 (PEWS: "enable windows [...] based on time in the pulse and basic plasma conditions"); la forma exacta es nuestra: la ventana fija, leída en la fase de onda (A-5, A-24), el plasma como un solo booleano (A-8) y la condición "sin stop" (A-9). Cobertura: la ventana es fija, igual para las dos unidades y para toda instancia (A-27); la ley no se comprueba con ventanas por unidad ni con calentamiento antes de Heating 1.

**P6 `stop_overrides_heat`** — meta `pr_p6(f, f2)`. *Derivada* (implicada por P5 y P7, §6.5).
```bend
def p6_unit(u: S.Heat, u2: S.Heat) -> Bool:
  Bool.not(Bool.and(Bool.not(S.is_hot(u)), S.is_hot(u2)))
def pr_p6(+f: S.Fin, +f2: S.Fin) -> Bool:
  S.implies(Bool.not(S.is_none(S.level_of(f))), Bool.and(p6_unit(...nb...), p6_unit(...rf...)))
```
- `p6_unit`: no ocurre que una unidad pase de "sin potencia" a "con potencia". `pr_p6`: eso vale para ambas si hay un stop en vigor.
- **Origen: HIP (A-9).** "With a stop in progress, no new command turns anything on" (conservador).

**P7 `heat_frame`** — meta `pr_p7(f, e, f2)`.
```bend
def p7_unit(u: S.Heat, u2: S.Heat, e: S.Ev, w: S.Who) -> Bool:
  S.implies(Bool.and(S.is_hot(u2), Bool.not(S.is_hot(u))), is_heaton_of(e, w))
```
- Si una unidad adquiere potencia, el evento fue el `HeatOn` de esa unidad. Aplicado a NB y RF.
- **Origen: HIP (A-19, comando = efecto).** Ley de marco.

**P9 `local_is_local`** — meta `pr_p9(f, e, bt, bh, f2)`.
```bend
def reduced_to(+u: S.Heat, +u2: S.Heat) -> Bool:
  Bool.and(S.implies(S.is_on(u), S.is_reduced(u2)), S.implies(Bool.not(S.is_on(u)), unit_eq(u2, u)))
def local_frame(f: S.Fin, f2: S.Fin, w: S.Who) -> Bool:
  match f f2 w:
    case Fin{...} Fin{...} S.Nb{}:  reduced_to(nb, nb2) ∧ (los otros 7 campos iguales)
    case Fin{...} Fin{...} S.Rf{}:  reduced_to(rf, rf2) ∧ (los otros 7 campos iguales)
def p9_go(+f, +w, +bt, +bh, +f2) -> Bool:
  Bool.and(local_frame(f, f2, w), Bool.and(is_keep(upd_hb(f, Local{w}, bh)), is_keep(upd_tack(f, Local{w}, bt, bh))))
def pr_p9(+f, e, +bt, +bh, +f2) -> Bool:
  match e:
    case S.Local{u}: p9_go(f, u, bt, bh, f2)
    case _: True{}
```
- `reduced_to`: `On → Reduced`; cualquier otro valor queda igual. `local_frame`: eso para la unidad alarmada y los siete campos restantes sin cambio. `p9_go`: además ambos contadores reciben `CKeep`. `pr_p9`: sólo aplica cuando el evento es `Local{u}`.
- **Origen: MIXTA.** El "un PINI afuera" es R-9; el marco y el "no se apaga la unidad" son A-6/A-7. Un solo nivel de reducción: una segunda alarma local no hace nada (A-33).

**P10 `no_spurious_stop`** — meta `pr_p10(f, e, bh, f2)`.
```bend
def pr_p10(+f, +e, +bh, +f2) -> Bool:
  S.implies(Bool.not(lvl_eq(level_of(f), level_of(f2))),
          Bool.or(is_stop(e), Bool.or(is_commfault(e), Bool.or(is_reset(e),
                  Bool.and(is_tick(e), Bool.and(Bool.not(bh), Bool.not(is_ptn(level_of(f)))))))))
```
- Si el nivel cambió, el evento fue un `Stop`, un `CommFault`, un `Reset`, o un `Tick` con watchdog expirado y PTN no activo.
- **Origen: HIP (A-12, A-13; cierre de R-13).** Las cuatro causas son de JET; el "ninguna otra" es nuestro.

**P12 `commfault_ptn`** — meta `pr_p12(e, f2)`.
```bend
def pr_p12(+e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(is_comm_en(e), S.is_ptn(S.level_of(f2)))
```
- Un `CommFault` con el chequeo habilitado (`en = True`) deja el nivel en PTN, desde cualquier estado.
- **Origen: JET (R-13).** "If RTPS detects communication or status faults [...] it can trigger the PTN system."

**P14 `phase_monotone`** — meta `pr_p14(f, e, f2)`.
```bend
def pr_p14(+f, +e, +f2) -> Bool:
  S.implies(Bool.not(is_reset(e)), Bool.and(phase_le(prog_of(f), prog_of(f2)), phase_le(wave_of(f), wave_of(f2))))
```
- Sin `Reset`, ni la fase del programa ni la de forma de onda retroceden.
- **Origen: HIP (A-5).** R-1 dice "timed phases"; el orden total y la irreversibilidad son nuestra lectura.

**P15 `dms_monotone`** — meta `pr_p15(f, e, f2)`.
```bend
def pr_p15(+f, +e, +f2) -> Bool:
  S.implies(Bool.not(is_reset(e)), dms_le(dms_of(f), dms_of(f2)))
```
- Sin `Reset`, el DMS sólo avanza `Idle → Armed → Fired`; nunca se desarma ni "des-dispara".
- **Origen: MIXTA ([S6] + A-11).** Que `Fired` sea definitivo hasta el fin de pulso tiene respaldo en [S6]: la válvula "has to be refilled by an operator in the control room after every injection" (A-11). Que el DMS armado nunca se desarme, tampoco si después cae el veredicto `ip` (A-22), es nuestro.

**P16 `dms_armed_on_demand`** — meta `pr_p16(f, e, bh, f2)`.
```bend
def pr_p16(+f, +e, +bh, +f2) -> Bool:
  S.implies(Bool.and(is_idle(dms_of(f)), Bool.and(ip_of(f), demands_dms(e, bh, level_of(f)))), is_armed(dms_of(f2)))
```
- Si el DMS está `Idle`, está el veredicto de habilitación del DMV (`ip`: corriente **o** energía almacenada por encima del umbral; A-22), y el evento demanda el DMS, queda `Armed`.
- **Origen: MIXTA.** Que los stops al PTN puedan disparar la DMV es R-11/[S6]; el umbral es R-14; *cuáles* stops llevan el bit es A-10 (código del modelo, igual para toda instancia).

**P17 `dms_frame`** — meta `pr_p17(f, e, bh, f2)`.
```bend
def pr_p17(+f, +e, +bh, +f2) -> Bool:
  S.implies(Bool.and(is_idle(dms_of(f)), Bool.not(is_idle(dms_of(f2)))), Bool.and(ip_of(f), demands_dms(e, bh, level_of(f))))
```
- Recíproca de P16: si el DMS salió de `Idle`, fue por una demanda con el veredicto de habilitación del DMV verdadero.
- **Origen: MIXTA (R-14 + A-10, A-11).** Que sin ese veredicto el DMS no se arme es R-14, como en `ip1_low_never_arms` (que implica); que sólo una demanda lo arme, y nada más, es marco nuestro (A-10, A-11).

**P18 `tack_frame`** — meta `pr_p18(f, e, bt, bh)` (no usa `f2`).
```bend
def pr_p18(+f, +e, +bt, +bh) -> Bool:
  S.implies(Bool.and(is_armed(dms_of(f)), Bool.and(Bool.not(is_tick(e)), Bool.not(is_reset(e)))),
          is_keep(upd_tack(f, e, bt, bh)))
```
- Con el DMS armado, cualquier evento que no sea `Tick` ni `Reset` da `CKeep` al contador de espera (una alarma repetida no reinicia la espera).
- **Origen: HIP (A-11).**

**P19 `advance_frozen`** — meta `pr_p19(f, e, bt, bh, f2)`.
```bend
def pr_p19(+f, +e, +bt, +bh, +f2) -> Bool:
  S.implies(Bool.and(is_advance(e), is_ptn(level_of(f))),
          Bool.and(fin_eq(f, f2), Bool.and(is_keep(upd_hb(f, e, bh)), is_keep(upd_tack(f, e, bt, bh)))))
```
- Un `Advance` bajo PTN es la identidad en el control y da `CKeep` a ambos contadores.
- **Origen: MIXTA (R-0 + A-11, A-12).** Ante la señal trabada del PTN, cada sistema de control ejecuta una "fixed shutdown sequence" (R-0): el programa ya no manda, y por eso `Advance` es la identidad bajo PTN (A-5). Que además los dos contadores reciban `CKeep` es formalización nuestra (A-11, A-12), como en `piw_after_ptn_is_noop`.

**P20 `reset_guarded`** — meta `pr_p20(f, e, bt, bh, f2)`.
```bend
def reset_shape(ok, f, f2, hb_cmd, tack_cmd) -> Bool:
  match ok:
    case True{}:  fin_eq(f2, init_fin()) ∧ is_creset(hb_cmd) ∧ is_creset(tack_cmd)
    case False{}: fin_eq(f2, f) ∧ is_keep(hb_cmd) ∧ is_keep(tack_cmd)
def pr_p20(+f, +e, +bt, +bh, +f2) -> Bool:
  S.implies(is_reset(e), reset_shape(reset_ok(f), f, f2, upd_hb(f, e, bh), upd_tack(f, e, bt, bh)))
```
- Si el evento es `Reset`: con `reset_ok(f)` el control vuelve a `init_fin` y ambos contadores reciben `CReset`; sin él, identidad y `CKeep`. Nota: cita `reset_ok` del propio modelo (autorreferencia); D10 lo repara.
- **Origen: HIP (A-14).** JET no publica un camino que limpie el enclavamiento en medio del pulso.

**P21 `reset_refused_mid_pulse`** — meta `pr_p21(f, e, bt, bh, f2)`.
```bend
def pr_p21(+f, +e, +bt, +bh, +f2) -> Bool:
  S.implies(Bool.and(is_reset(e), Bool.or(is_armed(dms_of(f)),
                                          Bool.and(Bool.not(is_ptn(level_of(f))), Bool.not(is_term(wave_of(f)))))),
          Bool.and(fin_eq(f, f2), Bool.and(is_keep(upd_hb(...)), is_keep(upd_tack(...)))))
```
- Un `Reset` con el DMS armado, o antes de que el pulso termine (ni PTN ni forma de onda de terminación), no cambia nada. La guarda está escrita explícitamente, no tomada de `reset_ok`.
- **Origen: HIP (A-14).**

### 2.4 Leyes de demanda y marco D1–D18 (18)

Las P dicen "nada malo pasa"; las D dicen "el secuenciador **hace** su trabajo" y "nada más se mueve". Se agregaron tras la auditoría #4, que mostró que el conjunto anterior era puramente negativo.

**D1 `d1_stop_honoured`** — meta `pr_d1(o, f, e, f2)`.
```bend
def lvl_lub(o, a, b) -> S.Level:  el más urgente de a y b bajo o
def pr_d1(+o, +f, +e, +f2) -> Bool:
  S.implies(is_stop(e), lvl_eq(level_of(f2), lvl_lub(o, level_of(f), ev_req(e))))
```
- Ante un `Stop{req, _}`, el nivel siguiente es **exactamente** el máximo del nivel en vigor y el pedido (dos lados; P1 sólo daba ≥).
- **Origen: MIXTA.** R-7: "subsequent alarms could generate a more urgent stop" (JET); "máximo" es A-2. Separando las partes (revisión 4): el stop primario atendido es **HECHO JET** (R-5; [N1] p.13 del PDF) y tiene ley propia, `d1b_primary_honoured`; la mitad del PTN (un pedido de PTN se atiende siempre) tiene ley propia, `d1a_ptn_honoured`, que es **MIXTA** porque además exige las dos unidades apagadas, que es A-9 como en `ptn_deenergizes` (§2.10); "suave sobre suave = el máximo" es **POLÍTICA NUESTRA** (A-2, A-16), y físicamente corta para los dos lados: pide al menos la autoridad solicitada, pero escalar un aterrizaje suave a PTN puede provocar una disrupción, e ignora un segundo pedido de igual o menor rango.

**D2 `d2_soft_stop_ramps`** — meta `pr_d2(o, f, e, f2)`.
```bend
def pr_d2(+o, +f, +e, +f2) -> Bool:
  +req = ev_req(e)
  S.implies(Bool.and(is_soft(req), Bool.and(lvl_lt(o, level_of(f), req), some_hot(f))), both_ramp(f, f2))
```
- Si el pedido es blando, más urgente que el actual (se acepta), y alguna unidad entregaba potencia, entonces toda unidad con potencia pasa a `Ramping`.
- **Origen: MIXTA (R-4 + A-9).** Que un stop suave baje la potencia en rampa y no la corte es R-4: "ramp down the plasma current and heating power to give a softer landing". Era el hallazgo H16 (la revisión 2 tenía "JTT apaga", contradiciendo R-4). Que todo stop suave aceptado lo haga con las dos unidades, también con la que está a potencia parcial, es A-9, como en `stop_reduces_power`.

**D3 `d3_advance_to_termination_ramps`** — meta `pr_d3(f, e, f2)`. *Derivada* (subsumida por E4).
```bend
def pr_d3(+f, +e, +f2) -> Bool:
  S.implies(Bool.and(is_advance(e), Bool.and(Bool.not(is_ptn(level_of(f))),
          Bool.and(phase_eq(prog_of(f), Heating2{}), some_hot(f)))), both_ramp(f, f2))
```
- Un `Advance` desde Heating 2 (a Termination), sin PTN y con potencia, pone las unidades a bajar.
- **Origen: HIP (A-9).** "On entering Termination by Advance, the same" es nuestro.

**D4 `d4_watchdog_latches`** — meta `pr_d4(f, e, bh, f2)`.
```bend
def pr_d4(+f, +e, +bh, +f2) -> Bool:
  S.implies(Bool.and(is_tick(e), Bool.and(Bool.not(bh), Bool.not(is_ptn(level_of(f))))), is_ptn(level_of(f2)))
```
- Un `Tick` con el watchdog expirado y PTN no activo enclava el PTN, lleve o no el bit DMS.
- **Origen: JET (R-13).** "A hardware watchdog signal to PTN ensures that RTPS is operational itself."

**D5 `d5_hb_counts`** — meta `pr_d5(f, e, bh)`. *Derivada* (mitad de E6).
```bend
def pr_d5(+f, +e, +bh) -> Bool:
  S.implies(Bool.and(is_tick(e), Bool.and(bh, Bool.not(is_ptn(level_of(f))))), is_cinc(upd_hb(f, e, bh)))
```
- Un `Tick` con margen (`bh`) y sin PTN incrementa el contador de latidos.
- **Origen: HIP (A-12).**

**D6 `d6_hb_frame`** — meta `pr_d6(f, e, bh)`.
```bend
def pr_d6(+f, +e, +bh) -> Bool:
  S.implies(is_creset(upd_hb(f, e, bh)), Bool.or(is_heartbeat(e), Bool.and(is_reset(e), reset_ok(f))))
```
- Si el comando al watchdog es `CReset`, el evento fue `Heartbeat` o un `Reset` aceptado.
- **Origen: HIP (A-12).**

**D7 `d7_ack_timeout_fires`** — meta `pr_d7(f, e, bt, f2)`.
```bend
def pr_d7(+f, +e, +bt, +f2) -> Bool:
  S.implies(Bool.and(is_armed(dms_of(f)), Bool.and(is_ptn(level_of(f)), Bool.and(is_tick(e), Bool.not(bt)))), is_fired(dms_of(f2)))
```
- DMS armado, PTN activo, `Tick` y espera expirada (`bt = False`) ⇒ el DMS dispara.
- **Origen: JET (R-11).** "conditioned with an acknowledgement from the heating plant (and timeout)"; [S6]: RF no confirma, el timeout es el camino real.

**D8 `d8_ack_counts`** — meta `pr_d8(f, e, bt, bh)`.
```bend
def pr_d8(+f, +e, +bt, +bh) -> Bool:
  S.implies(Bool.and(is_armed(dms_of(f)), Bool.and(is_ptn(level_of(f)), Bool.and(is_tick(e), bt))), is_cinc(upd_tack(f, e, bt, bh)))
```
- DMS armado, PTN activo, `Tick` con margen ⇒ el contador de espera incrementa.
- **Origen: HIP (A-11).**

**D9 `d9_heatack_fires`** — meta `pr_d9(f, e, f2)`. *Derivada* (mitad de E11).
```bend
def pr_d9(+f, +e, +f2) -> Bool:
  S.implies(Bool.and(is_armed(dms_of(f)), is_heatack(e)), is_fired(dms_of(f2)))
```
- DMS armado y llega `HeatAck` ⇒ dispara.
- **Origen: JET (R-11).** "acknowledgement from the heating plant".

**D10 `d10_reset_accepted_when_safe`** — meta `pr_d10(f, e, bt, bh, f2)`. *Derivada* (implicada por P20).
```bend
def reset_guard(+f) -> Bool:
  Bool.and(Bool.or(is_ptn(level_of(f)), is_term(wave_of(f))), Bool.not(is_armed(dms_of(f))))
def pr_d10(+f, +e, +bt, +bh, +f2) -> Bool:
  S.implies(Bool.and(is_reset(e), reset_guard(f)),
          Bool.and(fin_eq(f2, init_fin()), Bool.and(is_creset(upd_hb(...)), is_creset(upd_tack(...)))))
```
- `reset_guard` reescribe la guarda **sin** citar `reset_ok` del modelo. Si `Reset` y la guarda vale: control a inicial, ambos contadores `CReset`. Rompe la autorreferencia de P20 (auditoría #1).
- **Origen: HIP (A-14).**

**D11 `d11_advance_is_one_step`** — meta `pr_d11(f, e, f2)`.
```bend
def pr_d11(+f, +e, +f2) -> Bool:
  S.implies(Bool.and(is_advance(e), Bool.and(Bool.not(is_ptn(level_of(f))), Bool.not(is_term(prog_of(f))))),
          phase_eq(prog_of(f2), next_phase(prog_of(f))))
```
- `Advance` sin PTN y no en Termination ⇒ la fase del programa es exactamente la siguiente.
- **Origen: HIP (A-5).** `Advance` abstrae el reloj del programa; que avance de a una es nuestro.

**D12 `d12_phase_frame`** — meta `pr_d12(f, e, f2)`. No es derivada: al revés, F1b es su caso Stop (§6.5).
```bend
def pr_d12(+f, +e, +f2) -> Bool:
  S.implies(Bool.not(phase_eq(prog_of(f), prog_of(f2))), Bool.or(is_advance(e), is_reset(e)))
```
- Si la fase del programa cambió, fue por `Advance` o `Reset`.
- **Origen: HIP (A-5, A-24).**

**D13 `d13_plasma_is_input`** — meta `pr_d13(e, f2)`.
```bend
def pr_d13(+e, +f2) -> Bool:
  S.implies(is_plasma(e), beq(plasma_of(f2), ev_ok(e)))
```
- `Plasma{ok}` escribe `ok` en el campo `plasma`.
- **Origen: HIP (A-8).** Un booleano para corriente y densidad es nuestra abstracción de R-12.

**D14 `d14_plasma_frame`** — meta `pr_d14(f, e, f2)`.
```bend
def pr_d14(+f, +e, +f2) -> Bool:
  S.implies(Bool.not(beq(plasma_of(f), plasma_of(f2))), Bool.or(is_plasma(e), Bool.and(is_reset(e), reset_ok(f))))
```
- Si `plasma` cambió, fue por `Plasma{_}` o un `Reset` aceptado.
- **Origen: HIP (A-8).**

**D15 `d15_heatoff_is_local`** — meta `pr_d15(f, e, bt, bh, f2)`.
```bend
def one_unit(+f, +f2, +w, exp, +e, +bt, +bh) -> Bool:
  unit_eq(unit_of(w, f2), exp) ∧ unit_eq(unit_of(other(w), f2), unit_of(other(w), f))
  ∧ frame_units(f, f2) ∧ is_keep(upd_hb(...)) ∧ is_keep(upd_tack(...))
def pr_d15(+f, e, +bt, +bh, +f2) -> Bool:
  match e:
    case S.HeatOff{u}: one_unit(f, f2, u, deenergize(unit_of(u, f)), HeatOff{u}, bt, bh)
    case _: True{}
```
- `one_unit`: la unidad `w` queda en `exp`, la otra igual, los seis campos que no son unidades iguales, contadores `CKeep`. `pr_d15`: ante `HeatOff{u}`, `exp = Off`.
- **Origen: HIP (A-19).** Marco.

**D16 `d16_heaton_is_local`** — meta `pr_d16(f, e, bt, bh, f2)`.
```bend
def pr_d16(+f, e, +bt, +bh, +f2) -> Bool:
  match e:
    case S.HeatOn{u}:
      frame_units(f, f2) ∧ unit_eq(unit_of(other(u), f2), unit_of(other(u), f)) ∧ is_keep(upd_hb) ∧ is_keep(upd_tack)
    case _: True{}
```
- Ante `HeatOn{u}`: todo salvo la unidad `u` queda igual (lo que le pasa a `u` es P5).
- **Origen: HIP (A-19).** Marco.

**D17 `d17_heatack_frame`** — meta `pr_d17(f, e, bt, bh, f2)`.
```bend
def pr_d17(+f, +e, +bt, +bh, +f2) -> Bool:
  S.implies(is_heatack(e), Bool.and(frame_dms(f, f2), Bool.and(is_keep(upd_hb(...)), is_keep(upd_tack(...)))))
```
- Ante `HeatAck`: los siete campos que no son el DMS quedan iguales y los contadores `CKeep`.
- **Origen: HIP (A-11).** Marco.

**D18 `d18_heartbeat_frame`** — meta `pr_d18(f, e, bt, bh, f2)`.
```bend
def pr_d18(+f, +e, +bt, +bh, +f2) -> Bool:
  S.implies(is_heartbeat(e), Bool.and(fin_eq(f, f2), is_keep(upd_tack(f, e, bt, bh))))
```
- Ante `Heartbeat`: el control no cambia y el contador de espera del DMS recibe `CKeep` (el de latidos lo trata E5).
- **Origen: HIP (A-12).** Marco.

### 2.5 Leyes E2–E11 (8) — cierran los agujeros que dejaban D1–D18 (auditoría #5)

Once de veinticinco mutantes nuevos sobrevivían a D1–D18. E1 se retiró con el valor `Inhibited` (A-26). Con el banco actual (76 defectos del modelo de referencia en Python, juzgados por las leyes reescritas como predicados de Python, `v3/pymodel/jetprot_laws.py`, y por el control de que el invariante del modelo es el de la especificación; el verificador de Bend no participa) se matan 75; el único sobreviviente, M06, es equivalente: el gate calcula que su paso y sus dos comandos a los contadores coinciden con los del modelo en las 924 672 celdas del certificado, su paso con los contadores en 12 042 240 celdas con valores concretos de los contadores y su `concretize` en 1 032 192 celdas (instancia, estado de control, evento de planta) (`C6.equivalence` en `results.json`, corrida de referencia del 2026-09-23), así que ninguna ley puede distinguirlo. Si un sobreviviente difiriera en una sola celda, el gate fallaría.

**E2 `e2_dms_fire_frame`** — meta `pr_e2(f, e, bt, f2)`.
```bend
def pr_e2(+f, +e, +bt, +f2) -> Bool:
  S.implies(Bool.and(is_armed(dms_of(f)), is_fired(dms_of(f2))), Bool.or(is_heatack(e), Bool.and(is_tick(e), Bool.not(bt))))
```
- Si el DMS pasó de armado a disparado, fue por `HeatAck` o por `Tick` con espera expirada.
- **Origen: JET (R-11).** Los dos caminos son exactamente "acknowledgement [...] (and timeout)". Aunque se llame "frame", no es una ley de marco en el sentido de §0: el "sólo" lo publica la misma frase, que condiciona la activación del DMS a esos dos caminos ("conditioned with an acknowledgement from the heating plant (and timeout) before activating the DMS").

**E3 `e3_stop_phase_exact`** — meta `pr_e3(o, f, e, f2)`.
```bend
def e3_phase(jtt_accepted: Bool, w: S.Phase) -> S.Phase:
  match jtt_accepted:
    case True{}: S.Termination{}
    case False{}: w
def pr_e3(+o, +f, +e, +f2) -> Bool:
  +req = ev_req(e)
  S.implies(is_stop(e), phase_eq(wave_of(f2), e3_phase(Bool.and(is_jtt(req), lvl_lt(o, level_of(f), req)), wave_of(f))))
```
- `e3_phase`: Termination si el JTT se aceptó, si no la fase de onda previa. `pr_e3`: ante un `Stop`, la fase de onda siguiente es exactamente eso; "aceptado" = es JTT y es más urgente que el nivel actual.
- **Origen: MIXTA.** El JTT "move forward in their waveforms to the termination region" es R-4; que sólo mueva la onda y no el programa es A-24; "aceptado = más urgente según el orden" es nuestra política (A-2).

**E4 `e4_advance_units`** — meta `pr_e4(f, e, f2)`.
```bend
def pr_e4(+f, +e, +f2) -> Bool:
  +nxt = next_phase(prog_of(f))
  S.implies(Bool.and(is_advance(e), Bool.and(Bool.not(is_ptn(level_of(f))), Bool.not(is_term(prog_of(f))))),
          Bool.and(unit_eq(nb_of(f2), adv_unit(nxt, nb_of(f))), unit_eq(rf_of(f2), adv_unit(nxt, rf_of(f)))))
```
- Ante un `Advance` válido, cada unidad queda exactamente en `adv_unit(nxt, u)`: `ramp(u)` si la siguiente es Termination, `Off` si la siguiente cierra la ventana, igual si no. Cubre los seis avances.
- **Origen: HIP (A-5, A-9).**

**E5 `e5_heartbeat_resets_hb`** — meta `pr_e5(f, e, bh)`.
```bend
def pr_e5(+f, +e, +bh) -> Bool:
  S.implies(is_heartbeat(e), is_creset(upd_hb(f, e, bh)))
```
- `Heartbeat` siempre da `CReset` al watchdog.
- **Origen: HIP (A-12).**

**E6 `e6_hb_tick_exact`** — meta `pr_e6(f, e, bh)`.
```bend
def hb_tick_exp(bh: Bool, l: S.Level) -> S.Upd:
  match bh l:
    case True{} S.LPtn{}: S.CKeep{}
    case True{} _:        S.CInc{}
    case False{} _:       S.CKeep{}
def pr_e6(+f, +e, +bh) -> Bool:
  S.implies(is_tick(e), upd_eq(upd_hb(f, e, bh), hb_tick_exp(bh, level_of(f))))
```
- `hb_tick_exp`: el comando esperado en un `Tick`: con margen y sin PTN → `CInc`; con PTN → `CKeep`; sin margen → `CKeep` (el paso enclava el PTN, D4). `pr_e6`: el comando real es exactamente ese.
- **Origen: HIP (A-12).**

**E7 `e7_tack_inc_frame`** — meta `pr_e7(f, e, bt, bh)`.
```bend
def pr_e7(+f, +e, +bt, +bh) -> Bool:
  S.implies(is_cinc(upd_tack(f, e, bt, bh)), Bool.and(is_tick(e), Bool.and(is_armed(dms_of(f)), bt)))
```
- Si el contador de espera recibe `CInc`, fue un `Tick` con DMS armado y margen.
- **Origen: HIP (A-11).**

**E8 `e8_tack_reset_frame`** — meta `pr_e8(f, e, bt, bh)`.
```bend
def pr_e8(+f, +e, +bt, +bh) -> Bool:
  S.implies(is_creset(upd_tack(f, e, bt, bh)),
          Bool.or(Bool.and(is_reset(e), reset_guard(f)),
                  Bool.and(demands_dms(e, bh, level_of(f)), Bool.and(ip_of(f), is_idle(dms_of(f))))))
```
- Si el contador de espera recibe `CReset`, fue un fin de pulso aceptado (guarda explícita) o una demanda que realmente arma (DMS idle y veredicto de habilitación del DMV: corriente o energía almacenada por encima del umbral, A-22).
- **Origen: HIP (A-11, A-14).**

**E11 `e11_heatack_exact`** — meta `pr_e11(f, e, f2)`.
```bend
def ack_exp(d: S.Dms) -> S.Dms:
  match d:
    case S.DmsArmed{}: S.DmsFired{}
    case d2: d2
def pr_e11(+f, +e, +f2) -> Bool:
  S.implies(is_heatack(e), dms_eq(dms_of(f2), ack_exp(dms_of(f))))
```
- Ante `HeatAck`: `Armed → Fired`, cualquier otro estado del DMS queda igual (dos lados de D9).
- **Origen: MIXTA.** El disparo por acknowledgement es R-11; que un `HeatAck` en `Idle` no haga nada es A-11.

### 2.6 Leyes de fidelidad F1, F2, F3, F4, IP (13) — bloqueante 4 del STATUS 2026-09-21

**F1a `f1a_table_reads_prog`** — fuera de molde.
```bend
law f1a_table_reads_prog:
  for +i: S.Inst
  for +f: S.Fin
  for +t: S.Trig
  {Spec.lvl_eq(Spec.ev_req(S.concretize(i, f, S.XAlarm{t})), E.m_pick(E.m_is_none(S.level_of(f)), i, S.prog_of(f), t)) == True{} : Bool}
```
- Línea 2: toda instancia de configuración (1 a 4). Línea 3: todo estado de control. Línea 4: todo disparador concreto (`Slow`, `Fast`, `Mhd`, `MhdB`, `Mchs`, `Dhs`, `BothHs`, `Blind`). Línea 5: el nivel que `concretize` pone en el `Stop` abstracto para la alarma `t` es igual al que devuelve `m_pick`, la transcripción **separada** del enumerador: sin stop en vigor, la tabla primaria con sus máscaras (`m_alarm`); con un stop en vigor, la tabla secundaria de la instancia (`m_sec`, revisión 4). Las dos se leen en la **fase del programa**. Para las instancias 1 a 3 la secundaria es la primaria, así que para ellas la ley dice lo mismo que antes. Refuta una lectura en la fase de onda, una celda mal transcrita, una máscara ignorada o una tabla equivocada según haya o no un stop en vigor.
- **Origen: MIXTA.** Que la tabla se indexe por fase es R-5; que sea la fase del programa Level-1 y no la de onda tras un JTT es A-24 (nuestra lectura de [S2] §3.4: "time within a sequence [...] jumps [...] to the start of another"). Qué fase lee una alarma **durante** un stop es una lectura no documentada (A-24, A-30): [N1] describe, para el controlador de forma, una configuración congelada en el stop primario, y el modelo no la congela.

**F1b `f1b_stop_keeps_prog`** — meta `pr_f1b(f, e, f2)`.
```bend
def pr_f1b(+f, +e, +f2) -> Bool:
  S.implies(is_stop(e), phase_eq(prog_of(f2), prog_of(f)))
```
- Un `Stop` nunca mueve la fase del programa.
- **Origen: HIP (A-24).**

**F1c `f1c_wave_ahead`** — fuera de molde.
```bend
law f1c_wave_ahead:
  for +f: S.Fin
  {Spec.phase_le(S.prog_of(f), S.wave_of(f)) == True{} : Bool}
```
- Para todo estado, la fase de onda es ≥ la del programa (I7). Se prueba directamente por casos sobre `jtt`: `wave = jtt ? Termination : prog`.
- **Origen: HIP (A-24).** Vale por construcción.

**F1d `f1d_wave_frame`** — meta `pr_f1d(f, e, f2)`.
```bend
def pr_f1d(+f, +e, +f2) -> Bool:
  S.implies(Bool.not(phase_eq(wave_of(f), wave_of(f2))), Bool.or(is_advance(e), Bool.or(is_reset(e), is_jtt(ev_req(e)))))
```
- Si la fase de onda cambió, fue `Advance`, `Reset` o un `Stop` que pide JTT.
- **Origen: HIP (A-24).** Marco.

**F1e `f1e_jtt_exact`** — meta `pr_f1e(o, f, e, f2)`.
```bend
def pr_f1e(+o, +f, +e, +f2) -> Bool:
  +req = ev_req(e)
  S.implies(Bool.not(is_reset(e)),
            beq(jtt_of(f2), Bool.or(jtt_of(f), Bool.and(is_stop(e), Bool.and(is_jtt(req), lvl_lt(o, level_of(f), req))))))
```
- Sin `Reset`, la bandera `jtt` siguiente es exactamente: la previa, o bien se acaba de aceptar un JTT. La encontró la métrica de estrechez (C2): dos estados en Termination que sólo diferían en `jtt` se comportaban igual y nada fijaba la bandera.
- **Origen: HIP (A-24).** "Aceptado = más urgente según el orden" es nuestra política (A-2).

**F4 `f4_units_frame`** — meta `pr_f4(f, e, f2)`.
```bend
def touches_units(e: S.Ev) -> Bool:
  match e:
    case Local{u}: True   case HeatOn{u}: True   case HeatOff{u}: True
    case Advance{}: True  case Reset{}: True
    case Plasma{ok}: Bool.not(ok)          # sólo la pérdida de plasma
    case Stop{req, dms}: is_ptn(req)       # sólo un stop PTN
    case CommFault{dms, en}: en            # sólo el chequeo habilitado
    case _: False
def pr_f4(+f, +e, +f2) -> Bool:
  S.implies(Bool.and(lvl_eq(level_of(f), level_of(f2)), Bool.not(touches_units(e))),
          Bool.and(unit_eq(nb_of(f), nb_of(f2)), unit_eq(rf_of(f), rf_of(f2))))
```
- `touches_units`: los eventos que *pueden* mover una unidad. `pr_f4`: si el nivel no cambió y el evento no es ninguno de esos, ambas unidades quedan iguales. La métrica de estrechez mostró que nada fijaba las unidades bajo `Ip` o `Plasma{True}`.
- **Origen: HIP (A-19).** Marco.

**F2a `f2a_local_reduces`** — meta `pr_f2a(f, e, f2)`.
```bend
def pr_f2a(+f, e, +f2) -> Bool:
  match e:
    case S.Local{u}: S.implies(is_on(unit_of(u, f)), is_reduced(unit_of(u, f2)))
    case _: True{}
```
- Ante `Local{u}`, si la unidad estaba a plena potencia queda `Reduced` (un PINI afuera, R-9), nunca apagada; que eso sea potencia parcial, sin compensación, es A-6.
- **Origen: JET (R-9).** "the relevant PINI should be turned off [...] This should not preclude the neutral-beam system as a whole from continuing to deliver the total requested power to the plasma, as other PINIs can be turned on to compensate".

**F2d `f2d_reduced_never_returns`** — meta `pr_f2d(f, e, f2)`.
```bend
def f2d_unit(u, u2, e) -> Bool:
  S.implies(Bool.and(is_reduced(u), Bool.not(is_reset(e))), Bool.not(is_on(u2)))
def pr_f2d(+f, +e, +f2) -> Bool:
  Bool.and(f2d_unit(nb_of(f), nb_of(f2), e), f2d_unit(rf_of(f), rf_of(f2), e))
```
- Una unidad `Reduced` no pasa a `On` en un solo paso (sin `Reset`). Sin ella, un `Plasma{True}` que restaurara `On` pasaba todas las leyes. Ojo: es una ley de un paso. Si la unidad pasa por `Off` (con `HeatOff` o con `Plasma{False}`), un `HeatOn` posterior la vuelve a `On` y la reducción se olvida (A-34).
- **Origen: HIP (A-6, A-7).** Conservador; R-9 dice que otros PINIs *pueden* compensar, eso no se modela.

**F3b `f3b_commfault_masked_is_noop`** — meta `pr_f3b(f, e, bt, bh, f2)`.
```bend
def pr_f3b(+f, +e, +bt, +bh, +f2) -> Bool:
  S.implies(is_comm_masked(e), Bool.and(fin_eq(f, f2), Bool.and(is_keep(upd_hb(...)), is_keep(upd_tack(...)))))
```
- Un `CommFault` con `en = False` es la identidad, contadores incluidos.
- **Origen: MIXTA ([S1] + A-21).** Que un chequeo deshabilitado no provoque nada lo publica [S1] (p.1296): la interfaz Level-1 condiciona estos chequeos "so that features or subsystems which are not in use cannot cause problems"; R-10 dice además que las entradas del PTN "can be enabled or disabled". Que no se mueva nada, contadores incluidos, es marco nuestro, y que la máscara sea por instancia y sólo para los dos chequeos de fiabilidad es A-21.

**IP1 `ip1_low_never_arms`** — meta `pr_ip1(f, f2)`.
```bend
def pr_ip1(+f, +f2) -> Bool:
  S.implies(Bool.and(Bool.not(ip_of(f)), is_idle(dms_of(f))), is_idle(dms_of(f2)))
```
- Sin el veredicto de habilitación del DMV (`ip` falso: ni la corriente ni, desde la revisión 4 del registro, la energía almacenada superan su umbral; A-22) y con el DMS idle, sigue idle sea cual sea el evento.
- **Origen: JET (R-14).** "The DMV was used systematically for scenarios above 2.5 MA [...] 7 disruptions were detected at a plasma current lower than the minimum current needed for the DMV to be fired" (R-15).

**IP2 `ip2_arms_on_demand`** — fuera de molde (forma concreta de P16).
```bend
law ip2_arms_on_demand:
  for +i: S.Inst
  for +f: S.Fin
  for +t: S.Trig
  for +h_ip: {S.ip_of(f) == True{} : Bool}
  for +h_idle: {S.is_idle(S.dms_of(f)) == True{} : Bool}
  for +h_ptn: {S.is_ptn(S.masked_table(i, S.prog_of(f), t)) == True{} : Bool}
  for +h_req: {S.dms_req(S.wave_of(f), t) == True{} : Bool}
  {S.is_armed(S.dms_of(S.fin_of(S.step_c(i, S.St{f, 0n, 0n}, S.XAlarm{t})))) == True{} : Bool}
```
- Líneas 2–4: instancia, estado, disparador. Línea 5: el veredicto de habilitación del DMV (corriente o energía almacenada por encima del umbral; A-22). Línea 6: DMS idle. Línea 7: la tabla enmascarada de la instancia, en la fase del programa, mapea `t` a PTN. Línea 8: `t` está cableado al DMS y la fase de onda está dentro de la ventana DMV. Línea 9: el paso **concreto** con la alarma `t` (contadores en 0, no importan) deja el DMS armado.
- **Origen: JET (R-11, R-14, [S6]).** "The triggering of the DMV can be attached to any of the stops sent to the Plasma Termination Network (PTN)"; ventana y umbral son R-14.

**IP3 `ip3_ip_is_input`** — meta `pr_ip3(e, f2)`.
```bend
def pr_ip3(+e, +f2) -> Bool:
  S.implies(is_ip(e), beq(ip_of(f2), ev_ip(e)))
```
- `Ip{ok}` escribe `ok` en el campo `ip`.
- **Origen: HIP (A-22: el veredicto de habilitación del DMV como entrada booleana es nuestra forma de modelar R-14; desde la revisión 4 se lee como corriente **o** energía almacenada por encima del umbral, [S7], [K15]).**

**IP4 `ip4_ip_frame`** — meta `pr_ip4(f, e, f2)`.
```bend
def pr_ip4(+f, +e, +f2) -> Bool:
  S.implies(Bool.not(beq(ip_of(f), ip_of(f2))), Bool.or(is_ip(e), Bool.and(is_reset(e), reset_guard(f))))
```
- Si `ip` cambió, fue `Ip{_}` o un fin de pulso aceptado (guarda explícita).
- **Origen: HIP (A-22).** Marco.

### 2.7 V1: dominio de verdictos del certificado (3) — TÉCNICA

```bend
law verdict_frame_step:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +h: {Spec.is_tick(e) == False{} : Bool}
  for +bt: Bool
  for +bh: Bool
  {S.step_fin(o, f, e, bt, bh) == S.step_fin(o, f, e, True{}, True{}) : S.Fin}
```
- Línea 5: hipótesis: el evento **no** es `Tick`. Línea 8: entonces el paso da lo mismo con cualquier par de verdictos que con `(True, True)`. Es una igualdad proposicional (`==` en `S.Fin`), no un Bool.
- **Origen: TÉCNICA.** Justifica que `enum_jetprot.bend` enumere los cuatro pares `(bt, bh)` sólo en las 5 columnas anchas (`Tick{True}`, `Tick{False}`, `Reset`, `CommFault{True, True}` y `Stop{LPtn, True}`) y certifique las otras 23 en `(True, True)`: la reducción de columnas pasa de chequeo mecánico (H13) a teorema.

```bend
law verdict_frame_hb:
  ...mismas hipótesis...
  {S.upd_hb(f, e, bh) == S.upd_hb(f, e, True{}) : S.Upd}

law verdict_frame_tack:
  ...mismas hipótesis...
  {S.upd_tack(f, e, bt, bh) == S.upd_tack(f, e, True{}, True{}) : S.Upd}
```
- Lo mismo para los dos comandos de contador. **Origen: TÉCNICA.**

### 2.8 P20 sobre estados completos (2)

```bend
law reset_accepted:
  for +o: S.Ord
  for +s: S.St
  for +h: {S.reset_ok(S.fin_of(s)) == True{} : Bool}
  {S.step_o(o, s, S.Reset{}) == S.init() : S.St}
```
- Con la guarda verdadera, un `Reset` sobre el estado completo (contadores incluidos) da exactamente `init()`. Igualdad proposicional, probada por reescritura desde P20 y la forma de los comandos.
- **Origen: HIP (A-14).**

```bend
law reset_refused:
  for +o: S.Ord
  for +s: S.St
  for +h: {S.reset_ok(S.fin_of(s)) == False{} : Bool}
  {S.step_o(o, s, S.Reset{}) == s : S.St}
```
- Con la guarda falsa, `Reset` es la identidad sobre el estado completo.
- **Origen: HIP (A-14).**

### 2.9 Corolarios de estado (4) — desde `corollaries_check` por reflexión

Todos tienen la forma: `for +f: S.Fin`, `for +h: {S.inv_fin(f) == True{}}`, meta Bool sobre `f`. Valen para todo estado alcanzable porque `traces_safe` garantiza `inv_fin`.

```bend
law ptn_no_heat:
  {S.implies(S.is_ptn(S.level_of(f)), Bool.and(S.unpowered(S.nb_of(f)), S.unpowered(S.rf_of(f)))) == True{} : Bool}
```
- Bajo PTN, ambas unidades están `Off`. **Origen: MIXTA (R-0, R-11 + A-9)**: que toda salida del PTN apague el calentamiento está documentado sólo para las que disparan el DMS (R-11), como en `ptn_deenergizes`; que ninguna unidad vuelva a prenderse bajo el stop también es A-9.

```bend
law dms_no_heat:
  {S.implies(Bool.not(S.is_idle(S.dms_of(f))), Bool.and(S.unpowered(S.nb_of(f)), S.unpowered(S.rf_of(f)))) == True{} : Bool}
```
- Con el DMS armado o disparado, ambas unidades están `Off`. **Origen: MIXTA (R-11, [S6] + A-9).** Que el calentamiento esté apagado antes de activar la válvula es R-11 y [S6] ("Heating systems cannot be operating when the DMV is activated"); que siga apagado después de la inyección, hasta el fin del pulso, es A-9, como en `ptn_no_heat`.

```bend
law stop_no_full_power:
  {S.implies(Bool.not(S.is_none(S.level_of(f))), Bool.and(Bool.not(S.is_hot(S.nb_of(f))), Bool.not(S.is_hot(S.rf_of(f))))) == True{} : Bool}
```
- Con cualquier stop en vigor, ninguna unidad entrega potencia (plena ni parcial). **Origen: MIXTA** (R-3/R-4 para el efecto del stop; "ni parcial" y "nunca vuelve" son A-9).

```bend
law termination_no_full_power:
  {S.implies(S.is_term(S.wave_of(f)), Bool.and(Bool.not(S.is_hot(S.nb_of(f))), Bool.not(S.is_hot(S.rf_of(f))))) == True{} : Bool}
```
- En la fase de onda Termination, ninguna unidad entrega potencia. **Origen: HIP (A-9).**

### 2.10 Lo que P1 y D1 dicen sobre el PTN y el stop primario, con nombre propio (5), y la demanda de la instancia 4 (1) — revisión 4

P1 y D1 mezclan lo que JET documenta sobre el PTN con nuestra política entre los dos stops suaves. Estas cinco leyes de celda (grupo `g_j` del certificado, molde de §1) enuncian por separado lo que P1 y D1 dicen sobre el PTN y el stop primario, para poder citarlo sin la política entre stops suaves. Dos son **HECHO JET** (`p1a_ptn_latched`, `d1b_primary_honoured`) y tres son **MIXTAS**: juntan un enunciado de JET con una formalización nuestra, declarada en cada entrada (`p1b_stop_never_cleared`, `d1a_ptn_honoured`, `piw_after_ptn_is_noop`). Fuente principal: [N1] De Tommasi et al. 2013, páginas del PDF del preprint. Cuatro son **derivadas** (§6.5); `piw_after_ptn_is_noop` no lo es. El tope de [N1], "a maximum of two in sequence" (p.13 del PDF; traducción nuestra: como máximo dos seguidas; que sean dos stops suaves es lectura nuestra), **no** es una ley: con dos niveles suaves y orden estricto se cumple por construcción (A-2).

**P1a `p1a_ptn_latched`** — meta `pr_p1a(f, e, f2)`.
```bend
def pr_p1a(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(S.is_ptn(S.level_of(f)), Bool.not(is_reset(e))), S.is_ptn(S.level_of(f2)))
```
- Con el PTN en vigor y un evento que no es `Reset`, el nivel siguiente sigue siendo PTN.
- **Origen: JET (R-0; [N1] p.14 del PDF).** "The PTN output is a latched stop signal" (R-0) y "a PIW stop can never preempt a PTN stop" ([N1]). Derivada: es el caso PTN de P1 (el PTN está arriba en los dos órdenes).

**P1b `p1b_stop_never_cleared`** — meta `pr_p1b(f, e, f2)`.
```bend
def pr_p1b(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(Bool.not(S.is_none(S.level_of(f))), Bool.not(is_reset(e))), Bool.not(S.is_none(S.level_of(f2))))
```
- Un stop en vigor (JTT, RTPS o PTN) no vuelve a "sin stop" salvo con `Reset`.
- **Origen: MIXTA (R-0 + A-14).** Para el PTN es hecho de JET: "The PTN output is a latched stop signal" (R-0). Para los stops suaves es lectura nuestra: ninguna fuente publica una forma de cancelar un stop (A-14, un argumento por ausencia) y [S1] presenta los stops como la manera de terminar el pulso (overrides "which truncate the experiment and land the plasma safely", R-8). R-6 ("allowing it to run to completion") habla de no pasar a una secundaria, no de borrar un stop. No es una frase de [N1]. Derivada: es el caso None de P1.

**D1a `d1a_ptn_honoured`** — meta `pr_d1a(e, f2)`.
```bend
def pr_d1a(+e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(is_stop(e), S.is_ptn(ev_req(e))),
          Bool.and(S.is_ptn(S.level_of(f2)), Bool.and(S.unpowered(S.nb_of(f2)), S.unpowered(S.rf_of(f2)))))
```
- Un `Stop` que pide PTN deja el nivel en PTN y las dos unidades apagadas, desde **cualquier** estado, con o sin un stop suave en curso.
- **Origen: MIXTA.** Que un pedido de PTN se atienda aun con un stop PIW en curso es HECHO JET ([N1] p.13 del PDF: los stops PTN "can be triggered even after a PIW stop is in execution"); que las dos unidades queden en `Off` es A-9, como en `ptn_deenergizes` (documentado para las salidas del PTN que disparan el DMS, R-11; para las demás sólo la "fixed shutdown sequence" de R-0), y que sea en el mismo paso es la abstracción sin tiempo del modelo (A-15; NBI 2 ms, RF ~38 ms, [S6]). Absorbe la ley propuesta "el PTN le gana al PIW". Derivada: el caso PTN de D1 más P2 (desde abajo del PTN) y P6 con la preservación (desde un PTN ya trabado, sólo en estados que cumplen el invariante).

**D1b `d1b_primary_honoured`** — meta `pr_d1b(f, e, f2)`.
```bend
def pr_d1b(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(S.is_none(S.level_of(f)), Bool.and(is_stop(e), S.is_soft(ev_req(e)))),
          lvl_eq(S.level_of(f2), ev_req(e)))
```
- Sin stop en vigor, un pedido suave (JTT o RTPS) pasa a ser la respuesta, bajo cualquiera de los dos órdenes.
- **Origen: JET (R-5; [N1] p.13 del PDF).** La tabla primaria define la respuesta (R-5) y "RTPS will select the stop and send it to SC" ([N1]). Derivada: es el caso "nivel None" de D1.

**`piw_after_ptn_is_noop`** — meta `pr_piw_noop(f, e, bt, bh, f2)`.
```bend
def pr_piw_noop(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(S.is_ptn(S.level_of(f)), Bool.and(is_stop(e), Bool.not(S.is_ptn(ev_req(e))))),
          Bool.and(fin_eq(f, f2), Bool.and(S.is_keep(S.upd_hb(f, e, bh)), S.is_keep(S.upd_tack(f, e, bt, bh)))))
```
- Con el PTN en vigor, un `Stop` que no pide PTN no cambia nada: ni el control ni los comandos a los dos contadores.
- **Origen: MIXTA.** JET: pedir un stop PIW "after a PTN stop was already being executed" es una "invalid task" ([N1] p.13 del PDF), frase de las pruebas de aceptación del simulador del controlador de forma, que ante una tarea inválida "still follows the correct path of action"; y un stop PIW nunca desplaza a un PTN (p.14). Que ese pedido deje igual todo el estado y los dos comandos a los contadores, en el paso del RTPS, es formalización nuestra (A-14; los comandos a los contadores son los de A-11 y A-12): es justo la parte que hace que la ley no sea derivada. **No es derivada**: ninguna ley anterior prohibía que el contador del watchdog recibiera `CInc` ante un stop con el PTN trabado; la métrica de estrechez de los comandos a contadores subió de 212 a 243 celdas de 400. La atrapa también el negativo `bug11_piw_overrides_ptn`.

**`inst4_second_alarm_ptn`** — fuera de molde (capa concreta).
```bend
law inst4_second_alarm_ptn:
  for +s: S.St
  for +t: S.Trig
  for +h_soft: {S.is_soft(S.level_of(S.fin_of(s))) == True{} : Bool}
  for +h_cfg: {S.is_none(S.masked_table(S.Inst4{}, S.prog_of(S.fin_of(s)), t)) == False{} : Bool}
  {S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, s, S.XAlarm{t})))) == True{} : Bool}
```
- Línea 2: todo estado completo. Línea 3: todo disparador. Línea 4: hay un stop suave en curso. Línea 5: la entrada primaria de la instancia 4, en la fase del programa, pide alguna respuesta. Línea 6: el paso concreto de la instancia 4 con esa alarma enclava el PTN. Es el caso de A-16 (un DHS leído como JTT durante un stop RTPS, que las instancias 1 a 3 ignoran): en la instancia 4 da PTN. La atrapa el negativo `bug12_secondary_ignored`.
- **Origen: MIXTA.** Mecanismo de JET ([S1] R-6: "two levels of stop response, primary, and secondary") + contenido inventado (A-35: la tabla secundaria ilustrativa, no la de JET, que no está publicada).

## 3. `LAWS_JETPROT_CONF.bend` — 143 leyes de conformidad

### 3.1 Molde (vale para 133 de las 143)

```bend
law pub_Heating2_Dhs:                                                    # (1)
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Dhs{}), S.LJtt{}) == True{} : Bool}   # (2)
```
1. El nombre codifica `prefijo_Fase_Disparador`. Prefijos: `pub_` = celda impresa o por ditto en la Tabla 1 de [S1]; `asm_` = columna ausente, celda asumida (A-4, A-25); `inst2_` = celda que la instancia 2 cambia; `inst2_same_` = celda que la instancia 2 copia de la 1; `dms_trig_`, `dms_window_`, `dms_on_` = cableado del DMS; `mask_` = máscaras.
2. `table1(fase, disparador)` es la matriz del modelo (`jetprot.bend`); el valor esperado (`LPtn`, `LRtps`, `LJtt`, `LNone`) es una **segunda transcripción, separada**, escrita a mano en este archivo. `lvl_eq` compara rangos. Se prueba por cómputo (`{==}`), una ley por celda, en 0,7 s (corrida del 2026-09-22).

Cada ley es una celda; para no repetir 133 veces el molde, las tablas siguientes dan **el código reducido a (fase, disparador) → valor esperado** y el origen.

### 3.2 `pub_*` — las 28 celdas de la Tabla 1 de [S1] — JET (R-5)

Columnas Slow, MHD, MCHS, DHS × 7 fases. `ⁱ` = celda leída de una marca ditto `|` (13 celdas); las otras 15 están impresas. La lectura ditto fue verificada forénsicamente por dos revisores (glifo U+007C centrado en la columna, sin objetos vectoriales en la página), así que se cuenta como JET, con esa salvedad.

| Fase | `_Slow` | `_Mhd` | `_Mchs` | `_Dhs` |
|---|---|---|---|---|
| Breakdown | LPtn | LNone | LNone | LPtn |
| IpRise | LPtn ⁱ | LNone ⁱ | LNone ⁱ | LPtn ⁱ |
| Limiter | LPtn | LNone ⁱ | LNone ⁱ | LPtn ⁱ |
| Xpoint | LPtn | LNone ⁱ | LNone ⁱ | LPtn ⁱ |
| Heating1 | LRtps | LNone ⁱ | LRtps | LPtn |
| Heating2 | LRtps | LNone ⁱ | LRtps | **LJtt** |
| Termination | LPtn | LNone ⁱ | LPtn | LPtn |

Salvedad adicional de R-5: la identificación de la columna "Slow" con el disparador "slow termination" de R-2 es inferencia nuestra, declarada en `phase3-sources.md` como A-31. Por eso las 7 leyes `pub_*_Slow` son hecho de JET más inferencia nuestra: las celdas están impresas, la identificación de la columna no.

### 3.3 `asm_*` — las 21 celdas de columnas ausentes — HIP (A-4)

| Fase | `_Fast` | `_MhdB` | `_BothHs` |
|---|---|---|---|
| Breakdown | LPtn | LNone | LPtn |
| IpRise | LPtn | LNone | LPtn |
| Limiter | LPtn | LNone | LPtn |
| Xpoint | LPtn | LNone | LPtn |
| Heating1 | LPtn | LNone | LPtn |
| Heating2 | LPtn | LNone | **LRtps** |
| Termination | LPtn | LNone | LPtn |

- `Fast → PTN` en toda fase: el mecanismo ("fast termination [...] through PTN") es R-7; la uniformidad es nuestra y es **una configuración posible** entre varias (A-4): [N1] fig. 6 lista también un stop PIW llamado "Fast". `MhdB = Mhd`: nuestro. `BothHs` = el más urgente de MCHS y DHS bajo `Ord1` (A-1, A-32): es una **cota inferior** que depende de A-1 (en JET "MCHS+DHS" es un disparador configurado por separado, [N1] fig. 6); en Heating 2 da RTPS porque JTT < RTPS en nuestro orden, y con el otro orden (`Ord2`) `asm_Heating2_BothHs` daría JTT. Etiqueta en el registro: *fabricated*.

### 3.4 `asm_*_Blind` — la fila del disparador ciego (7) — HIP (A-25)

`asm_Breakdown_Blind` … `asm_Termination_Blind`: `table1(p, Blind) = LPtn` en las siete fases. R-13 dice que el VTM define "blind stop alarms"; su fila **no** está publicada. Etiqueta: *fabricated*.

### 3.5 `inst2_*` — la segunda instancia (14 + 42) — HIP

Instancia 2 (`table2`): igual a la 1 salvo que MHD y MHD-B llegan al PTN desde X-point:

| Fase | `inst2_*_Mhd` | `inst2_*_MhdB` |
|---|---|---|
| Breakdown, IpRise, Limiter | LNone | LNone |
| Xpoint, Heating1, Heating2, Termination | LPtn | LPtn |

- Motivación: [S6], sobre la señal de modo bloqueado: "It is already used at JET to soft-stop the pulse"; y [S7]: PETRA "triggers a stop and MGI" en modo bloqueado; la Tabla 1 de 2011 tiene MHD = None. La instancia es **nuestra**: los valores no están en ninguna tabla publicada.

`inst2_same_*` (42 = 6 disparadores × 7 fases: Slow, Fast, Mchs, Dhs, BothHs, Blind): cada una dice `lvl_eq(table2(p, t), table1(p, t))`, es decir, que la instancia 2 copia la 1 en esa celda. Origen HIP: es la definición de nuestra instancia.

### 3.6 Cableado del DMS (17)

```bend
law dms_trig_Fast:  {S.dms_trig(S.Fast{}) == True{} : Bool}
law dms_trig_Mhd:   {S.dms_trig(S.Mhd{}) == True{} : Bool}
law dms_trig_MhdB:  {S.dms_trig(S.MhdB{}) == True{} : Bool}
law dms_trig_Slow:  {S.dms_trig(S.Slow{}) == False{} : Bool}
law dms_trig_Mchs:  {S.dms_trig(S.Mchs{}) == False{} : Bool}
law dms_trig_Dhs:   {S.dms_trig(S.Dhs{}) == False{} : Bool}
law dms_trig_BothHs:{S.dms_trig(S.BothHs{}) == False{} : Bool}
law dms_trig_Blind: {S.dms_trig(S.Blind{}) == False{} : Bool}
```
- Qué disparadores llevan el bit DMS: los precursores de disrupción y la terminación rápida. Igualdad proposicional sobre `Bool`. **Origen: HIP (A-10).** [S6] dice que la DMV "can be attached to any of the stops"; cuáles, es configuración nuestra.

```bend
law dms_window_Breakdown:   {S.dms_window(S.Breakdown{}) == False{} : Bool}
law dms_window_IpRise:      {S.dms_window(S.IpRise{}) == False{} : Bool}
law dms_window_Limiter:     {S.dms_window(S.Limiter{}) == False{} : Bool}
law dms_window_Xpoint:      {S.dms_window(S.Xpoint{}) == True{} : Bool}
law dms_window_Heating1:    {S.dms_window(S.Heating1{}) == True{} : Bool}
law dms_window_Heating2:    {S.dms_window(S.Heating2{}) == True{} : Bool}
law dms_window_Termination: {S.dms_window(S.Termination{}) == True{} : Bool}
```
- La ventana de habilitación de la DMV, leída en la fase de onda: X-point … Termination. **Origen: JET (R-14)** para las seis primeras: "enabled only for a pre-programmed time window during the pulse, generally between the X-point formation and the end of the post-heating phase." Salvedad (A-10): en JET la ventana se programa por pulso y el modelo la fija. `dms_window_Termination` es **MIXTA (R-14 + A-10)**: **extiende** la ventana de [S6], que se cierra "generally" al final de la fase posterior al calentamiento, a toda la fila de Termination.

```bend
law dms_on_commfault_off: {S.dms_on_commfault() == False{} : Bool}
law dms_on_watchdog_off:  {S.dms_on_watchdog() == False{} : Bool}
```
- Los dos caminos cableados (fallo de comunicación, watchdog) no arman el DMS en ninguna instancia. **Origen: HIP (A-10, A-12, A-13).** Elección nuestra, igual para toda instancia; [S6] permitiría cualquiera. Es un **compromiso, no algo conservador** (A-12): un corte duro a alta corriente puede provocar una disrupción, y ésta quedaría sin mitigar.

### 3.7 Instancia 3 y máscaras (5) — HIP (A-21, A-25)

```bend
law inst3_uses_table1:
  for +p: S.Phase
  for +t: S.Trig
  {Spec.lvl_eq(S.table(S.Inst3{}, p, t), S.table1(p, t)) == True{} : Bool}
```
- Para toda fase y disparador, la instancia 3 lee la matriz publicada. Universal (56 celdas en una ley: 7 fases × 8 disparadores, `Blind` incluido).

```bend
law mask_inst1_checks_on:  {S.mask_of(S.Inst1{}) == S.Mask{True{}, True{}} : S.Mask}
law mask_inst2_checks_on:  {S.mask_of(S.Inst2{}) == S.Mask{True{}, True{}} : S.Mask}
law mask_inst3_checks_off: {S.mask_of(S.Inst3{}) == S.Mask{False{}, False{}} : S.Mask}
```
- `Mask{comm, blind}`: qué chequeos de fiabilidad habilita cada instancia. Las instancias 1 y 2, ambos; la tercera, ninguno (y se certifica igual: es el argumento de que la configuración de cada pulso debe certificarse, R-15). La máscara de la instancia 4 (ambos habilitados) es `inst4_mask`, §3.10.

```bend
law blind_masked_no_response:
  for +p: S.Phase
  {Spec.lvl_eq(S.masked_table(S.Inst3{}, p, S.Blind{}), S.LNone{}) == True{} : Bool}
```
- En toda fase, una alarma ciega con la máscara apagada no pide respuesta.

### 3.8 P13 `fast_ptn` (1) — MIXTA

```bend
law fast_ptn:
  for +i: S.Inst
  for +s: S.St
  {S.is_ptn(S.level_of(S.fin_of(S.step_c(i, s, S.XAlarm{S.Fast{}})))) == True{} : Bool}
```
- Línea 2: toda instancia (las cuatro). Línea 3: todo estado completo. Línea 4: un paso concreto con la alarma `Fast` deja el nivel en PTN. Universal sobre fases y estados, a diferencia de las celdas. Desde la revisión 4, con un stop en vigor la alarma pasa por la tabla secundaria.
- **Origen: MIXTA.** El mecanismo (Fast → PTN) es R-7; las 7 celdas son A-4, y "Fast → PTN siempre" es **una configuración posible** entre varias ([N1] fig. 6 lista también un stop PIW "Fast").

### 3.9 La capa concreta (2) — TÉCNICA

```bend
law concretize_is_the_table:
  {E.check_concretize() == True{} : Bool}
```
- `check_concretize` recorre 4 instancias × 7 fases × 2 (`jtt`) × 4 niveles en vigor × 24 eventos de planta = 5 376 celdas (desde la revisión 4; antes 3 × 7 × 2 × 24 = 1 008; hasta la auditoría del 2026-09-22 este texto decía 22 eventos, 4 928 y 924, cuentas mal hechas: el enumerador de la corrida de entonces ya recorría los 24, `XIp{ok}` incluido) y compara `concretize` contra una **cuarta** transcripción separada (`m_table1`, `m_table2`, `m_trig`, `m_win`, `m_sec` del enumerador). Atrapa una celda mal, una ventana mal, una lectura en la fase de onda, una máscara ignorada o una tabla secundaria mal leída. Qué fase se lee es nuestra lectura, no documentada (A-24, A-30).

```bend
law step_c_is_the_concrete_step:
  for +i: S.Inst
  for +s: S.St
  for +c: S.CEv
  {S.step_c(i, s, c) == S.step_o(S.Ord1{}, s, S.concretize(i, S.fin_of(s), c)) : S.St}
```
- Un paso concreto es exactamente el paso abstracto bajo `Ord1`, sobre el estado **anterior** a la transición, con la configuración de **esta** instancia. Sin esta ley, leer la matriz de otra instancia, la fase siguiente o el otro orden eran invisibles (mutantes N05/N06/N07).

### 3.10 Instancia 4 y tablas secundarias (6) — revisión 4

Una alarma que llega con un stop ya en vigor lee la **tabla secundaria** de la instancia, `sec_table(i, p, t)`, en vez de la primaria. El mecanismo está documentado ([S1] R-6: "two levels of stop response, primary, and secondary"); el contenido de la tabla de JET no está publicado. Las instancias 1 a 3 conservan la lectura anterior (la secundaria es la primaria otra vez); la instancia 4 usa una tabla ilustrativa (A-35).

```bend
law inst4_table:
  for +p: S.Phase
  for +t: S.Trig
  {Spec.lvl_eq(S.table(S.Inst4{}, p, t), S.table1(p, t)) == True{} : Bool}

law inst4_mask:
  {S.mask_of(S.Inst4{}) == S.Mask{True{}, True{}} : S.Mask}
```
- La instancia 4 lee la matriz publicada (la de la instancia 1) celda por celda, con los dos chequeos de fiabilidad habilitados. **Origen: HIP** (es la definición de nuestra instancia, como `inst2_same_*`).

```bend
law sec_legacy:
  for +p: S.Phase
  for +t: S.Trig
  {Bool.and(Spec.lvl_eq(S.sec_table(S.Inst1{}, p, t), S.masked_table(S.Inst1{}, p, t)),
   Bool.and(Spec.lvl_eq(S.sec_table(S.Inst2{}, p, t), S.masked_table(S.Inst2{}, p, t)),
            Spec.lvl_eq(S.sec_table(S.Inst3{}, p, t), S.masked_table(S.Inst3{}, p, t)))) == True{} : Bool}
```
- En las instancias 1 a 3 la tabla secundaria es la entrada primaria enmascarada: una segunda alarma relee la tabla primaria y el paso abstracto se queda con el máximo (A-2, A-16, A-24). **Origen: MIXTA** (mecanismo JET [S1] R-6 + contenido nuestro: la lectura de las revisiones 1 a 3).

```bend
law sec_inst4:
  for +p: S.Phase
  for +t: S.Trig
  {Spec.lvl_eq(S.sec_table(S.Inst4{}, p, t), E.m_sec(S.Inst4{}, p, t)) == True{} : Bool}
```
- La tabla secundaria de la instancia 4 es la regla ilustrativa: PTN donde la primaria pide alguna respuesta, nada donde no pide nada; comparada con la transcripción propia del enumerador (`m_sec`). **Origen: MIXTA** (mecanismo JET [S1] R-6 + contenido inventado, A-35; se inspira en la figura 7 de [N1], "The preferred secondary plasma stop is the PTN slow stop", p.23 del PDF, que es una estadística de uso).

```bend
law sec_monotone:
  for +o: S.Ord
  for +i: S.Inst
  for +p: S.Phase
  for +t: S.Trig
  {Spec.lvl_le(o, S.masked_table(i, p, t), S.sec_table(i, p, t)) == True{} : Bool}
```
- Ninguna entrada secundaria es menos urgente que la primaria, bajo los dos órdenes. **Origen: MIXTA** (mecanismo JET + propiedad de nuestro contenido).

```bend
law sec_primary_ptn:
  for +i: S.Inst
  for +p: S.Phase
  for +t: S.Trig
  {S.implies(S.is_ptn(S.masked_table(i, p, t)), S.is_ptn(S.sec_table(i, p, t))) == True{} : Bool}
```
- Si la entrada primaria es PTN, la secundaria también. Coincide con [N1] p.14 del PDF: "any primary PTN stop can never be followed by a PIW secondary". **Origen: MIXTA** (el hecho es de JET; que valga sobre nuestras tablas secundarias es propiedad de nuestro contenido).

## 4. `LAWS_JETPROT_LIVE.bend` — 2 teoremas de respuesta acotada (MIXTA)

Tres funciones auxiliares, explicadas línea a línea:

```bend
def ticks(trace: List<&2, S.Ev>) -> Nat:   # cuenta los Tick de una traza
  match trace:
    case Nil{}: 0n                         # traza vacía: cero
    case Con{e, t}:                        # cabeza e, cola t
      match e:
        case S.Tick{dms}: 1n+ticks(t)      # un Tick suma uno
        case _: ticks(t)                   # cualquier otro evento no cuenta

def no_hb(trace) -> Bool:                  # la traza no contiene Heartbeat ni Reset
  ... case S.Heartbeat{}: False   case S.Reset{}: False   case _: no_hb(t)

def no_reset(trace) -> Bool:               # la traza no contiene Reset
  ... case S.Reset{}: False   case _: no_reset(t)
```

```bend
law watchdog_responds:
  for +o: S.Ord                                                    # (1)
  for +s: S.St                                                     # (2)
  for +h_inv: {S.inv_all(s) == True{} : Bool}                       # (3)
  for +trace: List<&2, S.Ev>                                       # (4)
  for +h_nohb: {no_hb(trace) == True{} : Bool}                      # (5)
  for +h_len: {Nat.is_le(S.hb_max(), ticks(trace)) == True{} : Bool} # (6)
  {S.is_ptn(S.level_of(S.fin_of(S.run_o(o, trace, s)))) == True{} : Bool}  # (7)
```
1. Todo orden. 2. Todo estado completo. 3. Que cumple el invariante (en particular I6: `hb < hb_max`). 4. Toda traza. 5. Sin `Heartbeat` ni `Reset`. 6. Con al menos `hb_max` ticks. 7. Correr la traza deja el PTN enclavado. Se prueba por inducción sobre la traza en `PROOF_JETPROT_LIVE_CORE.bend` a partir de ocho hechos de celda (`step_safe`, P1, D4, D7, D8, P15, P18, E11) tomados como hipótesis de plantilla. Está verificada para el `hb_max` del modelo (3): la inducción sólo lo compara con cuentas de ticks y con el contador, así que el argumento debería valer para otros límites, pero ningún enunciado verificado cuantifica sobre él.
- **Origen: MIXTA.** El watchdog al PTN es R-13 (JET); el contador (ticks sin `Heartbeat` desde Breakdown, reiniciado por cada `Heartbeat`, con guarda por nivel) es formalización nuestra, A-12; contar en ticks y no en ms es A-15, común a todas las leyes (§0).

```bend
law dms_responds:
  for +o: S.Ord
  for +s: S.St
  for +h_inv: {S.inv_all(s) == True{} : Bool}
  for +h_armed: {S.is_armed(S.dms_of(S.fin_of(s))) == True{} : Bool}   # el DMS está armado
  for +trace: List<&2, S.Ev>
  for +h_noreset: {no_reset(trace) == True{} : Bool}                    # sin fin de pulso
  for +h_len: {Nat.is_le(S.ack_max(), ticks(trace)) == True{} : Bool}   # al menos ack_max ticks
  {Spec.is_fired(S.dms_of(S.fin_of(S.run_o(o, trace, s)))) == True{} : Bool}  # el DMS disparó
```
- Igual esquema: desde un estado del invariante con el DMS armado, toda traza sin `Reset` con ≥ `ack_max` ticks termina con el DMS disparado (por acknowledgement o por timeout).
- **Origen: MIXTA.** La secuencia apagar → ack o timeout → inyectar es R-11/[S6]; el contador de espera y su tope `ack_max` son formalización nuestra, A-11; contar en ticks es A-15, común a todas las leyes (§0).

## 5. `LAWS_JETPROT_SOUND.bend` — 8 leyes de solidez (TÉCNICA)

Todas las leyes de marco concluyen `fin_eq(f, f2) == True{}` (o `unit_eq`, `lvl_eq`): un Bool decidido comparando rangos. Nada ataba ese Bool a la igualdad proposicional: un predicado que confundiera dos constructores habría hecho vacuas esas leyes sin que Bend lo notara (bloqueante 1). Estas leyes son el puente. Se prueban por partición exhaustiva de casos, sin inducción. Ninguna dice nada sobre JET.

```bend
law beq_sound:
  for a: Bool
  for b: Bool
  for h: {Spec.beq(a, b) == True{} : Bool}
  {a == b : Bool}
```
- Líneas 2–3: dos booleanos (sin `+`: se usan una vez). Línea 4: hipótesis: el predicado los declara iguales. Línea 5: entonces son el mismo término.

Con la misma estructura exacta (cambia el tipo y el predicado):

| Ley | Tipo | Predicado | Constructores |
|---|---|---|---|
| `unit_eq_sound` | `S.Heat` | `unit_eq` (por `unit_rank`) | 4 |
| `dms_eq_sound` | `S.Dms` | `dms_eq` (por `dms_rank`) | 3 |
| `lvl_eq_sound` | `S.Level` | `lvl_eq` (por `lvl_rank` bajo `Ord1`) | 4 |
| `phase_eq_sound` | `S.Phase` | `phase_eq` (por `phase_rank`) | 7 |
| `fin_eq_sound` | `S.Fin` | `fin_eq` (conjunción campo a campo de los anteriores; hipótesis con `+h`) | 8 campos |

```bend
law lvl_le_refl:
  for o: S.Ord
  for a: S.Level
  {Spec.lvl_le(o, a, a) == True{} : Bool}
```
- Bajo ambos órdenes, todo nivel es ≤ sí mismo.

```bend
law lvl_le_sound:
  for o: S.Ord
  for a: S.Level
  for b: S.Level
  for h1: {Spec.lvl_le(o, a, b) == True{} : Bool}
  for h2: {Spec.lvl_le(o, b, a) == True{} : Bool}
  {a == b : S.Level}
```
- Antisimetría bajo ambos órdenes: dos niveles cada uno ≤ el otro son el mismo. Es lo que hace que P1, enunciada con `lvl_le`, hable de niveles y no del predicado.

## 6. Enumeración por origen

### 6.1 Origen JET (44): el contenido es una cita R-n, una frase de [N1] o una celda de la Tabla 1

**LAWS_JETPROT (10):** `commfault_ptn` (R-13) · `d4_watchdog_latches` (R-13) · `d7_ack_timeout_fires` (R-11) · `d9_heatack_fires` (R-11) · `e2_dms_fire_frame` (R-11) · `f2a_local_reduces` (R-9) · `ip1_low_never_arms` (R-14) · `ip2_arms_on_demand` (R-11, R-14) · revisión 4: `p1a_ptn_latched` (R-0, [N1] p.14) · `d1b_primary_honoured` (R-5, [N1] p.13).

**CONF (34):** las 28 `pub_*` (R-5; 15 impresas, 13 por ditto; las 7 `pub_*_Slow` son hecho de JET más inferencia nuestra, A-31) · 6 de las 7 `dms_window_*` (R-14; `dms_window_Termination` es MIXTA, §6.3).

### 6.2 Origen hipótesis nuestra (140): el contenido es una decisión A-n

**LAWS_JETPROT (39):**
- Orden y política: `latched` (A-1, A-2).
- Efecto de los stops en las unidades: `ramping_never_returns`, `stop_overrides_heat`, `termination_no_full_power`, `d3_advance_to_termination_ramps`, `e4_advance_units` (A-9).
- Marcos de unidades: `heat_frame`, `d15_heatoff_is_local`, `d16_heaton_is_local`, `f4_units_frame` (A-19).
- Potencia parcial: `f2d_reduced_never_returns` (A-6, A-7).
- Fases y programa: `phase_monotone`, `d11_advance_is_one_step`, `d12_phase_frame` (A-5).
- Dos vistas del tiempo: `f1b_stop_keeps_prog`, `f1c_wave_ahead`, `f1d_wave_frame`, `f1e_jtt_exact` (A-24).
- DMS: `tack_frame`, `d8_ack_counts`, `d17_heatack_frame`, `e7_tack_inc_frame`, `e8_tack_reset_frame` (A-11).
- Watchdog: `inv_init`, `d5_hb_counts`, `d6_hb_frame`, `d18_heartbeat_frame`, `e5_heartbeat_resets_hb`, `e6_hb_tick_exact` (A-12).
- Cierre de causas del nivel: `no_spurious_stop` (A-12, A-13).
- Fin de pulso: `reset_guarded`, `reset_refused_mid_pulse`, `d10_reset_accepted_when_safe`, `reset_accepted`, `reset_refused` (A-14).
- Plasma como entrada: `d13_plasma_is_input`, `d14_plasma_frame` (A-8).
- Veredicto de habilitación del DMV como entrada: `ip3_ip_is_input`, `ip4_ip_frame` (A-22).

**CONF (101):** las 21 `asm_*` Fast/MhdB/BothHs (A-4, A-32) · las 7 `asm_*_Blind` (A-25) · las 14 `inst2_*` y las 42 `inst2_same_*` (instancia 2, nuestra) · las 8 `dms_trig_*` y `dms_on_commfault_off`, `dms_on_watchdog_off` (A-10, A-12) · `inst3_uses_table1`, `mask_inst1_checks_on`, `mask_inst2_checks_on`, `mask_inst3_checks_off`, `blind_masked_no_response` (A-21, A-25) · revisión 4: `inst4_table`, `inst4_mask` (instancia 4, nuestra).

### 6.3 Origen mixto (32): mecanismo de JET, forma exacta nuestra

`pres_fin`, `pres_i5`, `pres_i6` (I1–I6) · `local_is_local` (R-9 + A-6/A-7) · `d1_stop_honoured` (R-7 + A-2) · `dms_armed_on_demand` (R-11/R-14 + A-10) · `e3_stop_phase_exact` (R-4 + A-24) · `e11_heatack_exact` (R-11 + A-11) · `f1a_table_reads_prog` (R-5 + A-24) · `stop_no_full_power` (R-3/R-4 + A-9) · `fast_ptn` (R-7 + A-4) · `watchdog_responds` (R-13 + A-12) · `dms_responds` (R-11 + A-11) · revisión 4, mecanismo JET [S1] R-6 + contenido nuestro o inventado (A-16, A-35): `inst4_second_alarm_ptn`, `sec_legacy`, `sec_inst4`, `sec_monotone`, `sec_primary_ptn` · pasadas de JET a MIXTA por la auditoría del 2026-09-22: `p1b_stop_never_cleared` (R-0 + A-14), `d1a_ptn_honoured` ([N1] p.13 + A-9), `piw_after_ptn_is_noop` ([N1] p.13 + A-14), `dms_window_Termination` (R-14 + A-10), `ptn_deenergizes` y `ptn_no_heat` (R-0, R-11 + A-9), `stop_reduces_power` (R-3, R-4 + A-9), `d2_soft_stop_ramps` (R-4 + A-9), `heat_permissive` (R-12 + A-5, A-8, A-9), `advance_frozen` (R-0 + A-11, A-12) · pasadas por la revisión del 2026-09-23, con la misma regla: `dms_no_heat` (R-11, [S6] + A-9), `dms_monotone` ([S6] + A-11), `dms_frame` (R-14 + A-10, A-11), `f3b_commfault_masked_is_noop` ([S1] + A-21).

Por archivo: LAWS_JETPROT 24 (las diez primeras, `inst4_second_alarm_ptn`, las nueve de la auditoría y las cuatro de la revisión del 2026-09-23), CONF 6 (`fast_ptn`, las cuatro `sec_*` y `dms_window_Termination`), LIVE 2.

### 6.4 Técnicas (18): existen por el método de prueba, no dicen nada de JET

`finite_check`, `finite_check_alt`, `corollaries_check`, `traces_safe`, `traces_safe_concrete`, `verdict_frame_step`, `verdict_frame_hb`, `verdict_frame_tack` · `concretize_is_the_table`, `step_c_is_the_concrete_step` · las 8 de `LAWS_JETPROT_SOUND.bend`.

### 6.5 Doce leyes derivadas (no son evidencia independiente)

`d3_advance_to_termination_ramps` ⊂ `e4_advance_units`; `d5_hb_counts` ⊂ `e6_hb_tick_exact`; `d9_heatack_fires` ⊂ `e11_heatack_exact`; `d10_reset_accepted_when_safe` ⇐ `reset_guarded` (se conserva para romper la autorreferencia de P20); `f1b_stop_keeps_prog` ⊂ `d12_phase_frame` (es su cláusula Stop; se conserva como enunciado nombrado de A-24); `f2a_local_reduces` ⊂ `local_is_local` (es su mitad de reducción; se conserva como enunciado nombrado de R-9); revisión 4: `p1a_ptn_latched` ⊂ `latched` (su caso PTN), `p1b_stop_never_cleared` ⊂ `latched` (su caso None), `d1a_ptn_honoured` ⊂ `d1_stop_honoured` + `ptn_deenergizes` + `stop_overrides_heat` con la preservación (desde un PTN ya trabado, sólo en estados del invariante), `d1b_primary_honoured` ⊂ `d1_stop_honoured` (su caso "nivel None"); auditoría del 2026-09-22: `ramping_never_returns` (P4) y `stop_overrides_heat` (P6) ⇐ `heat_permissive` (P5) ∧ `heat_frame` (P7): si una unidad sin potencia pasa a tener potencia, P7 obliga a que el evento sea su `HeatOn`, y P5 sólo lo acepta desde `Off` y con `permit(f)`, que exige que no haya stop; así que ni una unidad en `Ramping` (P4) ni una unidad bajo un stop (P6) pueden volver a tener potencia. Se verificó sobre todo el dominio en el modelo de referencia en Python (todas las celdas del certificado, con los 16 pares de valores de las unidades en el estado siguiente): 0 contraejemplos. `piw_after_ptn_is_noop` **no** es derivada: agrega una restricción sobre los contadores. La lista canónica es `DERIVED` en `pymodel/jetprot_laws.py`, que las lista a las doce; un informe no debe presentarlas como independientes. Ser derivada no cambia el origen: `f2a_local_reduces` sigue siendo HECHO JET y `f1b_stop_keeps_prog` sigue siendo HIP, sólo que no cuentan como evidencia adicional.

> **Resuelta en la revisión 4 (2026-09-22):** el comentario de cabecera de `LAWS_JETPROT.bend` ahora lista las leyes derivadas previas (ocho desde la auditoría del 2026-09-22, que sumó P4 y P6) más las cuatro nuevas y remite a `pymodel/jetprot_laws.py`. Aclaración del 2026-09-23: ningún gate lee `DERIVED` (no está en `results.json`); es la lista canónica que citan los documentos, así que la nota original se equivoca al decir que la leen los gates. Nota original:
>
> **Discrepancia detectada (2026-09-22).** El comentario de cabecera de `LAWS_JETPROT.bend` (sección E2..E11) dice "cinco", lista `D12_phase_frame` en lugar de `F1b`/`F2a`, e invierte la dirección de la relación (F1b es el caso Stop de D12, no al revés); además apunta a `pymodel/jetprot_ref.py`, que no contiene la lista. La fuente correcta es `pymodel/jetprot_laws.py`, que es la que leen los gates.

## Anexo A. Nombres completos de las 133 leyes de celda de `LAWS_JETPROT_CONF.bend`

Una línea por ley, con el código exacto del archivo y el origen. Complementa las tablas de §3.

```bend
# JET (R-5, Tabla 1 de [S1])
law pub_Breakdown_Slow:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.Slow{}), S.LPtn{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_IpRise_Slow:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.Slow{}), S.LPtn{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Limiter_Slow:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.Slow{}), S.LPtn{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Xpoint_Slow:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.Slow{}), S.LPtn{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Heating1_Slow:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.Slow{}), S.LRtps{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Heating2_Slow:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Slow{}), S.LRtps{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Termination_Slow:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.Slow{}), S.LPtn{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Breakdown_Mhd:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.Mhd{}), S.LNone{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_IpRise_Mhd:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.Mhd{}), S.LNone{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Limiter_Mhd:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.Mhd{}), S.LNone{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Xpoint_Mhd:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.Mhd{}), S.LNone{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Heating1_Mhd:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.Mhd{}), S.LNone{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Heating2_Mhd:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Mhd{}), S.LNone{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Termination_Mhd:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.Mhd{}), S.LNone{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Breakdown_Mchs:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.Mchs{}), S.LNone{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_IpRise_Mchs:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.Mchs{}), S.LNone{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Limiter_Mchs:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.Mchs{}), S.LNone{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Xpoint_Mchs:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.Mchs{}), S.LNone{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Heating1_Mchs:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.Mchs{}), S.LRtps{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Heating2_Mchs:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Mchs{}), S.LRtps{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Termination_Mchs:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.Mchs{}), S.LPtn{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Breakdown_Dhs:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_IpRise_Dhs:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Limiter_Dhs:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Xpoint_Dhs:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Heating1_Dhs:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Heating2_Dhs:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Dhs{}), S.LJtt{}) == True{} : Bool}
# JET (R-5, Tabla 1 de [S1])
law pub_Termination_Dhs:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Breakdown_Fast:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.Fast{}), S.LPtn{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_IpRise_Fast:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.Fast{}), S.LPtn{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Limiter_Fast:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.Fast{}), S.LPtn{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Xpoint_Fast:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.Fast{}), S.LPtn{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Heating1_Fast:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.Fast{}), S.LPtn{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Heating2_Fast:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Fast{}), S.LPtn{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Termination_Fast:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.Fast{}), S.LPtn{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Breakdown_MhdB:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.MhdB{}), S.LNone{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_IpRise_MhdB:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.MhdB{}), S.LNone{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Limiter_MhdB:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.MhdB{}), S.LNone{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Xpoint_MhdB:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.MhdB{}), S.LNone{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Heating1_MhdB:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.MhdB{}), S.LNone{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Heating2_MhdB:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.MhdB{}), S.LNone{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Termination_MhdB:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.MhdB{}), S.LNone{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Breakdown_BothHs:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_IpRise_BothHs:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Limiter_BothHs:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Xpoint_BothHs:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Heating1_BothHs:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Heating2_BothHs:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.BothHs{}), S.LRtps{}) == True{} : Bool}
# HIP (A-4, columna ausente)
law asm_Termination_BothHs:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_Breakdown_Mhd:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.Mhd{}), S.LNone{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_IpRise_Mhd:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.Mhd{}), S.LNone{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_Limiter_Mhd:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.Mhd{}), S.LNone{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_Xpoint_Mhd:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.Mhd{}), S.LPtn{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_Heating1_Mhd:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.Mhd{}), S.LPtn{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_Heating2_Mhd:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.Mhd{}), S.LPtn{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_Termination_Mhd:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.Mhd{}), S.LPtn{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_Breakdown_MhdB:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.MhdB{}), S.LNone{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_IpRise_MhdB:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.MhdB{}), S.LNone{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_Limiter_MhdB:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.MhdB{}), S.LNone{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_Xpoint_MhdB:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.MhdB{}), S.LPtn{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_Heating1_MhdB:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.MhdB{}), S.LPtn{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_Heating2_MhdB:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.MhdB{}), S.LPtn{}) == True{} : Bool}
# HIP (instancia 2, MHD al PTN; motivada por [S6]/[S7])
law inst2_Termination_MhdB:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.MhdB{}), S.LPtn{}) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Breakdown_Slow:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.Slow{}), S.table1(S.Breakdown{}, S.Slow{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_IpRise_Slow:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.Slow{}), S.table1(S.IpRise{}, S.Slow{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Limiter_Slow:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.Slow{}), S.table1(S.Limiter{}, S.Slow{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Xpoint_Slow:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.Slow{}), S.table1(S.Xpoint{}, S.Slow{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Heating1_Slow:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.Slow{}), S.table1(S.Heating1{}, S.Slow{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Heating2_Slow:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.Slow{}), S.table1(S.Heating2{}, S.Slow{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Termination_Slow:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.Slow{}), S.table1(S.Termination{}, S.Slow{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Breakdown_Fast:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.Fast{}), S.table1(S.Breakdown{}, S.Fast{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_IpRise_Fast:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.Fast{}), S.table1(S.IpRise{}, S.Fast{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Limiter_Fast:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.Fast{}), S.table1(S.Limiter{}, S.Fast{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Xpoint_Fast:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.Fast{}), S.table1(S.Xpoint{}, S.Fast{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Heating1_Fast:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.Fast{}), S.table1(S.Heating1{}, S.Fast{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Heating2_Fast:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.Fast{}), S.table1(S.Heating2{}, S.Fast{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Termination_Fast:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.Fast{}), S.table1(S.Termination{}, S.Fast{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Breakdown_Mchs:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.Mchs{}), S.table1(S.Breakdown{}, S.Mchs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_IpRise_Mchs:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.Mchs{}), S.table1(S.IpRise{}, S.Mchs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Limiter_Mchs:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.Mchs{}), S.table1(S.Limiter{}, S.Mchs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Xpoint_Mchs:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.Mchs{}), S.table1(S.Xpoint{}, S.Mchs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Heating1_Mchs:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.Mchs{}), S.table1(S.Heating1{}, S.Mchs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Heating2_Mchs:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.Mchs{}), S.table1(S.Heating2{}, S.Mchs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Termination_Mchs:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.Mchs{}), S.table1(S.Termination{}, S.Mchs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Breakdown_Dhs:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.Dhs{}), S.table1(S.Breakdown{}, S.Dhs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_IpRise_Dhs:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.Dhs{}), S.table1(S.IpRise{}, S.Dhs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Limiter_Dhs:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.Dhs{}), S.table1(S.Limiter{}, S.Dhs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Xpoint_Dhs:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.Dhs{}), S.table1(S.Xpoint{}, S.Dhs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Heating1_Dhs:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.Dhs{}), S.table1(S.Heating1{}, S.Dhs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Heating2_Dhs:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.Dhs{}), S.table1(S.Heating2{}, S.Dhs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Termination_Dhs:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.Dhs{}), S.table1(S.Termination{}, S.Dhs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Breakdown_BothHs:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.BothHs{}), S.table1(S.Breakdown{}, S.BothHs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_IpRise_BothHs:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.BothHs{}), S.table1(S.IpRise{}, S.BothHs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Limiter_BothHs:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.BothHs{}), S.table1(S.Limiter{}, S.BothHs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Xpoint_BothHs:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.BothHs{}), S.table1(S.Xpoint{}, S.BothHs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Heating1_BothHs:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.BothHs{}), S.table1(S.Heating1{}, S.BothHs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Heating2_BothHs:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.BothHs{}), S.table1(S.Heating2{}, S.BothHs{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Termination_BothHs:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.BothHs{}), S.table1(S.Termination{}, S.BothHs{})) == True{} : Bool}
# HIP (A-25, fila ciega asumida)
law asm_Breakdown_Blind:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.Blind{}), S.LPtn{}) == True{} : Bool}
# HIP (A-25, fila ciega asumida)
law asm_IpRise_Blind:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.Blind{}), S.LPtn{}) == True{} : Bool}
# HIP (A-25, fila ciega asumida)
law asm_Limiter_Blind:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.Blind{}), S.LPtn{}) == True{} : Bool}
# HIP (A-25, fila ciega asumida)
law asm_Xpoint_Blind:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.Blind{}), S.LPtn{}) == True{} : Bool}
# HIP (A-25, fila ciega asumida)
law asm_Heating1_Blind:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.Blind{}), S.LPtn{}) == True{} : Bool}
# HIP (A-25, fila ciega asumida)
law asm_Heating2_Blind:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Blind{}), S.LPtn{}) == True{} : Bool}
# HIP (A-25, fila ciega asumida)
law asm_Termination_Blind:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.Blind{}), S.LPtn{}) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Breakdown_Blind:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.Blind{}), S.table1(S.Breakdown{}, S.Blind{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_IpRise_Blind:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.Blind{}), S.table1(S.IpRise{}, S.Blind{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Limiter_Blind:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.Blind{}), S.table1(S.Limiter{}, S.Blind{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Xpoint_Blind:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.Blind{}), S.table1(S.Xpoint{}, S.Blind{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Heating1_Blind:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.Blind{}), S.table1(S.Heating1{}, S.Blind{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Heating2_Blind:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.Blind{}), S.table1(S.Heating2{}, S.Blind{})) == True{} : Bool}
# HIP (instancia 2 copia la 1)
law inst2_same_Termination_Blind:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.Blind{}), S.table1(S.Termination{}, S.Blind{})) == True{} : Bool}
# HIP (A-10, cableado DMS)
law dms_trig_Fast:
  {S.dms_trig(S.Fast{}) == True{} : Bool}
# HIP (A-10, cableado DMS)
law dms_trig_Mhd:
  {S.dms_trig(S.Mhd{}) == True{} : Bool}
# HIP (A-10, cableado DMS)
law dms_trig_MhdB:
  {S.dms_trig(S.MhdB{}) == True{} : Bool}
# HIP (A-10, cableado DMS)
law dms_trig_Slow:
  {S.dms_trig(S.Slow{}) == False{} : Bool}
# HIP (A-10, cableado DMS)
law dms_trig_Mchs:
  {S.dms_trig(S.Mchs{}) == False{} : Bool}
# HIP (A-10, cableado DMS)
law dms_trig_Dhs:
  {S.dms_trig(S.Dhs{}) == False{} : Bool}
# HIP (A-10, cableado DMS)
law dms_trig_BothHs:
  {S.dms_trig(S.BothHs{}) == False{} : Bool}
# HIP (A-10, cableado DMS)
law dms_trig_Blind:
  {S.dms_trig(S.Blind{}) == False{} : Bool}
# JET (R-14, ventana DMV)
law dms_window_Breakdown:
  {S.dms_window(S.Breakdown{}) == False{} : Bool}
# JET (R-14, ventana DMV)
law dms_window_IpRise:
  {S.dms_window(S.IpRise{}) == False{} : Bool}
# JET (R-14, ventana DMV)
law dms_window_Limiter:
  {S.dms_window(S.Limiter{}) == False{} : Bool}
# JET (R-14, ventana DMV)
law dms_window_Xpoint:
  {S.dms_window(S.Xpoint{}) == True{} : Bool}
# JET (R-14, ventana DMV)
law dms_window_Heating1:
  {S.dms_window(S.Heating1{}) == True{} : Bool}
# JET (R-14, ventana DMV)
law dms_window_Heating2:
  {S.dms_window(S.Heating2{}) == True{} : Bool}
# MIXTA (R-14 + A-10: extiende la ventana de [S6] a toda la fila de Termination)
law dms_window_Termination:
  {S.dms_window(S.Termination{}) == True{} : Bool}
# HIP (A-10, A-13)
law dms_on_commfault_off:
  {S.dms_on_commfault() == False{} : Bool}
# HIP (A-10, A-13)
law dms_on_watchdog_off:
  {S.dms_on_watchdog() == False{} : Bool}
# HIP (A-21, máscaras por instancia)
law mask_inst1_checks_on:
  {S.mask_of(S.Inst1{}) == S.Mask{True{}, True{}} : S.Mask}
# HIP (A-21, máscaras por instancia)
law mask_inst2_checks_on:
  {S.mask_of(S.Inst2{}) == S.Mask{True{}, True{}} : S.Mask}
# HIP (A-21, máscaras por instancia)
law mask_inst3_checks_off:
  {S.mask_of(S.Inst3{}) == S.Mask{False{}, False{}} : S.Mask}
# HIP (instancia 4, nuestra; revisión 4)
law inst4_mask:
  {S.mask_of(S.Inst4{}) == S.Mask{True{}, True{}} : S.Mask}
```
