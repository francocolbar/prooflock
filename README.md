# prooflock — verified reference models for machine-protection logic

*A case study on the JET wall-protection chain (RTPS Stop Selector + PTN + DMS arming), built with Bend 2.*
Spanish version: [README.es.md](README.es.md).

## 1. What this is, in one paragraph

A method for writing the discrete logic of a protection system (interlocks, stop sequencers, permissives) as a
**total, executable model** whose safety properties are **proved for every trace and every configuration** by a proof
checker, and then using that model as a **reference oracle** against the real implementation. The proofs are cheap to
write because the state is split into a finite control and a few counters driven by commands: every property of the
control is decided by computation over the whole domain (a *certificate*) and lifted to universal laws by reflection,
so the proof text does not grow with the size of the control. The checking time does: the checker evaluates every cell
of the certificate (924 672 for the two urgency orders here), and `PROOF_JETPROT_LIVE.bend`, which imports the
certificates, took 795.8 s on the serial path and 1 221.9 s beside the Python stages (§3). This repository contains
the method's base (a proven numeric base, a proven linear IR), two internal exercises, and one public case study: a
reconstruction, from open publications, of the JET Real-Time Protection Sequencer's stop logic and its interface to
the Pulse Termination Network and the Disruption Mitigation System.

**What it is not.** The modelled function is *machine protection* (investment protection), not a nuclear safety
function; the evidence is about a *specification*, not about a system; it contributes to a systematic-capability
argument (IEC 61508-3 tables A.1/A.2/A.9) and supports no SIL claim by itself; 28 of the 56 cells of the certified
configuration matrix (21 in columns the paper does not show, plus the 7-cell blind-alarm row) are our hypotheses because
the published table shows 28, and the secondary stop table of the fourth instance is illustrative. All of this is written
down before the results, in `v3/docs/phase3-safety.md`.

**New here?** [`v3/docs/JET_LAWS_EXPLAINED.md`](v3/docs/JET_LAWS_EXPLAINED.md) is a from-scratch, plain-English
walkthrough of the whole case study: why prove instead of only test, what JET's protection chain actually does, how
to read a Bend law, and what every one of the 234 laws says and where it comes from (published fact vs. our
declared assumption). It assumes nothing beyond general background — read it before the law files themselves.

## 2. Layout

| Path | What | Status |
|---|---|---|
| `env/` | the Bend runner pinned to one commit (`env/bend.sh`, refuses any other checkout), 13 toolchain and hello-world checks | `bash env/check_env.sh` |
| `v3/` | **the case study**: model, certificate, laws, proofs, negative tests, bridge, production implementation with planted bugs, Python re-execution of the certificate (C5), gate, run comparator (`compare_runs.py`) | `py -3.14 v3/run.py` |
| `v3/docs/` | sources and quotations (`phase3-sources.md`), design and laws (`phase3-design.md`), hazards / safety requirements / limits of evidence (`phase3-safety.md`), traceability (`phase3-traceability.md`), CC BY copies of the source papers (`sources/`); evaluation of the assumptions against the code, the JET sources and the physics (`SUPUESTOS_EVALUACION.md`); law catalogue, code-level (`LEYES_CATALOGO.md`) and plain-language (`LEYES_CATALOGO_ACCESIBLE.md`, and `JET_LAWS_EXPLAINED.md` in English) | English: `phase3-*.md`, `JET_LAWS_EXPLAINED.md` (plain-language walkthrough of all 234 laws); Spanish: `SUPUESTOS_EVALUACION.md`, `LEYES_CATALOGO.md`, `LEYES_CATALOGO_ACCESIBLE.md` |
| `v2/num/` | proven numeric base: canonical integers with the full commutative ring (22 laws), big naturals as bit lists with a proven adder, big integers | reusable |
| `v2/heat/` | proven linear IR + exact oracle for a 1-D heat stencil (the first exercise) | `py -3.14 v2/heat/run.py` |
| `v2/seq/`, `v2/seq3/` | a tokamak discharge sequencer with 6 machine-protection invariants proved for every trace; `seq3` is the redesign that made the proofs cheap (1593 → 323 lines) | `py -3.14 v2/seq3/run.py` |
| `docs/`, `heat/` | the first (historical) round of the spike, its closing report (`docs/spike-2026-09-18.md`) and the preprint draft (`docs/preprint-draft.md`) | history |

