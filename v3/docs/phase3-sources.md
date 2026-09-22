# Phase 3 — Source: the JET wall-protection chain (RTPS + PTN)

Date: 2026-09-19, **revision 3** (after two rounds of adversarial review; record in `phase3-design.md` §9). Status:
**pending confirmation**. This document fixes which real system is modelled, what was extracted verbatim from the
publications and what was simplified. Anything the model asserts that is not in the "verbatim" column is a modelling
decision of ours and is declared as such, with its direction of conservatism.

**Framing, stated first.** The RTPS is a **machine protection** system (investment protection): Fig. 1
of [S1] labels it "SOFT PROTECTION"; JET's safety layers are the CISS ("HARD PROTECTION") and the PSACS
(personnel safety). What is modelled is, in the words of [S1], the **Stop Selector** ("implements the state machine
and alarm processing logic"), not the **Stop Manager** ("defines and executes the stop responses"): the override
waveforms to the five actuator systems are out of scope. The evidence this phase produces is about a
*specification* of protection logic, not about a system, and is not evidence of a nuclear safety function.
The argument that the *method* transfers to category A/B/C functions (IEC 61513/61226) is made separately
(`phase3-safety.md`).

## 1. Candidates reviewed

| System | What was found | Verdict |
|---|---|---|
| **JET — Real-Time Protection Sequencer (RTPS) + Pulse Termination Network (PTN)** | Functional description published under CC BY: pulse phases, seven stop triggers, three response types, **the phase × trigger → response table**, primary/secondary response, local protection, latching of the PTN output, firing sequence of the disruption mitigation system (turn off heating → acknowledgement or timeout → injection), watchdog, "blind" alarms; and, in [S6], the rule connecting the DMV to the PTN, the DMV enable window and thresholds, the switch-off times and the record of disruptions missed by configuration. | **Chosen.** It is the only one with discrete logic published at table level, in open sources, and with a size that fits in the certificate. |
| ITER — Central Interlock System / Plant Interlock System: A. Vergara Fernández et al., *Modeling tools for the ITER Central Interlock System*, FED 86 (2011) 1137–1140; L. Fernández-Hernando et al. (incl. A. Vergara), *The ITER interlock system*, FED 129 (2018) 104–108; Barrera et al., FED 129 (2018) 73–77 | Architecture (slow PLC / fast FPGA / hardwired), function categories, deployment methodology. The concrete functions and their permissives are in IO internal documents; the FED papers are not CC-licensed and the public abstracts are not enough to extract an events → actions table. The ICALEPCS papers (open) on the CIS were not reviewed in depth. | Discarded for this phase (possible second case). |
| ASDEX Upgrade — Discharge Control System, exception handling: W. Treutterer et al., FED 89 (2014) 146–154, DOI 10.1016/j.fusengdes.2014.01.001 (green copy in MPG PuRe; the publisher's version is not CC) | Describes the *framework*: segments, segment scheduler, local and central event detection. The concrete reaction logic is per-discharge configuration (repair segments "laid down in the pulse schedule"); it does not publish a fixed event → action table. | Discarded: there is no fixed table to model. |
| MAST-U — Real-Time Protection System: S. Hall, P. Jacquet, G. Naylor, FED 146 (2019) 421–425, DOI 10.1016/j.fusengdes.2018.12.082; preprint UKAEA-CCFE-CP(19)29 | Threshold monitoring (currents, axial forces, stored energy, I²t) → actions (stops to sources, controlled stop by the PCS, vertical *kick*); "breaches are mapped to actions", with configurable mappings. The expression "state machine" does not appear in the paper. | Discarded: it is a threshold table, not a sequencer. |
| KSTAR — Fast/Supervisory Interlock | Only abstracts were reviewed (FED, paywall). | Not evaluated in depth; noted. |

## 2. Sources chosen

- **[S1]** A. V. Stephen et al., *Centralised Coordinated Control to Protect the JET ITER-like Wall*, Proc. ICALEPCS
  2011, Grenoble, paper FRAAULT04, pp. 1293–1296, ISSN 2226-0358 (JACoW 2011 assigns no DOI; the citation of record is
  URL + id). CC BY 3.0. Copy in `sources/Stephen2011_ICALEPCS_FRAAULT04_CC-BY-3.0.pdf`, text in
  `sources/Stephen2011_FRAAULT04.txt` (with attribution header). **Main source.**
  https://accelconf.web.cern.ch/icalepcs2011/papers/fraault04.pdf
  (Note: the reference list of [S3] cites this paper as "(2012) 1423"; the correct pages are 1293–1296.)
- **[S2]** J. Waterhouse, M. Wheatley, A. Stephen, C. Hogben, G. Jones, A. Goodyear, T. Farmer, P. McCullen, *JET CODAS —
  the final status*, Fusion Eng. Des. 210 (2025) 114737, DOI 10.1016/j.fusengdes.2024.114737. **CC BY 4.0** (Crown
  Copyright 2024, Elsevier). Verbatim excerpt of §3.4 in `sources/Waterhouse2025_sec3-4_excerpt_CC-BY-4.0.txt`. The
  full PDF is not copied by choice, not by licence restriction. (It writes "Real-Time Protection **Sequence**";
  [S1]/[S3] write "Sequencer".)
- **[S3]** J. S. Edwards et al., *Robust configuration of the JET Real-Time Protection Sequencer*, Fusion Eng. Des. 146
  (2019) 277–280, DOI 10.1016/j.fusengdes.2018.12.045 (reference of record; not CC). Open preprint UKAEA-CCFE-CP(19)30,
  SOFT 2018: https://scientific-publications.ukaea.uk/wp-content/uploads/UKAEA-CCFE-CP1930.PDF. Its "do not
  circulate" legend is conditioned on "prior to publication of the original", which has already occurred; it is cited, not copied.
- **[S4]** D. Alves et al., *The Software and Hardware Architectural Design of the Vessel Thermal Map Real-Time System in
  JET*, Proc. ICALEPCS 2011, WEPMN014, pp. 905–908. CC BY 3.0. Copy in `sources/`. Context for the thermal alarms
  (DHS; 10 ms cycle).
- **[S5]** M. Jouve et al., *Real-time protection of the "ITER-like Wall at JET"*, Proc. ICALEPCS 2011, WEPMU018,
  pp. 1096–1099. CC BY 3.0. Protection cameras; context only.
- **[S6]** C. Reux, M. Lehnen, U. Kruezi, S. Jachmich, P. Card, K. Heinola, E. Joffrin, P. J. Lomas, S. Marsen, G. Matthews,
  V. Riccardo, F. Rimini, P. de Vries and JET EFDA contributors, *Use of the disruption mitigation valve in closed loop for
  routine protection at JET*, Fusion Eng. Des. 88 (2013) 1101–1104, DOI 10.1016/j.fusengdes.2012.12.026. Open preprint
  EFDA–JET–CP(12)05/22 (SOFT 2012): https://scipub.euro-fusion.org/wp-content/uploads/2014/11/EFDC120522.pdf. Cited,
  not copied. **Added in revision 3**: rule connecting the DMV to the PTN, window and thresholds, times, misses.
- **[S7]** C. I. Stuart et al., *PETRA: A generalised real-time event detection platform at JET for disruption prediction,
  avoidance and mitigation*, Fusion Eng. Des. 168 (2021) 112412, DOI 10.1016/j.fusengdes.2021.112412 (open access).
  Post-2018 consolidation of the DMS triggers; enabling conditions of the alarms.

## 3. What was extracted verbatim

Quotes are from [S1] unless indicated. Numbered **R-n**; their class (context / architecture / functional requirement /
configuration datum / justification) is in `phase3-safety.md`, where the safety requirements are derived.

### Architecture of the chain (context)

- **R-0** "JET machine protection has been provided historically by three systems. The Central Interlock and Safety
  System (CISS) provides basic hardwired plant protection. Higher level protection with limited configurability is
  provided by the Pulse Termination Network (PTN). [...] The PTN output is a latched stop signal to each of the control
  systems, which execute a fixed shutdown sequence in response. Finally, additional heating systems require enable
  signals from the Plant Enable Window System (PEWS) which are conditioned by real-time protection signal validation
  algorithms." [S2]: "CISS was built as a finite state machine with combinatorial input logic."
- The RTPS is "a centralised controller which responds to the VTM and WALLS alarms by providing override commands to the
  plasma shape, current, density and heating controllers". 500 Hz cycle; VTM inputs at 100 Hz. Two modules:
  "the Stop Selector GAM which implements the state machine and alarm processing logic, and the Stop Manager GAM which
  defines and executes the stop responses."
- Supervisor states: "A supervisory level set of tasks implements a state machine distinguishing background
  operation, preparation for an experiment (pulse), pulse on, and post-pulse actions".

### Pulse phases

- **R-1** "Pulses are split into several timed 'phases'. Responses can be defined that vary by phase and category of
  alarm for each pulse." [S3]; and "Available states are defined by Level-1 so no hard-coded states are required" [S3].
  The seven phase names (**Breakdown, Ip Rise, Limiter, X-point, Heating 1, Heating 2, Plasma Termination**) are the
  row labels of Table 1 of [S1] (R-5), not prose. [S6] lists another, open, vocabulary: "in which phases of the
  discharge (current ramp-up, X-point formation, heating, scenario termination, ...) the DMV is to be enabled".
  **Conclusion: the set of phases is a configuration instance, not a property of the system.**

### Stop triggers

- **R-2** "Seven stop triggers have been identified. Three represent thermal problems. These are hot spots in the main
  chamber (inner and outer walls), in the divertor [...] or which occur in both regions. Two are associated with
  magneto-hydrodynamic (MHD) instabilities. Two more allow for generic conditions requiring either a slow or fast
  termination of the pulse."

### Stop responses

- **R-3** "There are three kinds of stop response. If a fault occurs early in the discharge before main heating phase,
  it can be sufficient to trigger the PTN system. During the heating phase, the real-time controllers require overrides
  which are fully programmable, termed RTPS stops. In some cases, the best possible way to end a pulse is to execute the
  control waveforms that would have come into force had the experiment reached a natural conclusion. This is termed a
  jump-to-termination (JTT) stop." And on the overrides: "the override is specified as a waveform which is
  parameterised as a set of steps, where for each step, the reference value to achieve and the time in which to make
  the transition are defined [...] If 10MW of neutral-beam total power were being delivered and a stop response was
  initiated, the new reference could be set to 6MW".
- **R-4** [S2]: "RTPS was also able to take control of the waveforms used to drive the shape controller and the heating
  systems such as RF and Neutral Beams via their local manager to ramp down the plasma current and heating power to
  give a softer landing for the plasma termination. [...] On a jump to termination, RTPS would signal to the shape
  controller, heating system local manager and gas injection local managers to move forward in their waveforms to the
  termination region." And the self-criticism: "A better language would have been time within a sequence of plasma control
  and jumps from within one sequence to the start of another, the termination sequence".
- The motivation for the RTPS: "The new system should act early, to prevent PTN or CISS from following a global stop strategy
  that might cause excessive energy loads on the walls."

### The configuration table (Table 1 of [S1])

- **R-5** "Table 1 illustrates the matrix that links stop triggers to stop responses, as a function of experimental
  phase. The full control matrix is a key part of the protection system configuration interface." Caption: "Table 1:
  The **primary** stops table configures the mapping between stop triggers and stop responses as a function of
  experimental phase. A subset of the possible stop triggers are shown, including mode lock (MHD), main chamber hotspot
  (MCHS) and divertor hotspot (DHS)." (The fourth column, "Slow", is identified with the "slow termination" trigger of
  R-2: our inference.)

  | Phase | Slow | MHD | MCHS | DHS |
  |---|---|---|---|---|
  | Breakdown | PTN | None | None | PTN |
  | Ip Rise | PTN ⁱ | None ⁱ | None ⁱ | PTN ⁱ |
  | Limiter | PTN | None ⁱ | None ⁱ | PTN ⁱ |
  | X-point | PTN | None ⁱ | None ⁱ | PTN ⁱ |
  | Heating 1 | RTPS | None ⁱ | RTPS | PTN |
  | Heating 2 | RTPS | None ⁱ | RTPS | JTT |
  | Plasma Termination | PTN | None ⁱ | PTN | PTN |

  ⁱ = cell read from a "ditto" mark (`|`); **15 printed cells, 13 by ditto**. Independent forensic
  verification (two reviewers): page 1295 contains no vector object (`lines=[]`, `rects=[]`,
  `curves=0`); each `|` is the U+007C glyph in the CMSY10 font centred on the x coordinate of its column to < 0.2 pt;
  in each of the 7 rows, printed cells + glyphs = 4; and where a column carries a printed value (`Limiter PTN`)
  the glyph does not appear. They are "ditto" marks, not table rules.

  It is an **example configuration** ("illustrates"), not the fixed logic of the system: the full matrix is defined by the
  *session leader* per pulse. There is a **secondary** matrix that is not published (A-16). In the model the matrix is
  data; the rule is certified for every matrix and this instance by conformance (`phase3-design.md` P11).

  **The MHD = None column does not mean "mode lock does nothing at JET".** [S6]: the mode lock "is already used at JET
  to soft-stop the pulse, albeit with a lower value than the one used to trigger the DMV"; and "a bad situation (mode-lock)
  has already been detected and soft-stop strategies have been initiated. They aim at reducing the disruption forces by
  transiting to a low-triangularity configuration". [S7]: PETRA "triggers a stop and MGI" on a locked mode. Compatible
  readings: in 2011 the mode-lock protection ran outside the RTPS primary table (via RTCC / direct connections
  to the PTN, later consolidated in PETRA), and the same signal has two thresholds with two responses. "None" means
  "no primary RTPS response", not "no protection". That is why the model certifies a **second instance** in which
  MHD reaches the PTN and arms the DMS (`phase3-design.md` §6).

### Primary and secondary; hierarchy

- **R-6** "The system also takes account of the possibility that one class of fault (and corresponding stop response)
  might be followed soon after by another. [...] This is addressed, by allowing for two levels of stop response,
  primary, and secondary. Not all possible combinations of control are allowable, since in some cases, once a primary
  stop response has begun, the best outcome is achieved by allowing it to run to completion."
- **R-7** [S2]: "This could initiate slow and fast termination of the plasma through PTN via 16 configurable direct
  connections. Unlike PTN, RTPS was able to act hierarchically so that subsequent alarms could generate a more urgent
  stop." [S6]: "The triggering of the DMV can be attached to any of the stops sent to the Plasma Termination Network
  (PTN) either directly or through an RTPS response."
- Vocabulary note: "slow/fast" names in R-2 two *triggers* and in R-7 two *output classes* of the PTN. The PTN
  is not a single response; in the model it is (A-20).

### Local protection

- **R-8** "Local alarms are limited in location or time, or may be set at lower thresholds and trigger a protection
  response which allows continued operation with dynamically controlled limits on further injection of heating with
  fine granularity. If this fails to bring checks back into tolerance, global alarms are raised which result in control
  overrides which truncate the experiment and land the plasma safely."
- **R-9** "when a local hotspot alarm occurs for such an element, the relevant PINI should be turned off to prevent
  further overheating. This should not preclude the neutral-beam system as a whole from continuing to deliver the total
  requested power to the plasma, as other PINIs can be turned on to compensate."

### PTN: latching and disruption mitigation sequence

- **R-10** [S2]: PTN "consists of a set of inputs from physical plant (inc. CISS) and programmable inputs from software
  implemented protection systems that are mapped onto a set of control outputs which stop various [*sic*] plant systems.
  Additionally, inputs and outputs can be enabled or disabled and inputs can be generated on a timer and latched and time
  stamped on activation." (The latching of the *inputs* is a configurable capability; the unconditional statement
  of latching is that of the *output*, in R-0.)
