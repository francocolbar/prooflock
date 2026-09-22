# Phase 2 — Findings: verified discharge sequencer + differential testing

Date: 2026-09-18. Reproduce: `py -3.14 bend-spike/v2/seq/run.py` → `all gates and checks ok: True` (about 20 s; numbers in `v2/seq/results.json`). Design and review of the laws in `phase2-design.md`.

## What was built (`bend-spike/v2/seq/`)

| Piece | File | Lines (code) |
|---|---|---|
| Model: 7 phases, 15 events, controller with interlocks, 6 decidable invariants, `run` | `seq.bend` | 449 (323) |
| Exhaustive enumerator of the finite space | `seq_enum.bend` | 139 (106) |
| Laws: 11 (preservation per component, trace theorem, corollary, two step-level ones) + 1 finite certificate | `LAWS_SEQ.bend`, `LAWS_SEQ_FINITE.bend` | 119 (84) |
| Proofs L1–L3 (agent, 70 defs, 2 iterations, the whole file passed on the first try) | `PROOF_SEQ_A.bend` | 856 (750) |
| Proofs L4–L6 (agent, 69 defs, 4 iterations) | `PROOF_SEQ_B.bend` | 843 (741) |
| Glue: `Bool` facts, `inv_init`, corollary, disruption/abort, **trace theorem** (by hand, 2 iterations) | `PROOF_SEQ.bend` | 132 (96) |
| Finite certificate by computation: `{==}` | `PROOF_SEQ_FINITE.bend` | 8 (6) |
| Bridge to Bend's JS loader (reference model as a JSON service) | `bridge.mjs` | 38 (27) |
| "Production" implementation in Python with two planted bugs | `prod/sequencer_prod.py` | 113 (90) |
| Driver: gates + Hypothesis (2 generators × 4 configurations × 2 oracles) | `run.py` | 171 (143) |
| Exhaustive instantiation and negative test | `tests/laws_seq_smoke.bend`, `tests/seq_bug_PROOF.bend` | 62 (44) |

Total Bend: 2106 lines of code, of which 1593 are proofs (12 laws, 152 proof definitions). Checking: 0.3 s for the theorem, 5.5 s for the finite certificate.

## What closed

1. **The trace theorem.** `∀ trace: inv_all(run(trace, init())) == True`: no sequence of events, of any length, with any value of the counters, takes the system out of the safe set. Gas or plasma only with vacuum and field; heating only in flat-top with density; solenoid and valve only in their phases; flat-top bounded; watchdog bounded. Moreover: in `Shutdown` everything off (corollary), and disruption or abort lead to `Shutdown` from **every** state, reachable or not.
2. **The certificate by computation.** 1792 states × 18 events (about 32 000 evaluations of the step plus the invariants) decided by the checker's evaluator in 5.5 s with a one-line proof. Before that, the runtime instantiation over 7168 × 18 ran in 0.6 s: the same technique serves to review laws before proving them and to certify finite spaces without writing inductions.
3. **The negative test.** The variant with the `RampDown` bug (the same as production) is rejected by the checker with the explicit counterexample: `expected False{} / observed True{}` in the `RampDown` state with vacuum lost.
4. **Differential testing.** The Bend model, loaded in node with the JS loader, serves ~1 ms per query. Against the Python implementation with planted bugs, Hypothesis with 3000 examples per configuration:

| Configuration | Random generator | Guided generator (happy-path prefix) |
|---|---|---|
| no bugs | no counterexample | no counterexample |
| `watchdog_off_by_one` | **found**, minimal trace of 5 events: `Vac+ CmdCharge Tick Tick Tick` → `Charged` with `hb = 3` | found, same trace |
| `rampdown_not_plasma` | **not found in 3000 traces** | **found**, minimal trace of 7 events: `Vac+ CmdCharge Tf+ CmdPuff CmdBreakdown CmdRampDown Vac-` → `RampDown` with `vac = False` |
| both | the watchdog one found | both found |

On every finding **both** oracles fire: the trajectory differs from the model, and Bend's invariants evaluated over the production states fail. The second oracle is the important one: it does not demand that production be "equal" to the model, it demands that it satisfy the specification.

## Findings

- **Random testing does not reach the deep states; the proof does.** The watchdog bug is 3 events from the start and the random generator finds it in seconds. The `RampDown` bug needs six events in order without an abort, a disruption or three ticks without heartbeat slipping in: 3000 random traces do not touch it. With a guided (state-aware) generator it shows up in 200 queries. `pres_l1`, on the other hand, covers it for every state without generating anything: the negative test shows it in a single `{==}`. It is the right division of labor: the proof for the specification, differential testing for the implementation that is not in Bend.
- **The cost of the proofs is the case explosion, literally.** The two preservation files add up to 1500 lines for six invariants because the checker does not specialize a wildcard `case s2:` over the nested fields of a record: each handler needed its 7 arms per phase and its arms per boolean, written one by one. Without tactics, "by cases" means "all the cases, by hand". The agents did it in 2 and 4 iterations because the code was written for that, but the proofs/model ratio is 5×, against 1.8× in Phase 1.
- **The hybrid alternative is in plain sight.** The certificate by computation covers the finite part of the state in one line; the only thing that needs induction is the counters (L5, L6). A design that splits the record into a finite part and counters, with the certificate for the former and two lemmas for the latter, would bring the 1500 lines down to fewer than 200. It is left as the next iteration: here the complete universal theorem was preferred in order to measure its real cost.
- **Verdict with evidence.** Decisions about counters (`Nat.is_lt(1+hb, hb_max)`) cannot be `match`ed in a proof; they are passed as `Bool` with an equation tying them to the state. For L6 the evidence had to be stated as `l6_hb` of the already-incremented state, not as the raw comparison, in order to hand it to the generic lemma of the flat-top counter. It is the idiom that makes properties with arithmetic provable without having arithmetic in the proof.
- **The interlock breaks the "preserve the hypothesis" pattern.** For L1, after `Vac{False}` in a phase with plasma, the intermediate state (before the interlock) violates L1 and there is no hypothesis to preserve: the lemma had to quantify over the computed booleans with equations `p == is_plasma(phase)`, `ok == Bool.and(vac, tf)` and rewrite. It was agent A's hardest step.
- **The laws forced fixing the design twice before proving anything**: the watchdog cannot run in `Idle` (or L6 is false when charging the coils) and `RampDown` is a phase with plasma. Both came from writing the law and asking whether it was true, not from the checker.
- **Small things that cost a round**: large `Nat` literals (`7168n`) blow the parser (`U32.to_nat`); an event used twice in the trace induction needs `+e`; an equality hypothesis can indeed be marked `+` and used six times.

## Verdict (hypotheses 4, B and C)

**Viable today and solid.** A sequencer with machine protection interlocks, with all its safety invariants proven for every trace, which moreover runs as a reference model from Python and detects planted bugs in an independent implementation. Cost: 2106 lines of Bend, 1593 of proofs; two prover agents and hand-written glue; about four hours of wall-clock time. What it does not cover: real time, liveness, the physics of the sensors. What would change on the next round: the finite/counters split so that the certificate by computation does 90 % of the work.

For the fusion project: this is what a machine protection team would want to have for every interlock: the executable specification, the proof that the specification is safe, and the oracle against which the real PLC is tested. All three come out of the same `.bend` file.
