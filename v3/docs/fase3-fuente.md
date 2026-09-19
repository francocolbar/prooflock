# Fase 3 — Fuente: la cadena de protección de la pared de JET (RTPS + PTN)

Fecha: 2026-09-19, **revisión 3** (tras dos rondas de revisión adversarial; registro en `fase3-diseno.md` §9). Estado:
**pendiente de confirmación**. Este documento fija qué sistema real se modela, qué se extrajo textualmente de las
publicaciones y qué se simplificó. Todo lo que el modelo afirme que no esté en la columna "textual" es una decisión
de modelado nuestra y se declara como tal, con su dirección de conservadurismo.

**Encuadre, dicho primero.** El RTPS es un sistema de **protección de máquina** (protección de inversión): la Fig. 1
de [S1] lo rotula "SOFT PROTECTION"; las capas de seguridad de JET son el CISS ("HARD PROTECTION") y el PSACS
(seguridad de personas). Lo que se modela es, en palabras de [S1], el **Stop Selector** ("implements the state machine
and alarm processing logic"), no el **Stop Manager** ("defines and executes the stop responses"): las formas de onda de
sobreescritura a los cinco sistemas actuadores quedan fuera. La evidencia que produce esta fase es sobre una
*especificación* de lógica de protección, no sobre un sistema, y no es evidencia de una función de seguridad nuclear.
El argumento de que el *método* transfiere a funciones de categoría A/B/C (IEC 61513/61226) se hace aparte
(`fase3-seguridad.md`).

## 1. Candidatos revisados

| Sistema | Qué se encontró | Veredicto |
|---|---|---|
| **JET — Real-Time Protection Sequencer (RTPS) + Pulse Termination Network (PTN)** | Descripción funcional publicada bajo CC BY: fases del pulso, siete disparadores de parada (*stop triggers*), tres tipos de respuesta, **la tabla fase × disparador → respuesta**, respuesta primaria/secundaria, protección local, enclavamiento (*latching*) de la salida del PTN, secuencia de disparo del sistema de mitigación de disrupciones (apagar calentamiento → acuse o timeout → inyección), watchdog, alarmas "ciegas"; y, en [S6], la regla de conexión del DMV al PTN, la ventana y umbrales de habilitación del DMV, los tiempos de apagado y el registro de disrupciones perdidas por configuración. | **Elegido.** Es el único con lógica discreta publicada al nivel de tabla, en fuentes abiertas, y con tamaño que entra en el certificado. |
| ITER — Central Interlock System / Plant Interlock System: A. Vergara Fernández et al., *Modeling tools for the ITER Central Interlock System*, FED 86 (2011) 1137–1140; L. Fernández-Hernando et al. (incl. A. Vergara), *The ITER interlock system*, FED 129 (2018) 104–108; Barrera et al., FED 129 (2018) 73–77 | Arquitectura (lenta PLC / rápida FPGA / cableada), categorías de funciones, metodología de despliegue. Las funciones concretas y sus permisivos están en documentos internos de IO; los papers de FED no tienen licencia CC y los resúmenes públicos no alcanzan para extraer una tabla de eventos → acciones. No se revisaron a fondo los papers de ICALEPCS (abiertos) sobre el CIS. | Descartado para esta fase (posible segundo caso). |
| ASDEX Upgrade — Discharge Control System, manejo de excepciones: W. Treutterer et al., FED 89 (2014) 146–154, DOI 10.1016/j.fusengdes.2014.01.001 (copia verde en MPG PuRe; la versión del editor no es CC) | Describe el *framework*: segmentos, planificador de segmentos, detección local y central de eventos. La lógica concreta de reacción es configuración por descarga (segmentos de reparación "laid down in the pulse schedule"); no publica una tabla fija evento → acción. | Descartado: no hay tabla fija que modelar. |
| MAST-U — Real-Time Protection System: S. Hall, P. Jacquet, G. Naylor, FED 146 (2019) 421–425, DOI 10.1016/j.fusengdes.2018.12.082; preprint UKAEA-CCFE-CP(19)29 | Monitoreo de umbrales (corrientes, fuerzas axiales, energía almacenada, I²t) → acciones (paradas a fuentes, parada controlada por PCS, *kick* vertical); "breaches are mapped to actions", con mapeos configurables. La expresión "state machine" no aparece en el paper. | Descartado: es una tabla de umbrales, no un secuenciador. |
| KSTAR — Fast/Supervisory Interlock | Solo se revisaron resúmenes (FED, paywall). | No evaluado a fondo; queda anotado. |

## 2. Fuentes elegidas

- **[S1]** A. V. Stephen et al., *Centralised Coordinated Control to Protect the JET ITER-like Wall*, Proc. ICALEPCS
  2011, Grenoble, paper FRAAULT04, pp. 1293–1296, ISSN 2226-0358 (JACoW 2011 no asigna DOI; la cita de registro es
  URL + id). CC BY 3.0. Copia en `sources/Stephen2011_ICALEPCS_FRAAULT04_CC-BY-3.0.pdf`, texto en
  `sources/Stephen2011_FRAAULT04.txt` (con cabecera de atribución). **Fuente principal.**
  https://accelconf.web.cern.ch/icalepcs2011/papers/fraault04.pdf
  (Nota: la lista de referencias de [S3] cita este paper como "(2012) 1423"; las páginas correctas son 1293–1296.)
- **[S2]** J. Waterhouse, M. Wheatley, A. Stephen, C. Hogben, G. Jones, A. Goodyear, T. Farmer, P. McCullen, *JET CODAS —
  the final status*, Fusion Eng. Des. 210 (2025) 114737, DOI 10.1016/j.fusengdes.2024.114737. **CC BY 4.0** (Crown
  Copyright 2024, Elsevier). Extracto verbatim de §3.4 en `sources/Waterhouse2025_sec3-4_excerpt_CC-BY-4.0.txt`. No se
  copia el PDF completo por elección, no por restricción de licencia. (Escribe "Real-Time Protection **Sequence**";
  [S1]/[S3] escriben "Sequencer".)
- **[S3]** J. S. Edwards et al., *Robust configuration of the JET Real-Time Protection Sequencer*, Fusion Eng. Des. 146
  (2019) 277–280, DOI 10.1016/j.fusengdes.2018.12.045 (referencia de registro; no CC). Preprint abierto UKAEA-CCFE-CP(19)30,
  SOFT 2018: https://scientific-publications.ukaea.uk/wp-content/uploads/UKAEA-CCFE-CP1930.PDF. Su leyenda de "no
  circular" está condicionada a "prior to publication of the original", ya ocurrida; se cita, no se copia.
- **[S4]** D. Alves et al., *The Software and Hardware Architectural Design of the Vessel Thermal Map Real-Time System in
  JET*, Proc. ICALEPCS 2011, WEPMN014, pp. 905–908. CC BY 3.0. Copia en `sources/`. Contexto de las alarmas térmicas
  (DHS; ciclo de 10 ms).
- **[S5]** M. Jouve et al., *Real-time protection of the "ITER-like Wall at JET"*, Proc. ICALEPCS 2011, WEPMU018,
  pp. 1096–1099. CC BY 3.0. Cámaras de protección; solo contexto.
- **[S6]** C. Reux, M. Lehnen, U. Kruezi, S. Jachmich, P. Card, K. Heinola, E. Joffrin, P. J. Lomas, S. Marsen, G. Matthews,
  V. Riccardo, F. Rimini, P. de Vries and JET EFDA contributors, *Use of the disruption mitigation valve in closed loop for
  routine protection at JET*, Fusion Eng. Des. 88 (2013) 1101–1104, DOI 10.1016/j.fusengdes.2012.12.026. Preprint abierto
  EFDA–JET–CP(12)05/22 (SOFT 2012): https://scipub.euro-fusion.org/wp-content/uploads/2014/11/EFDC120522.pdf. Se cita,
  no se copia. **Agregada en la revisión 3**: regla de conexión del DMV al PTN, ventana y umbrales, tiempos, misses.
- **[S7]** C. I. Stuart et al., *PETRA: A generalised real-time event detection platform at JET for disruption prediction,
  avoidance and mitigation*, Fusion Eng. Des. 168 (2021) 112412, DOI 10.1016/j.fusengdes.2021.112412 (acceso abierto).
  Consolidación post-2018 de los disparadores del DMS; condiciones de habilitación de las alarmas.

## 3. Qué se extrajo textualmente

Las citas son de [S1] salvo indicación. Numeradas **R-n**; su clase (contexto / arquitectura / requisito funcional /
dato de configuración / justificación) está en `fase3-seguridad.md`, donde se derivan los requisitos de seguridad.

### Arquitectura de la cadena (contexto)

- **R-0** "JET machine protection has been provided historically by three systems. The Central Interlock and Safety
  System (CISS) provides basic hardwired plant protection. Higher level protection with limited configurability is
  provided by the Pulse Termination Network (PTN). [...] The PTN output is a latched stop signal to each of the control
  systems, which execute a fixed shutdown sequence in response. Finally, additional heating systems require enable
  signals from the Plant Enable Window System (PEWS) which are conditioned by real-time protection signal validation
  algorithms." [S2]: "CISS was built as a finite state machine with combinatorial input logic."
- El RTPS es "a centralised controller which responds to the VTM and WALLS alarms by providing override commands to the
  plasma shape, current, density and heating controllers". Ciclo de 500 Hz; entradas del VTM a 100 Hz. Dos módulos:
  "the Stop Selector GAM which implements the state machine and alarm processing logic, and the Stop Manager GAM which
  defines and executes the stop responses."
- Estados del supervisor: "A supervisory level set of tasks implements a state machine distinguishing background
  operation, preparation for an experiment (pulse), pulse on, and post-pulse actions".

### Fases del pulso

- **R-1** "Pulses are split into several timed 'phases'. Responses can be defined that vary by phase and category of
  alarm for each pulse." [S3]; y "Available states are defined by Level-1 so no hard-coded states are required" [S3].
  Los siete nombres de fase (**Breakdown, Ip Rise, Limiter, X-point, Heating 1, Heating 2, Plasma Termination**) son las
  etiquetas de fila de la Tabla 1 de [S1] (R-5), no prosa. [S6] lista otra vocabulario, abierto: "in which phases of the
  discharge (current ramp-up, X-point formation, heating, scenario termination, ...) the DMV is to be enabled".
  **Conclusión: el conjunto de fases es una instancia de configuración, no una propiedad del sistema.**

### Disparadores de parada (stop triggers)

- **R-2** "Seven stop triggers have been identified. Three represent thermal problems. These are hot spots in the main
  chamber (inner and outer walls), in the divertor [...] or which occur in both regions. Two are associated with
  magneto-hydrodynamic (MHD) instabilities. Two more allow for generic conditions requiring either a slow or fast
  termination of the pulse."

### Respuestas de parada (stop responses)

- **R-3** "There are three kinds of stop response. If a fault occurs early in the discharge before main heating phase,
  it can be sufficient to trigger the PTN system. During the heating phase, the real-time controllers require overrides
  which are fully programmable, termed RTPS stops. In some cases, the best possible way to end a pulse is to execute the
  control waveforms that would have come into force had the experiment reached a natural conclusion. This is termed a
  jump-to-termination (JTT) stop." Y sobre las sobreescrituras: "the override is specified as a waveform which is
  parameterised as a set of steps, where for each step, the reference value to achieve and the time in which to make
  the transition are defined [...] If 10MW of neutral-beam total power were being delivered and a stop response was
  initiated, the new reference could be set to 6MW".
- **R-4** [S2]: "RTPS was also able to take control of the waveforms used to drive the shape controller and the heating
  systems such as RF and Neutral Beams via their local manager to ramp down the plasma current and heating power to
  give a softer landing for the plasma termination. [...] On a jump to termination, RTPS would signal to the shape
  controller, heating system local manager and gas injection local managers to move forward in their waveforms to the
  termination region." Y la autocrítica: "A better language would have been time within a sequence of plasma control
  and jumps from within one sequence to the start of another, the termination sequence".
- La motivación del RTPS: "The new system should act early, to prevent PTN or CISS from following a global stop strategy
  that might cause excessive energy loads on the walls."

### La tabla de configuración (Tabla 1 de [S1])

- **R-5** "Table 1 illustrates the matrix that links stop triggers to stop responses, as a function of experimental
  phase. The full control matrix is a key part of the protection system configuration interface." Leyenda: "Table 1:
  The **primary** stops table configures the mapping between stop triggers and stop responses as a function of
  experimental phase. A subset of the possible stop triggers are shown, including mode lock (MHD), main chamber hotspot
  (MCHS) and divertor hotspot (DHS)." (La cuarta columna, "Slow", se identifica con el disparador "slow termination" de
  R-2: inferencia nuestra.)

  | Fase | Slow | MHD | MCHS | DHS |
  |---|---|---|---|---|
  | Breakdown | PTN | None | None | PTN |
  | Ip Rise | PTN ⁱ | None ⁱ | None ⁱ | PTN ⁱ |
  | Limiter | PTN | None ⁱ | None ⁱ | PTN ⁱ |
  | X-point | PTN | None ⁱ | None ⁱ | PTN ⁱ |
  | Heating 1 | RTPS | None ⁱ | RTPS | PTN |
  | Heating 2 | RTPS | None ⁱ | RTPS | JTT |
  | Plasma Termination | PTN | None ⁱ | PTN | PTN |

  ⁱ = celda leída de una marca de "ídem" (`|`); **15 celdas impresas, 13 por ídem**. Verificación forense
  independiente (dos revisores): la página 1295 no contiene ningún objeto vectorial (`lines=[]`, `rects=[]`,
  `curves=0`); cada `|` es el glifo U+007C en fuente CMSY10 centrado en la coordenada x de su columna a < 0,2 pt;
  en cada una de las 7 filas, celdas impresas + glifos = 4; y donde una columna trae un valor impreso (`Limiter PTN`)
  el glifo no aparece. Son marcas de "ídem", no reglas de tabla.

  Es una **configuración de ejemplo** ("illustrates"), no la lógica fija del sistema: la matriz completa la define el
  *session leader* por pulso. Existe una matriz **secundaria** que no está publicada (A-16). En el modelo la matriz es un
  dato; se certifica la regla para toda matriz y esta instancia por conformidad (`fase3-diseno.md` P11).

  **La columna MHD = None no significa "el mode lock no hace nada en JET".** [S6]: el mode lock "is already used at JET
  to soft-stop the pulse, albeit with a lower value than the one used to trigger the DMV"; y "a bad situation (mode-lock)
  has already been detected and soft-stop strategies have been initiated. They aim at reducing the disruption forces by
  transiting to a low-triangularity configuration". [S7]: PETRA "triggers a stop and MGI" ante un modo bloqueado. Lecturas
  compatibles: en 2011 la protección por mode lock corría fuera de la tabla primaria del RTPS (vía RTCC / conexiones
  directas al PTN, después consolidadas en PETRA), y la misma señal tiene dos umbrales con dos respuestas. "None" significa
  "sin respuesta primaria del RTPS", no "sin protección". Por eso el modelo certifica una **segunda instancia** en la que
  MHD llega al PTN y arma el DMS (`fase3-diseno.md` §6).

