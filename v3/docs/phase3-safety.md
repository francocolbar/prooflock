# Phase 3 — Hazards, safety requirements and limits of the evidence

Date: 2026-09-19 (revision 4, with the law set closed); updated 2026-09-22 for revision 4 of the hypothesis register (A-1…A-35, the named PTN and primary-stop laws, the secondary stop response); updated 2026-09-23 (the Bend 2.0.25 pin in §5, A-9 in SR-1 and SR-4, R-0 as a basis of `p1a_ptn_latched`, SR-11 and SR-16 for revision 4, the mode-lock row of §3 and C5 described as a re-execution in §5); updated again the same day: the framing of §0 against Fig. 1 and R-0 of [S1], the mode-lock row of §3 against [N1], the toolchain entry of §5 (the age of Bend 2, the `concretize` comparison of C6, negative 8 as the adequacy test) and the answers of §7 on the toolchain, on instance 2 and on self-reference (the twelve `DERIVED` laws, P5's `permit`); and at the close of that day A-9 in SR-5 (for `dms_no_heat`), "independent evidence" in §7 and the mutant bank of §4 described as defects of the Python reference model; then, after a further audit, the invariant check named beside the Python laws in §4, the 7 late detections of R-15 kept apart from the configuration misses in H-F (§1) and the response bounds of §6 stated as checked for the model's limits. Status: **draft**. This document is the upper half of the traceability chain
that a functional safety assessor asks for: **hazard → protection function → requirement (shall / shall not, with
safe state) → hypothesis → law → proof → negative → differential → limit**. The lower half (law → proof) is in
`phase3-design.md`; the quotes and the hypotheses in `phase3-sources.md`. The table `phase3-traceability.md` (step 3) is generated
from these three.

## 0. Claim, scope and class of evidence (what goes in the first paragraph of the preprint)

- The modelled function is **machine protection** (investment protection) of JET: the RTPS ("soft protection" in
  Fig. 1 of [S1]) and its interface to the PTN ("hard protection" in the same figure). It is not a nuclear safety
  function; the rest of JET's hardwired plant protection (the CISS, R-0) and its personnel safety system (the PSACS,
  [S2]) are not modelled.
- The evidence is about a **specification** (a discrete model, without time), not about a system nor an
  implementation. In IEC 61508-3 terms it contributes to a **systematic capability** argument (tables A.1, A.2, A.9:
  formal methods in specification, design and verification) and **does not on its own support any SIL claim**.
- The model is the *Stop Selector* ([S1]), reconstructed **from open publications**; 28 of the 56 cells (21 by A-4, the 7 of the `Blind` row by A-25) of the certified
  matrix are our hypotheses (A-4), the secondary matrix is not published (A-16; the secondary table of instance 4 is illustrative, A-35) and the DMS only arms, in the
  published instance, by an assumed cell.
- Terminology: "certificate" is used only for the internal artefact (the term decided by the checker); never
  "certified system". The deliverable is "a verification evidence package intended to be integrated into a safety
  case", not "a safety case".
- The adversarial review was automated (instances of the same family of models that wrote the design); there was **no**
  independent human assessment. Before the preprint: send the reconstruction to the authors of [S1]/[S2] for
  a reading of factual accuracy (decision of the human author).

## 1. Hazards the chain exists to control

Derived from [S1], [S2] §3.4, [S6]. Demand source = which real system detects.

| ID | Hazard | Demand |
|---|---|---|
| H-A1 | Melting / tile damage by localized heat flux (main chamber or divertor) | VTM (IR, pyrometers), WALLS |
| H-A2 | Shine-through: one PINI heats a specific component | PEWS2 per PINI; local alarm |
| H-A3 | **The stop response itself deposits excessive energy on the wall** (motivation of the RTPS, [S1]) | choice of response |
| H-B | Disruption / MHD instability: thermal quench, halo currents, runaway electrons, forces | mode lock, APODIS, RAPTOR, PETRA |
| H-C | Massive gas injection with NB/RF on (pressure limits of the duct and antenna lines, [S6]) | PTN outputs → DMV/SPI |
| H-C2 | The DMS does not fire or fires late when needed (mandatory > 2 MA, [S2]) | idem |
| H-D | Loss of protection: blind VTM, communication/status fault, dead RTPS | blind alarms, monitoring, watchdog |
| H-E | Heating energized outside its window or without current/density (beam into vacuum) | PEWS/PEWS2 |
| H-F | **Incorrect configuration** of the matrix, of the window or of the inhibits ([S3]; R-15: 5 + 4 missed disruptions; the other 7 of R-15 were late detections) | Level-1 |
| H-G | Second, worse fault during a response in progress (R-6) | any trigger |
| H-H | Spurious stop; bypass (PTN inputs/outputs that can be enabled/disabled, R-10) | — |
| H-I | Loss of independence / common cause between RTPS (software) and PTN/CISS (hardwired) | architecture |
| H-J | Premature release of an interlock or of an inhibit | operator / reset |
| H-K | Late protection with respect to the thermal constant (process safety time) | timing |
| H-L | Command issued but the actuator does not obey | local managers |

