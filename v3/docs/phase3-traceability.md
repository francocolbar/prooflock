# Phase 3 — Traceability: hazard → function → requirement → hypothesis → law → proof → negative → differential → limit

Date: 2026-09-19 (revision 2, with the law set closed). This is the table a functional safety assessor
asks for. Sources: `phase3-safety.md` (hazards H-*, requirements SR-*), `phase3-sources.md` (quotes R-*, hypotheses A-*),
`phase3-design.md` (laws). Artefacts: `LAWS_JETPROT.bend` (75 laws since 2026-09-21; there were 64), `LAWS_JETPROT_CONF.bend` (137; there were 117),
`LAWS_JETPROT_LIVE.bend` (2 bounded response theorems, b5),
`PROOF_JETPROT*.bend`, `tests/jetprot_bug1..10*.bend`, `prod/jetprot_prod.py` (6 planted defects),
`pymodel/mutants.py` (adversarial bank of 62), `recheck.py` (C2, C3, C5, C6), `run.py` (single gate).

**Naming convention.** `I1`…`I6` are clauses of the invariant `inv_fin`/`inv_all`, not law identifiers: they are
proved by the preservation laws `pres_fin`, `pres_i5`, `pres_i6` and by the theorem `traces_safe`. Everything else in
the "Law" column is the literal name of a `law` in one of the two files.

## 1. Safety requirement → law → proof → negative → differential

