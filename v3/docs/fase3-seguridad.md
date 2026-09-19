# Fase 3 — Peligros, requisitos de seguridad y límites de la evidencia

Fecha: 2026-09-19 (revisión 4, con el conjunto de leyes cerrado). Estado: **borrador**. Este documento es la mitad superior de la cadena de trazabilidad
que un evaluador de seguridad funcional pide: **peligro → función de protección → requisito (shall / shall not, con
estado seguro) → hipótesis → ley → prueba → negativo → diferencial → límite**. La mitad inferior (ley → prueba) está en
`fase3-diseno.md`; las citas y las hipótesis en `fase3-fuente.md`. La tabla `fase3-trazabilidad.md` (paso 3) se genera
desde estos tres.

## 0. Reclamo, alcance y clase de evidencia (lo que va en el primer párrafo del preprint)

- La función modelada es **protección de máquina** (protección de inversión) de JET: el RTPS ("soft protection" en la
  Fig. 1 de [S1]) y su interfaz al PTN. No es una función de seguridad nuclear; las capas de seguridad de JET (CISS,
  PSACS) no se modelan.
- La evidencia es sobre una **especificación** (un modelo discreto, sin tiempo), no sobre un sistema ni una
  implementación. En términos de IEC 61508-3 contribuye a un argumento de **capacidad sistemática** (tablas A.1, A.2, A.9:
  métodos formales en especificación, diseño y verificación) y **no sostiene por sí sola ningún reclamo de SIL**.
- El modelo es el *Stop Selector* ([S1]), reconstruido **desde publicaciones abiertas**; 21 de las 49 celdas de la matriz
  certificada son hipótesis nuestras (A-4), la matriz secundaria no está publicada (A-16) y el DMS solo se arma, en la
  instancia publicada, por una celda supuesta.
- Terminología: "certificado" se usa solo para el artefacto interno (el término decidido por el checker); nunca
  "sistema certificado". El entregable es "un paquete de evidencia de verificación destinado a integrarse en un caso de
  seguridad", no "un caso de seguridad".
- La revisión adversarial fue automatizada (instancias de la misma familia de modelos que escribió el diseño); **no**
  hubo evaluación humana independiente. Antes del preprint: enviar la reconstrucción a los autores de [S1]/[S2] para
  una lectura de exactitud fáctica (decisión del autor humano).

## 1. Peligros que la cadena existe para controlar

Derivados de [S1], [S2] §3.4, [S6]. Fuente de demanda = qué sistema real detecta.

| ID | Peligro | Demanda |
|---|---|---|
| H-A1 | Fusión / daño de baldosas por flujo de calor localizado (cámara principal o divertor) | VTM (IR, pirómetros), WALLS |
| H-A2 | Shine-through: un PINI calienta un componente específico | PEWS2 por PINI; alarma local |
| H-A3 | **La propia respuesta de parada deposita energía excesiva en la pared** (motivación del RTPS, [S1]) | elección de respuesta |
| H-B | Disrupción / inestabilidad MHD: quench térmico, corrientes halo, electrones runaway, fuerzas | mode lock, APODIS, RAPTOR, PETRA |
| H-C | Inyección masiva de gas con NB/RF encendidos (límites de presión del ducto y líneas de antena, [S6]) | salidas del PTN → DMV/SPI |
| H-C2 | El DMS no dispara o dispara tarde cuando hace falta (obligatorio > 2 MA, [S2]) | ídem |
| H-D | Pérdida de protección: VTM ciega, falla de comunicación/estado, RTPS muerto | alarmas ciegas, monitoreo, watchdog |
| H-E | Calentamiento energizado fuera de su ventana o sin corriente/densidad (haz al vacío) | PEWS/PEWS2 |
| H-F | **Configuración incorrecta** de la matriz, de la ventana o de los inhibits ([S3]; R-15: 5 + 4 + 7 disrupciones perdidas) | Level-1 |
| H-G | Segunda falla, peor, durante una respuesta en curso (R-6) | cualquier disparador |
| H-H | Parada espuria; bypass (entradas/salidas del PTN habilitables/deshabilitables, R-10) | — |
| H-I | Pérdida de independencia / causa común entre RTPS (software) y PTN/CISS (cableado) | arquitectura |
| H-J | Liberación prematura de un enclavamiento o de un inhibit | operador / reset |
| H-K | Protección tardía respecto de la constante térmica (tiempo de seguridad del proceso) | temporización |
| H-L | Orden emitida pero el actuador no obedece | local managers |

