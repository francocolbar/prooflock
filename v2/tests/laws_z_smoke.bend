# laws_z_smoke.bend - instantiates every law of LAWS_Z_ADD/LAWS_Z_MUL on a grid of
# small integers BEFORE anyone tries to prove it. A false statement (typo, wrong
# argument order) shows up here as FALSE in seconds.
import Base
import ./../num/z.bend as Z

def eq(a: Z.Z, b: Z.Z) -> Bool:
  Z.Z.is_eq(a, b)

# one-parameter laws
def chk1(sel: Nat, +a: Z.Z) -> Bool:
  match sel:
    case 0n:
      eq(Z.Z.succ(Z.Z.pred(a)), a)
    case 1n:
      eq(Z.Z.pred(Z.Z.succ(a)), a)
    case 2n:
      eq(Z.Z.add(a, Z.Zero{}), a)
    case 3n:
      eq(Z.Z.neg(Z.Z.neg(a)), a)
    case 4n:
      eq(Z.Z.add(a, Z.Z.neg(a)), Z.Zero{})
    case 5n:
      eq(Z.Z.mul(a, Z.Zero{}), Z.Zero{})
    case 6n:
      eq(Z.Z.mul(Z.Pos{0n}, a), a)
    case 7n:
      eq(Z.Z.mul(a, Z.Pos{0n}), a)
    case 8n+_:
      True{}

# two-parameter laws
def chk2(sel: Nat, +a: Z.Z, +b: Z.Z) -> Bool:
  match sel:
    case 0n:
      eq(Z.Z.add(a, Z.Z.succ(b)), Z.Z.succ(Z.Z.add(a, b)))
    case 1n:
      eq(Z.Z.add(a, Z.Z.pred(b)), Z.Z.pred(Z.Z.add(a, b)))
    case 2n:
      eq(Z.Z.add(Z.Z.succ(a), b), Z.Z.succ(Z.Z.add(a, b)))
    case 3n:
      eq(Z.Z.add(Z.Z.pred(a), b), Z.Z.pred(Z.Z.add(a, b)))
    case 4n:
      eq(Z.Z.add(a, b), Z.Z.add(b, a))
    case 5n:
      eq(Z.Z.neg(Z.Z.add(a, b)), Z.Z.add(Z.Z.neg(a), Z.Z.neg(b)))
    case 6n:
      eq(Z.Z.mul(Z.Z.neg(a), b), Z.Z.neg(Z.Z.mul(a, b)))
    case 7n:
      eq(Z.Z.mul(a, Z.Z.neg(b)), Z.Z.neg(Z.Z.mul(a, b)))
    case 8n:
      eq(Z.Z.mul(a, b), Z.Z.mul(b, a))
    case 9n:
      eq(Z.Z.from_nat(Nat.add(Z.Z.abs(a), Z.Z.abs(b))), Z.Z.add(Z.Z.from_nat(Z.Z.abs(a)), Z.Z.from_nat(Z.Z.abs(b))))
    case 10n+_:
      True{}

# three-parameter laws
def chk3(sel: Nat, +a: Z.Z, +b: Z.Z, +c: Z.Z) -> Bool:
  match sel:
    case 0n:
      eq(Z.Z.add(a, Z.Z.add(b, c)), Z.Z.add(Z.Z.add(a, b), c))
    case 1n:
      eq(Z.Z.mul(a, Z.Z.add(b, c)), Z.Z.add(Z.Z.mul(a, b), Z.Z.mul(a, c)))
    case 2n:
      eq(Z.Z.mul(Z.Z.add(a, b), c), Z.Z.add(Z.Z.mul(a, c), Z.Z.mul(b, c)))
    case 3n:
      eq(Z.Z.mul(a, Z.Z.mul(b, c)), Z.Z.mul(Z.Z.mul(a, b), c))
    case 4n+_:
      True{}

def grid() -> List<&2, Z.Z>:
  [Z.Neg{2n}, Z.Neg{1n}, Z.Neg{0n}, Z.Zero{}, Z.Pos{0n}, Z.Pos{1n}, Z.Pos{2n}]

def all1(xs: List<&2, Z.Z>, +sel: Nat) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case Con{x, t}:
      Bool.and(chk1(sel, x), all1(t, sel))

def all2_go(ys: List<&2, Z.Z>, +sel: Nat, +x: Z.Z) -> Bool:
  match ys:
    case Nil{}:
      True{}
    case Con{y, t}:
      Bool.and(chk2(sel, x, y), all2_go(t, sel, x))

def all2(xs: List<&2, Z.Z>, +sel: Nat) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case Con{x, t}:
      Bool.and(all2_go(grid(), sel, x), all2(t, sel))

def all3_go2(zs: List<&2, Z.Z>, +sel: Nat, +x: Z.Z, +y: Z.Z) -> Bool:
  match zs:
    case Nil{}:
      True{}
    case Con{z, t}:
      Bool.and(chk3(sel, x, y, z), all3_go2(t, sel, x, y))

def all3_go(ys: List<&2, Z.Z>, +sel: Nat, +x: Z.Z) -> Bool:
  match ys:
    case Nil{}:
      True{}
    case Con{y, t}:
      Bool.and(all3_go2(grid(), sel, x, y), all3_go(t, sel, x))

def all3(xs: List<&2, Z.Z>, +sel: Nat) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case Con{x, t}:
      Bool.and(all3_go(grid(), sel, x), all3(t, sel))

def line(name: String, ok: Bool) -> String:
  match ok:
    case True{}:
      "ok    " ++ name ++ "\n"
    case False{}:
      "FALSE " ++ name ++ "\n"

def report() -> String:
  line("succ_pred", all1(grid(), 0n)) ++ line("pred_succ", all1(grid(), 1n)) ++
  line("add_zero_r", all1(grid(), 2n)) ++ line("neg_neg", all1(grid(), 3n)) ++
  line("add_neg_r", all1(grid(), 4n)) ++ line("mul_zero_r", all1(grid(), 5n)) ++
  line("mul_one_l", all1(grid(), 6n)) ++ line("mul_one_r", all1(grid(), 7n)) ++
  line("add_succ_r", all2(grid(), 0n)) ++ line("add_pred_r", all2(grid(), 1n)) ++
  line("add_succ_l", all2(grid(), 2n)) ++ line("add_pred_l", all2(grid(), 3n)) ++
  line("add_comm", all2(grid(), 4n)) ++ line("neg_add", all2(grid(), 5n)) ++
  line("mul_neg_l", all2(grid(), 6n)) ++ line("mul_neg_r", all2(grid(), 7n)) ++
  line("mul_comm", all2(grid(), 8n)) ++ line("from_nat_add", all2(grid(), 9n)) ++
  line("add_assoc", all3(grid(), 0n)) ++ line("dist_l", all3(grid(), 1n)) ++
  line("dist_r", all3(grid(), 2n)) ++ line("mul_assoc", all3(grid(), 3n))

def main() -> IO(Unit):
  IO.write(report())
