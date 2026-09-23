# Phase 3 — Design: JET's protection chain (RTPS + PTN) under law

Date: 2026-09-19, **revision 4**; updated 2026-09-22 for revision 4 of the hypothesis register (the named PTN and primary-stop laws and the secondary stop response: §2, §6, §9b H37); updated 2026-09-23 for the computed equivalence of surviving mutants (§5, §8, §9a H38), the parallel gate (§7, §8), R-0 as a basis of `p1a_ptn_latched` (§2), the twelve derived laws marked in §2, the `concretize` comparison of C6 `equivalence` (§5, §9a H38, H39), the generators of §4, the cell predicate of C1 named as in the code (§5), the reference run of that day (§5, §7, §8), the demand and frame laws counted (29) where §2 said "half of the laws", and H23's record of the audit's transcription, which the repository does not keep (§9a); at the close of that day, the origin of the demand and frame laws as §9b records it (§2), what the checker prints for a negative test (§3), C5's re-evaluation as the 62 cell checks of the Python oracle (§5), the table transcriptions called separate rather than independent (§2) and H23 dated to the model it ran on (§9a); then the times of §7 and §8 from the gate re-run after that day's closing code fixes (11:12–11:34), and again from the re-run of 12:01–12:22 after a last change to `env/bend.sh`; and, after a further audit, the demand and frame laws counted apart from the three V1 laws (26; 29 with V1, §2), negative 5's single witness cell (§3), F2a's R-9 quote given in full with the power reading left to A-6 (§2) and the two response theorems stated as checked for the model's limits (§2); then the times of §7 and §8 from the re-run of 12:52–13:13, after the same statement in the header comment of `v3/LAWS_JETPROT_LIVE.bend`, and IP1's basis in R-15 given as the 7 disruptions detected below the valve's minimum current (§2). Status: **implemented and closed**. The code is `v3/`; this document is the
specification of the Bend model (`jetprot.bend`) and of the Python reference model
(`pymodel/jetprot_ref.py`, which re-executes the Bend model in another language: §9a H23), and it is kept in sync with both; the findings log (§9) and the figures
labelled with a revision or a date are history (§5, §7 and §8 refreshed on 2026-09-23 from the files and `results.json`).
Five rounds of adversarial review (own + six
automated reviewers, one per perspective; not independent assessment: §9 and README §7), a sixth on fidelity (H33) and the revision-4 assumption review (H37); findings log in §9, with those that changed the law set in
§9b. Source and
hypothesis register: `phase3-sources.md` (**R-n**, **A-n**). Hazards, safety requirements and limits of the
evidence: `phase3-safety.md`. Pattern: `v2/seq3/` (finite control + commands to counters + certificate by computation +
reflection). Same standard as v2: exhaustive instantiation before proving, one prover agent per file, negative
test, single gate `py -3.14 v3/run.py` (from the repo root).

**What the model is.** The *Stop Selector* of JET's RTPS ([S1]: "the state machine and alarm processing logic") plus the
interface to the PTN and the DMS arming sequence; not the *Stop Manager* (the override waveforms). It certifies
the escalation **rule** for any configuration (primary matrix, DMS connection), and the published **instance**
by conformance.

## 1. The model (`v3/jetprot.bend`)

### Finite control `Fin`