## 2. Requisitos de seguridad (capa entre las citas R-n y las leyes)

Formato: **SR-n** (shall / shall not), estado seguro, fuente de demanda, plazo (declarado fuera de alcance cuando
corresponde), y clase de la cita de la que deriva (C = contexto, A = arquitectura, F = requisito funcional, D = dato
de configuración, J = justificación).

| SR | Enunciado | Estado seguro | Deriva de | Ley(es) | Plazo |
|---|---|---|---|---|---|
| SR-1 | Al recibir una demanda de parada PTN por cualquier camino, el sistema **shall** llevar toda unidad de calentamiento fuera de `On`/`Ramping` en el mismo ciclo. | `ptn_no_heat` | R-0 (A), R-11 (F) | `ptn_deenergizes`, I1, I2 | fuera (A-15) |
| SR-2 | Una parada **shall not** ser reemplazada por una respuesta de menor autoridad durante el pulso. | — | R-0 (A), R-7 (F), A-2 | `latched`, **`stop_honoured`** | — |
| SR-3 | Ante una alarma cuya respuesta configurada es RTPS o JTT, el sistema **shall** sacar toda unidad de potencia plena en el mismo ciclo y **shall not** devolverla a potencia plena en el pulso. | `stop_no_full_power` | R-3, R-4 (F), A-9 | `stop_reduces_power`, **`soft_stop_ramps`**, `ramping_never_returns`, I2 | fuera |
| SR-4 | Ninguna unidad **shall** energizarse fuera de la ventana de habilitación de la instancia, sin condiciones de plasma, o con una parada en curso. | — | R-12 (F), A-5, A-8 | I1, `heat_permissive`, `stop_overrides_heat`, `heat_frame` | — |
| SR-5 | El DMS **shall not** armarse ni dispararse salvo con el PTN activo (y por SR-1, sin calentamiento comandado). | `dms_no_heat` | R-11 (F), [S6] | I4, `dms_frame`, **`dms_fire_frame`** | — |
| SR-6 | Cuando una parada marcada para DMS llega al PTN, el DMS **shall** armarse; la espera del acuse **shall** estar acotada; una alarma repetida **shall not** reiniciarla. | — | R-11 (F), A-10, A-11 | `dms_armed_on_demand`, I5, `tack_frame`, `dms_monotone`, **`ack_timeout_fires`**, **`heatack_exact`** | fuera (50 ms real, [S6]) |
| SR-7 | La ausencia de heartbeat del RTPS durante `hb_max` ciclos **shall** producir una parada PTN. | — | R-13 (F), A-12 | I6, **`watchdog_latches`**, **`heartbeat_resets_hb`**, **`hb_tick_exact`**, **`hb_frame`** | fuera |
| SR-8 | Una falla de comunicación o alarma ciega **shall** producir una parada PTN desde cualquier estado. | — | R-13 (F), A-13 | `commfault_ptn` | fuera |
| SR-9 | Una alarma local **shall** inhibir la unidad afectada y **shall not** alterar fase, respuesta, DMS ni la otra unidad; la inhibición **shall** persistir el pulso. | — | R-8, R-9 (F/J), A-7 | `inhibit_latched`, `local_is_local`, **`inhibit_source`** | — |
| SR-10 | La respuesta **shall not** cambiar salvo por alarma, falla de comunicación, watchdog vencido o fin de pulso. | — | R-13, A-12, A-13 | `no_spurious_stop` | — |
| SR-11 | La configuración certificada **shall** coincidir celda por celda con la publicada (y las celdas supuestas **shall** estar identificadas). | — | R-5 (D), A-4 | `pub_*` (28), `asm_*` (21), `fast_ptn`, **`concretize_is_the_table`**, **`step_c_is_the_concrete_step`** | — |
| SR-12 | Bajo PTN el programa **shall not** avanzar; el programa **shall not** rebobinar. | — | R-0, A-5 | `advance_frozen`, `phase_monotone`, **`advance_is_one_step`**, **`phase_frame`** | — |
| SR-13 | El fin de pulso **shall** liberar los enclavamientos solo con el pulso terminado y sin mitigación armada. | — | A-14, [S1] supervisor | `reset_guarded`, `reset_refused_mid_pulse`, **`reset_accepted_when_safe`** | — |
| SR-15 | Las condiciones de plasma **shall** reflejar su entrada y **shall not** cambiar por ningún otro camino. | — | R-12 (F), A-8 | **`plasma_is_input`**, **`plasma_frame`** | — |
| SR-16 | Una petición de parada **shall** ser honrada: la respuesta pasa a ser la más urgente entre la actual y la pedida. | — | R-7 (F), A-2 | **`stop_honoured`** | — |
| SR-14 | Para toda secuencia de eventos del alfabeto, el estado **shall** satisfacer I1–I6. | `inv_all` | todos | `traces_safe`, `traces_safe_concrete` | — |