## 2. Safety requirements (layer between the R-n quotes and the laws)

Format: **SR-n** (shall / shall not), safe state, demand source, deadline (declared out of scope where
applicable), and class of the quote it derives from (C = context, A = architecture, F = functional requirement, D = configuration
data, J = justification).

| SR | Statement | Safe state | Derives from | Law(s) | Deadline |
|---|---|---|---|---|---|
| SR-1 | On receiving a PTN stop demand by any path, the system **shall** take every heating unit out of `On`/`Reduced`/`Ramping` in the same cycle. | `ptn_no_heat` | R-0 (A), R-11 (F), A-9 | `ptn_deenergizes`, I1, I2 | out (A-15) |
| SR-2 | A stop **shall not** be replaced by a response of lower authority during the pulse. | — | R-0 (A), R-7 (F), A-2, A-14; [N1] PDF pp.13–14 | `latched`, **`stop_honoured`**; named apart from our soft-over-soft policy (revision 4): `p1a_ptn_latched` (R-0; [N1] PDF p.14), `p1b_stop_never_cleared` (R-0 for the PTN; for soft stops our reading, A-14), `piw_after_ptn_is_noop` (the "invalid task" of [N1] PDF p.13, formalised by us as a no-op, A-14) | — |
| SR-3 | On an alarm whose configured response is RTPS or JTT, the system **shall** take every unit out of full power in the same cycle and **shall not** return it to full power in the pulse. | `stop_no_full_power` | R-3, R-4 (F), A-9 | `stop_reduces_power`, **`soft_stop_ramps`**, `ramping_never_returns`, I2 | out |
| SR-4 | No unit **shall** energize outside the enable window (fixed in the model for all instances), without plasma conditions, or with a stop in progress. | — | R-12 (F), A-5, A-8, A-9, A-27, A-28 | I1, `heat_permissive`, `stop_overrides_heat`, `heat_frame` | — |
| SR-5 | The DMS **shall not** arm or fire except with the PTN active (and by SR-1, with no heating commanded). | `dms_no_heat` | R-11 (F), [S6], A-9 (for `dms_no_heat`) | I4, `dms_frame`, **`dms_fire_frame`** | — |
| SR-6 | When a stop marked for DMS reaches the PTN, the DMS **shall** arm; the wait for the acknowledgement **shall** be bounded; a repeated alarm **shall not** restart it. | — | R-11 (F), A-10, A-11 | `dms_armed_on_demand`, I5, `tack_frame`, `dms_monotone`, **`ack_timeout_fires`**, **`heatack_exact`**; **`dms_responds`** (armed ⇒ fired in ≤ `ack_max` ticks, b5) | out (50 ms real, [S6]); the bound is in ticks |
| SR-7 | The absence of the RTPS heartbeat for `hb_max` cycles **shall** produce a PTN stop. | — | R-13 (F), A-12 | I6, **`watchdog_latches`**, **`heartbeat_resets_hb`**, **`hb_tick_exact`**, **`hb_frame`**; **`watchdog_responds`** (`hb_max` ticks without heartbeat ⇒ PTN, for every trace, b5) | out; the bound is in ticks |
| SR-8 | A communication fault **shall** produce a PTN stop from any state when the instance enables the check, and **shall not** do anything when it disables it; a blind alarm **shall** go through the table (revision 2026-09-21). | — | R-13 (F), A-13, A-21, A-25 | `commfault_ptn`, **`f3b_commfault_masked_is_noop`**, `mask_*`, `asm_*_Blind` | out |
| SR-9 | A local alarm **shall** take the affected unit from full power to partial power (one PINI out) and **shall not** alter phase, response, DMS or the other unit; the reduction **shall** persist for the pulse (revision 2026-09-21: previously "inhibit"). | — | R-8, R-9 (F/J), A-6, A-7, A-33, A-34 | `local_is_local`, **`f2a_local_reduces`**, **`f2d_reduced_never_returns`** (one step only: an `Off` → `On` cycle restores full power, A-34, so "persist for the pulse" is **not** established) | — |
| SR-16 | A concrete alarm **shall** read Table 1 in the programme phase when no stop is in force, and the instance's secondary table when one is (revision 4); a JTT **shall** switch the termination waveform and **shall not** move the programme phase (revision 2026-09-21). | — | R-1, R-4 (F), R-6 (J), [S2] §3.4, A-3, A-24, A-30 | **`f1a_table_reads_prog`**, **`f1b_stop_keeps_prog`**, **`f1c_wave_ahead`**, **`f1d_wave_frame`** | — |
| SR-18 | The DMS **shall not** arm without the DMV arming verdict (plasma current, or current OR stored energy, above threshold: A-22) and **shall** arm on a demand with it (revision 2026-09-21). | — | R-14 (F), [S6], [S7], A-22 | **`ip1_low_never_arms`**, **`ip2_arms_on_demand`**, **`ip3_ip_is_input`**, **`ip4_ip_frame`** | out (the threshold as a number) |
| SR-10 | The response **shall not** change except by alarm, communication fault, expired watchdog or end of pulse. | — | R-13, A-12, A-13 | `no_spurious_stop` | — |
| SR-11 | The certified configuration **shall** match the published one cell by cell (and the assumed cells **shall** be identified). | — | R-5 (D), R-6 (J), A-4, A-16, A-35 | `pub_*` (28), `asm_*` (21 + 7 `_Blind`), `fast_ptn`, **`concretize_is_the_table`**, **`step_c_is_the_concrete_step`**; revision 4: `inst4_table`, `inst4_mask`, `sec_legacy`, `sec_inst4`, `sec_monotone`, `sec_primary_ptn`, `inst4_second_alarm_ptn` | — |
| SR-12 | Under PTN the programme **shall not** advance; the programme **shall not** rewind. | — | R-0, A-5 | `advance_frozen`, `phase_monotone`, **`advance_is_one_step`**, **`phase_frame`** | — |
| SR-13 | The end of pulse **shall** release the interlocks only with the pulse finished and no mitigation armed. | — | A-14, [S1] supervisor | `reset_guarded`, `reset_refused_mid_pulse`, **`reset_accepted_when_safe`** | — |
| SR-15 | The plasma conditions **shall** reflect their input and **shall not** change by any other path. | — | R-12 (F), A-8 | **`plasma_is_input`**, **`plasma_frame`** | — |
| SR-19 | A stop request **shall** be honoured: the response becomes the most urgent of the current one and the requested one. | — | R-7 (F), A-2; [N1] PDF p.13 | **`stop_honoured`**; the parts about the PTN and the primary stop, named apart (revision 4): `d1a_ptn_honoured` (a PTN request from any state, soft stop included; its same-step switch-off is A-9), `d1b_primary_honoured` (the primary stop); concrete, instance 4 only: `inst4_second_alarm_ptn` | — |
| SR-14 | For every sequence of events of the alphabet, the state **shall** satisfy I1–I6. | `inv_all` | all | `traces_safe`, `traces_safe_concrete` | — |

