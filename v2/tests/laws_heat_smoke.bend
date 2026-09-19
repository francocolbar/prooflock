# laws_heat_smoke.bend - instantiates the quantified laws of LAWS_HEAT / LAWS_ORACLE
# on concrete expressions, windows and schemes BEFORE proving them, and the computed
# ones on the default scheme. A FALSE line means the statement is wrong.
import Base
import ./../num/z.bend as Z
import ./../num/bigz.bend as BigZ
import ./../heat/ir.bend as IR
import ./../heat/oracle_core.bend as O

def eq(a: Z.Z, b: Z.Z) -> Bool:
  Z.Z.is_eq(a, b)

def zgrid() -> List<&2, Z.Z>:
  [Z.Neg{2n}, Z.Neg{0n}, Z.Zero{}, Z.Pos{0n}, Z.Pos{2n}]

# a few expressions exercising every constructor, nesting and out-of-window reads
def exprs() -> List<&2, IR.Expr>:
  [IR.Var{0n},
   IR.Var{5n},
   IR.Const{Z.Neg{2n}},
   IR.Add{IR.Var{1n}, IR.Const{Z.Pos{1n}}},
   IR.Scale{Z.Neg{1n}, IR.Var{2n}},
   IR.Scale{Z.Zero{}, IR.Add{IR.Var{0n}, IR.Var{1n}}},
   IR.Add{IR.Scale{Z.Pos{2n}, IR.Add{IR.Var{0n}, IR.Scale{Z.Neg{0n}, IR.Var{1n}}}}, IR.Scale{Z.Neg{3n}, IR.Add{IR.Var{2n}, IR.Const{Z.Pos{4n}}}}},
   IR.stencil(IR.Scheme{1n, 2n}),
   IR.stencil(IR.Scheme{3n, 3n}),
   IR.stencil(IR.Scheme{3n, 2n}),
   IR.Scale{Z.Neg{1n}, IR.stencil(IR.Scheme{5n, 4n})}]

def envs() -> List<&2, List<&2, Z.Z>>:
  [[], [Z.Pos{0n}], [Z.Neg{2n}, Z.Pos{1n}, Z.Zero{}], [Z.Pos{6n}, Z.Neg{4n}, Z.Pos{2n}, Z.Neg{0n}, Z.Pos{9n}]]

# lin_sound on one (e, env)
def lin_ok(+e: IR.Expr, +env: List<&2, Z.Z>) -> Bool:
  eq(IR.eval_lin(IR.lin(e), env), IR.eval(e, env))

def to_big(env: List<&2, Z.Z>) -> List<&2, BigZ.BigZ>:
  match env:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      BigZ.BigZ.from_z(h) <> to_big(t)

# eval_big_sound on one (e, env)
def big_ok(+e: IR.Expr, +env: List<&2, Z.Z>) -> Bool:
  +benv = to_big(env)
  Bool.and(eq(BigZ.BigZ.to_z(O.eval_big(e, benv)), IR.eval(e, O.map_to_z(benv))),
           eq(IR.eval(e, O.map_to_z(benv)), IR.eval(e, env)))

def one(which: Nat, +e: IR.Expr, +env: List<&2, Z.Z>) -> Bool:
  match which:
    case 0n:
      lin_ok(e, env)
    case 1n+_:
      big_ok(e, env)

def over_envs(es: List<&2, List<&2, Z.Z>>, +e: IR.Expr, +which: Nat) -> Bool:
  match es:
    case Nil{}:
      True{}
    case Con{env, t}:
      Bool.and(one(which, e, env), over_envs(t, e, which))

def over_exprs(xs: List<&2, IR.Expr>, +which: Nat) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case Con{e, t}:
      Bool.and(over_envs(envs(), e, which), over_exprs(t, which))

# linear_exact on one (a, b)
def lin_exact_ok(+a: Z.Z, +b: Z.Z) -> Bool:
  eq(IR.eval(IR.stencil(IR.heat_scheme()), [a, Z.Z.add(a, b), Z.Z.add(a, Z.Z.add(b, b))]),
     Z.Z.mul(IR.den(IR.heat_scheme()), Z.Z.add(a, b)))

