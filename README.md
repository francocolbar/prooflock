# Verified reference models for machine-protection logic

*A case study on the JET wall-protection chain (RTPS Stop Selector + PTN + DMS arming), built with Bend 2.*
Working name: to be decided (candidates in §9). Spanish version: [README.es.md](README.es.md).

## 1. What this is, in one paragraph

A method for writing the discrete logic of a protection system (interlocks, stop sequencers, permissives) as a
**total, executable model** whose safety properties are **proved for every trace and every configuration** by a
proof checker, and then using that model as a **reference oracle** against the real implementation. The proofs are
cheap because the state is split into a finite control and a few counters driven by commands: every property of the
control is decided by computation over the whole domain (a *certificate*) and lifted to universal laws by reflection,
so the proof effort does not grow with the size of the control. This repository contains the method's base
(a proven numeric base, a proven linear IR), two internal exercises, and one public case study: a reconstruction, from
open publications, of the JET Real-Time Protection Sequencer's stop logic and its interface to the Pulse Termination
Network and the Disruption Mitigation System.

**What it is not.** The modelled function is *machine protection* (investment protection), not a nuclear safety
function; the evidence is about a *specification*, not about a system; it contributes to a systematic-capability
argument (IEC 61508-3 tables A.1/A.2/A.9) and supports no SIL claim by itself; 21 of the 49 cells of the certified
configuration matrix are our hypotheses because the published table shows 28. All of this is written down before the
results, in `v3/docs/fase3-seguridad.md`.

## 2. Layout

| Path | What | Status |
|---|---|---|
| `env/` | the Bend runner pinned to one commit (`env/bend.sh`, refuses any other checkout), 13 toolchain and hello-world checks | `bash env/check_env.sh` |
| `v3/` | **the case study**: model, certificate, laws, proofs, negative tests, bridge, production implementation with planted bugs, independent Python re-check, gate | `py -3.14 v3/run.py` |
| `v3/docs/` | sources and quotations (`fase3-fuente.md`), design and laws (`fase3-diseno.md`), hazards / safety requirements / limits of evidence (`fase3-seguridad.md`), traceability (`fase3-trazabilidad.md`), CC BY copies of the source papers (`sources/`) | Spanish |
| `v2/num/` | proven numeric base: canonical integers with the full commutative ring (22 laws), big naturals as bit lists with a proven adder, big integers | reusable |
| `v2/heat/` | proven linear IR + exact oracle for a 1-D heat stencil (the first exercise) | `py -3.14 v2/heat/run.py` |
| `v2/seq/`, `v2/seq3/` | a tokamak discharge sequencer with 6 machine-protection invariants proved for every trace; `seq3` is the redesign that made the proofs cheap (1593 → 323 lines) | `py -3.14 v2/seq3/run.py` |
| `docs/`, `heat/` | the first (historical) round of the spike, its closing report (`docs/spike-2026-09-18.md`, Spanish) and the preprint draft (`docs/preprint-draft.md`) | history |

## 3. The case study (v3) in numbers

Revised 2026-09-21 (fidelity to [S1]/[S2]/[S6], `docs/STATUS_2026-09-21.md` blocker 4): the program phase and the
termination waveform are two views of time, a local alarm reduces a unit instead of inhibiting it, the DMV current
threshold gates the arming of the DMS, and the two reliability checks pass through per-instance masks.

- **Model**: 10 752 control states (program phase × waveform flag × response × DMS × plasma × current threshold ×
  two units at Off / Ramping / Reduced / On) × 28 abstract event variants (the configuration travels as event
  payload) + 2 counters. A concrete alphabet of 22 plant events reaches it through three configuration instances:
  Table 1 of Stephen et al. 2011 as published, the same with mode lock routed to the PTN (the path [S6]/[S7]
  describe), and the published table with both reliability checks masked out.
