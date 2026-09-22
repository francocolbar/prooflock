# Phase 0 (v2) — Design of the numeric base and review of the specifications

Date: 2026-09-18. Replaces the PoC choice of `../../docs/phase0-reassessment.md` (v1) with a version without the shortcuts v1 needed: no `Nat` as semantics, no schemes restricted to non-negative weights, no tested-but-not-proven bignum. Everything in `v2/` is under a law or is trivial I/O.

## 1. What was weak in v1 and what replaces it

| v1 weakness | Consequence | v2 solution | File |
|---|---|---|---|
| Exact semantics over `Nat` | Only schemes with weights ≥ 0; subtraction does not exist; `r ≤ 1/2` chosen to dodge the sign | Canonical integers `Z` (`Zero`, `Pos{n}` = n+1, `Neg{n}` = −(n+1)) with proven ring laws | `num/z.bend`, `LAWS_Z_ADD/MUL` |
| `weights_sum` as a "CFL certificate" by saturation of `Nat.sub` | A trick: the law was true because of a side effect of the arithmetic, not because of the statement | Explicit certificate `weights_nonneg` (all weights ≥ 0 ⇔ convex combination ⇔ `r ≤ 1/2`) and a negative test that must be rejected | `LAWS_HEAT`, `tests/cfl_violation_PROOF.bend` |
| Stencil built with the weights already computed (`[p, D−2p, p]`) | The "simplifier" only removed `·1` and `+0`; the subtraction was done by the constructor | The stencil is written as the physics: `D·u_i + p·(u_{i−1} + (−2)·u_i + u_{i+1})`; a **normalizer** to linear form collects the coefficients; its correctness is the central law | `heat/ir.bend`, `lin_sound` |
| IR with general `Mul` | Non-linear terms representable and meaningless for a stencil | IR **linear by construction**: `Scale{c, e}` is the only product | `heat/ir.bend` |
| Bignum of limbs base 2^16 with `Nat.div/mod` | Tested against Python, not proven (division is opaque to the checker) | Naturals as lists of bits with structural meaning `to_nat`; adder with carry **proven**; big integers as a pair `p − n` (no borrows nor sign) | `num/big.bend`, `num/bigz.bend`, `LAWS_BIG`, `LAWS_BIGZ` |
| Oracle = "same `eval`" only up to 13 steps | No proven connection between the oracle at scale and the semantics | `eval_big` mirrors `eval` constructor by constructor and the law `eval_big_sound` equates them via `to_z` | `heat/oracle_core.bend`, `LAWS_ORACLE` |
| Laws written and proven without prior instantiation | v1 had a false law (`fire_guard`) that only showed up when proving | Every law is instantiated on a grid of values **before** attempting the proof (`tests/laws_*_smoke.bend`); a false law shows up in seconds as `FALSE` | `tests/` |

What stays the same: floats stay outside Bend (nothing is provable about `F32`); the JAX kernel is generated as text; the numerical comparison is done by Python with `Fraction`.

## 2. Design decisions that make the proofs possible

- **`Z` by `succ`/`pred`.** `Z.add(Pos{n}, b)` is `succ` applied n+1 times; `Z.mul(Pos{n}, b)` is `b` added n+1 times; negatives are `neg` of the positives. Every law is proven by structural induction over the inner `Nat`, without `Nat.sub` or comparisons. Price: `Z.add` is O(|a|) at runtime. `Z` is the **meaning** of the programs; execution at scale goes through `BigZ`. The only `Z` values that get executed are the scheme's coefficients (≤ 16).
- **Canonical form.** A single term per integer, so `{a == b : Z}` is structural equality and `{==}` closes goals. A `Z` as a pair of `Nat` would have forced laws "modulo equivalence" and hand-written congruence lemmas for every rewrite.
- **Bignum as bits, not as limbs.** `to_nat(b <> t) = bit(b) + 2·to_nat(t)` is structural; the adder is the textbook binary adder and its correctness is an induction with 8 cases per bit. With limbs base 2^16 the correctness needs symbolic `div`/`mod` ("hard" level). Price: one node per bit; irrelevant for an oracle (200 steps, 10 points: 1.8 s).
- **Big integers as `p − n` without canonicalizing.** `BigZ.add` is componentwise and `BigZ.neg` is a swap: zero sign logic, zero borrows. The representation is not unique (`BZ{[1],[1]}` is also 0): that is why **all** `BigZ` laws are stated through `to_z`, never over the representation.
- **Scaling mirrors multiplication.** `BigZ.scale(Pos{k}, v)` is `v` added k+1 times, exactly like `Z.mul_pos`. So `scale_sound` is proven with `add_sound` and an induction, without bignum multiplication.
- **Every helper does `match` on a single parameter** and has a mirror lemma. It is the discipline that in v1 made `simplify_sound` close on the first attempt; here it is applied to `zip_add`, `scale_list`, `dot`, `lookup`, `unit`.
- **Rewriting convention.** Every lemma is stated with the term to be eliminated on the right (`%e : P` replaces the right-hand side of `e`). The prover agents reported that this is the main source of iterations; it is fixed as a project rule.