| Field | Values | Source |
|---|---|---|
| `prog` | `Breakdown < IpRise < Limiter < Xpoint < Heating1 < Heating2 < Termination` (instance; total order by A-5): the Level-1 **programme** phase, the one that indexes Table 1 and that only `Advance` moves | R-1, R-5, A-5, A-24 |
| `jtt` | `Bool`: the JTT has already switched to the termination waveforms; the **waveform** phase is `wave = jtt ? Termination : prog` (read by the permissive, the DMV window, the end of pulse, I2/I3) | R-4, [S2] §3.4, A-24 |
| `level` | `LNone < LJtt < LRtps < LPtn` (authority/irreversibility; PTN on top by R-0, JTT/RTPS by A-1) | R-3, R-0, A-1 |
| `dms` | `DmsIdle < DmsArmed < DmsFired` | R-11, A-11 |
| `plasma_ok` | `Bool` | R-12, A-8 |
| `ip` | `Bool`: the DMV arming verdict (plasma current OR stored energy above threshold, the form of [S7]'s condition; [S6] used the current alone); gates the DMS **arming** | R-14, [S6], [S7], A-22 (redefined in revision 4) |
| `nb`, `rf` | `Unit = Off \| Ramping \| Reduced \| On` (`Reduced` = partial power: one PINI/antenna out, R-9; `Inhibited` withdrawn, A-26) | R-9, A-6, A-9, A-26 |

**10 752 states** (revision 2026-09-21; there were 2 688). `init() = Fin{Breakdown, jtt = False, LNone, DmsIdle, plasma_ok = False,
ip = False, Off, Off}`, `hb = 0`, `t_ack = 0`.

Counters (outside the control, with `CKeep/CReset/CInc` commands as in seq3): `hb` (ticks without heartbeat, limit
`hb_max = 3`, A-12) and `t_ack` (ticks waiting for the DMS acknowledgement, limit `ack_max = 2`, A-11). Verdicts: `bh = (1+hb <
hb_max)`, `bt = (1+t_ack < ack_max)`. **They enter only the `Tick` arm of `step_fin`** (the other arms do not receive them):
mechanically verified that no non-`Tick` arm depends on them or emits `CInc` (H13).

### Two layers: abstract alphabet and concrete alphabet

The configuration (which response each trigger requests in each phase, which stops arm the DMS) **is not inside
`step_fin`**: it enters as the event's payload. Thus the laws hold for **every** configuration, and the instance enters through
a concrete layer of one line per event plus the conformance laws.

**Abstract (28 variants)**: `Advance` · `Stop{req: Level, dms: Bool}` ×8 · `Local{u}` ×2 · `HeatOn{u}` ×2 ·
`HeatOff{u}` ×2 · `Plasma{ok}` ×2 · `Ip{ok}` ×2 · `CommFault{dms, en}` ×4 (`en`: the check is enabled in the
instance, A-21) · `Heartbeat` · `Tick{dms}` ×2 · `HeatAck` · `Reset`.

**Concrete (24 events)**: `Alarm{t}` with `t ∈ {Slow, Fast, Mhd, MhdB, Mchs, Dhs, BothHs, Blind}` ↦ `Stop{masked_table(i,
prog, t), dms_req(wave, t)}` when no stop is in force, and `Stop{sec_table(i, prog, t), dms_req(wave, t)}` when one is
(revision 4: the secondary stop response, [S1] R-6, A-3; both tables are read in the **programme** phase, the DMV window
in the **waveform** one; `Blind` with no response if the mask disables it); `CommFault` ↦ `CommFault{dms_on_commfault, mask(i).comm}`; `Tick` ↦
`Tick{dms_on_watchdog}`; `Ip{ok}` ↦ `Ip{ok}`; the rest, identity. `step_c(i, s, e) = step(s, concretize(i, fin(s), e))`.

**Configuration (instance 1, "published Table 1")**: `table1` = R-5 + A-4; `dms_req(p, t) = t ∈ {Fast, Mhd, MhdB} ∧
dms_window(p)`, `dms_window = p ∈ {Xpoint, Heating1, Heating2, Termination}` (R-14); `dms_on_commfault = False`;
`dms_on_watchdog = False`; `heat_win(p) = p ∈ {Heating1, Heating2}`; `mask = {comm: True, blind: True}`; `sec_table(1, p, t) = masked_table(1, p, t)`. Only the table, the mask and the secondary table vary between instances: `dms_req`, `dms_window`, `heat_win`, `dms_on_commfault` and `dms_on_watchdog` are model code, the same for every instance (A-10, A-27). **Instance
2, "MHD to the PTN"**: the same, with `table2(p, Mhd) = table2(p, MhdB) = LPtn` for `p ≥ Xpoint` (`table1` keeps `LNone`) (to exercise the DMS path that
[S6]/[S7] describe). **Instance 3, "checks disabled"**: Table 1 with `mask = {False, False}` (A-21: a communication
fault and a blind alarm do nothing; certified just like the other three). **Instance 4, "illustrative secondary"**
(revision 4): Table 1 and both checks on, as instance 1, with `sec_table(4, p, t) = LPtn` where the masked primary entry
is not `LNone`, `LNone` elsewhere (A-35: a fabricated reading of JET's documented preference, not JET's table, which is
unpublished). Instances 1–3 keep `sec_table = masked_table`, the reading of revisions 1–3.

### Shared helpers

- `deenergize(u)`: `On | Reduced | Ramping → Off`.
- `ramp(u)`: `On | Reduced → Ramping`; the rest unchanged.
- `reduce(u)`: `On → Reduced`; the rest unchanged (a local alarm takes out one PINI: partial power, R-9).
- `to_ptn(f)`: `level := LPtn`; `nb, rf := deenergize`. Used by rules 1, 7 and 8; no path to PTN goes anywhere else.
- `arm_dms(f)`: if `dms = DmsIdle` **and `ip`**: `dms := DmsArmed` and `CReset` to `t_ack`; otherwise, unchanged and `CKeep` (H6, P18, R-14).
- `soft_stop(f, req)`: `level := req`; `nb, rf := ramp`; if `req = LJtt`: `jtt := True` (the programme phase does not move, A-24).

### Rules (each one a single-`match` helper; verdicts as boolean parameters)

1. `Stop{req, d}`: if `req = LPtn` → `to_ptn`, and `arm_dms` if `d` (also if `level` was already PTN: a stop with DMS
   after a PTN by communication fault does arm). Otherwise, if `req > level` → `soft_stop(req)`. Otherwise, unchanged.
2. `Local{u}`: `u := reduce(u)`. Nothing else changes; counters `CKeep` (R-9, F2).
3. `HeatOn{u}`: accepted only if `u = Off ∧ heat_win(wave) ∧ plasma_ok ∧ level = LNone` → `On`. Otherwise, unchanged.
4. `HeatOff{u}`: `u := deenergize(u)`.
5. `Plasma{ok}`: `plasma_ok := ok`; if `¬ok`, units `deenergize`. 5b. `Ip{ok}`: `ip := ok` (R-14).
6. `Advance`: if `level = LPtn` or `phase = Termination`: identity (no re-ramp). Otherwise, next phase; on entering
   `Termination`, units `ramp` (the natural end of the programme brings the heating down); on entering a phase `p` with
   `¬heat_win(p)`, both units `deenergize` (the window has closed; A-29). With the fixed window (A-27) only the first case occurs. Under a soft stop `Advance` still moves `prog` (A-30).
7. `CommFault{d, en}`: if `en`: `to_ptn` and `arm_dms` if `d`; otherwise, identity, counters `CKeep` (A-13, A-21, F3).
8. `Tick{d}`: **first** the watchdog: if `¬bh ∧ level ≠ LPtn` → `to_ptn`, `arm_dms` if `d`; **otherwise**, the acknowledgement
   timeout: if `dms = DmsArmed ∧ ¬bt` → `DmsFired`. The two clauses are mutually exclusive (A5 of the review: they only
   overlap in states that violate I4).
9. `Heartbeat`: `CReset` to `hb`.
10. `HeatAck`: if `dms = DmsArmed` → `DmsFired`.
11. `Reset`: accepted only if `(level = LPtn ∨ wave = Termination) ∧ dms ≠ DmsArmed` → `init()`, counters `CReset`
    (A-14). Otherwise: control **and counters** unchanged (`CKeep`).

Commands to the counters: `hb`: `CInc` on `Tick` while `bh ∧ level ≠ LPtn` (level of the previous state), `CReset` on
`Heartbeat` and accepted `Reset`, `CKeep` otherwise; `t_ack`: `CReset` only when `arm_dms` **transitions** from
`Idle`, `CInc` on `Tick` if `DmsArmed ∧ bt`, `CReset` on accepted `Reset`, `CKeep` otherwise.

## 2. The laws (`LAWS_JETPROT.bend`, 81 + `LAWS_JETPROT_CONF.bend`, 143)

*Revision 2026-09-21 (blocker 4): 64 → 75 laws (P8 and E1 were withdrawn with `Inhibited`; F1a–F1e, F2a, F2d, F3b, F4,
IP1–IP4 came in; see the table at the end of this section) and 117 → 137 conformance laws (the `Blind` row, instance 3 and the masks).
The rows marked “(b4)” changed their statement.*
*Revision 4 of the register (2026-09-22): 75 → 81 laws (the five named PTN and primary-stop laws and `inst4_second_alarm_ptn`) and
137 → 143 conformance laws (instance 4 and the secondary tables); see "Named PTN and primary-stop laws and the secondary
response" below. No existing statement changed except `f1a_table_reads_prog`, whose expected request now depends on whether a
stop is in force (identical to before for instances 1–3).*

Phase 2 format: statement, intent, limits. Notation: `s2 = step(s, e)`; `u2` the unit `u` in `s2`. The universal laws
over `Ord × Fin × Ev × Bool × Bool` are proved by reflection over the certificate; the counter laws with the generic
lemma `cnt_go`; `traces_safe` by induction on the trace. Twelve laws are **derived** (implied by other laws; marked in
the tables below: P4, P6, D3, D5, D9, D10, F1b, F2a, P1a, P1b, D1a, D1b): the canonical list is `DERIVED` in
`pymodel/jetprot_laws.py`, which no gate reads, and a derived law is not counted as independent evidence.

**The rule that has already cost three findings (H3, H12, and again in round 2).** *Preservation* laws carry
`inv(s)` as a hypothesis and in an unreachable state they are trivially true. *Step* laws do not carry it: **they must
hold in unreachable states too**, because the certificate decides them over the whole domain. A step law of the
form "X(s2) implies Y(s2)" is suspect: almost always what is wanted is "not X(s) and X(s2) implies Y(s2)".

**And the rule that cost the whole of round 2.** A law set can be entirely *negative*: saying what cannot happen and
never what has to happen. That set is satisfied by the model that does nothing. The 18 demand and frame laws D1–D18
exist because an adversarial review built that model and made it pass (§9b H28); a second adversarial pass, aimed at
their seams, added E2–E8 and E11, and the three V1 laws (H29): 26 demand and frame laws, 29 with V1.

### State invariant `inv_all = I1 ∧ I2 ∧ I3 ∧ I4 ∧ I5 ∧ I6`, preserved by every step (theorem T)

| # | Law | Statement | Intent | Limits |
|---|---|---|---|---|
| I0 | `inv_init` | `inv_all(init())` | The initial state is safe. | — |
| I1 | `full_power_window` | `u ∈ {On, Reduced}` implies enable window (waveform phase), `plasma_ok` and `level = LNone` (b4) | A unit delivering power, full or partial, is inside the window, with plasma conditions and with no stop in progress. | The window is the abstraction of PEWS folded into the sequencer (A-5, A-27): fixed in the model and shared by both units, not the real per-PINI, per-pulse window. |
| I2 | `ramping_context` | `u = Ramping` implies `plasma_ok`, `level ≠ LPtn`, and soft stop or termination | Ramping only happens under a soft stop or in the natural termination, never under PTN. | It does not say how far it comes down nor in how long (A-15, A-19). |
| I3 | `jtt_in_termination` | `level = LJtt` implies `wave = Termination` (b4) | A JTT in progress implies that the termination waveforms are running. | A single cell of the matrix produces JTT; C2 reports it. |
| I4 | `dms_only_under_ptn` | `dms ≠ DmsIdle` implies `level = LPtn` | The DMS only arms or fires with the PTN active, and by I1/I2 with no unit at power. | State predicate: arming and de-energizing are the same atomic step; it does **not** verify the acknowledgement as a sequence (A-11). |
| I5 | `ack_bounded` | `dms = DmsArmed` implies `t_ack < ack_max` | The wait for the acknowledgement is bounded in ticks. | It does not say that it fires (liveness) nor how long it takes. |
| I6 | `watchdog_bounded` | `level ≠ LPtn` implies `hb < hb_max` | A mute RTPS does not leave the machine unprotected. | It does not cover faults of the PTN itself (A-17). |

**Proved corollaries** (what a safety review reads): `ptn_no_heat`, `dms_no_heat`, `stop_no_full_power`,
`termination_no_full_power`. **Safe state**: PTN latched, no unit at power, no mitigation left halfway.

### Step laws: what cannot happen (P1–P21)

| # | Law | What it guarantees |
|---|---|---|
| P1 | `latched` | Stops never degrade. |
| P2 | `ptn_deenergizes` | **The step that reaches the PTN de-energizes**, by any path. Headline law. |
| P3 | `stop_reduces_power` | The step that initiates a soft stop takes every unit out of power, full or partial (b4). |
| P4 | `ramping_never_returns` | A ramping unit does not deliver power again in the pulse (b4). *(Derived: implied by P5 and P7.)* |
| P5 | `heat_permissive` | The switch-on permissive: only from `Off`, in window, with plasma and with no stop. |
| P6 | `stop_overrides_heat` | With a stop in progress no unit acquires power (b4). *(Derived: P5 and P7.)* |
| P7 | `heat_frame` | No unit acquires power without its command (b4). |
| ~~P8~~ | ~~`inhibit_latched`~~ | Withdrawn with `Inhibited` (A-26): no pulse event produced it; it would have been left vacuous. |
| P9 | `local_is_local` | A local alarm **reduces** its unit (`On → Reduced`, the rest unchanged) and touches nothing else, counters included (b4; F2b). |
| P10 | `no_spurious_stop` | The level only changes by alarm, communication fault, end of pulse or expired watchdog. |
| P12 | `commfault_ptn` | Losing communication is a stop, from any state, **when the check is enabled** (b4; F3a). |
| P14, P15 | `phase_monotone`, `dms_monotone` | Neither the programme phase nor the waveform phase rewinds (b4); the DMS does not disarm nor "un-fire". |
| P16, P17 | `dms_armed_on_demand`, `dms_frame` | The DMS arms when a marked stop reaches the PTN with the DMV arming verdict (current OR stored energy above threshold, A-22), **and only then** (b4). |
| P18 | `tack_frame` | A repeated alarm does not restart the acknowledgement wait. |
| P19 | `advance_frozen` | Under PTN the programme does not advance. |
| P20, P21 | `reset_guarded`, `reset_refused_mid_pulse` | The end of pulse is accepted only with the pulse finished and no mitigation armed. *(P20 is expressed with the model's own guard and therefore does not detect a wrong guard; P21 and D10 write it literally. See §9b.)* |
| T | `traces_safe`, `traces_safe_concrete` | **The theorem**: no sequence of events, over the abstract alphabet (any configuration) or the concrete one (every instance, Inst1..Inst4), takes the system out of I1–I6. |

### Demand and frame laws: what **has** to happen (D1–D18, E2–E11, V1)

Without these, the whole set is satisfied by a model that ignores almost everything. Each one was born from a mutant that survived.

| # | Law | What it demands | Mutant that motivated it |
|---|---|---|---|
| D1 | `stop_honoured` | The level becomes the maximum of the current one and the requested one: **a stop request is honoured**. Two-sided, where P1 was one-sided. | a PTN stop ignored if not wired to the DMS: it turned almost all of Table 1 into a no-op |
| D2 | `soft_stop_ramps` | An accepted soft stop puts every unit delivering power, full or partial, into ramping (R-4; b4). | the soft stop that **trips** instead of ramping |
| D3 | `advance_to_termination_ramps` | The natural end of the programme also ramps. *(Derived from E4.)* | — |
| D4 | `watchdog_latches` | The watchdog latches the PTN **regardless** of whether the instance wires it to the DMS. | the watchdog that only acts if wired |
| D5 | `hb_counts` | The heartbeat counter runs while the PTN is not latched. *(Derived from E6.)* | — |
| D6 | `hb_frame` | Only a heartbeat or an accepted end of pulse reset the watchdog. | any event resetting the watchdog |
| D7, D8 | `ack_timeout_fires`, `ack_counts` | The timeout fires the DMS and the wait counts. | the DMS that never fires |
| D9 | `heatack_fires` | The plant's acknowledgement fires the DMS. *(Derived from E11.)* | the ignored acknowledgement |
| D10 | `reset_accepted_when_safe` | The end of pulse **is accepted** with the pulse finished and no mitigation armed, **with the guard written literally**. *(Pointwise implied by P20; its job is to break P20's self-reference.)* | a reset guard that also refuses with the DMS fired |
| D11 | `advance_is_one_step` | The programme advances exactly one phase. | the advance that skips two |
| D12 | `phase_frame` | Nothing but `Advance` or `Reset` moves the **programme** phase (b4; the JTT moves the waveform one: F1d). | an RTPS stop that jumps to termination |
| D13, D14 | `plasma_is_input`, `plasma_frame` | The plasma conditions are an input, and only that input moves them. | the plasma loss that does not lower the flag |
| D15–D18 | `heatoff_is_local`, `heaton_is_local`, `heatack_frame`, `heartbeat_frame` | Each command touches its own and nothing else. | `HeatOff` that switches off both units |
| ~~E1~~ | ~~`inhibit_source`~~ | Withdrawn with `Inhibited` (A-26). The mutant that motivated it (the plasma loss that *latched* the units) is today N08, "the plasma loss leaves the units at partial power", and I1 catches it. |
| E2 | `dms_fire_frame` | The DMS fires only by the acknowledgement or by the timeout. | — |
| E3 | `stop_phase_exact` | A stop moves the **waveform** phase to Termination exactly when an accepted JTT requests it (b4). | — |
| E4 | `advance_units` | The units after an `Advance` are completely determined, in all six transitions and not in one. | the advance to a phase without window that does not close the heating |
| E5 | `heartbeat_resets_hb` | **A heartbeat always restarts the watchdog counter.** | the heartbeat ignored under PTN: nothing required it, D18 framed the control and the other counter, and D6 only *allowed* it |
| E6 | `hb_tick_exact` | The watchdog counter on a `Tick` is exactly determined. | the counter that runs past its limit without any law seeing it |
| E7, E8 | `tack_inc_frame`, `tack_reset_frame` | Only what should does increment or restart the acknowledgement wait. | — |
| E11 | `heatack_exact` | The acknowledgement is two-sided. | — |
| V1 | `verdict_frame_step/_hb/_tack` | **Outside the `Tick` arm nothing reads the counter verdicts.** It turns into a theorem the assumption that legitimizes the certificate checking 23 of its 28 columns with a single pair of verdicts. | two mutants that lived entirely in the unexamined verdict corners |

### Fidelity laws (blocker 4, 2026-09-21: F1–F3, IP)

They were born from the fidelity audit against [S1]/[S2]/[S6] (`docs/improvements-2026-09-21/00-summary.md`): three points where the model
said the opposite of the source, plus the DMV threshold. F1b, F1d, F2a, F2d, F3b, IP1, IP3, IP4 are cell laws
(group `g_f` of the certificate); F1a, F1c and IP2 are proved directly.

| # | Law | What it demands | Where it comes from |
|---|---|---|---|
| F1a | `f1a_table_reads_prog` | A concrete alarm reads Table 1 in the **programme** phase, whatever `jtt` and the rest of the state; against the separate transcription of the matrix and the enumerator's masks. Since revision 4 the expected request is the primary entry with no stop in force and the enumerator's own secondary entry (`m_sec`) otherwise; for instances 1–3 this is the same statement as before. Which phase is read is our reading (A-24, A-30). | [S2] §3.4 "two views of time": the JTT relabelled the single phase and a later `Slow` read the Termination row (unpublished PTN) |
| F1b | `f1b_stop_keeps_prog` | A stop never moves the programme phase. *(Derived: the `Stop` case of D12.)* | idem |
| F1c | `f1c_wave_ahead` | `wave ≥ prog` always (I7; by construction of `wave`). | idem |
| F1d | `f1d_wave_frame` | The waveform phase only moves with `Advance`, an accepted JTT or the end of pulse. | idem |
| F1e | `f1e_jtt_exact` | The waveform flag is exactly determined: an accepted JTT sets it, the end of pulse clears it, nothing else touches it. | the tightness metric: with `prog = Termination`, two states differing only in `jtt` are bisimilar and nothing fixed the flag (H36) |
| F2a | `f2a_local_reduces` | A local alarm takes a unit at full power to `Reduced` (one PINI out), never to off; partial power without compensation is A-6. *(Derived: the reduction half of P9.)* | R-9: "the relevant PINI should be turned off [...] This should not preclude the neutral-beam system as a whole from continuing to deliver the total requested power to the plasma, as other PINIs can be turned on to compensate" |
| F2d | `f2d_reduced_never_returns` | A unit at partial power does not return to full power in one step (a one-step law: through `Off` the reduction is forgotten, A-34). | without it, a `Plasma{True}` that restored `On` passed all the laws (found while validating the new set in Python) |
| F4 | `f4_units_frame` | If the response level does not change and the event is not a unit command, plasma loss, `Advance`, `Reset`, PTN stop or enabled communication fault, both units stay as they were. | the tightness metric: on `Ip` or `Plasma{True}` no law framed the units (previously P8 and the four values of `Heat` did) (H36) |
| F3b | `f3b_commfault_masked_is_noop` | A communication fault whose check the instance disables is the identity, counters included. | R-13 "*can* trigger the PTN", "features [...] not in use cannot cause problems"; [S6] the 5 disruptions missed due to inhibits |
| IP1 | `ip1_low_never_arms` | Without the DMV arming verdict (current OR stored energy above threshold, A-22) the DMS does not arm, with any event. | R-14; R-15 (7 disruptions detected below the valve's minimum current) |
| IP2 | `ip2_arms_on_demand` | With the DMV arming verdict (current OR stored energy above threshold, A-22), DMS idle and a concrete alarm that the instance maps to PTN and wires to the DMS inside the window, the alarm arms in the same step (concrete form of P16). | R-14, [S6] |
| IP3, IP4 | `ip3_ip_is_input`, `ip4_ip_frame` | The DMV arming verdict (current OR stored energy above threshold, A-22) is an input and only that input (or the end of pulse) moves it. | as D13/D14 for the plasma |

### Named PTN and primary-stop laws and the secondary response (revision 4 of the register, 2026-09-22)

P1 and D1 mix what JET documents about the PTN with our policy between the two soft levels (A-1, A-2, A-16). The
five laws below state the parts about the PTN and the primary stop on their own, so they can be cited without the
soft-over-soft policy. P1a and D1b restate JET sources; D1a, P1b and PIW-after-PTN also carry our formalisation, declared
in the last column (the same-step switch-off of D1a is A-9; the soft half of P1b and the no-op, counters included, of
PIW-after-PTN rest on A-14); they are cell laws
(group `g_j` of the certificate). Four are **derived** (named cases of P1, D1, P2 and the frame laws; D1a from a
latched PTN only on states that satisfy the invariant); `piw_after_ptn_is_noop` is derived for the control state but
not for the counters, and raised the counter-command tightness from 212 to 243 of 400. [N1]'s cap, "a maximum of two
in sequence" (PDF p.13; our reading: two PIW, i.e. soft, stops), is **not** a law: with two soft levels and a strict
order it holds by construction (A-2).

| # | Law | What it demands | Where it comes from |
|---|---|---|---|
| P1a | `p1a_ptn_latched` | A latched PTN stays latched until the end of pulse. | R-0: "The PTN output is a latched stop signal"; [N1] PDF p.14: "a PIW stop can never preempt a PTN stop" |
| P1b | `p1b_stop_never_cleared` | A stop in force (JTT, RTPS or PTN) never returns to `LNone` except by the end of pulse. | mixed: R-0 for the PTN latch; for soft stops our reading (A-14): no source publishes a way to cancel a stop, and [S1] presents stops as the way to end the pulse (R-8). R-6 ("allowing it to run to completion") is about not switching to a secondary |
| D1a | `d1a_ptn_honoured` | A PTN request is honoured from any state, a soft stop in progress included, and leaves both units unpowered. | mixed: [N1] PDF p.13: PTN stops "can be triggered even after a PIW stop is in execution"; same-step switch-off: A-9 (R-0, R-11) |
| D1b | `d1b_primary_honoured` | With no stop in force, a soft request becomes the response, under either order. | R-5; [N1] PDF p.13: "RTPS will select the stop and send it to SC" |
| — | `piw_after_ptn_is_noop` | A non-PTN request while the PTN is latched changes nothing, both counter commands included. | mixed: [N1] PDF p.13 calls a PIW request "after a PTN stop was already being executed" an "invalid task" in the acceptance tests of the shape-controller simulator; that it leaves the whole state and both counter commands unchanged is our formalisation (A-14) |
| — | `inst4_second_alarm_ptn` | In instance 4, an alarm during a soft stop whose primary entry is not `LNone` latches the PTN in the same step (the A-16 case gives PTN). | mechanism [S1] R-6; content fabricated (A-35) |

Conformance (`LAWS_JETPROT_CONF.bend`): `inst4_table` and `inst4_mask` (instance 4 = instance 1 cell by cell, both
checks on); `sec_legacy` (instances 1–3: secondary = masked primary); `sec_inst4` (instance 4 against the enumerator's
independent `m_sec`); `sec_monotone` (no secondary entry is less urgent than the primary one, both orders);
`sec_primary_ptn` (a PTN primary stays a PTN; [N1] PDF p.14: "any primary PTN stop can never be followed by a PIW
secondary"). What these add, stated honestly: the abstract theorem T already held for **any** `Stop` event, so
"safety holds under both readings" is nearly automatic; what is new is the documented mechanism under conformance laws,
a certified concrete demand in instance 4, and the secondary content as an explicit, declared parameter instead of
being hidden in D1's maximum.

### Bounded response laws over traces (blocker 5, 2026-09-21: `LAWS_JETPROT_LIVE.bend`, 2)

Everything above says what does not happen (`traces_safe`) or what a step does. These two say that protection **arrives**, for
every trace, every configuration and every counter value, and they are checked for the model's limits, `hb_max` = 3
and `ack_max` = 2: the induction only compares the limits with tick counts and counters, so the argument should carry
over to other limits, but no checked statement quantifies over them. They are proved in `PROOF_JETPROT_LIVE_CORE.bend`
by induction over the trace from eight cell facts (`step_safe`, P1, D4, D7, D8, P15, P18, E11) taken as template
hypotheses; `PROOF_JETPROT_LIVE.bend` instantiates them with the laws of `LAWS_JETPROT.bend` (via
`PROOF_JETPROT.bend`) and is the gate. This is not infinite liveness (Bend has no ◇): it is an invariant over traces
of bounded length, which is what a response requirement asks for.

| # | Law | What it demands | Where it comes from |
|---|---|---|---|
| L1 | `watchdog_responds` | From any state satisfying `inv_all`, every trace without `Heartbeat` or `Reset` with at least `hb_max` ticks ends with the PTN latched. | R-13, A-12 (SR-7); inductive claim `ptn ∨ hb_max ≤ ticks(rest) + hb` |
| L2 | `dms_responds` | From any state satisfying `inv_all` with the DMS armed, every trace without `Reset` with at least `ack_max` ticks ends with the DMS fired (by acknowledgement or by timeout). | R-11, A-10, A-11 (SR-6); inductive claim `fired ∨ (armed ∧ ack_max ≤ ticks(rest) + tack)` |

### Configuration conformance (`LAWS_JETPROT_CONF.bend`, 143)

The 28 published cells of Table 1 (15 printed + 13 by ditto mark) and the 21 assumed by A-4, separately; the
`Blind` row (A-25, 14 laws); instance 2; instance 3 and the masks (`inst3_uses_table1`, `mask_inst*`,
`blind_masked_no_response`); the DMS wiring; `fast_ptn` (every instance; under a stop, through the secondary table);
instance 4 and the secondary tables (six laws, revision 4, above); and two laws about the concrete layer:

- `concretize_is_the_table`: `concretize` is the configuration **value by value**, against a literal transcription of
  the matrix as its own constants (since revision 4 over 4 instances × 7 phases × 2 × 4 levels in force × 24 events =
  5 376 cells: the level selects the primary or the secondary table). The first version of this law was **self-referential** — it compared `concretize`
  against an expectation built with the same `table()` — so it detected a miswired column but not a
  wrong value nor a shifted window.
- `step_c_is_the_concrete_step`: `step_c` uses the instance it is given, the declared urgency order and **the phase
  prior to the transition**. In Bend it turns out definitional (one line with `{==}`) because it is the definition; in the
  Python reference model **it is not**, and that is where the three mutants that motivated it live: always reading the matrix of
  instance 1 (silently disables instance 2's reason to exist), reading it in the next phase, or running the
  step under the other urgency order. None of the three changes the reachable set, so the trace theorem
  is blind to all three.

Laws that are **stated and not proved** (declared limits): the correctness of the alarms (VTM/WALLS); the timing and
the shapes of the ramps; the plant that acknowledges; independence and diversity between the layers (A-17); invalid inputs
(A-18); the **content** of JET's secondary table (R-6, A-16; the mechanism is modelled since revision 4, A-3, A-35) and the freeze of the stop configuration at the primary stop (A-24, A-30); the bypass of the PTN inputs and outputs and the misconfigured window (A-21;
the masks of the two reliability checks are modelled). The DMV enabling condition ceased to be a limit
(A-22, IP1–IP4; since revision 4 of the register it is read as current OR stored energy above threshold).

## 3. Negative tests (`tests/jetprot_bug*.bend`, the checker must reject them)

Each one plants a defect or states a false law and the gate requires the checker to reject it **by refuting a `Bool`**
(not by a type error, which would print the same words) **and** citing the name of the file's law. Eleven evaluate a
predicate at a witness cell written into the test (ten on a buggy variant of the step, negative 5 a false law on the
correct model) and negative 8 states the certificate false; what the checker prints is that refuted `Bool` with the
law's name (`expected`/`observed`), a failing instance the test supplies, not a counterexample found by a search.

| # | File | What it plants | Law that catches it |
|---|---|---|---|
| 1 | `bug1_deescalation` | a soft request replaces the response without comparing urgency | P1 `latched` |
| 2 | `bug2_jtt_no_ramp` | the JTT moves the phase to Termination without taking the units out of full power | preservation of I1 |
| 3 | `bug3_commfault_no_deenergize` | the communication fault latches the PTN without de-energizing | P2 `ptn_deenergizes` |
| 4 | `bug4_dms_without_ptn` | a soft stop arms the DMS | preservation of I4 |
| 5 | `bug5_law_p2_unconditional` | **a false law over the correct model**: P2 without its "arrival" condition | the checker itself, at one spurious witness cell (level already PTN, a unit On, `Heartbeat`); H12 counted 11 592 such cells in the model of that time |
| 6 | `bug6_rearm_restarts_ack` | a repeated alarm restarts the acknowledgement wait | P18 `tack_frame` |
| 7 | `bug7_rtps_keeps_full_power` | an RTPS stop with no effect on the heating | P3 `stop_reduces_power` |
| 8 | `bug8_certificate_false` | **the certificate asserted false**: forces the checker to evaluate it (38 s) | shows that `{==}` is computed, not skipped |
| 9 | `bug9_stop_is_noop` | a stop that reaches the PTN is ignored if the instance does not wire it to the DMS (mutant M26 of the adversarial bank) | D1 `stop_honoured` |
| 10 | `bug10_soft_stop_trips` | a soft stop **trips** the heating instead of ramping it (mutant M04; infidelity to R-4) | D2 `soft_stop_ramps` |
| 11 | `bug11_piw_overrides_ptn` | a PIW (soft) request overrides a latched PTN (revision 4) | `piw_after_ptn_is_noop` |
| 12 | `bug12_secondary_ignored` | `concretize` ignores instance 4's secondary table: a second `Slow` during an RTPS stop in Heating 1 is not a PTN (revision 4) | `inst4_second_alarm_ptn` |

Negatives 1–4 and 6–7 are also regressions of defects this project really had (§9 H2, H6, H15, H16).

## 4. Differential testing (`v3/prod/jetprot_prod.py`, `v3/bridge.mjs`)

Python implementation written from `phase3-sources.md` (not from the `.bend`), with planted bugs of the kind that survives
a review. Since revision 4 there are nine: `deescalation` (P1), `commfault_leaves_heating` (P2), `rtps_keeps_full_power`
(P3), `plasma_ok_restores_reduced` (F2d), `watchdog_off_by_one` (I6), `repeated_alarm_restarts_ack` (P18),
`jtt_moves_program_phase` (F1), `arms_below_threshold` (IP1) and `secondary_ignored_during_stop` (instance 4). Five
defect × instance pairs are unobservable by construction and declared by the gate: the communication-fault defect in
instance 3 (check masked), `secondary_ignored_during_stop` in instances 1–3 (their secondary is the primary) and
`deescalation` in instance 4 (under a stop every alarm asks for PTN or nothing). Two oracles (trajectory and Bend invariants
over foreign states), two generators (random, and guided: a prefix of the happy path `HAPPY` of `run.py`,
`Plasma{True}`, `Ip{True}`, `Advance`×4, `HeatOn{Nb}`, `Heartbeat`, `Tick`, `HeatOn{Rf}`, `Advance`, followed by up to
30 random events), Hypothesis with shrinking to the minimal counterexample. Same as `v2/seq/run.py`.

## 5. Method gates

| # | Gate | What it decides |
|---|---|---|
| C1 | `finite_check` / `finite_check_alt` | The certificate by computation: `prop` (`enum_jetprot.bend`) over the whole abstract domain, **10 752 states × 43 columns = 462 336 cells per urgency order**, both orders (revision 2: 2 688 × 39 = 104 832). Each cell computes `step_fin` once and evaluates on that result the preservation of the invariant, the shapes of the two counters and the 59 cell laws (the `pr_*` predicates of `spec_jetprot.bend`, in the groups of `enum_jetprot.bend`: P, D, E, the fidelity group and the five named PTN and primary-stop laws; 48 step laws in revision 2). The verdicts are enumerated in the 5 columns where the checker cannot discard them symbolically (the two `Tick`, `Reset`, `CommFault{True, True}`, `Stop{LPtn,True}`); that the other 23 do not read them ceased to be an assumption and is the law `verdict_frame` (V1). |
| C2 | `vacuity` and **tightness** | Per law: certificate cells and reachable states where the hypothesis holds; fails at zero and warns below threshold. And the measure that replaced one that was **zero by construction**: over a sample of 400 reachable cells with a fixed seed, in how many the law set **fixes the next state uniquely** among the 10 752 possible ones (2 688 before blocker 4), and likewise for the 9 pairs of counter commands. A law set that admits many successors proves little, however many laws it has. |
| C3 | `sensitivity` (A-1) | The urgency order between the two soft responses is a **model parameter**, not a constant: every abstract law is proved for both orders (`finite_check` and `finite_check_alt`), and the gate reports the behavioural difference. The concrete layer and the configuration are certified under the chosen order, `Ord1`, only (A-1, A-32). |
| C5 | `recheck` | A re-execution in another language, not an independent implementation (H23): all the certificate cells computed by Bend (via `bridge.mjs`) compared against the Python model, and each of the Python oracle's 62 cell checks (`LAWS` in `pymodel/jetprot_laws.py`) re-evaluated in Python **on the next state that Bend produced**; plus the concrete layer and the concrete reachability `(Fin, hb, tack)`. |
| C6 | `mutation_score` | The **adversarial bank** (`pymodel/mutants.py`; 62 defects when this gate was designed, 76 since revision 4: 62 by two separate automated reviews (§9) whose brief was to break the law set, 11 on the constants and the oracle, 3 on the secondary table), plus the 17 flags that were written alongside the laws. The second number is the weak measure and is reported as such: a bank chosen to fit the laws always scores well. **A mutant that survives passes only if it is computed to be equivalent** (since 2026-09-23, H38): its `step_fin`, `upd_hb` and `upd_tack` must equal the model's on all 924 672 certificate cells (both orders × 10 752 states × 43 columns), its step with the counters (`step_st`) on 12 042 240 cells with concrete counter values (both orders × 10 752 states × `hb` 0–4 × `t_ack` 0–3 × 28 events), and its `concretize` on 1 032 192 cells (4 instances × 10 752 control states × 24 plant events; H39); the counts go to `C6.equivalence`, and a single differing cell, or a survivor without that comparison, fails the gate. In the bank of 76 the only survivor is M06, with 0 differing cells in all three. |

The three certificates (`PROOF_JETPROT_FIN`, `_FIN_ALT`, `_COR`) are **libraries, not gates**: each one discharges a
single law of the file and by construction reports "TODOs" if run on its own. `PROOF_JETPROT.bend` imports them and supplies
the rest. Since blocker 5 the gate is `PROOF_JETPROT_LIVE.bend`, which imports `PROOF_JETPROT.bend` (and with it the
certificates) and fills the two laws of `LAWS_JETPROT_LIVE.bend`; `PROOF_JETPROT_LIVE_CORE.bend` is another library
(it reports exactly 2 TODOs on its own, without certificate, in seconds).

## 6. Certified instances

| Instance | `table1` | `dms_req` | What for |
|---|---|---|---|
| 1 "published Table 1" | R-5 + A-4 | `Fast, Mhd, MhdB` × window `Xpoint..Termination` | conformance P11; the DMS only arms by `Fast` (assumed cell): C2 says so |
| 2 "MHD to the PTN" | idem, with `Mhd, MhdB → LPtn` for `prog ≥ Xpoint` | idem | our reading of the mode-lock protection that [S6] and [S7] describe (R-5 note of `phase3-sources.md`): the DMS arms by a cell motivated by a published source, but the cells themselves are ours (`inst2_*`, ASSUMPTION) |
| 3 "checks disabled" (2026-09-21) | = instance 1, `mask = {comm: False, blind: False}` | idem | the A-21 configuration: a communication fault and a blind alarm do nothing, and the rest remains certified |
| 4 "illustrative secondary" (2026-09-22) | = instance 1; `sec_table` = PTN wherever the primary entry is not None | idem | the secondary mechanism of [S1] R-6 with a fabricated content (A-35): the A-16 case gives PTN (`inst4_second_alarm_ptn`); 744 reachable concrete states against 804 in instances 1–3 |

Instances 1–3 have `sec_table = masked_table` (the reading of revisions 1–3). The step, demand, frame and fidelity laws
are proved once over the abstract alphabet and hold for the four instances; only conformance (P11/P13, C1, `mask_*`) and C2 are run per instance. Configuration record per instance: hash of the model, of the matrices,
of the laws, checker version, gate output, date (A-23).

## 7. Test plan

*The plan below is as designed in revision 2 (2026-09-19). What was built differs in three places: conformance is one
file, `PROOF_JETPROT_CONF.bend`; there is no `PROOF_JETPROT_FIN_LC`, and the C4 gate is declared future work
(`phase3-traceability.md` §4); and since blocker 5 the gate file is `PROOF_JETPROT_LIVE.bend`, which imports
`PROOF_JETPROT.bend` (§5). The sizes, line counts and times after the plan are current (2026-09-23) unless labelled.*

```
PROOF_JETPROT_FIN (C1, {==})  ──> PROOF_JETPROT (reflection: I1-I4, P1-P19; counters: I5, I6; I0, P20, P21)
PROOF_JETPROT_CONF_1/2 (P11 per instance, {==} per cell)
tests/laws_jetprot_smoke.bend  (exhaustive instantiation at runtime + C2, BEFORE proving)
tests/jetprot_bug_*.bend       (negatives, §3)
PROOF_JETPROT_FIN_ALT (C3), PROOF_JETPROT_FIN_LC (C4)
recheck.py (C5), mutants.py (C6)
```
One bend-prover agent for `PROOF_JETPROT.bend` (seq3 ladder: one level per `Fin` field and per event
constructor; the 22 non-`Tick` arms close by reduction). Checker budget estimated in revision 2: C1 ≈ 90 s,
re-evaluated in every file that imports it: total gate 6–8 min plus C3/C4 (measured today: below).

### Size and cost

| | States | Columns | Cells per order | Full product |
|---|---|---|---|---|
| Certificate (`check_fin`), up to 2026-09-21 | 2 688 | 39 | **104 832** | 2 688 × 24 × 4 = 258 048 |
| Certificate (`check_fin`), blocker 4 | 10 752 | 43 | **462 336** | 10 752 × 28 × 4 = 1 204 224 |
| Phase 2b (reference) | 448 | 18 × 4 | 32 256 | — |

The verdicts are enumerated in 5 of the 28 columns (the two `Tick`, `Reset`, `CommFault{True, True}`,
`Stop{LPtn,True}`), exactly those where `reset_if` or `arms_now` get stuck on a symbolic `Fin`; that the
other 23 do not read them is law V1. Timings of the revision: see `docs/STATUS_2026-09-21.md` §4.4.

| Artefact | Lines of code (2026-09-23) | |
|---|---|---|
| `jetprot.bend` | 1 156 | the model (concrete layer and instances included) |
| `spec_jetprot.bend` | 746 | the Bool cell predicates `pr_*` of the 59 cell laws and the equality predicates |
| `enum_jetprot.bend` | 768 | certificate, quantifier ladder, concrete-layer check and independent transcriptions |
| `LAWS_JETPROT.bend` + `LAWS_JETPROT_CONF.bend` | 801 + 499 | 81 + 143 laws |
| `PROOF_JETPROT.bend` + `PROOF_JETPROT_CONF.bend` | 3 250 + 4 951 | reflection, induction and conformance |
| `LAWS_JETPROT_LIVE.bend` + `PROOF_JETPROT_LIVE_CORE.bend` + `PROOF_JETPROT_LIVE.bend` | 81 + 842 + 33 | bounded response: induction over the trace (b5) |
| `LAWS_JETPROT_SOUND.bend` + `PROOF_JETPROT_SOUND.bend` | 72 + 388 | the 8 soundness lemmas of the equality and order predicates |
| `pymodel/jetprot_ref.py` + `pymodel/jetprot_laws.py` + `pymodel/spec_consts.py` | 378 + 551 + 88 | reference model; the laws as predicates (the oracle); the specification constants |
| `pymodel/mutants.py` | 811 | the adversarial bank of 76 defects |
| `prod/jetprot_prod.py` | 204 | production implementation with 9 planted bugs |
| `recheck.py`, `run.py`, `bridge.mjs`, `bridge_client.py` | 702 + 640 + 116 + 31 | gates (serial and parallel paths, `--jobs`) and bridge |
| `compare_runs.py` | 321 | leaf-by-leaf comparison of two runs' `results.json` and `recheck.json` (2026-09-23) |

Revision 2 (2026-09-19) had `jetprot.bend` 1 116 lines (with the predicates of 48 step laws), 64 + 117 laws, a bank of
62 defects and 6 planted bugs.

Checker cost (`results.json`); the certificate is re-evaluated in every file that imports it. Reference run,
`all --full` of 2026-09-23 with `--jobs 12` and Bend 2.0.25: `PROOF_JETPROT_LIVE.bend`, which imports
`PROOF_JETPROT.bend` and through it the certificates, 1 221.9 s, checked beside the Python stages (which had all ended
by 1 200.6 s); `PROOF_JETPROT_CONF.bend` 1.6 s; `PROOF_JETPROT_SOUND.bend` 0.8 s; the whole gate 1 222.4 s. Serial
run, `all --full --jobs 1` of 2026-09-22 with Bend 2.0.24: the same three checks 795.8 s, 0.7 s and 0.3 s; the whole
gate 7 305.5 s, of which 5 884.4 s are the per-law mutant census of `--full`. The two runs record the same verdicts,
counts, census and differential traces (`compare_runs.py`). The same figures in revision 2: `PROOF_JETPROT.bend` ≈
140–160 s (83–113 s before the demand laws); `PROOF_JETPROT_CONF.bend` 0.3 s; the three certificates alone 14–19 s
(`_COR` 0.3 s); the runtime smoke 5.6 s; the certificate negative 38 s, which is the evidence that `{==}` is computed
and not skipped; full gate (`run.py`) ≈ 5–6 min.

## 8. What counts as "closed"

`py -3.14 v3/run.py all` (from the repo root) → `[done] all: ok` (the reference run, `all --full` of 2026-09-23 with
`--jobs 12`: ok in 1 222.4 s; the serial path, `--jobs 1`, on 2026-09-22: ok in 7 305.5 s): (1) the PROOFs print
`All terms check.`; (2) the exhaustive grid without `FALSE` and C2 with no vacuous law; (3) the twelve negatives
rejected; (4) without bugs, no counterexample; every planted bug found by some generator, with a minimal trace, in
every instance where it is observable (the gate declares the five unobservable defect × instance pairs, §4; a
difference in the trajectory or a violated invariant counts); (5) C5 matches C1 cell by cell and the concrete
reachability is contained in `inv_all`; (6) C6 reported, with every surviving mutant computed to be equivalent (§5,
H38); (7) C3 run with its behavioural difference (C4 was not built: declared future work); (8)
`phase3-traceability.md` with the chain hazard → function → requirement → hypothesis → law → proof → negative →
differential → limit (`phase3-safety.md`), with the status of every quote and the reason: R-11 partial (A-11); R-6
covered as a mechanism since revision 4 (A-3), the content of JET's secondary table out of scope (A-16, A-35); R-14
covered since 2026-09-21 (A-22); R-15 operational evidence, not a requirement. (Revision 2 required six negatives and
C4, and listed R-6, R-11, R-14 and R-15 as out of scope.)

## 9. Adversarial review log

Five rounds over the design and over the code, a sixth on fidelity (H33, 2026-09-21) and the revision-4 assumption review (H37, 2026-09-22). **Independence note**: these are automated passes by the same
family of models that wrote the design; they do **not** constitute independent assessment in the regulatory sense, and there has
been no independent human assessment (see `phase3-safety.md` §0). All findings ended up as negative
tests, gates, laws or declared limits; none was resolved by weakening a law.

| Round | Perspectives |
|---|---|
| 1 (2026-09-18) | own + one reviewer on the design |
| 2 (2026-09-19) | own + four reviewers: bibliography and citations, executable model, functional safety (IEC 61508/61513), tokamak operations |
| 3 | verification of gates, equivalence of the four models, documented claims, adversarial |
| 4 | second adversarial pass over the newly added demand laws |
| 5 | verification of the transcription to Bend and of the closure of each hole |
| 6 (2026-09-21) | fidelity audit against [S1]/[S2]/[S6]: six auditors + direct review (H33) |
| revision 4 (2026-09-22) | assumption review against the code, [N1], [N2], [K15], [M13] and the physics library, a debate between three positions and a judge (H37); then audits of the documents |

### 9a. Findings on the model and the specification

| # | Finding | Sev. | Resolution |
|---|---|---|---|
| H1 | `sec` (primary/secondary) **unreachable**: the only JTT cell is in `Heating2`, JTT jumps to `Termination`, and that row has no RTPS. Its law was vacuous. *(Revision-4 note: since F1/H33 the JTT no longer moves `prog`, so second stops after a JTT are reachable again; A-3 no longer rests on this finding, and the secondary response is modelled as instance data, H37.)* | high | Field and law removed; R-6 out of scope (A-16); gate C2 was born. |
| H2 | `inv_all` **not inductive** by three paths: JTT moved the phase without touching units; `Local{u}` under PTN left `Inhibited` and the law said `= Off`; `CommFault` and watchdog reached the PTN without switching off. | high | Single `to_ptn` with `deenergize` preserving `Inhibited`; P2 as a step law. Negatives 2 and 3. |
| H3 | Step law false in spurious cells. | high | The principle of §2, first rule. |
| H4 | Wrong domain arithmetic. | medium | §5 and §7 recalculated and verified by two reviewers. |
| H5 | Dead path: with Table 1, MHD never reaches the PTN. | medium | Reinterpreted with [S6]/[S7]: "None" is "no primary RTPS response", not "no protection". Instance 2 was born. |
| H6 | The DMS re-armed from `Fired` and a repeated alarm restarted the wait. | medium | `arm_dms` only from `Idle`; P15, P18. Negative 6. |
| H7 | Unconditional `Reset` and `LocalClear` with no textual basis: two ways of deactivating a latched protection without condition. | medium | P20 with guard; `LocalClear` removed (A-7). |
| H8 | `Advance` ran under PTN, against R-0. | medium | P19. |
| H9, H13 | Verdicts to all arms made reflection expensive; irrelevance outside `Tick` was a single mechanical check. | medium | Only to the `Tick` arm; and in round 3 it ceased to be an assumption: it is law V1. |
| H10 | Intents that over-claimed. | low | Rewritten. |
| H11 | The only free choice of A-1 is JTT vs RTPS; the order orders **authority**, not safety. | low | A-1 with counter-hypothesis; the order is a model parameter and every abstract law is proved for both (the concrete layer runs `Ord1` only). |
| **H12** | **P2 false in 11 592 spurious cells**: the same error as H3 in a new law. | high | P2 in the form "the step that reaches PTN"; **negative 5**, which is a false law over the correct model. |
| H14 | The DMS was constrained only negatively: a model that never arms it passed all the laws. | high | P16, P17, P18. |
| H15 | **The source's main hazard had no law**: a hotspot during heating fires an RTPS stop, and an RTPS stop changed nothing observable. | high | Unit with `Ramping` state; P3, P4, I2. Negative 7. |
| H16 | **The JTT de-energized in the same step**: contradicts R-4 (the JTT *ramps*) and made the JTT harsher than the RTPS stop, against the A-1 order itself. | high | JTT and RTPS ramp; D2. Negative 10. |
| H17 | Source fidelity: a fabricated quote, a typo of the original silently repaired, the PTN argument anchored to the weakest quote, 13 of 28 cells by ditto mark (not 6), a nonexistent author, missing licences and DOIs, a derivative without attribution. | medium | `phase3-sources.md` rev. 3; `sources/NOTICE`. |
| H18 | Framing: machine protection, not a nuclear safety function; Stop Selector, not Stop Manager; the hazard analysis and the requirements layer between the quotes and the laws were missing; six implicit hypotheses. | high | Header of `phase3-sources.md`; A-18…A-23; `phase3-safety.md`. |
| H19 | Operations: phases and window are instance; the DMS arming is configuration with window and threshold; the real reason for the switch-off prior to the DMV is the duct pressure and the antenna lines; the mode lock does protect in JET. | medium | Abstract/concrete layer; A-10, A-22; R-14, R-15; instance 2. |
| H20 | C3 had no signal ("all survive"). | medium | It reports the behavioural difference; and the order became a proved parameter. |
| H21 | `check_env.sh` broken when vendoring the runner (a space in the repo path split the unquoted variable): 9 failures out of 11. | high | Array `BEND=(bash "$HERE/bend.sh")`. 11 PASS / 0 FAIL. |
| H22 | Three gates looser than they seemed: `run.py` accepted a type error as a valid rejection, the smoke criterion was a substring, and C3 could not fail. | medium | Strict criteria: refutation of a `Bool` **and** the name of the file's law; line count; C3 reports difference. |
| H23 | The "independent" Python model was a port of the Bend, not a reading of the document: it had a law the document does not contain and copied internal decompositions of the `.bend`. | high | Claim downgraded everywhere; C5 is described as **re-execution in another language**, not as N-version diversity. During that audit an automated reviewer (the same model family, README §7) also wrote a transcription from the design document alone, which, on the model of that day (2026-09-19, 2 688 states, before blocker 4 and revision 4), reached the same 921-state concrete space and, in the reviewer's report, agreed with the model on every reachable cell and on every law; that transcription and its run are not kept in the repository, so this is a record of the audit, not evidence the gate reproduces. |
| H24 | The document and the three models diverged on two points (both unreachable) and there was a real ambiguity in the precedence on entering `Termination`. | medium | Document corrected; the precedence written down. |
| H25 | `fast_ptn` (P13) was cited as a law in the design, the traceability and a safety requirement, **and did not exist**. | high | Written and proved (42 arms: 7 phases × 3 DMS states × 2 instances). |
| H26 | Numbering collision: P21 meant two different laws in four documents and the code. | medium | The theorem is **T**; P21 is `reset_refused_mid_pulse`. |
| H27 | Stale numbers in the documents and a cited `results.json` that did not exist. | medium | All measured again; §7. |
| H38 | The mutation gate accepted its one survivor **by name**: C6 passed any survivor whose name began with `M06`. That M06 is equivalent had been computed outside the gate, the results files recorded only the name, and the docstring of the bank still quoted the certificate domain of revision 2 (0 of 209 664 cells). | medium | Since 2026-09-23 C6 compares every survivor's `step_fin`, `upd_hb` and `upd_tack` with the model's on all 924 672 certificate cells, its step with the counters (`step_st`) on 12 042 240 cells with concrete counter values and its `concretize` on 1 032 192 (instance, control state, plant event) cells (H39), and records the three counts (`C6.equivalence`); it accepts a survivor only with 0 differing cells in all three and fails on a survivor without the comparison. M06: 0 of 924 672, 0 of 12 042 240 and 0 of 1 032 192 (reference run of 2026-09-23). |
| H39 | The first version of the computed equivalence (H38) compared the step and the counters but not `concretize`, which the Python law set checks only in part: C1 on 112 control states per instance (DMS idle, plasma on, both units off), C3 against the mutant's own `concretize`. Two probe mutants of `concretize` (an alarm dropped while NB is on; the DMS bit dropped without plasma) survived the law set with 0 differing cells in the step and the counters, so they would have been accepted as equivalent. | medium | Since 2026-09-23 C6 `equivalence` also compares `concretize` on all 1 032 192 (instance, control state, plant event) cells: the two probes differ on 18 144 and 50 688 cells and are rejected, M06 on 0 (checked outside the gate, then in the reference run of 2026-09-23). Open: the Python oracle has no copy of the Bend law `fast_ptn` (P13), which would catch the first probe directly (`TODO.md`). |

### 9b. Findings that changed the law set

The three most important of the project, because they are not transcription errors but errors of **method**.

| # | Finding | How it was found | Resolution |
|---|---|---|---|
| **H28** | **The law set was entirely negative.** It said what cannot happen and never what has to happen, so it was satisfied by a degenerate model: ignore every stop not wired to the DMS, trip instead of ramping, not count the watchdog and never accept the end of pulse. That model passed **the laws and the vacuity gate together**. 16 of 37 plausible mutants survived. | an adversarial review built the degenerate model and made it pass | 18 demand and frame laws (D1–D18). Bank 21/37 → 36/37; tightness 12 % → 46 %. |
| **H29** | The demand laws left **eight holes**, and 11 of 25 new mutants survived. The worst: nothing required a heartbeat to reset the watchdog; the counter could run past its limit without any law seeing it; and **nothing constrained `step_c`**, so that always reading the matrix of instance 1 silently disabled instance 2 without changing the reachable set. | second adversarial pass, with 25 mutants aimed at the seams of the new laws | E1–E11, `step_c_is_the_concrete_step`, V1. Bank 50/62 → **61/62**; tightness 46 % → **95 %**. |
| **H30** | Two **self-referential** laws: P20 expresses the end-of-pulse guard with the model's own guard (so any guard satisfies it), and the first `concretize` law compared the function against an expectation built with the same table (so it did not detect a wrong value). | strength analysis of each law, removing one guard at a time and looking for counterexamples | D10 and E8 write the guard literally; the matrix is transcribed as its own constants. |
| H31 | The C2 coverage metric was **zero by construction**: `P1`, `P14` and `P15` have hypothesis `e ≠ Reset`, so every cell came out "covered". And the bank of 17 mutants was chosen to fit the laws. | the same review | **Tightness** metric (how many of the 2 688 successors the law set admits, plus the 9 command pairs), and an adversarial bank of 62 written by reviewers whose brief was to break. |
| H32 | A law proposed by the audit (`dms ≠ DmsIdle ⇒ plasma_ok`) is **physically false and not inductive**: losing the plasma with the DMS armed violates it in one step, and that step is precisely what the mitigation exists for. | the audit itself, when verifying it before recommending it | Not added; the underlying concern (reachable states with the DMS fired and no plasma) remains as a declared limit. |
| **H33** | **Fidelity, round 6 (2026-09-21, six auditors + direct review):** the JTT relabelled the single phase and `concretize` afterwards read the Termination row of Table 1 (a later `Slow` escalated to PTN with no published basis); the local protection switched off the whole unit when R-9 says *one PINI*; `CommFault` was unconditional PTN when [S1] says "*can* trigger" and [S6] documents disruptions missed due to inhibits; the DMV current threshold was left out (7/16 misses of R-15). | fidelity audit against [S1]/[S2]/[S6] | Blocker 4: `prog`/`jtt` (A-24), `Reduced` (A-6/A-7), `CommFault{dms, en}` + `Blind` + masks (A-13/A-21/A-25), `ip` (A-22 withdrawn); laws F1a–F1d, F2a, F2d, F3b, IP1–IP4. |
| H34 | With the local protection reducing, `Inhibited` became **unreachable**: P8 had 0 reachable cells (vacuous by construction, which C2 rejects) and the design proposed keeping it "for R-10". | when validating the new domain in Python before touching Bend | The value was withdrawn (A-26) and with it P8 and E1; the certificate went down from 16 800 to 10 752 states. |
| H35 | A `Plasma{True}` that returned a unit from `Reduced` to `On` passed **all** the laws: I1 already held, P7 only looks at units without power and no law framed the units on `Plasma{True}`. | the same validation | F2d (`reduced_never_returns`); the planted bug `plasma_ok_restores_reduced` in `prod/`. |
| H36 | The **tightness** metric fell from 93 % to 82 % with the new model: without P8 and with `Reduced`, nothing framed the units on the events that do not touch them (`Ip`, `Plasma{True}`, a `Tick` without watchdog, a rejected stop), and `jtt` was left free with `prog = Termination`. | the first `all` run of blocker 4, and a diagnosis of which fields varied among admissible successors | F4 (`units_frame`) and F1e (`jtt_exact`): tightness 99 %, mean 1.01 admissible. Lesson: the tightness metric is worth more than the law count; a type revision leaves holes that no existing law sees. |
| **H37** | **Revision 4 of the register (2026-09-22; assumption review against the code, [N1], [N2], [K15], [M13] and the physics library, then a debate between three positions and a judge).** The model's weak point is an alarm that arrives during a stop in progress: [N1] documents primary and secondary stops (the secondary ones configured apart, "seven primary stops and six secondary", PDF p.13, and started when the primary fails to mitigate the event or itself generates a higher-priority termination event, PDF p.14; the most used secondary was PTN slow, Fig. 7, a usage statistic), a configuration frozen at the primary stop (for the shape controller) and a cap of "a maximum of two in sequence" (PDF p.13); the model re-read the primary table at the advancing programme phase and took the maximum. Other findings: the reduction is forgotten through `Off` (A-34), the heating window is model code, not instance data (A-27), the DMV verdict is current OR stored energy (A-22). | the review and the judge's Python runs (reachability, distinct ignored cases, the freeze's effect) | **Freezing the table at the primary stop (M1) rejected**: the verbatim rule is about the shape controller ("RTPS will select the stop and send it to SC", [N1] PDF p.13), freezing alone removes more PTN escalations than it adds on the Python model, and with instance 4's PTN secondary table it changes nothing observable (level, DMS and units after the second alarm: 0 of 144 two-alarm scenarios per base table, on the Python reference model), while in instances 1–3, which keep the legacy reading, it would change 40 of 144 per instance (36 PTN escalations lost, 4 gained). **Secondary response adopted as instance data of the concrete layer, without a freeze**: `sec_table`, legacy reading kept in instances 1–3, illustrative instance 4 (A-35). The parts of P1 and D1 about the PTN and the primary stop named apart from the policy (P1a, P1b, D1a, D1b, `piw_after_ptn_is_noop`; the documents audit of 2026-09-22 labelled D1a, P1b and PIW-after-PTN mixed, because they carry our formalisation, A-9, A-14). Negatives 11 and 12; mutants W01–W03; planted bug `secondary_ignored_during_stop`. Gate `run.py all --full` of 2026-09-22: all stages ok. |

### 9c. Lessons on the method, for the preprint

1. **A certificate is not coverage.** Saying "104 832 cells decided" sounds like exhaustiveness and says nothing about whether the laws demand anything. The honest measure is **tightness**: how many successors the set admits. It started at 15 of 2 688 and ended at 1.08 (1.01 of 10 752 after blocker 4, run of 2026-09-22).
2. **A mutation score is only worth something if the bank is adversarial.** With the bank written alongside the laws: 17/17 from the start. With banks written to break them: 21/37.
3. **Step laws hold over the whole domain, including the unreachable part.** Three times the same error.
4. **A law must not cite the model in its conclusion.** If the model's guard appears in the law, the law cannot detect a wrong guard.
5. **The seq3 pattern does not scale as is.** Bend compares complete normal forms: projecting from the whole certificate with symbolic arguments cost 15–30 minutes. Slicing it into 56 pieces brought it down to minutes.
7. **The facts of a proof by induction go in as template hypotheses, not as open laws.** Bend rejects live code that calls an unfilled law ("an unfilled law is a dead claim"), so a core without certificate cannot leave its facts as open `law`s: it takes them as `for ~fact: ...` and the gate file instantiates them with the laws proved by reflection. The core checks in seconds and is iterated without paying the 11–18 min of the certificate; the gate pays once.
6. **What is definitional in Bend is not so in another implementation.** `step_c_is_the_concrete_step` closes with `{==}` in Bend because it is the definition; in the Python reference model it is a real obligation, and that is where the mutants that motivated it live. That is why mutation and differential testing operate on the side that can deviate.
