# PROOF_BIG.bend - proofs of LAWS_BIG.bend (bit-list arithmetic is sound w.r.t. Big.to_nat).

import Base
import ./big.bend as Big
import ./LAWS_BIG.bend as Laws

# ---------------------------------------------------------------------------
# Nat kit (Base ships none). Every lemma is oriented with the term a rewrite
# must ELIMINATE on the right-hand side.
# ---------------------------------------------------------------------------

def add_zero(a: Nat) -> {a == Nat.add(a, 0n) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+p == 1n+_ : Nat}
      {==}

def add_zero_r(a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero_r(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def add_succ(a: Nat, -b: Nat) -> {1n+Nat.add(a, b) == Nat.add(a, 1n+b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, b) : {2n+Nat.add(p, b) == 1n+_ : Nat}
      {==}

def add_one(a: Nat) -> {1n+a == Nat.add(a, 1n) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_one(p) : {2n+p == 1n+_ : Nat}
      {==}

def one_add(a: Nat) -> {Nat.add(a, 1n) == 1n+a : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %one_add(p) : {1n+Nat.add(p, 1n) == 1n+_ : Nat}
      {==}

def double_add(a: Nat, -b: Nat) -> {Nat.add(Nat.double(a), Nat.double(b)) == Nat.double(Nat.add(a, b)) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %double_add(p, b) : {2n+Nat.add(Nat.double(p), Nat.double(b)) == 2n+_ : Nat}
      {==}

# ---------------------------------------------------------------------------
# add_carry: per-bit steps as pure Nat lemmas. a = to_nat(xt), r = to_nat(add_carry(xt, c2)),
# ih = the induction hypothesis on xt.
# ---------------------------------------------------------------------------

# x = False, c = False
def ac_ff(+a: Nat, -r: Nat, ih: {Nat.add(a, 0n) == r : Nat}) -> {Nat.add(Nat.double(a), 0n) == Nat.double(r) : Nat}:
  %ih : {Nat.add(Nat.double(a), 0n) == Nat.double(_) : Nat}
  %add_zero(a) : {Nat.add(Nat.double(a), 0n) == Nat.double(_) : Nat}
  %add_zero(Nat.double(a)) : {_ == Nat.double(a) : Nat}
  {==}

# x = False, c = True
def ac_ft(+a: Nat, -r: Nat, ih: {Nat.add(a, 0n) == r : Nat}) -> {Nat.add(Nat.double(a), 1n) == 1n+Nat.double(r) : Nat}:
  %ih : {Nat.add(Nat.double(a), 1n) == 1n+Nat.double(_) : Nat}
  %add_zero(a) : {Nat.add(Nat.double(a), 1n) == 1n+Nat.double(_) : Nat}
  %add_one(Nat.double(a)) : {_ == 1n+Nat.double(a) : Nat}
  {==}

# x = True, c = False
def ac_tf(+a: Nat, -r: Nat, ih: {Nat.add(a, 0n) == r : Nat}) -> {1n+Nat.add(Nat.double(a), 0n) == 1n+Nat.double(r) : Nat}:
  %ih : {1n+Nat.add(Nat.double(a), 0n) == 1n+Nat.double(_) : Nat}
  %add_zero(a) : {1n+Nat.add(Nat.double(a), 0n) == 1n+Nat.double(_) : Nat}
  %add_zero(Nat.double(a)) : {1n+_ == 1n+Nat.double(a) : Nat}
  {==}

# x = True, c = True
def ac_tt(+a: Nat, -r: Nat, ih: {Nat.add(a, 1n) == r : Nat}) -> {1n+Nat.add(Nat.double(a), 1n) == Nat.double(r) : Nat}:
  %ih : {1n+Nat.add(Nat.double(a), 1n) == Nat.double(_) : Nat}
  %add_one(a) : {1n+Nat.add(Nat.double(a), 1n) == Nat.double(_) : Nat}
  %add_one(Nat.double(a)) : {1n+_ == 2n+Nat.double(a) : Nat}
  {==}

# flipped orientation: the stuck to_nat(add_carry ..) is on the right
def ac_sound(xs: List<&2, Bool>, c: Bool) -> {Nat.add(Big.Big.to_nat(xs), Big.Big.bit(c)) == Big.Big.to_nat(Big.Big.add_carry(xs, c)) : Nat}:
  match xs c:
    case Nil{} False{}:
      {==}
    case Nil{} True{}:
      {==}
    case Con{False{}, +xt} False{}:
      ac_ff(Big.Big.to_nat(xt), Big.Big.to_nat(Big.Big.add_carry(xt, False{})), ac_sound(xt, False{}))
    case Con{False{}, +xt} True{}:
      ac_ft(Big.Big.to_nat(xt), Big.Big.to_nat(Big.Big.add_carry(xt, False{})), ac_sound(xt, False{}))
    case Con{True{}, +xt} False{}:
      ac_tf(Big.Big.to_nat(xt), Big.Big.to_nat(Big.Big.add_carry(xt, False{})), ac_sound(xt, False{}))
    case Con{True{}, +xt} True{}:
      ac_tt(Big.Big.to_nat(xt), Big.Big.to_nat(Big.Big.add_carry(xt, True{})), ac_sound(xt, True{}))

# ac_sound with a stuck Nat.add(_, 0n) on the left (the Con/Nil arm of add_go)
def ac_sound_z(+xs: List<&2, Bool>, +c: Bool) -> {Nat.add(Nat.add(Big.Big.to_nat(xs), 0n), Big.Big.bit(c)) == Big.Big.to_nat(Big.Big.add_carry(xs, c)) : Nat}:
  %add_zero(Big.Big.to_nat(xs)) : {Nat.add(_, Big.Big.bit(c)) == Big.Big.to_nat(Big.Big.add_carry(xs, c)) : Nat}
  ac_sound(xs, c)

# ---------------------------------------------------------------------------
# add_go: the 8 full-adder cases as pure Nat lemmas. a = to_nat(xt), b = to_nat(yt),
# r = to_nat(add_go(xt, yt, carry3(x, y, c))), ih = the induction hypothesis.
# ---------------------------------------------------------------------------

# x=F y=F c=F : sum=F carry=F
def ag_fff(+a: Nat, +b: Nat, -r: Nat, ih: {Nat.add(Nat.add(a, b), 0n) == r : Nat}) -> {Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 0n) == Nat.double(r) : Nat}:
  %ih : {Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 0n) == Nat.double(_) : Nat}
  %add_zero(Nat.add(a, b)) : {Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 0n) == Nat.double(_) : Nat}
  %double_add(a, b) : {Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 0n) == _ : Nat}
  %add_zero(Nat.add(Nat.double(a), Nat.double(b))) : {_ == Nat.add(Nat.double(a), Nat.double(b)) : Nat}
  {==}

# x=F y=F c=T : sum=T carry=F
def ag_fft(+a: Nat, +b: Nat, -r: Nat, ih: {Nat.add(Nat.add(a, b), 0n) == r : Nat}) -> {Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 1n) == 1n+Nat.double(r) : Nat}:
  %ih : {Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 1n) == 1n+Nat.double(_) : Nat}
  %add_zero(Nat.add(a, b)) : {Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 1n) == 1n+Nat.double(_) : Nat}
  %double_add(a, b) : {Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 1n) == 1n+_ : Nat}
  %add_one(Nat.add(Nat.double(a), Nat.double(b))) : {_ == 1n+Nat.add(Nat.double(a), Nat.double(b)) : Nat}
  {==}

