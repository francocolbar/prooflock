# PROOF_JETPROT.bend - the laws of jetprot, by REFLECTION on the finite certificates:
# PROOF_JETPROT_FIN.bend / PROOF_JETPROT_FIN_ALT.bend decide `check_fin(o) == True` by
# computation for each order and PROOF_JETPROT_COR.bend decides `check_cor() == True`; here
# one small lemma per quantifier level turns those Bools into universal statements about
# every (order, control state, event, verdicts) cell, and short lemmas turn a cell into the
# step laws and the preservation laws. The only inductions are on the traces.
import Base
import ./jetprot.bend as S
import ./spec_jetprot.bend as Spec
import ./enum_jetprot.bend as E
import ./LAWS_JETPROT.bend as Laws
import ./PROOF_JETPROT_FIN.bend as PF
import ./PROOF_JETPROT_FIN_ALT.bend as PFA
import ./PROOF_JETPROT_COR.bend as PC

# ---------------------------------------------------------------------------
# Bool facts
# ---------------------------------------------------------------------------

# the motive of a Bool clash: sends True to the wanted type and False to Unit
def At(A: Type, b: Bool) -> Type:
  match b:
    case True{}:
      A
    case False{}:
      Unit

# anything follows from False == True
def clash_ft(-A: Type, e: {False{} == True{} : Bool}) -> A:
  %e : At(A, _)
  Unit{}

# the motive of a True/False clash in the other direction
def Af(A: Type, b: Bool) -> Type:
  match b:
    case True{}:
      Unit
    case False{}:
      A

def clash_tf(-A: Type, e: {True{} == False{} : Bool}) -> A:
  %e : Af(A, _)
  Unit{}