def lin_exact_b(bs: List<&2, Z.Z>, +a: Z.Z) -> Bool:
  match bs:
    case Nil{}:
      True{}
    case Con{b, t}:
      Bool.and(lin_exact_ok(a, b), lin_exact_b(t, a))

def lin_exact_all(as: List<&2, Z.Z>) -> Bool:
  match as:
    case Nil{}:
      True{}
    case Con{a, t}:
      Bool.and(lin_exact_b(zgrid(), a), lin_exact_all(t))

# weights_sum_all on one (p, q)
def wsum_ok(+p: Nat, +q: Nat) -> Bool:
  eq(IR.sum(IR.weights(IR.Scheme{p, q})), IR.den(IR.Scheme{p, q}))

def wsum_q(qs: List<&2, Nat>, +p: Nat) -> Bool:
  match qs:
    case Nil{}:
      True{}
    case Con{q, t}:
      Bool.and(wsum_ok(p, q), wsum_q(t, p))

def wsum_all(ps: List<&2, Nat>) -> Bool:
  match ps:
    case Nil{}:
      True{}
    case Con{p, t}:
      Bool.and(wsum_q([0n, 1n, 2n, 3n, 4n], p), wsum_all(t))

# step_sound / iterate_sound on one (xs, e, d)
def zs_eq(xs: List<&2, Z.Z>, ys: List<&2, Z.Z>) -> Bool:
  match xs ys:
    case Nil{} Nil{}:
      True{}
    case Con{x, xt} Con{y, yt}:
      Bool.and(eq(x, y), zs_eq(xt, yt))
    case _ _:
      False{}

# Z's arithmetic is unary (deep recursion): keep the values small (1 step with d, 2 steps with d = 2)
def step_ok(+xs: List<&2, Z.Z>, +e: IR.Expr, +d: Z.Z) -> Bool:
  +bxs = to_big(xs)
  Bool.and(zs_eq(O.map_to_z(O.step(bxs, e, d)), O.step_z(O.map_to_z(bxs), e, d)),
           zs_eq(O.map_to_z(O.iterate(2n, bxs, e, Z.Pos{1n})), O.iterate_z(2n, O.map_to_z(bxs), e, Z.Pos{1n})))

def step_envs(es: List<&2, List<&2, Z.Z>>, +e: IR.Expr, +d: Z.Z) -> Bool:
  match es:
    case Nil{}:
      True{}
    case Con{xs, t}:
      Bool.and(step_ok(xs, e, d), step_envs(t, e, d))

def step_exprs(xs: List<&2, IR.Expr>, +d: Z.Z) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case Con{e, t}:
      Bool.and(step_envs(envs(), e, d), step_exprs(t, d))

def line(name: String, ok: Bool) -> String:
  match ok:
    case True{}:
      "ok    " ++ name ++ "\n"
    case False{}:
      "FALSE " ++ name ++ "\n"

def report() -> String:
  +s = IR.heat_scheme()
  line("lin_sound (11 exprs x 4 envs)", over_exprs(exprs(), 0n)) ++
  line("eval_big_sound (11 exprs x 4 envs)", over_exprs(exprs(), 1n)) ++
  line("weights_sum", eq(IR.sum(IR.weights(s)), IR.den(s))) ++
  line("weights_symmetric", eq(IR.lookup(0n, IR.weights(s)), IR.lookup(2n, IR.weights(s)))) ++
  line("weights_nonneg", IR.all_nonneg(IR.weights(s))) ++
  line("no_source", eq(IR.const_of(IR.lin(IR.stencil(s))), Z.Zero{})) ++
  line("weights_sum_all (p 0..6 x q 0..4)", wsum_all([0n, 1n, 2n, 3n, 4n, 5n, 6n])) ++
  line("linear_exact (5 x 5)", lin_exact_all(zgrid())) ++
  line("step_sound (11 exprs x 4 grids, d = 4 and d = -3) + iterate_sound (2 steps, d = 2)", Bool.and(step_exprs(exprs(), Z.Pos{3n}), step_exprs(exprs(), Z.Neg{2n}))) ++
  line("weights_nonneg is FALSE for r=3/4 (expected: violates CFL)", Bool.not(IR.all_nonneg(IR.weights(IR.Scheme{3n, 2n}))))

def main() -> IO(Unit):
  IO.write(report())
