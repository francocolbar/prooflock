import Base
import ./../num/z.bend as Z
import ./../heat/ir.bend as IR

def report() -> String:
  +s = IR.heat_scheme()
  +e = IR.stencil(s)
  "raw:      " ++ IR.show(e) ++ "\n" ++
  "lin:      " ++ IR.show_lin(IR.lin(e)) ++ "\n" ++
  "python:   " ++ IR.py_lin(IR.lin(e)) ++ "\n" ++
  "weights:  " ++ IR.show_zs(IR.weights(s)) ++ "\n" ++
  "sum:      " ++ Z.Z.show(IR.sum(IR.weights(s))) ++ "  D = " ++ Z.Z.show(IR.den(s)) ++ "\n" ++
  "nonneg:   " ++ Bool.show(IR.all_nonneg(IR.weights(s))) ++ "\n" ++
  "eval raw [1,2,3]: " ++ Z.Z.show(IR.eval(e, [Z.Pos{0n}, Z.Pos{1n}, Z.Pos{2n}])) ++ "\n" ++
  "eval lin [1,2,3]: " ++ Z.Z.show(IR.eval_lin(IR.lin(e), [Z.Pos{0n}, Z.Pos{1n}, Z.Pos{2n}])) ++ "\n" ++
  "r=3/8 weights:  " ++ IR.show_zs(IR.weights(IR.Scheme{3n, 3n})) ++ "\n" ++
  "r=3/4 weights:  " ++ IR.show_zs(IR.weights(IR.Scheme{3n, 2n})) ++ "  nonneg: " ++ Bool.show(IR.all_nonneg(IR.weights(IR.Scheme{3n, 2n}))) ++ "\n"

def main() -> IO(Unit):
  IO.write(report())
