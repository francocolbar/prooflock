# oracle_core.bend - the exact oracle, pure part: the RAW stencil tree evaluated over
# big integers (bigz.bend), stepped in time. LAWS_ORACLE.bend states that eval_big
# means exactly what IR.eval means.

import Base
import ./../num/z.bend as Z
import ./../num/bigz.bend as BigZ
import ./ir.bend as IR

def lookup_big(k: Nat, env: List<&2, BigZ.BigZ>) -> BigZ.BigZ:
  match k env:
    case _ Nil{}:
      BigZ.BigZ.zero()
    case 0n Con{h, t}:
      h
    case 1n+p Con{h, t}:
      lookup_big(p, t)

# mirrors IR.eval constructor by constructor
def eval_big(e: IR.Expr, +env: List<&2, BigZ.BigZ>) -> BigZ.BigZ:
  match e:
    case IR.Var{k}:
      lookup_big(k, env)
    case IR.Const{c}:
      BigZ.BigZ.from_z(c)
    case IR.Add{a, b}:
      BigZ.BigZ.add(eval_big(a, env), eval_big(b, env))
    case IR.Scale{c, e2}:
      BigZ.BigZ.scale(c, eval_big(e2, env))

def map_to_z(env: List<&2, BigZ.BigZ>) -> List<&2, Z.Z>:
  match env:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      BigZ.BigZ.to_z(h) <> map_to_z(t)

# one time step over numerators with a common denominator: interior points get
# eval_big(stencil, [left, centre, right]); the two Dirichlet boundaries are scaled
# by D so every entry keeps the common denominator D^t * 2^m.
def step_go(rest: List<&2, BigZ.BigZ>, left: BigZ.BigZ, +c: BigZ.BigZ, +e: IR.Expr, +d: Z.Z) -> List<&2, BigZ.BigZ>:
  match rest:
    case Nil{}:
      [BigZ.BigZ.scale(d, c)]
    case Con{+r, t}:
      eval_big(e, [left, c, r]) <> step_go(t, c, r, e, d)

def step_start(rest: List<&2, BigZ.BigZ>, +left: BigZ.BigZ, +e: IR.Expr, +d: Z.Z) -> List<&2, BigZ.BigZ>:
  match rest:
    case Nil{}:
      [BigZ.BigZ.scale(d, left)]
    case Con{+c, t}:
      BigZ.BigZ.scale(d, left) <> step_go(t, left, c, e, d)

def step(xs: List<&2, BigZ.BigZ>, +e: IR.Expr, +d: Z.Z) -> List<&2, BigZ.BigZ>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+b, t}:
      step_start(t, b, e, d)

def iterate(n: Nat, xs: List<&2, BigZ.BigZ>, +e: IR.Expr, +d: Z.Z) -> List<&2, BigZ.BigZ>:
  match n:
    case 0n:
      xs
    case 1n+p:
      iterate(p, step(xs, e, d), e, d)

# ---------------------------------------------------------------------------
# The SPECIFICATION of the stepping, over Z (the meaning; never run at scale).
# step / iterate above mirror these constructor by constructor; LAWS_ORACLE.bend
# states that map_to_z commutes with them.
# ---------------------------------------------------------------------------

def step_go_z(rest: List<&2, Z.Z>, left: Z.Z, +c: Z.Z, +e: IR.Expr, +d: Z.Z) -> List<&2, Z.Z>:
  match rest:
    case Nil{}:
      [Z.Z.mul(d, c)]
    case Con{+r, t}:
      IR.eval(e, [left, c, r]) <> step_go_z(t, c, r, e, d)

def step_start_z(rest: List<&2, Z.Z>, +left: Z.Z, +e: IR.Expr, +d: Z.Z) -> List<&2, Z.Z>:
  match rest:
    case Nil{}:
      [Z.Z.mul(d, left)]
    case Con{+c, t}:
      Z.Z.mul(d, left) <> step_go_z(t, left, c, e, d)

def step_z(xs: List<&2, Z.Z>, +e: IR.Expr, +d: Z.Z) -> List<&2, Z.Z>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+b, t}:
      step_start_z(t, b, e, d)

def iterate_z(n: Nat, xs: List<&2, Z.Z>, +e: IR.Expr, +d: Z.Z) -> List<&2, Z.Z>:
  match n:
    case 0n:
      xs
    case 1n+p:
      iterate_z(p, step_z(xs, e, d), e, d)
