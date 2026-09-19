# oracle.bend - the exact oracle: the SAME scheme, evolved over Nat numerators with a
# common dyadic denominator. Inputs come from the environment (Bend has no argv):
#   BEND_IC  comma-separated numerators of the initial condition (over 2^m)
#   BEND_N   number of time steps
# Output: "scheme <p> <D>" then one line with the final numerators (over 2^m * D^N).
# Every interior value is IR.eval applied to the RAW stencil tree; the kernel
# emitted by emit.bend prints the SIMPLIFIED tree. simplify_sound (LAWS.bend) is
# what makes the two the same scheme.

import Base
import ./ir.bend as IR

def or_zero(m: Maybe<&2, Nat>) -> Nat:
  match m:
    case None{}:
      0n
    case Some{n}:
      n

def parse_nats(parts: List<&2, String>) -> List<&2, Nat>:
  match parts:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      or_zero(Nat.read(h)) <> parse_nats(t)

# rest = the points after the centre c; left = the point before it
def step_go(rest: List<&2, Nat>, left: Nat, +c: Nat, +e: IR.Expr, +d: Nat) -> List<&2, Nat>:
  match rest:
    case Nil{}:
      [Nat.mul(c, d)]
    case Con{+r, t}:
      IR.eval(e, [left, c, r]) <> step_go(t, c, r, e, d)

# left = the left boundary, rest = everything after it
def step_start(rest: List<&2, Nat>, +left: Nat, +e: IR.Expr, +d: Nat) -> List<&2, Nat>:
  match rest:
    case Nil{}:
      [Nat.mul(left, d)]
    case Con{+c, t}:
      Nat.mul(left, d) <> step_go(t, left, c, e, d)

def step(xs: List<&2, Nat>, +e: IR.Expr, +d: Nat) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+b, t}:
      step_start(t, b, e, d)

def iterate(n: Nat, xs: List<&2, Nat>, +e: IR.Expr, +d: Nat) -> List<&2, Nat>:
  match n:
    case 0n:
      xs
    case 1n+p:
      iterate(p, step(xs, e, d), e, d)

def show_nats(xs: List<&2, Nat>) -> String:
  match xs:
    case Nil{}:
      ""
    case Con{h, t}:
      Nat.show(h) ++ " " ++ show_nats(t)

def p_of(s: IR.Scheme) -> Nat:
  match s:
    case IR.Scheme{p, q}:
      p

def run(ic: String, ns: String) -> String:
  +s = IR.heat_scheme()
  n = or_zero(Nat.read(ns))
  out = iterate(n, parse_nats(String.split(ic, ',')), IR.stencil(s), IR.den(s))
  "scheme " ++ Nat.show(p_of(s)) ++ " " ++ Nat.show(IR.den(s)) ++ "\n" ++ show_nats(out) ++ "\n"

def main() -> IO(Unit):
  do IO<Unit>:
    ic : String <- IO.try(String, IO.get_env("BEND_IC"))
    ns : String <- IO.try(String, IO.get_env("BEND_N"))
    IO.write(run(ic, ns))
