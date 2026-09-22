# Phase 2 — Design: verified discharge sequencer + differential testing

Date: 2026-09-18. Hypotheses covered: **4** (verified supervisory logic), **B** (certificates by computation) and **C** (total reference model called from Python for differential testing). Same standard as v2: specification designed for the checker, laws reviewed by exhaustive instantiation before proving, one prover agent per file, negative test, and a single gate (`py -3.14 v2/seq/run.py`).

## 1. The system (discrete abstraction of a pulse)

A discharge sequence controller with machine protection interlocks (MPS), reduced to the discrete:

- **Phases**: `Idle → Charged` (TF coils at field) `→ Prefill` (gas) `→ Breakdown` (central solenoid ramp, initiation) `→ FlatTop → RampDown → Idle`, plus `Shutdown` (safe state) reachable from any phase.
- **Sensors** (booleans in the state, updated by events): `vac` (vacuum ok), `tf` (nominal toroidal field), `dens` (density within window).
- **Actuators**: `gas` (prefill valve), `cs` (solenoid energized), `heat` (auxiliary heating).
- **Counters**: `t_flat` (ticks in flat-top; limit `t_max = 4`: coil heating), `hb` (ticks without PCS heartbeat; limit `hb_max = 3`: watchdog).
- **Events** (15): `Tick`, `Heartbeat`, `Vac{ok}`, `Tf{ok}`, `Dens{ok}`, `CmdCharge`, `CmdPuff`, `CmdBreakdown`, `CmdFlatTop`, `CmdHeatOn`, `CmdHeatOff`, `CmdRampDown`, `Disruption`, `Abort`, `Reset`.

Controller rules (`seq.bend`): each command is accepted only in its phase and with its permissives (charge only with vacuum; gas only with coils charged, vacuum and field; breakdown only after prefill; heat only in flat-top with density); after each sensor update the interlock is re-evaluated (phase with gas or plasma without vacuum or field ⇒ `Shutdown`; without density ⇒ heating off); on each `Tick` the watchdog runs in the watched phases (all but `Idle` and `Shutdown`) along with the flat-top counter; `Disruption` and `Abort` lead to `Shutdown` from any state; `Reset` returns to `Idle` from `RampDown` or `Shutdown`.

**Written in proof shape**: each handler does `match` on one thing; each decision that depends on a computed value (`is_plasma(phase)`, `Bool.and(vac, tf)`, `Nat.is_lt(1+hb, hb_max)`) is passed to a helper as a `Bool` parameter, so that the proof can `match` on the same boolean ("verdict with evidence"). No IO: the same file is loaded from JavaScript as the reference model.

## 2. The laws (`LAWS_SEQ.bend`, `LAWS_SEQ_FINITE.bend`) and their review

Each invariant is a `Bool` function over the state that reads a single group of fields:

| Law | Statement | What it guarantees / what it does not |
|---|---|---|
| `inv_init` (computation) | `inv_all(init()) == True` | The initial state is safe. |
| `pres_l1` | `∀ s, e: l1..l6(s) ⇒ l1_field(step(s, e))` | **Gas or plasma only with vacuum and field.** Covers the loss of a sensor in any phase with plasma, including `RampDown`. |
| `pres_l2` | same for `l2_heat` | **Heating only in flat-top with density within window.** Covers `Dens{False}` during heating and leaving flat-top by any route. |
| `pres_l3` | same for `l3_cs` | **Solenoid energized only in breakdown / flat-top / ramp-down.** |
| `pres_l4` | same for `l4_gas` | **Gas valve open only in prefill.** |
| `pres_l5` | same for `l5_flat` | **In flat-top, `t_flat < t_max`**: the pulse ends on its own, for every value of the counter (not only those of the grid). |
| `pres_l6` | same for `l6_hb` | **In a watched phase, `hb < hb_max`**: three ticks without heartbeat never leave the machine in a phase with plasma. |
| `traces_safe` | `∀ trace: inv_all(run(trace, init())) == True` | **The theorem**: no sequence of events, of any length, takes the system out of the safe set. It is what an operator wants to be true. |
| `shutdown_safe` | `l2, l3, l4 ⇒ l7_safe(s)` | Corollary: in `Shutdown` every actuator is off. It is stated because it is what one reads in a safety review; it is proven from the others. |
| `disruption_shuts_down`, `abort_shuts_down` | `∀ s: phase(step(s, Disruption)) == Shutdown` | Step level, for **every** state (not only the reachable ones): disruption and abort have no precondition. |
| `finite_check` (computation) | `check_small() == True` | Certificate by computation: 1792 states (every phase × every combination of sensors and actuators × counters at 0 and at limit−1) × 18 events; the checker decides it in 5.5 s. Weaker than `traces_safe` (counters not universal) but it is one line. |