Numbering: SR-17 is not used (the masked communication fault and the blind alarm are part of SR-8 since 2026-09-21);
SR-19 carried a duplicate number, SR-16, until revision 4 of the register. `phase3-traceability.md` §1 uses the same
numbers.

**Out of scope, declared**: the content of JET's secondary table (R-6 → A-16; the mechanism is modelled since revision 4 as instance data, A-3, with the previous reading in instances 1–3 and an illustrative PTN table in instance 4, A-35) and the freeze of the stop configuration at the primary stop (A-24, A-30); the acknowledgement as a sequence (R-11 partial → A-11);
the bypass of the PTN inputs and outputs and the misconfigured windows (R-15 → A-21; the masks of the two reliability
checks are modelled); every deadline (A-15). The DMV enabling condition is no longer out of scope (A-22, SR-18; since revision 4 of the register it is read as current OR stored energy above threshold).

## 3. Hazard → law matrix

S = safety law (demand on the protection function); A = availability or frame; — = no law. In **bold**,
the laws added after two adversarial reviews showed that the previous set was purely
negative (`phase3-design.md` §9b).

| Hazard | S | A | No law / gap |
|---|---|---|---|
| H-A1 hot spot before heating | `pub_*`/`asm_*`, `ptn_deenergizes`, I1, **`stop_honoured`** | — | what to respond with a stop already in progress: only `latched` and `stop_honoured` |
| H-A1 **during heating** (→ RTPS) | **`soft_stop_ramps`**, `stop_reduces_power`, `ramping_never_returns`, I2, `stop_overrides_heat` | — | how far the power comes down and in how long (A-19, A-15) |
| H-A2 shine-through / local | **`f2a_local_reduces`**, **`f2d_reduced_never_returns`** | `local_is_local` | which PINI to take out (the PEWS2 logic); compensation with other PINIs (A-6) |
| H-A3 the stop damages the wall | — | — | **inexpressible** in this abstraction; it is the motivation of [S1]; declared |
| H-B disruption / MHD | `dms_armed_on_demand` (instance 2) | — | in the published instance MHD → None; in the tables JET configured, MHD-driven stops were among the most frequent primary PIW (RTPS-triggered) stops of 2011–2012 ([N1] PDF pp.12, 14), and the mode lock also fired the DMV through a PTN stop ([S6], [S7]); instance 2 certifies our reading of the PTN path, not the soft one (R-5 note of `phase3-sources.md`) |
| H-C gas with heating | I4 ∧ I1 ∧ I2 (`dms_no_heat`), `dms_frame`, **`dms_fire_frame`** | — | commanded state, not reported (A-11, A-19) |
| H-C2 the DMS does not fire | `dms_armed_on_demand`, **`ip2_arms_on_demand`**, **`ack_timeout_fires`**, **`heatack_exact`**, **`ack_counts`**, **`dms_responds`** (b5) | I5, **`ip1_low_never_arms`** | real-time liveness (A-15: the proved bound is in ticks); the threshold as a number (R-14) |
| H-D loss of protection | `commfault_ptn`, I6, **`watchdog_latches`**, **`heartbeat_resets_hb`**, **`hb_tick_exact`**, **`hb_frame`** | `no_spurious_stop` | faults of the PTN itself; the two detection sides of a communication fault merged into one step (A-13, A-17) |
| H-E outside window | I1, `heat_permissive`, `stop_overrides_heat`, `heat_frame`, **`plasma_is_input`**, **`plasma_frame`** | — | the independence of the real PEWS (A-5, A-17); the per-pulse, per-unit windows (A-27) |
| H-F configuration | `pub_*`/`asm_*`, **`concretize_is_the_table`**, **`step_c_is_the_concrete_step`**, `fast_ptn`, C2, configuration record (A-23) | — | there is no **well-formedness** law for configurations (e.g. "no phase with plasma maps a thermal trigger to None"): future work |
| H-G second fault | `latched`, **`stop_honoured`**; `d1a_ptn_honoured` (a PTN always pre-empts); instance 4: `inst4_second_alarm_ptn` | — | Second alarms: the base instances resolve them with the primary table at the advancing programme phase and the maximum (A-2, A-24, A-30), so a DHS in the Heating 2 row during an RTPS stop is ignored; instance 4 with an illustrative PTN secondary (A-35); JET's secondary table is unpublished; the freeze of [N1] is not modelled |
| H-H spurious / bypass | **`f3b_commfault_masked_is_noop`**, `mask_*` | `no_spurious_stop`, `reset_guarded`, `local_is_local` | the bypass of PTN inputs/outputs is not modelled (A-21); the masks of the two checks are |
| H-I independence | — | — | **nothing** (A-17): goes in the preprint's abstract |
| H-J premature release | `latched`, `f2d_reduced_never_returns`, `dms_monotone`, `reset_guarded`, `reset_refused_mid_pulse`, **`reset_accepted_when_safe`**, **`advance_is_one_step`**, **`phase_frame`**, **`f1d_wave_frame`** | — | well covered |
| H-K time | — | — | nothing (A-15) |
| H-L actuator obedience | — | `heat_frame`, **`heatoff_is_local`**, **`advance_units`** | command = effect (A-19) |