### Primaria y secundaria; jerarquía

- **R-6** "The system also takes account of the possibility that one class of fault (and corresponding stop response)
  might be followed soon after by another. [...] This is addressed, by allowing for two levels of stop response,
  primary, and secondary. Not all possible combinations of control are allowable, since in some cases, once a primary
  stop response has begun, the best outcome is achieved by allowing it to run to completion."
- **R-7** [S2]: "This could initiate slow and fast termination of the plasma through PTN via 16 configurable direct
  connections. Unlike PTN, RTPS was able to act hierarchically so that subsequent alarms could generate a more urgent
  stop." [S6]: "The triggering of the DMV can be attached to any of the stops sent to the Plasma Termination Network
  (PTN) either directly or through an RTPS response."
- Nota de vocabulario: "slow/fast" nombra en R-2 dos *disparadores* y en R-7 dos *clases de salida* del PTN. El PTN
  no es una sola respuesta; en el modelo lo es (A-20).

### Protección local

- **R-8** "Local alarms are limited in location or time, or may be set at lower thresholds and trigger a protection
  response which allows continued operation with dynamically controlled limits on further injection of heating with
  fine granularity. If this fails to bring checks back into tolerance, global alarms are raised which result in control
  overrides which truncate the experiment and land the plasma safely."
