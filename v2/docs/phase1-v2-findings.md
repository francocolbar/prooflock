# Phase 1 (v2) — Findings: the complete circuit over a proven numeric base

Date: 2026-09-18. Reproduce: `py -3.14 bend-spike/v2/heat/run.py` (the numbers come from `v2/heat/results.json`). Design and review of the laws in `phase0-v2-design.md`.

## What was built (`bend-spike/v2/`)

| Layer | Files | Content |
|---|---|---|
| Integers | `num/z.bend`, `LAWS_Z_ADD` (13), `LAWS_Z_MUL` (9), `PROOF_Z_ADD`, `PROOF_Z_MUL` | canonical `Z` by `succ`/`pred`; complete commutative ring proven |
| Big naturals | `num/big.bend`, `LAWS_BIG` (5), `PROOF_BIG` | lists of bits; adder with carry, `inc`, `from_nat`, all proven against `to_nat` |
| Big integers | `num/bigz.bend`, `LAWS_BIGZ` (5), `PROOF_BIGZ` | pairs `p − n`; `add`, `neg`, `scale`, `from_z`, `zero` proven against `to_z` |
| Heat IR | `heat/ir.bend`, `LAWS_HEAT` (7), `PROOF_HEAT` | IR linear by construction; normalizer to coefficients proven; scheme certificates |
| Oracle | `heat/oracle_core.bend`, `LAWS_ORACLE` (4), `PROOF_ORACLE` | evaluation and time step over `BigZ`, proven equal to the specification in `Z` |
| I/O | `heat/emit.bend`, `heat/oracle.bend` | JAX kernel to stdout; oracle via environment variables (bits) |
| Driver | `heat/run.py` | gates (proofs, grids, negative test), 2 schemes × 2 horizons, comparison with `Fraction` |
| Review | `tests/laws_z_smoke.bend`, `tests/laws_heat_smoke.bend`, `tests/cfl_violation_PROOF.bend`, `tests/big_smoke.bend` + `run_big_smoke.py` | instantiation of every law before proving it; negative test; bignum vs `int` |

Total: 43 laws, 43 proven. `py -3.14 v2/heat/run.py` → `all gates and checks ok: True`.

| Proof file | Laws | Lines (code) | Defs | Checker iterations until `All terms check.` | Who |
|---|---|---|---|---|---|
| `PROOF_Z_ADD.bend` | 13 | 397 (310) | 46 | 2 | prover agent |
| `PROOF_Z_MUL.bend` | 9 | 300 (215) | 34 | 1 (the whole file passed on the first try) | prover agent |
| `PROOF_BIG.bend` | 5 | 237 (173) | 26 | 4 (+14 probes of one `match` rule) | prover agent |
| `PROOF_BIGZ.bend` | 5 | 125 (83) | 12 | 1 | prover agent |
| `PROOF_HEAT.bend` | 7 | 164 (109) | 15 | 2 | prover agent |
| `PROOF_ORACLE.bend` | 4 | 90 (72) | 9 | 1 | written by hand before `PROOF_BIGZ` existed, passed once the import was enabled |
| **Total** | **43** | **1313 (962)** | **142** | | |

Each proof file runs in ~0.2 s. No law was relaxed, none was left `?TODO`, there is no `@unsafe`.

## Numerical results (identical before and after closing the proofs: the proofs do not change the code, they guarantee it)

10-point grid, Dirichlet 0, initial condition `sin(πx)` quantized to 21 bits (exact in float64), α = 1, `dx = 1/9`, `dt = r·dx²`.

| Scheme | N | t | max\|u\| | numerator bits | JAX f64 vs exact (rel) | JAX f32 vs exact (rel) | both vs analytic | exact vs discrete closed form |
|---|---|---|---|---|---|---|---|---|
| r = 1/4 | 13 | 0.040 | 0.66 | 47 | **0** | 1.3e-7 | 1.34e-3 | 3.7e-8 |
| r = 1/4 | 200 | 0.617 | 2.2e-3 | 413 | 2.7e-16 | 1.0e-7 | 6.8e-5 | 1.1e-10 |
| r = 3/8 | 13 | 0.060 | 0.54 | 60 | 6.3e-17 | 6.9e-8 | 4.2e-3 | 2.8e-8 |
| r = 3/8 | 200 | 0.926 | 9.4e-5 | 608 | 3.0e-16 | 5.3e-8 | 1.2e-5 | 4.8e-12 |

In all four runs Bend's oracle matches Python's `fractions.Fraction` **exactly** on the same scheme, and the negative test (`r = 3/4`, central weight −2) is **rejected** by the checker.

Reading:

- **Float64 rounding ≈ 1 ulp in all cases** (`ε₆₄ = 2.2e-16`), far below the `N·ε` bound. With `r = 3/8` and 13 steps the numerators already have 60 bits and float64 rounds (6e-17): confirms that v1's "zero error" was just that 47 bits fit in the 53-bit mantissa.
- **Float32 ≈ 1 ulp** (`ε₃₂ = 1.2e-7`) in all four cases. The scheme is a convex combination (`weights_nonneg`) and does not amplify rounding; that property is proven, not observed.
- **The distance to the analytic solution is discretization** and it is the same for JAX and for the oracle: the oracle matches the closed form of the discrete scheme `g^N sin(πx_i)` down to the quantization level of the initial condition.

## What changed with respect to v1 (and what it cost)

