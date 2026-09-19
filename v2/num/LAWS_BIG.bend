# LAWS_BIG.bend - the bit-list arithmetic means what it should. Proven in PROOF_BIG.bend.

import Base
import ./big.bend as Big

law add_carry_sound:
  for +xs: List<&2, Bool>
  for +c: Bool
  {Big.Big.to_nat(Big.Big.add_carry(xs, c)) == Nat.add(Big.Big.to_nat(xs), Big.Big.bit(c)) : Nat}

law add_go_sound:
  for +xs: List<&2, Bool>
  for +ys: List<&2, Bool>
  for +c: Bool
  {Big.Big.to_nat(Big.Big.add_go(xs, ys, c)) == Nat.add(Nat.add(Big.Big.to_nat(xs), Big.Big.to_nat(ys)), Big.Big.bit(c)) : Nat}

law add_sound:
  for +xs: List<&2, Bool>
  for +ys: List<&2, Bool>
  {Big.Big.to_nat(Big.Big.add(xs, ys)) == Nat.add(Big.Big.to_nat(xs), Big.Big.to_nat(ys)) : Nat}

law inc_sound:
  for +xs: List<&2, Bool>
  {Big.Big.to_nat(Big.Big.inc(xs)) == 1n+Big.Big.to_nat(xs) : Nat}

law from_nat_sound:
  for +n: Nat
  {Big.Big.to_nat(Big.Big.from_nat(n)) == n : Nat}