- **R-9** "when a local hotspot alarm occurs for such an element, the relevant PINI should be turned off to prevent
  further overheating. This should not preclude the neutral-beam system as a whole from continuing to deliver the total
  requested power to the plasma, as other PINIs can be turned on to compensate."

### PTN: enclavamiento y secuencia de mitigación de disrupciones

- **R-10** [S2]: PTN "consists of a set of inputs from physical plant (inc. CISS) and programmable inputs from software
  implemented protection systems that are mapped onto a set of control outputs which stop various [*sic*] plant systems.
  Additionally, inputs and outputs can be enabled or disabled and inputs can be generated on a timer and latched and time
  stamped on activation." (El enclavamiento de las *entradas* es una capacidad configurable; el enunciado incondicional
  del enclavamiento es el de la *salida*, en R-0.)
- **R-11** [S2]: "Several PTN outputs are used to trigger the Disruption Mitigation System (DMS) [...]. As the injection
  of a massive quantity of gas into a plasma with Neutral Beam or RF heating would be undesirable, these triggers first
  cause the heating systems to be turned off and then conditioned with an acknowledgement from the heating plant (and
  timeout) before activating the DMS." [S6] da la razón de ingeniería y los tiempos: "Heating systems cannot be operating
  when the DMV is activated (limitation beam duct pressure and antennae lines). Consequently, they have to be switched
  off via interlocks before the triggering of the valve. [...] It takes only 2 ms to switch off the NBI power supplies,
  but approximately 38 ms to switch off RF. Due to the fact that no feedback signal is sent by RF plant to confirm that
  power supplies have been switched off, additional margin was taken leading to an overall delay of 50 ms between the
  request and the actual injection." Es protección de la *planta de calentamiento*, con **timeout como camino real**
  (RF no acusa).
