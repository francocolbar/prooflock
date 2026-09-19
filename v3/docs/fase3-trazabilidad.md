# Fase 3 — Trazabilidad: peligro → función → requisito → hipótesis → ley → prueba → negativo → diferencial → límite

Fecha: 2026-09-19 (revisión 2, con el conjunto de leyes cerrado). Es la tabla que pide un evaluador de seguridad
funcional. Fuentes: `fase3-seguridad.md` (peligros H-*, requisitos SR-*), `fase3-fuente.md` (citas R-*, hipótesis A-*),
`fase3-diseno.md` (leyes). Artefactos: `LAWS_JETPROT.bend` (64 leyes), `LAWS_JETPROT_CONF.bend` (117),
`PROOF_JETPROT*.bend`, `tests/jetprot_bug1..10*.bend`, `prod/jetprot_prod.py` (6 defectos plantados),
`pymodel/mutants.py` (banco adversarial de 62), `recheck.py` (C2, C3, C5, C6), `run.py` (gate único).

**Convención de nombres.** `I1`…`I6` son cláusulas del invariante `inv_fin`/`inv_all`, no identificadores de ley: se
prueban por las leyes de preservación `pres_fin`, `pres_i5`, `pres_i6` y por el teorema `traces_safe`. Todo lo demás en
la columna "Ley" es el nombre literal de un `law` en uno de los dos archivos.

## 1. Requisito de seguridad → ley → prueba → negativo → diferencial

| SR | Requisito (shall / shall not) | Peligro | Deriva de | Hipótesis | Ley | Prueba | Negativo | Bug plantado |
|---|---|---|---|---|---|---|---|---|
| SR-1 | Al llegar una parada PTN por cualquier camino, toda unidad **shall** salir de potencia en el mismo ciclo | H-C, H-A1 | R-0, R-11 | A-9, A-19 | `ptn_deenergizes`; corolario `ptn_no_heat`; cláusula I1 | reflexión sobre `finite_check` / `_alt`; `corollaries_check` | bug3, bug5 | `commfault_leaves_heating` |
| SR-2 | Una parada **shall not** ser reemplazada por una de menor autoridad durante el pulso | H-G, H-J | R-0, R-7 | A-1, A-2 | `latched`; **`stop_honoured`** (dos lados); `reset_accepted`, `reset_refused` | reflexión | bug1, **bug9** | `deescalation` |
| SR-3 | Ante una respuesta RTPS o JTT, toda unidad **shall** salir de potencia plena en el mismo ciclo y **shall not** volver | H-A1 (calentamiento) | R-3, R-4 | A-9 | `stop_reduces_power`; **`soft_stop_ramps`**; `ramping_never_returns`; cláusula I2 | reflexión | bug2, bug7, **bug10** | `rtps_keeps_full_power` |
| SR-4 | Ninguna unidad **shall** energizarse fuera de la ventana, sin plasma, o con una parada en curso | H-E | R-12 | A-5, A-8 | cláusula I1; `heat_permissive`; `stop_overrides_heat`; `heat_frame`; **`heaton_is_local`** | preservación; reflexión | — | — |
| SR-5 | El DMS **shall not** armarse ni dispararse salvo con el PTN activo | H-C | R-11, [S6] | A-11 | cláusula I4; `dms_frame`; corolario `dms_no_heat`; **`dms_fire_frame`** | preservación; reflexión | bug4 | — |
| SR-6 | Una parada marcada para DMS que llega al PTN **shall** armarlo; la espera **shall** estar acotada; una alarma repetida **shall not** reiniciarla | H-C2 | R-11 | A-10, A-11 | `dms_armed_on_demand`; cláusula I5; `tack_frame`; `dms_monotone`; **`ack_timeout_fires`**, **`ack_counts`**, **`heatack_exact`**, **`tack_inc_frame`**, **`tack_reset_frame`** | reflexión; `cnt_go` | bug6 | `repeated_alarm_restarts_ack` |
| SR-7 | `hb_max` ciclos sin heartbeat **shall** producir PTN | H-D | R-13 | A-12 | cláusula I6; **`watchdog_latches`**, **`hb_counts`**, **`hb_tick_exact`**, **`heartbeat_resets_hb`**, **`hb_frame`** | `cnt_go`; alcanzabilidad concreta (C5) | — | `watchdog_off_by_one` |
| SR-8 | Una falla de comunicación **shall** producir PTN desde cualquier estado | H-D | R-13 | A-13 | `commfault_ptn` | reflexión | bug3 | `commfault_leaves_heating` |
| SR-9 | Una alarma local **shall** inhibir su unidad y nada más; la inhibición **shall** durar el pulso; y **shall not** crearse por ningún otro camino | H-A2 | R-8, R-9 | A-6, A-7 | `inhibit_latched`; `local_is_local`; **`inhibit_source`** | reflexión | — | `plasma_ok_clears_inhibit` |
| SR-10 | La respuesta **shall not** cambiar salvo por alarma, falla de comunicación, watchdog vencido o fin de pulso | H-H | R-13 | A-12, A-13 | `no_spurious_stop` | reflexión | — | — |
| SR-11 | La configuración certificada **shall** coincidir con la publicada, con las celdas supuestas identificadas, y la capa concreta **shall** usarla tal cual | H-F | R-5 | A-4 | `pub_*` (28), `asm_*` (21), `inst2_*` (49), `dms_*` (16), `fast_ptn`, **`concretize_is_the_table`**, **`step_c_is_the_concrete_step`** | `PROOF_JETPROT_CONF` (`{==}` por celda) | — | tercera transcripción en `prod/` |
| SR-12 | Bajo PTN el programa **shall not** avanzar; **shall not** rebobinar; y **shall** avanzar exactamente una fase | H-J | R-0 | A-5 | `advance_frozen`; `phase_monotone`; **`advance_is_one_step`**, **`phase_frame`**, **`stop_phase_exact`**, **`advance_units`** | reflexión | — | — |
| SR-13 | El fin de pulso **shall** liberar los enclavamientos solo con el pulso terminado y sin mitigación armada, y **shall** aceptarse cuando esas condiciones valen | H-J | A-14, [S1] supervisor | A-14 | `reset_guarded`; `reset_refused_mid_pulse`; **`reset_accepted_when_safe`** (guarda escrita literalmente) | reflexión; reescritura | — | — |
| SR-14 | Para toda secuencia de eventos, el estado **shall** satisfacer I1–I6 | todos | todos | todas | `traces_safe`, `traces_safe_concrete`; `inv_init`; `pres_fin`, `pres_i5`, `pres_i6` | inducción en la traza | — | los dos oráculos del diferencial |
| SR-15 | Las condiciones de plasma **shall** reflejar su entrada y **shall not** cambiar por ningún otro camino | H-E | R-12 | A-8 | **`plasma_is_input`**, **`plasma_frame`** | reflexión | — | — |