## 3. The case study (v3) in numbers

Revised 2026-09-21 (fidelity to [S1]/[S2]/[S6], `docs/STATUS_2026-09-21.md` blocker 4): the program phase and the
termination waveform are two views of time, a local alarm reduces a unit instead of inhibiting it, the DMV arming
verdict (then read as plasma current alone) gates the arming of the DMS, and the two reliability checks pass through
per-instance masks. Revised again 2026-09-22 (revision 4 of the assumption register, `v3/docs/phase3-sources.md` §4;
evaluation in `v3/docs/SUPUESTOS_EVALUACION.md`): what P1 and D1 say about the PTN and the primary stop is stated in
five named laws, apart from our policy between the two soft stops (two restate JET sources, mainly De Tommasi et al.
2013, [N1]; three join a JET statement with our declared formalisation), the DMV arming verdict is read as plasma
current OR stored energy above threshold (A-22; the code and the laws did not change), and an alarm that arrives
during a stop reads a per-instance secondary table (a fourth, illustrative instance was added). On 2026-09-23 the Bend
pin moved to 2.0.25, the gate learned to run its stages in parallel (`--jobs`, §4), and the mutation gate computes the
equivalence of its one surviving mutant instead of accepting it by name; every count below is the same as in the run
of 2026-09-22.

- **Model**: 10 752 control states (program phase × waveform flag × response × DMS × plasma × DMV arming verdict × two
  units at Off / Ramping / Reduced / On) × 28 abstract event variants (the configuration travels as event payload) +
  2 counters. A concrete alphabet of 24 plant events reaches it through four configuration instances: Table 1 of
  Stephen et al. 2011 as published, the same with mode lock routed to the PTN (our reading of the path [S6]/[S7]
  describe), the published table with both reliability checks masked out, and the published table with an
  **illustrative** secondary table (during a stop, PTN for any alarm whose primary entry asks for a response, none
  otherwise, so a mode-lock alarm, which the published table leaves unanswered, still gets no response; JET's
  secondary table is unpublished, A-35).
- **Certificate**: 43 columns × 10 752 states = **462 336 cells per urgency order**, both orders, decided by the
  checker (`PROOF_JETPROT_LIVE.bend`, which imports the reflection proof and the certificates, took 795.8 s on the JS
  checker in the serial run of 2026-09-22 and 1 221.9 s beside the Python stages in the parallel reference run of
  2026-09-23); plus a 10 752-state certificate for the state corollaries and a 5 376-cell one for the concrete layer
  (4 instances × 7 phases × 2 × 4 levels in force × 24 events: the level selects the primary or the secondary table).
- **Laws**: **81** (`LAWS_JETPROT.bend`) + **143** conformance laws + 8 soundness lemmas + 2 bounded-response
  theorems = 234, all `All terms check.` Six invariant clauses, the step laws saying what cannot happen, the demand
  and frame laws saying what must happen, thirteen fidelity laws (two views of time, partial power, masks, the DMV
  arming verdict -- current OR stored energy above threshold, A-22 -- and the two frames the tightness metric asked
  for), five laws that name what P1 and D1 say about the PTN and the primary stop, apart from our soft-over-soft
  policy (`p1a_ptn_latched` and `d1b_primary_honoured` restate JET sources; `d1a_ptn_honoured`,
  `p1b_stop_never_cleared` and `piw_after_ptn_is_noop` join a JET statement with our formalisation), the trace theorem
  for the abstract and the concrete alphabets, the configuration cell by cell (28 published cells + 21 assumed + the
  blind row, kept apart), the secondary tables and the fourth instance (seven laws), and two response theorems over
  traces: `hb_max` ticks without a heartbeat latch the PTN, an armed DMS fires within `ack_max` ticks -- checked for
  the model's limits (`hb_max` = 3, `ack_max` = 2); the induction only compares them with tick counts and counters, so
  the argument should carry over to other limits, but only these two values are checked. Twelve of them are derived
  from the others (`DERIVED` in `v3/pymodel/jetprot_laws.py`): they are kept as named statements and not counted as
  independent evidence.