# x=F y=T c=F : sum=T carry=F
def ag_ftf(+a: Nat, +b: Nat, -r: Nat, ih: {Nat.add(Nat.add(a, b), 0n) == r : Nat}) -> {Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 0n) == 1n+Nat.double(r) : Nat}:
  %ih : {Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 0n) == 1n+Nat.double(_) : Nat}
  %add_zero(Nat.add(a, b)) : {Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 0n) == 1n+Nat.double(_) : Nat}
  %double_add(a, b) : {Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 0n) == 1n+_ : Nat}
  %add_zero(Nat.add(Nat.double(a), 1n+Nat.double(b))) : {_ == 1n+Nat.add(Nat.double(a), Nat.double(b)) : Nat}
  %add_succ(Nat.double(a), Nat.double(b)) : {_ == 1n+Nat.add(Nat.double(a), Nat.double(b)) : Nat}
  {==}

# x=F y=T c=T : sum=F carry=T
def ag_ftt(+a: Nat, +b: Nat, -r: Nat, ih: {Nat.add(Nat.add(a, b), 1n) == r : Nat}) -> {Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 1n) == Nat.double(r) : Nat}:
  %ih : {Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 1n) == Nat.double(_) : Nat}
  %add_one(Nat.add(a, b)) : {Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 1n) == Nat.double(_) : Nat}
  %double_add(a, b) : {Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 1n) == 2n+_ : Nat}
  %add_one(Nat.add(Nat.double(a), 1n+Nat.double(b))) : {_ == 2n+Nat.add(Nat.double(a), Nat.double(b)) : Nat}
  %add_succ(Nat.double(a), Nat.double(b)) : {1n+_ == 2n+Nat.add(Nat.double(a), Nat.double(b)) : Nat}
  {==}