- **R-11** [S2]: "Several PTN outputs are used to trigger the Disruption Mitigation System (DMS) [...]. As the injection
  of a massive quantity of gas into a plasma with Neutral Beam or RF heating would be undesirable, these triggers first
  cause the heating systems to be turned off and then conditioned with an acknowledgement from the heating plant (and
  timeout) before activating the DMS." [S6] gives the engineering reason and the times: "Heating systems cannot be operating
  when the DMV is activated (limitation beam duct pressure and antennae lines). Consequently, they have to be switched
  off via interlocks before the triggering of the valve. [...] It takes only 2 ms to switch off the NBI power supplies,
  but approximately 38 ms to switch off RF. Due to the fact that no feedback signal is sent by RF plant to confirm that
  power supplies have been switched off, additional margin was taken leading to an overall delay of 50 ms between the
  request and the actual injection." It is protection of the *heating plant*, with **timeout as the real path**
  (RF does not acknowledge).
- **R-14** [S6], DMV enabling: "The DMV was used systematically for scenarios above 2.5 MA, and for some other
  risky scenarios between 2.0 MA and 2.5 MA. In addition, it is usually left active down to 1.75 MA. The use of the DMV
  is enabled only for a pre-programmed time window during the pulse, generally between the X-point formation and the
  end of the post-heating phase." [S2] §3.3: "use of Disruption Mitigation when the plasma current is greater than 2 MA".
  [S7]: alarms conditioned on "plasma current > 1.6 MA OR plasma energy > 5 MJ".