Change with respect to the previous revision of this document: of fifteen hazards, seven had no law at all. Now there are
**four** (H-A3, H-I, H-K, and H-H in its bypass part), and all four are declared limits of the abstraction, not
oversights. The most important of those now covered is H-A1 during heating —the hazard the real system
exists for— which previously only had "nothing new switches on".

## 4. What `traces_safe` establishes and what it does not (for the preprint, in these terms)

**It establishes**: for the discrete model of §1 of `phase3-design.md`, under hypotheses A-1…A-35, every finite
sequence of events of the alphabet, applied to the initial state, for every value of the abstract counters, produces a
state that satisfies I1–I6. It is a safety property (Alpern–Schneider) of a *specification*, with complete coverage of
the input space: no trace of any length, in any interleaving, escapes. Having many laws or many certified cells does
**not** distinguish it from a model that ignores everything: a set of safety properties is satisfied by the null
model, and an adversarial review demonstrated this against the previous version of this work, getting a degenerate
model through the laws **and** through the vacuity gate. What distinguishes it is the 26 demand and frame laws (29
with the three V1 laws), the tightness metric (how many successors the set admits: 1.01 out of 10 752 in the runs of
2026-09-22 and 2026-09-23) and the adversarial mutant bank (defects of the Python reference model, judged by the laws
re-encoded in Python and by the check that the model's invariant is the specification's: 75 of 76 in those runs;
since 2026-09-23 the gate computes that the one survivor is equivalent to the model).