# x=T y=F c=F : sum=T carry=F
def ag_tff(+a: Nat, +b: Nat, -r: Nat, ih: {Nat.add(Nat.add(a, b), 0n) == r : Nat}) -> {1n+Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 0n) == 1n+Nat.double(r) : Nat}:
  %ih : {1n+Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 0n) == 1n+Nat.double(_) : Nat}
  %add_zero(Nat.add(a, b)) : {1n+Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 0n) == 1n+Nat.double(_) : Nat}
  %double_add(a, b) : {1n+Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 0n) == 1n+_ : Nat}
  %add_zero(Nat.add(Nat.double(a), Nat.double(b))) : {1n+_ == 1n+Nat.add(Nat.double(a), Nat.double(b)) : Nat}
  {==}

# x=T y=F c=T : sum=F carry=T
def ag_tft(+a: Nat, +b: Nat, -r: Nat, ih: {Nat.add(Nat.add(a, b), 1n) == r : Nat}) -> {1n+Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 1n) == Nat.double(r) : Nat}:
  %ih : {1n+Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 1n) == Nat.double(_) : Nat}
  %add_one(Nat.add(a, b)) : {1n+Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 1n) == Nat.double(_) : Nat}
  %double_add(a, b) : {1n+Nat.add(Nat.add(Nat.double(a), Nat.double(b)), 1n) == 2n+_ : Nat}
  %add_one(Nat.add(Nat.double(a), Nat.double(b))) : {1n+_ == 2n+Nat.add(Nat.double(a), Nat.double(b)) : Nat}
  {==}

# x=T y=T c=F : sum=F carry=T
def ag_ttf(+a: Nat, +b: Nat, -r: Nat, ih: {Nat.add(Nat.add(a, b), 1n) == r : Nat}) -> {1n+Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 0n) == Nat.double(r) : Nat}:
  %ih : {1n+Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 0n) == Nat.double(_) : Nat}
  %add_one(Nat.add(a, b)) : {1n+Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 0n) == Nat.double(_) : Nat}
  %double_add(a, b) : {1n+Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 0n) == 2n+_ : Nat}
  %add_zero(Nat.add(Nat.double(a), 1n+Nat.double(b))) : {1n+_ == 2n+Nat.add(Nat.double(a), Nat.double(b)) : Nat}
  %add_succ(Nat.double(a), Nat.double(b)) : {1n+_ == 2n+Nat.add(Nat.double(a), Nat.double(b)) : Nat}
  {==}

# x=T y=T c=T : sum=T carry=T
def ag_ttt(+a: Nat, +b: Nat, -r: Nat, ih: {Nat.add(Nat.add(a, b), 1n) == r : Nat}) -> {1n+Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 1n) == 1n+Nat.double(r) : Nat}:
  %ih : {1n+Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 1n) == 1n+Nat.double(_) : Nat}
  %add_one(Nat.add(a, b)) : {1n+Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 1n) == 1n+Nat.double(_) : Nat}
  %double_add(a, b) : {1n+Nat.add(Nat.add(Nat.double(a), 1n+Nat.double(b)), 1n) == 3n+_ : Nat}
  %add_one(Nat.add(Nat.double(a), 1n+Nat.double(b))) : {1n+_ == 3n+Nat.add(Nat.double(a), Nat.double(b)) : Nat}
  %add_succ(Nat.double(a), Nat.double(b)) : {2n+_ == 3n+Nat.add(Nat.double(a), Nat.double(b)) : Nat}
  {==}

