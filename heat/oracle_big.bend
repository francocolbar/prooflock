# oracle_big.bend - plan B of the exact oracle: the same scheme, the same IR tree,
# evaluated over arbitrary-precision numerators (big.bend) so the step count is no
# longer capped by Nat < 2^48. Same inputs as oracle.bend (BEND_IC, BEND_N).
# Output: "scheme <p> <D>" then one line with the final numerators as limb dumps
# (little-endian base 2^16, ':'-separated) separated by spaces.

import Base
import ./ir.bend as IR
import ./big.bend as Big

def or_zero(m: Maybe<&2, Nat>) -> Nat:
  match m:
    case None{}:
      0n
    case Some{n}:
      n

def parse_bigs(parts: List<&2, String>) -> List<&2, List<&2, Nat>>:
  match parts:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      Big.Big.from_nat(or_zero(Nat.read(h))) <> parse_bigs(t)

# the window lookup over big numerators (out of range reads zero = Nil)
def lookup_big(k: Nat, env: List<&2, List<&2, Nat>>) -> List<&2, Nat>:
  match k env:
    case _ Nil{}:
      Nil{}
    case 0n Con{h, t}:
      h
    case 1n+p Con{h, t}:
      lookup_big(p, t)

# the exact semantics of the IR over big numerators (mirrors IR.eval)
def eval_big(e: IR.Expr, +env: List<&2, List<&2, Nat>>) -> List<&2, Nat>:
  match e:
    case IR.Var{k}:
      lookup_big(k, env)
    case IR.Const{c}:
      Big.Big.from_nat(c)
    case IR.Add{a, b}:
      Big.Big.add(eval_big(a, env), eval_big(b, env))
    case IR.Mul{a, b}:
      Big.Big.mul(eval_big(a, env), eval_big(b, env))

def step_go(rest: List<&2, List<&2, Nat>>, left: List<&2, Nat>, +c: List<&2, Nat>, +e: IR.Expr, +d: Nat) -> List<&2, List<&2, Nat>>:
  match rest:
    case Nil{}:
      [Big.Big.mul_small(c, d, 0n)]
    case Con{+r, t}:
      eval_big(e, [left, c, r]) <> step_go(t, c, r, e, d)

def step_start(rest: List<&2, List<&2, Nat>>, +left: List<&2, Nat>, +e: IR.Expr, +d: Nat) -> List<&2, List<&2, Nat>>:
  match rest:
    case Nil{}:
      [Big.Big.mul_small(left, d, 0n)]
    case Con{+c, t}:
      Big.Big.mul_small(left, d, 0n) <> step_go(t, left, c, e, d)

def step(xs: List<&2, List<&2, Nat>>, +e: IR.Expr, +d: Nat) -> List<&2, List<&2, Nat>>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+b, t}:
      step_start(t, b, e, d)

def iterate(n: Nat, xs: List<&2, List<&2, Nat>>, +e: IR.Expr, +d: Nat) -> List<&2, List<&2, Nat>>:
  match n:
    case 0n:
      xs
    case 1n+p:
      iterate(p, step(xs, e, d), e, d)

def show_bigs(xs: List<&2, List<&2, Nat>>) -> String:
  match xs:
    case Nil{}:
      ""
    case Con{h, t}:
      Big.Big.dump(h) ++ " " ++ show_bigs(t)

def p_of(s: IR.Scheme) -> Nat:
  match s:
    case IR.Scheme{p, q}:
      p

def run(ic: String, ns: String) -> String:
  +s = IR.heat_scheme()
  n = or_zero(Nat.read(ns))
  out = iterate(n, parse_bigs(String.split(ic, ',')), IR.stencil(s), IR.den(s))
  "scheme " ++ Nat.show(p_of(s)) ++ " " ++ Nat.show(IR.den(s)) ++ "\n" ++ show_bigs(out) ++ "\n"

def main() -> IO(Unit):
  do IO<Unit>:
    ic : String <- IO.try(String, IO.get_env("BEND_IC"))
    ns : String <- IO.try(String, IO.get_env("BEND_N"))
    IO.write(run(ic, ns))