- **Negative tests**: **12** false statements the checker must reject. Eleven evaluate a predicate at a witness cell
  written into the test (ten on a buggy variant of the step, one a false law on the correct model); one (negative 8)
  claims the certificate is `False`. The checker answers with the refuted *Bool* and the name of the law
  (`expected`/`observed` `True{}`/`False{}`): a failing instance that the test supplies, not a counterexample the
  checker searched for. The gate accepts a rejection only if the checker refuted a *Bool* and named the law -- a Bend
  type error prints the same words.
- **Re-check in Python** (a re-execution in another language, not an independent implementation:
  `v3/docs/phase3-design.md` §9a H23): **924 672 cells** of the Bend certificate compared against the Python reference
  model, the 62 cell checks of the Python oracle (`LAWS` in `v3/pymodel/jetprot_laws.py`) re-evaluated on the states
  Bend produced, 0 mismatches; concrete reachability 804 states in each of the three base instances and 744 in the
  fourth, all inside the invariant.
- **Adversarial mutation**: **75 of 76** defects of the Python reference model killed, judged by the laws rewritten as
  Python predicates (`v3/pymodel/jetprot_laws.py`), which read the specification's constants
  (`pymodel/spec_consts.py`), not the model's, plus one check that the model's invariant is the specification's. The
  Bend checker takes no part: the score measures the Python copies of the laws, and a Bend law weaker than its copy,
  or one without a copy (`TODO.md`), would not show in it. 62 of the defects were written by two separate automated
  reviews (§7) whose brief was to break the law set, 11 target the constants and the oracle itself, 3 the secondary
  table; the single survivor is an *equivalent* mutant whose transition relation differs from the model's on 0 of
  924 672 cells, whose step with the counters differs on 0 of 12 042 240 cells with concrete counter values and whose
  `concretize` differs on 0 of 1 032 192 (instance, control state, plant event) cells (computed by the gate, C6
  `equivalence`, which accepts a survivor only if it differs on no cell). `run.py all --full` also records how many
  laws catch each mutant; in the committed run 31 fell to a single law or check (11 of them only to the two
  concrete-layer laws, and M72 only to the invariant check): declared weak points.
- **Tightness**: on a fixed, reproducible sample of 400 reachable cells, the law set pins the next control state
  uniquely on **99.3 %** of them (1.01 admissible of 10 752), and the counter commands on 243 of them (212 before
  revision 4: the law `piw_after_ptn_is_noop` is new evidence for the counters).
- **Differential testing**: 9 planted defects × 4 instances × 2 generators, fixed seed (88 runs with the clean and
  the all-defects configurations); 35 of 40 defective configurations found, no false positive on the clean ones; the
  other 5 are unobservable by construction and declared as such by the gate: the communication-fault defect in the
  instance that masks that check, the ignored-secondary defect in the three instances whose secondary is the primary,
  and a de-escalation in the fourth instance, where every alarm during a stop asks for PTN or nothing.
- **Sensitivity**: the urgency order between the two soft responses -- the model's one free choice -- is a
  parameter; every abstract law is proved for both orders; the concrete layer and the configuration are certified
  under the chosen order (`Ord1`, A-1).