En **negrita**, las leyes que se agregaron después de que dos revisiones adversariales mostraran que el conjunto
anterior era puramente negativo (`fase3-diseno.md` §9b, H28–H29).

**Fuera de alcance, declarado**: la respuesta secundaria (R-6 → A-16); el acuse como secuencia, no solo como cota
(R-11 parcial → A-11); el umbral de corriente del DMV (R-14 → A-22); el bypass de entradas del PTN y las ventanas mal
configuradas (R-15 → A-21); todo plazo (A-15); la independencia entre capas (A-17).

## 2. Cita de la fuente → cómo se usa

| Cita | Clase | Uso | Estado |
|---|---|---|---|
| R-0 | arquitectura | PTN arriba del orden; `to_ptn`; `ptn_deenergizes`, `advance_frozen` | cubierto |
| R-1 | contexto / dato | las siete fases, como instancia de configuración (A-5) | cubierto |
| R-2 | requisito | los siete disparadores | cubierto; las columnas ausentes son A-4 |
| R-3 | requisito | los tres niveles de respuesta; `soft_apply`, `to_ptn` | cubierto |
| R-4 | requisito | el JTT salta a terminación y **rampa** el calentamiento | cubierto (`soft_stop_ramps`; fue el hallazgo H16) |
| R-5 | dato de configuración | 28 celdas publicadas + 21 supuestas; las 117 leyes de conformidad | cubierto (15 impresas + 13 por ídem) |
| R-6 | justificación | — | **fuera de alcance** (A-3, A-16): no hay matriz secundaria publicada |
| R-7 | requisito | escalada por máximo (A-2); el cableado del DMS es configuración ([S6]) | cubierto como política nuestra |
| R-8, R-9 | justificación | `Local`, `Inhibited`, `inhibit_latched`, `inhibit_source`, `local_is_local` | cubierto como política más restrictiva (A-7); la compensación de R-9 no es expresable (A-6) |
| R-10 | arquitectura | enclavamiento; `Reset` guardado | cubierto; el bypass **fuera de alcance** (A-21) |
| R-11 | requisito | `arm_dms`, `HeatAck`, `ack_max`, I4, I5 y las seis leyes del DMS | **parcial**: atomicidad y cota, no el acuse como secuencia (A-11) |
| R-12 | requisito | `heat_win`, `plasma`, I1, `heat_permissive`, `plasma_is_input` | cubierto como abstracción (A-5, A-8); PEWS no se modela como sistema independiente |
| R-13 | requisito | `CommFault`, el watchdog y sus cinco leyes | cubierto (A-12, A-13) |
| R-14 | dato de configuración | `dms_window` | **parcial**: el umbral de corriente queda fuera (A-22) |
| R-15 | evidencia operativa | — | no es un requisito: es el argumento del método (certificar la configuración de cada pulso) |

