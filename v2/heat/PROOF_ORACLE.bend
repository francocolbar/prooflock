# PROOF_ORACLE.bend - the big-integer evaluator agrees with the Z evaluator.
# Uses the BigZ laws (LAWS_BIGZ.bend, proven in PROOF_BIGZ.bend).

import Base
import ./../num/z.bend as Z
import ./../num/big.bend as Big
import ./../num/bigz.bend as BigZ
import ./../num/LAWS_BIGZ.bend as LB
import ./../num/PROOF_BIGZ.bend as PB
import ./ir.bend as IR
import ./oracle_core.bend as O
import ./LAWS_ORACLE.bend as Laws

# the BigZ laws, flipped so that %-rewriting eliminates the to_z(op(..)) side
def add_flip(+a: BigZ.BigZ, +b: BigZ.BigZ) -> {Z.Z.add(BigZ.BigZ.to_z(a), BigZ.BigZ.to_z(b)) == BigZ.BigZ.to_z(BigZ.BigZ.add(a, b)) : Z.Z}:
  Equal.sym(Z.Z, BigZ.BigZ.to_z(BigZ.BigZ.add(a, b)), Z.Z.add(BigZ.BigZ.to_z(a), BigZ.BigZ.to_z(b)), LB.add_sound(a, b))

def scale_flip(+c: Z.Z, +v: BigZ.BigZ) -> {Z.Z.mul(c, BigZ.BigZ.to_z(v)) == BigZ.BigZ.to_z(BigZ.BigZ.scale(c, v)) : Z.Z}:
  Equal.sym(Z.Z, BigZ.BigZ.to_z(BigZ.BigZ.scale(c, v)), Z.Z.mul(c, BigZ.BigZ.to_z(v)), LB.scale_sound(c, v))

def Laws.lookup_big_sound(k, env):
  match k env:
    case 0n Nil{}:
      LB.zero_sound()
    case 1n+p Nil{}:
      LB.zero_sound()
    case 0n Con{h, t}:
      {==}
    case 1n+p Con{h, t}:
      Laws.lookup_big_sound(p, t)

def Laws.eval_big_sound(e, env):
  match e:
    case IR.Var{k}:
      Laws.lookup_big_sound(k, env)
    case IR.Const{c}:
      LB.from_z_sound(c)
    case IR.Add{+a, +b}:
      %add_flip(O.eval_big(a, env), O.eval_big(b, env)) : {_ == Z.Z.add(IR.eval(a, O.map_to_z(env)), IR.eval(b, O.map_to_z(env))) : Z.Z}
      %Laws.eval_big_sound(a, env) : {Z.Z.add(BigZ.BigZ.to_z(O.eval_big(a, env)), BigZ.BigZ.to_z(O.eval_big(b, env))) == Z.Z.add(_, IR.eval(b, O.map_to_z(env))) : Z.Z}
      %Laws.eval_big_sound(b, env) : {Z.Z.add(BigZ.BigZ.to_z(O.eval_big(a, env)), BigZ.BigZ.to_z(O.eval_big(b, env))) == Z.Z.add(BigZ.BigZ.to_z(O.eval_big(a, env)), _) : Z.Z}
      {==}
    case IR.Scale{+c, +e2}:
      %scale_flip(c, O.eval_big(e2, env)) : {_ == Z.Z.mul(c, IR.eval(e2, O.map_to_z(env))) : Z.Z}
      %Laws.eval_big_sound(e2, env) : {Z.Z.mul(c, BigZ.BigZ.to_z(O.eval_big(e2, env))) == Z.Z.mul(c, _) : Z.Z}
      {==}

# ---------------------------------------------------------------------------
# Stepping: map_to_z commutes with step and iterate
# ---------------------------------------------------------------------------