## 3. The laws, one by one, with their review

Format: **statement** (as it is in the file, in Bend notation) · *what it guarantees* · *what it does NOT guarantee* · *prior validation*. The prior validation is the grid instantiation of `tests/laws_z_smoke.bend` (7 values of Z, up to 343 triples per law) and `tests/laws_heat_smoke.bend` (11 expressions × 4 windows; 35 schemes; 25 pairs (a,b)). No law turned out false in v2; the two reviews that did change statements are in §4.

### 3.1 `LAWS_Z_ADD.bend` (13 laws) — proven, 397 lines, 2 checker iterations

| Law | Statement | What it guarantees / what it does not |
|---|---|---|
| `succ_pred`, `pred_succ` | `succ(pred(a)) == a`, `pred(succ(a)) == a` | `Z` is a discrete cyclic group without endpoints. Says nothing about `add`. |
| `add_zero_r` | `add(a, Zero) == a` | Right identity; on the left it is definitional. |
| `add_succ_r/l`, `add_pred_r/l` | `add(a, succ(b)) == succ(add(a, b))` and symmetric ones | The "shifting" lemmas that drive all the inductions. |
| `add_comm`, `add_assoc` | commutativity and associativity | With `add_zero_r`: `(Z, +)` is a commutative monoid. |
| `neg_neg`, `add_neg_r`, `neg_add` | `neg(neg(a)) == a`, `add(a, neg(a)) == Zero`, `neg(a + b) == neg(a) + neg(b)` | Inverses: `(Z, +)` is an abelian group. `add_neg_l` is not stated: it is obtained from `add_comm`. |
| `from_nat_add` | `from_nat(a + b) == add(from_nat(a), from_nat(b))` | The inclusion `Nat → Z` respects addition. Needed for `BigZ.add_sound`. Says nothing about `mul` (`from_nat_mul` is not needed). |

### 3.2 `LAWS_Z_MUL.bend` (9 laws) — being proven

| Law | Statement | What it guarantees / what it does not |
|---|---|---|
| `mul_zero_r` | `mul(a, Zero) == Zero` | On the left it is definitional. |
| `mul_one_l`, `mul_one_r` | `mul(Pos{0n}, b) == b`, `mul(a, Pos{0n}) == a` | `Pos{0n}` is 1. |
| `mul_neg_l`, `mul_neg_r` | `mul(neg(a), b) == neg(mul(a, b))` and symmetric one | Rule of signs. |
| `dist_l`, `dist_r` | `mul(c, x + y) == mul(c, x) + mul(c, y)` and `mul(a + b, x) == mul(a, x) + mul(b, x)` | The two distributivities; both are used in `lin_sound` (the left one when scaling a linear form, the right one when adding coefficients). |
| `mul_assoc`, `mul_comm` | associativity and commutativity | With the above: `Z` is a commutative ring. `mul_comm` is not used by any later law; it is there because a ring without it is a half-made claim. |

### 3.3 `LAWS_BIG.bend` (5 laws) — being proven

| Law | Statement | What it guarantees / what it does not |
|---|---|---|
| `add_carry_sound` | `to_nat(add_carry(xs, c)) == to_nat(xs) + bit(c)` | Propagating a carry adds exactly that bit. |
| `add_go_sound` | `to_nat(add_go(xs, ys, c)) == (to_nat(xs) + to_nat(ys)) + bit(c)` | The adder with carry-in is correct **without a width bound**: there is no overflow because the list grows. |
| `add_sound` | `to_nat(add(xs, ys)) == to_nat(xs) + to_nat(ys)` | The law everything else uses. |
| `inc_sound`, `from_nat_sound` | `to_nat(inc(xs)) == 1 + to_nat(xs)`, `to_nat(from_nat(n)) == n` | The IR's constants enter the bignum correctly. There is **no** law for `parse` (bits from text): it is a character-to-bit translation that can be read at a glance, and `run.py` compares against `Fraction` anyway. |