What the laws do **not** say: nothing about real time (ticks are abstract), nothing about liveness (that the pulse *progresses*), nothing about the physical plant (sensors are arbitrary inputs: the laws also hold for physically impossible sensor sequences, which is the right thing for protection).

### Prior validation (exhaustive instantiation)

`tests/laws_seq_smoke.bend` evaluates at runtime the preservation of the six components, the two step-level laws and the corollary over **7168 states × 18 events** (counters in {0, 2, 3, 4}), in 0.6 s. Result: no false law; 452 of the 7168 states satisfy `inv_all`.

### Reviews that changed the design before proving

1. **Watchdog in `Idle`.** First version: the heartbeat was counted in every phase. Consequence: `hb` grows without bound in `Idle` and on charging the coils the machine would enter a watched phase already violating L6. Decision: the watchdog runs only in watched phases (`is_watched`) and `CmdCharge` enters `Charged` with `hb = 0`. It is a case of "the correct law forces fixing the design", not the law.
2. **`RampDown` is a phase with plasma.** When writing `is_plasma` the question was whether the ramp-down needs the vacuum and field interlock. Yes: there is plasma until the current reaches zero. It is exactly the planted bug in the production implementation (`rampdown_not_plasma`), and the negative test `tests/seq_bug_PROOF.bend` shows that the checker rejects the law for that variant with the explicit counterexample.
3. **L7 derived, not an axiom.** "In `Shutdown` everything off" came out first as a component of the invariant; it is a consequence of L2–L4 and was left as a proven corollary, so as not to have two truths about the same thing.
4. **Hypotheses per component.** `inv_all` as a single conjunction meant that no hypothesis reduced without splitting all the fields (`Bool.and` reduces by its first argument). Each preservation law receives the six components as separate hypotheses and spends only the ones it needs; `traces_safe` joins them with `and_l`/`and_r`/`and_intro`.
5. **Large literals.** `7168n` and `1792n` in the enumerator blew the parser ("a literal too large to expand"): `Nat` literals are expanded into unary. They become `U32.to_nat(7168)`.

## 3. Differential testing (hypothesis C)

- **Bridge**: `bridge.mjs` loads `seq.bend` with Bend's JS loader (`node --import file:///…/bend2/main.ts`) and serves JSON over stdin: a trace → the trajectory of states and `inv_all` at each step; a list of foreign states → `inv_all` over them. A persistent process: ~1 ms per call.
- **Production implementation** (`prod/sequencer_prod.py`): written in Python from the same natural-language specification, not from the `.bend`, with two planted bugs of the kind that survives a code review: `watchdog_off_by_one` (`>` instead of `>=`: `hb` reaches `hb_max` in a watched phase) and `rampdown_not_plasma` (losing vacuum or field in `RampDown` does not shut down).
- **Two oracles**: (a) the complete production trajectory equals that of the Bend model; (b) Bend's invariants, evaluated by Bend over the states that production produces, hold. The second does not need the model to be "equal": it detects violations of the specification directly.
- **Two generators** (Hypothesis, 3000 examples, with shrinking to the minimal counterexample): pure random traces, and "guided" traces that start with a prefix of the happy path and continue at random.
- **Configurations**: no bugs (must pass), each bug alone, both.

## 4. Proof plan

```
PROOF_SEQ_A (pres_l1..l3) ─┐
PROOF_SEQ_B (pres_l4..l6) ─┴─> PROOF_SEQ (inv_init, traces_safe, shutdown_safe, disruption/abort)
PROOF_SEQ_FINITE (finite_check by computation)
```
Two agents in parallel (each one three preservation laws, one mirror lemma per handler and per invariant), and the glue laws by hand. An open law cannot be used as a lemma, so `PROOF_SEQ` imports `A` and `B`.

## 5. What counts as "closed"

`py -3.14 v2/seq/run.py` finishes with `all gates and checks ok: True`:

1. `PROOF_SEQ.bend` and `PROOF_SEQ_FINITE.bend` print `All terms check.` (12 laws).
2. The exhaustive grid has no `FALSE` line.
3. `tests/seq_bug_PROOF.bend` is rejected.
4. No bugs: no counterexample in 3000 traces with either of the two generators. Each planted bug: found by at least one generator, with a minimal trace and with both oracles firing.
