import Base

def big() -> Nat:
  Nat.mul(U32.to_nat(4000000000), U32.to_nat(4000000000))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(Nat.mul(big(), big())))
