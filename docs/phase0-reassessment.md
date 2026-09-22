# Phase 0 — Reassessment of the question with real knowledge of Bend 2

Date: 2026-09-18. Bend 2.0.6 (source commit `67692d7f`, run with bun 1.3.11 on Windows 11 without WSL or clang). Everything stated about the language is verified on this machine or cited from the official guide / runtime paper (copied into my `bend2` and `bend2-laws` skills); whatever I could not verify here is marked **[not verified here]**.

## Corrections to the prompt (where what I know about the real language wins)

Before the audit, four premises of the prompt that do not match Bend 2 as it exists today:

1. **Bend 2 does not run on interaction nets.** That was Bend 1 / HVM2. The Bend 2 runtime (BendRT) is a compiled machine with move semantics: every def is cut into `tail / cut / fork` segments, values have a single owner (which is why there is no GC), and parallelism is fork-join over a fixed scheduler ("the cube": 2^14 rings, no work stealing, no shared queue). "HVM5" exists, but as a *demo written in Bend* (`demos/pure_hvm5_mini`), not as a runtime. Consequence: the argument "interaction nets are good for irregular tree-like computation" does not apply. What does apply is the opposite: the scheduler **never rebalances**, so unbalanced search trees (pruning) are the documented worst case (queens: GPU 0.93 s vs 16 cores 0.46 s).
2. **`Nat` is not unbounded.** It is a 48-bit immediate at runtime: passing 2^48−1 aborts with `bend: a Nat past the largest immediate 2^48-1`. I verified it in all three evaluators: in-process JS runtime, emitted JS run with node, and the checker's normalizer (which expands literals into unary and blows the stack). There is no bignum in Base. Point 2 as written is not implementable.
3. **"Synthesis" does not exist in 2.0.6.** The compiler has `?name` (prints the goal and fails) and `?TODO` (leaves the hole open), but it does not fill in proofs or programs. There are no tactics, no proof search, no inference of almost anything (every literal, every `do` bind, every operator carries its type).
4. **"Single-thread much slower than C" is too pessimistic.** According to the runtime paper, native sequential execution sits at 0.8–1.5× of the C twin (pointer-chasing and strings 2–4× worse). What is true: only `F32` (no F64), single-owner arrays, and on Windows the native backend does not even exist. The verdict on the hot layer does not change: Bend 2 does not compete there. But for the right reasons: F32 and lack of ecosystem, not sequential speed.

Two premises that are correct: affine, non-shareable arrays (they are `Type`-kinded, one owner, explicit `Array.clone`) and `F32` as the only float (and axiomatic as well: nothing is provable about floats).

---

## 1. Reformulation of the question

Original question: *"how does one innovate in fusion (or physics simulation in general) using Bend 2 as a complement to the current stack?"*

Reformulated in terms of what Bend 2 is: **which parts of a simulation pipeline benefit from being written in a total language (mandatory termination), with dependent types and compile-time-checked proofs, whose output can be text (generated code), importable JS, or POSIX C, and whose arithmetic is limited to `Nat < 2^48`, `U32` and `F32`?** The answer is not in the runtime (which on this machine does not even exist in native mode) but in the **checker**: it is the only component of Bend 2 that does something JAX + Python + sympy do not.

Property by property, for this domain:

