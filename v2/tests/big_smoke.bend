# big_smoke.bend - bit lists and big integers on small values, checked by run_big_smoke.py
import Base
import ./../num/z.bend as Z
import ./../num/big.bend as Big
import ./../num/bigz.bend as BigZ

def b(n: Nat) -> List<&2, Bool>:
  Big.Big.from_nat(n)

def bz(c: Z.Z) -> BigZ.BigZ:
  BigZ.BigZ.from_z(c)

def report() -> String:
  "13           " ++ Big.Big.show(b(13n)) ++ "\n" ++
  "13+29        " ++ Big.Big.show(Big.Big.add(b(13n), b(29n))) ++ "\n" ++
  "255+1        " ++ Big.Big.show(Big.Big.add(b(255n), b(1n))) ++ "\n" ++
  "0+7          " ++ Big.Big.show(Big.Big.add(Nil{}, b(7n))) ++ "\n" ++
  "7+0          " ++ Big.Big.show(Big.Big.add(b(7n), Nil{})) ++ "\n" ++
  "inc 15       " ++ Big.Big.show(Big.Big.inc(b(15n))) ++ "\n" ++
  "parse 1011   " ++ Nat.show(Big.Big.to_nat(Big.Big.parse("1011"))) ++ "\n" ++
  "to_nat 200   " ++ Nat.show(Big.Big.to_nat(b(200n))) ++ "\n" ++
  "z 5+-8       " ++ Z.Z.show(BigZ.BigZ.to_z(BigZ.BigZ.add(bz(Z.Pos{4n}), bz(Z.Neg{7n})))) ++ "\n" ++
  "z -3*7       " ++ Z.Z.show(BigZ.BigZ.to_z(BigZ.BigZ.scale(Z.Neg{2n}, bz(Z.Pos{6n})))) ++ "\n" ++
  "z 3*-7       " ++ Z.Z.show(BigZ.BigZ.to_z(BigZ.BigZ.scale(Z.Pos{2n}, bz(Z.Neg{6n})))) ++ "\n" ++
  "z 0*-7       " ++ Z.Z.show(BigZ.BigZ.to_z(BigZ.BigZ.scale(Z.Zero{}, bz(Z.Neg{6n})))) ++ "\n" ++
  "z neg -9     " ++ Z.Z.show(BigZ.BigZ.to_z(BigZ.BigZ.neg(bz(Z.Neg{8n})))) ++ "\n" ++
  "show 5+-8    " ++ BigZ.BigZ.show(BigZ.BigZ.add(bz(Z.Pos{4n}), bz(Z.Neg{7n}))) ++ "\n"

def main() -> IO(Unit):
  IO.write(report())