### 3.4 `LAWS_BIGZ.bend` (5 laws) — pending (depends on 3.1 and 3.3)

| Law | Statement | What it guarantees / what it does not |
|---|---|---|
| `add_sound` | `to_z(add(a, b)) == Z.add(to_z(a), to_z(b))` | Adding pairs is adding integers. |
| `neg_sound` | `to_z(neg(a)) == Z.neg(to_z(a))` | Swapping is negating. |
| `scale_sound` | `to_z(scale(c, v)) == Z.mul(c, to_z(v))` | Scaling by a `Z` constant is multiplying. It is the only multiplication the oracle needs. |
| `from_z_sound`, `zero_sound` | `to_z(from_z(c)) == c`, `to_z(zero()) == Zero` | The constants enter correctly. |

What these laws do **not** say: anything about the size of the representation (`p` and `n` grow without cancelling). It is a performance fact, not a correctness one, and in 200 steps the numerators have 608 bits.

### 3.5 `LAWS_HEAT.bend` (7 laws) — pending (depends on 3.2)

| Law | Statement | What it guarantees / what it does not |
|---|---|---|
| `lin_sound` | `∀ e, env: eval_lin(lin(e), env) == eval(e, env)` | **The central law.** The normalizer that produces the kernel's coefficients does not change the exact meaning of any tree under any window (including windows shorter or longer than the stencil). It says nothing about the float that JAX computes with those coefficients. |
| `weights_sum` (by computation) | `sum(weights(heat_scheme())) == den(heat_scheme())` | A constant profile is a fixed point: order-0 consistency. Only for `r = 1/4`. |
| `weights_symmetric` (by computation) | `w_{−1} == w_{+1}` | Null first moment: second-order consistency. Only for `r = 1/4`. |
| `weights_nonneg` (by computation) | `all_nonneg(weights) == True` | Convex combination ⇒ maximum principle ⇒ stability. Equivalent to `r ≤ 1/2`. **It is false for `r = 3/4`** and `tests/cfl_violation_PROOF.bend` verifies that the checker rejects it. |
| `no_source` (by computation) | `const_of(lin(stencil)) == Zero` | The equation is homogeneous. |
| `weights_sum_all` | `∀ p, q: sum(weights(Scheme{p, q})) == den(Scheme{p, q})` | Order-0 consistency holds for **every** dyadic `r`, it is not a coincidence of 1/4. Requires the `Z` ring with symbolic `p` and `q`. |
| `linear_exact` | `∀ a, b: eval(stencil, [a, a+b, a+2b]) == D·(a+b)` | A linear profile (`u_xx = 0`) is preserved exactly for all integers `a, b`. Only `r = 1/4`. |

### 3.6 `LAWS_ORACLE.bend` (2 laws) — pending (depends on 3.4)

| Law | Statement | What it guarantees / what it does not |
|---|---|---|
| `lookup_big_sound` | `to_z(lookup_big(k, env)) == lookup(k, map_to_z(env))` | Reading the big window is reading the `Z` window, even out of range (both give 0). |
| `eval_big_sound` | `∀ e, env: to_z(eval_big(e, env)) == eval(e, map_to_z(env))` | The oracle at scale computes exactly the `Z` semantics of the raw tree. With `lin_sound`: the kernel (normal form) and the oracle (raw tree) implement the same scheme. |
| `step_sound` | `∀ xs, e, d: map_to_z(step(xs, e, d)) == step_z(map_to_z(xs), e, d)` | A time step over big integers (windows of 3, Dirichlet boundaries scaled by `D`) is the time step of the specification in `Z`. `step_z` is the same function written over `Z`: it is the definition of "one step of the scheme", readable in 20 lines. |
| `iterate_sound` | `∀ n, xs, e, d: map_to_z(iterate(n, xs, e, d)) == iterate_z(n, map_to_z(xs), e, d)` | `n` steps are `n` steps. With this, **the whole oracle run** is under law; outside remain only `parse` (text → bits) and `show` (bits → text), and `run.py` covers them by comparing with `Fraction` (4 runs, exact match). |

Implementation note (review 5, §4): the specification `step_z`/`iterate_z` **cannot be executed** except on tiny values, because `Z` arithmetic is unary and non-tail recursive: the first instantiation grid of `iterate_sound` with 3 steps blew the JS stack (`memory fault`). The grid uses 1 step with `d = 4` and `d = −3`, and 2 steps with `d = 2`. It is the price of having a `Z` over which the proofs are simple inductions.