| | v1 | v2 |
|---|---|---|
| Exact semantics | `Nat` (unsigned) | canonical `Z` with proven ring |
| Stencil | precomputed weights `[p, D−2p, p]` | the textual physics `D·u_i + p·(u_{i−1} + (−2)·u_i + u_{i+1})`, normalized by `lin` |
| Proven transformation | constant folding (6 rules) | normalization to linear form (coefficient collection) |
| Stability certificate | `Nat.sub` saturating (a trick) | explicit `weights_nonneg` + rejected negative test |
| Bignum | limbs base 2^16, tested | bits, adder **proven**; big integers as `p − n` with laws via `to_z` |
| Oracle under law | only `eval` in 13 steps | `eval_big`, `step`, `iterate`: the whole run except parse/print |
| Schemes run | r = 1/4 | r = 1/4 and r = 3/8 (any `p/2^q`) |
| Laws | 4 | 43 |
| Lines of Bend (code) | 554 (373 program + 181 laws and proofs) | 1666 (528 program + 176 laws + 962 proofs) + 244 of instantiation grids |
| False laws detected before proving | — (v1 did not instantiate) | 0 out of 43, over grids of up to 343 triples per law |

## Where it hurt

1. **A law without proof is "a dead claim".** The checker does not allow using an open law as a lemma (`an unfilled law is a dead claim: live code cannot use it`). That forces proving in the strict order of the dependency graph and each proof file importing the **proof** files it depends on, not just the laws. It is what prevented launching the six provers at once: there were two batches of two and one of one, plus the oracle by hand.
2. **The orientation of the rewrites.** All six reports say the same thing: `%e : P` replaces the **right-hand** side of `e`, and the goals almost always show the left-hand side of the natural law (`to_z(add(..))`, `mul(succ a, x)`). Each file ends with a collection of twins flipped by `Equal.sym` (`add_flip`, `neg_add_f`, `big_add_f`, ...). It is the fixed cost of not having tactics: it is paid once per lemma, it is mechanical, and it stabilized as a convention (`phase0-v2-design.md` §4.7).
3. **`match` rules that are not in the guide.** To split the three bits of the adder, the agent discovered that an inner `match` on fields bound by a multi-scrutinee `case` is rejected ("match scrutinees in binder order"): parameters had to be reordered and a single `match xs c ys` with 8 rows of nested patterns had to be written. And a wildcard row with `+x` above rows with constructors fails with `cannot infer False{}`. Fourteen checker probes for two rules.
4. **`Z` cannot be executed.** The `succ`/`pred` arithmetic is unary and non-tail: three steps of the `iterate_z` specification in the instantiation grid blew the JS stack (`memory fault`). The grid was left at 1–2 steps with small values. It is v2's division of labor: `Z` is the meaning, `BigZ` is the engine, and the law that joins them is what gets executed.
5. **Annotations the checker does not infer.** A `let` of a constructor with computed arguments needs its type (`+s = {IR.Scheme{..} : IR.Scheme}`); a `Nat` selector used in two branches needs `+`; declaration order rules (a helper function used before being defined is `a defined name`). Each one cost a checker round; none a piece of reasoning.
6. **What did NOT hurt.** No law turned out false: the prior grid instantiation found nothing, and the proofs closed with 1–4 iterations each. The discipline "one `match` per helper, one mirror lemma per helper" turned 43 laws into mechanical work distributable among agents. Compared with v1 (one false law found only when proving), the process change is the finding: **designing the specification and reviewing it by instantiation before proving** is what makes the proof routine.

## What remains outside the law (and why it is accepted)

- `Big.parse` / `Big.show` / `BigZ.show` (text ↔ bits) and Python's `run.py`: they are trivial translations and `run.py` compares the complete result with `Fraction`.
- The kernel's text generation (`py_lin`): that `"(2.0) * u[1:-1]"` is what JAX interprets as 2·u_i is not demonstrable in Bend. The numerical comparison covers it.
- Everything that happens in float: by design.

## Verdict

**The hypothesis "kernel generator with proven transformations + exact oracle of the same IR" is viable today, and in v2 it is solid**: everything that is not I/O nor float is under a machine-checked law, from the ring of integers to the oracle's time step. It closed in one day with six prover agents.

What it costs, in numbers: 1666 lines of Bend (58% are proofs) against 41 of Python + sympy + `Fraction` with no guarantee at all. The 962 lines of proofs are the price for "the kernel and the oracle implement the same scheme, for every window and every dyadic `r`" being a theorem and not a claim. The numeric base (`num/`, 32 laws) is reusable for any future discrete layer: a sequencer, an interlock with counters, certificates of Runge-Kutta tableaus.

What stays out and how much it would cost to bring in:

- **Non-dyadic denominators** (`1/3`, `1/6` of RK4): the IR and the laws do not depend on `D` being a power of 2; only `Scheme{p, q}` builds it that way. Changing `den_nat` to an arbitrary `D` is one line and no new proof.
- **Two and three dimensions**: `Var{k}` indexes a flattened window; the normalizer and `lin_sound` do not change. The printer and the oracle change (bigger windows).
- **Variable coefficients** (`α(x)`): the IR would need per-point constants in the environment; `lin_sound` generalizes with the same structure.
- **Non-linear terms** (`u·u_x`): outside the linear IR **by design**; bringing them in requires a polynomial IR and a polynomial normal form with its laws: it is another project, not an extension.
- **Floats**: never. The boundary stays where it was: exact in Bend, float in JAX, bridge via exact dyadic inputs and numerical comparison.

On the underlying question ("does Bend fulfill its purpose of keeping the AI from making mistakes?"): in v2 the checker found no semantic error because the process avoided it beforehand: the 43 laws were instantiated on a grid and none was false. What it did catch were the errors of form (affinity, order, annotations) and what it does guarantee is that **nobody**, human or AI, can change `lin`, `Z.mul` or `step` without `run.py` ceasing to say `True`. That is the real utility: not that the AI does not make mistakes when writing, but that no future mistake goes by in silence.
