import Base
import ./../big.bend as Big

# values checked by run_big_test.py against Python ints
def report() -> String:
  +a = Big.Big.from_nat(U32.to_nat(4294967295))          # 2^32 - 1
  +b = Big.Big.from_nat(Nat.mul(U32.to_nat(4000000000), U32.to_nat(65536)))   # 4e9 * 2^16 < 2^48
  "a      " ++ Big.Big.dump(a) ++ "\n" ++
  "b      " ++ Big.Big.dump(b) ++ "\n" ++
  "a+b    " ++ Big.Big.dump(Big.Big.add(a, b)) ++ "\n" ++
  "a*b    " ++ Big.Big.dump(Big.Big.mul(a, b)) ++ "\n" ++
  "b*b    " ++ Big.Big.dump(Big.Big.mul(b, b)) ++ "\n" ++
  "b*b*b  " ++ Big.Big.dump(Big.Big.mul(Big.Big.mul(b, b), b)) ++ "\n" ++
  "a*3    " ++ Big.Big.dump(Big.Big.mul_small(a, 3n, 0n)) ++ "\n" ++
  "0+a    " ++ Big.Big.dump(Big.Big.add(Nil{}, a)) ++ "\n" ++
  "a+0    " ++ Big.Big.dump(Big.Big.add(a, Nil{})) ++ "\n"

def main() -> IO(Unit):
  IO.write(report())