## 3. Hipótesis → leyes que dependen de ella

| A-n | Leyes dependientes | Qué pasa si es falsa |
|---|---|---|
| A-1 | `latched`, `stop_honoured`, `soft_stop_ramps`, `stop_phase_exact` | El orden es un **parámetro del modelo**: toda ley se prueba para los dos (`finite_check` y `finite_check_alt`). La diferencia de comportamiento es de 2 688 celdas, 168 alcanzables. |
| A-2 | `latched`, `stop_honoured` | Dejan de describir a JET (R-6 permite suprimir escaladas). |
| A-4 | `asm_*`, `fast_ptn` | Cambian 21 celdas; las leyes sobre el alfabeto abstracto no dependen. |
| A-5 | I1, `heat_permissive`, `phase_monotone`, `advance_frozen`, `advance_is_one_step`, `advance_units` | La ventana y las fases son instancia; recertificar. |
| A-6 | `local_is_local` | Más débil que R-9. |
| A-7 | `inhibit_latched`, `inhibit_source` | Política más restrictiva que la de JET, declarada. |
| A-8 | I1, `plasma_is_input` | I1 dice menos de lo que parece (Ip global vs densidad por PINI). |
| A-9 | I1, I2, `ptn_deenergizes`, `stop_reduces_power`, `ramping_never_returns`, `soft_stop_ramps`, `advance_units` | El efecto real es una forma de onda (A-19). |
| A-10 | `dms_armed_on_demand`, `dms_frame`, `dms_fire_frame` | La instancia decide qué paradas llevan el bit de DMS. |
| A-11 | I4, I5, y las leyes del acuse | El acuse como secuencia queda fuera. |
| A-12, A-13 | I6 y las cinco del watchdog; `commfault_ptn` | Dos caminos de demanda fundidos en uno. |
| A-14 | `reset_guarded`, `reset_refused_mid_pulse`, `reset_accepted_when_safe` | `latched` pierde contenido. |
| A-15…A-23 | ninguna (límites declarados) | — |

## 4. Estado medido (de `results.json` y `recheck.json`, gate del 2026-09-19)

| Artefacto | Resultado |
|---|---|
| `PROOF_JETPROT.bend` | `All terms check.`, 143 s. 64 leyes: reflexión sobre el certificado, el lema de contadores y la inducción en la traza |
| `PROOF_JETPROT_CONF.bend` | `All terms check.`, 0,3 s. 117 leyes de conformidad |
| Certificados `_FIN`, `_FIN_ALT`, `_COR` | 104 832 celdas por orden + 2 688 estados; 14–19 s y 0,3 s. Son **bibliotecas**, no gates: cada uno descarga una sola ley y solo `PROOF_JETPROT.bend` puede dar verde |
| Negativos `bug1..bug10` | 10/10 rechazados, cada uno por refutar un `Bool` **y** citando el nombre de su ley |
| C5 | **209 664 celdas** Bend = Python; 0 discrepancias; 0 fallas de ley sobre los estados que produce Bend; capa concreta idéntica; alcanzabilidad concreta 921 estados (`hb ≤ 2`, `tack ≤ 1`), todos en `inv_all` |
| C2 | 323 estados abstractos alcanzables; ninguna ley vacua; **ajuste: 374/400 celdas con sucesor único (93,5 %), 1,1 sucesores admisibles de 2 688**; comandos a contadores fijados en 195/400 (1,51 de 9). Avisos bajo umbral: `heat_frame`, `advance_to_termination_ramps` |
| C3 | 2 688 celdas difieren entre los dos órdenes, 168 alcanzables; todas las leyes valen en ambos |
| C6 | **Banco adversarial: 61/62**, único sobreviviente `M06`, verificado equivalente (difiere en 0 de 209 664 celdas). Flags del modelo: 17/17, reportado como la medida débil |
| Diferencial | 6 defectos plantados × 2 instancias × 2 generadores; encontrados 14/16 configuraciones con defecto, 0 falsos positivos en las 2 sin defecto; el generador guiado los encuentra todos con trazas de 2–10 eventos, el aleatorio pierde varios |
| Gate completo | `py -3.14 v3/run.py` → `all gates and checks ok: True`, ≈ 5–6 min |

**Trabajo futuro declarado**: el gate C4 (`LocalClear` guardado, la sensibilidad de A-7) no está implementado; el
estado comandado vs. reportado de las unidades (para verificar el acuse de R-11 como secuencia); el umbral de corriente
del DMV; el cross-check del certificado en nuXmv o TLA+/Apalache.