**Fuera de alcance, declarado**: la respuesta secundaria (R-6 → A-16); el acuse como secuencia (R-11 parcial → A-11);
el umbral de corriente del DMV (R-14 → A-22); bypass y ventanas mal configuradas (R-15 → A-21); todo plazo (A-15).

## 3. Matriz peligro → ley

S = ley de seguridad (demanda sobre la función de protección); A = disponibilidad o marco; — = sin ley. En **negrita**,
las leyes agregadas después de que dos revisiones adversariales mostraran que el conjunto anterior era puramente
negativo (`fase3-diseno.md` §9b).

| Peligro | S | A | Sin ley / hueco |
|---|---|---|---|
| H-A1 hot spot antes del calentamiento | `pub_*`/`asm_*`, `ptn_deenergizes`, I1, **`stop_honoured`** | — | qué responder con una parada ya en curso: solo `latched` y `stop_honoured` |
| H-A1 **durante el calentamiento** (→ RTPS) | **`soft_stop_ramps`**, `stop_reduces_power`, `ramping_never_returns`, I2, `stop_overrides_heat` | — | cuánto baja la potencia y en cuánto tiempo (A-19, A-15) |
| H-A2 shine-through / local | `inhibit_latched`, **`inhibit_source`** | `local_is_local` | qué unidad inhibir (la lógica de PEWS2); la compensación de R-9 (A-6) |
| H-A3 la parada daña la pared | — | — | **inexpresable** en esta abstracción; es la motivación de [S1]; declarado |
| H-B disrupción / MHD | `dms_armed_on_demand` (instancia 2) | — | en la instancia publicada MHD → None: la protección real corre fuera de la tabla primaria ([S6], [S7]) |
| H-C gas con calentamiento | I4 ∧ I1 ∧ I2 (`dms_no_heat`), `dms_frame`, **`dms_fire_frame`** | — | estado comandado, no reportado (A-11, A-19) |
| H-C2 el DMS no dispara | `dms_armed_on_demand`, **`ack_timeout_fires`**, **`heatack_exact`**, **`ack_counts`** | I5 | vivacidad (A-15); el umbral de corriente (A-22) |
| H-D pérdida de protección | `commfault_ptn`, I6, **`watchdog_latches`**, **`heartbeat_resets_hb`**, **`hb_tick_exact`**, **`hb_frame`** | `no_spurious_stop` | fallas del propio PTN; alarma ciega y falla de comunicación fundidas (A-13) |
| H-E fuera de ventana | I1, `heat_permissive`, `stop_overrides_heat`, `heat_frame`, **`plasma_is_input`**, **`plasma_frame`** | — | la independencia del PEWS real (A-5, A-17) |
| H-F configuración | `pub_*`/`asm_*`, **`concretize_is_the_table`**, **`step_c_is_the_concrete_step`**, `fast_ptn`, C2, registro de configuración (A-23) | — | no hay ley de **buena formación** de configuraciones (p. ej. "ninguna fase con plasma mapea un disparador térmico a None"): trabajo futuro |
| H-G segunda falla | `latched`, **`stop_honoured`** | — | R-6 fuera de alcance (A-16) |
| H-H espuria / bypass | — | `no_spurious_stop`, `reset_guarded`, `local_is_local` | el bypass no se modela (A-21) |
| H-I independencia | — | — | **nada** (A-17): va en el resumen del preprint |
| H-J liberación prematura | `latched`, `inhibit_latched`, `dms_monotone`, `reset_guarded`, `reset_refused_mid_pulse`, **`reset_accepted_when_safe`**, **`advance_is_one_step`**, **`phase_frame`** | — | bien cubierto |
| H-K tiempo | — | — | nada (A-15) |
| H-L obediencia del actuador | — | `heat_frame`, **`heatoff_is_local`**, **`advance_units`** | comando = efecto (A-19) |

