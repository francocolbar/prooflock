# LAWS_Z_ADD.bend - succ/pred, addition and negation on Z. Proven in PROOF_Z_ADD.bend.
# Every parameter is +: proofs spend them freely.

import Base
import ./z.bend as Z

# succ and pred are inverse
law succ_pred:
  for +a: Z.Z
  {Z.Z.succ(Z.Z.pred(a)) == a : Z.Z}

law pred_succ:
  for +a: Z.Z
  {Z.Z.pred(Z.Z.succ(a)) == a : Z.Z}

# addition: neutral element, shifting, commutativity, associativity
law add_zero_r:
  for +a: Z.Z
  {Z.Z.add(a, Z.Zero{}) == a : Z.Z}

law add_succ_r:
  for +a: Z.Z
  for +b: Z.Z
  {Z.Z.add(a, Z.Z.succ(b)) == Z.Z.succ(Z.Z.add(a, b)) : Z.Z}

law add_pred_r:
  for +a: Z.Z
  for +b: Z.Z
  {Z.Z.add(a, Z.Z.pred(b)) == Z.Z.pred(Z.Z.add(a, b)) : Z.Z}

law add_succ_l:
  for +a: Z.Z
  for +b: Z.Z
  {Z.Z.add(Z.Z.succ(a), b) == Z.Z.succ(Z.Z.add(a, b)) : Z.Z}

law add_pred_l:
  for +a: Z.Z
  for +b: Z.Z
  {Z.Z.add(Z.Z.pred(a), b) == Z.Z.pred(Z.Z.add(a, b)) : Z.Z}

law add_comm:
  for +a: Z.Z
  for +b: Z.Z
  {Z.Z.add(a, b) == Z.Z.add(b, a) : Z.Z}

law add_assoc:
  for +a: Z.Z
  for +b: Z.Z
  for +c: Z.Z
  {Z.Z.add(a, Z.Z.add(b, c)) == Z.Z.add(Z.Z.add(a, b), c) : Z.Z}

# negation
law neg_neg:
  for +a: Z.Z
  {Z.Z.neg(Z.Z.neg(a)) == a : Z.Z}

law add_neg_r:
  for +a: Z.Z
  {Z.Z.add(a, Z.Z.neg(a)) == Z.Zero{} : Z.Z}

law neg_add:
  for +a: Z.Z
  for +b: Z.Z
  {Z.Z.neg(Z.Z.add(a, b)) == Z.Z.add(Z.Z.neg(a), Z.Z.neg(b)) : Z.Z}

# the embedding of Nat is a homomorphism
law from_nat_add:
  for +a: Nat
  for +b: Nat
  {Z.Z.from_nat(Nat.add(a, b)) == Z.Z.add(Z.Z.from_nat(a), Z.Z.from_nat(b)) : Z.Z}