| SR | Requirement (shall / shall not) | Hazard | Derives from | Hypothesis | Law | Proof | Negative | Planted bug |
|---|---|---|---|---|---|---|---|---|
| SR-1 | When a PTN stop arrives by any path, every unit **shall** leave power in the same cycle | H-C, H-A1 | R-0, R-11 | A-9, A-19 | `ptn_deenergizes`; corollary `ptn_no_heat`; clause I1 | reflection over `finite_check` / `_alt`; `corollaries_check` | bug3, bug5 | `commfault_leaves_heating` |
| SR-2 | A stop **shall not** be replaced by one of lower authority during the pulse | H-G, H-J | R-0, R-7 | A-1, A-2 | `latched`; **`stop_honoured`** (two-sided); `reset_accepted`, `reset_refused` | reflection | bug1, **bug9** | `deescalation` |
| SR-3 | On an RTPS or JTT response, every unit **shall** leave full power in the same cycle and **shall not** return | H-A1 (heating) | R-3, R-4 | A-9 | `stop_reduces_power`; **`soft_stop_ramps`**; `ramping_never_returns`; clause I2 | reflection | bug2, bug7, **bug10** | `rtps_keeps_full_power` |
| SR-4 | No unit **shall** energize outside the window, without plasma, or with a stop in progress; and **shall not** change state without a command, a plasma loss, the programme, the end of pulse or a stop that changes the response | H-E, H-L | R-12 | A-5, A-8 | clause I1; `heat_permissive`; `stop_overrides_heat`; `heat_frame`; **`heaton_is_local`**; **`f4_units_frame`** (b4) | preservation; reflection | — | — |
| SR-5 | The DMS **shall not** arm or fire except with the PTN active | H-C | R-11, [S6] | A-11 | clause I4; `dms_frame`; corollary `dms_no_heat`; **`dms_fire_frame`** | preservation; reflection | bug4 | — |
| SR-6 | A stop marked for DMS that reaches the PTN **shall** arm it; the wait **shall** be bounded; a repeated alarm **shall not** restart it | H-C2 | R-11 | A-10, A-11 | `dms_armed_on_demand`; clause I5; `tack_frame`; `dms_monotone`; **`ack_timeout_fires`**, **`ack_counts`**, **`heatack_exact`**, **`tack_inc_frame`**, **`tack_reset_frame`**; **`dms_responds`** (b5: armed ⇒ fired in ≤ `ack_max` ticks without `Reset`) | reflection; `cnt_go`; induction over the trace (`PROOF_JETPROT_LIVE_CORE`) | bug6 | `repeated_alarm_restarts_ack` |
| SR-7 | `hb_max` cycles without heartbeat **shall** produce PTN | H-D | R-13 | A-12 | clause I6; **`watchdog_latches`**, **`hb_counts`**, **`hb_tick_exact`**, **`heartbeat_resets_hb`**, **`hb_frame`**; **`watchdog_responds`** (b5: `hb_max` ticks without `Heartbeat` or `Reset` ⇒ PTN, from any state of the invariant) | `cnt_go`; concrete reachability (C5); induction over the trace (`PROOF_JETPROT_LIVE_CORE`) | — | `watchdog_off_by_one` |
| SR-8 | A communication fault **shall** produce PTN from any state | H-D | R-13 | A-13 | `commfault_ptn` | reflection | bug3 | `commfault_leaves_heating` |
| SR-9 | A local alarm **shall** take its unit from full power to **partial** power (one PINI out, R-9) and nothing else; the reduction **shall** last the pulse (a reduced unit **shall not** return to full power) | H-A2 | R-8, R-9 | A-6, A-7 | `local_is_local` (b4); **`f2a_local_reduces`**, **`f2d_reduced_never_returns`** | reflection | — | `plasma_ok_restores_reduced` |
| SR-16 | A concrete alarm **shall** read Table 1 in the Level-1 programme phase; a JTT **shall** switch the waveform and **shall not** move the programme phase | H-A1, H-F | R-1, R-4, [S2] §3.4 | A-24 | **`f1a_table_reads_prog`**, **`f1b_stop_keeps_prog`**, **`f1c_wave_ahead`**, **`f1d_wave_frame`**, **`f1e_jtt_exact`**, `stop_phase_exact` (b4), `phase_frame` (b4) | by cases (F1a, F1c); reflection | — | `jtt_moves_program_phase` |
| SR-17 | A communication fault **shall** produce PTN when the instance enables the check and **shall not** do anything when it disables it; a blind alarm **shall** go through the table | H-D, H-H | R-13, [S1] p.1296 | A-13, A-21, A-25 | `commfault_ptn` (b4), **`f3b_commfault_masked_is_noop`**, `mask_inst1/2_checks_on`, `mask_inst3_checks_off`, `asm_*_Blind`, `blind_masked_no_response` | reflection; `{==}` | — | third instance in `prod/` |
| SR-18 | The DMS **shall not** arm with the plasma current below the DMV threshold, and **shall** arm on a demand above it | H-C2 | R-14, [S6] | (A-22 withdrawn) | **`ip1_low_never_arms`**, **`ip2_arms_on_demand`**, **`ip3_ip_is_input`**, **`ip4_ip_frame`**, `dms_armed_on_demand` (b4), `dms_frame` (b4) | reflection; P16 | — | `arms_below_threshold` |
| SR-10 | The response **shall not** change except by alarm, communication fault, expired watchdog or end of pulse | H-H | R-13 | A-12, A-13 | `no_spurious_stop` | reflection | — | — |
| SR-11 | The certified configuration **shall** match the published one, with the assumed cells identified, and the concrete layer **shall** use it as is | H-F | R-5 | A-4 | `pub_*` (28), `asm_*` (21), `inst2_*` (49), `dms_*` (16), `fast_ptn`, **`concretize_is_the_table`**, **`step_c_is_the_concrete_step`** | `PROOF_JETPROT_CONF` (`{==}` per cell) | — | third transcription in `prod/` |
| SR-12 | Under PTN the programme **shall not** advance; **shall not** rewind; and **shall** advance exactly one phase | H-J | R-0 | A-5 | `advance_frozen`; `phase_monotone`; **`advance_is_one_step`**, **`phase_frame`**, **`stop_phase_exact`**, **`advance_units`** | reflection | — | — |
| SR-13 | The end of pulse **shall** release the interlocks only with the pulse finished and no mitigation armed, and **shall** be accepted when those conditions hold | H-J | A-14, [S1] supervisor | A-14 | `reset_guarded`; `reset_refused_mid_pulse`; **`reset_accepted_when_safe`** (guard written literally) | reflection; rewriting | — | — |
| SR-14 | For every sequence of events, the state **shall** satisfy I1–I6 | all | all | all | `traces_safe`, `traces_safe_concrete`; `inv_init`; `pres_fin`, `pres_i5`, `pres_i6` | induction on the trace | — | the two oracles of the differential |
| SR-15 | The plasma conditions **shall** reflect their input and **shall not** change by any other path | H-E | R-12 | A-8 | **`plasma_is_input`**, **`plasma_frame`** | reflection | — | — |