Cambio respecto de la revisión anterior de este documento: de quince peligros, siete no tenían ninguna ley. Ahora son
**cuatro** (H-A3, H-I, H-K, y H-H en su parte de bypass), y los cuatro son límites de la abstracción declarados, no
olvidos. El más importante de los que se cubrieron es H-A1 durante el calentamiento —el peligro por el que existe el
sistema real— que antes solo tenía "no se enciende nada nuevo".

## 4. Qué establece `traces_safe` y qué no (para el preprint, en estos términos)

**Establece**: para el modelo discreto de §1 de `fase3-diseno.md`, bajo las hipótesis A-1…A-23, toda secuencia finita
de eventos del alfabeto, aplicada al estado inicial, para todo valor de los contadores abstractos, produce un estado que
satisface I1–I6. Es una propiedad de seguridad (Alpern–Schneider) de una *especificación*, con cobertura completa del
espacio de entradas: ninguna traza de ningún largo, en ningún entrelazado, escapa. **No** lo distingue de un modelo que ignora todo el hecho de tener muchas leyes ni muchas celdas certificadas: un
conjunto de propiedades de seguridad lo satisface el modelo nulo, y una revisión adversarial lo demostró contra la
versión anterior de este trabajo, haciendo pasar un modelo degenerado por las leyes **y** por el gate de vacuidad.
Lo distinguen las 29 leyes de demanda y de marco, la métrica de ajuste (cuántos sucesores admite el conjunto: 1,1 de
2 688) y el banco de mutantes adversarial (61 de 62).

**No establece**: (1) comportamiento a falla de hardware (nada de PFD/PFH, SFF, HFT: el modelo asume que la función
de transición ejecuta); (2) capacidad sistemática de ninguna implementación (el C emitido no va a un PLC; el único
vínculo es el testing diferencial, que es testing); (3) ausencia de paradas espurias (P10 es de marco; las alarmas son
entradas libres); (4) nada bajo entradas inválidas (A-18); (5) nada de tiempo (A-15; los números reales están en A-15);
(6) vivacidad; (7) corrección de las fuentes de alarma; (8) obediencia de la planta (A-19); (9) independencia entre
capas (A-17).

Fraseo propuesto: "Para el modelo discreto abstracto definido en §X, bajo las hipótesis A-1…A-23 del Anexo B, probamos
que toda secuencia finita de eventos modelados aplicada al estado inicial produce un estado que satisface I1–I6, para
todo valor de los contadores abstractos. Es una propiedad de la especificación, no de una implementación. No establece
temporización, vivacidad, comportamiento ante falla aleatoria de hardware, mensajes perdidos o malformados, cambio de
configuración durante el pulso, ni la corrección de las fuentes de alarma. En términos de IEC 61508 es evidencia que
contribuye a un argumento de capacidad sistemática para la especificación y el diseño (61508-3, tablas A.1, A.2, A.9);
no sostiene por sí sola un reclamo de SIL, y la función modelada es protección de máquina, no una función de seguridad
nuclear."

## 5. Calificación de la cadena de herramientas (lo que hoy falta y se agrega)

- Bend 2.0.6, backend JS, un proveedor, un año de vida, sin calificación: en términos de 61508-3 una herramienta de
  soporte *offline* clase T2 (puede no detectar errores). Evidencia mínima: versiones pinneadas (`env/SETUP.md`);
  **puntaje de mutación** (C6) sobre modelo y leyes; **test de adecuación del certificado** (un `cell_ok` que devuelve
  `True` incondicionalmente debe ser atrapado por la grilla en runtime); **re-verificación diversa** del certificado
  por fuerza bruta en Python escrito desde el documento, no desde el `.bend` (C5). Cross-check en nuXmv o TLA+/Apalache:
  declarado como trabajo futuro (daría vivacidad "no reclamada" en vez de "no intentada").
- `cell_ok` es un punto único de falla para las leyes reflejadas: por eso C5 y C6.

## 6. Comparación honesta con la práctica publicada