| Property | What it really is | Value for physics simulation |
|---|---|---|
| Affine semantics | Every variable is used ≤ 1 time; `+x` allows reuse only on `Data` types (never on functions, arrays, handles). Closures are called exactly once. | **Neutral in the symbolic layer** (expression trees are `Data`, copied with `+`). **Counterproductive for numerics** (no array aliasing; `Array<T>` is single-owner). It is what enables logical consistency with `Type : Type` and a GC-free runtime, i.e.: it is the price of the proofs, not a domain feature. |
| Mandatory termination | Every recursive call must decrease structurally in one argument (the first one that changes). No mutual recursion. `@unsafe` skips it but voids the guarantees. | **High for supervisory logic** (everything terminates, every `match` is exhaustive: the properties that safety-critical code standards demand). **Cost for search** (a `Nat` fuel has to be threaded). Irrelevant for numerics. |
| Dependent types | Types indexed by values (GADTs via "Ford's trick": fields `eq: {TNum{} == t : Ty}`), predicates as types (`LE`, `Sorted`), `Sigma`, propositional equality `{a == b : T}`. | **High**: expression IR well-typed by construction, provenance as an index, certificates as values. Verified today: `Field<3n, 7n>` vs `Field<3n, 8n>` is a type error. |
| Compile-time proofs | `law` (statement) + `def` (proof). Primitives: `{==}` (reflexivity after unfolding definitions), `match` (induction/cases), `%e : P` (rewriting), `Equal.sym/trans/cong`, refutation by motive. No tactics. | **The central property.** Two modes: (a) structural induction over IR/traces (the proofs of the `proof_typed_eval` demo: 59 lines for a 3-rule optimizer); (b) **proof by computation**: if the statement is closed and decidable, the checker normalizes it and `{==}` closes it (idiom `T(check_all()) := Unit{}`). On floats: nothing (F32 is axiomatic). On `Nat`: everything, but unary in the checker (large literals are expensive). |
| HVM / parallelism | Static fork-join (`a b = f(x) g(y)`), balance is up to the program, GPU only for uniform work (mandelbrot/nbody 60–120× vs sequential; divergent search loses against 16 cores). Requires clang ≥ 14 and POSIX. | **Irrelevant for this spike** (does not exist on Windows) and **weak for pruned search** by scheduler design. Where it would shine (uniform kernels) is precisely the hot layer we discarded because of F32. |
| Synthesis | Does not exist. | — |
| I/O and interop | `IO` monad with effects: print, files (write-only on Windows), env vars, channels. Foreign effects in C or JS (not Python). JS loader: `import X from "./x.bend"` exposes pure defs as JS functions. Emits C (POSIX) and JS. No argv, no stdin. | **Sufficient** to emit code and data as text and to expose pure functions to node. Verified today: three routes (stdout → .py, `File.write` with path via `BEND_OUT`, and `node --import` of the loader). There is no FFI to Python; integration is via subprocess + text/JSON. |
| Number system | `Nat < 2^48` (unary in the checker), `U32`, `F32`. No F64, no signed integers, no bignum, no rationals. `U32` is opaque to the checker except by computation on literals. | **The hard limit of the spike.** Exact oracle: either hand-rolled bignum (`Nat` limbs base 2^16) or instances that fit in 48 bits. Proofs go over `Nat`; float is generated code only. |
| Packages by hash | `import 0x<hash>/main.bend` downloads and verifies by content hash; `--publish` uploads. **[not verified here]** | Provenance of the symbolic code at module level, for free. |

Summary: for this domain, Bend 2 is worth it for **checker + dependent types + text emission**. The parallel runtime and affinity are irrelevant or a cost. Arithmetic is the constraint one has to design around.

---

## 2. Audit of the 5 points

### Point 1 — Symbolic front-end that emits JAX/CUDA kernels

**Does the mechanism exist?** Yes. Three routes verified today with a real hello-world (`env/hello/`, log in `env/check_env.log`):
- A: `IO.write(src)` → stdout → redirected to `.py` → `py -3.14` runs it. (This is the one I will use: no paths, no state.)
- B: `File.open/write/close` with the path read from `IO.get_env("BEND_OUT")` (Bend has no argv). Works on Windows.
- C: JS loader: `node --import file:///…/bend2/main.ts app.mjs` with `import Lib from "./lib.bend"`; pure defs are called from JS and constructors arrive as `{$: "Add", a, b}`. Useful for Python to call Bend functions via subprocess+JSON without writing a `main`.

There is no FFI to Python nor export of Python modules. `String` is a linked list of chars (one node per character): generating a few KB of kernel is trivial, generating MBs is not.

