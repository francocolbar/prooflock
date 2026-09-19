import Base
import ./../num/z.bend as Z

def z(n: Nat) -> Z.Z:
  Z.Z.from_nat(n)

def report() -> String:
  "3 + 5      = " ++ Z.Z.show(Z.Z.add(z(3n), z(5n))) ++ "\n" ++
  "3 + -5     = " ++ Z.Z.show(Z.Z.add(z(3n), Z.Z.neg(z(5n)))) ++ "\n" ++
  "-3 + 5     = " ++ Z.Z.show(Z.Z.add(Z.Z.neg(z(3n)), z(5n))) ++ "\n" ++
  "-3 + -5    = " ++ Z.Z.show(Z.Z.add(Z.Z.neg(z(3n)), Z.Z.neg(z(5n)))) ++ "\n" ++
  "5 - 5      = " ++ Z.Z.show(Z.Z.sub(z(5n), z(5n))) ++ "\n" ++
  "3 * 5      = " ++ Z.Z.show(Z.Z.mul(z(3n), z(5n))) ++ "\n" ++
  "-3 * 5     = " ++ Z.Z.show(Z.Z.mul(Z.Z.neg(z(3n)), z(5n))) ++ "\n" ++
  "3 * -5     = " ++ Z.Z.show(Z.Z.mul(z(3n), Z.Z.neg(z(5n)))) ++ "\n" ++
  "-3 * -5    = " ++ Z.Z.show(Z.Z.mul(Z.Z.neg(z(3n)), Z.Z.neg(z(5n)))) ++ "\n" ++
  "0 * -5     = " ++ Z.Z.show(Z.Z.mul(z(0n), Z.Z.neg(z(5n)))) ++ "\n" ++
  "-5 * 0     = " ++ Z.Z.show(Z.Z.mul(Z.Z.neg(z(5n)), z(0n))) ++ "\n" ++
  "pred(succ(-1)) = " ++ Z.Z.show(Z.Z.pred(Z.Z.succ(Z.Z.neg(z(1n))))) ++ "\n" ++
  "succ(pred(0))  = " ++ Z.Z.show(Z.Z.succ(Z.Z.pred(z(0n)))) ++ "\n"

def main() -> IO(Unit):
  IO.write(report())