- **R-14** [S6], habilitación del DMV: "The DMV was used systematically for scenarios above 2.5 MA, and for some other
  risky scenarios between 2.0 MA and 2.5 MA. In addition, it is usually left active down to 1.75 MA. The use of the DMV
  is enabled only for a pre-programmed time window during the pulse, generally between the X-point formation and the
  end of the post-heating phase." [S2] §3.3: "use of Disruption Mitigation when the plasma current is greater than 2 MA".
  [S7]: alarmas condicionadas a "plasma current > 1.6 MA OR plasma energy > 5 MJ".
- **R-15** [S6], disrupciones perdidas por configuración (2011–2012, 67 mitigadas): "5 disruptions were missed due to
  inhibits in the real-time protection systems that prevented the valve from firing. [...] 4 disruptions were missed
  due to an incorrect setting of the time window when the DMV was enabled. Finally, 7 disruptions were detected at a
  plasma current lower than the minimum current needed for the DMV to be fired."

### Permisivos del calentamiento (PEWS)

- **R-12** [S2]: "The Plant Enable Window System (PEWS) provides enable windows, realised as pulse trains over FO links,
  to heating systems plant based on time in the pulse and basic plasma conditions. [...] provided basic interlocks with
  plasma current and density along with the programmed time windows. Its successor, PEWS2 [...] provided enhanced neutral
  beam shine-through calculations on a PINI-by-PINI basis".