- **R-15** [S6], disruptions missed by configuration (2011–2012, 67 mitigated): "5 disruptions were missed due to
  inhibits in the real-time protection systems that prevented the valve from firing. [...] 4 disruptions were missed
  due to an incorrect setting of the time window when the DMV was enabled. Finally, 7 disruptions were detected at a
  plasma current lower than the minimum current needed for the DMV to be fired."

### Heating permissives (PEWS)

- **R-12** [S2]: "The Plant Enable Window System (PEWS) provides enable windows, realised as pulse trains over FO links,
  to heating systems plant based on time in the pulse and basic plasma conditions. [...] provided basic interlocks with
  plasma current and density along with the programmed time windows. Its successor, PEWS2 [...] provided enhanced neutral
  beam shine-through calculations on a PINI-by-PINI basis".

### Reliability: blind alarms, communication faults, watchdog

- **R-13** "Alarm systems such as the VTM define blind stop alarms to handle loss of critical signals during a shot. If
  RTPS detects communication or status faults with the alarm source systems, or real-time controllers, it can trigger
  the PTN system. A hardware watchdog signal to PTN ensures that RTPS is operational itself."

### Validation at the source (for the preprint narrative)

- [S3]: "much of the state machine logic implemented in RTPS GAMs was migrated to Level-1"; validation by "71 pulse
  schedules" defined by the Plasma Operations Group as "behavioural tests", plus "unit tests for each component".
  This is the gap the method fills: case-based tests → laws for every trace and every configuration. [S2]: an automatic
  post-pulse analysis produces "an ordered list of events that lead to termination of the pulse".