- **Certificate**: 43 columns × 10 752 states = **462 336 cells per urgency order**, both orders, decided by the
  checker (1064 s for `PROOF_JETPROT.bend` on the JS checker); plus a 10 752-state certificate for the
  state corollaries and a 924-cell one for the concrete layer.
- **Laws**: **75** (`LAWS_JETPROT.bend`) + **137** conformance laws + 8 soundness lemmas + 2 bounded-response
  theorems, all `All terms check.` Six invariant clauses, the step laws saying what cannot happen, the demand and
  frame laws saying what must happen, thirteen fidelity laws (two views of time, partial power, masks, current
  threshold, and the two frames the tightness metric asked for), the trace theorem for the abstract and the concrete alphabets, the configuration cell by cell (28
  published cells + 21 assumed + the blind row, kept apart), and two response theorems over traces: `hb_max`
  ticks without a heartbeat latch the PTN, an armed DMS fires within `ack_max` ticks -- universal in both limits.
- **Negative tests**: **10**, each rejected by the checker with an explicit counterexample, and the gate accepts a
  rejection only if the checker refuted a *Bool* and named the law -- a Bend type error prints the same words.
- **Independent re-check**: **924,672 cells** of the Bend certificate compared against the Python
  reference model, every law re-evaluated on the states Bend produced, 0 mismatches; concrete
  reachability 804 states per instance, all inside the invariant.
- **Adversarial mutation**: **72 of 73** defects killed, judged against the specification's
  constants (`pymodel/spec_consts.py`), not the model's. 62 of them were written by two independent reviews whose
  brief was to break the law set, 11 target the constants and the oracle itself; the single survivor is an
  *equivalent* mutant whose transition relation differs from the model's on 0 of 924 672 cells. `run.py all --full` also records how many laws catch each mutant; in the last full run 37 fell to a single law (10 of
  them only to the two concrete-layer laws): declared weak points.
- **Tightness**: on a fixed, reproducible sample of 400 reachable cells, the law set pins the next control state
  uniquely on **99.3 %** of them (1.01 admissible of 10 752).
- **Differential testing**: 8 planted defects × 3 instances × 2 generators, fixed seed; 26 of
  27 defective configurations found, no false positive on the clean ones; the 27th (the communication-fault bug in
  the instance that masks that check) is unobservable by construction and declared as such by the gate.
- **Sensitivity**: the urgency order between the two soft responses -- the model's one free choice -- is a
  parameter; every law is proved for both orders.
- **Reproducibility**: `py -3.14 v3/run.py quick` in about 30 s, `all` in about 37.3 min; `results.json`,
  `recheck.json` and `SHA256SUMS` are the committed reference run with a provenance block (tool versions, the
  pinned Bend commit, the seed, the SHA-256 of every input).

## 4. Reproduce