# flipped orientation, induction on xs (as add_go). The carry sits between xs and ys so
# that one match can split xs, c and ys at once (an inner match on the fields of a
# multi-scrutinee case is refused: "match scrutinees in binder order").
def ag_sound(xs: List<&2, Bool>, +c: Bool, ys: List<&2, Bool>) -> {Nat.add(Nat.add(Big.Big.to_nat(xs), Big.Big.to_nat(ys)), Big.Big.bit(c)) == Big.Big.to_nat(Big.Big.add_go(xs, ys, c)) : Nat}:
  match xs c ys:
    case Nil{} c2 ys2:
      ac_sound(ys2, c2)
    case Con{x, xt} c2 Nil{}:
      ac_sound_z(x <> xt, c2)
    case Con{False{}, +xt} False{} Con{False{}, +yt}:
      ag_fff(Big.Big.to_nat(xt), Big.Big.to_nat(yt), Big.Big.to_nat(Big.Big.add_go(xt, yt, False{})), ag_sound(xt, False{}, yt))
    case Con{False{}, +xt} True{} Con{False{}, +yt}:
      ag_fft(Big.Big.to_nat(xt), Big.Big.to_nat(yt), Big.Big.to_nat(Big.Big.add_go(xt, yt, False{})), ag_sound(xt, False{}, yt))
    case Con{False{}, +xt} False{} Con{True{}, +yt}:
      ag_ftf(Big.Big.to_nat(xt), Big.Big.to_nat(yt), Big.Big.to_nat(Big.Big.add_go(xt, yt, False{})), ag_sound(xt, False{}, yt))
    case Con{False{}, +xt} True{} Con{True{}, +yt}:
      ag_ftt(Big.Big.to_nat(xt), Big.Big.to_nat(yt), Big.Big.to_nat(Big.Big.add_go(xt, yt, True{})), ag_sound(xt, True{}, yt))
    case Con{True{}, +xt} False{} Con{False{}, +yt}:
      ag_tff(Big.Big.to_nat(xt), Big.Big.to_nat(yt), Big.Big.to_nat(Big.Big.add_go(xt, yt, False{})), ag_sound(xt, False{}, yt))
    case Con{True{}, +xt} True{} Con{False{}, +yt}:
      ag_tft(Big.Big.to_nat(xt), Big.Big.to_nat(yt), Big.Big.to_nat(Big.Big.add_go(xt, yt, True{})), ag_sound(xt, True{}, yt))
    case Con{True{}, +xt} False{} Con{True{}, +yt}:
      ag_ttf(Big.Big.to_nat(xt), Big.Big.to_nat(yt), Big.Big.to_nat(Big.Big.add_go(xt, yt, True{})), ag_sound(xt, True{}, yt))
    case Con{True{}, +xt} True{} Con{True{}, +yt}:
      ag_ttt(Big.Big.to_nat(xt), Big.Big.to_nat(yt), Big.Big.to_nat(Big.Big.add_go(xt, yt, True{})), ag_sound(xt, True{}, yt))

# ---------------------------------------------------------------------------
# The laws
# ---------------------------------------------------------------------------

def Laws.add_carry_sound(xs, c):
  Equal.sym(Nat, Nat.add(Big.Big.to_nat(xs), Big.Big.bit(c)), Big.Big.to_nat(Big.Big.add_carry(xs, c)), ac_sound(xs, c))

def Laws.add_go_sound(xs, ys, c):
  Equal.sym(Nat, Nat.add(Nat.add(Big.Big.to_nat(xs), Big.Big.to_nat(ys)), Big.Big.bit(c)), Big.Big.to_nat(Big.Big.add_go(xs, ys, c)), ag_sound(xs, c, ys))

def Laws.add_sound(xs, ys):
  %add_zero_r(Nat.add(Big.Big.to_nat(xs), Big.Big.to_nat(ys))) : {Big.Big.to_nat(Big.Big.add(xs, ys)) == _ : Nat}
  Laws.add_go_sound(xs, ys, False{})

def Laws.inc_sound(xs):
  %one_add(Big.Big.to_nat(xs)) : {Big.Big.to_nat(Big.Big.inc(xs)) == _ : Nat}
  Laws.add_carry_sound(xs, True{})

def Laws.from_nat_sound(n):
  match n:
    case 0n:
      {==}
    case 1n++p:
      %Laws.from_nat_sound(p) : {Big.Big.to_nat(Big.Big.inc(Big.Big.from_nat(p))) == 1n+_ : Nat}
      Laws.inc_sound(Big.Big.from_nat(p))
