# oracle.bend (v2) - IO wrapper of oracle_core. Inputs (Bend has no argv):
#   BEND_P, BEND_Q   the scheme r = p / 2^q
#   BEND_IC          comma-separated non-negative numerators as bit strings, LSB first
#   BEND_N           number of steps
# Output: "scheme <p> <D>" then one line: per point "pbits/nbits" (value = p - n),
# over the denominator 2^m * D^N.

import Base
import ./../num/z.bend as Z
import ./../num/bigz.bend as BigZ
import ./ir.bend as IR
import ./oracle_core.bend as O

def or_zero(m: Maybe<&2, Nat>) -> Nat:
  match m:
    case None{}:
      0n
    case Some{n}:
      n

def parse_ic(parts: List<&2, String>) -> List<&2, BigZ.BigZ>:
  match parts:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      BigZ.BigZ.parse_nat(h) <> parse_ic(t)

def show_all(xs: List<&2, BigZ.BigZ>) -> String:
  match xs:
    case Nil{}:
      ""
    case Con{h, t}:
      BigZ.BigZ.show(h) ++ " " ++ show_all(t)

def run(ps: String, qs: String, ic: String, ns: String) -> String:
  +s = {IR.Scheme{or_zero(Nat.read(ps)), or_zero(Nat.read(qs))} : IR.Scheme}
  n = or_zero(Nat.read(ns))
  out = O.iterate(n, parse_ic(String.split(ic, ',')), IR.stencil(s), IR.den(s))
  "scheme " ++ Nat.show(IR.p_of(s)) ++ " " ++ Z.Z.show(IR.den(s)) ++ "\n" ++ show_all(out) ++ "\n"

def main() -> IO(Unit):
  do IO<Unit>:
    ps : String <- IO.try(String, IO.get_env("BEND_P"))
    qs : String <- IO.try(String, IO.get_env("BEND_Q"))
    ic : String <- IO.try(String, IO.get_env("BEND_IC"))
    ns : String <- IO.try(String, IO.get_env("BEND_N"))
    IO.write(run(ps, qs, ic, ns))
