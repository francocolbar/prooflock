# The JET laws, explained from scratch

This document covers exactly the same 234 laws as `LEYES_CATALOGO.md`, but builds up the vocabulary step by step so that everything can be understood with no prior background in fusion or in formal proof. If a term ever feels unfamiliar, it was probably defined a few sections earlier — use the index to jump back.

## Index

0. [What this document is](#0-what-this-document-is)
1. [The problem in one sentence](#1-the-problem-in-one-sentence)
2. [What JET is and what it protects](#2-what-jet-is-and-what-it-protects)
3. [What "proving" something means here](#3-what-proving-something-means-here)
4. [The minimal dictionary](#4-the-minimal-dictionary)
5. [How to read a piece of proof code](#5-how-to-read-a-piece-of-proof-code)
6. [The behavior laws — 81 laws](#6-the-behavior-laws--81-laws)
7. [The configuration-table laws — 143 laws](#7-the-configuration-table-laws--143-laws)
8. [The "protection always arrives on time" laws — 2 laws](#8-the-protection-always-arrives-on-time-laws--2-laws)
9. [The mathematical-plumbing laws — 8 laws](#9-the-mathematical-plumbing-laws--8-laws)
10. [Summary: what's from JET and what's ours](#10-summary-whats-from-jet-and-whats-ours)
11. [Quick glossary](#11-quick-glossary)

---

## 0. What this document is

`prooflock` is a project that takes a real, published protection system — the one on the JET fusion machine, in England — rebuilds its decision logic as a model from JET's open publications, filling every gap with a declared assumption (§3), and mathematically proves that this model satisfies certain rules **in every possible case**, not just the cases someone happened to test by hand. The result is 234 mathematical statements ("laws"), each one checked by a proof checker, a program that accepts a proof only if every step is valid (the checker, Bend 2, is itself unqualified software: `phase3-safety.md` §5).

This document explains, gradually, everything needed to read those 234 laws: what problem they solve, what JET is, what "proving" something means, how to read the code, and then, law by law, what each one says and where it comes from.

The specifications, laws and proofs were written by an AI system (Claude) directed and audited by a human author; the checker judges every proof, and the adversarial reviews mentioned below were automated passes by other instances of the same model family, not independent human assessment (README §7).

---

## 1. The problem in one sentence

**How can you be sure a safety system works correctly in EVERY case, not just the few someone happened to test?**

Think of it this way: if you want to confirm a bridge can hold heavy trucks, you can drive 71 different trucks across it and see that it doesn't collapse. That gives you confidence, but not certainty — maybe truck number 72, with a combination of weight and speed nobody tried, is the one that breaks it.

JET validated its protection sequencer this way when it was refactored in 2017 ([S3]): with **71 "pulse schedules"** (experiment scripts, defined by JET's Plasma Operations Group) used as test cases, plus unit tests for each individual component. It's the standard engineering method and it works reasonably well, but it has that limit: it only covers the cases someone thought to try.

This project does the other thing: instead of testing 71 cases, it **mathematically proves** that a property holds for **every possible case** of the model, even if there are millions of them. This isn't a stronger claim about JET specifically (JET validated its sequencer with those 71 cases, and that validation was perfectly reasonable) — it's a demonstration that a different, complementary method exists, using JET as the real, published example because, among the protection systems we reviewed (`phase3-sources.md` §1), it is the only one whose logic is published at table level in open sources.

**Important, to be clear from the start:** the point of this project is not to certify that JET is safe. JET was operated with its own validations. The point is to show that the method — "prove every case with mathematics, not just test a few" — is applicable to a real, realistically sized protection system, as a first step toward using it on real nuclear safety systems (see §2 for exactly what kind of system this is).

---

## 2. What JET is and what it protects

**JET** (Joint European Torus) is a nuclear fusion machine: it heats a gas until it becomes plasma (a fourth state of matter; JET's is hotter than the core of the Sun) and confines it with magnetic fields, hoping to produce energy through fusion, the same way the Sun does. Each experiment is called a **pulse**: it lasts from seconds to a bit over a minute, and during that time the plasma goes through several **phases** (start-up, formation, heating, termination) with different rules in each one.

Plasma is hard to control, and if something goes wrong it can strike the machine's walls with a lot of energy (a "disruption"). That's why JET has an automatic system that watches dozens of signals and, if it detects a problem, shuts things down or halts the experiment before the equipment gets damaged. **That's what this project models and proves: the decision logic of that protection system**, not the plasma itself or the physical actuators.

Three pieces, from the mildest to the most severe:

- **RTPS** (*Real-Time Protection Sequencer*). It's the brain: it looks at which phase of the experiment is running and which alarm came in, and decides how severe the response should be, with room to pick among several intermediate options.
- **PTN** (*Pulse Termination Network*). It's the final panic button: a directly hardwired signal that, once triggered, **shuts everything down and latches** (it cannot be "reset" mid-pulse). Once it fires, there's no going back until the experiment ends.
- **DMS** (*Disruption Mitigation System*, also called the DMV after the valve that fires). It's the last line of containment: if a disruption is going to happen anyway, it injects gas into the plasma to spread its energy out in a less damaging way. It doesn't fire on its own: first the heating systems have to be turned off (if they're still on when the gas is injected, that's dangerous for the equipment), and only after a confirmation — or after waiting a fixed time — does the valve actually fire.

**A clarification that comes up again and again in JET's documentation, and that's worth having clear from the start:** this system (RTPS + PTN) protects the **investment** — the equipment, the walls, the heating systems — not people directly. People are protected by a separate system, the PSACS (Personal Safety & Access Control System, [S2]); below the RTPS and the PTN there is also the CISS (Central Interlock and Safety System), which [S1] calls "basic hardwired plant protection". Neither is modelled. This project is not evidence that a nuclear safety system works: it is evidence that the **method** (proving instead of only testing) is viable on a case of this size and complexity, and that's why the argument that the method could extend to real nuclear safety functions is made separately, carefully, in another document (`phase3-safety.md`).

---

## 3. What "proving" something means here

When we say a law is "proven," we don't mean "we tried it several times and it worked." We mean something much stronger: **it cannot be false**, given the model and a correct checker. (The checker, Bend, is itself unqualified software; that is why the certificate is re-checked in Python and a bank of deliberately planted bugs is run against the laws, `phase3-safety.md` §5.)

### The idea of "for all"

Consider a simple example: the statement *"for every even number n, n+2 is also even"* is true for infinitely many numbers. There's no need to check it against 2, then 4, then 6... all the way to infinity: it gets proven **once**, with a general argument, and that proof automatically covers the infinite cases.

Something similar happens here, but on a more manageable scale: the number of "possible cases" isn't infinite, it's **huge but finite** (on the order of hundreds of thousands). So there are two ways to prove a law:

1. **By verified brute force** (we call this a **certificate**): a computer checks, one by one, all 462,336 "cells" of the check (every state with every event and, on five of the 28 events, every combination of two yes/no counter signals: the step reads them only on the two clock ticks, and on three more events the checker cannot set them aside on its own, §6.7), once for each of the two possible urgency orders (§6.1), and confirms the property holds in every one of them. This isn't "testing some cases" — it's testing *all* of them, literally, one at a time, with the exact precision of a computer doing arithmetic (no rounding, no randomness).
2. **By a general argument** (we call this **induction**): for properties about entire sequences of events (like "the protection always eventually arrives"), looking at one step at a time isn't enough; you need to reason about sequences of any length, the same way as with the even numbers above.

Almost all of the 234 laws use one of these two forms; the configuration-table cells of §7 are single evaluations, and the 8 plumbing lemmas of §9 are case-by-case checks, the same idea on a tiny scale. In both cases, the final result is checked by a program called **Bend**, which will not accept a proof unless it is written with total mathematical precision: if a single logical step is missing, Bend refuses to accept it. That's why we say "proven," not "tested" or "seems to work."

### A distinction that matters a lot: fact vs. assumption

Every law in this catalog states something about a **model** of JET, not about the physical machine. That model was built in two layers:

- **Documented facts**: sentences quoted verbatim from published JET papers (identified as **R-0, R-1, R-2... R-15** in the source documentation; since revision 4 also sentences from [N1], a 2013 paper by De Tommasi et al. on JET's stops, cited by PDF page). These are literal quotes, like transcribing a witness's testimony word for word.
- **Our assumptions**: modelling decisions we made to fill in what the papers don't say (identified as **A-1, A-2... A-35**). These are like a detective's reasonable inferences: the witness didn't say everything, but there's a reasonable way to fill in the rest, and we declare it explicitly instead of hiding it.

For example: JET publishes that the RTPS "was able to act hierarchically so that subsequent alarms could generate a more urgent stop" (that's a fact, R-7, from [S2]). But JET does **not** publish the exact order of urgency between two of the four possible responses (we decided that, it's assumption A-1). A law that relies on that order is then a **mix**: the mechanism is JET's, the exact detail is ours.

Every law in this catalog carries an origin label:

| Label | What it means, plainly |
|---|---|
| **JET FACT** | What the law says is quoted, almost word for word, from a published JET paper. A declared caveat that adds no content doesn't change the label; neither does the model having no clock (every effect happens in one step, A-15), because that holds for every law. If the law adds something the paper doesn't say (it extends the paper to cases the paper doesn't cover, or pins down a detail we formalised ourselves), it's labelled MIX instead. |
| **ASSUMPTION** | What the law says is a decision we made. It may be *motivated* by something JET published, but the exact content isn't written anywhere; we filled it in ourselves, explicitly. |
| **MIX** | The general mechanism is a JET fact; the exact form (which order, which phase is read, which policy, which cases it extends to) is ours. |
| **PLUMBING** | The law exists because of how the mathematical proof works (the method), not because it says anything about JET. It's "infrastructure" for the proof. |

---

## 4. The minimal dictionary

Before getting into the laws, we define the pieces that will keep coming up. It's worth reading this whole section once; after that it works as a reference.

### 4.1 State: a "snapshot" of the machine at one instant

A **state** is all the relevant information about JET at a given instant. In this model, a state has eight fields (think of eight slots that need to be filled in):

| Field | What it holds | Possible values |
|---|---|---|
| **program phase** | Which stage of the pulse the experiment is in | Breakdown (start-up), IpRise (current ramp-up), Limiter, X-point (the plasma takes a diverted shape, with an X-point), Heating 1, Heating 2, Termination |
| **"jtt" flag** | Whether a direct jump to termination was accepted (see below) | yes / no |
| **response level in force** | How severe the active stop is right now | None, JTT, RTPS, PTN (from least to most severe) |
| **DMS state** | Which step the emergency valve's firing sequence is at | Idle (at rest), Armed (armed, waiting), Fired (fired) |
| **plasma** | Whether the plasma's basic conditions (current, density) are OK | yes / no |
| **DMV arming verdict** | The emergency valve's "enabling verdict": whether the plasma current **or** the energy stored in the plasma is above its threshold, so that the valve may be armed (A-22: the form of the condition in an example of the PETRA paper [S7], its Fig. 2, and of the limit for operating without the valve in [K15]; the older valve paper [S6] used the current alone). The model never sees the numbers, only the yes/no | yes / no |
| **NB heating unit** | State of the neutral-beam heaters (*Neutral Beam*, one of the two systems that heat the plasma) | Off, Ramping (winding down), Reduced (partial power), On (full power) |
| **RF heating unit** | State of the radio-frequency heating (the other system) | Off, Ramping, Reduced, On |

Added to this are **two counters** (numbers that count clock ticks): one counts how long it's been since the system last received an "I'm still alive" signal (for the watchdog below), and the other counts how long the DMS has been waiting for confirmation.

### 4.2 Event: something that happens

An **event** is the only thing that can change a state: an alarm sounding, a command, the passage of a clock tick, a reset. There are 28 possible kinds — for example "an alarm arrived asking for such-and-such response," "advance to the next phase," "turn on the RF heater," "a clock tick happened," "the heating plant's confirmation arrived," "end of pulse."

### 4.3 Step: the rule for "what happens next"

The **step** is the model's central mathematical function: it takes a state and an event, and returns the next state. The system's entire behavior is described by this single function; the 234 laws are, at bottom, all statements about what this function does (or doesn't do).

### 4.4 Trace: the complete history of a pulse

A **trace** is an ordered list of events: the complete sequence of everything that happened to JET during a pulse, from start-up to the end. "Running a trace" means applying the step function, event after event, and seeing what state you end up in.

### 4.5 Invariant: a rule that never breaks

An **invariant** is a property that is true in the initial state and **stays true after any event, forever**. It's like saying "the water level in this tank never rises above the red line, no matter what": you don't need to check it at every instant if you can prove that (a) it starts below the line and (b) no mechanism in the tank can make it jump above it in one go. This model has six control invariants (called **I1** through **I6**) — for example, "if the DMS is not idle, the response level has to be PTN" (I4).

### 4.6 Law: a proven mathematical statement

A **law**, in this catalog, is a statement of the form *"for every possible state and every possible event, if such-and-such happens, then such-and-such else happens,"* which was proven with mathematical certainty (not merely observed in some cases). Each of the 234 rows in this catalog is a law.

### 4.7 Certificate: computer-verified brute force

A **certificate** is the result of having a computer sweep through absolutely every possible cell (a state, an event and, on five events (§6.7), the two counter verdicts: 462,336 cells per urgency order) and confirm that certain properties hold in each one. Once the certificate exists, many laws are deduced from it automatically ("by reflection": the proof simply *reads off* the certificate's result instead of reasoning from scratch case by case).

### 4.8 Configuration instance: "the same machine, a different setting"

JET's **configuration table** says which response corresponds to each combination of (experiment phase, alarm type). That table is set by the session leader before each pulse — it isn't fixed in the system, it's a setting. This project certifies four **instances** (four different configurations, to prove the method works with any of them): instance 1 is the table JET published; instance 2 is a reasonable variant (motivated by another paper) where an alarm that "does nothing" in the published table actually does trigger protection; instance 3 is the same published table but with two extra safety checks turned off (to prove the method detects that difference); and instance 4 (added in revision 4) is the published table with a different way of answering a **second** alarm that arrives while a stop is already running: instead of reading the usual table again, it asks for the PTN wherever the usual table asks for any response, and for nothing where it asks for nothing (so a mode-lock alarm, which the published table leaves unanswered, still gets no response). That "secondary table" is **illustrative**, invented by us; JET's is not published (A-35).

---

## 5. How to read a piece of proof code

The laws are written in **Bend 2**, a general-purpose programming language (it compiles to C, CUDA, Metal and JavaScript) whose type checker also checks mathematical proofs; here only the checker matters. You don't need to know how to program to read it — it's a matter of learning a handful of symbols. We translate them once here, with a real, simple example.

```bend
law ptn_deenergizes:                                              # (1)
  for +o: S.Ord                                                   # (2)
  for +f: S.Fin                                                   # (3)
  for +e: S.Ev                                                    # (4)
  for +bt: Bool                                                   # (5)
  for +bh: Bool                                                   # (5)
  {Spec.pr_p2(f, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}   # (6)
```

1. **`law name:`** — the name of what's being proven. This is what the "negative tests" (tests that deliberately introduce a bug and confirm the proof catches it) cite when they say "this violates the law `ptn_deenergizes`."
2. **`for +o: S.Ord`** — "this holds **for either** of the two possible urgency orders." Which of the two is the right one is our assumption (§4.8 and §6.1), so every law that carries this line is proven for both. (The few laws about the concrete layer, the plant's own events, run only the order we chose, `Ord1`: A-1.)
3. **`for +f: S.Fin`** — "for any state `f`." The `S.` prefix just means "this type comes from the file that defines the model." The `+` is a Bend technicality (it allows the variable to be used more than once) and can be ignored when reading.
4. **`for +e: S.Ev`** — "for any event `e`."
5. **`for +bt: Bool` and `for +bh: Bool`** — "for any value of the two counter verdicts": whether the DMS wait counter and the heartbeat watchdog counter still have headroom or not (§4.1). They enter as Yes/No so the law doesn't depend on the counter's exact numeric value.
6. **`{... == True{} : Bool}`** — the actual claim: the predicate `pr_p2` (a function that returns Yes/No), evaluated on state `f` and on the next state, gives **Yes**. `S.step_fin(o, f, e, bt, bh)` is precisely "the next state": the result of applying the step (§4.3) to `f` with event `e`. The `Spec.` prefix means "comes from the file that defines the properties being checked." The predicate `pr_p2`, in plain terms, says: *"if the step makes the response level reach PTN, then both heating units end up off."*

One detail worth looking at closely: the next state is **not** quantified as "any state," it is written as the result of the step. That difference isn't cosmetic. If the law said "for every next state `f2`," it would be flatly **false**, because nothing would stop you from picking an invented `f2` with PTN active and the heaters on. What's being claimed is about the state the model actually produces, not about any state you could imagine.

So this whole law reads: **"for either urgency order, every state, every event, and any value of the two counters: if the step made the response reach PTN, both heating units ended up off."** And because it's "for all," it covers at once every state, every event and every pair of verdicts, for each order (10,752 × 28 × 4 = 1,204,224 cases). The certificate decides them with its 462,336 cells: the step reads the verdicts only on the two clock ticks (the `verdict_frame` laws of §6.7 prove it), so on 23 of the 28 events one pair of verdicts stands for all four; the other 5 are checked with all four.

Other symbols you'll run into:

- **`for +h: {condition}`** — a **hypothesis**: not part of the conclusion, a condition that has to hold for the law to apply. Example: `for +h: {S.inv_all(s) == True{} : Bool}` means "assuming state `s` satisfies the invariant."
- **`Bool.and(A, B)`**, **`Bool.or(A, B)`**, **`Bool.not(A)`** — logical AND, OR, NOT, as in any course on propositional logic.
- **`S.implies(A, B)`** — "if A then B" (if A is false, the statement is automatically true — it says nothing about B).
- **`match e: case S.Tick{...}: ... case _: ...`** — "depending on what kind of event `e` is, do one thing or another"; `case _:` is the "anything else" case.
- **`...`** inside a code block — a part left out to keep the example short; the blocks of §8 also write their hypotheses in words, between braces. Those blocks are schematic, not valid Bend: the exact statements are in the `LAWS_*.bend` files.
- **`{A == B : T}`**, where `T` is the type of `A` and `B` (for example `S.Level`, the type of response levels, in §9): the goal is an **exact equality** between two values, not a Yes/No answer. A Bool predicate that says "equal" is tied to this equality by the "plumbing" laws of §9.

With this, any of the 234 laws can be read. On to the groups.

---

## 6. The behavior laws — 81 laws

This is the main file (`LAWS_JETPROT.bend`). It's organized into families, each with a different purpose. We present them in the order that makes them easiest to understand, not necessarily the order they appear in the file.

### 6.1 The certificates (3 laws) — PLUMBING

Before any individual law, the foundation has to be built: the brute-force check over the 462,336 cells of each order.

```bend
law finite_check:
  {E.check_fin(S.Ord1{}) == True{} : Bool}
```

`check_fin` is a function that sweeps through, one by one, every cell (a state, an event and, on five events (§6.7), the counter verdicts) under the urgency order we chose (`Ord1`: None < JTT < RTPS < PTN) and confirms that every "step" law of §6.3–§6.5 (except F1a, F1c and IP2, which are proven directly) and the five of §6.8 on the PTN and the first stop holds on that cell. This law says: "that sweep returned Yes on absolutely all of them." It's the foundation almost every other law in this section rests on — they're deduced from it "by reflection": once you know something holds on every combination, you automatically know it holds on any one in particular.

```bend
law finite_check_alt:
  {E.check_fin(S.Ord2{}) == True{} : Bool}
```

The same, but with the **other** possible urgency order (`Ord2`: None < RTPS < JTT < PTN). Why check both? Because which of the two orders is "the correct one" is **our assumption** (A-1: JET doesn't publish a single order between JTT and RTPS). By proving every abstract law for both orders, we make sure none of them depends "by accident" on having chosen one particular one. (The exception, stated in A-1: the laws about the concrete layer and the configuration are certified under the chosen order, `Ord1`, only.)

```bend
law corollaries_check:
  {E.check_cor() == True{} : Bool}
```

A second sweep, this time over the states that satisfy the invariant, to check four additional properties ("corollaries," §6.6).

**Source: PLUMBING**, all three. They're the method, not facts or assumptions about JET.

### 6.2 The general invariants (6 laws) — ASSUMPTION/MIX/PLUMBING

```bend
law inv_init:
  {S.inv_all(S.init()) == True{} : Bool}
```

The initial state — pulse start-up, everything off, no alarm active, counters at zero — already satisfies the full invariant. It's the "starting point" of the induction proof. **Source: ASSUMPTION** (that the pulse starts this way is our reasonable choice of initial state, A-5 and A-12).

```bend
law pres_fin:
  for +o: S.Ord
  for +s: S.St
  for +h: {S.inv_all(s) == True{} : Bool}
  for +e: S.Ev
  {S.inv_fin(...) == True{} : Bool}
```

"For any order, any state that already satisfies the invariant, and any event: after taking a step, the control invariant (I1–I4) still holds." This is the law that makes the invariant actually invariant: no matter how much time passes or how many events arrive, the property never breaks.

The four control invariants it covers:
- **I1**: a heating unit can only be on (full or partial) if the heating window is open, plasma is OK, and no stop is active.
- **I2**: a unit can only be "winding down" (`Ramping`) if a soft stop is in progress or the pulse is ending.
- **I3**: if the response level in force is JTT (a jump to termination is running), the "waveform" phase is Termination.
- **I4**: if the DMS is not idle, the response level has to be PTN (you can't arm the DMS without the most severe alarm already sounding).

**Source: MIX.** I1 comes from JET publishing a system that "provides enable windows" to the heating (fact, R-12); summarizing it as a single boolean is our simplification (A-5, A-8). I4 comes from JET publishing that the DMS fires *after* the stops (fact, R-11); the exact form of "invariant" is ours.

```bend
law pres_i5:  ...  {S.i5_ack(...) == True{} : Bool}
```

Same kind of law, for **I5**: while the DMS is armed, the wait counter never reaches the limit (there's always headroom left). **Source: MIX** (the timed-wait-with-timeout mechanism is fact, R-11; expressing it as a "tick counter with a cap" is assumption, A-11).

```bend
law pres_i6:  ...  {S.i6_hb(...) == True{} : Bool}
```

For **I6**: while the PTN isn't active, the "how long since the last heartbeat" counter never reaches the limit. **Source: MIX** (the heartbeat watchdog is fact, R-13; the counter is assumption, A-12).

```bend
law traces_safe:
  for +o: S.Ord
  for +trace: List<&2, S.Ev>
  {S.inv_all(S.run_o(o, trace, S.init())) == True{} : Bool}
```

The theorem that ties everything together: **for any sequence of events, of any length, run from start-up, the final state always satisfies the full invariant.** This isn't a "one step" law; it's about **entire pulses**, of any duration. It's proven by induction (like the even numbers in §3): it holds at the start (`inv_init`) and every step preserves it (`pres_fin`, `pres_i5`, `pres_i6`), so it holds forever. **Source: PLUMBING** (it's the way of combining the invariants above into a single theorem about whole traces).

```bend
law traces_safe_concrete:
  for +i: S.Inst
  for +trace: List<&2, S.CEv>
  {S.inv_all(S.run_c(i, trace, S.init())) == True{} : Bool}
```

The same, but with the plant's "real" events (not the abstract version), running through one of the four configuration instances. **Source: PLUMBING.**

### 6.3 The "nothing bad happens" laws (P1–P21, 18 laws)

This family says, for each situation, **what CANNOT happen**. Each law follows the mold from §5: for every state `f`, every event `e`, and the counter verdicts, if something happens, then something else has to be true.

**P1 — `latched` ("the level never drops on its own").**
```bend
S.implies(Bool.not(is_reset(e)), lvl_le(o, S.level_of(f), S.level_of(f2)))
```
If the event wasn't a reset, the response level after the step is **equal to or more severe** than before. It never "eases up" on its own. **Source: ASSUMPTION** (A-1, A-2): JET publishes that the system *can* escalate (get more severe), but also explicitly says that sometimes it's better **not** to escalate (letting a stop already in progress run to completion instead of interrupting it with a new one). The policy "always rise to the maximum requested, never come down" is a decision we made, stricter than JET's own. Note that this law mixes several things. That the PTN stays latched is **JET FACT**, and since revision 4 it has a law of its own (`p1a_ptn_latched`, §6.8). That a stop never goes back to "none" also has its own law (`p1b_stop_never_cleared`, §6.8), a **MIX**: for the PTN it's JET fact, for the soft stops it's our reading. What is **OUR POLICY** is what happens between the two soft stops (JTT and RTPS) when one arrives on top of the other.

**P2 — `ptn_deenergizes` ("the panic button shuts everything off").** Already seen in full in §5. **Source: MIX** (R-0: "the PTN output is a latched stop signal"; R-11: "these triggers first cause the heating systems to be turned off"; A-9). JET documents the heating switch-off for the PTN outputs that trigger the emergency valve (R-11); for the other outputs it only says that each control system executes a "fixed shutdown sequence" (R-0). That **every** path to the PTN leaves both units off is ours (A-9), and it's the same part that makes `d1a_ptn_honoured` a MIX (§6.8). That it happens "in the same step" is the simplification of a model with no clock (A-15), shared by every law: in the plant the neutral beams take 2 ms to switch off and RF about 38 ms.

**P3 — `stop_reduces_power` ("starting a stop cuts the power").**
```bend
S.implies(Bool.and(S.is_none(S.level_of(f)), S.is_soft(S.level_of(f2))),
          Bool.and(Bool.not(S.is_hot(S.nb_of(f2))), Bool.not(S.is_hot(S.rf_of(f2)))))
```
If you go from "no stop" to a medium-severity stop (RTPS or JTT), neither heating unit keeps delivering power (full or partial) in that same step. **Source: MIX** (R-3, R-4 + A-9). That a soft stop brings the heating power down is fact (R-3, R-4: the "overrides" bring the power reference down). That **every** soft stop takes **both** units out of power, including one at partial power, is ours (A-9): JET describes the RTPS stops as "fully programmable" and doesn't say that each one brings both units down. It's the same part that makes `stop_no_full_power` a MIX (§6.6).

**P4 — `ramping_never_returns` ("what started winding down doesn't come back up").** A unit that's `Ramping` (winding its power down) never delivers power again unless there's a reset. **Source: ASSUMPTION** (A-9): a conservative policy of ours; JET doesn't say this explicitly. *(Derived: it follows from P5 and P7 together; see §10.)*

**P5 — `heat_permissive` ("the permission to heat is all-or-nothing, and exact").** A "turn this unit on" command turns it on **if and only if** all three conditions hold (window open, plasma OK, no stop); if they don't, the command does nothing. **Source: MIX**: the permissive mechanism itself is fact (R-12: the PEWS system "provides enable windows"); the exact form is ours: the fixed window (A-5), the plasma summarized as a single yes/no (A-8) and the "no stop" condition (A-9). One limit to keep in mind: the "window" in which heating is allowed is fixed in the model, the same for both units and every instance (A-27), whereas JET programs it pulse by pulse; this law says nothing about different windows.

**P6 — `stop_overrides_heat` ("with an active stop, nothing turns on").** While any stop is in force, no unit can go from "no power" to "power." **Source: ASSUMPTION** (A-9). *(Derived: it follows from P5 and P7 together; see §10.)*

**P7 — `heat_frame` ("a unit doesn't turn itself on").** If a unit goes from "no power" to "power," the event has to have been exactly the command to turn that unit on — it can't be a side effect of something else. **Source: ASSUMPTION** (A-19): we assume "command = effect," without modeling the real physical actuator.

**P9 — `local_is_local` ("a local alarm only touches its own unit").** When a "local" alarm arrives (a specific hot spot), the affected unit goes from full power to **partial** power (never all the way off), and the other seven state fields stay exactly the same. **Source: MIX.** JET publishes (R-9) that "the relevant PINI should be turned off [...] This should not preclude the neutral-beam system as a whole from continuing to deliver the total requested power to the plasma, as other PINIs can be turned on to compensate" — that is, JET talks about turning off **one part** of the unit and compensating with other parts; our model simplifies that to "the whole unit drops to partial power," without modeling the compensation (A-6, A-7). There is also a single reduction step: a second local alarm on the same unit does nothing, whereas at JET it would take out another PINI (A-33).

**P10 — `no_spurious_stop` ("the level only changes for one of four reasons").** If the response level changed, the event had to be: a stop request, a communication fault, a reset, or a clock tick with the watchdog expired. No other cause can move the level. **Source: ASSUMPTION** (A-12, A-13): this is our closure of the list of causes.

**P12 — `commfault_ptn` ("an enabled communication fault goes straight to PTN").** If a communication-fault event arrives and the corresponding check is enabled, the level ends up at PTN, no matter what state it was in before. **Source: JET FACT** (R-13: "if RTPS detects communication or status faults... it can trigger the PTN system").

**P14 — `phase_monotone` ("phases never go backward").** Without a reset, neither the program phase nor the "waveform" phase (see P19/F1 below) ever goes backward. **Source: ASSUMPTION** (A-5): JET says the phases are "timed" (fact, R-1); that they form a total, irreversible order is our reading.

**P15 — `dms_monotone` ("the DMS only moves forward").** Without a reset, the DMS can only go Idle → Armed → Fired, never backward. **Source: MIX** ([S6] + A-11): that once fired it stays fired until the end of the pulse is backed by the valve paper ([S6]: the valve "has to be refilled by an operator in the control room after every injection"); that an armed DMS never disarms is ours (A-11).

**P16 — `dms_armed_on_demand` ("a valid demand arms the DMS").** If the DMS was idle, the valve's enabling verdict is "yes" (current or stored energy above threshold; A-22), and an event arrives that "demands" the DMS (a severe stop wired to it, or a communication fault wired to it, or the watchdog expired and wired to it), the DMS ends up armed. **Source: MIX.** That certain stops trigger the emergency valve is fact (R-11, and the valve paper [S6]); *which* stops exactly are wired is our decision, the same for every instance (assumption, A-10).

**P17 — `dms_frame` ("nothing else arms the DMS").** The converse of P16: if the DMS left idle, it was because of one of those valid demands and no other cause. **Source: MIX** (R-14 + A-10, A-11): that the DMS doesn't arm without the enabling verdict is fact, as in IP1 (R-14); that only those demands arm it, and nothing else, is a frame of ours (A-10, A-11).

**P18 — `tack_frame` ("a repeated alarm doesn't reset the wait").** With the DMS already armed, any event that isn't a clock tick or a reset leaves the wait counter exactly unchanged (it doesn't reset it or move it forward). **Source: ASSUMPTION** (A-11): the alarm sounding again shouldn't "reset the stopwatch" on the wait.

**P19 — `advance_frozen` ("under PTN, the program is frozen").** An "advance to next phase" command while PTN is active does absolutely nothing: it neither moves the control state nor touches the counters. **Source: MIX**: that under PTN the program stops being in charge is fact (R-0: on the PTN signal, each control system executes "a fixed shutdown sequence"); that the two counters also stay exactly as they were is our formalisation (A-11, A-12), as in `piw_after_ptn_is_noop` (§6.8).

**P20 — `reset_guarded` ("end of pulse is all-or-nothing, gated by a guard").** A reset, if the safety condition holds (the pulse ended and the DMS is not armed), returns everything to the initial state; if it doesn't hold, absolutely nothing changes. **Source: ASSUMPTION** (A-14): JET doesn't publish a documented path for "clearing" the PTN mid-pulse, so we assume the reset is only accepted once the pulse has actually ended.

**P21 — `reset_refused_mid_pulse` ("you can't reset with the DMS armed or the pulse in progress").** The explicit version of the "no" half of P20: if the DMS is armed, or if neither PTN is active nor the termination phase has started, a reset request changes nothing. **Source: ASSUMPTION** (A-14).

### 6.4 The "does its job, and nothing else moves" laws (D1–D18, E2–E11, 26 laws)

The P laws above only say "nothing bad happens" — they're all negative. But on its own, that doesn't prove the system **works**: a system that never did anything would also satisfy "nothing bad happens." That's why this second family was added, with two parts to each law:

- the **"demand"** part: when certain conditions hold, the system **has to** act (not just "may");
- the **"frame"** part: when those conditions **don't** hold, **nothing else** moves (not one extra field changes).

These laws were added after two rounds of adversarial review (automated reviewers briefed to "trick" the model with subtle bugs on purpose, README §7; these laws are what it took to catch them). Of the 76 deliberately planted bugs in today's bank, 75 are caught. The bugs are planted in the Python reference model, not in the Bend one, and they are judged by these laws rewritten as Python predicates, which read the specification's constants rather than the model's (`v3/pymodel/`), plus one check that the model's invariant is the specification's (bug M72 is caught only by it). So this score measures the Python copies of the laws: a Bend law weaker than its copy would not show in it. For the remaining bug, the gate computes that it behaves exactly like the model on every case it compares, so no law could tell it apart.

**D1 — `d1_stop_honoured` ("the level is exactly the maximum requested").** On a stop request, the next level is **exactly** the more severe of the one in force and the one requested (not just "equal or worse," as P1 says — here it's "exactly that"). **Source: MIX** (R-7 says that "subsequent alarms could generate a more urgent stop"; that the rule is "take the maximum" is ours, A-2). Splitting the parts: that with no stop in progress the first request is honoured is **JET FACT**, with a law of its own since revision 4 (`d1b_primary_honoured`, §6.8). That a PTN request is always honoured is JET fact too, but its law, `d1a_ptn_honoured` (§6.8), also demands both heating units off, which is ours (A-9, as in P2), so it's a **MIX**. That a soft stop on top of another soft stop is resolved by "taking the maximum" is **OUR POLICY** (A-2, A-16), and it cuts both ways: it demands at least the authority requested, but escalating a soft landing to a PTN can itself provoke the disruption it meant to avoid, and a second request of equal or lower rank is ignored.

**D2 — `d2_soft_stop_ramps` ("an accepted stop brings the power down").** If the request is a soft stop (RTPS or JTT), it's more severe than what was in force, and some unit had power, that unit starts winding down. **Source: MIX** (R-4 + A-9). That the soft stop **ramps** the power down instead of cutting it is fact (R-4: "ramp down the plasma current and heating power to give a softer landing"). That every accepted soft stop does so for both units, including one at partial power, is ours (A-9), as in P3.

**D3 — `d3_advance_to_termination_ramps` ("the program's natural end also brings power down").** When the program reaches its natural end (with no stop at all) and advances to the termination phase, the power wind-down also begins. **Source: ASSUMPTION** (A-9). *(Note: this law is "derived" — it is fully covered by a more general law, E4; it's kept documented for tidiness, but doesn't count as additional independent evidence.)*

**D4 — `d4_watchdog_latches` ("the watchdog triggers PTN").** A clock tick, with the watchdog expired and PTN not yet active, makes the level move to PTN. **Source: JET FACT** (R-13: "a hardware watchdog signal to PTN ensures that RTPS is operational itself").

**D5 — `d5_hb_counts` ("the watchdog counter increments when it should").** A tick with headroom and no PTN adds one to the "how long since the last heartbeat" counter. **Source: ASSUMPTION** (A-12). *(Derived: it's half of E6.)*

**D6 — `d6_hb_frame` ("only a heartbeat resets the watchdog").** If the watchdog counter resets, the event had to be a heartbeat signal, or an accepted pulse reset. **Source: ASSUMPTION** (A-12).

**D7 — `d7_ack_timeout_fires` ("if time runs out, it fires anyway").** With the DMS armed, PTN active, and a tick with the wait exhausted, the DMS fires. **Source: JET FACT** (R-11: the triggers are "conditioned with an acknowledgement from the heating plant (and timeout)"; the valve paper [S6] clarifies the RF system never confirms, so the timeout is, in practice, the real path it fires through).

**D8 — `d8_ack_counts` ("the DMS wait counter increments when it should").** With the DMS armed, PTN active, and a tick with headroom, the wait counter adds one. **Source: ASSUMPTION** (A-11).

**D9 — `d9_heatack_fires` ("the plant's confirmation fires the DMS").** With the DMS armed, if the confirmation arrives that the heaters have already been turned off, the DMS fires. **Source: JET FACT** (R-11). *(Derived: it's half of E11.)*

**D10 — `d10_reset_accepted_when_safe` ("reset IS accepted when it's safe").** The other half of P20, written with the safety condition spelled out explicitly (not citing the model's own internal function, so that a bug in that condition is separately detectable). **Source: ASSUMPTION** (A-14). *(Derived from P20; kept so P20 doesn't "prove itself" by citing its own internal definition.)*

**D11 — `d11_advance_is_one_step` ("the program advances one phase at a time").** An advance command, without PTN and not already in the last phase, moves the program phase to **exactly** the next one (no skipping phases). **Source: ASSUMPTION** (A-5).

**D12 — `d12_phase_frame` ("only advance or reset move the program phase").** **Source: ASSUMPTION** (A-5, A-24). *(Not derived; the other way round: F1b, below, is its Stop case.)*

**D13 — `d13_plasma_is_input` / D14 — `d14_plasma_frame` ("plasma status is an external input").** The "plasma OK" state gets updated with exactly what the corresponding event carries, and only with that (or an accepted reset). **Source: ASSUMPTION** (A-8): summarizing current and density into a single boolean is our simplification.

**D15 — `d15_heatoff_is_local` / D16 — `d16_heaton_is_local` ("turning a unit on or off only touches that unit").** A command to turn the NB unit on or off, for instance, changes absolutely nothing about the RF unit's state or any other field (aside from the direct effect on that unit, which P5 describes). **Source: ASSUMPTION** (A-19).

**D17 — `d17_heatack_frame` ("a confirmation only touches the DMS").** On the plant's confirmation signal, only the DMS state changes; the other seven fields and both counters stay the same. **Source: ASSUMPTION** (A-11).

**D18 — `d18_heartbeat_frame` ("a heartbeat only touches its own counter").** On a heartbeat signal, the control state doesn't change at all, and only the watchdog counter is touched (not the DMS one). **Source: ASSUMPTION** (A-12).

**E2 — `e2_dms_fire_frame` ("the DMS only fires through two paths").** If the DMS went from armed to fired, it had to be either the plant's confirmation or the wait time running out — there's no third path. **Source: JET FACT** (R-11: the two paths are exactly the "acknowledgement from the heating plant (and timeout)"). Although it's called a "frame" law, the "no third path" part is JET's too: the same sentence says the DMS activation is "conditioned with" those two paths.

**E3 — `e3_stop_phase_exact` ("the jump to termination moves the waveform exactly when it should").** On a stop request, the "waveform" phase moves to Termination **if and only if** a direct jump (JTT) more urgent than what was in force got accepted; otherwise it stays the same. **Source: MIX** (R-4: on a JTT the RTPS signals the controllers "to move forward in their waveforms to the termination region", fact; that it only moves the "waveform" and not the Level-1 program phase is our reading, A-24 — see family F1 below; and "accepted if more urgent than what was in force" is our policy, A-2).

**E4 — `e4_advance_units` ("a phase advance exactly determines what happens to each unit").** Covers all six possible phase-advance cases (not just the one going to Termination, as D3 did): depending on which phase is being advanced to, each unit ends up exactly in the state that corresponds (winding down, off if the window closes, or unchanged). **Source: ASSUMPTION** (A-5, A-9).

**E5 — `e5_heartbeat_resets_hb` ("a heartbeat ALWAYS resets the watchdog").** The unconditional "yes" half of D6. **Source: ASSUMPTION** (A-12).

**E6 — `e6_hb_tick_exact` ("the command to the watchdog counter on a tick is exactly one of three").** On a tick, with headroom and no PTN: increment. With PTN: leave it alone. Without headroom: leave it alone too (because in that same step PTN fires, by D4, and it stops making sense to keep counting). There's no fourth possible case. **Source: ASSUMPTION** (A-12).

**E7 — `e7_tack_inc_frame` / E8 — `e8_tack_reset_frame` ("the DMS wait counter is only touched in two exact situations").** E7: it only increments on a tick with the DMS armed and headroom left. E8: it only resets on an accepted end of pulse or a demand that actually arms the DMS. **Source: ASSUMPTION** (A-11, A-14).

**E11 — `e11_heatack_exact` ("the confirmation is two-way").** On the plant's confirmation, if the DMS was armed it moves to fired; if it was in any other state, nothing changes. This is the full (both-sides) version of D9. **Source: MIX** (firing on confirmation is fact, R-11; that a `HeatAck` arriving without the DMS armed does nothing is assumption, A-11).

### 6.5 The fidelity-to-the-papers laws (F1, F2, F3, F4, IP — 13 laws)

These laws were added in a later review (called "blocker 4" in the project's log) to tie off very specific loose ends that JET's papers mention but the initial model didn't distinguish precisely enough: two different "phase clocks," partial power, the reliability-check masks, and the DMV arming verdict for the emergency valve (current OR stored energy above threshold, A-22).

**The two views of time (F1a–F1e).** A JET paper ([S2], about the CODAS control system) says that during a jump to termination "there were two views of time": the time in the waveforms, which drive the actuators, and the time in the plasma pulse as executed. The model keeps both: the **program** phase, which (our reading, A-24) indexes the configuration table and only advances through explicit "advance" commands or a reset, and the **waveform** phase, which the heating permissive and the emergency valve's window read and which a direct jump to termination moves to Termination. Before this revision the model had a single phase, so after a jump to termination a later alarm read the Termination row; which row JET's RTPS reads in that case is not published (A-24, A-30).

- **F1a `f1a_table_reads_prog`**: a concrete alarm always reads the table using the **program** phase, never the waveform one, in any instance and any state. It's stated against a separate transcription of the table (the enumerator's own constants in `enum_jetprot.bend`, not the model's table), so if the model read the wrong phase or the wrong cell, this law would catch it. Since revision 4, if a stop is already running, the alarm reads the instance's **secondary table** instead of the primary one (in instances 1 to 3 they are the same thing, so for them the law did not change). **Source: MIX** (that the table is indexed by phase is fact, R-5; which of the two phases exactly is our reading, A-24). Which phase an alarm reads **during** a stop is not documented (A-24, A-30): a JET paper says the shape controller keeps the stop configuration of the time window in which the primary stop was issued ([N1] PDF p.13), that is, it freezes it, and the model does not freeze it.
- **F1b `f1b_stop_keeps_prog`**: a stop request never moves the program phase (only the waveform one). **Source: ASSUMPTION** (A-24). *(Derived: it is the Stop case of D12; kept as the named statement of A-24.)*
- **F1c `f1c_wave_ahead`**: the waveform phase is never "behind" the program phase (always equal or further ahead). This holds by construction, independent of any specific event. **Source: ASSUMPTION** (A-24).
- **F1d `f1d_wave_frame`**: the waveform phase only moves through a program advance, a reset, or an accepted direct jump. **Source: ASSUMPTION** (A-24).
- **F1e `f1e_jtt_exact`**: the "a direct jump was accepted" flag is exactly determined: it turns on when the jump is accepted, off at end of pulse, and otherwise stays the same. This was found thanks to a metric of "how tight is the model," which discovered two states that only differed in this flag and behaved exactly the same — that is, nothing pinned it down yet. **Source: ASSUMPTION** (A-24; "accepted if more urgent" is our policy, A-2).

**F4 `f4_units_frame` ("nothing moves the heating units except a short list of events").** If the response level didn't change and the event isn't one of those that can touch a unit (a direct command, a phase advance, a reset, a loss of plasma, a severe stop, or an enabled communication fault), then no unit changes. The same tightness metric found that, without this law, nothing stopped the units from changing "for free" on a current or plasma change that shouldn't affect them. **Source: ASSUMPTION** (A-19).

**F2a `f2a_local_reduces` / F2d `f2d_reduced_never_returns` ("partial power is one-way").** F2a: a local alarm takes one PINI (one antenna for RF) out of a unit at full power: the unit goes to `Reduced`, never to off. **Source: JET FACT** (R-9, the quote already seen at P9). That `Reduced` means **partial** power, with no compensation by other PINIs, is ours (A-6), as in P9. *(Derived: it is the reduction half of P9; kept as the named statement of R-9.)* F2d: a unit at partial power never jumps straight back to full power. It is a one-step rule: if the unit is switched off (by an off command or because the plasma conditions are lost) and later switched on again, it comes back at full power and the PINI that was taken out is back in (A-34). **Source: ASSUMPTION** (A-6, A-7: without this law, a "plasma OK" event could restore full power without any other law forbidding it; JET does allow compensating with other parts of the unit, but that isn't modelled, so this policy is stricter than the real one — conservative).

**F3b `f3b_commfault_masked_is_noop` ("a disabled check does nothing").** If the communication-fault check is disabled in that instance's configuration, the corresponding event changes absolutely nothing (neither the control state nor the counters). **Source: MIX** ([S1] + A-21): the main paper, [S1], publishes that these checks are conditioned "so that features or subsystems which are not in use cannot cause problems", and JET publishes that inputs to the PTN "can be enabled or disabled" (fact, R-10); that absolutely nothing moves, counters included, is a frame of ours, and the detail of "a per-instance mask, only for these two checks" is ours too (A-21).

**IP1 `ip1_low_never_arms` ("without the arming verdict, there's no arming").** Without the valve's enabling verdict (neither the current nor, since revision 4 of the register, the stored energy is above its threshold; A-22) and with the DMS idle, no event arms it. **Source: JET FACT** (the valve paper [S6]: "The DMV was used systematically for scenarios above 2.5 MA"; and the same paper reports **7 disruptions** detected "at a plasma current lower than the minimum current needed for the DMV to be fired": the valve could not fire, because the first thermal quench (the sudden loss of the plasma's heat at the start of a disruption) had happened at higher current and none of the detection signals caught it).

**IP2 `ip2_arms_on_demand` ("with the arming verdict, a demand DOES arm it").** The concrete version of P16: with the enabling verdict "yes", DMS idle, and an alarm that this instance's table sends to PTN and that is wired to the DMS within the enabled window, the DMS arms in that same step. **Source: JET FACT** (R-11, R-14, and the paper [S6]).

**IP3 `ip3_ip_is_input` / IP4 `ip4_ip_frame` ("the enabling verdict is an external input").** The DMV arming verdict (current OR stored energy above threshold, A-22) gets updated with exactly the corresponding event, and only with that or an accepted reset. **Source: ASSUMPTION** (A-22: in an earlier revision this threshold was entirely outside the model; it was added later, and since revision 4 it is read as "current **or** stored energy above threshold", the form of the condition in the Fig. 2 example of [S7] and of [K15]'s limit for operating without the valve; the laws do not change because they speak of a yes/no).

### 6.6 The corollaries (4 laws) — MIX/ASSUMPTION

These are consequences read directly off the invariant, with no need to look at a single step: they hold in **any** reachable state, because `traces_safe` (§6.2) guarantees every reachable state satisfies the invariant.

- **`ptn_no_heat`**: under PTN, both units are off. **MIX** (R-0, R-11 + A-9): that every path to the PTN switches the heating off is ours, as in P2 (JET documents it for the PTN outputs that trigger the emergency valve), and that nothing turns back on afterwards is assumption too (A-9).
- **`dms_no_heat`**: with the DMS armed or fired, both units are off. **MIX** (R-11, [S6] + A-9): that the heating is off when the valve is activated is fact (valve paper [S6]: "Heating systems cannot be operating when the DMV is activated"); that it stays off after the injection, until the end of the pulse, is assumption (A-9), as in `ptn_no_heat`.
- **`stop_no_full_power`**: with any stop in force, no unit delivers power (full or partial). **MIX** (the stop's effect is fact; that it also holds for partial power is assumption, A-9).
- **`termination_no_full_power`**: in the "Termination" waveform phase, no unit delivers power. **ASSUMPTION** (A-9).

### 6.7 Fine plumbing (5 laws) — PLUMBING / ASSUMPTION

A small group of technical laws that don't add new content about JET, but fine-tune the proof machinery:

- **`verdict_frame_step`, `verdict_frame_hb`, `verdict_frame_tack`**: prove that, except for "clock tick" events, the result of the step **doesn't depend at all** on the counter verdicts. This justifies why the certificate (§6.1) doesn't need to check all four verdict combinations on each of the 28 event columns, only on 5 of them: the two clock ticks, and three events where the checker cannot discard the verdicts symbolically, even though, by these same laws, the step does not read them — saving computation without losing rigor. **PLUMBING.**
- **`reset_accepted`, `reset_refused`**: the version of P20 stated over the **complete** state (including both counters, not just the control state): with the safety condition, a reset gives exactly the complete initial state; without it, it's the exact identity. **ASSUMPTION** (A-14).

### 6.8 What P1 and D1 say about the PTN and the first stop, under their own names (5 laws), and the second alarm in instance 4 (1 law) — revision 4

Laws P1 and D1 mixed two things: what JET documents about the PTN (the "panic button") and what we decided for a soft stop arriving on top of another soft stop. These five laws split off the part about the PTN and the first stop, so it can be cited without dragging our soft-over-soft policy along. Two are **JET FACT**; the other three are **MIX**, because each adds something of ours, said in its entry. The main source is [N1], a 2013 paper on JET's stops; page numbers are PDF pages. In [N1], "PIW" is the Protection of the ITER-like Wall project (PDF p.12), and "PIW stops" are the new shape-controller stop responses it introduced, triggered by the RTPS (JTT is one of them, Fig. 6); we identify them with the model's soft stops (JTT and RTPS).

- **`p1a_ptn_latched` ("the PTN stays latched").** If the PTN is active and the event isn't a reset, the PTN stays active. **Source: JET FACT** (the PTN output is latched, R-0: "The PTN output is a latched stop signal"; and [N1] p.14: "a PIW stop can never preempt a PTN stop"). *(Derived: a case of P1.)*
- **`p1b_stop_never_cleared` ("a stop doesn't clear itself").** If a stop is running (soft or PTN) and the event isn't a reset, a stop is still running. **Source: MIX**: for the PTN it's JET fact (the latched PTN output, R-0); for the soft stops it's our reading: no paper publishes a way to cancel a stop (A-14, an argument from absence), and the main paper [S1] presents stops as the way to end the pulse (R-8). ("Allowing it to run to completion", R-6, is about not switching to a secondary stop.) It is not a sentence from [N1]. *(Derived: another case of P1.)*
- **`d1a_ptn_honoured` ("a PTN request is always honoured").** A PTN request leaves the level at PTN and both heating units off, from any state, even with a soft stop running. **Source: MIX**: that a PTN request is honoured even with a soft stop running is JET FACT ([N1] p.13: PTN stops "can be triggered even after a PIW stop is in execution"); that both units are off is ours (A-9, as in P2): JET documents the heating switch-off for the PTN outputs that trigger the emergency valve (R-11), otherwise only as a "fixed shutdown sequence" (R-0). *(Derived: follows from D1, P2 and P6, on the states that satisfy the invariant.)*
- **`d1b_primary_honoured` ("the first stop is honoured").** With no stop running, a soft request (JTT or RTPS) becomes the response in force, under either order. **Source: JET FACT** (the primary table, R-5; [N1] p.13: "RTPS will select the stop and send it to SC", i.e. the RTPS picks the stop and sends it to the shape controller). *(Derived: a case of D1.)*
- **`piw_after_ptn_is_noop` ("a soft request after the PTN does nothing").** With the PTN active, a request that isn't a PTN changes absolutely nothing, neither the state nor the two counters. **Source: MIX**: [N1] p.13 calls a PIW request "after a PTN stop was already being executed" an "invalid task", in the acceptance tests of the shape controller's simulator, which "still follows the correct path of action"; that such a request leaves the whole state and both counters unchanged is our formalisation (A-14; the counter commands are those of A-11 and A-12), and it's exactly the part that makes the law non-derived. **Not derived**: no earlier law stopped that request from moving the watchdog counter, and the "how tight is the model" metric showed it (counter commands pinned on 243 of 400 sampled cases, up from 212).
- **`inst4_second_alarm_ptn` ("in instance 4, a second alarm leads to the PTN").** In instance 4, if a soft stop is running and an alarm arrives that the primary table does not map to "none", the concrete step fires the PTN. This is exactly the case that instances 1 to 3 ignore: a divertor hot spot during an RTPS stop, with the phase at Heating 2. **Source: MIX**: the two-level mechanism, primary and secondary response, is **JET FACT** ([S1], R-6); the content of the secondary table is **invented** by us (A-35), because JET's is not published. It is inspired by the caption of [N1]'s Fig. 7 (PDF p.23), "The preferred secondary plasma stop is the PTN slow stop", which is a usage statistic, not a rule.

[N1]'s cap, "a maximum of two in sequence" ([N1] PDF p.13; our reading: two PIW, i.e. soft, stops), does **not** get its own law: with only two soft levels and a strict order, it holds by itself, from the way the model is built. Presenting it as a proof of JET's rule would be overclaiming.

---

## 7. The configuration-table laws — 143 laws

This file (`LAWS_JETPROT_CONF.bend`) isn't about "what happens when something changes" (section 6 already covered that) — it's about **what the configuration table exactly says**, cell by cell.

### 7.1 Why there are so many nearly identical laws

JET's configuration table is a lookup table: row = experiment phase (7 possible), column = alarm type (8 possible) → cell = how severe the response is. That's 56 combinations per instance (there are four instances, but the fourth copies the first one's table), plus the emergency valve's wiring, the masks and, since revision 4, the secondary tables. Each cell was transcribed **twice, separately** (once in the model, once again in this laws file), and it's proven, cell by cell, that the two transcriptions agree. It's literally the same trick you use when copying down a long phone number: you write it, and then you read it back out loud comparing it against the original, to catch a typo.

Each individual law has this form:

```bend
law pub_Heating2_Dhs:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Dhs{}), S.LJtt{}) == True{} : Bool}
```

Read as: "in table 1, the cell (phase Heating2, alarm Dhs) is exactly JTT." The name encodes the cell (`prefix_Phase_Alarm`), so there's no need to memorize 143 different names — just understand **4 prefixes**.

| Prefix | What cell it is | Source |
|---|---|---|
| `pub_` | A cell that JET's Table 1 publishes directly (printed, or marked with a "ditto" `\|` repeating the value above) | **JET FACT** |
| `asm_` | A cell in a column Table 1 does **not** publish (that whole column is missing) | **ASSUMPTION** |
| `inst2_` | A cell where instance 2 (our variant) changes the published value | **ASSUMPTION** |
| `inst2_same_` | A cell where instance 2 copies exactly the value from instance 1 | **ASSUMPTION** (defines our variant) |

### 7.2 The table JET published — 28 `pub_*` laws — JET FACT

This is Table 1 as it appears in the original JET paper [S1]. Of the 28 cells, **15 are printed directly** and **13 are read from an "idem" mark** (the symbol `|`, which in the original table means "repeat the value in the cell above"). That reading of the marks was checked forensically and carefully (two separate automated reviews, see README §7, confirmed that each `|` really was the repetition symbol and not a table rule, by measuring the glyph's position in the original PDF), so all 28 count as documented fact.

| Phase | "Slow" alarm | "MHD" alarm (instability) | "MCHS" alarm (hot spot, chamber) | "DHS" alarm (hot spot, divertor) |
|---|---|---|---|---|
| Breakdown (start-up) | PTN | None | None | PTN |
| Ip Rise (current ramp-up) | PTN | None | None | PTN |
| Limiter | PTN | None | None | PTN |
| X-point (formation) | PTN | None | None | PTN |
| Heating 1 (heating) | RTPS | None | RTPS | PTN |
| Heating 2 (heating) | RTPS | None | RTPS | **JTT** |
| Termination | PTN | None | PTN | PTN |

One important clarification from the source documentation: the "MHD = None" column does **not** mean JET ignores that instability. Other JET papers show that the mode-lock signal did protect: it soft-stopped the pulse and triggered the emergency valve ([S6]), and PETRA "triggers a stop and MGI" on it ([S7]). And the tables JET actually configured did answer it: in the ITER-like wall campaigns of 2011–2012, MHD-driven stops were, together with the hotspot ones, "the vast majority of primary PIW stops", the stops the RTPS triggers ([N1] PDF pp.12, 14). Table 1 only illustrates one configuration; instance 2 (§7.4) certifies our version of the other documented path, MHD to the PTN and the valve.

Another clarification: that the "Slow" column is the generic "slow termination" alarm is our inference (A-31). The values of those 7 cells are printed, but the paper never says explicitly what that column is. So the 7 `pub_*_Slow` laws are JET fact plus an inference of ours.

### 7.3 The columns missing from the published table — 21 `asm_*` laws — ASSUMPTION

JET published a table with only 4 of the 8 possible alarm columns (leaving out 3 more alarm types plus the "blind" alert row, which is handled separately in §7.5). To be able to prove laws about **all** possible alarms, we filled in the missing columns using a conservative, declared criterion: the "fast" alarm always goes straight to PTN in any phase (motivated by another paper that mentions this mechanism, though it doesn't publish the full table), and the other two missing columns are filled with a simple, explicit rule.

| Phase | `_Fast` | `_MhdB` (second instability) | `_BothHs` (both hot spots at once) |
|---|---|---|---|
| Breakdown | PTN | None | PTN |
| Ip Rise | PTN | None | PTN |
| Limiter | PTN | None | PTN |
| X-point | PTN | None | PTN |
| Heating 1 | PTN | None | PTN |
| Heating 2 | PTN | None | **RTPS** |
| Termination | PTN | None | PTN |

Label from the source documentation: **"fabricated,"** the most honest of the assumption labels — these are values we invented to complete the model, not an inference from an ambiguous quote. Two refinements. "Fast always to PTN" is **one possible configuration** among several: another JET paper ([N1]) also lists a soft stop called "Fast" (A-4). And "both hot spots" is the more severe of the two separate ones, a reasonable **lower bound** that depends on the chosen order (A-1, A-32): in Heating 2 it gives RTPS because we put JTT below RTPS; with the other order that cell would give JTT. At JET, "both at once" is an alarm configured on its own.

### 7.4 The second configuration instance — 14 + 42 `inst2_*` laws — ASSUMPTION

Instance 2 is identical to instance 1 in everything (that's why 42 `inst2_same_*` laws are needed, which simply confirm "this cell equals instance 1's cell"), except for one thing: the "MHD" instability and its variant DO reach the PTN from the X-point phase onward.

| Phase | `inst2_*_Mhd` | `inst2_*_MhdB` |
|---|---|---|
| Breakdown, Ip Rise, Limiter | None | None |
| X-point, Heating 1, Heating 2, Termination | **PTN** | **PTN** |

Why this second instance exists: another JET paper, about the emergency valve, mentions that the mode-lock signal "is already used at JET to soft-stop the pulse"; a third paper about a later detection system (PETRA, [S7]) explicitly says that, on that alarm, PETRA "triggers a stop and MGI" (MGI: massive gas injection, the emergency valve's job). In other words: there's solid evidence that in practice this alarm does protect, even though the 2011 table we cite as "instance 1" doesn't show it. Instead of arguing over which table is "the real one," we certify both, so the method is proven for either.

### 7.5 The blind-alert row — 7 `asm_*_Blind` laws — ASSUMPTION

A "blind alert" is the emergency response when a sensor stops sending data (the system goes "blind" on that signal). JET mentions this category of alert exists, but doesn't publish its row in the table. We assume, explicitly, that across the seven phases it goes straight to PTN.

### 7.6 The emergency valve's wiring — 17 laws — ASSUMPTION/JET FACT/MIX

- **8 `dms_trig_*` laws** (ASSUMPTION, A-10): state which alarms are wired to the emergency valve (the ones that signal a likely disruption: fast, both instabilities) and which aren't (hot spots, "both at once," blind alert).
- **7 `dms_window_*` laws** (**JET FACT**, R-14, for six of them; `dms_window_Termination` is a **MIX**, R-14 + A-10): the window of phases during which the valve can fire — from the X-point formation (when the plasma, already formed, takes its diverted shape with an X-point) to the end. With two caveats (A-10): at JET that window is programmed pulse by pulse and in the model it is fixed; and the paper says it "generally" closes at the end of the post-heating stage, while the model keeps it open through the whole termination (`dms_window_Termination` extends the paper's window, which is why it's a MIX).
- **2 `dms_on_commfault_off`, `dms_on_watchdog_off` laws** (ASSUMPTION, A-10, A-12, A-13): neither a communication fault nor the expired watchdog arms the emergency valve in any instance — our decision; JET would allow either option. It is a **trade-off, not a conservative choice**: a hard stop at high current can cause a disruption, and that disruption would then be unmitigated.

### 7.7 The third instance and the masks — 5 laws — ASSUMPTION

Instance 3 uses the same published table as instance 1, but with both reliability checks (communication fault and blind alert) **turned off**. This shows that the configuration is pinned cell by cell, masks included: a disabled check is part of the checked data, not a silent change of behavior. JET did lose disruptions to configuration ([S6], R-15: 5 because of inhibits in the real-time protection systems that prevented the valve from firing, 4 because the valve's time window was set incorrectly), but neither case is modelled here: the valve window is fixed in the model (A-10), and the inhibits and bypasses of the PTN inputs and outputs are outside it (A-21); the masks cover only the two reliability checks.

### 7.8 One universal alarm — 1 `fast_ptn` law — MIX

```bend
law fast_ptn:
  for +i: S.Inst
  for +s: S.St
  {S.is_ptn(S.level_of(...)) == True{} : Bool}
```
"For any instance and any state, the fast alarm always leads to PTN." Unlike the cell laws (which are about a fixed phase), this one is universal across **all** phases and states at once, because in our table the fast alarm is PTN in all seven phases without exception. **Source: MIX** (the mechanism is fact, R-7; that it's uniform across all seven phases is assumption, A-4, and one possible configuration among several). It holds for all four instances; with a stop already running, the alarm goes through the secondary table.

### 7.9 The "concrete" layer — 2 laws — PLUMBING

Two technical laws that connect the "abstract alphabet" of events (the one the laws in section 6 use) with the "concrete alphabet" (the events as the real plant would see them). They check against a **fourth**, separate transcription of the table and the windows, and confirm that translating a plant event into its corresponding abstract event uses exactly the right instance (it doesn't, for example, mix instance 1's table with instance 2's window). Since revision 4 they also check, for every stop level in force, that the primary or the secondary table is read as appropriate (5 376 cases in all: 4 instances × 7 phases × 2 × 4 levels × 24 plant events). Which phase of the table is read is our reading, not something documented (A-24, A-30). **Source: PLUMBING.**

### 7.10 Instance 4 and the secondary tables — 6 laws — ASSUMPTION/MIX (revision 4)

When an alarm arrives and **a stop is already running**, the model now looks up a **secondary table** that belongs to each instance. That there are two levels of response, primary and secondary, is JET's ([S1], R-6); what was never published is what JET's secondary table says.

- **`inst4_table`, `inst4_mask`** (ASSUMPTION): instance 4 uses the published table, cell by cell, with both reliability checks on. It is the definition of our instance, like the `inst2_same_*` laws.
- **`sec_legacy`** (MIX): in instances 1 to 3, the secondary table is the primary one again. It is the way the model worked before, kept as is: a second alarm reads the usual table again and keeps the more severe response (A-2, A-16).
- **`sec_inst4`** (MIX): in instance 4, the secondary table says PTN wherever the primary one asks for any response, and nothing where it asks for nothing. It is checked against a separate transcription. The content is **illustrative and invented** (A-35).
- **`sec_monotone`** (MIX): no secondary response is less severe than the primary one, under either order.
- **`sec_primary_ptn`** (MIX): if the primary table says PTN, so does the secondary one. It matches [N1] p.14: "any primary PTN stop can never be followed by a PIW secondary".

An honest warning: the model's safety theorem already held for any stop request, so saying "it is safe with both tables" is nearly automatic. What these laws add is something else: the mechanism JET does document, a concrete demand proved in instance 4, and the content of the secondary table as explicit, declared data. And more authority is not necessarily more safety: in instance 4 a secondary PTN can provoke a disruption, and for the Slow, MCHS, DHS and both-hotspots alarms that PTN does not arm the emergency valve.

---

## 8. The "protection always arrives on time" laws — 2 laws

Apart from the two trace theorems of §6.2, which say the invariant survives any sequence of events, everything above says **what cannot happen** and **what has to happen in one step**. But none of those laws, on their own, guarantee the protection **actually arrives**: in principle, a system could satisfy every single-step law and still end up "waiting forever" without ever firing. These two laws close that gap: they are the only ones about what must **eventually happen** along a sequence of events of any length (bounded response). Like `traces_safe`, they're proven by induction on the trace (§3), from single-step facts the certificate already provides.

The two blocks below are schematic: the hypotheses are written in words, and the exact statements are in `LAWS_JETPROT_LIVE.bend`.

```bend
law watchdog_responds:
  for +o: S.Ord
  for +s: S.St
  for +h_inv: {invariant of s}
  for +trace: List<&2, S.Ev>
  for +h_nohb: {the trace has no "heartbeat" and no reset}
  for +h_len: {the trace has at least hb_max ticks}
  {PTN ended up active}
```

In plain terms: **from any valid state, if enough time passes with no "I'm still alive" signal at all (and no reset in between), PTN ends up active, guaranteed, no matter what else happened in the meantime.** It's not "probably" — it's "mathematically inevitable" given the model. **Source: MIX** (the heartbeat watchdog to PTN is fact, R-13; the counter of ticks without a sign of life, which starts at Breakdown and restarts with every heartbeat, is our formalisation, A-12; counting in ticks instead of milliseconds is the clockless simplification, A-15, common to every law: the model has no notion of real time, only of "how many events happened").

```bend
law dms_responds:
  ... (same scheme) ...
  for +h_armed: {the DMS is already armed}
  for +h_noreset: {the trace has no reset}
  for +h_len: {the trace has at least ack_max ticks}
  {the DMS ended up fired}
```

In plain terms: **once the DMS is armed, if enough time passes with no reset, it ends up firing, no matter what** — either because the plant's confirmation arrived or because the wait time ran out. **Source: MIX** (the sequence "turn off heaters → confirmation or timeout → fire" is fact, R-11, and the valve paper [S6]; the wait counter and its cap `ack_max` are our formalisation, A-11; counting in ticks is the clockless simplification, A-15, common to every law).

These two laws are proven from eight "single-cell facts" already proven in section 6 (P1, D4, D7, D8, P15, P18, E11, and a preservation lemma), combined with induction over the whole trace in a separate file (`PROOF_JETPROT_LIVE_CORE.bend`).

---

## 9. The mathematical-plumbing laws — 8 laws

This last group (`LAWS_JETPROT_SOUND.bend`) says nothing about JET. It's the equivalent of checking that the scale you're weighing everything else with is properly calibrated.

**The problem they solve.** Many laws in sections 6 and 7 end up concluding things like "these two states are equal" — but they say so through a **predicate** (a function that compares two values and returns Yes/No by comparing an internal number assigned to each one, a "rank"). The risk: if that predicate had a bug — for instance, if it accidentally confused two distinct values like `Off` and some other state, assigning them the same internal number — every law that depends on it could end up "vacuous" (technically proven, but saying nothing real), with nothing catching it. These 8 laws are the bridge that ties "the predicate said Yes" to "the two values are **really, mathematically**, the same value."

Example, with a line-by-line translation:

```bend
law lvl_eq_sound:
  for a: S.Level                                    # any response level a
  for b: S.Level                                    # any response level b
  for h: {Spec.lvl_eq(a, b) == True{} : Bool}        # assuming the predicate says "they're equal"
  {a == b : S.Level}                                 # then a and b really are the same value
```

There's one of these for each data type the model compares: equality of response levels (`lvl_eq_sound`), of phases (`phase_eq_sound`), of DMS states (`dms_eq_sound`), of a heating unit's state (`unit_eq_sound`), of booleans (`beq_sound`), and of the complete control state — all eight fields together (`fin_eq_sound`). Two more are added about the **ordering** of urgency between levels: that every level is "equal to or less urgent" than itself (`lvl_le_refl`), and that if A is equal-to-or-less-urgent than B and B is equal-to-or-less-urgent than A, then A and B are the same level (`lvl_le_sound` — this is what makes P1 from section 6, stated using that ordering predicate, actually talk about "urgency" and not about a number-comparison trick).

**Source: PLUMBING**, all 8. They're proven with no induction: the seven about small types by checking every case (types with 2, 3, 4 or 7 values), and `fin_eq_sound` field by field, applying those lemmas to the eight fields of the control state.

---

## 10. Summary: what's from JET and what's ours

| Source | What it means | Count |
|---|---|---|
| **JET FACT** | Quoted nearly word for word from a published paper | 44 |
| **ASSUMPTION** | Our own modelling decision, declared | 140 |
| **MIX** | JET's mechanism, our exact form | 32 |
| **PLUMBING** | Part of the proof method, doesn't speak about JET | 18 |
| **Total** | | **234** |

What changed in revision 4: 5 new laws in §6.8 (2 JET FACT and 3 MIX, after an audit of the same day), 2 ASSUMPTION (`inst4_table`, `inst4_mask`) and 5 MIX (`inst4_second_alarm_ptn` and the four `sec_*`). The same audit moved seven laws that already existed from JET FACT to MIX, because each one states something no paper says: `dms_window_Termination` (it extends the valve window to the whole termination phase, A-10); `ptn_deenergizes` (P2) and `ptn_no_heat`, which switch the heating off on every path to the PTN (A-9); `stop_reduces_power` (P3) and `d2_soft_stop_ramps` (D2), which bring both units down on every soft stop (A-9); `heat_permissive` (P5), whose exact form is ours (A-5, A-8, A-9); and `advance_frozen` (P19), which pins the counter commands (A-11, A-12). The other laws that already existed keep their label, but several now say which part is fact and which part is our policy (P1, D1, E3, F1a, F1e, `fast_ptn`, the `_Fast` and `_BothHs` cells, `dms_on_*`). A review of 2026-09-23 applied the same rule to four more laws: `dms_no_heat` moved from JET FACT to MIX (that the heating stays off after the injection is A-9), and `dms_monotone` (P15), `dms_frame` (P17) and `f3b_commfault_masked_is_noop` moved from ASSUMPTION to MIX, because besides their part of ours they state something JET publishes ([S6], R-14, [S1]).

**Why are there so many more "assumption" laws than "fact" ones?** It's not that the model drifts away from JET. 101 of the 140 are configuration cells and data that JET doesn't publish or that belong to our own instances: the columns and the row missing from Table 1, instances 2, 3 and 4, the valve wiring and the masks (`asm_*`, `inst2_*`, `dms_trig_*`...). Of the 39 behaviour laws labelled "assumption", about 18 are **frame** laws (the ones that say "and nothing else moves"). No engineering paper ever publishes a sentence like "and nothing else happens" — that's exactly the kind of detail that has to be filled in to be able to prove anything with mathematical precision, and that's why those laws end up classified as ours. It's not a weakness of the model — it's, literally, the work required to be able to prove anything in the first place.

Twelve laws are **"derived"**. All twelve are in the project's canonical list (`pymodel/jetprot_laws.py`): `d3_advance_to_termination_ramps`, `d5_hb_counts`, `d9_heatack_fires`, `d10_reset_accepted_when_safe`, `f1b_stop_keeps_prog`, `f2a_local_reduces` and, since revision 4, `p1a_ptn_latched`, `p1b_stop_never_cleared`, `d1a_ptn_honoured` and `d1b_primary_honoured`, and since the audit of 2026-09-22 `ramping_never_returns` (P4) and `stop_overrides_heat` (P6). These last two follow from P5 and P7 together: a unit can only regain power through its own "turn on" command (P7), and that command only works from off and with no stop (P5). That audit found this and checked it on every cell of the Python reference model. The fifth new law of revision 4, `piw_after_ptn_is_noop`, is not derived. They're kept documented because each is the named statement of something that matters (a JET quote, a declared assumption), but each one is covered by other, more general laws (`d1a_ptn_honoured` only on the states that satisfy the invariant), so they shouldn't be counted as additional independent evidence. Being derived doesn't change a law's origin: `f2a_local_reduces` is still a JET FACT, for instance.

---

## 11. Quick glossary

| Term | What it is |
|---|---|
| **Bend** | The programming language the proofs are written in; a computer checks them with total mathematical precision. |
| **Certificate** | Brute-force verification, done by computer, of every possible combination of a check. |
| **CISS / PSACS** | Two JET layers not modelled here: the CISS (Central Interlock and Safety System), hardwired plant protection ([S1]), and the PSACS (Personal Safety & Access Control System), which protects people ([S2]). This project models RTPS+PTN, which protects the equipment. |
| **DMS / DMV** | Disruption Mitigation System/valve: injects emergency gas into the plasma. |
| **Event** | Something that happens and can change the state (an alarm, a command, a clock tick, a reset). |
| **Invariant** | A property that holds always, with no exceptions, from start-up to the end. |
| **JTT** | *Jump-to-Termination*: a soft stop that moves the waveforms straight to the termination region, without going through the PTN. |
| **Law** | A mathematically proven statement about the model. |
| **PTN** | *Pulse Termination Network*: the final, hardwired, latched emergency stop. |
| **RTPS** | *Real-Time Protection Sequencer*: the "brain" that decides how severe the response should be. |
| **State** | The "snapshot" of all of JET's relevant data at one instant. |
| **Trace** | The complete sequence of events of a pulse, start to finish. |

---

For the exact code, without the extended explanations, and with a line-by-line breakdown of every predicate, see `LEYES_CATALOGO.md` in this same folder (Spanish).