**It does not establish**: (1) behaviour under hardware failure (nothing on PFD/PFH, SFF, HFT: the model assumes that the transition
function executes); (2) systematic capability of any implementation (the emitted C does not go to a PLC; the only
link is differential testing, which is testing); (3) absence of spurious stops (P10 is a frame law; the alarms are
free inputs); (4) nothing under invalid inputs (A-18); (5) nothing about time (A-15; the real numbers are in A-15);
(6) unbounded liveness (the response **bounded in ticks** is proved since blocker 5: `watchdog_responds`,
`dms_responds`; not that the pulse ends); (7) correctness of the alarm sources; (8) plant obedience (A-19); (9) independence between
layers (A-17).

Proposed wording: "For the abstract discrete model defined in §X, under hypotheses A-1…A-35 of Annex B, we prove
that every finite sequence of modelled events applied to the initial state produces a state that satisfies I1–I6, for
every value of the abstract counters, and that the watchdog and the armed DMS respond within `hb_max` and `ack_max`
ticks respectively, for every trace. It is a property of the specification, not of an implementation. It does not establish
timing, unbounded liveness, behaviour under random hardware failure, lost or malformed messages, configuration change
during the pulse, nor the correctness of the alarm sources. In IEC 61508 terms it is evidence that
contributes to a systematic capability argument for the specification and the design (61508-3, tables A.1, A.2, A.9);
it does not on its own support a SIL claim, and the modelled function is machine protection, not a nuclear safety
function."

## 5. Toolchain qualification (what is missing today and is being added)

