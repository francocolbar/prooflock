# Verified reference models for machine-protection logic: a case study on the JET wall-protection chain

> **Note (2026-09-21, updated 2026-09-23).** The numbers in this draft correspond to the version of 2026-09-19 (2 688
> states, 64 + 117 laws, 61/62 mutants). The revision of blocker 4 (`docs/STATUS_2026-09-21.md`: two views of time,
> partial power, masks, DMV threshold) changed the model to 10 752 states, 75 + 137 laws, 8 soundness lemmas and 2
> bounded response theorems (222 laws); revision 4 of the assumption register (2026-09-22) then brought the laws to
> 81 + 143 (234 with the 8 + 2) and the bank to 76 mutants. The current numbers are in `README.md` §3 and in
> `v3/results.json`. This draft will be rewritten with them before the preprint. On 2026-09-23 some statements below
> were made precise without touching the numbers: what does not grow with the control is the proof text, not the
> checking time; a negative test is rejected as a refuted `Bool` at a cell the test supplies, not with a
> counterexample the checker searches for; the re-check re-evaluates the laws as re-encoded in Python; the mutants are
> defects of the Python reference model, judged by those Python laws; and the 26 demand and frame laws (29 with the
> three V1 laws) came from two adversarial passes (§3.4).


**Preprint draft, revision 1 (2026-09-19).** The working language was Spanish; the draft is now kept in English
(translated 2026-09-22), and the arXiv version (cs.SE / cs.LO, with cross-list to physics.plasm-ph) is produced from it
at closing. The numbers in this version come from `v3/results.json` and `v3/recheck.json`; the citations [S1]–[S7] are those of `v3/docs/phase3-sources.md`.

## Abstract

We present a method for writing the discrete logic of a machine-protection system as a total, executable model whose
properties are proved with a proof checker for every sequence of events and for every configuration, and for using
that model as a reference oracle against the real implementation. The technical idea is to split the state into a
finite control and counters governed by commands, to decide every property of the control by computation over the
whole domain —a certificate of 104 832 cells per urgency order that the checker evaluates in seconds— and to lift the
result to universal laws by reflection, so that the proof text does not grow with the size of the control (the
checking time does, with the number of cells). We apply it to a reconstruction, from open publications, of the *Stop
Selector* of the JET Real-Time Protection Sequencer, its interface with the Pulse Termination Network and the arming
of the disruption mitigation system: 2 688 control states, 24 event variants, 64 proved laws —including the theorem
that no trace leaves the safe set, for any configuration matrix and for both possible urgency orders— plus 117 laws of
conformance with the published configuration.

The result we consider most transferable is not the case study but a negative methodological finding. A set of safety
laws —properties of the form "nothing bad happens"— **is satisfied by the model that does nothing**, and no amount of
laws or of certified cells reveals that. An adversarial review built that degenerate model against our first version
and made it pass, together with the vacuity gate we had written precisely to detect it. The answer, over that review
and a second adversarial pass, was 26 demand and frame laws (29 with the three V1 laws), and two measures that do see
the difference: the **tightness** of the law set (how many of the 2 688 next states they admit, on average: 15 before,
1.1 after) and an **adversarial mutant bank** written by reviewers whose brief was to break it (defects of the Python
reference model, judged by the laws re-encoded in Python; 21 of 37 defects detected before, 61 of 62 after; the only
survivor is equivalent by exhaustive comparison in Python, not by a checked proof). A mutation score against a bank
written alongside the laws gave 17 of 17 from the start and distinguished nothing.

The evidence is completed by ten negative tests that the checker rejects by refuting a `Bool` at a cell the test
supplies —including one that asserts the false certificate, to show that it is computed and not skipped—, a
cell-by-cell re-check of the certificate in another language (a re-execution, not an independent implementation), and
differential testing against an implementation with six planted defects. The modelled function is investment
protection, not a nuclear safety function; the evidence is about a specification, not about a system, and supports no
SIL claim. We discuss what the trace theorem does and does not establish in terms of IEC 61508. The specifications,
the models and the proofs were written by an AI system directed and audited by a human author, with the checker as the
judge of every claim under law; the five rounds of adversarial review were also automated and do **not** constitute
independent assessment.

## 1. Introduction