### Fiabilidad: alarmas ciegas, fallas de comunicación, watchdog

- **R-13** "Alarm systems such as the VTM define blind stop alarms to handle loss of critical signals during a shot. If
  RTPS detects communication or status faults with the alarm source systems, or real-time controllers, it can trigger
  the PTN system. A hardware watchdog signal to PTN ensures that RTPS is operational itself."

### Validación en la fuente (para el relato del preprint)

- [S3]: "much of the state machine logic implemented in RTPS GAMs was migrated to Level-1"; validación por "71 pulse
  schedules" definidos por el Plasma Operations Group como "behavioural tests", más "unit tests for each component".
  Es el hueco que el método cubre: pruebas por casos → leyes para toda traza y para toda configuración. [S2]: un análisis
  automático post-pulso produce "an ordered list of events that lead to termination of the pulse".

## 4. Registro de hipótesis (decisiones de modelado)

Cada ítem es **nuestro**, no de la fuente. Columnas: **Dirección** = conservadora (el modelo exige más que el sistema),
no conservadora (exige menos), o neutral/fabricada; **Si es falsa** = qué ley pierde sustento. Las leyes que dependen de
cada hipótesis están en la tabla de `fase3-diseno.md` §2.

| # | Hipótesis | Dirección | Si es falsa |
|---|---|---|---|
| **A-1** | **Orden de las respuestas** `None < JTT < RTPS < PTN`. Ordena **autoridad / irreversibilidad**, no seguridad. PTN arriba lo fuerza R-0 (salida enclavada, secuencia fija): nada más suave puede reemplazarlo. JTT vs RTPS es una elección nuestra: **no es un concepto de JET** (la Tabla 1 los ordena por celda, no globalmente). Contra-hipótesis: en calentamiento, escalar a PTN es lo que el RTPS existe para evitar ([S1]). | neutral | P1 y P3 cambian de sentido; C3 lo mide |
| **A-2** | **Escalada = máximo.** Ante una alarma, `nivel := max(nivel, req)`. R-6 dice explícitamente que JET puede **suprimir** una escalada ("allowing it to run to completion"): esto es una **política distinta**, no una aproximación conservadora; P1 es un teorema sobre nuestra política. | no conservadora respecto de R-6 | P1 deja de describir a JET |
| **A-3** | **Primaria/secundaria: fuera de alcance** (ver A-16). La revisión 1 tenía un campo `sec`; era inalcanzable con esta matriz (la única celda JTT está en `Heating2`, JTT salta a `Termination`, y esa fila no tiene RTPS). | — | — |
| **A-4** | **Columnas ausentes de la Tabla 1** (21 de 49 celdas): *Fast* → PTN en toda fase (mecanismo respaldado por R-7: "fast termination [...] through PTN"; la uniformidad por fase es nuestra); segundo disparador MHD = MHD; hotspot en ambas regiones = la más urgente de MCHS/DHS según A-1 (solo no trivial en Heating 1 → PTN y Heating 2 → depende del orden). | fabricada | P11b, P13 |
| **A-5** | **Fases**: siete, en orden total, como instancia de configuración (R-1). `Advance` abstrae el reloj del programa (las fases son "timed"); un pulso que salta fases se modela con `Advance` consecutivos sin eventos entre medio. JTT es el segundo escritor de la fase: `phase := Termination` (R-4, "jumps [...] to the start of another, the termination sequence"). Bajo PTN no avanza (R-0). Ventanas de PEWS abstraídas en `heat_allowed(u, phase)` (instancia: Heating 1 y 2 para ambas unidades). **PEWS es otro sistema**, independiente y por PINI (R-12): plegarlo al secuenciador borra esa independencia (ver A-17). Calentamiento temprano en la rampa (LH/ICRH) es rutina en JET: cambia la instancia, no el modelo. | no conservadora en arquitectura | I1 pierde su lectura como PEWS |
| **A-6** | **Dos unidades de calentamiento** (NB, RF) por 16 PINIs + antenas + klystrons. Alcanza para "una unidad se apaga y el pulso sigue"; **no** expresa la compensación de R-9 ("other PINIs can be turned on to compensate"). | neutral | P9 es más débil que R-9 |
| **A-7** | **Protección local = enclavamiento por el resto del pulso.** R-8 habla de "dynamically controlled limits [...] with fine granularity" (un límite que se recalcula, no un bit que se pega); un des-inhibir por hotspot no está publicado. El modelo certifica una política **más restrictiva** que la de JET; el gate C4 recertifica con un `LocalClear` guardado. | conservadora | P8 sobra; nada se pierde |
| **A-8** | **`plasma_ok`**: un booleano por corriente y densidad (R-12). Funde un enlace global (Ip) con uno por PINI y no monótono (densidad/shine-through); no modela validez ni staleness (PDV cae por una lista ordenada de señales, [S2]). | neutral | I1 dice menos de lo que parece |
| **A-9** | **Efecto de las paradas sobre el calentamiento.** Unidad con cuatro valores `Off | Inhibited | Ramping | On`. Al entrar a RTPS o a JTT, toda unidad `On` pasa a `Ramping` (las referencias están sobreescritas / el programa saltó a las formas de onda de terminación, que bajan la potencia: R-3, R-4) y `Ramping` nunca vuelve a `On`. Al entrar a Termination por `Advance` (fin natural), lo mismo. Al llegar a PTN por cualquier camino, `On`/`Ramping` → `Off` en el mismo paso (R-0, R-11). `Inhibited` se preserva siempre. Con una parada en curso, ninguna orden nueva enciende nada. **Revisión 2 tenía "JTT des-energiza"**: contradecía R-4 (JTT *rampa*) y hacía al JTT más duro que el RTPS stop contra A-1. | conservadora en "no enciende"; neutral en "rampa" | I1, I2, P3, P4 |
| **A-10** | **Qué paradas arman el DMS es configuración**, no una propiedad del disparador ([S6]: "attached to any of the stops sent to the PTN either directly or through an RTPS response"). El modelo abstracto recibe el bit `dms` con cada parada; la instancia lo pone en `Fast`, `MHD`, `MHD-B` dentro de la ventana `dms_window(phase)` = X-point … Termination (R-14), y en `False` para falla de comunicación y watchdog (decisión nuestra; [S6] permite cualquiera). Con la Tabla 1 publicada MHD nunca llega a PTN: la instancia 2 (§6 del diseño) sí. | neutral | P16/P17 son sobre la instancia |
| **A-11** | **Secuencia del DMS**: `Idle → Armed` al entrar a PTN con `dms = True`, solo desde `Idle` (una alarma repetida no re-arma ni reinicia la espera; P15, P18); en `Armed` se espera `HeatAck` o `ack_max` ticks; cualquiera → `Fired`, definitivo hasta el fin del pulso. El acuse es una entrada no verificada contra la planta; **el timeout es el camino real para RF** (R-11/[S6]: sin señal de acuse, margen fijo de 50 ms). Lo verificado: armar y apagar ocurren en el mismo paso atómico, y la espera está acotada en ticks. **No** se verifica "conditioned with an acknowledgement" como secuencia (haría falta estado comandado vs. reportado: trabajo futuro). | no conservadora (dispara con timeout sin evidencia de planta) | I4 |
| **A-12** | **Watchdog** desde el lado del PTN: contador `hb` de ticks sin `Heartbeat`; en `hb_max` el PTN dispara (R-13). Corre desde `Breakdown` (inicio del pulso) con `hb = 0`; la guarda es `level ≠ PTN`, no la fase. Si el PTN por watchdog arma el DMS es configuración (A-10). | conservadora | I6 |
| **A-13** | **Falla de comunicación y alarmas ciegas** (R-13) en un solo evento `CommFault` → PTN desde cualquier estado. Son dos caminos de demanda distintos en la planta; se funden. | neutral | P12 |
| **A-14** | **Fin de pulso**: `Reset` es la transición *pulse on → post-pulse* del supervisor de [S1]; aceptado solo si el pulso terminó (PTN activo o fase Termination) y no hay una secuencia de mitigación armada; si no, se ignora. No hay camino publicado que limpie un enclavamiento del PTN a mitad del pulso (R-10: habilitar/deshabilitar es pre-pulso; latch + time stamp; el análisis post-pulso reconstruye la causa). | conservadora | P20; P1 pierde contenido |
| **A-15** | **Sin tiempo real ni vivacidad.** Ticks abstractos; no se prueba que el pulso termine ni que el DMS dispare. Los números que faltan: VTM 10 ms [S4]; VTM→RTPS 100 Hz, RTPS 500 Hz [S1]; PETRA 2 ms [S7]; NBI off 2 ms, RF off 38 ms, pedido→inyección 50 ms, vuelo del gas 3,4 ms [S6]. **I5 acota un contador, no una latencia.** | — | — |
| **A-16** | **Sin matriz secundaria.** La Tabla 1 es "the primary stops table"; la secundaria y "not all possible combinations of control are allowable" (R-6) no están publicadas. R-6 fuera de alcance. Consecuencia concreta bajo A-1: un DHS en Heating 2 durante un RTPS stop en curso se ignora (JTT < RTPS). | — | — |
| **A-17** | **Un solo `step`** para el camino software (RTPS) y el cableado (PTN, CISS). La arquitectura de tres capas de JET existe **por diversidad**; el modelo no dice nada de independencia ni causa común. Va en el resumen del preprint, no acá. | no conservadora en arquitectura | ninguna ley; el alcance |
| **A-18** | **Alfabeto total y bien formado**: sin mensajes perdidos, duplicados, fuera de orden ni corruptos ([S1] tiene una base de mensajes con ids únicos justamente por eso); sin limpieza de alarmas (harmless con escalada monótona). | no conservadora | — |
| **A-19** | **Comando = efecto; sin modelo de actuadores.** `nb`/`rf` son estado comandado; los cinco sistemas actuadores, las formas de onda de sobreescritura y respuestas como "transiting to a low-triangularity configuration" [S6] están fuera del alfabeto. | no conservadora | P2, P3 hablan del comando |
| **A-20** | **Un solo nivel PTN.** Las clases "slow/fast" de salida del PTN (R-7) se representan solo por si la parada arma el DMS (A-10). | neutral | — |
| **A-21** | **Sin bypass ni deshabilitación de entradas/salidas del PTN** (R-10) ni ventana de habilitación mal configurada: exactamente donde JET perdió 5 + 4 disrupciones (R-15). Es el argumento *a favor* del método: certificar la configuración de cada pulso. | no conservadora | — |
| **A-22** | **Umbral de corriente del DMV** (R-14) fuera del alfabeto; solo la ventana por fase. Extensión posible sin estado: un veredicto `ip_ok_dms` en el evento de parada. 7 de las disrupciones perdidas de R-15 son de este tipo. | no conservadora | P16 |
| **A-23** | **Configuración fija durante el pulso e igual a la instancia certificada** (registro de configuración: hashes de modelo, matrices, leyes, versión del checker). | — | todo |