# eval_big_sound flipped, to eliminate to_z(eval_big(..)) from a goal
def eval_flip(+e: IR.Expr, +env: List<&2, BigZ.BigZ>) -> {IR.eval(e, O.map_to_z(env)) == BigZ.BigZ.to_z(O.eval_big(e, env)) : Z.Z}:
  Equal.sym(Z.Z, BigZ.BigZ.to_z(O.eval_big(e, env)), IR.eval(e, O.map_to_z(env)), Laws.eval_big_sound(e, env))

def step_go_sound(rest: List<&2, BigZ.BigZ>, +left: BigZ.BigZ, +c: BigZ.BigZ, +e: IR.Expr, +d: Z.Z) -> {O.map_to_z(O.step_go(rest, left, c, e, d)) == O.step_go_z(O.map_to_z(rest), BigZ.BigZ.to_z(left), BigZ.BigZ.to_z(c), e, d) : List<&2, Z.Z>}:
  match rest:
    case Nil{}:
      %scale_flip(d, c) : {Con{_, Nil{}} == Con{Z.Z.mul(d, BigZ.BigZ.to_z(c)), Nil{}} : List<&2, Z.Z>}
      {==}
    case Con{+r, t}:
      %eval_flip(e, [left, c, r]) : {Con{_, O.map_to_z(O.step_go(t, c, r, e, d))} == Con{IR.eval(e, O.map_to_z([left, c, r])), O.step_go_z(O.map_to_z(t), BigZ.BigZ.to_z(c), BigZ.BigZ.to_z(r), e, d)} : List<&2, Z.Z>}
      %step_go_sound(t, c, r, e, d) : {Con{IR.eval(e, O.map_to_z([left, c, r])), O.map_to_z(O.step_go(t, c, r, e, d))} == Con{IR.eval(e, O.map_to_z([left, c, r])), _} : List<&2, Z.Z>}
      {==}

def step_start_sound(rest: List<&2, BigZ.BigZ>, +left: BigZ.BigZ, +e: IR.Expr, +d: Z.Z) -> {O.map_to_z(O.step_start(rest, left, e, d)) == O.step_start_z(O.map_to_z(rest), BigZ.BigZ.to_z(left), e, d) : List<&2, Z.Z>}:
  match rest:
    case Nil{}:
      %scale_flip(d, left) : {Con{_, Nil{}} == Con{Z.Z.mul(d, BigZ.BigZ.to_z(left)), Nil{}} : List<&2, Z.Z>}
      {==}
    case Con{+c, t}:
      %scale_flip(d, left) : {Con{_, O.map_to_z(O.step_go(t, left, c, e, d))} == Con{Z.Z.mul(d, BigZ.BigZ.to_z(left)), O.step_go_z(O.map_to_z(t), BigZ.BigZ.to_z(left), BigZ.BigZ.to_z(c), e, d)} : List<&2, Z.Z>}
      %step_go_sound(t, left, c, e, d) : {Con{Z.Z.mul(d, BigZ.BigZ.to_z(left)), O.map_to_z(O.step_go(t, left, c, e, d))} == Con{Z.Z.mul(d, BigZ.BigZ.to_z(left)), _} : List<&2, Z.Z>}
      {==}

def Laws.step_sound(xs, e, d):
  match xs:
    case Nil{}:
      {==}
    case Con{+b, t}:
      step_start_sound(t, b, e, d)

def Laws.iterate_sound(n, xs, e, d):
  match n:
    case 0n:
      {==}
    case 1n+p:
      %Equal.sym(List<&2, Z.Z>, O.map_to_z(O.iterate(p, O.step(xs, e, d), e, d)), O.iterate_z(p, O.map_to_z(O.step(xs, e, d)), e, d), Laws.iterate_sound(p, O.step(xs, e, d), e, d)) : {_ == O.iterate_z(p, O.step_z(O.map_to_z(xs), e, d), e, d) : List<&2, Z.Z>}
      %Laws.step_sound(xs, e, d) : {O.iterate_z(p, O.map_to_z(O.step(xs, e, d)), e, d) == O.iterate_z(p, _, e, d) : List<&2, Z.Z>}
      {==}