```bash
bash env/check_env.sh          # toolchain + 13 checks, Bend 2.0.24 pinned (bun, node, Python 3.14, JAX f64)
py -3.14 v3/run.py quick       # the case study in < 1 min (the CI gate); `--help` lists the stages and their times
py -3.14 v3/run.py all         # everything (~7 min): proofs, smoke, 10 negatives, re-check, 73 mutants, differential testing -> v3/results.json + SHA256SUMS
py -3.14 v3/recheck.py         # only the Python-side gates (C2 vacuity, C3 sensitivity, C5 re-check, C6 mutants)
py -3.14 v2/seq3/run.py        # the sequencer exercise
py -3.14 v2/heat/run.py        # the heat exercise
```
Everything runs on Windows without a native toolchain (Bend on the JS backend through `env/bend.sh`); Linux/macOS work
the same. Pinned versions: `env/SETUP.md`. Python: `py -3.14 -m pip install -r requirements.txt`. The Bend compiler itself is not vendored: `env/bend.sh` fetches the pinned commit (2.0.24), refuses any other checkout, and `env/SETUP.md` records the commit, the tree hash and what to do now that the upstream GitHub repository answers 404 (`BEND_SRC` to a checkout of that commit, or `BEND_BIN` to the official installer's binary).

## 5. The method in seven moves

1. **Finite control + counter commands.** The control state is a product of small enumerations; the counters never
   enter the control, only their *verdicts* (Booleans) do, and the control answers with commands (`Keep/Reset/Inc`).
2. **Certificate by computation.** Every property of one cell (order, control state, event, verdicts) is a Boolean;
   the conjunction over the whole domain is one `{==}` for the checker.
3. **Reflection.** One small lemma per quantifier level turns `check == True` into universal statements; the only
   inductions left are one generic counter lemma and the trace induction.
4. **Configuration as event payload.** The laws are proved for every configuration; the published instance enters
   through conformance laws, one per cell, separated into published and assumed.
5. **Laws that demand, not only laws that forbid.** A set of laws that only says what cannot happen is satisfied by
   the model that does nothing. Half of this repository's laws exist because an adversarial review built that model
   and made it pass.
6. **Measure the law set, not the number of laws.** The honest measure is how tightly the laws pin the next state,
   and a mutation score is worth only as much as the bank is adversarial. Both metrics are gates here.
7. **Everything under law is judged by the checker; everything outside is judged by a second implementation** —
   cell-by-cell re-check, vacuity and tightness gates, the mutation bank, and differential testing against an
   implementation written from the prose.

## 6. Limits (the short list; the long one is in `v3/docs/fase3-seguridad.md` §4)

No timing, no liveness, no hardware failure, no lost or malformed messages, no plant model behind the
acknowledgements, no independence claim between the software and hardwired layers, no secondary stop matrix (not
published), the DMV current threshold out of scope.

And the limit that cost this project two rounds of work, stated plainly because it generalises: **a model that ignores
every event satisfies a safety theorem.** An earlier version of this repository claimed that the vacuity gate and the
conformance laws distinguished it from such a model. They did not: an adversarial review built a degenerate model —
ignore every stop not wired to the DMS, trip instead of ramping, never count the watchdog, never accept the end of
pulse — and it passed the laws *and* the vacuity gate together. What actually distinguishes the model is the 29 demand
and frame laws written in response, and the two measures that can see the difference: the tightness of the law set and
a mutation bank written by reviewers whose brief was to break it.

## 7. How this was made (authorship)

The specifications, the models, the laws and the proofs were written by an AI system (Claude, Anthropic) directed and
audited by a human author; the proof checker (Bend 2) is the judge of every claim under law; the adversarial reviews
were automated passes by other instances of the same model family — **they are not independent assessment in any
regulatory sense, and no human independent assessment has been performed**. The human decided the scope, the sources,
the hypotheses and what counts as closed. The findings of the five adversarial rounds are recorded in `v3/docs/fase3-diseno.md` §9, including the three that changed the law set itself (§9b) and the lessons about the method (§9c).

## 8. Sources

Stephen et al., ICALEPCS 2011, FRAAULT04 (CC BY 3.0) · Waterhouse et al., Fusion Eng. Des. 210 (2025) 114737 (CC BY 4.0) ·
Edwards et al., Fusion Eng. Des. 146 (2019) 277 · Alves et al., ICALEPCS 2011, WEPMN014 (CC BY 3.0) · Reux et al.,
Fusion Eng. Des. 88 (2013) 1101 · Stuart et al., Fusion Eng. Des. 168 (2021) 112412. Full records and licences:
`v3/docs/fase3-fuente.md` §2 and `v3/docs/sources/NOTICE`.

## 9. Name (not decided)

Candidates: **cerrojo** (Spanish: bolt, latch — an interlock), **veredicto** (verdict, the idiom the proofs use: a
verdict with its evidence), **latchproof**, **finlock**.

## 10. Licence

Apache License 2.0 (see `LICENSE`, `NOTICE`). Third-party papers under their own CC BY licences (`v3/docs/sources/NOTICE`).
