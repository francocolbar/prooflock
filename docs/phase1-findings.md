# Phase 1 — Findings: 1-D heat equation, symbolic → generated → numerical → verified

Date: 2026-09-18. Everything that follows is reproduced with `py -3.14 bend-spike/heat/run.py` (the numbers come from `heat/results.json`). Environment: Bend 2.0.6 via bun on Windows, JAX 0.11.2 float64 on Python 3.14 (see `env/SETUP.md`).

## What was built (`bend-spike/heat/`)

| File | What it is | Lines (code without comments) |
|---|---|---|
| `ir.bend` | Expression IR (`Var/Const/Add/Mul`), exact semantics `eval` over `Nat`, simplifier (constant folding, `x+0`, `0+x`, `1·x`, `x·1`, `0·x`, `x·0`), scheme `r = p/2^q`, weights, stencil tree, printers to IR and to Python/JAX | 155 |
| `LAWS.bend` | 4 laws: `simplify_sound` (induction), `weights_sum` and `weights_symmetric` (by computation), `linear_exact` (algebra over symbolic `Nat`) | 14 |
| `PROOF.bend` | The proofs: 3 `Nat` lemmas + 10 mirror lemmas of the simplifier's helpers + 4 sum lemmas for `linear_exact` | 167 |
| `emit.bend` | `main` that prints to stdout the Python/JAX module with `step(u)` generated from the simplified tree | 27 |
| `oracle.bend` | Plan A: the same `IR.eval` over the **raw** tree, `Nat` numerators (< 2^48), input via environment variables | 58 |
| `big.bend` | Plan B: custom bignum (limbs base 2^16): `add`, `mul`, `mul_small`, `from_nat`, `dump` | 56 |
| `oracle_big.bend` | Plan B: `eval_big` (mirror of `IR.eval` over `Big`) and the same iteration | 77 |
| `run.py` | Orchestrator: proof gate, emission, JAX f64 and f32, oracles, comparison, `results.json` | 154 |
| `tests/` | `smoke.bend`, `big_test.bend` + `run_big_test.py` (bignum vs Python's `int`), `sympy_equivalent.py` (the same pipeline in Python without proofs, to compare size) | — |

Circuit: `run.py` runs `bend PROOF.bend` (gate), `bend emit.bend > kernel_heat.py`, imports the kernel and runs it in JAX, runs `bend oracle.bend` and `bend oracle_big.bend` with the initial condition in `BEND_IC` and the steps in `BEND_N`, parses the numerators into `fractions.Fraction` and compares.

## What closed

The five points of the statement, plus plan B:

1. **PDE + discretization as a tree, with a real transformation.** `stencil(Scheme{1n, 2n})` produces the raw tree `Add(Mul(Const 1, Var 0), Add(Mul(Const 2, Var 1), Add(Mul(Const 1, Var 2), Const 0)))`; `simplify` leaves it as `Add(Var 0, Add(Mul(Const 2, Var 1), Var 2))`: two multiplications by 1 and one addition of 0 eliminated. For `r = 1/2` the central weight is 0 and the simplifier deletes the whole term (`Add(Var 0, Var 2)`). There is no CSE: a 3-point stencil has no common subexpressions; I did not force it.
2. **Kernel emission.** Route A (stdout). 19 lines of Python with `@jax.jit def step(u)`, `inner = (u[:-2] + ((2.0 * u[1:-1]) + u[2:])) / D`, plus the raw tree and the simplified one as a comment.
3. **Run in JAX float64.** 10 points, Dirichlet 0, initial condition `sin(πx)` quantized to 2^-21 (exact in float64, verified with an `assert`), `r = 1/4`, `dx = 1/9`, `dt = r·dx²`. Also run in float32 for contrast.
4. **Exact oracle.** Plan A: 13 steps (the maximum with `Nat < 2^48`: the final numerators use 47 bits). Plan B: 200 steps with the custom bignum; 413-bit numerators; **matches Python's `Fraction` bit for bit** on the same scheme (`assert` in `run.py`).
5. **Comparison.** See table.
6. **The four laws proven**: `bend PROOF.bend` → `All terms check.` in 0.2 s.

### Numbers

| | Plan A, N = 13 (t = 0.040, amplitude 0.67) | Plan B, N = 200 (t = 0.617, amplitude 2.2e-3) |
|---|---|---|
| JAX f64 vs exact oracle, max abs error | **0** (exact) | 5.8e-19 |
| same, relative to max\|u\| | 0 | 2.7e-16 (≈ 1.2 ε₆₄) |
| Trivial bound N·ε₆₄ | 2.9e-15 | 4.4e-14 |
| JAX f32 vs exact oracle, relative | 1.2e-7 (≈ 1 ε₃₂) | 1.0e-7 (≈ 0.8 ε₃₂) |
| JAX f64 vs analytic `e^{-π²t} sin(πx)` | 1.34e-3 | 6.8e-5 (3% relative) |
| Oracle vs analytic | 1.34e-3 | 6.8e-5 |
| Oracle vs closed form of the discrete scheme `g^N sin(πx_i)`, `g = 1 − 4r sin²(πdx/2)` | 3.7e-8 | 1.1e-10 |

Reading:

- **The float64 error is where theory says, and a bit better.** The scheme is a convex combination (non-negative weights summing to 1), non-expansive in max norm, so the accumulated rounding is bounded by N·ε·max\|u\|; what is observed is ~1 ulp in both precisions, far below the bound. In plan A the error is **exactly zero**: with 47 bits of numerator everything fits in float64's 53-bit mantissa and no operation rounds. I anticipated it in Phase 0 ("if it comes out exactly 0, it is because small dyadics are exact in f64"), and it is the underlying reason why plan A is not enough to measure rounding: to see it more than 53 bits are needed, i.e. more steps than `Nat` allows.
- **The difference against the analytic solution is discretization, not rounding.** JAX and the oracle give the same number against the analytic solution down to the last reported digit. At N = 13 Phase 0 predicted ~1e-3 (dominated by O(dx²) with dx = 1/9): it came out 1.34e-3. At N = 200 the 3% relative is the error in the decay rate of the `sin(πx)` mode accumulated over 6 characteristic times. The oracle matches the closed form of the discrete scheme down to the quantization level of the initial condition (2^-22 ≈ 2.4e-7, attenuated by the decay): the oracle computes exactly what the scheme says, and the scheme differs from the PDE by what theory says.
- **Bend's oracle is worth it as an oracle**: it matches `Fraction` over 200 steps. But that check was done by Python; the bignum's correctness is **tested, not proven**.

## What did not close or closed differently

- **"Rationals over unbounded `Nat`"**: does not exist. Plan A covers up to 13 steps (47 bits). Plan B needed 56 lines of bignum without proofs. Proving `to_nat(add(a,b)) == add(to_nat a, to_nat b)` with carry in base 2^16 is a separate project (`Nat.divmod` with divisor 65536 is opaque except by computation: the proof would be over symbolic `Nat.div`/`Nat.mod`, "hard" level in the cookbook). I did not attempt it.
- **Signed rationals**: avoided by design (`r ≤ 1/2` gives non-negative weights). Any scheme with negative weights (high-order upwind, Runge-Kutta with negative coefficients, the Laplacian as such) breaks the `Nat` semantics and forces a custom `Z` type with its algebra and its lemmas. That is the real limit of the approach, not the 48 bits.
- **F32 takes part in nothing**: the laws speak about the exact semantics; about the generated float nothing is proven nor can be proven in Bend. The kernel ↔ oracle connection is "same tree, exact semantics proven equal"; the step from that semantics to float64 is guaranteed by the dyadic quantization and the test, not by the checker.

## Where it hurt (each point cost at least one checker round)

1. **Destructuring a computed value is forbidden**: `(d, m) = Nat.divmod(x, b)` fails with "a match cannot scrutinize a computed value". The official way out (passing the pair to a helper that destructures it) creates mutual recursion with the bignum, also forbidden. Solution: `Nat.div` and `Nat.mod` separately over a shared `+t`. Same problem in the IO `do`: `(f, r) : File & Result <- File.write(...)` does not parse; one has to bind to a name and pass it to a helper.
2. **Affinity**: `k` used in `Var{k}` and in `1n+k` → `+k`; the path read from `IO.get_env` used twice (open and print) → error; `+s`, `+e`, `+simp` in the emitter. Each one is trivial to fix and the message is clear (`consumed more than once`), but one does not see it coming without the checker.
3. **Almost nothing is inferred**: lets inside `do` need `x : T = v`; `List.show` demands `~&2, ~Nat, ~Nat.show` (three templates, all with `~`); large `Nat` literals are expanded into unary in the parser, so the bignum's base is `U32.to_nat(65536)`.
4. **Recursion over two lists** (addition with carry): the first one that decreases has to be the first parameter and an argument cannot be "reconstructed" (`Big.add_go(Nil{}, yt, d)` does not pass the termination check). Way out: a separate function to propagate the carry over the leftover list.
5. **Designing for the checker**: the simplifier was written as 10 helpers that `match` on ONE parameter each, so that each correctness lemma is an exact mirror of the helper. With that discipline, `simplify_sound` (14 lemmas, 105 lines) **closed on the first attempt**; the two laws by computation closed with `{==}`. `linear_exact` was closed by the prover agent in 2 iterations with 4 sum lemmas (~30 lines); the hard part was seeing the exact reduced goal (`?goal`) before writing the rewriting motives, and the orientation (the term to be eliminated goes on the right-hand side of the lemma).
6. **JS backend performance**: 0.2–0.3 s per invocation (bun startup + checking), 4.3 s for the 200-step bignum oracle over linked lists. Irrelevant for an oracle; unacceptable for anything else. There is no native backend on Windows.

## How much code: Bend vs Python + sympy

| | Bend | Python + sympy + `Fraction` (`tests/sympy_equivalent.py`) |
|---|---|---|
| Pipeline without proofs (IR, simplifier, scheme, printer, oracle, bignum) | 373 lines of code | 41 lines of code |
| Laws + proofs | 181 lines | no equivalent exists |
| Total | 554 | 41 |

The ratio is ~9× without counting proofs and ~13× with them. What explains the difference: sympy brings simplification, printing and unbounded rational arithmetic out of the box; Bend brings none of that and moreover forces one to write the simplifier with a structure the checker can follow. **What the 181 lines of laws and proofs buy is the only thing sympy cannot give**: the machine-checked guarantee that `simplify` does not change the exact meaning of any tree, that the stencil sums to the denominator (CFL), that it is symmetric, and that it is exact on linear profiles for all `a, b`, not for tested values. `sp.simplify` is a black box one trusts.

## Verdict on hypothesis 1 + A + 2'

**Viable today, and it closed in one day of work.** The PoC proves that Bend 2 can be the symbolic front-end of a kernel generator with demonstrated transformations and with an exact oracle of the same IR. The value is in the proofs; without them it is a worse sympy, and with them it is something no tool in the Python stack offers.

What the PoC does **not** prove, and must be said before extrapolating to fusion:

- Simplifier scale: 16 cases per binary operator with the smart-constructor pattern. Associative-commutative normalization, CSE with sharing, two and three dimensions, non-trivial boundary conditions and variable coefficients multiply the cases and the laws. The largest official demo of this kind (`proof_typed_eval`) has 3 rules; the "hell" eval in the cookbook reaches 840 lines of proof per program.
- Exact semantics with sign and division: mandatory for any real scheme. It is a custom `Z`/`Q` type with its proven algebra before anything can be stated.
- Nothing about floats: the generator certifies the scheme, not the kernel compiled by XLA.

## Proposed next step (Phase 2, pending confirmation)

The next hypothesis in the Phase 0 ranking that Phase 1 does not cover is **4** (verified supervisory logic), extended with **B** (certificates by computation) and **C** (total reference model called from Python for differential testing): a miniature tokamak discharge sequencer, with safety invariants proven over all traces, decisions over the finite space by computation, and the model exposed via JS loader to a Hypothesis suite that compares it against a "production" implementation in Python with a planted bug. Same size and same measurement standard as this phase.