Hoy ([S3], [S1], [S2]): 71 *pulse schedules* como pruebas de comportamiento definidas por el Plasma Operations Group,
pruebas unitarias, comisionado extremo a extremo con señales de cámara simuladas, una demostración en vivo del JTT
(pulso 80500), y un análisis automático post-pulso que produce la lista ordenada de eventos que terminaron el pulso;
más miles de pulsos de experiencia operativa. Eso da hardware real, latencias reales, sensores reales, modos de falla
reales: evidencia sobre el *sistema*. Lo que no puede dar es cobertura: 7 fases × 7 disparadores × orden × fallas de
comunicación × watchdog × inhibits × contadores supera por órdenes de magnitud a 71 pruebas, **y la matriz cambia por
pulso**: las 71 pruebas validan el *framework*, no la configuración de cada *session leader*.

Valor incremental del modelo, en orden: (1) chequeo exhaustivo de la lógica discreta **por configuración** en
minutos, que es el problema que [S3] enuncia ("robust configuration") y donde JET perdió disrupciones (R-15); (2) una
declaración chequeable por máquina de qué debe hacer la lógica, que hoy existe como prosa más una GUI; (3) un oráculo
de referencia para testing diferencial (Fase 2: el bug profundo fue inalcanzable para 3 000 trazas aleatorias, hallado
en 200 consultas guiadas, y la prueba lo cubría sin generar nada); (4) regresión ante cambios de configuración.

No reemplaza: las 71 pruebas, el comisionado, FAT/SAT, el análisis de tiempos, el análisis de fallas de hardware ni la
evaluación independiente. Y se compara contra el *registro publicado*: CCFE seguramente hizo FMEA/HAZOP y tiene una
autoridad de diseño que los papers no describen; el hueco que se cubre no es un hueco de su práctica. Un usuario de
nuXmv o TLA+ construiría este modelo en un día y obtendría vivacidad gratis; la elección de herramienta se defiende por
prueba en vez de *model checking* (universalidad genuina sobre los contadores), certificado y leyes en un artefacto, y
un modelo funcional total que sirve de oráculo ejecutable; y se neutraliza la objeción con el cross-check de §5.

## 7. Lo que un revisor hostil va a usar, y la respuesta

| Ataque | Respuesta preparada |
|---|---|
| "Es protección de máquina, no seguridad nuclear." | Dicho en el primer párrafo; el método transfiere, la instancia no; mapeo a categorías de IEC 61513/61226 con la categoría realista (B/C) y lo que faltaría para A. |
| "Requisitos citados de un paper; 21 de 49 celdas inventadas; sin la matriz secundaria." | Título honesto ("reconstruido desde publicaciones abiertas"); P11a/P11b separadas; lectura por los autores de [S1]/[S2]. |
| "Probaron que su programa es igual a sí mismo." | Se nombran las leyes tautológicas (P5, I3) y se argumenta por I1–I6 + `traces_safe`, la especificación chequeable y el diferencial contra una implementación escrita aparte. |
| "El peligro principal (hotspot en calentamiento) no tiene ley." | Rev. 3: P3, P4, I2 (`Ramping`). |
| "Sin tiempo ni vivacidad, un ladrillo satisface el teorema." | §4, explícito, con lo que distingue al modelo de un ladrillo. |
| "Un proveedor, un año, backend JS, escalera de reflexión escrita a mano." | C5, C6, versiones pinneadas, test de adecuación del certificado. |
| "La revisión independiente fue otra instancia del mismo LLM." | Dicho en §0; se busca lectura humana. |
| "La instancia certificada mapea MHD a None: cero protección contra disrupciones." | Es propiedad de la configuración ilustrativa; la instancia 2 certifica el camino que JET operó; argumento para leyes de buena formación de configuraciones. |
| "Plegaron PEWS y usaron un `step` para lo cableado y lo software: borraron la independencia." | A-5, A-17 en el resumen; I1 no cita PEWS como sistema. |
| "80 000 celdas no es verificación exhaustiva de nada real: 16 PINIs, 5 actuadores, formas de onda continuas." | Registro de hipótesis con dirección de conservadurismo (§4 de `fase3-fuente.md`). |
| "¿Qué requisito de la ARN satisface esto?" | Se afirma aptitud como *tipo* de evidencia, nunca aceptabilidad; el regulador clasifica. |