## 4. Reviews that changed something

1. **Side of the coefficient in `Scale`.** First version of `eval`: `Scale{c, e} ↦ mul(eval(e), c)`. When writing `lin_sound` on paper, the proof of `scale_list` required `mul(mul(x, a), c) == mul(x, mul(a, c))` and that of `zip_add` required the left distributivity; with the coefficient on the left (`mul(c, eval(e))`) and `dot` as `Σ mul(c_k, x_k)`, `scale_list` uses `mul_assoc` directly and `zip_add` uses `dist_r`. The second was chosen so that each helper needs a single law. It does not change the meaning, it changes how many lemmas are needed.
2. **"CFL by saturation" → `weights_nonneg`.** In v1, `weights_sum` was true for `r ≤ 1/2` and false for `r > 1/2` only because `Nat.sub` saturates at 0; the statement did not speak about stability. In v2 the sum gives `D` for every `r` (`weights_sum_all`, true for 35 schemes including the unstable ones) and stability has its own law, with its own negative test.
3. **`lookup` out of range.** `eval(Var{5n}, [a, b, c])` gives 0 by definition. `Var{5n}` and windows of length 0, 1, 3 and 5 were added to the grid of `lin_sound` and `eval_big_sound` so that the law is also instantiated where `dot`, `unit` and `zip_add` have different lengths: that is where a proof by induction over two lists usually fails.
4. **`from_nat_add` with negative values.** The law is over `Nat`; the grid instantiates it with `abs(a)`, `abs(b)`. It is documented so that nobody reads "proven over the Z grid" as "proven with negatives".
5. **The time step came in without a law.** The first version of `LAWS_ORACLE` covered `eval_big` and left `step`/`iterate` (windows, scaled boundaries) validated only against Python. The specification `step_z`/`iterate_z` over `Z` and the laws `step_sound`/`iterate_sound` were added. When instantiating them the execution limit of `Z` appeared (note in §3.6).
6. **An open law is "a dead claim".** The checker refuses to use as a lemma a law that does not yet have a proof (`an unfilled law is a dead claim: live code cannot use it`). Consequence for the plan: the proofs are done in the strict order of the graph in §5 and each proof file imports the proof files it depends on, not just their laws. One cannot "prove in parallel assuming what is below".
7. **Orientation of the lemmas.** The three prover agents of v1/v2 reported the same thing: most iterations go into the rewriting direction. Rule fixed: every law is stated in its natural form (`to_z(op(..)) == Z.op(..)`), and each proof file defines "flipped" versions with `Equal.sym` (`add_flip`, `scale_flip`, `eval_flip`) to eliminate the left-hand side of a goal.

## 5. Proof plan and dependencies

```
LAWS_Z_ADD ──┬──> LAWS_Z_MUL ──> LAWS_HEAT (lin_sound, weights_sum_all, linear_exact)
             └──> LAWS_BIGZ  ──> LAWS_ORACLE
LAWS_BIG   ──────> LAWS_BIGZ
```
One prover agent per file, in parallel when the dependencies allow it. Each one receives: the laws file (untouchable), the lemma plan, the orientation convention, the exact checker command, and an iteration cap. No law is relaxed so that it closes: if one does not close, it stays `?TODO` and is reported.

## 6. What counts as "closed" in Phase 1 v2

`py -3.14 v2/heat/run.py` finishes with `all gates and checks ok: True`, which requires:

1. The six `PROOF_*.bend` print `All terms check.` (41 laws, no `@unsafe`, no `?TODO`).
2. The two instantiation grids have no `FALSE` line.
3. `tests/cfl_violation_PROOF.bend` is **rejected** by the checker.
4. For `r = 1/4` and `r = 3/8`, with 13 and 200 steps: the emitted kernel runs in JAX float64; Bend's oracle matches Python's `Fraction` **exactly**; the float64 error against the oracle is below `N·ε`; JAX and oracle give the same error against the analytic solution; the oracle matches the closed form of the discrete scheme down to the quantization of the initial condition.

Numerical result already obtained (before the pending proofs, `heat/results.json`): the four runs satisfy point 4. With `r = 3/8` and 13 steps the numerators have 60 bits and float64 already rounds (relative error 6e−17), which confirms the v1 reading: "zero error" was an artifact of the 47 bits.