*(To be written in the final version; here the argument.)* The machine-protection systems of the large fusion
experiments (JET, ASDEX Upgrade, KSTAR, ITER) combine a hard-wired layer of fixed sequence with a programmable layer
whose response logic is configured per pulse. The published evidence of their validation consists of case-based
behavioural tests: [S3] describes 71 *pulse schedules* as tests of the JET RTPS, and [S6] documents 5 + 4
disruptions missed in 2011–2012 because of inhibits and a wrongly set valve window, and 7 more detected only below
the valve's minimum current because the first thermal quench went undetected. The combinatorics of
phases, triggers, arrival order, communication faults, watchdog and counters exceeds any case-based test set by orders
of magnitude, and the matrix changes per pulse. Fusion power plants and the nuclear industry in general will have to
present evidence of the systematic capability of this software to a regulator; the question is what form that
evidence can take so that it is exhaustive over the logic, cheap to redo per configuration, and honest about what it
does not cover.

## 2. Method

### 2.1 Finite control and commands to counters

The state is `St = Fin × ℕ × ℕ`, with `Fin` a product of enumerations (phase, response in progress, DMS sequence,
plasma conditions, two heating units) and two counters (cycles without heartbeat, cycles waiting for the DMS
acknowledgement). The counters never enter the control: their *verdicts* do (`1 + n < limit`, two booleans) and the
control answers with commands `Keep | Reset | Inc`. Every decision is therefore finite.

### 2.2 Certificate by computation and reflection

For each cell (urgency order, control state, abstract event, verdicts) the next state is computed once and, on it,
the preservation of the invariant, the "shapes" of the commands to the counters and the 48 step laws are evaluated.
The conjunction over the domain —2 688 states × 39 columns = 104 832 cells per order— is a single equality
`check_fin(o) == True` that the checker decides by normalisation. A ladder of lemmas, one per quantification level,
extracts the arbitrary cell from that boolean; the projections give each law; a generic counter lemma gives the
counter invariants for every value; induction on the trace gives the theorem. The proof cost is almost constant in the
size of the control: adding an event or a state adds one arm to a level lemma.

Two implementation details that are not details. **First**, the counter verdicts are enumerated only in the five
columns where the checker cannot discard them symbolically; that the other nineteen do not read them was an assumption
checked once by hand, and is now a proved law. **Second**, the ladder does not project from the whole certificate but
from 56 slices decided by computation, because the checker compares complete normal forms: naming the certificate in
a type costs evaluating it on both sides of the comparison (§4).

### 2.3 Configuration as event payload

The phase × trigger → response matrix and the DMS connection are not inside the step: the abstract alphabet carries
the requested response and the DMS bit in the event, and a concrete layer maps the plant alphabet through a
configuration instance. The laws then hold for every configuration; the published instance enters through 117
conformance laws —one per cell, separated into published (28, of which 15 printed and 13 read from "idem" marks)
and assumed (21)—, plus two laws on the concrete layer: that `concretize` is the configuration value by value, against
a literal transcription of the matrix, and that `step_c` uses it with the correct instance, order and phase.

### 2.4 What the checker judges and what another implementation judges

Everything under law is decided by the checker. What cannot be under law —that the laws are not vacuous, that the
certificate is computed, that the model matches the prose, that the real implementation matches the model— is decided
by a second implementation in another language: cell-by-cell re-check of the 209 664 cells of the certificate,
re-evaluation of the laws, re-encoded in Python, over the next states produced by the verified model, abstract and
concrete reachability, count of cells where the hypothesis of each law holds, the tightness metric, the mutant bank,
and differential testing against a production implementation with planted defects.

**A caveat about that second implementation, because we described it wrongly.** Ours was written after the verified
model and with it in view: it is a **re-execution in another language**, not an independent N-version implementation,
and that is how what its agreement demonstrates must be read (it protects against evaluator errors, not against a
shared misunderstanding of the specification). An audit detected this from textual evidence —our "independent" model
contained a law that the design document does not mention— and wrote a transcription from the document (the same model
family, not kept in the repository) that agreed on every reachable cell.

## 3. Case study: the JET wall-protection chain

### 3.1 Source and scope