- **Reproducibility**: `py -3.14 v3/run.py quick` in about a minute (34–87 s in the runs of 2026-09-23); `all --full`
  in 1 222.4 s (about 20 min) with the default `--jobs` on the reference machine (2026-09-23, Bend 2.0.25) and in
  7 305.5 s (about 122 min) on the serial path, `--jobs 1` (2026-09-22, Bend 2.0.24); per-stage times in §4.
  `results.json`, `recheck.json` and `SHA256SUMS` are the committed reference run of 2026-09-23, with a provenance
  block (tool versions, the pinned Bend commit, the seed, the number of parallel jobs, the SHA-256 of every input);
  `v3/compare_runs.py` compares two runs leaf by leaf.

## 4. Reproduce

```bash
bash env/check_env.sh          # toolchain + 13 checks, Bend 2.0.25 pinned (bun, node, Python 3.14, JAX f64)
py -3.14 v3/run.py quick       # a smoke test of the case study in about a minute (meant for CI; none is configured yet)
py -3.14 v3/run.py all --full  # everything, as in the committed run: proofs, smoke, 12 negatives, re-check, 76 mutants and the laws that catch each, differential testing -> rewrites v3/results.json, v3/recheck.json + SHA256SUMS
py -3.14 v3/compare_runs.py v3 OLD   # this run against another one (a results directory or a repo root), leaf by leaf
py -3.14 v3/recheck.py         # only the Python-side gates (C2 vacuity, C3 sensitivity, C5 re-check, C6 mutants); rewrites v3/recheck.json without a provenance block
py -3.14 v2/seq3/run.py        # the sequencer exercise
py -3.14 v2/heat/run.py        # the heat exercise
```
`quick` checks `PROOF_JETPROT_CONF.bend` and `PROOF_JETPROT_SOUND.bend` (the 143 + 8 laws), one negative test, the
runtime smoke and 2 differential runs; the 81 + 2 laws of `LAWS_JETPROT.bend` and `LAWS_JETPROT_LIVE.bend` and the
certificates are checked only by `proofs` and `all`, through `PROOF_JETPROT_LIVE.bend` (§3). `run.py --help` lists the
stages. `all` rewrites `v3/results.json`, `v3/recheck.json` and `SHA256SUMS` in place (the new `SHA256SUMS` matches
the new files); `recheck.py` rewrites `v3/recheck.json` alone, without the provenance block (and, without `--full`,
without the per-law census), so `sha256sum -c SHA256SUMS` then fails on it. To compare a new run with the committed
one, keep a copy of the committed files first
(`mkdir ../prooflock-ref && cp v3/results.json v3/recheck.json ../prooflock-ref/`), then run
`py -3.14 v3/compare_runs.py v3 ../prooflock-ref --list`; `git restore v3/results.json v3/recheck.json SHA256SUMS`
brings the committed run back.