## 4. Hypothesis register (modelling decisions)

Each item is **ours**, not the source's. Columns: **Direction** = conservative (the model demands more than the system),
non-conservative (demands less), or neutral/fabricated; **If false** = which law loses its support. The laws that depend on
each hypothesis are in the table of `phase3-design.md` §2.

| # | Hypothesis | Direction | If false |
|---|---|---|---|
| **A-1** | **Order of the responses** `None < JTT < RTPS < PTN`. It orders **authority / irreversibility**, not safety. PTN at the top is forced by R-0 (latched output, fixed sequence): nothing softer can replace it. JTT vs RTPS is our choice: **it is not a JET concept** (Table 1 orders them per cell, not globally). Counter-hypothesis: during heating, escalating to PTN is what the RTPS exists to avoid ([S1]). | neutral | P1 and P3 change meaning; C3 measures it |
| **A-2** | **Escalation = maximum.** On an alarm, `nivel := max(nivel, req)`. R-6 says explicitly that JET can **suppress** an escalation ("allowing it to run to completion"): this is a **different policy**, not a conservative approximation; P1 is a theorem about our policy. | non-conservative with respect to R-6 | P1 no longer describes JET |
| **A-3** | **Primary/secondary: out of scope** (see A-16). Revision 1 had a `sec` field; it was unreachable with this matrix (the only JTT cell is in `Heating2`, JTT jumps to `Termination`, and that row has no RTPS). | — | — |
| **A-4** | **Columns absent from Table 1** (21 of 49 cells): *Fast* → PTN in every phase (mechanism supported by R-7: "fast termination [...] through PTN"; the uniformity across phases is ours); second MHD trigger = MHD; hotspot in both regions = the more urgent of MCHS/DHS according to A-1 (only non-trivial in Heating 1 → PTN and Heating 2 → depends on the order). | fabricated | P11b, P13 |
| **A-5** | **Phases**: seven, in total order, as a configuration instance (R-1). `Advance` abstracts the programme clock (the phases are "timed"); a pulse that skips phases is modelled with consecutive `Advance`s with no events in between. JTT is the second writer of the phase: `phase := Termination` (R-4, "jumps [...] to the start of another, the termination sequence"). Under PTN it does not advance (R-0). PEWS windows abstracted in `heat_allowed(u, phase)` (instance: Heating 1 and 2 for both units). **PEWS is another system**, independent and per PINI (R-12): folding it into the sequencer erases that independence (see A-17). Early heating during the ramp (LH/ICRH) is routine at JET: it changes the instance, not the model. | non-conservative in architecture | I1 loses its reading as PEWS |
| **A-6** | **Two heating units** (NB, RF) for 16 PINIs + antennas + klystrons. Each unit has **full, partial or no** power (`On`, `Reduced`, `Off`, plus `Ramping`): a local alarm takes out one PINI and the unit goes to `Reduced` without ceasing to deliver power (R-9); compensation with other PINIs is not modelled and a reduced unit does not return to `On` within the pulse (conservative). Revision 2026-09-21 (F2); until then the model inhibited the whole unit. | conservative in "does not return to On"; neutral in the rest | P9, F2a, F2d |
| **A-7** | **Local protection = reduction for the rest of the pulse.** R-8 speaks of "dynamically controlled limits [...] with fine granularity" (a limit that is recomputed, not a bit that sticks); an un-reduce after a hotspot is not published, so the unit stays `Reduced` until the end of the pulse. Until 2026-09-21 the model inhibited the whole unit (a policy more restrictive than JET's and contrary to the concept of R-9): F2. | conservative | F2d is superfluous; nothing is lost |
| **A-8** | **`plasma_ok`**: one boolean for current and density (R-12). It merges a global interlock (Ip) with a per-PINI, non-monotonic one (density/shine-through); it does not model validity or staleness (PDV falls through an ordered list of signals, [S2]). | neutral | I1 says less than it seems |
| **A-9** | **Effect of the stops on heating.** Unit with four values `Off | Ramping | Reduced | On` (A-26). On entering RTPS or JTT, every `On` or `Reduced` unit goes to `Ramping` (the references are overridden / the programme jumped to the termination waveforms, which bring the power down: R-3, R-4) and `Ramping` never returns to `On`. On entering Termination by `Advance` (natural end), the same. On reaching PTN by any path, `On`/`Reduced`/`Ramping` → `Off` in the same step (R-0, R-11). With a stop in progress, no new command turns anything on. **Revision 2 had "JTT de-energises"**: it contradicted R-4 (JTT *ramps*) and made the JTT harder than the RTPS stop against A-1. | conservative in "does not turn on"; neutral in "ramps" | I1, I2, P3, P4 |
| **A-10** | **Which stops arm the DMS is configuration**, not a property of the trigger ([S6]: "attached to any of the stops sent to the PTN either directly or through an RTPS response"). The abstract model receives the `dms` bit with each stop; the instance sets it for `Fast`, `MHD`, `MHD-B` within the window `dms_window(phase)` = X-point … Termination (R-14), and to `False` for communication fault and watchdog (our decision; [S6] allows any). With the published Table 1 MHD never reaches the PTN: instance 2 (§6 of the design) does. | neutral | P16/P17 are about the instance |
| **A-11** | **DMS sequence**: `Idle → Armed` on entering PTN with `dms = True`, only from `Idle` (a repeated alarm does not re-arm or restart the wait; P15, P18); in `Armed` it waits for `HeatAck` or `ack_max` ticks; either → `Fired`, definitive until the end of the pulse. The acknowledgement is an input not verified against the plant; **the timeout is the real path for RF** (R-11/[S6]: no acknowledgement signal, fixed 50 ms margin). What is verified: arming and switching off occur in the same atomic step, and the wait is bounded in ticks. "conditioned with an acknowledgement" is **not** verified as a sequence (it would need commanded vs. reported state: future work). | non-conservative (fires on timeout without plant evidence) | I4 |
| **A-12** | **Watchdog** from the PTN side: counter `hb` of ticks without `Heartbeat`; at `hb_max` the PTN fires (R-13). It runs from `Breakdown` (start of the pulse) with `hb = 0`; the guard is `level ≠ PTN`, not the phase. Whether the PTN by watchdog arms the DMS is configuration (A-10). | conservative | I6 |
| **A-13** | **Communication fault and blind alarms** (R-13) are two paths: `CommFault{dms, en}` → PTN from any state **if the check is enabled** (`en`, the instance's mask: A-21) and identity if not (F3); a blind alarm is the `Blind` trigger of the table (A-25). Until 2026-09-21 both were merged into an unconditional `CommFault`. | neutral | P12, F3b |
| **A-14** | **End of pulse**: `Reset` is the *pulse on → post-pulse* transition of the supervisor of [S1]; accepted only if the pulse has ended (PTN active or Termination phase) and no mitigation sequence is armed; otherwise it is ignored. There is no published path that clears a PTN latch mid-pulse (R-10: enable/disable is pre-pulse; latch + time stamp; the post-pulse analysis reconstructs the cause). | conservative | P20; P1 loses content |
| **A-15** | **No real time or unbounded liveness.** Abstract ticks; it is not proven that the pulse terminates. That the watchdog latches the PTN in `hb_max` ticks and that an armed DMS fires in `ack_max` ticks is proven (`LAWS_JETPROT_LIVE.bend`, 2026-09-21), in ticks, not in ms. The missing numbers: VTM 10 ms [S4]; VTM→RTPS 100 Hz, RTPS 500 Hz [S1]; PETRA 2 ms [S7]; NBI off 2 ms, RF off 38 ms, request→injection 50 ms, gas flight 3.4 ms [S6]. **I5 bounds a counter, not a latency.** | — | — |
| **A-16** | **No secondary matrix.** Table 1 is "the primary stops table"; the secondary one and "not all possible combinations of control are allowable" (R-6) are not published. R-6 out of scope. Concrete consequence under A-1: a DHS in Heating 2 during an RTPS stop in progress is ignored (JTT < RTPS). | — | — |
| **A-17** | **A single `step`** for the software path (RTPS) and the hardwired one (PTN, CISS). JET's three-layer architecture exists **for diversity**; the model says nothing about independence or common cause. It goes in the preprint summary, not here. | non-conservative in architecture | no law; the scope |
| **A-18** | **Total and well-formed alphabet**: no lost, duplicated, out-of-order or corrupted messages ([S1] has a message database with unique ids precisely for that); no alarm clearing (harmless with monotonic escalation). | non-conservative | — |
| **A-19** | **Command = effect; no actuator model.** `nb`/`rf` are commanded state; the five actuator systems, the override waveforms and responses such as "transiting to a low-triangularity configuration" [S6] are outside the alphabet. | non-conservative | P2, P3 speak of the command |
| **A-20** | **A single PTN level.** The "slow/fast" output classes of the PTN (R-7) are represented only by whether the stop arms the DMS (A-10). | neutral | — |
| **A-21** | **Bypass modelled only for the two reliability checks** of R-13 (communication fault, blind alarms), as the instance's mask (`Mask{comm, blind}`: instances 1 and 2 with both enabled, instance 3 with both disabled and certified all the same). The PTN inputs and outputs (R-10) and the misconfigured window remain outside: exactly where JET lost 5 + 4 disruptions (R-15). It is the argument *in favour* of the method: certifying the configuration of each pulse. Revision 2026-09-21 (F3). | non-conservative in what is left out | F3b, `mask_*`, `blind_masked_no_response` |
| **A-22** | ~~DMV current threshold outside the alphabet~~ **Withdrawn 2026-09-21: R-14 modelled.** `ip` is state (the verdict `Ip ≥ threshold`, input `Ip{ok}` like `Plasma{ok}`) and gates the **arming** of the DMS: below the threshold no event arms (IP1); the threshold is evaluated on arming, a later drop does not disarm (conservative with respect to [S6]). 7 of the missed disruptions of R-15 are of this type. | neutral | IP1–IP4, P16, P17 |
| **A-23** | **Configuration fixed during the pulse and equal to the certified instance** (configuration record: hashes of model, matrices, laws, checker version). | — | everything |
| **A-24** | **Two views of time** ([S2] §3.4). `prog` is the Level-1 programme phase: the one that indexes Table 1 and that only `Advance` (and `Reset`) moves. The JTT does not touch it: it sets `jtt`, and the waveform phase is `wave = jtt ? Termination : prog`. `wave` is read by: the heating permissive, the DMV window, the end-of-pulse guard, I2/I3. `prog` is read by: the table, `Advance`, D11/D12. Until 2026-09-21 the JTT wrote `Termination` into the single phase and a later alarm read the Termination row (F1). | neutral | F1a–F1d, E3, D12 |
| **A-25** | **A blind alarm is a trigger of the table** (`Blind`: PTN row in every phase for instances 1 and 2; no response when the mask disables it). R-13 says that the VTM defines "blind stop alarms"; its row is not published. | fabricated (the row) | `asm_*_Blind`, `blind_masked_no_response` |
| **A-26** | **No `Inhibited`.** With local protection reducing (A-7), no pulse event produced the inhibited state; a unit disabled before the pulse (R-10) is configuration, not an event. The value was removed and with it P8 (`inhibit_latched`) and E1 (`inhibit_source`), which would have been left vacuous (gate C2). | — | — |

## 5. Size of the finite domain (≈10⁵ cells criterion)

Finite control: 7 phases × 4 levels × 3 DMS states × 2 (`plasma_ok`) × 4² units = **2 688 states**. **Abstract**
alphabet (the configuration enters as event payload, see `phase3-design.md` §1): `Advance`, `Stop{req, dms}` ×8,
`Local{u}` ×2, `HeatOn{u}` ×2, `HeatOff{u}` ×2, `Plasma{ok}` ×2, `CommFault{dms}` ×2, `Heartbeat`, `Tick{dms}` ×2,
`HeatAck`, `Reset` = **24 variants**. The verdicts `bh`, `bt` enter only the `Tick` arm: columns = 22 + 2 × 4 = 30
→ **80 640 cells** (full product 2 688 × 24 × 4 = 258 048; Phase 2b: 32 256 in 34 s). Estimate: ≈ 90 s per
check; re-evaluated in every file that imports it: gate ≈ 6–8 min.

**Revision 2026-09-21 (blocker 4):** 7 programme phases × 2 (`jtt`) × 4 levels × 3 DMS × 2 (`plasma_ok`) × 2 (`ip`) × 4²
units = **10 752 states**; abstract alphabet of **28 variants** (`Ip{ok}` ×2, `CommFault{dms, en}` ×4); columns
23 + 5 × 4 = 43 → **462 336 cells per order**. Certificate at runtime (JS): 27 s for both orders; concrete layer 3
instances × 7 × 2 × 22 = 924 cells.

Spurious states: for the *preservation* laws the hypothesis `inv(s)` is false and the implication holds; the *step*
laws do not carry that hypothesis and **must also hold in those states** (that is how they are stated). Verified mechanically
in Python over the full domain before writing Bend (`phase3-design.md` §9, H13).