In **bold**, the laws that were added after two adversarial reviews showed that the previous set
was purely negative (`phase3-design.md` §9b, H28–H29).

**Out of scope, declared**: the secondary response (R-6 → A-16); the acknowledgement as a sequence, not only as a bound
(R-11 partial → A-11); the bypass of the PTN inputs and outputs and the misconfigured windows (R-15 → A-21; the
masks of the two reliability checks are modelled since 2026-09-21); every deadline (A-15); the independence
between layers (A-17). The DMV current threshold (R-14) is no longer out of scope (A-22 withdrawn; SR-18).

## 2. Source quote → how it is used

| Quote | Class | Use | Status |
|---|---|---|---|
| R-0 | architecture | PTN at the top of the order; `to_ptn`; `ptn_deenergizes`, `advance_frozen` | covered |
| R-1 | context / data | the seven phases, as a configuration instance (A-5) | covered |
| R-2 | requirement | the seven triggers | covered; the missing columns are A-4 |
| R-3 | requirement | the three response levels; `soft_apply`, `to_ptn` | covered |
| R-4 | requirement | the JTT jumps to termination and **ramps** the heating | covered (`soft_stop_ramps`; it was finding H16) |
| R-5 | configuration data | 28 published cells + 21 assumed; the 117 conformance laws | covered (15 printed + 13 by ditto) |
| R-6 | justification | — | **out of scope** (A-3, A-16): there is no published secondary matrix |
| R-7 | requirement | escalation by maximum (A-2); the DMS wiring is configuration ([S6]) | covered as our policy |
| R-8, R-9 | requirement | `Local`, `Reduced`, `local_is_local`, `f2a_local_reduces`, `f2d_reduced_never_returns` | covered: a local alarm reduces (one PINI out) and does not switch off (A-6, A-7, revision 2026-09-21); compensation with other PINIs is not modelled |
| R-10 | architecture | interlock; guarded `Reset` | covered; the bypass **out of scope** (A-21) |
| R-11 | requirement | `arm_dms`, `HeatAck`, `ack_max`, I4, I5 and the six DMS laws | **partial**: atomicity and bound, not the acknowledgement as a sequence (A-11) |
| R-12 | requirement | `heat_win`, `plasma`, I1, `heat_permissive`, `plasma_is_input` | covered as an abstraction (A-5, A-8); PEWS is not modelled as an independent system |
| R-13 | requirement | `CommFault{dms, en}`, `Blind`, the masks, the watchdog and its five laws | covered (A-12, A-13, A-21, A-25): both checks go through the instance's mask |
| R-14 | requirement | `dms_window` (waveform phase), `ip`, IP1–IP4 | covered since 2026-09-21: the current threshold gates the arming (A-22 withdrawn) |
| R-15 | operational evidence | — | not a requirement: it is the argument for the method (certify the configuration of each pulse) |

## 3. Hypothesis → laws that depend on it