**How someone who knows Bend 2 would do it vs how it is described.** As described (Bend as a "code generator that runs once"), it is a worse sympy: no algebra, no built-in simplification, with slow strings and no bignum. The version of someone who knows the language is that of the `proof_typed_eval` demo: an **intrinsically typed** IR (`type Expr<-t: Ty>` with Ford's trick, impossible to build an ill-typed term), a reference evaluator `eval : Expr<t> -> Val(t)` over exact semantics (`Nat`), a transformation pass `opt`, and the law `eval(opt(e)) == eval(e)` **proven** by induction over the IR. The printer to Python/JAX is a trivial `show`. That is: point 1 only makes sense in Bend if it comes with point A of section 3 (proven transformations). Without that, it adds nothing over sympy.

**Verdict: viable today**, but the value is in the pair "generator + correctness law", not in the generator.

### Point 2 — Exact oracle in rational arithmetic over unbounded `Nat`

**Does the mechanism exist?** **Not as stated.** `Nat` aborts at 2^48−1 (verified in checker, runtime and emitted JS). There is no bignum nor rationals in Base. Nor signed integers: `Nat.sub` saturates at 0, `U32.sub` wraps around.

**How someone who knows Bend 2 would do it.** Three ways out, from least to most effort:
1. **Design the instance so that it fits in 48 bits.** The heat scheme with r = α·dt/dx² = 1/4 is `u_i' = (2u_i + u_{i-1} + u_{i+1}) / 4`: non-negative coefficients (avoids the sign) and dyadic (denominator 2^e, avoids the gcd). If the initial condition is quantized to m bits (values k/2^m, exactly representable in float64), after N steps the numerators have ≤ m + 2N bits. With m = 21 and N = 13 it fits in 47 bits. **The oracle is then literally the same `eval` function over which the simplifier's law is proven**: there is nothing extra to verify.
2. **Hand-rolled bignum**: numerators as `List<&2, Nat>` of limbs base 2^16 (one has to use `Nat`, not `U32`, if anything is to be proven: `U32` is opaque to the checker). For this scheme only addition and doubling are needed (the denominator is a separate `Nat` exponent). ~40–60 lines; testable against Python's `int`; proving `to_nat(add(a,b)) == to_nat(a) + to_nat(b)` with carry is "firm/hard" level in the cookbook.
3. **Another tool**: Python's `fractions.Fraction` does the oracle in 5 lines, without limit, and it is what anyone uses. Bend only wins if the oracle is *the same IR* that generated the kernel (that is how one proves that kernel and oracle implement the same scheme). That is the only argument in favor.

**Verdict:** as written, **not viable**. Reformulated as "oracle = exact evaluator of the same IR, on instances that fit in 48 bits (or with a custom bignum)", **viable today**. If only an oracle is wanted, **the idea works but with another tool: `fractions.Fraction`**.

### Point 3 — Combinatorial exploration of the design space (enumerate + prune topologies)

**What does affinity imply for a tree search with pruning?** Little if the candidates are `Data` (`+cand` copies them; a list or tree with `+` becomes reference-counted throughout the program, acceptable). Recursion over the search tree is natural. What it does imply:
- **Termination**: depth goes as a structural `Nat` (first parameter). Normal.
- **No shared state**: classic branch-and-bound (a global incumbent bound that prunes sibling branches) **does not exist**: either the bound is threaded sequentially (goodbye parallelism) or each subtree prunes only with local bounds. Static pruning (feasibility) does work.
- **Parallelism**: the scheduler does not rebalance; a pruned tree is unbalanced by definition. The performance documentation lists it as the main anti-pattern ("cube never rebalances: lanes idle until the slow child ends"). On this machine, moreover, there is no native backend: zero measurable parallelism.
- What Bend would give and nobody else: **proving that the enumerator is complete** (every valid topology appears) or that the pruner is sound (never discards a feasible one), by induction. It is a "hard/hell" level proof in the cookbook (sound+complete decision procedures: 333–840 lines in the evals).

**How someone who knows Bend 2 would do it.** Enumeration by index over a power-of-two space with the feasibility test at the leaf (so the fork is balanced), without a global bound, and only if the "sound and complete" property justifies the proof effort. For real design exploration (coils, divertor topologies) the tool is a solver (OR-tools, Z3) or Python + numba; the continuous part is already JAX.

**Verdict: viable with work, low value with current Bend.** The idea works but with another tool (Z3/OR-tools for pruning with bounds; JAX for the continuous part). The only angle of Bend's own is the completeness proof, and it is expensive.

### Point 4 — Verified supervisory control logic (state machines, interlocks)

**What can really be proven and with how much effort without tactics?** I measured it today with a toy interlock (`env/interlock/`): 3 states (Idle/Armed/Firing), 3 events (Arm/Fire{permit}/Abort), `step`, `run` over traces, and two laws:
- `fire_guard`: "Firing is only entered from Armed with permission". Proof: `match s e` with the 12 cases, each one `{==}` (the checker unfolds `step` and compares). **Closed in minutes.** And before closing it **found an error in the specification**: the first version said "not be in Firing after the step except in the Armed+Fire{True} case", and the checker returned the exact counterexample (`case Firing{} Arm{}`: staying in Firing is not entering). That is the concrete value: the counterexample comes for free from the case that does not reduce to `True{}`.
- `never_firing`: "from Idle, no trace without `Fire{True}` reaches Firing". Proof by induction over the trace, generalized to any non-Firing initial state, with refutation of the hypothesis `{False{} == True{}}` by motive. **52 lines, 2 checker iterations, ~2 minutes of a subagent** (bend-prover). Total: program 60 lines, laws 12, proofs 83. Checker: < 0.5 s.

What can be proven: safety invariants over all traces, determinism, absence of forbidden transitions, reachability properties of finite spaces **by computation** (`{check_all() == True{} : Bool}` closed with `{==}`, no induction: the checker enumerates). What cannot: real time, hybrid dynamics (nothing continuous: F32 is axiomatic), unbounded liveness (there is no coinduction), anything about the code that actually runs on the PLC.

**How someone who knows Bend 2 would do it vs how it is described.** As you described it, with two refinements: (i) prefer proof by computation when the space is finite (cheaper than induction; it scales badly only because the checker is unary in `Nat`); (ii) the C that Bend emits is POSIX, reserves 8 TiB of virtual space and brings its runtime along: **it is not going onto a PLC**. The realistic role is **executable reference model** (golden model) with proven properties, against which the real implementation is differentially tested (see point C).

**Alternatives**: TLA+/Apalache, nuXmv (model checking is the industry standard for interlocks and scales better than a unary checker). Bend's advantage is that the specification, the proof and the executable model are the same file, and that the model can be called from node/Python.

**Verdict: viable today.** It is the hypothesis with the best value/risk ratio of the batch.

### Point 5 — Typed provenance

**Does the type system allow indexing a type by a value?** Yes, verified (`env/provenance/`): `type Field<-ver: Nat, -geom: Nat> is Data` with erased indices (`-`: zero runtime cost), `solve(-g, seed) -> Field<3n, g>`, and a diagnostic that demands `Field<3n, geom_a()>` rejects `solve(geom_b(), …)` with `expected : Field<3n, 7n> / observed : Field<3n, 8n>`.

**A limit an outsider does not see.** The indices are **closed terms known at compile time**. Real provenance (hash of a geometry file read at runtime, version of a data library) cannot be lifted to the type without a runtime check that produces a `Sigma`/GADT, that is: the same as a `dataclass` with `assert` in Python. What the type guarantees at compile time is the **internal wiring of the Bend code** (that no program path connects a result from geometry A to a consumer of B). Useful inside a pipeline written in Bend; useless as an outward contract, because outward everything is text.

**How someone who knows Bend 2 would do it.** With content-hash packages (`import 0x<hash>/…`): the identity of the symbolic code is cryptographic and enforced by the compiler. The emitted kernel carries the generator's hash in a comment, and data provenance is handled where it lives (manifests, DVC). **[not verified here: requires `--publish` and network]**

**Verdict: viable today, low value.** The idea works but with another tool for data (manifests with hashes / DVC); for code, Bend's hash packages are better than a git SHA.

---

## 3. Points you did not see

### A. Proven transformation passes over the discretization IR

**Feature**: GADTs via Ford's trick + definitional unfolding + `%e` rewriting. The `proof_typed_eval` demo (136 lines of program, 19 of laws, 59 of proofs) proves `eval(opt(e)) == eval(e)` and `opt(e) == lit(eval(e))` for a 3-rule constant folding. A finite-difference kernel generator is this very thing: IR (`Var` with offset, `Const`, `Add`, `Mul`), a simplifier (folding, identities, CSE), a printer. The law "the simplifier does not change the exact meaning" turns the generator into something sympy cannot be: a scheme compiler with demonstrated correctness. It is what Devito, PSyclone, Firedrake/UFL do by hand (and without proofs). It is the reason point 1 is worthwhile in Bend.

### B. Discrete certificates by computation (reflection)

**Feature**: the checker normalizes closed terms; `def T(b: Bool) -> Data` (True→Unit, False→Empty) and `T(check()) := Unit{}` is a proof. It works for any decidable property of a finite object: that the weights of the generated stencil sum to the denominator (order-0 consistency), that the odd moments cancel (order 2, expressible without sign as Σ_{k>0} c_k·k == Σ_{k<0} c_k·|k|), that a coefficient matrix is symmetric, that all 3^k combinations of an interlock are safe. It costs one line per certificate and the checker takes milliseconds. Limitation: `Nat` is unary in the checker, so the certificate's numbers have to be small (hundreds, not millions).

### C. Total reference model + differential testing against production code

**Feature**: totality (termination + exhaustive `match` + no null nor exceptions) + JS loader. A Bend program that checks is a total function over its types: no undefined paths. Exposed via `node --import` (verified), it can be called from Python with random inputs (Hypothesis) and compared against the real code (Fortran/C++ of a protection system, or the sequencing logic of a tokamak). It is classic V&V with an oracle that moreover has its properties proven. It replaces nothing: it is added alongside.

### D. Cryptographic identity of the code generator

**Feature**: `import 0x<hash>/main.bend` (content-hash hub). Every emitted kernel can carry the hash of the generator that produced it, and that hash is verified by the compiler on import, not by a script. Provenance of code, not of data. Minimal effort; **[not verified here]**.

---

## 4. Ranking

(a) potential value for the domain (fusion: control, MPS/interlocks, V&V of safety codes, kernel generation); (b) probability that the PoC closes in a weekend **on this machine** (Windows, bun, no native).

| # | Hypothesis | (a) Value | (b) Closes in a weekend | Why |
|---|---|---|---|---|
| 1 | **1 + A + 2'**: kernel generator with proven simplifier, plus exact oracle = the same IR evaluated in `Nat` | High | Medium-high | The pattern exists (typed_eval). Risks: the simplifier's proof if it has more than 4–5 rules; the oracle fits in 48 bits only with N ≈ 13 steps (bignum as stretch). |
| 2 | **4**: verified interlock (invariants over traces + certificates by computation) | High | High | Already closed in miniature today: 155 lines, counterexample found by the checker, 2 iterations. |
| 3 | **C**: total golden model + differential testing via loader | Medium-high | High | Loader verified; the work is Python (Hypothesis) more than Bend. |
| 4 | **B**: stencil certificates by computation | Medium | High | One line per certificate; attaches to PoC 1 at no cost. |
| 5 | **3**: combinatorial exploration | Medium | Medium | No measurable parallelism here; no global bound; the angle of its own (proven completeness) is expensive. |
| 6 | **D**: generator hash | Low-medium | High (but requires network and `--publish`) | Trivial; I did not verify it. |
| 7 | **5**: typed provenance | Low | High | Mechanism verified; only protects Bend's internal wiring. |
| 8 | **2** as written (unbounded `Nat`) | — | None | `Nat < 2^48`. |

**Explicit trade-off**: the two highest-value hypotheses (1+A+2' and 4) are almost tied; 4 is safer, 1+A+2' tests more things at once (emission, interop, proofs by induction, oracle, numerical comparison) and is the one that answers the thesis "symbolic layer over numerical layer". I choose 1+A+2' for Phase 1 and leave 4 (extended with B and C) as the natural candidate for Phase 2. If Phase 1 gets stuck on the simplifier's proof, the fallback is to reduce rules until it closes, not to jump to `@unsafe`.

---

## 5. Choice of the Phase 1 PoC

**I keep the 1-D heat equation**, with two changes with respect to what was described, both forced by what was verified above:

1. **The simplifier's law is added** (`eval(simplify(e), env) == eval(e, env)` over `Nat`, proven by induction). Without it, the PoC would produce by construction the conclusion "Bend adds nothing over sympy". With it, it tests the strongest hypothesis of the ranking.
2. **The oracle is not "rationals over unbounded `Nat`"** but non-negative dyadics within 48 bits (plan A), with a custom bignum as stretch (plan B).

### What gets built (`bend-spike/heat/`)

- `ir.bend`: `type Expr is Data: Var{k: Nat} | Const{c: Nat} | Add{a, b} | Mul{a, b}` (the stencil offsets are encoded as indices into the environment vector; the denominator 2^e stays as a `Nat` outside the tree because the scheme is linear with non-negative integer coefficients: `u_i' = (2u_i + u_{i-1} + u_{i+1}) / 4` for r = 1/4). `eval(e, env: List<&2, Nat>) -> Nat`. `simplify`: constant folding, `Mul(Const 1, x) → x`, `Add(Const 0, x) → x`, `Mul(Const 0, x) → Const 0`, and a trivial CSE if time allows. `build_stencil(r)` generates the step's tree from the discretized PDE.
- `LAWS.bend`: `simplify_sound` (induction); `stencil_sum` (Σ c_k == 2^e, by computation with `{==}`); `stencil_symmetric` (Σ_{k>0} c_k·k == Σ_{k<0} c_k·|k|, by computation). `PROOF.bend` with the proofs; gate `All terms check.`.
- `emit.bend`: `main` that prints the Python module to stdout: `step(u)` in JAX (vectorized with slices, `jnp.float64`), constants as `c_k / 2**e`, and a comment with the simplified tree. Interop route A.
- `oracle.bend`: `main` that runs N steps of `eval` per point over `Nat` numerators (common `Nat` exponent), 10-point grid with Dirichlet (boundaries at 0), initial condition quantized to m = 21 bits, and prints one line per step with the numerators and the exponent (decimal). Plan A: N = 13 (m + 2N ≤ 47). Plan B (stretch): `Big` with `Nat` limbs base 2^16, N = 200, tested against Python's `int` (not proven).
- `run.py`: invokes Bend (portable), saves `kernel_heat.py`, imports it, runs N steps in JAX float64 with the **same** quantized initial condition (exact in float64), parses the oracle into `fractions.Fraction`, and reports.

### What gets measured

| Metric | How | What counts as "closed" |
|---|---|---|
| `bend PROOF.bend` | literal line `All terms check.` | The three laws closed without `@unsafe` or `?TODO`. |
| Emitted kernel runs | `run.py` imports `kernel_heat.py`, `jnp.float64` | N steps without error, dtype float64 verified. |
| JAX f64 vs exact oracle | max abs error over the 10 points after N steps | ≤ ~N × 2·10⁻¹⁶ (accumulated rounding error; with N = 13 expect ~10⁻¹⁵). If it comes out exactly 0, it is because small dyadics are exact in f64 and that has to be said. |
| Both vs analytic `e^{-απ²t} sin(πx)` | max abs error | Dominated by spatial discretization O(dx²) with dx = 1/9: expect ~10⁻³ (the discrete eigenvalue (2/dx²)(1−cos π dx) is ~1% below π²), plus Euler's O(dt). The oracle and JAX must give the **same** number to 10⁻¹⁵. |
| Code size | lines of Bend (IR + laws + proofs + emitter + oracle) vs an equivalent in Python with sympy + `Fraction` without proofs | Reported, no target: it is information for the README. |

If the `simplify_sound` proof does not close with all the rules, the rule set is reduced until it closes and it is documented which one was left out and why. If the bignum (plan B) does not close, the PoC closes anyway with plan A.

---

## 6. Environment verification

Reference run: `bash bend-spike/env/check_env.sh` (full log in `env/check_env.log`, pinned versions in `env/SETUP.md`).

| Item | Status | Evidence |
|---|---|---|
| Bend installed | **2.0.6** via bun 1.3.11 from `~/.bend-src` (commit `67692d7f`, 2026-09-18). No native binary: Windows without clang or WSL. | `bend --version` → `bend 2.0.6`. The 2.0.6 guide differs from the 2.0.5 one in my skill in a single line (description of the `bend file.bend` command): the skill remains valid. |
| JAX float64 | **jax 0.11.2, numpy 2.4.3, Python 3.14.3**, `jax_enable_x64` → dtype `float64`, CPU. Installed today with `py -3.14 -m pip install jax`. | `PASS jax float64 enabled` |
| Interop A (stdout → .py) | **Tested**: `emit_hello.bend` prints a numpy kernel, Python runs it and prints `[0.5]`. | `PASS interop A` |
| Interop B (`File.write`) | **Tested**: path via `BEND_OUT`; writes the file; Python runs it. | `PASS interop B` |
| Interop C (JS loader) | **Tested**: `node --import file:///…/main.ts app.mjs` imports `lib.bend`, calls `show(sample())` → `((2 * x) + 3)`. With node the `file:///` URL has to be passed; with bun `--preload` is enough. | `PASS interop C` |
| `Nat` cap | **Confirmed** at runtime (`a Nat past the largest immediate 2^48-1`) and in the checker (stack overflow on expansion). | `PASS Nat capped` ×2 |
| Proofs | Interlock: `All terms check.` in < 0.5 s. Provenance: mismatch rejected by type. | `PASS interlock`, `PASS provenance` |

What **cannot** be done on this machine and affects the spike: native binaries, GPU, real parallelism, `File.read`, sockets, `IO.sleep`, and any `Fail` path of an effect (calls libc via `bun:ffi`). None of that is needed by the chosen Phase 1.

---

**Status: Phase 0 finished. Awaiting confirmation of the PoC (1-D heat with simplifier law and dyadic oracle in 48 bits, plan A/B) before starting Phase 1.**