def and_l(a: Bool, -b: Bool, h: {Bool.and(a, b) == True{} : Bool}) -> {a == True{} : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      h

def and_r(a: Bool, -b: Bool, h: {Bool.and(a, b) == True{} : Bool}) -> {b == True{} : Bool}:
  match a:
    case True{}:
      h
    case False{}:
      clash_ft({b == True{} : Bool}, h)

def and_intro(a: Bool, -b: Bool, ha: {a == True{} : Bool}, hb: {b == True{} : Bool}) -> {Bool.and(a, b) == True{} : Bool}:
  match a:
    case True{}:
      hb
    case False{}:
      clash_ft({Bool.and(False{}, b) == True{} : Bool}, ha)

# modus ponens on the Bool implication
def implies_e(a: Bool, -b: Bool, h: {S.implies(a, b) == True{} : Bool}, ha: {a == True{} : Bool}) -> {b == True{} : Bool}:
  match a:
    case True{}:
      h
    case False{}:
      clash_ft({b == True{} : Bool}, ha)

# projections of and(a, and(b, c))
def and3_1(+a: Bool, +b: Bool, +c: Bool, h: {Bool.and(a, Bool.and(b, c)) == True{} : Bool}) -> {a == True{} : Bool}:
  and_l(a, Bool.and(b, c), h)

def and3_2(+a: Bool, +b: Bool, +c: Bool, h: {Bool.and(a, Bool.and(b, c)) == True{} : Bool}) -> {b == True{} : Bool}:
  and_l(b, c, and_r(a, Bool.and(b, c), h))

def and3_3(+a: Bool, +b: Bool, +c: Bool, h: {Bool.and(a, Bool.and(b, c)) == True{} : Bool}) -> {c == True{} : Bool}:
  and_r(b, c, and_r(a, Bool.and(b, c), h))

# projections of and(and(a, b), and(c, d))
def and4_1(+a: Bool, +b: Bool, +c: Bool, +d: Bool, h: {Bool.and(Bool.and(a, b), Bool.and(c, d)) == True{} : Bool}) -> {a == True{} : Bool}:
  and_l(a, b, and_l(Bool.and(a, b), Bool.and(c, d), h))

def and4_2(+a: Bool, +b: Bool, +c: Bool, +d: Bool, h: {Bool.and(Bool.and(a, b), Bool.and(c, d)) == True{} : Bool}) -> {b == True{} : Bool}:
  and_r(a, b, and_l(Bool.and(a, b), Bool.and(c, d), h))

def and4_3(+a: Bool, +b: Bool, +c: Bool, +d: Bool, h: {Bool.and(Bool.and(a, b), Bool.and(c, d)) == True{} : Bool}) -> {c == True{} : Bool}:
  and_l(c, d, and_r(Bool.and(a, b), Bool.and(c, d), h))

def and4_4(+a: Bool, +b: Bool, +c: Bool, +d: Bool, h: {Bool.and(Bool.and(a, b), Bool.and(c, d)) == True{} : Bool}) -> {d == True{} : Bool}:
  and_r(c, d, and_r(Bool.and(a, b), Bool.and(c, d), h))

# ---------------------------------------------------------------------------
# Reflection, FIRST ORDER: one lemma per quantifier level of enum_jetprot.bend, each
# specialised to the one concrete certificate function of that level (there are no
# higher-order parameters: Bend's `+` is a Data annotation and a predicate argument
# `+P: @p: S.Phase -> Bool` is rejected with `expected : Data / observed : Type`, while a
# plain function parameter is affine and cannot be used twice).
#
# The ladder starts one level BELOW the top. Bend's conversion compares normal forms, so
# turning `check_fin(o) == True` into `all_level(o, p) == True` would make the checker
# normalise the whole certificate with `o` and `p` still symbolic, twice per phase branch
# (minutes per branch). Instead the 56 slices `all_dms(o, p, l)` -- which together ARE
# `check_fin(Ord1)` and `check_fin(Ord2)`, the two certificates of LAWS_JETPROT.bend -- are
# decided directly by computation, exactly as PROOF_JETPROT_FIN.bend decides the whole of
# one order. From there every remaining comparison is over a term of at most 1/28 of a
# certificate.
# ---------------------------------------------------------------------------

# The certificate of LAWS_JETPROT.bend (finite_check / finite_check_alt, decided in
# PROOF_JETPROT_FIN.bend and _FIN_ALT.bend), sliced per (order, phase, stop level):
# 2 x 7 x 4 slices of 96 control states x 39 columns, i.e. exactly the 2 x 104 832 cells of
# check_fin(Ord1) and check_fin(Ord2), decided here the same way, by computation. Slicing
# is what keeps the ladder cheap: no comparison in this file ever has to normalise a whole
# certificate (even naming `check_fin(Ord1{})` in a type costs the checker a full
# evaluation of it on both sides of the comparison).
def base(o: S.Ord, p: S.Phase, l: S.Level) -> {E.all_dms(o, p, l) == True{} : Bool}:
  match o p l:
    case S.Ord1{} S.Breakdown{} S.LNone{}:
      {==}
    case S.Ord1{} S.Breakdown{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Breakdown{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Breakdown{} S.LPtn{}:
      {==}
    case S.Ord1{} S.IpRise{} S.LNone{}:
      {==}
    case S.Ord1{} S.IpRise{} S.LJtt{}:
      {==}
    case S.Ord1{} S.IpRise{} S.LRtps{}:
      {==}
    case S.Ord1{} S.IpRise{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Limiter{} S.LNone{}:
      {==}
    case S.Ord1{} S.Limiter{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Limiter{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Limiter{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Xpoint{} S.LNone{}:
      {==}
    case S.Ord1{} S.Xpoint{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Xpoint{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Xpoint{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Heating1{} S.LNone{}:
      {==}
    case S.Ord1{} S.Heating1{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Heating1{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Heating1{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Heating2{} S.LNone{}:
      {==}
    case S.Ord1{} S.Heating2{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Heating2{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Heating2{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Termination{} S.LNone{}:
      {==}
    case S.Ord1{} S.Termination{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Termination{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Termination{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Breakdown{} S.LNone{}:
      {==}
    case S.Ord2{} S.Breakdown{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Breakdown{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Breakdown{} S.LPtn{}:
      {==}
    case S.Ord2{} S.IpRise{} S.LNone{}:
      {==}
    case S.Ord2{} S.IpRise{} S.LJtt{}:
      {==}
    case S.Ord2{} S.IpRise{} S.LRtps{}:
      {==}
    case S.Ord2{} S.IpRise{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Limiter{} S.LNone{}:
      {==}
    case S.Ord2{} S.Limiter{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Limiter{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Limiter{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Xpoint{} S.LNone{}:
      {==}
    case S.Ord2{} S.Xpoint{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Xpoint{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Xpoint{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Heating1{} S.LNone{}:
      {==}
    case S.Ord2{} S.Heating1{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Heating1{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Heating1{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Heating2{} S.LNone{}:
      {==}
    case S.Ord2{} S.Heating2{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Heating2{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Heating2{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Termination{} S.LNone{}:
      {==}
    case S.Ord2{} S.Termination{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Termination{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Termination{} S.LPtn{}:
      {==}

# --- the control fields below the stop level: dms, plasma, nb, rf ---

def lvl_dms(+o: S.Ord, +p: S.Phase, +l: S.Level, d: S.Dms, h: {E.all_dms(o, p, l) == True{} : Bool}) -> {E.all_plasma(o, p, l, d) == True{} : Bool}:
  match d:
    case S.DmsIdle{}:
      and3_1(E.all_plasma(o, p, l, S.DmsIdle{}), E.all_plasma(o, p, l, S.DmsArmed{}), E.all_plasma(o, p, l, S.DmsFired{}), h)
    case S.DmsArmed{}:
      and3_2(E.all_plasma(o, p, l, S.DmsIdle{}), E.all_plasma(o, p, l, S.DmsArmed{}), E.all_plasma(o, p, l, S.DmsFired{}), h)
    case S.DmsFired{}:
      and3_3(E.all_plasma(o, p, l, S.DmsIdle{}), E.all_plasma(o, p, l, S.DmsArmed{}), E.all_plasma(o, p, l, S.DmsFired{}), h)

def lvl_plasma(+o: S.Ord, +p: S.Phase, +l: S.Level, +d: S.Dms, pl: Bool, h: {E.all_plasma(o, p, l, d) == True{} : Bool}) -> {E.all_nb(o, p, l, d, pl) == True{} : Bool}:
  match pl:
    case True{}:
      and_l(E.all_nb(o, p, l, d, True{}), E.all_nb(o, p, l, d, False{}), h)
    case False{}:
      and_r(E.all_nb(o, p, l, d, True{}), E.all_nb(o, p, l, d, False{}), h)

def lvl_nb(+o: S.Ord, +p: S.Phase, +l: S.Level, +d: S.Dms, +pl: Bool, nb: S.Heat, h: {E.all_nb(o, p, l, d, pl) == True{} : Bool}) -> {E.all_rf(o, p, l, d, pl, nb) == True{} : Bool}:
  match nb:
    case S.Off{}:
      and4_1(E.all_rf(o, p, l, d, pl, S.Off{}), E.all_rf(o, p, l, d, pl, S.Inhibited{}), E.all_rf(o, p, l, d, pl, S.Ramping{}), E.all_rf(o, p, l, d, pl, S.On{}), h)
    case S.Inhibited{}:
      and4_2(E.all_rf(o, p, l, d, pl, S.Off{}), E.all_rf(o, p, l, d, pl, S.Inhibited{}), E.all_rf(o, p, l, d, pl, S.Ramping{}), E.all_rf(o, p, l, d, pl, S.On{}), h)
    case S.Ramping{}:
      and4_3(E.all_rf(o, p, l, d, pl, S.Off{}), E.all_rf(o, p, l, d, pl, S.Inhibited{}), E.all_rf(o, p, l, d, pl, S.Ramping{}), E.all_rf(o, p, l, d, pl, S.On{}), h)
    case S.On{}:
      and4_4(E.all_rf(o, p, l, d, pl, S.Off{}), E.all_rf(o, p, l, d, pl, S.Inhibited{}), E.all_rf(o, p, l, d, pl, S.Ramping{}), E.all_rf(o, p, l, d, pl, S.On{}), h)

def lvl_rf(+o: S.Ord, +p: S.Phase, +l: S.Level, +d: S.Dms, +pl: Bool, +nb: S.Heat, rf: S.Heat, h: {E.all_rf(o, p, l, d, pl, nb) == True{} : Bool}) -> {E.all_ev(o, S.Fin{p, l, d, pl, nb, rf}) == True{} : Bool}:
  match rf:
    case S.Off{}:
      and4_1(E.all_ev(o, S.Fin{p, l, d, pl, nb, S.Off{}}), E.all_ev(o, S.Fin{p, l, d, pl, nb, S.Inhibited{}}), E.all_ev(o, S.Fin{p, l, d, pl, nb, S.Ramping{}}), E.all_ev(o, S.Fin{p, l, d, pl, nb, S.On{}}), h)
    case S.Inhibited{}:
      and4_2(E.all_ev(o, S.Fin{p, l, d, pl, nb, S.Off{}}), E.all_ev(o, S.Fin{p, l, d, pl, nb, S.Inhibited{}}), E.all_ev(o, S.Fin{p, l, d, pl, nb, S.Ramping{}}), E.all_ev(o, S.Fin{p, l, d, pl, nb, S.On{}}), h)
    case S.Ramping{}:
      and4_3(E.all_ev(o, S.Fin{p, l, d, pl, nb, S.Off{}}), E.all_ev(o, S.Fin{p, l, d, pl, nb, S.Inhibited{}}), E.all_ev(o, S.Fin{p, l, d, pl, nb, S.Ramping{}}), E.all_ev(o, S.Fin{p, l, d, pl, nb, S.On{}}), h)
    case S.On{}:
      and4_4(E.all_ev(o, S.Fin{p, l, d, pl, nb, S.Off{}}), E.all_ev(o, S.Fin{p, l, d, pl, nb, S.Inhibited{}}), E.all_ev(o, S.Fin{p, l, d, pl, nb, S.Ramping{}}), E.all_ev(o, S.Fin{p, l, d, pl, nb, S.On{}}), h)

# --- the twelve event groups: all_ev = and(q1, and(q2, q3)), each q a four-way split ---

def q1of(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_q1(o, f) == True{} : Bool}:
  and3_1(E.ev_q1(o, f), E.ev_q2(o, f), E.ev_q3(o, f), h)

def q2of(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_q2(o, f) == True{} : Bool}:
  and3_2(E.ev_q1(o, f), E.ev_q2(o, f), E.ev_q3(o, f), h)

def q3of(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_q3(o, f) == True{} : Bool}:
  and3_3(E.ev_q1(o, f), E.ev_q2(o, f), E.ev_q3(o, f), h)

def grp1(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g1(o, f) == True{} : Bool}:
  and4_1(E.ev_g1(o, f), E.ev_g2(o, f), E.ev_g3(o, f), E.ev_g4(o, f), q1of(o, f, h))

def grp2(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g2(o, f) == True{} : Bool}:
  and4_2(E.ev_g1(o, f), E.ev_g2(o, f), E.ev_g3(o, f), E.ev_g4(o, f), q1of(o, f, h))

def grp3(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g3(o, f) == True{} : Bool}:
  and4_3(E.ev_g1(o, f), E.ev_g2(o, f), E.ev_g3(o, f), E.ev_g4(o, f), q1of(o, f, h))

def grp4(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g4(o, f) == True{} : Bool}:
  and4_4(E.ev_g1(o, f), E.ev_g2(o, f), E.ev_g3(o, f), E.ev_g4(o, f), q1of(o, f, h))

def grp5(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g5(o, f) == True{} : Bool}:
  and4_1(E.ev_g5(o, f), E.ev_g6(o, f), E.ev_g7(o, f), E.ev_g8(o, f), q2of(o, f, h))

def grp6(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g6(o, f) == True{} : Bool}:
  and4_2(E.ev_g5(o, f), E.ev_g6(o, f), E.ev_g7(o, f), E.ev_g8(o, f), q2of(o, f, h))

def grp7(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g7(o, f) == True{} : Bool}:
  and4_3(E.ev_g5(o, f), E.ev_g6(o, f), E.ev_g7(o, f), E.ev_g8(o, f), q2of(o, f, h))

def grp8(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g8(o, f) == True{} : Bool}:
  and4_4(E.ev_g5(o, f), E.ev_g6(o, f), E.ev_g7(o, f), E.ev_g8(o, f), q2of(o, f, h))

def grp9(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g9(o, f) == True{} : Bool}:
  and4_1(E.ev_g9(o, f), E.ev_g10(o, f), E.ev_g11(o, f), E.ev_g12(o, f), q3of(o, f, h))

def grp10(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g10(o, f) == True{} : Bool}:
  and4_2(E.ev_g9(o, f), E.ev_g10(o, f), E.ev_g11(o, f), E.ev_g12(o, f), q3of(o, f, h))

def grp11(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g11(o, f) == True{} : Bool}:
  and4_3(E.ev_g9(o, f), E.ev_g10(o, f), E.ev_g11(o, f), E.ev_g12(o, f), q3of(o, f, h))

def grp12(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g12(o, f) == True{} : Bool}:
  and4_4(E.ev_g9(o, f), E.ev_g10(o, f), E.ev_g11(o, f), E.ev_g12(o, f), q3of(o, f, h))

# --- the verdicts, for the five events the certificate enumerates at all four pairs ---

def lvl_bt(+o: S.Ord, +f: S.Fin, +e: S.Ev, bt: Bool, h: {E.all_bt(o, f, e) == True{} : Bool}) -> {E.all_bh(o, f, e, bt) == True{} : Bool}:
  match bt:
    case True{}:
      and_l(E.all_bh(o, f, e, True{}), E.all_bh(o, f, e, False{}), h)
    case False{}:
      and_r(E.all_bh(o, f, e, True{}), E.all_bh(o, f, e, False{}), h)

def lvl_bh(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, bh: Bool, h: {E.all_bh(o, f, e, bt) == True{} : Bool}) -> {E.prop(o, f, e, bt, bh) == True{} : Bool}:
  match bh:
    case True{}:
      and_l(E.prop(o, f, e, bt, True{}), E.prop(o, f, e, bt, False{}), h)
    case False{}:
      and_r(E.prop(o, f, e, bt, True{}), E.prop(o, f, e, bt, False{}), h)

# the event level. For the nineteen columns certified once (E.one = prop at (True, True))
# the verdicts are erased by the reduction of the cell -- the counter commands of those
# events do not mention bt or bh -- so the same proof closes the goal at any (bt, bh).
def lvl_ev(+o: S.Ord, +f: S.Fin, e: S.Ev, +bt: Bool, +bh: Bool, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.prop(o, f, e, bt, bh) == True{} : Bool}:
  match e:
    case S.Advance{}:
      and_l(E.one(o, f, S.Advance{}), E.one(o, f, S.Heartbeat{}), grp1(o, f, h))
    case S.Stop{req, dms}:
      match req dms:
        case S.LNone{} True{}:
          and_l(E.one(o, f, S.Stop{S.LNone{}, True{}}), E.one(o, f, S.Stop{S.LNone{}, False{}}), grp9(o, f, h))
        case S.LNone{} False{}:
          and_r(E.one(o, f, S.Stop{S.LNone{}, True{}}), E.one(o, f, S.Stop{S.LNone{}, False{}}), grp9(o, f, h))
        case S.LJtt{} True{}:
          and_l(E.one(o, f, S.Stop{S.LJtt{}, True{}}), E.one(o, f, S.Stop{S.LJtt{}, False{}}), grp10(o, f, h))
        case S.LJtt{} False{}:
          and_r(E.one(o, f, S.Stop{S.LJtt{}, True{}}), E.one(o, f, S.Stop{S.LJtt{}, False{}}), grp10(o, f, h))
        case S.LRtps{} True{}:
          and_l(E.one(o, f, S.Stop{S.LRtps{}, True{}}), E.one(o, f, S.Stop{S.LRtps{}, False{}}), grp11(o, f, h))
        case S.LRtps{} False{}:
          and_r(E.one(o, f, S.Stop{S.LRtps{}, True{}}), E.one(o, f, S.Stop{S.LRtps{}, False{}}), grp11(o, f, h))
        case S.LPtn{} True{}:
          lvl_bh(o, f, S.Stop{S.LPtn{}, True{}}, bt, bh,
            lvl_bt(o, f, S.Stop{S.LPtn{}, True{}}, bt,
              and_l(E.all_bt(o, f, S.Stop{S.LPtn{}, True{}}), E.one(o, f, S.Stop{S.LPtn{}, False{}}), grp12(o, f, h))))
        case S.LPtn{} False{}:
          and_r(E.all_bt(o, f, S.Stop{S.LPtn{}, True{}}), E.one(o, f, S.Stop{S.LPtn{}, False{}}), grp12(o, f, h))
    case S.Local{u}:
      match u:
        case S.Nb{}:
          and_l(E.one(o, f, S.Local{S.Nb{}}), E.one(o, f, S.Local{S.Rf{}}), grp3(o, f, h))
        case S.Rf{}:
          and_r(E.one(o, f, S.Local{S.Nb{}}), E.one(o, f, S.Local{S.Rf{}}), grp3(o, f, h))
    case S.HeatOn{u}:
      match u:
        case S.Nb{}:
          and_l(E.one(o, f, S.HeatOn{S.Nb{}}), E.one(o, f, S.HeatOn{S.Rf{}}), grp4(o, f, h))
        case S.Rf{}:
          and_r(E.one(o, f, S.HeatOn{S.Nb{}}), E.one(o, f, S.HeatOn{S.Rf{}}), grp4(o, f, h))
    case S.HeatOff{u}:
      match u:
        case S.Nb{}:
          and_l(E.one(o, f, S.HeatOff{S.Nb{}}), E.one(o, f, S.HeatOff{S.Rf{}}), grp5(o, f, h))
        case S.Rf{}:
          and_r(E.one(o, f, S.HeatOff{S.Nb{}}), E.one(o, f, S.HeatOff{S.Rf{}}), grp5(o, f, h))
    case S.Plasma{ok}:
      match ok:
        case True{}:
          and_l(E.one(o, f, S.Plasma{True{}}), E.one(o, f, S.Plasma{False{}}), grp6(o, f, h))
        case False{}:
          and_r(E.one(o, f, S.Plasma{True{}}), E.one(o, f, S.Plasma{False{}}), grp6(o, f, h))
    case S.CommFault{dms}:
      match dms:
        case True{}:
          lvl_bh(o, f, S.CommFault{True{}}, bt, bh,
            lvl_bt(o, f, S.CommFault{True{}}, bt,
              and_l(E.all_bt(o, f, S.CommFault{True{}}), E.one(o, f, S.CommFault{False{}}), grp7(o, f, h))))
        case False{}:
          and_r(E.all_bt(o, f, S.CommFault{True{}}), E.one(o, f, S.CommFault{False{}}), grp7(o, f, h))
    case S.Heartbeat{}:
      and_r(E.one(o, f, S.Advance{}), E.one(o, f, S.Heartbeat{}), grp1(o, f, h))
    case S.Tick{dms}:
      match dms:
        case True{}:
          lvl_bh(o, f, S.Tick{True{}}, bt, bh,
            lvl_bt(o, f, S.Tick{True{}}, bt,
              and_l(E.all_bt(o, f, S.Tick{True{}}), E.all_bt(o, f, S.Tick{False{}}), grp8(o, f, h))))
        case False{}:
          lvl_bh(o, f, S.Tick{False{}}, bt, bh,
            lvl_bt(o, f, S.Tick{False{}}, bt,
              and_r(E.all_bt(o, f, S.Tick{True{}}), E.all_bt(o, f, S.Tick{False{}}), grp8(o, f, h))))
    case S.HeatAck{}:
      and_l(E.one(o, f, S.HeatAck{}), E.all_bt(o, f, S.Reset{}), grp2(o, f, h))
    case S.Reset{}:
      lvl_bh(o, f, S.Reset{}, bt, bh,
        lvl_bt(o, f, S.Reset{}, bt,
          and_r(E.one(o, f, S.HeatAck{}), E.all_bt(o, f, S.Reset{}), grp2(o, f, h))))

# every cell of the certificate holds, for either order
def cell(+o: S.Ord, f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.prop(o, f, e, bt, bh) == True{} : Bool}:
  match f:
    case S.Fin{+p, +l, +d, +pl, +nb, +rf}:
      +f2 = {S.Fin{p, l, d, pl, nb, rf} : S.Fin}
      lvl_ev(o, f2, e, bt, bh,
        lvl_rf(o, p, l, d, pl, nb, rf,
          lvl_nb(o, p, l, d, pl, nb,
            lvl_plasma(o, p, l, d, pl,
              lvl_dms(o, p, l, d, base(o, p, l))))))

# ---------------------------------------------------------------------------
# The conjuncts of a cell: prop_at = and(g_pres, and(g_a, and(g_b, g_c)))
# ---------------------------------------------------------------------------

# the last three groups of prop_at, as one Bool (so the projections stay four-way)
def gde(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(E.g_d(o, f, e, bt, bh, f2), E.g_e(o, f, e, bt, bh, f2))

def gcd(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(E.g_c(f, e, bt, bh, f2), gde(o, f, e, bt, bh, f2))

def c_pres(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_pres(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(E.g_pres(f, e, bt, bh, f2), Bool.and(E.g_a(o, f, e, f2), Bool.and(E.g_b(f, e, bt, bh, f2), gcd(o, f, e, bt, bh, f2))), cell(o, f, e, bt, bh))

def c_a(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_a(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and3_1(E.g_a(o, f, e, f2), E.g_b(f, e, bt, bh, f2), gcd(o, f, e, bt, bh, f2),
    and_r(E.g_pres(f, e, bt, bh, f2), Bool.and(E.g_a(o, f, e, f2), Bool.and(E.g_b(f, e, bt, bh, f2), gcd(o, f, e, bt, bh, f2))), cell(o, f, e, bt, bh)))

def c_b(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_b(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and3_2(E.g_a(o, f, e, f2), E.g_b(f, e, bt, bh, f2), gcd(o, f, e, bt, bh, f2),
    and_r(E.g_pres(f, e, bt, bh, f2), Bool.and(E.g_a(o, f, e, f2), Bool.and(E.g_b(f, e, bt, bh, f2), gcd(o, f, e, bt, bh, f2))), cell(o, f, e, bt, bh)))

def c_cd(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {gcd(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and3_3(E.g_a(o, f, e, f2), E.g_b(f, e, bt, bh, f2), gcd(o, f, e, bt, bh, f2),
    and_r(E.g_pres(f, e, bt, bh, f2), Bool.and(E.g_a(o, f, e, f2), Bool.and(E.g_b(f, e, bt, bh, f2), gcd(o, f, e, bt, bh, f2))), cell(o, f, e, bt, bh)))

def c_c(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_c(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(E.g_c(f, e, bt, bh, f2), gde(o, f, e, bt, bh, f2), c_cd(o, f, e, bt, bh))

def c_de(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {gde(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(E.g_c(f, e, bt, bh, f2), gde(o, f, e, bt, bh, f2), c_cd(o, f, e, bt, bh))

def c_d(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_d(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(E.g_d(o, f, e, bt, bh, f2), E.g_e(o, f, e, bt, bh, f2), c_de(o, f, e, bt, bh))

def c_e(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_e(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(E.g_d(o, f, e, bt, bh, f2), E.g_e(o, f, e, bt, bh, f2), c_de(o, f, e, bt, bh))

# g_pres = and(pr_pres, and(pr_hb, pr_tack))
def cp_pres(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_pres(f, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and3_1(Spec.pr_pres(f, f2), Spec.pr_hb(f, e, bh, f2), Spec.pr_tack(f, e, bt, bh, f2), c_pres(o, f, e, bt, bh))

def cp_hb(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_hb(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and3_2(Spec.pr_pres(f, f2), Spec.pr_hb(f, e, bh, f2), Spec.pr_tack(f, e, bt, bh, f2), c_pres(o, f, e, bt, bh))

def cp_tack(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_tack(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and3_3(Spec.pr_pres(f, f2), Spec.pr_hb(f, e, bh, f2), Spec.pr_tack(f, e, bt, bh, f2), c_pres(o, f, e, bt, bh))

# g_a = and(p1, and(p2, and(p3, p4)))
def ta3(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p3(f, f2), Spec.pr_p4(f, e, f2))

def ta2(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p2(f, f2), ta3(f, e, f2))

def cp1(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p1(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p1(o, f, e, f2), ta2(f, e, f2), c_a(o, f, e, bt, bh))

def cp2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p2(f, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p2(f, f2), ta3(f, e, f2), and_r(Spec.pr_p1(o, f, e, f2), ta2(f, e, f2), c_a(o, f, e, bt, bh)))

def cp3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p3(f, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p3(f, f2), Spec.pr_p4(f, e, f2), and_r(Spec.pr_p2(f, f2), ta3(f, e, f2), and_r(Spec.pr_p1(o, f, e, f2), ta2(f, e, f2), c_a(o, f, e, bt, bh))))

def cp4(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p4(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p3(f, f2), Spec.pr_p4(f, e, f2), and_r(Spec.pr_p2(f, f2), ta3(f, e, f2), and_r(Spec.pr_p1(o, f, e, f2), ta2(f, e, f2), c_a(o, f, e, bt, bh))))

# g_b = and(p5, and(p6, and(p7, and(p8, p9))))
def tb4(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p8(f, e, f2), Spec.pr_p9(f, e, bt, bh, f2))

def tb3(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p7(f, e, f2), tb4(f, e, bt, bh, f2))

def tb2(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p6(f, f2), tb3(f, e, bt, bh, f2))

def cp5(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p5(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p5(f, e, f2), tb2(f, e, bt, bh, f2), c_b(o, f, e, bt, bh))

def cp6(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p6(f, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p6(f, f2), tb3(f, e, bt, bh, f2), and_r(Spec.pr_p5(f, e, f2), tb2(f, e, bt, bh, f2), c_b(o, f, e, bt, bh)))

def cp7(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p7(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p7(f, e, f2), tb4(f, e, bt, bh, f2), and_r(Spec.pr_p6(f, f2), tb3(f, e, bt, bh, f2), and_r(Spec.pr_p5(f, e, f2), tb2(f, e, bt, bh, f2), c_b(o, f, e, bt, bh))))

def cp8(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p8(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p8(f, e, f2), Spec.pr_p9(f, e, bt, bh, f2), and_r(Spec.pr_p7(f, e, f2), tb4(f, e, bt, bh, f2), and_r(Spec.pr_p6(f, f2), tb3(f, e, bt, bh, f2), and_r(Spec.pr_p5(f, e, f2), tb2(f, e, bt, bh, f2), c_b(o, f, e, bt, bh)))))

def cp9(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p9(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p8(f, e, f2), Spec.pr_p9(f, e, bt, bh, f2), and_r(Spec.pr_p7(f, e, f2), tb4(f, e, bt, bh, f2), and_r(Spec.pr_p6(f, f2), tb3(f, e, bt, bh, f2), and_r(Spec.pr_p5(f, e, f2), tb2(f, e, bt, bh, f2), c_b(o, f, e, bt, bh)))))

# g_c = and(p10, and(p12, and(p14, and(p15, and(p16, and(p17, and(p18, and(p19, and(p20, p21)))))))))
def tc9(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p20(f, e, bt, bh, f2), Spec.pr_p21(f, e, bt, bh, f2))

def tc8(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p19(f, e, bt, bh, f2), tc9(f, e, bt, bh, f2))

def tc7(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p18(f, e, bt, bh), tc8(f, e, bt, bh, f2))

def tc6(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p17(f, e, bh, f2), tc7(f, e, bt, bh, f2))

def tc5(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p16(f, e, bh, f2), tc6(f, e, bt, bh, f2))

def tc4(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p15(f, e, f2), tc5(f, e, bt, bh, f2))

def tc3(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p14(f, e, f2), tc4(f, e, bt, bh, f2))

def tc2(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p12(e, f2), tc3(f, e, bt, bh, f2))

# the successive tails of g_c as facts
def cc2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tc2(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p10(f, e, bh, f2), tc2(f, e, bt, bh, f2), c_c(o, f, e, bt, bh))

def cc3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tc3(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p12(e, f2), tc3(f, e, bt, bh, f2), cc2(o, f, e, bt, bh))

def cc4(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tc4(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p14(f, e, f2), tc4(f, e, bt, bh, f2), cc3(o, f, e, bt, bh))

def cc5(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tc5(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p15(f, e, f2), tc5(f, e, bt, bh, f2), cc4(o, f, e, bt, bh))

def cc6(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tc6(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p16(f, e, bh, f2), tc6(f, e, bt, bh, f2), cc5(o, f, e, bt, bh))

def cc7(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tc7(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p17(f, e, bh, f2), tc7(f, e, bt, bh, f2), cc6(o, f, e, bt, bh))

def cc8(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tc8(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p18(f, e, bt, bh), tc8(f, e, bt, bh, f2), cc7(o, f, e, bt, bh))

def cp10(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p10(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p10(f, e, bh, f2), tc2(f, e, bt, bh, f2), c_c(o, f, e, bt, bh))

def cp12(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p12(e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p12(e, f2), tc3(f, e, bt, bh, f2), cc2(o, f, e, bt, bh))

def cp14(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p14(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p14(f, e, f2), tc4(f, e, bt, bh, f2), cc3(o, f, e, bt, bh))

def cp15(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p15(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p15(f, e, f2), tc5(f, e, bt, bh, f2), cc4(o, f, e, bt, bh))

def cp16(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p16(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p16(f, e, bh, f2), tc6(f, e, bt, bh, f2), cc5(o, f, e, bt, bh))

def cp17(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p17(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p17(f, e, bh, f2), tc7(f, e, bt, bh, f2), cc6(o, f, e, bt, bh))

def cp18(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p18(f, e, bt, bh) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p18(f, e, bt, bh), tc8(f, e, bt, bh, f2), cc7(o, f, e, bt, bh))

def cp19(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p19(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p19(f, e, bt, bh, f2), tc9(f, e, bt, bh, f2), cc8(o, f, e, bt, bh))

def cc9(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tc9(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p19(f, e, bt, bh, f2), tc9(f, e, bt, bh, f2), cc8(o, f, e, bt, bh))

def cp20(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p20(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p20(f, e, bt, bh, f2), Spec.pr_p21(f, e, bt, bh, f2), cc9(o, f, e, bt, bh))

def cp21(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p21(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p20(f, e, bt, bh, f2), Spec.pr_p21(f, e, bt, bh, f2), cc9(o, f, e, bt, bh))

# ---------------------------------------------------------------------------
# The demand and frame conjuncts: g_d = and(pr_d1, and(pr_d2, ... and(pr_d17, pr_d18)...))
# ---------------------------------------------------------------------------

# g_d = and(pr_d1, and(pr_d2, ... and(pr_d17, pr_d18)...)): the tails as named Bools
def td17(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d17(f, e, bt, bh, f2), Spec.pr_d18(f, e, bt, bh, f2))

def td16(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d16(f, e, bt, bh, f2), td17(f, e, bt, bh, f2))

def td15(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d15(f, e, bt, bh, f2), td16(f, e, bt, bh, f2))

def td14(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d14(f, e, f2), td15(f, e, bt, bh, f2))

def td13(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d13(e, f2), td14(f, e, bt, bh, f2))

def td12(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d12(f, e, f2), td13(f, e, bt, bh, f2))

def td11(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d11(f, e, f2), td12(f, e, bt, bh, f2))

def td10(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d10(f, e, bt, bh, f2), td11(f, e, bt, bh, f2))

def td9(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d9(f, e, f2), td10(f, e, bt, bh, f2))

def td8(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d8(f, e, bt, bh), td9(f, e, bt, bh, f2))

def td7(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d7(f, e, bt, f2), td8(f, e, bt, bh, f2))

def td6(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d6(f, e, bh), td7(f, e, bt, bh, f2))

def td5(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d5(f, e, bh), td6(f, e, bt, bh, f2))

def td4(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d4(f, e, bh, f2), td5(f, e, bt, bh, f2))

def td3(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d3(f, e, f2), td4(f, e, bt, bh, f2))

def td2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d2(o, f, e, f2), td3(f, e, bt, bh, f2))

# the successive tails of g_d as facts
def cd2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td2(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d1(o, f, e, f2), td2(o, f, e, bt, bh, f2), c_d(o, f, e, bt, bh))

def cd3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td3(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d2(o, f, e, f2), td3(f, e, bt, bh, f2), cd2(o, f, e, bt, bh))

def cd4(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td4(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d3(f, e, f2), td4(f, e, bt, bh, f2), cd3(o, f, e, bt, bh))

def cd5(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td5(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d4(f, e, bh, f2), td5(f, e, bt, bh, f2), cd4(o, f, e, bt, bh))

def cd6(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td6(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d5(f, e, bh), td6(f, e, bt, bh, f2), cd5(o, f, e, bt, bh))

def cd7(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td7(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d6(f, e, bh), td7(f, e, bt, bh, f2), cd6(o, f, e, bt, bh))

def cd8(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td8(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d7(f, e, bt, f2), td8(f, e, bt, bh, f2), cd7(o, f, e, bt, bh))

def cd9(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td9(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d8(f, e, bt, bh), td9(f, e, bt, bh, f2), cd8(o, f, e, bt, bh))

def cd10(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td10(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d9(f, e, f2), td10(f, e, bt, bh, f2), cd9(o, f, e, bt, bh))

def cd11(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td11(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d10(f, e, bt, bh, f2), td11(f, e, bt, bh, f2), cd10(o, f, e, bt, bh))

def cd12(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td12(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d11(f, e, f2), td12(f, e, bt, bh, f2), cd11(o, f, e, bt, bh))

def cd13(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td13(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d12(f, e, f2), td13(f, e, bt, bh, f2), cd12(o, f, e, bt, bh))

def cd14(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td14(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d13(e, f2), td14(f, e, bt, bh, f2), cd13(o, f, e, bt, bh))

def cd15(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td15(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d14(f, e, f2), td15(f, e, bt, bh, f2), cd14(o, f, e, bt, bh))

def cd16(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td16(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d15(f, e, bt, bh, f2), td16(f, e, bt, bh, f2), cd15(o, f, e, bt, bh))

def cd17(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {td17(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d16(f, e, bt, bh, f2), td17(f, e, bt, bh, f2), cd16(o, f, e, bt, bh))

# the eighteen demand and frame properties of one cell
def cp_d1(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d1(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d1(o, f, e, f2), td2(o, f, e, bt, bh, f2), c_d(o, f, e, bt, bh))

def cp_d2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d2(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d2(o, f, e, f2), td3(f, e, bt, bh, f2), cd2(o, f, e, bt, bh))

def cp_d3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d3(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d3(f, e, f2), td4(f, e, bt, bh, f2), cd3(o, f, e, bt, bh))

def cp_d4(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d4(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d4(f, e, bh, f2), td5(f, e, bt, bh, f2), cd4(o, f, e, bt, bh))

def cp_d5(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d5(f, e, bh) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d5(f, e, bh), td6(f, e, bt, bh, f2), cd5(o, f, e, bt, bh))

def cp_d6(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d6(f, e, bh) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d6(f, e, bh), td7(f, e, bt, bh, f2), cd6(o, f, e, bt, bh))

def cp_d7(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d7(f, e, bt, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d7(f, e, bt, f2), td8(f, e, bt, bh, f2), cd7(o, f, e, bt, bh))

def cp_d8(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d8(f, e, bt, bh) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d8(f, e, bt, bh), td9(f, e, bt, bh, f2), cd8(o, f, e, bt, bh))

def cp_d9(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d9(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d9(f, e, f2), td10(f, e, bt, bh, f2), cd9(o, f, e, bt, bh))

def cp_d10(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d10(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d10(f, e, bt, bh, f2), td11(f, e, bt, bh, f2), cd10(o, f, e, bt, bh))

def cp_d11(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d11(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d11(f, e, f2), td12(f, e, bt, bh, f2), cd11(o, f, e, bt, bh))

def cp_d12(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d12(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d12(f, e, f2), td13(f, e, bt, bh, f2), cd12(o, f, e, bt, bh))

def cp_d13(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d13(e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d13(e, f2), td14(f, e, bt, bh, f2), cd13(o, f, e, bt, bh))

def cp_d14(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d14(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d14(f, e, f2), td15(f, e, bt, bh, f2), cd14(o, f, e, bt, bh))

def cp_d15(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d15(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d15(f, e, bt, bh, f2), td16(f, e, bt, bh, f2), cd15(o, f, e, bt, bh))

def cp_d16(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d16(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d16(f, e, bt, bh, f2), td17(f, e, bt, bh, f2), cd16(o, f, e, bt, bh))

def cp_d17(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d17(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d17(f, e, bt, bh, f2), Spec.pr_d18(f, e, bt, bh, f2), cd17(o, f, e, bt, bh))

def cp_d18(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d18(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d17(f, e, bt, bh, f2), Spec.pr_d18(f, e, bt, bh, f2), cd17(o, f, e, bt, bh))

# ---------------------------------------------------------------------------
# The E conjuncts: g_e = and(pr_e1, and(pr_e2, ... and(pr_e8, pr_e11)...))
# ---------------------------------------------------------------------------

def te8(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_e8(f, e, bt, bh), Spec.pr_e11(f, e, f2))

def te7(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_e7(f, e, bt, bh), te8(f, e, bt, bh, f2))

def te6(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_e6(f, e, bh), te7(f, e, bt, bh, f2))

def te5(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_e5(f, e, bh), te6(f, e, bt, bh, f2))

def te4(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_e4(f, e, f2), te5(f, e, bt, bh, f2))

def te3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_e3(o, f, e, f2), te4(f, e, bt, bh, f2))

def te2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_e2(f, e, bt, f2), te3(o, f, e, bt, bh, f2))

# the successive tails of g_e as facts
def ce2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {te2(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_e1(f, e, f2), te2(o, f, e, bt, bh, f2), c_e(o, f, e, bt, bh))

def ce3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {te3(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_e2(f, e, bt, f2), te3(o, f, e, bt, bh, f2), ce2(o, f, e, bt, bh))

def ce4(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {te4(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_e3(o, f, e, f2), te4(f, e, bt, bh, f2), ce3(o, f, e, bt, bh))

def ce5(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {te5(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_e4(f, e, f2), te5(f, e, bt, bh, f2), ce4(o, f, e, bt, bh))

def ce6(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {te6(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_e5(f, e, bh), te6(f, e, bt, bh, f2), ce5(o, f, e, bt, bh))

def ce7(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {te7(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_e6(f, e, bh), te7(f, e, bt, bh, f2), ce6(o, f, e, bt, bh))

def ce8(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {te8(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_e7(f, e, bt, bh), te8(f, e, bt, bh, f2), ce7(o, f, e, bt, bh))

# the nine E properties of one cell
def cp_e1(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_e1(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_e1(f, e, f2), te2(o, f, e, bt, bh, f2), c_e(o, f, e, bt, bh))

def cp_e2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_e2(f, e, bt, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_e2(f, e, bt, f2), te3(o, f, e, bt, bh, f2), ce2(o, f, e, bt, bh))

def cp_e3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_e3(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_e3(o, f, e, f2), te4(f, e, bt, bh, f2), ce3(o, f, e, bt, bh))

def cp_e4(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_e4(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_e4(f, e, f2), te5(f, e, bt, bh, f2), ce4(o, f, e, bt, bh))

def cp_e5(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_e5(f, e, bh) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_e5(f, e, bh), te6(f, e, bt, bh, f2), ce5(o, f, e, bt, bh))

def cp_e6(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_e6(f, e, bh) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_e6(f, e, bh), te7(f, e, bt, bh, f2), ce6(o, f, e, bt, bh))

def cp_e7(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_e7(f, e, bt, bh) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_e7(f, e, bt, bh), te8(f, e, bt, bh, f2), ce7(o, f, e, bt, bh))

def cp_e8(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_e8(f, e, bt, bh) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_e8(f, e, bt, bh), Spec.pr_e11(f, e, f2), ce8(o, f, e, bt, bh))

def cp_e11(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_e11(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_e8(f, e, bt, bh), Spec.pr_e11(f, e, f2), ce8(o, f, e, bt, bh))

# ---------------------------------------------------------------------------
# From a cell to the counter bound: a Reset restarts at 0, a Keep inherits the old
# bound, an Inc was allowed by the verdict
# ---------------------------------------------------------------------------

def cnt_of_shape(fl: Bool, u: S.Upd, was: Bool, v: Bool, -n: Nat, -lim: Nat,
                 hs: {S.implies(fl, Spec.shape_ok(u, was, v)) == True{} : Bool},
                 hv: {Nat.is_lt(1n+n, lim) == v : Bool},
                 hz: {Nat.is_lt(0n, lim) == True{} : Bool},
                 hold: {S.cnt_go(was, n, lim) == True{} : Bool}) -> {S.cnt_go(fl, S.apply(u, n), lim) == True{} : Bool}:
  match fl:
    case False{}:
      {==}
    case True{}:
      match u:
        case S.CReset{}:
          hz
        case S.CKeep{}:
          match was:
            case True{}:
              hold
            case False{}:
              clash_ft({S.cnt_go(True{}, S.apply(S.CKeep{}, n), lim) == True{} : Bool}, hs)
        case S.CInc{}:
          match v:
            case True{}:
              hv
            case False{}:
              clash_ft({S.cnt_go(True{}, S.apply(S.CInc{}, n), lim) == True{} : Bool}, hs)

# ---------------------------------------------------------------------------
# The invariant laws
# ---------------------------------------------------------------------------

def Laws.inv_init():
  {==}

def Laws.pres_fin(o, s, h, e):
  match s:
    case S.St{+f, +hb, +tack}:
      +bt = Nat.is_lt(1n+tack, S.ack_max())
      +bh = Nat.is_lt(1n+hb, S.hb_max())
      implies_e(S.inv_fin(f), S.inv_fin(S.step_fin(o, f, e, bt, bh)), cp_pres(o, f, e, bt, bh),
        and_l(S.inv_fin(f), Bool.and(S.i5_ack(S.St{f, hb, tack}), S.i6_hb(S.St{f, hb, tack})), h))

def Laws.pres_i5(o, s, h, e):
  match s:
    case S.St{+f, +hb, +tack}:
      +bt = Nat.is_lt(1n+tack, S.ack_max())
      +bh = Nat.is_lt(1n+hb, S.hb_max())
      cnt_of_shape(Spec.tack_running(S.step_fin(o, f, e, bt, bh)), S.upd_tack(f, e, bt, bh), Spec.tack_running(f), bt, tack, S.ack_max(),
        cp_tack(o, f, e, bt, bh), {==}, {==},
        and_l(S.i5_ack(S.St{f, hb, tack}), S.i6_hb(S.St{f, hb, tack}),
          and_r(S.inv_fin(f), Bool.and(S.i5_ack(S.St{f, hb, tack}), S.i6_hb(S.St{f, hb, tack})), h)))

def Laws.pres_i6(o, s, h, e):
  match s:
    case S.St{+f, +hb, +tack}:
      +bt = Nat.is_lt(1n+tack, S.ack_max())
      +bh = Nat.is_lt(1n+hb, S.hb_max())
      cnt_of_shape(Spec.hb_running(S.step_fin(o, f, e, bt, bh)), S.upd_hb(f, e, bh), Spec.hb_running(f), bh, hb, S.hb_max(),
        cp_hb(o, f, e, bt, bh), {==}, {==},
        and_r(S.i5_ack(S.St{f, hb, tack}), S.i6_hb(S.St{f, hb, tack}),
          and_r(S.inv_fin(f), Bool.and(S.i5_ack(S.St{f, hb, tack}), S.i6_hb(S.St{f, hb, tack})), h)))

# one safe step: the three preservation laws, rebuilt as inv_all
def step_safe(+o: S.Ord, +s: S.St, +hall: {S.inv_all(s) == True{} : Bool}, +e: S.Ev) -> {S.inv_all(S.step_o(o, s, e)) == True{} : Bool}:
  and_intro(S.inv_fin(S.fin_of(S.step_o(o, s, e))), Bool.and(S.i5_ack(S.step_o(o, s, e)), S.i6_hb(S.step_o(o, s, e))), Laws.pres_fin(o, s, hall, e),
    and_intro(S.i5_ack(S.step_o(o, s, e)), S.i6_hb(S.step_o(o, s, e)), Laws.pres_i5(o, s, hall, e), Laws.pres_i6(o, s, hall, e)))

# induction on the trace, generalized to any safe start state
def run_safe(trace: List<&2, S.Ev>, +o: S.Ord, +s: S.St, +hall: {S.inv_all(s) == True{} : Bool}) -> {S.inv_all(S.run_o(o, trace, s)) == True{} : Bool}:
  match trace:
    case Nil{}:
      hall
    case Con{+e, t}:
      run_safe(t, o, S.step_o(o, s, e), step_safe(o, s, hall, e))

def Laws.traces_safe(o, trace):
  run_safe(trace, o, S.init(), Laws.inv_init())

# the concrete alphabet: a concrete step is an abstract step under Ord1 on the concretized event
def step_c_safe(+i: S.Inst, +s: S.St, +hall: {S.inv_all(s) == True{} : Bool}, +c: S.CEv) -> {S.inv_all(S.step_c(i, s, c)) == True{} : Bool}:
  step_safe(S.Ord1{}, s, hall, S.concretize(i, S.phase_of(S.fin_of(s)), c))

def run_c_safe(trace: List<&2, S.CEv>, +i: S.Inst, +s: S.St, +hall: {S.inv_all(s) == True{} : Bool}) -> {S.inv_all(S.run_c(i, trace, s)) == True{} : Bool}:
  match trace:
    case Nil{}:
      hall
    case Con{+c, t}:
      run_c_safe(t, i, S.step_c(i, s, c), step_c_safe(i, s, hall, c))

def Laws.traces_safe_concrete(i, trace):
  run_c_safe(trace, i, S.init(), Laws.inv_init())

# ---------------------------------------------------------------------------
# The step laws: one cell projection each
# ---------------------------------------------------------------------------

def Laws.latched(o, f, e, bt, bh):
  cp1(o, f, e, bt, bh)

def Laws.ptn_deenergizes(o, f, e, bt, bh):
  cp2(o, f, e, bt, bh)

def Laws.stop_reduces_power(o, f, e, bt, bh):
  cp3(o, f, e, bt, bh)

def Laws.ramping_never_returns(o, f, e, bt, bh):
  cp4(o, f, e, bt, bh)

def Laws.heat_permissive(o, f, e, bt, bh):
  cp5(o, f, e, bt, bh)

def Laws.stop_overrides_heat(o, f, e, bt, bh):
  cp6(o, f, e, bt, bh)

def Laws.heat_frame(o, f, e, bt, bh):
  cp7(o, f, e, bt, bh)

def Laws.inhibit_latched(o, f, e, bt, bh):
  cp8(o, f, e, bt, bh)

def Laws.local_is_local(o, f, e, bt, bh):
  cp9(o, f, e, bt, bh)

def Laws.no_spurious_stop(o, f, e, bt, bh):
  cp10(o, f, e, bt, bh)

def Laws.commfault_ptn(o, f, e, bt, bh):
  cp12(o, f, e, bt, bh)

def Laws.phase_monotone(o, f, e, bt, bh):
  cp14(o, f, e, bt, bh)

def Laws.dms_monotone(o, f, e, bt, bh):
  cp15(o, f, e, bt, bh)

def Laws.dms_armed_on_demand(o, f, e, bt, bh):
  cp16(o, f, e, bt, bh)

def Laws.dms_frame(o, f, e, bt, bh):
  cp17(o, f, e, bt, bh)

def Laws.tack_frame(o, f, e, bt, bh):
  cp18(o, f, e, bt, bh)

def Laws.advance_frozen(o, f, e, bt, bh):
  cp19(o, f, e, bt, bh)

def Laws.reset_guarded(o, f, e, bt, bh):
  cp20(o, f, e, bt, bh)

def Laws.reset_refused_mid_pulse(o, f, e, bt, bh):
  cp21(o, f, e, bt, bh)

# the demand and frame laws D1..D18
def Laws.d1_stop_honoured(o, f, e, bt, bh):
  cp_d1(o, f, e, bt, bh)

def Laws.d2_soft_stop_ramps(o, f, e, bt, bh):
  cp_d2(o, f, e, bt, bh)

def Laws.d3_advance_to_termination_ramps(o, f, e, bt, bh):
  cp_d3(o, f, e, bt, bh)

def Laws.d4_watchdog_latches(o, f, e, bt, bh):
  cp_d4(o, f, e, bt, bh)

def Laws.d5_hb_counts(o, f, e, bt, bh):
  cp_d5(o, f, e, bt, bh)

def Laws.d6_hb_frame(o, f, e, bt, bh):
  cp_d6(o, f, e, bt, bh)

def Laws.d7_ack_timeout_fires(o, f, e, bt, bh):
  cp_d7(o, f, e, bt, bh)

def Laws.d8_ack_counts(o, f, e, bt, bh):
  cp_d8(o, f, e, bt, bh)

def Laws.d9_heatack_fires(o, f, e, bt, bh):
  cp_d9(o, f, e, bt, bh)

def Laws.d10_reset_accepted_when_safe(o, f, e, bt, bh):
  cp_d10(o, f, e, bt, bh)

def Laws.d11_advance_is_one_step(o, f, e, bt, bh):
  cp_d11(o, f, e, bt, bh)

def Laws.d12_phase_frame(o, f, e, bt, bh):
  cp_d12(o, f, e, bt, bh)

def Laws.d13_plasma_is_input(o, f, e, bt, bh):
  cp_d13(o, f, e, bt, bh)

def Laws.d14_plasma_frame(o, f, e, bt, bh):
  cp_d14(o, f, e, bt, bh)

def Laws.d15_heatoff_is_local(o, f, e, bt, bh):
  cp_d15(o, f, e, bt, bh)

def Laws.d16_heaton_is_local(o, f, e, bt, bh):
  cp_d16(o, f, e, bt, bh)

def Laws.d17_heatack_frame(o, f, e, bt, bh):
  cp_d17(o, f, e, bt, bh)

def Laws.d18_heartbeat_frame(o, f, e, bt, bh):
  cp_d18(o, f, e, bt, bh)

# the remaining demand and frame laws E1..E11
def Laws.e1_inhibit_source(o, f, e, bt, bh):
  cp_e1(o, f, e, bt, bh)

def Laws.e2_dms_fire_frame(o, f, e, bt, bh):
  cp_e2(o, f, e, bt, bh)

def Laws.e3_stop_phase_exact(o, f, e, bt, bh):
  cp_e3(o, f, e, bt, bh)

def Laws.e4_advance_units(o, f, e, bt, bh):
  cp_e4(o, f, e, bt, bh)

def Laws.e5_heartbeat_resets_hb(o, f, e, bt, bh):
  cp_e5(o, f, e, bt, bh)

def Laws.e6_hb_tick_exact(o, f, e, bt, bh):
  cp_e6(o, f, e, bt, bh)

def Laws.e7_tack_inc_frame(o, f, e, bt, bh):
  cp_e7(o, f, e, bt, bh)

def Laws.e8_tack_reset_frame(o, f, e, bt, bh):
  cp_e8(o, f, e, bt, bh)

def Laws.e11_heatack_exact(o, f, e, bt, bh):
  cp_e11(o, f, e, bt, bh)

# ---------------------------------------------------------------------------
# V1: the verdict domain. Outside the Tick arm, step_fin, upd_hb and upd_tack do not read
# the verdicts at all -- each of the ten remaining event constructors selects a branch that
# never mentions bt or bh, so the two sides are the same normal form and {==} closes it.
# The Tick case is refuted by the hypothesis is_tick(e) == False.
# ---------------------------------------------------------------------------

def Laws.verdict_frame_step(o, f, e, h, bt, bh):
  match e:
    case S.Advance{}:
      {==}
    case S.Stop{req, dms}:
      {==}
    case S.Local{u}:
      {==}
    case S.HeatOn{u}:
      {==}
    case S.HeatOff{u}:
      {==}
    case S.Plasma{ok}:
      {==}
    case S.CommFault{dms}:
      {==}
    case S.Heartbeat{}:
      {==}
    case S.Tick{dms}:
      clash_tf({S.step_fin(o, f, S.Tick{dms}, bt, bh) == S.step_fin(o, f, S.Tick{dms}, True{}, True{}) : S.Fin}, h)
    case S.HeatAck{}:
      {==}
    case S.Reset{}:
      {==}

def Laws.verdict_frame_hb(o, f, e, h, bt, bh):
  match e:
    case S.Advance{}:
      {==}
    case S.Stop{req, dms}:
      {==}
    case S.Local{u}:
      {==}
    case S.HeatOn{u}:
      {==}
    case S.HeatOff{u}:
      {==}
    case S.Plasma{ok}:
      {==}
    case S.CommFault{dms}:
      {==}
    case S.Heartbeat{}:
      {==}
    case S.Tick{dms}:
      clash_tf({S.upd_hb(f, S.Tick{dms}, bh) == S.upd_hb(f, S.Tick{dms}, True{}) : S.Upd}, h)
    case S.HeatAck{}:
      {==}
    case S.Reset{}:
      {==}

def Laws.verdict_frame_tack(o, f, e, h, bt, bh):
  match e:
    case S.Advance{}:
      {==}
    case S.Stop{req, dms}:
      {==}
    case S.Local{u}:
      {==}
    case S.HeatOn{u}:
      {==}
    case S.HeatOff{u}:
      {==}
    case S.Plasma{ok}:
      {==}
    case S.CommFault{dms}:
      {==}
    case S.Heartbeat{}:
      {==}
    case S.Tick{dms}:
      clash_tf({S.upd_tack(f, S.Tick{dms}, bt, bh) == S.upd_tack(f, S.Tick{dms}, True{}, True{}) : S.Upd}, h)
    case S.HeatAck{}:
      {==}
    case S.Reset{}:
      {==}

# ---------------------------------------------------------------------------
# P20 on states: the Reset step, with the guard as a Bool parameter
# ---------------------------------------------------------------------------

def reset_acc_go(b: Bool, +f: S.Fin, -hb: Nat, -tack: Nat, h: {b == True{} : Bool}) -> {S.St{S.reset_go(b, f), S.apply(S.reset_if(b), hb), S.apply(S.reset_if(b), tack)} == S.init() : S.St}:
  match b:
    case True{}:
      {==}
    case False{}:
      clash_ft({S.St{S.reset_go(False{}, f), S.apply(S.reset_if(False{}), hb), S.apply(S.reset_if(False{}), tack)} == S.init() : S.St}, h)

def reset_ref_go(b: Bool, +f: S.Fin, -hb: Nat, -tack: Nat, h: {b == False{} : Bool}) -> {S.St{S.reset_go(b, f), S.apply(S.reset_if(b), hb), S.apply(S.reset_if(b), tack)} == S.St{f, hb, tack} : S.St}:
  match b:
    case True{}:
      clash_tf({S.St{S.reset_go(True{}, f), S.apply(S.reset_if(True{}), hb), S.apply(S.reset_if(True{}), tack)} == S.St{f, hb, tack} : S.St}, h)
    case False{}:
      {==}

def Laws.reset_accepted(o, s, h):
  match s:
    case S.St{+f, +hb, +tack}:
      reset_acc_go(S.reset_ok(f), f, hb, tack, h)

def Laws.reset_refused(o, s, h):
  match s:
    case S.St{+f, +hb, +tack}:
      reset_ref_go(S.reset_ok(f), f, hb, tack, h)

# ---------------------------------------------------------------------------
# The state corollaries: from check_cor() == True down to one control state
# ---------------------------------------------------------------------------

def kf6() -> Bool:
  Bool.and(E.cor_level(S.Heating2{}), E.cor_level(S.Termination{}))

def kf5() -> Bool:
  Bool.and(E.cor_level(S.Heating1{}), kf6())

def kf4() -> Bool:
  Bool.and(E.cor_level(S.Xpoint{}), kf5())

def kf3() -> Bool:
  Bool.and(E.cor_level(S.Limiter{}), kf4())

def kf2() -> Bool:
  Bool.and(E.cor_level(S.IpRise{}), kf3())

def cor_phase(p: S.Phase, h: {E.check_cor() == True{} : Bool}) -> {E.cor_level(p) == True{} : Bool}:
  match p:
    case S.Breakdown{}:
      and_l(E.cor_level(S.Breakdown{}), kf2(), h)
    case S.IpRise{}:
      and_l(E.cor_level(S.IpRise{}), kf3(), and_r(E.cor_level(S.Breakdown{}), kf2(), h))
    case S.Limiter{}:
      and_l(E.cor_level(S.Limiter{}), kf4(), and_r(E.cor_level(S.IpRise{}), kf3(), and_r(E.cor_level(S.Breakdown{}), kf2(), h)))
    case S.Xpoint{}:
      and_l(E.cor_level(S.Xpoint{}), kf5(), and_r(E.cor_level(S.Limiter{}), kf4(), and_r(E.cor_level(S.IpRise{}), kf3(), and_r(E.cor_level(S.Breakdown{}), kf2(), h))))
    case S.Heating1{}:
      and_l(E.cor_level(S.Heating1{}), kf6(), and_r(E.cor_level(S.Xpoint{}), kf5(), and_r(E.cor_level(S.Limiter{}), kf4(), and_r(E.cor_level(S.IpRise{}), kf3(), and_r(E.cor_level(S.Breakdown{}), kf2(), h)))))
    case S.Heating2{}:
      and_l(E.cor_level(S.Heating2{}), E.cor_level(S.Termination{}), and_r(E.cor_level(S.Heating1{}), kf6(), and_r(E.cor_level(S.Xpoint{}), kf5(), and_r(E.cor_level(S.Limiter{}), kf4(), and_r(E.cor_level(S.IpRise{}), kf3(), and_r(E.cor_level(S.Breakdown{}), kf2(), h))))))
    case S.Termination{}:
      and_r(E.cor_level(S.Heating2{}), E.cor_level(S.Termination{}), and_r(E.cor_level(S.Heating1{}), kf6(), and_r(E.cor_level(S.Xpoint{}), kf5(), and_r(E.cor_level(S.Limiter{}), kf4(), and_r(E.cor_level(S.IpRise{}), kf3(), and_r(E.cor_level(S.Breakdown{}), kf2(), h))))))

def cor_lvl_level(+p: S.Phase, l: S.Level, h: {E.cor_level(p) == True{} : Bool}) -> {E.cor_dms(p, l) == True{} : Bool}:
  match l:
    case S.LNone{}:
      and4_1(E.cor_dms(p, S.LNone{}), E.cor_dms(p, S.LJtt{}), E.cor_dms(p, S.LRtps{}), E.cor_dms(p, S.LPtn{}), h)
    case S.LJtt{}:
      and4_2(E.cor_dms(p, S.LNone{}), E.cor_dms(p, S.LJtt{}), E.cor_dms(p, S.LRtps{}), E.cor_dms(p, S.LPtn{}), h)
    case S.LRtps{}:
      and4_3(E.cor_dms(p, S.LNone{}), E.cor_dms(p, S.LJtt{}), E.cor_dms(p, S.LRtps{}), E.cor_dms(p, S.LPtn{}), h)
    case S.LPtn{}:
      and4_4(E.cor_dms(p, S.LNone{}), E.cor_dms(p, S.LJtt{}), E.cor_dms(p, S.LRtps{}), E.cor_dms(p, S.LPtn{}), h)

def cor_lvl_dms(+p: S.Phase, +l: S.Level, d: S.Dms, h: {E.cor_dms(p, l) == True{} : Bool}) -> {E.cor_plasma(p, l, d) == True{} : Bool}:
  match d:
    case S.DmsIdle{}:
      and3_1(E.cor_plasma(p, l, S.DmsIdle{}), E.cor_plasma(p, l, S.DmsArmed{}), E.cor_plasma(p, l, S.DmsFired{}), h)
    case S.DmsArmed{}:
      and3_2(E.cor_plasma(p, l, S.DmsIdle{}), E.cor_plasma(p, l, S.DmsArmed{}), E.cor_plasma(p, l, S.DmsFired{}), h)
    case S.DmsFired{}:
      and3_3(E.cor_plasma(p, l, S.DmsIdle{}), E.cor_plasma(p, l, S.DmsArmed{}), E.cor_plasma(p, l, S.DmsFired{}), h)

def cor_lvl_plasma(+p: S.Phase, +l: S.Level, +d: S.Dms, pl: Bool, h: {E.cor_plasma(p, l, d) == True{} : Bool}) -> {E.cor_nb(p, l, d, pl) == True{} : Bool}:
  match pl:
    case True{}:
      and_l(E.cor_nb(p, l, d, True{}), E.cor_nb(p, l, d, False{}), h)
    case False{}:
      and_r(E.cor_nb(p, l, d, True{}), E.cor_nb(p, l, d, False{}), h)

def cor_lvl_nb(+p: S.Phase, +l: S.Level, +d: S.Dms, +pl: Bool, nb: S.Heat, h: {E.cor_nb(p, l, d, pl) == True{} : Bool}) -> {E.cor_rf(p, l, d, pl, nb) == True{} : Bool}:
  match nb:
    case S.Off{}:
      and4_1(E.cor_rf(p, l, d, pl, S.Off{}), E.cor_rf(p, l, d, pl, S.Inhibited{}), E.cor_rf(p, l, d, pl, S.Ramping{}), E.cor_rf(p, l, d, pl, S.On{}), h)
    case S.Inhibited{}:
      and4_2(E.cor_rf(p, l, d, pl, S.Off{}), E.cor_rf(p, l, d, pl, S.Inhibited{}), E.cor_rf(p, l, d, pl, S.Ramping{}), E.cor_rf(p, l, d, pl, S.On{}), h)
    case S.Ramping{}:
      and4_3(E.cor_rf(p, l, d, pl, S.Off{}), E.cor_rf(p, l, d, pl, S.Inhibited{}), E.cor_rf(p, l, d, pl, S.Ramping{}), E.cor_rf(p, l, d, pl, S.On{}), h)
    case S.On{}:
      and4_4(E.cor_rf(p, l, d, pl, S.Off{}), E.cor_rf(p, l, d, pl, S.Inhibited{}), E.cor_rf(p, l, d, pl, S.Ramping{}), E.cor_rf(p, l, d, pl, S.On{}), h)

def cor_lvl_rf(+p: S.Phase, +l: S.Level, +d: S.Dms, +pl: Bool, +nb: S.Heat, rf: S.Heat, h: {E.cor_rf(p, l, d, pl, nb) == True{} : Bool}) -> {E.cor_at(S.Fin{p, l, d, pl, nb, rf}) == True{} : Bool}:
  match rf:
    case S.Off{}:
      and4_1(E.cor_at(S.Fin{p, l, d, pl, nb, S.Off{}}), E.cor_at(S.Fin{p, l, d, pl, nb, S.Inhibited{}}), E.cor_at(S.Fin{p, l, d, pl, nb, S.Ramping{}}), E.cor_at(S.Fin{p, l, d, pl, nb, S.On{}}), h)
    case S.Inhibited{}:
      and4_2(E.cor_at(S.Fin{p, l, d, pl, nb, S.Off{}}), E.cor_at(S.Fin{p, l, d, pl, nb, S.Inhibited{}}), E.cor_at(S.Fin{p, l, d, pl, nb, S.Ramping{}}), E.cor_at(S.Fin{p, l, d, pl, nb, S.On{}}), h)
    case S.Ramping{}:
      and4_3(E.cor_at(S.Fin{p, l, d, pl, nb, S.Off{}}), E.cor_at(S.Fin{p, l, d, pl, nb, S.Inhibited{}}), E.cor_at(S.Fin{p, l, d, pl, nb, S.Ramping{}}), E.cor_at(S.Fin{p, l, d, pl, nb, S.On{}}), h)
    case S.On{}:
      and4_4(E.cor_at(S.Fin{p, l, d, pl, nb, S.Off{}}), E.cor_at(S.Fin{p, l, d, pl, nb, S.Inhibited{}}), E.cor_at(S.Fin{p, l, d, pl, nb, S.Ramping{}}), E.cor_at(S.Fin{p, l, d, pl, nb, S.On{}}), h)

# every control state satisfies cor_at
def cor_cell(f: S.Fin) -> {E.cor_at(f) == True{} : Bool}:
  match f:
    case S.Fin{+p, +l, +d, +pl, +nb, +rf}:
      cor_lvl_rf(p, l, d, pl, nb, rf, cor_lvl_nb(p, l, d, pl, nb, cor_lvl_plasma(p, l, d, pl,
        cor_lvl_dms(p, l, d, cor_lvl_level(p, l, cor_phase(p, Laws.corollaries_check()))))))

# the four consequents of cor_at
def k1(+f: S.Fin) -> Bool:
  S.implies(S.is_ptn(S.level_of(f)), Bool.and(S.unpowered(S.nb_of(f)), S.unpowered(S.rf_of(f))))

def k2(+f: S.Fin) -> Bool:
  S.implies(Bool.not(S.is_idle(S.dms_of(f))), Bool.and(S.unpowered(S.nb_of(f)), S.unpowered(S.rf_of(f))))

def k3(+f: S.Fin) -> Bool:
  S.implies(Bool.not(S.is_none(S.level_of(f))), Bool.and(Bool.not(S.is_on(S.nb_of(f))), Bool.not(S.is_on(S.rf_of(f)))))

def k4(+f: S.Fin) -> Bool:
  S.implies(S.is_term(S.phase_of(f)), Bool.and(Bool.not(S.is_on(S.nb_of(f))), Bool.not(S.is_on(S.rf_of(f)))))

def k34(+f: S.Fin) -> Bool:
  Bool.and(k3(f), k4(f))

def k234(+f: S.Fin) -> Bool:
  Bool.and(k2(f), k34(f))

def k_all(+f: S.Fin) -> Bool:
  Bool.and(k1(f), k234(f))

# the consequents under inv_fin
def cor_body(+f: S.Fin, h: {S.inv_fin(f) == True{} : Bool}) -> {k_all(f) == True{} : Bool}:
  implies_e(S.inv_fin(f), k_all(f), cor_cell(f), h)

def Laws.ptn_no_heat(f, h):
  and_l(k1(f), k234(f), cor_body(f, h))

def Laws.dms_no_heat(f, h):
  and_l(k2(f), k34(f), and_r(k1(f), k234(f), cor_body(f, h)))

def Laws.stop_no_full_power(f, h):
  and_l(k3(f), k4(f), and_r(k2(f), k34(f), and_r(k1(f), k234(f), cor_body(f, h))))

def Laws.termination_no_full_power(f, h):
  and_r(k3(f), k4(f), and_r(k2(f), k34(f), and_r(k1(f), k234(f), cor_body(f, h))))
