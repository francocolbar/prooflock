# Phase 2b — Technical debt: the sequencer redesigned for cheap proofs

Date: 2026-09-18. Reproduce: `py -3.14 bend-spike/v2/seq3/run.py` → `all gates and checks ok: True`.

## The problem

In Phase 2 the six preservation laws cost 1593 lines of proof for 323 of model (5×), because the checker does not specialize a wildcard `case` over the nested fields of a record: each handler needed all its arms per phase and per boolean, written one by one.

## The redesign (`v2/seq3/seq3.bend`)

The state is split into **finite control** `Fin{phase, vac, tf, dens, gas, cs, heat}` and **two counters**. Every decision is finite: the two comparisons on the counters enter the control as boolean verdicts (`bt`, `bh`), and the control returns **commands** to the counters (`CKeep`, `CReset`, `CInc`) instead of touching them. Then:

- `step_fin(f, e, bt, bh)` is a function over a finite domain (448 states × 18 events × 4 verdicts). Everything said about it is decided by the checker by computation, and since `bt`/`bh` range over `Bool`, the certificate covers **every** value of the counters, not a grid.
- The two update "shapes" (`t_shape`, `hb_shape`: if the next control runs a counter, the command is `Reset`, or `Keep` from a state that was already running it, or `Inc` with verdict "below the limit") are also finite.
- The only thing that needs symbolic reasoning is a generic lemma: `cnt_go(fl, apply(u, n), lim)` from the shape and the previous bound. One lemma, three cases, serves both counters.
- The universal laws are obtained from the certificate by **reflection**: a ladder of small lemmas (one per quantification level: 7 phases, 6 booleans, 18 events, 2 verdicts) that extract from `check_fin() == True` the cell `prop(f, e, bt, bh) == True` for arbitrary `f`, `e`, `bt`, `bh`.

In addition: `same_as_old`, a certificate by computation that the new model gives exactly the same states as `seq/seq.bend` over 7168 states × 18 events at runtime (0.6 s) and over 1792 × 18 in the checker (34 s, structural comparison; with strings it took 5 minutes).

## Result

| | Phase 2 (`seq/`) | Phase 2b (`seq3/`) |
|---|---|---|
| Model (code) | 323 | 425 (the commands and the shapes add ~100) |
| Enumerator / certificates | 106 | 223 |
| Laws | 12 | 11 (the same guarantees; L1–L4 in a single law `pres_fin`) + equivalence |
| **Proofs (code)** | **1593** | **323** (311 reflection and glue + 12 certificates) |
| Proofs / model | 4.9× | 0.76× |
| Prover iterations | 2 + 4 + 2 | 5 (all syntax, none logic) |
| Checking time | 0.3 s + 5.5 s | 34 s + 34 s |
| Differential testing | 2 bugs found | identical (same bridge, same production implementation) |

The 1593 lines went down to 323: **five times fewer**, with the same guarantees, and with an extra certificate that the model did not change behavior.

## What was learned

- **Design for the certificate, not for the induction.** When all decisions are finite and the arithmetic is encapsulated in `apply`, the checker does the case-by-case work on its own; the human (or agent) proof is the reflection ladder, which is generic and does not grow with the number of handlers. Adding an event or a phase adds one arm to a level lemma, not 7×64 cases.
- **The price is checker time, not lines.** The certificate is re-evaluated every time the file is checked (34 s), even when imported. For a larger model the size of the domain has to be watched: about 10⁵ cells is the practical ceiling today.
- **A wildcard `case _` does not refine the scrutinee in the hypothesis nor in the goal**: the prover's only friction was that and the annotation of a constructor `let`; zero logic iterations.
- **Equivalence with the previous model is cheap and worth it**: it is what allows refactoring a verified model without fear. It should be a gate in any redesign.

## Verdict

Debt settled. With this design, modeling a real interlock (Phase 3 candidate) costs writing the finite control and the commands; the proofs are almost the same 300 lines for any control size, and the checker decides the rest.