## 5. Tamaño del dominio finito (criterio de ≈10⁵ celdas)

Control finito: 7 fases × 4 niveles × 3 estados del DMS × 2 (`plasma_ok`) × 4² unidades = **2 688 estados**. Alfabeto
**abstracto** (la configuración entra como carga del evento, ver `fase3-diseno.md` §1): `Advance`, `Stop{req, dms}` ×8,
`Local{u}` ×2, `HeatOn{u}` ×2, `HeatOff{u}` ×2, `Plasma{ok}` ×2, `CommFault{dms}` ×2, `Heartbeat`, `Tick{dms}` ×2,
`HeatAck`, `Reset` = **24 variantes**. Los veredictos `bh`, `bt` entran solo al brazo `Tick`: columnas = 22 + 2 × 4 = 30
→ **80 640 celdas** (producto completo 2 688 × 24 × 4 = 258 048; Fase 2b: 32 256 en 34 s). Estimación: ≈ 90 s por
chequeo; re-evaluado en cada archivo que lo importa: gate ≈ 6–8 min.

Estados espurios: para las leyes de *preservación* la hipótesis `inv(s)` es falsa y la implicación cierta; las leyes de
*paso* no llevan esa hipótesis y **deben valer también en esos estados** (así se enuncian). Verificado mecánicamente
en Python sobre el dominio completo antes de escribir Bend (`fase3-diseno.md` §9, H13).