[S1] publishes the *Stop Selector* of the RTPS: seven phases, seven triggers, three responses (PTN, RTPS stop, JTT),
Table 1 (an example configuration, "the primary stops table"), primary/secondary response, local protection, blind
alarms and watchdog. [S2] adds the latching of the PTN output, the DMS sequence (switch off heating → acknowledgement
or timeout → inject), the escalation hierarchy and the enable windows. [S6] adds the rule that "the triggering of the
DMV can be attached to any of the stops sent to the Plasma Termination Network (PTN)", the DMV window and thresholds,
the timings (NBI 2 ms, RF 38 ms, 50 ms in total, no RF acknowledgement) and the record of missed disruptions. The Stop
Selector is modelled with its interface to the PTN and the arming of the DMS; **not** the Stop Manager (the override
waveforms to the five actuators), nor the CISS/PSACS safety layers. Sixteen textual requirements (R-0…R-15) and
twenty-three declared hypotheses (A-1…A-23) with their direction of conservatism are in the supplementary material.

### 3.2 Model and laws

*(Details in `v3/docs/phase3-design.md` §2.)* The invariant has six clauses: a unit at full power is in the enable
window, with plasma conditions and no stop in progress; a unit in ramp-down is under a soft stop or in the termination
and never under PTN; a JTT in progress implies termination phase; the DMS is only armed or fired under PTN; the wait
for the acknowledgement and the cycles without heartbeat are bounded. Twenty-one step laws say what cannot happen
—stops do not degrade, the step that reaches the PTN de-energises, no order switches anything on with a stop in
progress, the DMS is armed only on a demand, under PTN the programme does not advance— and twenty-six demand and frame
laws (twenty-nine with the three V1 laws, which make the certificate's reduced verdict domain a theorem) say what has
to happen: a stop request is honoured, a soft stop ramps the heating, the watchdog latches regardless of how the DMS
is wired, a heartbeat always resets its counter, the end of pulse is accepted when appropriate, and each command
touches its own and nothing else. The theorem `traces_safe` covers every trace over the abstract alphabet —that is,
for any configuration— and its concrete corollary, the two certified instances.

### 3.3 Results

| Artefact | Result |
|---|---|
| Certificates (`finite_check`, `finite_check_alt`, `corollaries_check`) | 104 832 cells per order + 2 688 states; 14–19 s and 0.3 s in the checker |
| Laws by reflection and induction | 64 in `PROOF_JETPROT.bend` (1 034 lines of code), 143 s |
| Configuration conformance | 117 laws, `{==}` per cell, 0.3 s |
| Negative tests | 10/10 rejected, each as a refuted `Bool` at a cell the test supplies (not a searched counterexample); the gate requires that the checker refute a `Bool` **and** name the law |
| Re-check in Python (a re-execution) | 209 664 cells Bend = Python; 0 mismatches; concrete reachability 921 states, all in the invariant |
| Vacuity and **tightness** | no vacuous law; 374/400 reachable cells with a unique successor (93.5 %), 1.1 admissible out of 2 688 |
| Sensitivity | 2 688 cells differ between the two urgency orders, 168 reachable; all laws hold in both |
| **Adversarial mutation** | **61/62** defects of the Python reference model, judged by the laws re-encoded in Python; the only survivor differs from the model in 0 cells (equivalent). The bank written alongside the laws: 17/17, reported as the weak measure |
| Differential testing | 6 defects × 2 instances × 2 generators: 14/16 defective configurations detected, 0 false positives; the guided generator finds them all with traces of 2–10 events, the random one misses several in 3 000 |
| Full gate | `py -3.14 v3/run.py` → `all gates and checks ok: True`, ≈ 5–6 min |

### 3.4 What the reviews found

Five adversarial rounds, three on the design before writing code and two on the already-proved law set.
The first ones found an unreachable state field with its vacuous law, an invariant that was not inductive along three
paths, a false step law on unreachable cells (twice, because it is natural to write "X(s′) implies Y(s′)" where the
correct form is "not X(s) and X(s′) implies Y(s′)"), a subsystem constrained only negatively, the main hazard of the
source without any law, and an infidelity to the source: the JTT *ramps* the heating, it does not cut it.

The last two are the ones that matter for the method, and neither is a transcription error.

**The law set was entirely negative.** A review built a degenerate model —ignore every stop not wired to the DMS,
cut instead of ramp, never count the watchdog, never accept the end of pulse— and made it pass: the laws **and** the
vacuity gate we had written to detect exactly that. Of 37 plausible mutants, 16 survived. The answer was 18 demand
and frame laws.

**The demand laws left eight holes**, and a second pass with 25 new mutants broke them again: 11 survived. The three
worst: nothing required a heartbeat to reset the watchdog counter (one law framed the control and the other counter
and forgot that one); the counter could run past its limit without any law seeing it, because the step that would
have exposed it latches the PTN and empties every hypothesis; and nothing constrained the concrete layer, so that
always reading the matrix of the first instance silently disabled the reason for the second one to exist **without
changing the reachable set**, whereby the trace theorem was blind. Eleven more laws.

Two **self-referential** laws also appeared —one wrote the end-of-pulse guard by calling the model's own guard, and
was therefore satisfied by any guard; another compared the concrete layer against an expectation built with the same
table— and a coverage metric that was **zero by construction**.

## 4. Measured costs

| | Phase 2 (`seq`) | Phase 2b (`seq3`) | Phase 3 (`v3`) |
|---|---|---|---|
| Model (lines of code) | 323 | 425 | 1 116 |
| Enumerator / certificates | 106 | 223 | 446 |
| Laws | 12 | 9 + 1 | 64 + 117 |
| Proofs (lines of code) | 1 593 | 323 | 1 034 + 330 |
| Certificate cells | 1 792 × 18 | 448 × 18 × 4 | 2 688 × 39 × 2 |
| Checker time per certificate | 5.5 s | 34 s | 14–19 s |
| Prover iterations | 2 + 4 + 2 | 5 | 6 (demand laws) + 18 (round 3), none of logic |
| Errors while writing the model | — | — | 9, all of syntax or linearity; 0 false cells in the previous instantiation |

Two cost observations that hold for whoever repeats the method. **First**: the pattern of the previous phase does not
scale as is. Bend compares complete normal forms, with no syntactic shortcut, so projecting from the whole certificate
with symbolic arguments forces the checker to normalise it on both sides of each comparison; measured, a single delta
step to a syntactically identical term cost 8.6 s, and the literal ladder of the previous phase would have cost
between 15 and 30 minutes. Slicing the certificate into 56 pieces decided by computation brings it down to minutes and
weakens nothing: the 56 slices *are* the certificate, cell by cell. **Second**: adding laws to the certificate costs
checker time, not proof lines. The 18 demand laws took the proof from 83–113 s to 140–160 s; the 9 of round 3 did not
move it measurably. The reflection ladder did not change in either of the two rounds.

## 5. Limits of the evidence

See `v3/docs/phase3-safety.md` §4: no real time, no unbounded liveness (since 2026-09-21 bounded response in
watchdog and DMS ticks is proved over traces: `LAWS_JETPROT_LIVE.bend`), no hardware faults, no lost or malformed
messages, no plant model behind the acknowledgement, no independence between layers, JET's secondary table only as
an illustrative instance (A-35), the DMV enabling condition only as a Boolean verdict (A-22), no bypass of PTN inputs. **A model that ignores every event also satisfies the trace theorem.**
An earlier version of this work claimed that the vacuity gate and the conformance laws already distinguished it from
such a model; that was false, and it is the finding of §3.4. What distinguishes it are the 26 demand and frame laws
(29 with the three V1 laws), the tightness metric and the adversarial mutant bank. Comparison with published practice
([S3]: 71 behavioural tests + commissioning + operating experience): the tests give evidence about the real system;
the model gives coverage over the logic, per configuration, in minutes. It does not replace commissioning, FAT/SAT,
timing analysis or independent assessment.

## 6. Authorship and how it was done

The specifications, the models, the laws, the proofs and the adversarial reviews were produced by an AI system
(Claude, Anthropic; Opus 5 and Fable 5.1 instances) directed by a human author who decided the scope, the sources,
the hypotheses and what counts as closed, and who audited the results. The proof checker (Bend 2.0.6, JS backend)
is the judge of every claim under law: the AI can make mistakes when writing, and it did (see §3.4); what the
method guarantees is that no mistake in the layer under laws passes silently. The automated reviews do **not**
constitute independent assessment in the regulatory sense and there was no independent human assessment; before
the final version the reconstruction will be sent to the authors of [S1]/[S2] for a reading of factual accuracy.
All the material is reproducible from the repository (Apache 2.0) on a Windows machine with no native
toolchain.

## 7. Future work

Commanded vs. reported state of the units (to verify the R-11 acknowledgement as a sequence); well-formedness laws
for configurations and certification of the rule instead of the instance;
cross-check of the certificate and of the two response bounds in nuXmv or TLA+/Apalache;
a second case study outside fusion (research reactor or detritiation plant) with the same method.

## References

[S1]–[S7] as in `v3/docs/phase3-sources.md` §2; IEC 61508-3:2010; IEC 61513:2011; Alpern & Schneider, *Defining
liveness* (1985); the repository of this work.