| A-n | Dependent laws | What happens if it is false |
|---|---|---|
| A-1 | `latched`, `stop_honoured`, `soft_stop_ramps`, `stop_phase_exact` | The order is a **model parameter**: every law is proved for both (`finite_check` and `finite_check_alt`). The behavioural difference is 2 688 cells, 168 reachable. |
| A-2 | `latched`, `stop_honoured` | They stop describing JET (R-6 allows suppressing escalations). |
| A-4 | `asm_*`, `fast_ptn` | 21 cells change; the laws over the abstract alphabet do not depend on it. |
| A-5 | I1, `heat_permissive`, `phase_monotone`, `advance_frozen`, `advance_is_one_step`, `advance_units` | The window and the phases are instance; recertify. |
| A-6 | `local_is_local`, `f2a_local_reduces`, `f2d_reduced_never_returns` | A reduced unit does not return to full power (conservative); compensation with other PINIs is not expressed. |
| A-7 | `f2d_reduced_never_returns` | Policy more restrictive than JET's on un-reducing, declared. |
| A-13, A-21, A-25 | `commfault_ptn`, `f3b_commfault_masked_is_noop`, `mask_*`, `asm_*_Blind`, `blind_masked_no_response` | The mask is configuration certified per instance; the `Blind` row is assumed. |
| A-24 | `f1a_table_reads_prog`, `f1b_stop_keeps_prog`, `f1c_wave_ahead`, `f1d_wave_frame`, `stop_phase_exact`, `phase_frame`, `heat_permissive`, I2, I3 | If the table were indexed by the waveform phase (the previous reading), a `Slow` after a JTT would escalate to PTN. |
| A-8 | I1, `plasma_is_input` | I1 says less than it seems (global Ip vs per-PINI density). |
| A-9 | I1, I2, `ptn_deenergizes`, `stop_reduces_power`, `ramping_never_returns`, `soft_stop_ramps`, `advance_units` | The real effect is a waveform (A-19). |
| A-10 | `dms_armed_on_demand`, `dms_frame`, `dms_fire_frame` | The instance decides which stops carry the DMS bit. |
| A-11 | I4, I5, and the acknowledgement laws | The acknowledgement as a sequence is left out. |
| A-12, A-13 | I6 and the five watchdog laws; `commfault_ptn` | Two demand paths merged into one. |
| A-14 | `reset_guarded`, `reset_refused_mid_pulse`, `reset_accepted_when_safe` | `latched` loses content. |
| A-15…A-23 | none (declared limits) | — |

## 4. Measured status (from `results.json` and `recheck.json`, gate of 2026-09-19)

| Artefact | Result |
|---|---|
| `PROOF_JETPROT.bend` | `All terms check.`, 143 s. 64 laws: reflection over the certificate, the counter lemma and the induction on the trace |
| `PROOF_JETPROT_CONF.bend` | `All terms check.`, 0.3 s. 117 conformance laws |
| Certificates `_FIN`, `_FIN_ALT`, `_COR` | 104 832 cells per order + 2 688 states; 14–19 s and 0.3 s. They are **libraries**, not gates: each one discharges a single law and only `PROOF_JETPROT.bend` can give green |
| Negatives `bug1..bug10` | 10/10 rejected, each one by refuting a `Bool` **and** citing the name of its law |
| C5 | **209 664 cells** Bend = Python; 0 discrepancies; 0 law failures on the states Bend produces; identical concrete layer; concrete reachability 921 states (`hb ≤ 2`, `tack ≤ 1`), all in `inv_all` |
| C2 | 323 reachable abstract states; no vacuous law; **tightness: 374/400 cells with a unique successor (93.5 %), 1.1 admissible successors out of 2 688**; counter commands fixed in 195/400 (1.51 of 9). Warnings below threshold: `heat_frame`, `advance_to_termination_ramps` |
| C3 | 2 688 cells differ between the two orders, 168 reachable; all laws hold in both |
| C6 | **Adversarial bank: 61/62**, sole survivor `M06`, verified equivalent (differs in 0 of 209 664 cells). Model flags: 17/17, reported as the weak measure |
| Differential | 6 planted defects × 2 instances × 2 generators; found in 14/16 configurations with a defect, 0 false positives in the 2 without a defect; the guided generator finds them all with traces of 2–10 events, the random one misses several |
| Full gate | `py -3.14 v3/run.py` → `all gates and checks ok: True`, ≈ 5–6 min |

**Declared future work**: the C4 gate (guarded `LocalClear`, the sensitivity of A-7) is not implemented; the
commanded vs. reported state of the units (to verify the R-11 acknowledgement as a sequence); the DMV current
threshold; the cross-check of the certificate in nuXmv or TLA+/Apalache.