Everything runs on Windows without a native toolchain (Bend runs from its source checkout with bun through
`env/bend.sh`, and the bridge loads the model into node with Bend's JS backend). The scripts are written for Linux and
macOS too, but no run there is recorded yet: use `python3.14` where this README says `py -3.14`, and
`PY=python3.14 bash env/check_env.sh`. Pinned versions: `env/SETUP.md`. Python:
`py -3.14 -m pip install -r requirements.txt`. The Bend compiler itself is not vendored: `env/bend.sh` fetches the
pinned commit (2.0.25, tag `v2.0.25`) from github.com/bendlang/bend (github.com/HigherOrderCO/Bend redirects there),
refuses any other checkout, and `env/SETUP.md` records the commit, the tree hash and what to do if the upstream
becomes unreachable again (it answered 404 on 2026-09-21 and has been public again since 2026-09-22): point `BEND_SRC`
to a checkout of that commit, which the whole gate needs (the bridge of the re-check and of the differential testing
loads `bend2/main.ts` from it, and the provenance block records its commit); `BEND_BIN`, a binary from the official
installer (which itself downloads from the GitHub releases of bendlang/bend), is for `bash env/bend.sh` on its own:
`v3/run.py` refuses to start with it set, since its Bend checks would then run on that binary while the bridge and the
provenance block use `BEND_SRC`.

`--jobs N` (`run.py`; `recheck.py` takes it too, for the Python stages; default: the number of logical CPUs minus 4,
12 on the reference machine) runs the stages in parallel: at most 8 Bend checks at a time, `PROOF_JETPROT_LIVE.bend`
first, beside a pool of below-normal-priority Python workers (7 in the committed run) for C5, C2, C3, the mutants and
model flags of C6 and the 88 differential runs. Every result is assembled in the serial order, and `--jobs 1` is
exactly the serial path, kept as the serial reference. On the same model, laws and compiler as the serial run of
2026-09-22, an `all --full --jobs 12` run (1 535.5 s, Bend 2.0.24) gave the same `results.json` and `recheck.json`,
leaf by leaf (6 433 leaves), apart from wall times, run metadata and the hashes of the two gate scripts. The committed
run against the serial one: the same verdicts, counts, census and differential traces over the same 6 433 leaves;
apart from wall times and run metadata they differ only in the Bend version and commit, the hashes of the 17 inputs
edited in between and of the two gate scripts, the hash of the new `v3/compare_runs.py`, the new C6 `equivalence`
field and the descriptions of five mutants whose assumption numbers were corrected. `v3/compare_runs.py` makes that
comparison for any two runs and checks the new run's hashes against the files on disk. `all` without `--full` skips
the per-law census. Measured times, in seconds (reference machine: Windows 11, 8 cores / 16 threads, 32 GB):

| Stage (seconds) | committed run: `all --full`, `--jobs 12`, 2026-09-23, Bend 2.0.25 | serial: `all --full --jobs 1`, 2026-09-22, Bend 2.0.24 |
|---|---|---|
| `PROOF_JETPROT_LIVE.bend` | 1 221.9 | 795.8 |
| `PROOF_JETPROT_CONF.bend` / `PROOF_JETPROT_SOUND.bend` | 1.6 / 0.8 | 0.7 / 0.3 |
| C5, re-check of the certificate | 32.5 | 20.3 |
| C2, vacuity and tightness | 111.0 | 66.4 |
| C6, mutants with the `--full` census | 1 193.0 | 5 884.4 |
| the 88 differential runs, added up | 243.0 | 161.9 |
| **whole gate** | **1 222.4** | **7 305.5** |

In the parallel run the stages overlap: the C6 figure is the time from the start of the stages, every Python stage had
ended by 1 200.6 s, and the gate ended with `PROOF_JETPROT_LIVE.bend`.

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
   the model that does nothing. An adversarial review built that model and made it pass; the 18 demand and frame laws
   D1–D18 answer it, and a second adversarial pass, aimed at their seams, added 8 more (E2–E8, E11) and the three V1
   laws that make the certificate's reduced verdict domain a theorem: 29 laws, 26 of them demand and frame laws (§6).
6. **Measure the law set, not the number of laws.** The honest measure is how tightly the laws pin the next state,
   and a mutation score is worth only as much as the bank is adversarial. The gate fails on any surviving mutant
   that it does not compute to be equivalent; tightness is measured on every run and recorded in `recheck.json`,
   where `compare_runs.py` shows any change, but no threshold fails the gate.
7. **Everything under law is judged by the checker; everything outside is judged by a second implementation** —
   cell-by-cell re-check, the vacuity gate and the tightness measure, the mutation bank, and differential testing
   against an implementation written from the prose.

## 6. Limits (the short list; the long one is in `v3/docs/phase3-safety.md` §4)

No timing, no unbounded liveness (bounded response is proven: `hb_max` ticks without a heartbeat latch the PTN and an
armed DMS fires within `ack_max` ticks, in abstract ticks, not milliseconds), no hardware failure, no lost or
malformed messages, no plant model behind the acknowledgements, no independence claim between the software and
hardwired layers. A new alarm during a stop in progress reads a per-instance secondary table: the three base instances
read the primary table again, at the program phase (which keeps advancing during a soft stop), and keep the more
urgent of the new request and the response in force (the maximum, A-2); a fourth, illustrative instance uses PTN as
the secondary wherever the primary entry asks for a response (inspired by the caption of [N1] Fig. 7, "The preferred
secondary plasma stop is the PTN slow stop", a usage statistic, not JET's table, which is unpublished; A-35); the
freeze of the stop configuration at the primary stop that De Tommasi et al. 2013 describe for the shape controller is
not modelled (A-24, A-30). The heating window and the DMV window are fixed in the model, the same for every instance,
while JET programs them per pulse (A-10, A-27); a local reduction is forgotten if the unit is switched off and on
again (A-34); the DMV enabling condition enters only as a Boolean verdict (current OR stored energy above threshold,
A-22; the numbers are outside the model). What JET publishes about the PTN (a PIW stop, which we identify with the
model's soft stops, never pre-empts a PTN; a PIW request after a PTN is an "invalid task" for the shape controller,
which we formalise as a no-op) is stated in named, proved laws.

And the limit that cost this project two rounds of work, stated plainly because it generalises: **a model that ignores
every event satisfies a safety theorem.** An earlier version of this repository claimed that the vacuity gate and the
conformance laws distinguished it from such a model. They did not: an adversarial review built a degenerate model —
ignore every stop not wired to the DMS, trip instead of ramping, never count the watchdog, never accept the end of
pulse — and it passed the laws *and* the vacuity gate together. What actually distinguishes the model is the 26 demand
and frame laws (29 with the three V1 laws) written in response to it and to a second adversarial pass (§5, move 5),
and the two measures that can see the difference: the tightness of the law set and a mutation bank written by
reviewers whose brief was to break it.

## 7. How this was made (authorship)

The specifications, the models, the laws and the proofs were written by an AI system (Claude, Anthropic) directed and
audited by a human author; the proof checker (Bend 2) is the judge of every claim under law; the adversarial reviews
were automated passes by other instances of the same model family — **they are not independent assessment in any
regulatory sense, and no human independent assessment has been performed**. The human decided the scope, the sources,
the hypotheses and what counts as closed. The findings of the adversarial rounds (five over the design and the code, a
sixth on fidelity and the revision-4 assumption review) are recorded in `v3/docs/phase3-design.md` §9, including the
three that changed the law set itself (§9b) and the lessons about the method (§9c).

## 8. Sources

Stephen et al., ICALEPCS 2011, FRAAULT04 (CC BY 3.0) · Waterhouse et al., Fusion Eng. Des. 210 (2025) 114737 (CC BY 4.0) ·
Edwards et al., Fusion Eng. Des. 146 (2019) 277 · Alves et al., ICALEPCS 2011, WEPMN014 (CC BY 3.0) · Reux et al.,
Fusion Eng. Des. 88 (2013) 1101 · Stuart et al., Fusion Eng. Des. 168 (2021) 112412 · De Tommasi et al., preprint
EFDA-JET-PR(13)06 (cited, not copied) · Neto et al., ICALEPCS 2011, MOPMU035 (CC BY 3.0) · Kruezi et al., preprint
CCFE-PR(17)36 · Mayoral et al., arXiv:1309.0948. Full records and licences:
`v3/docs/phase3-sources.md` §2 and `v3/docs/sources/NOTICE`.

## 9. Name

**prooflock** (interlock + proof), decided 2026-09-22. The repository was developed under the working name
*bend-spike*, which the dated documents in `docs/` keep; "verdict with its evidence" stays the idiom of the proofs.

## 10. Licence

Apache License 2.0, copyright 2026 Franco Colombo Barceló (see `LICENSE`, `NOTICE`; cite with `CITATION.cff`).
Third-party papers under their own CC BY licences (`v3/docs/sources/NOTICE`).