- Bend 2.0.25 (commit `c65bcb78…`, pinned by `env/bend.sh` since 2026-09-23, the compiler of the reference run of that
  day; 2.0.24 for the serial run of 2026-09-22, 2.0.6 in the spike of 2026-09-18), run from its source checkout with
  bun (JS backend), one vendor, new and unqualified: Bend 2 was first released on 2026-09-17 (2.0.0, "a new type
  checker (an affine dependent type theory)", upstream `CHANGELOG.md`), 2.0.25 is its 26th release in five days, and
  it closed two holes in how the checker handles literals (#941, #954) that prooflock does not reach (`env/SETUP.md`).
  In 61508-3 terms an *offline* support tool of class T2 (it may fail to detect errors). Minimum evidence: pinned
  versions (`env/SETUP.md`); **mutation score** (C6) over the Python reference model, judged by the laws re-encoded in
  Python (evidence about the law set, not about the checker, which takes no part), where a surviving mutant passes
  only if the gate computes it to be equivalent on every cell it compares (the 924 672 certificate cells, 12 042 240 cells with
  concrete counter values and 1 032 192 `concretize` cells); **certificate adequacy test** (negative 8,
  `tests/jetprot_bug8_certificate_false.bend`: the certificate claimed `False` must be rejected, which shows that
  `{==}` on `check_fin` is computed, not skipped); **re-execution** of the certificate by brute force in Python (C5; a
  port of the model, not N-version diversity: `phase3-design.md` §9a H23). Cross-check in nuXmv or TLA+/Apalache:
  declared as future work (it would confirm with another tool the two response bounds of `LAWS_JETPROT_LIVE.bend`).
- `prop` (the cell predicate of `enum_jetprot.bend`) is a single point of failure for the reflected laws: hence C5 and
  C6.

## 6. Honest comparison with published practice

As published ([S3], [S1], [S2]): 71 *pulse schedules* as behavioural tests defined by the Plasma Operations Group,
unit tests, end-to-end commissioning with simulated camera signals, a live demonstration of the JTT
(pulse 80500), and an automatic post-pulse analysis that produces the ordered list of events that ended the pulse;
plus thousands of pulses of operational experience. That gives real hardware, real latencies, real sensors, real failure
modes: evidence about the *system*. What it cannot give is coverage: 7 phases × 7 triggers × order × communication
faults × watchdog × inhibits × counters exceeds 71 tests by orders of magnitude, **and the matrix changes per
pulse**: the 71 tests validate the *framework*, not the configuration of each *session leader*.

Incremental value of the model, in order: (1) exhaustive check of the discrete logic **per configuration** in
minutes, which is the problem [S3] states ("robust configuration") and where JET missed disruptions (R-15); (2) a
machine-checkable statement of what the logic must do, which today exists as prose plus a GUI; (3) a reference
oracle for differential testing (Phase 2: the deep bug was unreachable for 3 000 random traces, found
in 200 guided queries, and the proof covered it without generating anything); (4) regression against configuration changes.

It does not replace: the 71 tests, commissioning, FAT/SAT, timing analysis, hardware failure analysis or
independent assessment. And it is compared against the *published record*: CCFE surely did FMEA/HAZOP and has a
design authority that the papers do not describe; the gap being covered is not a gap in their practice. A user of
nuXmv or TLA+ would build this model in a day and get liveness for free (here the two response bounds cost
an 842-line proof by induction on the trace, which covers traces of any length, every configuration and every
counter value that satisfies the invariant; the limits themselves are checked only at the model's `hb_max` = 3 and
`ack_max` = 2, as they would be in a model checker); the choice of tool is defended by proof instead of *model
checking* (genuine universality over the counters), certificate and laws in one artefact, and a total functional
model that serves as an executable oracle; and the objection is neutralized with the cross-check of §5.

## 7. What a hostile reviewer will use, and the answer

| Attack | Prepared answer |
|---|---|
| "It is machine protection, not nuclear safety." | Said in the first paragraph; the method transfers, the instance does not; mapping to IEC 61513/61226 categories with the realistic category (B/C) and what would be missing for A. |
| "Requirements cited from a paper; 28 of 56 cells invented; without the secondary matrix." | Honest title ("reconstructed from open publications"); P11a/P11b separated; the secondary mechanism is modelled, with its content declared ours (A-16) or illustrative (A-35); questions to JET in `SUPUESTOS_EVALUACION.md`; reading by the authors of [S1]/[S2]. |
| "You proved that your program equals itself." | The laws that restate others are named (the twelve `DERIVED` of `pymodel/jetprot_laws.py`, kept as statements and not counted as independent evidence), and P5 reads the model's own `permit` (`LEYES_CATALOGO.md`, P5); the argument is made by I1–I6 + `traces_safe`, the checkable specification and the differential against an implementation written separately. |
| "The main hazard (hotspot during heating) has no law." | Rev. 3: P3, P4, I2 (`Ramping`). |
| "Without time or liveness, a brick satisfies the theorem." | §4, explicit, with what distinguishes the model from a brick. |
| "One vendor, a checker first released on 2026-09-17, JS backend, hand-written reflection ladder." | C5, pinned versions, certificate adequacy test (negative 8); C6 measures the law set, not the checker. |
| "The independent review was another instance of the same LLM." | Said in §0; human reading is being sought. |
| "The certified instance maps MHD to None: zero protection against disruptions." | It is a property of the published example table (instance 1; [S1] says Table 1 "illustrates" the matrix); instance 2 certifies our reading of the mode-lock path that [S6] and [S7] describe (R-5 note of `phase3-sources.md`); argument for configuration well-formedness laws. |
| "You folded PEWS and used one `step` for the hardwired and the software: you erased the independence." | A-5, A-17 in the abstract; I1 does not cite PEWS as a system. |
| "80 000 cells is not exhaustive verification of anything real: 16 PINIs, 5 actuators, continuous waveforms." | Hypothesis register with direction of conservatism (§4 of `phase3-sources.md`). |
| "Which ARN requirement does this satisfy?" | Suitability is claimed as a *type* of evidence, never acceptability; the regulator classifies. |
