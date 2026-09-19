import Base

def big() -> Nat:
  Nat.mul(U32.to_nat(4000000000), U32.to_nat(4000000000))

def main() -> Nat:
  Nat.mul(big(), big())
