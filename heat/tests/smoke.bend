import Base
import ./../ir.bend as IR

def report() -> String:
  +s = IR.heat_scheme()
  +e = IR.stencil(s)
  "weights:    " ++ List.show(~&2, ~Nat, ~Nat.show, IR.weights(s)) ++ "\n" ++
  "raw:        " ++ IR.show(e) ++ "\n" ++
  "simplified: " ++ IR.show(IR.simplify(e)) ++ "\n" ++
  "python:     " ++ IR.py(IR.simplify(e)) ++ "\n" ++
  "eval raw  [1,2,3] = " ++ Nat.show(IR.eval(e, [1n, 2n, 3n])) ++ "\n" ++
  "eval simp [1,2,3] = " ++ Nat.show(IR.eval(IR.simplify(e), [1n, 2n, 3n])) ++ "\n" ++
  "r=1/2 simplified: " ++ IR.show(IR.simplify(IR.stencil(IR.Scheme{1n, 1n}))) ++ "\n" ++
  "r=3/4 weights (CFL violated, saturated): " ++ List.show(~&2, ~Nat, ~Nat.show, IR.weights(IR.Scheme{3n, 2n})) ++ "\n"

def main() -> IO(Unit):
  IO.write(report())
