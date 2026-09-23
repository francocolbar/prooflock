# PROOF_JETPROT.bend - the laws of jetprot, by REFLECTION on the finite certificates:
# PROOF_JETPROT_FIN.bend / PROOF_JETPROT_FIN_ALT.bend decide `check_fin(o) == True` by
# computation for each order and PROOF_JETPROT_COR.bend decides `check_cor() == True`; here
# one small lemma per quantifier level turns those Bools into universal statements about
# every (order, control state, event, verdicts) cell, and short lemmas turn a cell into the
# step laws and the preservation laws. The only inductions are on the traces. Three laws
# (F1a, F1c, IP2) are proven directly, by computation on the concrete layer and through P16.
#
# Revision 2026-09-21 (blocker 4): eight control fields, 10 752 control states x 43 columns
# (2 x 462 336 cells), seven property groups, fourteen event pairs, 112 slices.
# Revision 4 (2026-09-22): the group g_j of the named PTN/primary-stop laws (P1a, P1b, D1a, D1b,
# PIW-after-PTN) closes g_f.
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
# turning `check_fin(o) == True` into `all_jtt(o, p) == True` would make the checker
# normalise the whole certificate with `o` and `p` still symbolic, twice per phase branch
# (minutes per branch). Instead the 112 slices `all_dms(o, p, j, l)` -- which together ARE
# `check_fin(Ord1)` and `check_fin(Ord2)`, the two certificates of LAWS_JETPROT.bend -- are
# decided directly by computation, exactly as PROOF_JETPROT_FIN.bend decides the whole of
# one order. From there every remaining comparison is over a term of at most 1/56 of a
# certificate.
# ---------------------------------------------------------------------------

# The certificate of LAWS_JETPROT.bend (finite_check / finite_check_alt, decided in
# PROOF_JETPROT_FIN.bend and _FIN_ALT.bend), sliced per (order, program phase, waveform
# flag, stop level): 2 x 7 x 2 x 4 = 112 slices of 192 control states x 43 columns, i.e.
# exactly the 2 x 462 336 cells of check_fin(Ord1) and check_fin(Ord2), decided here the
# same way, by computation. Slicing is what keeps the ladder cheap: no comparison in this
# file ever has to normalise a whole certificate (even naming `check_fin(Ord1{})` in a type
# costs the checker a full evaluation of it on both sides of the comparison).
def base(o: S.Ord, p: S.Phase, j: Bool, l: S.Level) -> {E.all_dms(o, p, j, l) == True{} : Bool}:
  match o p j l:
    case S.Ord1{} S.Breakdown{} False{} S.LNone{}:
      {==}
    case S.Ord1{} S.Breakdown{} False{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Breakdown{} False{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Breakdown{} False{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Breakdown{} True{} S.LNone{}:
      {==}
    case S.Ord1{} S.Breakdown{} True{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Breakdown{} True{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Breakdown{} True{} S.LPtn{}:
      {==}
    case S.Ord1{} S.IpRise{} False{} S.LNone{}:
      {==}
    case S.Ord1{} S.IpRise{} False{} S.LJtt{}:
      {==}
    case S.Ord1{} S.IpRise{} False{} S.LRtps{}:
      {==}
    case S.Ord1{} S.IpRise{} False{} S.LPtn{}:
      {==}
    case S.Ord1{} S.IpRise{} True{} S.LNone{}:
      {==}
    case S.Ord1{} S.IpRise{} True{} S.LJtt{}:
      {==}
    case S.Ord1{} S.IpRise{} True{} S.LRtps{}:
      {==}
    case S.Ord1{} S.IpRise{} True{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Limiter{} False{} S.LNone{}:
      {==}
    case S.Ord1{} S.Limiter{} False{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Limiter{} False{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Limiter{} False{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Limiter{} True{} S.LNone{}:
      {==}
    case S.Ord1{} S.Limiter{} True{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Limiter{} True{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Limiter{} True{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Xpoint{} False{} S.LNone{}:
      {==}
    case S.Ord1{} S.Xpoint{} False{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Xpoint{} False{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Xpoint{} False{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Xpoint{} True{} S.LNone{}:
      {==}
    case S.Ord1{} S.Xpoint{} True{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Xpoint{} True{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Xpoint{} True{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Heating1{} False{} S.LNone{}:
      {==}
    case S.Ord1{} S.Heating1{} False{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Heating1{} False{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Heating1{} False{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Heating1{} True{} S.LNone{}:
      {==}
    case S.Ord1{} S.Heating1{} True{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Heating1{} True{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Heating1{} True{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Heating2{} False{} S.LNone{}:
      {==}
    case S.Ord1{} S.Heating2{} False{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Heating2{} False{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Heating2{} False{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Heating2{} True{} S.LNone{}:
      {==}
    case S.Ord1{} S.Heating2{} True{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Heating2{} True{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Heating2{} True{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Termination{} False{} S.LNone{}:
      {==}
    case S.Ord1{} S.Termination{} False{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Termination{} False{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Termination{} False{} S.LPtn{}:
      {==}
    case S.Ord1{} S.Termination{} True{} S.LNone{}:
      {==}
    case S.Ord1{} S.Termination{} True{} S.LJtt{}:
      {==}
    case S.Ord1{} S.Termination{} True{} S.LRtps{}:
      {==}
    case S.Ord1{} S.Termination{} True{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Breakdown{} False{} S.LNone{}:
      {==}
    case S.Ord2{} S.Breakdown{} False{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Breakdown{} False{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Breakdown{} False{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Breakdown{} True{} S.LNone{}:
      {==}
    case S.Ord2{} S.Breakdown{} True{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Breakdown{} True{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Breakdown{} True{} S.LPtn{}:
      {==}
    case S.Ord2{} S.IpRise{} False{} S.LNone{}:
      {==}
    case S.Ord2{} S.IpRise{} False{} S.LJtt{}:
      {==}
    case S.Ord2{} S.IpRise{} False{} S.LRtps{}:
      {==}
    case S.Ord2{} S.IpRise{} False{} S.LPtn{}:
      {==}
    case S.Ord2{} S.IpRise{} True{} S.LNone{}:
      {==}
    case S.Ord2{} S.IpRise{} True{} S.LJtt{}:
      {==}
    case S.Ord2{} S.IpRise{} True{} S.LRtps{}:
      {==}
    case S.Ord2{} S.IpRise{} True{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Limiter{} False{} S.LNone{}:
      {==}
    case S.Ord2{} S.Limiter{} False{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Limiter{} False{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Limiter{} False{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Limiter{} True{} S.LNone{}:
      {==}
    case S.Ord2{} S.Limiter{} True{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Limiter{} True{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Limiter{} True{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Xpoint{} False{} S.LNone{}:
      {==}
    case S.Ord2{} S.Xpoint{} False{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Xpoint{} False{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Xpoint{} False{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Xpoint{} True{} S.LNone{}:
      {==}
    case S.Ord2{} S.Xpoint{} True{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Xpoint{} True{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Xpoint{} True{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Heating1{} False{} S.LNone{}:
      {==}
    case S.Ord2{} S.Heating1{} False{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Heating1{} False{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Heating1{} False{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Heating1{} True{} S.LNone{}:
      {==}
    case S.Ord2{} S.Heating1{} True{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Heating1{} True{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Heating1{} True{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Heating2{} False{} S.LNone{}:
      {==}
    case S.Ord2{} S.Heating2{} False{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Heating2{} False{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Heating2{} False{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Heating2{} True{} S.LNone{}:
      {==}
    case S.Ord2{} S.Heating2{} True{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Heating2{} True{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Heating2{} True{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Termination{} False{} S.LNone{}:
      {==}
    case S.Ord2{} S.Termination{} False{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Termination{} False{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Termination{} False{} S.LPtn{}:
      {==}
    case S.Ord2{} S.Termination{} True{} S.LNone{}:
      {==}
    case S.Ord2{} S.Termination{} True{} S.LJtt{}:
      {==}
    case S.Ord2{} S.Termination{} True{} S.LRtps{}:
      {==}
    case S.Ord2{} S.Termination{} True{} S.LPtn{}:
      {==}

# --- the control fields below the stop level: dms, plasma, ip, nb, rf ---

def lvl_dms(+o: S.Ord, +p: S.Phase, +j: Bool, +l: S.Level, d: S.Dms, h: {E.all_dms(o, p, j, l) == True{} : Bool}) -> {E.all_plasma(o, p, j, l, d) == True{} : Bool}:
  match d:
    case S.DmsIdle{}:
      and3_1(E.all_plasma(o, p, j, l, S.DmsIdle{}), E.all_plasma(o, p, j, l, S.DmsArmed{}), E.all_plasma(o, p, j, l, S.DmsFired{}), h)
    case S.DmsArmed{}:
      and3_2(E.all_plasma(o, p, j, l, S.DmsIdle{}), E.all_plasma(o, p, j, l, S.DmsArmed{}), E.all_plasma(o, p, j, l, S.DmsFired{}), h)
    case S.DmsFired{}:
      and3_3(E.all_plasma(o, p, j, l, S.DmsIdle{}), E.all_plasma(o, p, j, l, S.DmsArmed{}), E.all_plasma(o, p, j, l, S.DmsFired{}), h)

def lvl_plasma(+o: S.Ord, +p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, pl: Bool, h: {E.all_plasma(o, p, j, l, d) == True{} : Bool}) -> {E.all_ip(o, p, j, l, d, pl) == True{} : Bool}:
  match pl:
    case True{}:
      and_l(E.all_ip(o, p, j, l, d, True{}), E.all_ip(o, p, j, l, d, False{}), h)
    case False{}:
      and_r(E.all_ip(o, p, j, l, d, True{}), E.all_ip(o, p, j, l, d, False{}), h)

def lvl_ip(+o: S.Ord, +p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, +pl: Bool, ip: Bool, h: {E.all_ip(o, p, j, l, d, pl) == True{} : Bool}) -> {E.all_nb(o, p, j, l, d, pl, ip) == True{} : Bool}:
  match ip:
    case True{}:
      and_l(E.all_nb(o, p, j, l, d, pl, True{}), E.all_nb(o, p, j, l, d, pl, False{}), h)
    case False{}:
      and_r(E.all_nb(o, p, j, l, d, pl, True{}), E.all_nb(o, p, j, l, d, pl, False{}), h)

def lvl_nb(+o: S.Ord, +p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, +pl: Bool, +ip: Bool, nb: S.Heat, h: {E.all_nb(o, p, j, l, d, pl, ip) == True{} : Bool}) -> {E.all_rf(o, p, j, l, d, pl, ip, nb) == True{} : Bool}:
  match nb:
    case S.Off{}:
      and4_1(E.all_rf(o, p, j, l, d, pl, ip, S.Off{}), E.all_rf(o, p, j, l, d, pl, ip, S.Ramping{}), E.all_rf(o, p, j, l, d, pl, ip, S.Reduced{}), E.all_rf(o, p, j, l, d, pl, ip, S.On{}), h)
    case S.Ramping{}:
      and4_2(E.all_rf(o, p, j, l, d, pl, ip, S.Off{}), E.all_rf(o, p, j, l, d, pl, ip, S.Ramping{}), E.all_rf(o, p, j, l, d, pl, ip, S.Reduced{}), E.all_rf(o, p, j, l, d, pl, ip, S.On{}), h)
    case S.Reduced{}:
      and4_3(E.all_rf(o, p, j, l, d, pl, ip, S.Off{}), E.all_rf(o, p, j, l, d, pl, ip, S.Ramping{}), E.all_rf(o, p, j, l, d, pl, ip, S.Reduced{}), E.all_rf(o, p, j, l, d, pl, ip, S.On{}), h)
    case S.On{}:
      and4_4(E.all_rf(o, p, j, l, d, pl, ip, S.Off{}), E.all_rf(o, p, j, l, d, pl, ip, S.Ramping{}), E.all_rf(o, p, j, l, d, pl, ip, S.Reduced{}), E.all_rf(o, p, j, l, d, pl, ip, S.On{}), h)

def lvl_rf(+o: S.Ord, +p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, +pl: Bool, +ip: Bool, +nb: S.Heat, rf: S.Heat, h: {E.all_rf(o, p, j, l, d, pl, ip, nb) == True{} : Bool}) -> {E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, rf}) == True{} : Bool}:
  match rf:
    case S.Off{}:
      and4_1(E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Off{}}), E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Ramping{}}), E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Reduced{}}), E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.On{}}), h)
    case S.Ramping{}:
      and4_2(E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Off{}}), E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Ramping{}}), E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Reduced{}}), E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.On{}}), h)
    case S.Reduced{}:
      and4_3(E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Off{}}), E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Ramping{}}), E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Reduced{}}), E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.On{}}), h)
    case S.On{}:
      and4_4(E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Off{}}), E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Ramping{}}), E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Reduced{}}), E.all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.On{}}), h)

# --- the fourteen event groups: all_ev = and(q1, and(q2, and(q3, q4))), q1..q3 four-way, q4 two-way ---

def q1of(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_q1(o, f) == True{} : Bool}:
  and_l(E.ev_q1(o, f), Bool.and(E.ev_q2(o, f), Bool.and(E.ev_q3(o, f), E.ev_q4(o, f))), h)

def q2of(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_q2(o, f) == True{} : Bool}:
  and_l(E.ev_q2(o, f), Bool.and(E.ev_q3(o, f), E.ev_q4(o, f)), and_r(E.ev_q1(o, f), Bool.and(E.ev_q2(o, f), Bool.and(E.ev_q3(o, f), E.ev_q4(o, f))), h))

def q3of(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_q3(o, f) == True{} : Bool}:
  and_l(E.ev_q3(o, f), E.ev_q4(o, f), and_r(E.ev_q2(o, f), Bool.and(E.ev_q3(o, f), E.ev_q4(o, f)), and_r(E.ev_q1(o, f), Bool.and(E.ev_q2(o, f), Bool.and(E.ev_q3(o, f), E.ev_q4(o, f))), h)))

def q4of(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_q4(o, f) == True{} : Bool}:
  and_r(E.ev_q3(o, f), E.ev_q4(o, f), and_r(E.ev_q2(o, f), Bool.and(E.ev_q3(o, f), E.ev_q4(o, f)), and_r(E.ev_q1(o, f), Bool.and(E.ev_q2(o, f), Bool.and(E.ev_q3(o, f), E.ev_q4(o, f))), h)))

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

def grp13(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g13(o, f) == True{} : Bool}:
  and_l(E.ev_g13(o, f), E.ev_g14(o, f), q4of(o, f, h))

def grp14(+o: S.Ord, +f: S.Fin, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.ev_g14(o, f) == True{} : Bool}:
  and_r(E.ev_g13(o, f), E.ev_g14(o, f), q4of(o, f, h))

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

# the event level. For the 23 columns certified once (E.one = prop at (True, True))
# the verdicts are erased by the reduction of the cell -- the counter commands of those
# events do not mention bt or bh -- so the same proof closes the goal at any (bt, bh).
def lvl_ev(+o: S.Ord, +f: S.Fin, e: S.Ev, +bt: Bool, +bh: Bool, h: {E.all_ev(o, f) == True{} : Bool}) -> {E.prop(o, f, e, bt, bh) == True{} : Bool}:
  match e:
    case S.Advance{}:
      and_l(E.one(o, f, S.Advance{}), E.one(o, f, S.Heartbeat{}), grp1(o, f, h))
    case S.Stop{req, dms}:
      match req dms:
        case S.LNone{} True{}:
          and_l(E.one(o, f, S.Stop{S.LNone{}, True{}}), E.one(o, f, S.Stop{S.LNone{}, False{}}), grp11(o, f, h))
        case S.LNone{} False{}:
          and_r(E.one(o, f, S.Stop{S.LNone{}, True{}}), E.one(o, f, S.Stop{S.LNone{}, False{}}), grp11(o, f, h))
        case S.LJtt{} True{}:
          and_l(E.one(o, f, S.Stop{S.LJtt{}, True{}}), E.one(o, f, S.Stop{S.LJtt{}, False{}}), grp12(o, f, h))
        case S.LJtt{} False{}:
          and_r(E.one(o, f, S.Stop{S.LJtt{}, True{}}), E.one(o, f, S.Stop{S.LJtt{}, False{}}), grp12(o, f, h))
        case S.LRtps{} True{}:
          and_l(E.one(o, f, S.Stop{S.LRtps{}, True{}}), E.one(o, f, S.Stop{S.LRtps{}, False{}}), grp13(o, f, h))
        case S.LRtps{} False{}:
          and_r(E.one(o, f, S.Stop{S.LRtps{}, True{}}), E.one(o, f, S.Stop{S.LRtps{}, False{}}), grp13(o, f, h))
        case S.LPtn{} True{}:
          lvl_bh(o, f, S.Stop{S.LPtn{}, True{}}, bt, bh,
            lvl_bt(o, f, S.Stop{S.LPtn{}, True{}}, bt,
              and_l(E.all_bt(o, f, S.Stop{S.LPtn{}, True{}}), E.one(o, f, S.Stop{S.LPtn{}, False{}}), grp14(o, f, h))))
        case S.LPtn{} False{}:
          and_r(E.all_bt(o, f, S.Stop{S.LPtn{}, True{}}), E.one(o, f, S.Stop{S.LPtn{}, False{}}), grp14(o, f, h))
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
    case S.Ip{ok}:
      match ok:
        case True{}:
          and_l(E.one(o, f, S.Ip{True{}}), E.one(o, f, S.Ip{False{}}), grp7(o, f, h))
        case False{}:
          and_r(E.one(o, f, S.Ip{True{}}), E.one(o, f, S.Ip{False{}}), grp7(o, f, h))
    case S.CommFault{dms, en}:
      match dms en:
        case True{} True{}:
          lvl_bh(o, f, S.CommFault{True{}, True{}}, bt, bh,
            lvl_bt(o, f, S.CommFault{True{}, True{}}, bt,
              and_l(E.all_bt(o, f, S.CommFault{True{}, True{}}), E.one(o, f, S.CommFault{True{}, False{}}), grp8(o, f, h))))
        case True{} False{}:
          and_r(E.all_bt(o, f, S.CommFault{True{}, True{}}), E.one(o, f, S.CommFault{True{}, False{}}), grp8(o, f, h))
        case False{} True{}:
          and_l(E.one(o, f, S.CommFault{False{}, True{}}), E.one(o, f, S.CommFault{False{}, False{}}), grp9(o, f, h))
        case False{} False{}:
          and_r(E.one(o, f, S.CommFault{False{}, True{}}), E.one(o, f, S.CommFault{False{}, False{}}), grp9(o, f, h))
    case S.Heartbeat{}:
      and_r(E.one(o, f, S.Advance{}), E.one(o, f, S.Heartbeat{}), grp1(o, f, h))
    case S.Tick{dms}:
      match dms:
        case True{}:
          lvl_bh(o, f, S.Tick{True{}}, bt, bh,
            lvl_bt(o, f, S.Tick{True{}}, bt,
              and_l(E.all_bt(o, f, S.Tick{True{}}), E.all_bt(o, f, S.Tick{False{}}), grp10(o, f, h))))
        case False{}:
          lvl_bh(o, f, S.Tick{False{}}, bt, bh,
            lvl_bt(o, f, S.Tick{False{}}, bt,
              and_r(E.all_bt(o, f, S.Tick{True{}}), E.all_bt(o, f, S.Tick{False{}}), grp10(o, f, h))))
    case S.HeatAck{}:
      and_l(E.one(o, f, S.HeatAck{}), E.all_bt(o, f, S.Reset{}), grp2(o, f, h))
    case S.Reset{}:
      lvl_bh(o, f, S.Reset{}, bt, bh,
        lvl_bt(o, f, S.Reset{}, bt,
          and_r(E.one(o, f, S.HeatAck{}), E.all_bt(o, f, S.Reset{}), grp2(o, f, h))))

# every cell of the certificate holds, for either order
def cell(+o: S.Ord, f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.prop(o, f, e, bt, bh) == True{} : Bool}:
  match f:
    case S.Fin{+p, +j, +l, +d, +pl, +ip, +nb, +rf}:
      +f2 = {S.Fin{p, j, l, d, pl, ip, nb, rf} : S.Fin}
      lvl_ev(o, f2, e, bt, bh,
        lvl_rf(o, p, j, l, d, pl, ip, nb, rf,
          lvl_nb(o, p, j, l, d, pl, ip, nb,
            lvl_ip(o, p, j, l, d, pl, ip,
              lvl_plasma(o, p, j, l, d, pl,
                lvl_dms(o, p, j, l, d, base(o, p, j, l)))))))

# ---------------------------------------------------------------------------
# The conjuncts of a cell: prop_at = and(g_pres, and(g_a, and(g_b, and(g_c, and(g_d, and(g_e, g_f))))))
# ---------------------------------------------------------------------------

# the tails of prop_at, as named Bools (so every projection is one and_l / and_r)
def gef(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(E.g_e(o, f, e, bt, bh, f2), E.g_f(o, f, e, bt, bh, f2))

def gdef(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(E.g_d(o, f, e, bt, bh, f2), gef(o, f, e, bt, bh, f2))

def gcdef(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(E.g_c(f, e, bt, bh, f2), gdef(o, f, e, bt, bh, f2))

def gbcdef(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(E.g_b(f, e, bt, bh, f2), gcdef(o, f, e, bt, bh, f2))

def gabcdef(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(E.g_a(o, f, e, f2), gbcdef(o, f, e, bt, bh, f2))

def c_pres(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_pres(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(E.g_pres(f, e, bt, bh, f2), gabcdef(o, f, e, bt, bh, f2), cell(o, f, e, bt, bh))

# the successive tails of prop_at as facts
def c_t1(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {gabcdef(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(E.g_pres(f, e, bt, bh, f2), gabcdef(o, f, e, bt, bh, f2), cell(o, f, e, bt, bh))

def c_a(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_a(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(E.g_a(o, f, e, f2), gbcdef(o, f, e, bt, bh, f2), c_t1(o, f, e, bt, bh))

def c_t2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {gbcdef(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(E.g_a(o, f, e, f2), gbcdef(o, f, e, bt, bh, f2), c_t1(o, f, e, bt, bh))

def c_b(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_b(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(E.g_b(f, e, bt, bh, f2), gcdef(o, f, e, bt, bh, f2), c_t2(o, f, e, bt, bh))

def c_t3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {gcdef(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(E.g_b(f, e, bt, bh, f2), gcdef(o, f, e, bt, bh, f2), c_t2(o, f, e, bt, bh))

def c_c(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_c(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(E.g_c(f, e, bt, bh, f2), gdef(o, f, e, bt, bh, f2), c_t3(o, f, e, bt, bh))

def c_t4(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {gdef(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(E.g_c(f, e, bt, bh, f2), gdef(o, f, e, bt, bh, f2), c_t3(o, f, e, bt, bh))

def c_d(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_d(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(E.g_d(o, f, e, bt, bh, f2), gef(o, f, e, bt, bh, f2), c_t4(o, f, e, bt, bh))

def c_t5(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {gef(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(E.g_d(o, f, e, bt, bh, f2), gef(o, f, e, bt, bh, f2), c_t4(o, f, e, bt, bh))

def c_e(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_e(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(E.g_e(o, f, e, bt, bh, f2), E.g_f(o, f, e, bt, bh, f2), c_t5(o, f, e, bt, bh))

def c_f(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_f(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(E.g_e(o, f, e, bt, bh, f2), E.g_f(o, f, e, bt, bh, f2), c_t5(o, f, e, bt, bh))

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

# g_b = and(p5, and(p6, and(p7, p9)))
def tb3(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p7(f, e, f2), Spec.pr_p9(f, e, bt, bh, f2))

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
  and_l(Spec.pr_p7(f, e, f2), Spec.pr_p9(f, e, bt, bh, f2), and_r(Spec.pr_p6(f, f2), tb3(f, e, bt, bh, f2), and_r(Spec.pr_p5(f, e, f2), tb2(f, e, bt, bh, f2), c_b(o, f, e, bt, bh))))

def cp9(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p9(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p7(f, e, f2), Spec.pr_p9(f, e, bt, bh, f2), and_r(Spec.pr_p6(f, f2), tb3(f, e, bt, bh, f2), and_r(Spec.pr_p5(f, e, f2), tb2(f, e, bt, bh, f2), c_b(o, f, e, bt, bh))))

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
# The E conjuncts: g_e = and(pr_e2, and(pr_e3, ... and(pr_e8, pr_e11)...))
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

# the successive tails of g_e as facts
def ce3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {te3(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_e2(f, e, bt, f2), te3(o, f, e, bt, bh, f2), c_e(o, f, e, bt, bh))

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

# the eight E properties of one cell
def cp_e2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_e2(f, e, bt, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_e2(f, e, bt, f2), te3(o, f, e, bt, bh, f2), c_e(o, f, e, bt, bh))

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
# The fidelity conjuncts: g_f = and(pr_f1b, and(pr_f1d, and(pr_f1e, and(pr_f2a, and(pr_f2d, and(pr_f3b,
#   and(pr_f4, and(pr_ip1, and(pr_ip3, and(pr_ip4, g_j))))))))))
# and the group g_j of the named PTN/primary-stop laws (revision 4): g_j = and(pr_p1a, and(pr_p1b, and(pr_d1a, and(pr_d1b, pr_piw_noop))))
# ---------------------------------------------------------------------------

def tf10(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_ip4(f, e, f2), E.g_j(f, e, bt, bh, f2))

def tf9(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_ip3(e, f2), tf10(f, e, bt, bh, f2))

def tf8(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_ip1(f, f2), tf9(f, e, bt, bh, f2))

def tf7(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_f4(f, e, f2), tf8(f, e, bt, bh, f2))

def tf6(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_f3b(f, e, bt, bh, f2), tf7(f, e, bt, bh, f2))

def tf5(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_f2d(f, e, f2), tf6(f, e, bt, bh, f2))

def tf4(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_f2a(f, e, f2), tf5(f, e, bt, bh, f2))

def tf3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_f1e(o, f, e, f2), tf4(f, e, bt, bh, f2))

def tf2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_f1d(f, e, f2), tf3(o, f, e, bt, bh, f2))

# the successive tails of g_f as facts
def cf2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tf2(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_f1b(f, e, f2), tf2(o, f, e, bt, bh, f2), c_f(o, f, e, bt, bh))

def cf3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tf3(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_f1d(f, e, f2), tf3(o, f, e, bt, bh, f2), cf2(o, f, e, bt, bh))

def cf4(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tf4(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_f1e(o, f, e, f2), tf4(f, e, bt, bh, f2), cf3(o, f, e, bt, bh))

def cf5(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tf5(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_f2a(f, e, f2), tf5(f, e, bt, bh, f2), cf4(o, f, e, bt, bh))

def cf6(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tf6(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_f2d(f, e, f2), tf6(f, e, bt, bh, f2), cf5(o, f, e, bt, bh))

def cf7(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tf7(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_f3b(f, e, bt, bh, f2), tf7(f, e, bt, bh, f2), cf6(o, f, e, bt, bh))

def cf8(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tf8(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_f4(f, e, f2), tf8(f, e, bt, bh, f2), cf7(o, f, e, bt, bh))

def cf9(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tf9(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_ip1(f, f2), tf9(f, e, bt, bh, f2), cf8(o, f, e, bt, bh))

# the ten fidelity properties of one cell
def cp_f1b(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_f1b(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_f1b(f, e, f2), tf2(o, f, e, bt, bh, f2), c_f(o, f, e, bt, bh))

def cp_f1d(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_f1d(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_f1d(f, e, f2), tf3(o, f, e, bt, bh, f2), cf2(o, f, e, bt, bh))

def cp_f1e(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_f1e(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_f1e(o, f, e, f2), tf4(f, e, bt, bh, f2), cf3(o, f, e, bt, bh))

def cp_f2a(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_f2a(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_f2a(f, e, f2), tf5(f, e, bt, bh, f2), cf4(o, f, e, bt, bh))

def cp_f2d(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_f2d(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_f2d(f, e, f2), tf6(f, e, bt, bh, f2), cf5(o, f, e, bt, bh))

def cp_f3b(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_f3b(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_f3b(f, e, bt, bh, f2), tf7(f, e, bt, bh, f2), cf6(o, f, e, bt, bh))

def cp_f4(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_f4(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_f4(f, e, f2), tf8(f, e, bt, bh, f2), cf7(o, f, e, bt, bh))

def cp_ip1(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_ip1(f, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_ip1(f, f2), tf9(f, e, bt, bh, f2), cf8(o, f, e, bt, bh))

def cf10(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tf10(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_ip3(e, f2), tf10(f, e, bt, bh, f2), cf9(o, f, e, bt, bh))

def cp_ip3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_ip3(e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_ip3(e, f2), tf10(f, e, bt, bh, f2), cf9(o, f, e, bt, bh))

def cp_ip4(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_ip4(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_ip4(f, e, f2), E.g_j(f, e, bt, bh, f2), cf10(o, f, e, bt, bh))

# the group g_j of the named PTN/primary-stop laws (revision 4) and its successive tails
def cg_j(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.g_j(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_ip4(f, e, f2), E.g_j(f, e, bt, bh, f2), cf10(o, f, e, bt, bh))

def tj4(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d1b(f, e, f2), Spec.pr_piw_noop(f, e, bt, bh, f2))

def tj3(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d1a(e, f2), tj4(f, e, bt, bh, f2))

def tj2(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p1b(f, e, f2), tj3(f, e, bt, bh, f2))

def cj2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tj2(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p1a(f, e, f2), tj2(f, e, bt, bh, f2), cg_j(o, f, e, bt, bh))

def cj3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tj3(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_p1b(f, e, f2), tj3(f, e, bt, bh, f2), cj2(o, f, e, bt, bh))

def cj4(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {tj4(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d1a(e, f2), tj4(f, e, bt, bh, f2), cj3(o, f, e, bt, bh))

def cp_p1a(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p1a(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p1a(f, e, f2), tj2(f, e, bt, bh, f2), cg_j(o, f, e, bt, bh))

def cp_p1b(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_p1b(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_p1b(f, e, f2), tj3(f, e, bt, bh, f2), cj2(o, f, e, bt, bh))

def cp_d1a(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d1a(e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d1a(e, f2), tj4(f, e, bt, bh, f2), cj3(o, f, e, bt, bh))

def cp_d1b(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_d1b(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_l(Spec.pr_d1b(f, e, f2), Spec.pr_piw_noop(f, e, bt, bh, f2), cj4(o, f, e, bt, bh))

def cp_piw_noop(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {Spec.pr_piw_noop(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}:
  +f2 = S.step_fin(o, f, e, bt, bh)
  and_r(Spec.pr_d1b(f, e, f2), Spec.pr_piw_noop(f, e, bt, bh, f2), cj4(o, f, e, bt, bh))

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
  step_safe(S.Ord1{}, s, hall, S.concretize(i, S.fin_of(s), c))

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

# the remaining demand and frame laws E2..E11
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

# the fidelity laws decided by the certificate (group g_f)
def Laws.f1b_stop_keeps_prog(o, f, e, bt, bh):
  cp_f1b(o, f, e, bt, bh)

def Laws.f1d_wave_frame(o, f, e, bt, bh):
  cp_f1d(o, f, e, bt, bh)

def Laws.f1e_jtt_exact(o, f, e, bt, bh):
  cp_f1e(o, f, e, bt, bh)

def Laws.f2a_local_reduces(o, f, e, bt, bh):
  cp_f2a(o, f, e, bt, bh)

def Laws.f2d_reduced_never_returns(o, f, e, bt, bh):
  cp_f2d(o, f, e, bt, bh)

def Laws.f3b_commfault_masked_is_noop(o, f, e, bt, bh):
  cp_f3b(o, f, e, bt, bh)

def Laws.f4_units_frame(o, f, e, bt, bh):
  cp_f4(o, f, e, bt, bh)

def Laws.ip1_low_never_arms(o, f, e, bt, bh):
  cp_ip1(o, f, e, bt, bh)

def Laws.ip3_ip_is_input(o, f, e, bt, bh):
  cp_ip3(o, f, e, bt, bh)

def Laws.ip4_ip_frame(o, f, e, bt, bh):
  cp_ip4(o, f, e, bt, bh)

# the named PTN/primary-stop laws of revision 4 (P1a, D1b: JET facts; P1b, D1a, PIW-after-PTN:
# mixed), decided by the certificate (group g_j)
def Laws.p1a_ptn_latched(o, f, e, bt, bh):
  cp_p1a(o, f, e, bt, bh)

def Laws.p1b_stop_never_cleared(o, f, e, bt, bh):
  cp_p1b(o, f, e, bt, bh)

def Laws.d1a_ptn_honoured(o, f, e, bt, bh):
  cp_d1a(o, f, e, bt, bh)

def Laws.d1b_primary_honoured(o, f, e, bt, bh):
  cp_d1b(o, f, e, bt, bh)

def Laws.piw_after_ptn_is_noop(o, f, e, bt, bh):
  cp_piw_noop(o, f, e, bt, bh)

# ---------------------------------------------------------------------------
# The three fidelity laws proven directly: F1c by construction of wave_of, F1a by
# computation on the concrete layer (4 instances x 8 triggers x 7 program phases, for the
# primary and for the secondary table), IP2 through the abstract demand law P16; and the
# concrete law of revision 4, inst4_second_alarm_ptn, through D1a
# ---------------------------------------------------------------------------

# F1c: wave_go(j, p) is Termination or p itself, and phase_le is reflexive on each phase
def f1c_go(j: Bool, p: S.Phase) -> {Spec.phase_le(p, S.wave_go(j, p)) == True{} : Bool}:
  match j p:
    case True{} S.Breakdown{}:
      {==}
    case True{} S.IpRise{}:
      {==}
    case True{} S.Limiter{}:
      {==}
    case True{} S.Xpoint{}:
      {==}
    case True{} S.Heating1{}:
      {==}
    case True{} S.Heating2{}:
      {==}
    case True{} S.Termination{}:
      {==}
    case False{} S.Breakdown{}:
      {==}
    case False{} S.IpRise{}:
      {==}
    case False{} S.Limiter{}:
      {==}
    case False{} S.Xpoint{}:
      {==}
    case False{} S.Heating1{}:
      {==}
    case False{} S.Heating2{}:
      {==}
    case False{} S.Termination{}:
      {==}

def Laws.f1c_wave_ahead(f):
  match f:
    case S.Fin{p, j, l, d, pl, ip, nb, rf}:
      f1c_go(j, p)

# F1a: with the state split into its fields (and the level in force), concretize computes to the
# Stop on masked_table(i, p, t) (no stop in force) or sec_table(i, p, t) (a stop in force); each
# (instance, program phase, trigger) cell of either table is decided by computation
def f1a_go(i: S.Inst, p: S.Phase, t: S.Trig) -> {Spec.lvl_eq(S.masked_table(i, p, t), E.m_alarm(i, p, t)) == True{} : Bool}:
  match i p t:
    case S.Inst1{} S.Breakdown{} S.Slow{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.Fast{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.Mhd{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.MhdB{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.Mchs{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.Dhs{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.BothHs{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.Blind{}:
      {==}
    case S.Inst1{} S.IpRise{} S.Slow{}:
      {==}
    case S.Inst1{} S.IpRise{} S.Fast{}:
      {==}
    case S.Inst1{} S.IpRise{} S.Mhd{}:
      {==}
    case S.Inst1{} S.IpRise{} S.MhdB{}:
      {==}
    case S.Inst1{} S.IpRise{} S.Mchs{}:
      {==}
    case S.Inst1{} S.IpRise{} S.Dhs{}:
      {==}
    case S.Inst1{} S.IpRise{} S.BothHs{}:
      {==}
    case S.Inst1{} S.IpRise{} S.Blind{}:
      {==}
    case S.Inst1{} S.Limiter{} S.Slow{}:
      {==}
    case S.Inst1{} S.Limiter{} S.Fast{}:
      {==}
    case S.Inst1{} S.Limiter{} S.Mhd{}:
      {==}
    case S.Inst1{} S.Limiter{} S.MhdB{}:
      {==}
    case S.Inst1{} S.Limiter{} S.Mchs{}:
      {==}
    case S.Inst1{} S.Limiter{} S.Dhs{}:
      {==}
    case S.Inst1{} S.Limiter{} S.BothHs{}:
      {==}
    case S.Inst1{} S.Limiter{} S.Blind{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.Slow{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.Fast{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.Mhd{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.MhdB{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.Mchs{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.Dhs{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.BothHs{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.Blind{}:
      {==}
    case S.Inst1{} S.Heating1{} S.Slow{}:
      {==}
    case S.Inst1{} S.Heating1{} S.Fast{}:
      {==}
    case S.Inst1{} S.Heating1{} S.Mhd{}:
      {==}
    case S.Inst1{} S.Heating1{} S.MhdB{}:
      {==}
    case S.Inst1{} S.Heating1{} S.Mchs{}:
      {==}
    case S.Inst1{} S.Heating1{} S.Dhs{}:
      {==}
    case S.Inst1{} S.Heating1{} S.BothHs{}:
      {==}
    case S.Inst1{} S.Heating1{} S.Blind{}:
      {==}
    case S.Inst1{} S.Heating2{} S.Slow{}:
      {==}
    case S.Inst1{} S.Heating2{} S.Fast{}:
      {==}
    case S.Inst1{} S.Heating2{} S.Mhd{}:
      {==}
    case S.Inst1{} S.Heating2{} S.MhdB{}:
      {==}
    case S.Inst1{} S.Heating2{} S.Mchs{}:
      {==}
    case S.Inst1{} S.Heating2{} S.Dhs{}:
      {==}
    case S.Inst1{} S.Heating2{} S.BothHs{}:
      {==}
    case S.Inst1{} S.Heating2{} S.Blind{}:
      {==}
    case S.Inst1{} S.Termination{} S.Slow{}:
      {==}
    case S.Inst1{} S.Termination{} S.Fast{}:
      {==}
    case S.Inst1{} S.Termination{} S.Mhd{}:
      {==}
    case S.Inst1{} S.Termination{} S.MhdB{}:
      {==}
    case S.Inst1{} S.Termination{} S.Mchs{}:
      {==}
    case S.Inst1{} S.Termination{} S.Dhs{}:
      {==}
    case S.Inst1{} S.Termination{} S.BothHs{}:
      {==}
    case S.Inst1{} S.Termination{} S.Blind{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.Slow{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.Fast{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.Mhd{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.MhdB{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.Mchs{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.Dhs{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.BothHs{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.Blind{}:
      {==}
    case S.Inst2{} S.IpRise{} S.Slow{}:
      {==}
    case S.Inst2{} S.IpRise{} S.Fast{}:
      {==}
    case S.Inst2{} S.IpRise{} S.Mhd{}:
      {==}
    case S.Inst2{} S.IpRise{} S.MhdB{}:
      {==}
    case S.Inst2{} S.IpRise{} S.Mchs{}:
      {==}
    case S.Inst2{} S.IpRise{} S.Dhs{}:
      {==}
    case S.Inst2{} S.IpRise{} S.BothHs{}:
      {==}
    case S.Inst2{} S.IpRise{} S.Blind{}:
      {==}
    case S.Inst2{} S.Limiter{} S.Slow{}:
      {==}
    case S.Inst2{} S.Limiter{} S.Fast{}:
      {==}
    case S.Inst2{} S.Limiter{} S.Mhd{}:
      {==}
    case S.Inst2{} S.Limiter{} S.MhdB{}:
      {==}
    case S.Inst2{} S.Limiter{} S.Mchs{}:
      {==}
    case S.Inst2{} S.Limiter{} S.Dhs{}:
      {==}
    case S.Inst2{} S.Limiter{} S.BothHs{}:
      {==}
    case S.Inst2{} S.Limiter{} S.Blind{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.Slow{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.Fast{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.Mhd{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.MhdB{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.Mchs{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.Dhs{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.BothHs{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.Blind{}:
      {==}
    case S.Inst2{} S.Heating1{} S.Slow{}:
      {==}
    case S.Inst2{} S.Heating1{} S.Fast{}:
      {==}
    case S.Inst2{} S.Heating1{} S.Mhd{}:
      {==}
    case S.Inst2{} S.Heating1{} S.MhdB{}:
      {==}
    case S.Inst2{} S.Heating1{} S.Mchs{}:
      {==}
    case S.Inst2{} S.Heating1{} S.Dhs{}:
      {==}
    case S.Inst2{} S.Heating1{} S.BothHs{}:
      {==}
    case S.Inst2{} S.Heating1{} S.Blind{}:
      {==}
    case S.Inst2{} S.Heating2{} S.Slow{}:
      {==}
    case S.Inst2{} S.Heating2{} S.Fast{}:
      {==}
    case S.Inst2{} S.Heating2{} S.Mhd{}:
      {==}
    case S.Inst2{} S.Heating2{} S.MhdB{}:
      {==}
    case S.Inst2{} S.Heating2{} S.Mchs{}:
      {==}
    case S.Inst2{} S.Heating2{} S.Dhs{}:
      {==}
    case S.Inst2{} S.Heating2{} S.BothHs{}:
      {==}
    case S.Inst2{} S.Heating2{} S.Blind{}:
      {==}
    case S.Inst2{} S.Termination{} S.Slow{}:
      {==}
    case S.Inst2{} S.Termination{} S.Fast{}:
      {==}
    case S.Inst2{} S.Termination{} S.Mhd{}:
      {==}
    case S.Inst2{} S.Termination{} S.MhdB{}:
      {==}
    case S.Inst2{} S.Termination{} S.Mchs{}:
      {==}
    case S.Inst2{} S.Termination{} S.Dhs{}:
      {==}
    case S.Inst2{} S.Termination{} S.BothHs{}:
      {==}
    case S.Inst2{} S.Termination{} S.Blind{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.Slow{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.Fast{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.Mhd{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.MhdB{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.Mchs{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.Dhs{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.BothHs{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.Blind{}:
      {==}
    case S.Inst3{} S.IpRise{} S.Slow{}:
      {==}
    case S.Inst3{} S.IpRise{} S.Fast{}:
      {==}
    case S.Inst3{} S.IpRise{} S.Mhd{}:
      {==}
    case S.Inst3{} S.IpRise{} S.MhdB{}:
      {==}
    case S.Inst3{} S.IpRise{} S.Mchs{}:
      {==}
    case S.Inst3{} S.IpRise{} S.Dhs{}:
      {==}
    case S.Inst3{} S.IpRise{} S.BothHs{}:
      {==}
    case S.Inst3{} S.IpRise{} S.Blind{}:
      {==}
    case S.Inst3{} S.Limiter{} S.Slow{}:
      {==}
    case S.Inst3{} S.Limiter{} S.Fast{}:
      {==}
    case S.Inst3{} S.Limiter{} S.Mhd{}:
      {==}
    case S.Inst3{} S.Limiter{} S.MhdB{}:
      {==}
    case S.Inst3{} S.Limiter{} S.Mchs{}:
      {==}
    case S.Inst3{} S.Limiter{} S.Dhs{}:
      {==}
    case S.Inst3{} S.Limiter{} S.BothHs{}:
      {==}
    case S.Inst3{} S.Limiter{} S.Blind{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.Slow{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.Fast{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.Mhd{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.MhdB{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.Mchs{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.Dhs{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.BothHs{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.Blind{}:
      {==}
    case S.Inst3{} S.Heating1{} S.Slow{}:
      {==}
    case S.Inst3{} S.Heating1{} S.Fast{}:
      {==}
    case S.Inst3{} S.Heating1{} S.Mhd{}:
      {==}
    case S.Inst3{} S.Heating1{} S.MhdB{}:
      {==}
    case S.Inst3{} S.Heating1{} S.Mchs{}:
      {==}
    case S.Inst3{} S.Heating1{} S.Dhs{}:
      {==}
    case S.Inst3{} S.Heating1{} S.BothHs{}:
      {==}
    case S.Inst3{} S.Heating1{} S.Blind{}:
      {==}
    case S.Inst3{} S.Heating2{} S.Slow{}:
      {==}
    case S.Inst3{} S.Heating2{} S.Fast{}:
      {==}
    case S.Inst3{} S.Heating2{} S.Mhd{}:
      {==}
    case S.Inst3{} S.Heating2{} S.MhdB{}:
      {==}
    case S.Inst3{} S.Heating2{} S.Mchs{}:
      {==}
    case S.Inst3{} S.Heating2{} S.Dhs{}:
      {==}
    case S.Inst3{} S.Heating2{} S.BothHs{}:
      {==}
    case S.Inst3{} S.Heating2{} S.Blind{}:
      {==}
    case S.Inst3{} S.Termination{} S.Slow{}:
      {==}
    case S.Inst3{} S.Termination{} S.Fast{}:
      {==}
    case S.Inst3{} S.Termination{} S.Mhd{}:
      {==}
    case S.Inst3{} S.Termination{} S.MhdB{}:
      {==}
    case S.Inst3{} S.Termination{} S.Mchs{}:
      {==}
    case S.Inst3{} S.Termination{} S.Dhs{}:
      {==}
    case S.Inst3{} S.Termination{} S.BothHs{}:
      {==}
    case S.Inst3{} S.Termination{} S.Blind{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.Slow{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.Fast{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.Mhd{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.MhdB{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.Mchs{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.Dhs{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.BothHs{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.Blind{}:
      {==}
    case S.Inst4{} S.IpRise{} S.Slow{}:
      {==}
    case S.Inst4{} S.IpRise{} S.Fast{}:
      {==}
    case S.Inst4{} S.IpRise{} S.Mhd{}:
      {==}
    case S.Inst4{} S.IpRise{} S.MhdB{}:
      {==}
    case S.Inst4{} S.IpRise{} S.Mchs{}:
      {==}
    case S.Inst4{} S.IpRise{} S.Dhs{}:
      {==}
    case S.Inst4{} S.IpRise{} S.BothHs{}:
      {==}
    case S.Inst4{} S.IpRise{} S.Blind{}:
      {==}
    case S.Inst4{} S.Limiter{} S.Slow{}:
      {==}
    case S.Inst4{} S.Limiter{} S.Fast{}:
      {==}
    case S.Inst4{} S.Limiter{} S.Mhd{}:
      {==}
    case S.Inst4{} S.Limiter{} S.MhdB{}:
      {==}
    case S.Inst4{} S.Limiter{} S.Mchs{}:
      {==}
    case S.Inst4{} S.Limiter{} S.Dhs{}:
      {==}
    case S.Inst4{} S.Limiter{} S.BothHs{}:
      {==}
    case S.Inst4{} S.Limiter{} S.Blind{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.Slow{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.Fast{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.Mhd{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.MhdB{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.Mchs{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.Dhs{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.BothHs{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.Blind{}:
      {==}
    case S.Inst4{} S.Heating1{} S.Slow{}:
      {==}
    case S.Inst4{} S.Heating1{} S.Fast{}:
      {==}
    case S.Inst4{} S.Heating1{} S.Mhd{}:
      {==}
    case S.Inst4{} S.Heating1{} S.MhdB{}:
      {==}
    case S.Inst4{} S.Heating1{} S.Mchs{}:
      {==}
    case S.Inst4{} S.Heating1{} S.Dhs{}:
      {==}
    case S.Inst4{} S.Heating1{} S.BothHs{}:
      {==}
    case S.Inst4{} S.Heating1{} S.Blind{}:
      {==}
    case S.Inst4{} S.Heating2{} S.Slow{}:
      {==}
    case S.Inst4{} S.Heating2{} S.Fast{}:
      {==}
    case S.Inst4{} S.Heating2{} S.Mhd{}:
      {==}
    case S.Inst4{} S.Heating2{} S.MhdB{}:
      {==}
    case S.Inst4{} S.Heating2{} S.Mchs{}:
      {==}
    case S.Inst4{} S.Heating2{} S.Dhs{}:
      {==}
    case S.Inst4{} S.Heating2{} S.BothHs{}:
      {==}
    case S.Inst4{} S.Heating2{} S.Blind{}:
      {==}
    case S.Inst4{} S.Termination{} S.Slow{}:
      {==}
    case S.Inst4{} S.Termination{} S.Fast{}:
      {==}
    case S.Inst4{} S.Termination{} S.Mhd{}:
      {==}
    case S.Inst4{} S.Termination{} S.MhdB{}:
      {==}
    case S.Inst4{} S.Termination{} S.Mchs{}:
      {==}
    case S.Inst4{} S.Termination{} S.Dhs{}:
      {==}
    case S.Inst4{} S.Termination{} S.BothHs{}:
      {==}
    case S.Inst4{} S.Termination{} S.Blind{}:
      {==}

# F1a under a stop in force: the secondary table, cell by cell against the enumerator's rule
def f1a_sec(i: S.Inst, p: S.Phase, t: S.Trig) -> {Spec.lvl_eq(S.sec_table(i, p, t), E.m_sec(i, p, t)) == True{} : Bool}:
  match i p t:
    case S.Inst1{} S.Breakdown{} S.Slow{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.Fast{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.Mhd{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.MhdB{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.Mchs{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.Dhs{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.BothHs{}:
      {==}
    case S.Inst1{} S.Breakdown{} S.Blind{}:
      {==}
    case S.Inst1{} S.IpRise{} S.Slow{}:
      {==}
    case S.Inst1{} S.IpRise{} S.Fast{}:
      {==}
    case S.Inst1{} S.IpRise{} S.Mhd{}:
      {==}
    case S.Inst1{} S.IpRise{} S.MhdB{}:
      {==}
    case S.Inst1{} S.IpRise{} S.Mchs{}:
      {==}
    case S.Inst1{} S.IpRise{} S.Dhs{}:
      {==}
    case S.Inst1{} S.IpRise{} S.BothHs{}:
      {==}
    case S.Inst1{} S.IpRise{} S.Blind{}:
      {==}
    case S.Inst1{} S.Limiter{} S.Slow{}:
      {==}
    case S.Inst1{} S.Limiter{} S.Fast{}:
      {==}
    case S.Inst1{} S.Limiter{} S.Mhd{}:
      {==}
    case S.Inst1{} S.Limiter{} S.MhdB{}:
      {==}
    case S.Inst1{} S.Limiter{} S.Mchs{}:
      {==}
    case S.Inst1{} S.Limiter{} S.Dhs{}:
      {==}
    case S.Inst1{} S.Limiter{} S.BothHs{}:
      {==}
    case S.Inst1{} S.Limiter{} S.Blind{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.Slow{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.Fast{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.Mhd{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.MhdB{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.Mchs{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.Dhs{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.BothHs{}:
      {==}
    case S.Inst1{} S.Xpoint{} S.Blind{}:
      {==}
    case S.Inst1{} S.Heating1{} S.Slow{}:
      {==}
    case S.Inst1{} S.Heating1{} S.Fast{}:
      {==}
    case S.Inst1{} S.Heating1{} S.Mhd{}:
      {==}
    case S.Inst1{} S.Heating1{} S.MhdB{}:
      {==}
    case S.Inst1{} S.Heating1{} S.Mchs{}:
      {==}
    case S.Inst1{} S.Heating1{} S.Dhs{}:
      {==}
    case S.Inst1{} S.Heating1{} S.BothHs{}:
      {==}
    case S.Inst1{} S.Heating1{} S.Blind{}:
      {==}
    case S.Inst1{} S.Heating2{} S.Slow{}:
      {==}
    case S.Inst1{} S.Heating2{} S.Fast{}:
      {==}
    case S.Inst1{} S.Heating2{} S.Mhd{}:
      {==}
    case S.Inst1{} S.Heating2{} S.MhdB{}:
      {==}
    case S.Inst1{} S.Heating2{} S.Mchs{}:
      {==}
    case S.Inst1{} S.Heating2{} S.Dhs{}:
      {==}
    case S.Inst1{} S.Heating2{} S.BothHs{}:
      {==}
    case S.Inst1{} S.Heating2{} S.Blind{}:
      {==}
    case S.Inst1{} S.Termination{} S.Slow{}:
      {==}
    case S.Inst1{} S.Termination{} S.Fast{}:
      {==}
    case S.Inst1{} S.Termination{} S.Mhd{}:
      {==}
    case S.Inst1{} S.Termination{} S.MhdB{}:
      {==}
    case S.Inst1{} S.Termination{} S.Mchs{}:
      {==}
    case S.Inst1{} S.Termination{} S.Dhs{}:
      {==}
    case S.Inst1{} S.Termination{} S.BothHs{}:
      {==}
    case S.Inst1{} S.Termination{} S.Blind{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.Slow{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.Fast{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.Mhd{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.MhdB{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.Mchs{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.Dhs{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.BothHs{}:
      {==}
    case S.Inst2{} S.Breakdown{} S.Blind{}:
      {==}
    case S.Inst2{} S.IpRise{} S.Slow{}:
      {==}
    case S.Inst2{} S.IpRise{} S.Fast{}:
      {==}
    case S.Inst2{} S.IpRise{} S.Mhd{}:
      {==}
    case S.Inst2{} S.IpRise{} S.MhdB{}:
      {==}
    case S.Inst2{} S.IpRise{} S.Mchs{}:
      {==}
    case S.Inst2{} S.IpRise{} S.Dhs{}:
      {==}
    case S.Inst2{} S.IpRise{} S.BothHs{}:
      {==}
    case S.Inst2{} S.IpRise{} S.Blind{}:
      {==}
    case S.Inst2{} S.Limiter{} S.Slow{}:
      {==}
    case S.Inst2{} S.Limiter{} S.Fast{}:
      {==}
    case S.Inst2{} S.Limiter{} S.Mhd{}:
      {==}
    case S.Inst2{} S.Limiter{} S.MhdB{}:
      {==}
    case S.Inst2{} S.Limiter{} S.Mchs{}:
      {==}
    case S.Inst2{} S.Limiter{} S.Dhs{}:
      {==}
    case S.Inst2{} S.Limiter{} S.BothHs{}:
      {==}
    case S.Inst2{} S.Limiter{} S.Blind{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.Slow{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.Fast{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.Mhd{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.MhdB{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.Mchs{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.Dhs{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.BothHs{}:
      {==}
    case S.Inst2{} S.Xpoint{} S.Blind{}:
      {==}
    case S.Inst2{} S.Heating1{} S.Slow{}:
      {==}
    case S.Inst2{} S.Heating1{} S.Fast{}:
      {==}
    case S.Inst2{} S.Heating1{} S.Mhd{}:
      {==}
    case S.Inst2{} S.Heating1{} S.MhdB{}:
      {==}
    case S.Inst2{} S.Heating1{} S.Mchs{}:
      {==}
    case S.Inst2{} S.Heating1{} S.Dhs{}:
      {==}
    case S.Inst2{} S.Heating1{} S.BothHs{}:
      {==}
    case S.Inst2{} S.Heating1{} S.Blind{}:
      {==}
    case S.Inst2{} S.Heating2{} S.Slow{}:
      {==}
    case S.Inst2{} S.Heating2{} S.Fast{}:
      {==}
    case S.Inst2{} S.Heating2{} S.Mhd{}:
      {==}
    case S.Inst2{} S.Heating2{} S.MhdB{}:
      {==}
    case S.Inst2{} S.Heating2{} S.Mchs{}:
      {==}
    case S.Inst2{} S.Heating2{} S.Dhs{}:
      {==}
    case S.Inst2{} S.Heating2{} S.BothHs{}:
      {==}
    case S.Inst2{} S.Heating2{} S.Blind{}:
      {==}
    case S.Inst2{} S.Termination{} S.Slow{}:
      {==}
    case S.Inst2{} S.Termination{} S.Fast{}:
      {==}
    case S.Inst2{} S.Termination{} S.Mhd{}:
      {==}
    case S.Inst2{} S.Termination{} S.MhdB{}:
      {==}
    case S.Inst2{} S.Termination{} S.Mchs{}:
      {==}
    case S.Inst2{} S.Termination{} S.Dhs{}:
      {==}
    case S.Inst2{} S.Termination{} S.BothHs{}:
      {==}
    case S.Inst2{} S.Termination{} S.Blind{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.Slow{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.Fast{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.Mhd{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.MhdB{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.Mchs{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.Dhs{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.BothHs{}:
      {==}
    case S.Inst3{} S.Breakdown{} S.Blind{}:
      {==}
    case S.Inst3{} S.IpRise{} S.Slow{}:
      {==}
    case S.Inst3{} S.IpRise{} S.Fast{}:
      {==}
    case S.Inst3{} S.IpRise{} S.Mhd{}:
      {==}
    case S.Inst3{} S.IpRise{} S.MhdB{}:
      {==}
    case S.Inst3{} S.IpRise{} S.Mchs{}:
      {==}
    case S.Inst3{} S.IpRise{} S.Dhs{}:
      {==}
    case S.Inst3{} S.IpRise{} S.BothHs{}:
      {==}
    case S.Inst3{} S.IpRise{} S.Blind{}:
      {==}
    case S.Inst3{} S.Limiter{} S.Slow{}:
      {==}
    case S.Inst3{} S.Limiter{} S.Fast{}:
      {==}
    case S.Inst3{} S.Limiter{} S.Mhd{}:
      {==}
    case S.Inst3{} S.Limiter{} S.MhdB{}:
      {==}
    case S.Inst3{} S.Limiter{} S.Mchs{}:
      {==}
    case S.Inst3{} S.Limiter{} S.Dhs{}:
      {==}
    case S.Inst3{} S.Limiter{} S.BothHs{}:
      {==}
    case S.Inst3{} S.Limiter{} S.Blind{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.Slow{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.Fast{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.Mhd{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.MhdB{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.Mchs{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.Dhs{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.BothHs{}:
      {==}
    case S.Inst3{} S.Xpoint{} S.Blind{}:
      {==}
    case S.Inst3{} S.Heating1{} S.Slow{}:
      {==}
    case S.Inst3{} S.Heating1{} S.Fast{}:
      {==}
    case S.Inst3{} S.Heating1{} S.Mhd{}:
      {==}
    case S.Inst3{} S.Heating1{} S.MhdB{}:
      {==}
    case S.Inst3{} S.Heating1{} S.Mchs{}:
      {==}
    case S.Inst3{} S.Heating1{} S.Dhs{}:
      {==}
    case S.Inst3{} S.Heating1{} S.BothHs{}:
      {==}
    case S.Inst3{} S.Heating1{} S.Blind{}:
      {==}
    case S.Inst3{} S.Heating2{} S.Slow{}:
      {==}
    case S.Inst3{} S.Heating2{} S.Fast{}:
      {==}
    case S.Inst3{} S.Heating2{} S.Mhd{}:
      {==}
    case S.Inst3{} S.Heating2{} S.MhdB{}:
      {==}
    case S.Inst3{} S.Heating2{} S.Mchs{}:
      {==}
    case S.Inst3{} S.Heating2{} S.Dhs{}:
      {==}
    case S.Inst3{} S.Heating2{} S.BothHs{}:
      {==}
    case S.Inst3{} S.Heating2{} S.Blind{}:
      {==}
    case S.Inst3{} S.Termination{} S.Slow{}:
      {==}
    case S.Inst3{} S.Termination{} S.Fast{}:
      {==}
    case S.Inst3{} S.Termination{} S.Mhd{}:
      {==}
    case S.Inst3{} S.Termination{} S.MhdB{}:
      {==}
    case S.Inst3{} S.Termination{} S.Mchs{}:
      {==}
    case S.Inst3{} S.Termination{} S.Dhs{}:
      {==}
    case S.Inst3{} S.Termination{} S.BothHs{}:
      {==}
    case S.Inst3{} S.Termination{} S.Blind{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.Slow{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.Fast{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.Mhd{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.MhdB{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.Mchs{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.Dhs{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.BothHs{}:
      {==}
    case S.Inst4{} S.Breakdown{} S.Blind{}:
      {==}
    case S.Inst4{} S.IpRise{} S.Slow{}:
      {==}
    case S.Inst4{} S.IpRise{} S.Fast{}:
      {==}
    case S.Inst4{} S.IpRise{} S.Mhd{}:
      {==}
    case S.Inst4{} S.IpRise{} S.MhdB{}:
      {==}
    case S.Inst4{} S.IpRise{} S.Mchs{}:
      {==}
    case S.Inst4{} S.IpRise{} S.Dhs{}:
      {==}
    case S.Inst4{} S.IpRise{} S.BothHs{}:
      {==}
    case S.Inst4{} S.IpRise{} S.Blind{}:
      {==}
    case S.Inst4{} S.Limiter{} S.Slow{}:
      {==}
    case S.Inst4{} S.Limiter{} S.Fast{}:
      {==}
    case S.Inst4{} S.Limiter{} S.Mhd{}:
      {==}
    case S.Inst4{} S.Limiter{} S.MhdB{}:
      {==}
    case S.Inst4{} S.Limiter{} S.Mchs{}:
      {==}
    case S.Inst4{} S.Limiter{} S.Dhs{}:
      {==}
    case S.Inst4{} S.Limiter{} S.BothHs{}:
      {==}
    case S.Inst4{} S.Limiter{} S.Blind{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.Slow{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.Fast{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.Mhd{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.MhdB{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.Mchs{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.Dhs{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.BothHs{}:
      {==}
    case S.Inst4{} S.Xpoint{} S.Blind{}:
      {==}
    case S.Inst4{} S.Heating1{} S.Slow{}:
      {==}
    case S.Inst4{} S.Heating1{} S.Fast{}:
      {==}
    case S.Inst4{} S.Heating1{} S.Mhd{}:
      {==}
    case S.Inst4{} S.Heating1{} S.MhdB{}:
      {==}
    case S.Inst4{} S.Heating1{} S.Mchs{}:
      {==}
    case S.Inst4{} S.Heating1{} S.Dhs{}:
      {==}
    case S.Inst4{} S.Heating1{} S.BothHs{}:
      {==}
    case S.Inst4{} S.Heating1{} S.Blind{}:
      {==}
    case S.Inst4{} S.Heating2{} S.Slow{}:
      {==}
    case S.Inst4{} S.Heating2{} S.Fast{}:
      {==}
    case S.Inst4{} S.Heating2{} S.Mhd{}:
      {==}
    case S.Inst4{} S.Heating2{} S.MhdB{}:
      {==}
    case S.Inst4{} S.Heating2{} S.Mchs{}:
      {==}
    case S.Inst4{} S.Heating2{} S.Dhs{}:
      {==}
    case S.Inst4{} S.Heating2{} S.BothHs{}:
      {==}
    case S.Inst4{} S.Heating2{} S.Blind{}:
      {==}
    case S.Inst4{} S.Termination{} S.Slow{}:
      {==}
    case S.Inst4{} S.Termination{} S.Fast{}:
      {==}
    case S.Inst4{} S.Termination{} S.Mhd{}:
      {==}
    case S.Inst4{} S.Termination{} S.MhdB{}:
      {==}
    case S.Inst4{} S.Termination{} S.Mchs{}:
      {==}
    case S.Inst4{} S.Termination{} S.Dhs{}:
      {==}
    case S.Inst4{} S.Termination{} S.BothHs{}:
      {==}
    case S.Inst4{} S.Termination{} S.Blind{}:
      {==}

def Laws.f1a_table_reads_prog(i, f, t):
  match f:
    case S.Fin{p, j, l, d, pl, ip, nb, rf}:
      match l:
        case S.LNone{}:
          f1a_go(i, p, t)
        case S.LJtt{}:
          f1a_sec(i, p, t)
        case S.LRtps{}:
          f1a_sec(i, p, t)
        case S.LPtn{}:
          f1a_sec(i, p, t)

# IP2: step_c on St{f, 0n, 0n} is step_fin(Ord1, f, Stop{req, dms_req(wave, t)}, True, True)
# (both counter verdicts compute to True at 0n), so P16 applies with its hypothesis assembled
# from the four given facts. Revision 4: req is masked_table(i, prog, t) with no stop in force
# and sec_table(i, prog, t) with one, so the proof splits on the level; under a stop the PTN
# request carries over because every secondary table keeps a PTN primary entry (sec_ptn_up).
def sec_ptn_lem(l: S.Level, h: {S.is_ptn(l) == True{} : Bool}) -> {S.is_ptn(S.sec_ptn(l)) == True{} : Bool}:
  match l:
    case S.LNone{}:
      clash_ft({S.is_ptn(S.sec_ptn(S.LNone{})) == True{} : Bool}, h)
    case S.LJtt{}:
      clash_ft({S.is_ptn(S.sec_ptn(S.LJtt{})) == True{} : Bool}, h)
    case S.LRtps{}:
      clash_ft({S.is_ptn(S.sec_ptn(S.LRtps{})) == True{} : Bool}, h)
    case S.LPtn{}:
      {==}

def sec_ptn_up(i: S.Inst, +p: S.Phase, +t: S.Trig, h: {S.is_ptn(S.masked_table(i, p, t)) == True{} : Bool}) -> {S.is_ptn(S.sec_table(i, p, t)) == True{} : Bool}:
  match i:
    case S.Inst1{}:
      h
    case S.Inst2{}:
      h
    case S.Inst3{}:
      h
    case S.Inst4{}:
      sec_ptn_lem(S.masked_table(S.Inst4{}, p, t), h)

# the demand step for a given request req (the primary or the secondary entry), through P16
def ip2_req(+f: S.Fin, +req: S.Level, +d: Bool,
            h_ip: {S.ip_of(f) == True{} : Bool}, h_idle: {S.is_idle(S.dms_of(f)) == True{} : Bool},
            h_ptn: {S.is_ptn(req) == True{} : Bool}, h_req: {d == True{} : Bool})
            -> {S.is_armed(S.dms_of(S.step_fin(S.Ord1{}, f, S.Stop{req, d}, True{}, True{}))) == True{} : Bool}:
  implies_e(Bool.and(S.is_idle(S.dms_of(f)), Bool.and(S.ip_of(f), Bool.and(S.is_ptn(req), d))),
            S.is_armed(S.dms_of(S.step_fin(S.Ord1{}, f, S.Stop{req, d}, True{}, True{}))),
            Laws.dms_armed_on_demand(S.Ord1{}, f, S.Stop{req, d}, True{}, True{}),
            and_intro(S.is_idle(S.dms_of(f)), Bool.and(S.ip_of(f), Bool.and(S.is_ptn(req), d)), h_idle,
              and_intro(S.ip_of(f), Bool.and(S.is_ptn(req), d), h_ip,
                and_intro(S.is_ptn(req), d, h_ptn, h_req))))

def Laws.ip2_arms_on_demand(i, f, t, h_ip, h_idle, h_ptn, h_req):
  match f:
    case S.Fin{+p, +j, l, +d, +pl, +ip, +nb, +rf}:
      match l:
        case S.LNone{}:
          ip2_req(S.Fin{p, j, S.LNone{}, d, pl, ip, nb, rf}, S.masked_table(i, p, t), S.dms_req(S.wave_go(j, p), t), h_ip, h_idle, h_ptn, h_req)
        case S.LJtt{}:
          ip2_req(S.Fin{p, j, S.LJtt{}, d, pl, ip, nb, rf}, S.sec_table(i, p, t), S.dms_req(S.wave_go(j, p), t), h_ip, h_idle, sec_ptn_up(i, p, t, h_ptn), h_req)
        case S.LRtps{}:
          ip2_req(S.Fin{p, j, S.LRtps{}, d, pl, ip, nb, rf}, S.sec_table(i, p, t), S.dms_req(S.wave_go(j, p), t), h_ip, h_idle, sec_ptn_up(i, p, t, h_ptn), h_req)
        case S.LPtn{}:
          ip2_req(S.Fin{p, j, S.LPtn{}, d, pl, ip, nb, rf}, S.sec_table(i, p, t), S.dms_req(S.wave_go(j, p), t), h_ip, h_idle, sec_ptn_up(i, p, t, h_ptn), h_req)

# inst4_second_alarm_ptn (revision 4): split the state down to the level in force, the program
# phase and the trigger, so that concretize computes the request. Under a soft stop instance 4
# asks for sec_table(Inst4, prog, t) = LPtn whenever the primary entry is not None (h_cfg refutes
# the other cells), and D1a (a PTN request is honoured from any state) gives the PTN level; the
# DMS bit and the counter verdicts stay symbolic.
def d1a_level(+f: S.Fin, +d: Bool, +bt: Bool, +bh: Bool) -> {S.is_ptn(S.level_of(S.step_fin(S.Ord1{}, f, S.Stop{S.LPtn{}, d}, bt, bh))) == True{} : Bool}:
  +f2 = S.step_fin(S.Ord1{}, f, S.Stop{S.LPtn{}, d}, bt, bh)
  and_l(S.is_ptn(S.level_of(f2)), Bool.and(S.unpowered(S.nb_of(f2)), S.unpowered(S.rf_of(f2))),
    Laws.d1a_ptn_honoured(S.Ord1{}, f, S.Stop{S.LPtn{}, d}, bt, bh))

def i4_go(l: S.Level, p: S.Phase, t: S.Trig, +j: Bool, +d: S.Dms, +pl: Bool, +ip: Bool, +nb: S.Heat, +rf: S.Heat, +hb: Nat, +tack: Nat,
          h_soft: {S.is_soft(l) == True{} : Bool}, h_cfg: {S.is_none(S.masked_table(S.Inst4{}, p, t)) == False{} : Bool})
          -> {S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{p, j, l, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{t})))) == True{} : Bool}:
  match l p t:
    case S.LNone{} S.Breakdown{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Breakdown{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Breakdown{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Breakdown{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Breakdown{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Breakdown{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Breakdown{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Breakdown{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.IpRise{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.IpRise{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.IpRise{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.IpRise{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.IpRise{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.IpRise{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.IpRise{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.IpRise{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Limiter{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Limiter{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Limiter{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Limiter{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Limiter{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Limiter{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Limiter{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Limiter{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Xpoint{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Xpoint{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Xpoint{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Xpoint{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Xpoint{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Xpoint{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Xpoint{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Xpoint{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating1{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating1{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating1{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating1{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating1{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating1{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating1{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating1{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating2{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating2{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating2{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating2{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating2{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating2{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating2{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Heating2{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Termination{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Termination{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Termination{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Termination{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Termination{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Termination{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Termination{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LNone{} S.Termination{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LNone{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)
    case S.LJtt{} S.Breakdown{} S.Slow{}:
      d1a_level(S.Fin{S.Breakdown{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Breakdown{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Breakdown{} S.Fast{}:
      d1a_level(S.Fin{S.Breakdown{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Breakdown{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Breakdown{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Breakdown{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Breakdown{} S.Mchs{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Breakdown{} S.Dhs{}:
      d1a_level(S.Fin{S.Breakdown{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Breakdown{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Breakdown{} S.BothHs{}:
      d1a_level(S.Fin{S.Breakdown{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Breakdown{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Breakdown{} S.Blind{}:
      d1a_level(S.Fin{S.Breakdown{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Breakdown{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.IpRise{} S.Slow{}:
      d1a_level(S.Fin{S.IpRise{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.IpRise{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.IpRise{} S.Fast{}:
      d1a_level(S.Fin{S.IpRise{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.IpRise{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.IpRise{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.IpRise{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.IpRise{} S.Mchs{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.IpRise{} S.Dhs{}:
      d1a_level(S.Fin{S.IpRise{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.IpRise{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.IpRise{} S.BothHs{}:
      d1a_level(S.Fin{S.IpRise{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.IpRise{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.IpRise{} S.Blind{}:
      d1a_level(S.Fin{S.IpRise{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.IpRise{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Limiter{} S.Slow{}:
      d1a_level(S.Fin{S.Limiter{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Limiter{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Limiter{} S.Fast{}:
      d1a_level(S.Fin{S.Limiter{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Limiter{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Limiter{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Limiter{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Limiter{} S.Mchs{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Limiter{} S.Dhs{}:
      d1a_level(S.Fin{S.Limiter{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Limiter{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Limiter{} S.BothHs{}:
      d1a_level(S.Fin{S.Limiter{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Limiter{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Limiter{} S.Blind{}:
      d1a_level(S.Fin{S.Limiter{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Limiter{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Xpoint{} S.Slow{}:
      d1a_level(S.Fin{S.Xpoint{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Xpoint{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Xpoint{} S.Fast{}:
      d1a_level(S.Fin{S.Xpoint{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Xpoint{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Xpoint{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Xpoint{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Xpoint{} S.Mchs{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Xpoint{} S.Dhs{}:
      d1a_level(S.Fin{S.Xpoint{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Xpoint{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Xpoint{} S.BothHs{}:
      d1a_level(S.Fin{S.Xpoint{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Xpoint{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Xpoint{} S.Blind{}:
      d1a_level(S.Fin{S.Xpoint{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Xpoint{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Heating1{} S.Slow{}:
      d1a_level(S.Fin{S.Heating1{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating1{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Heating1{} S.Fast{}:
      d1a_level(S.Fin{S.Heating1{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating1{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Heating1{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Heating1{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Heating1{} S.Mchs{}:
      d1a_level(S.Fin{S.Heating1{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating1{}), S.Mchs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Heating1{} S.Dhs{}:
      d1a_level(S.Fin{S.Heating1{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating1{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Heating1{} S.BothHs{}:
      d1a_level(S.Fin{S.Heating1{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating1{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Heating1{} S.Blind{}:
      d1a_level(S.Fin{S.Heating1{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating1{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Heating2{} S.Slow{}:
      d1a_level(S.Fin{S.Heating2{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating2{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Heating2{} S.Fast{}:
      d1a_level(S.Fin{S.Heating2{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating2{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Heating2{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Heating2{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Heating2{} S.Mchs{}:
      d1a_level(S.Fin{S.Heating2{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating2{}), S.Mchs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Heating2{} S.Dhs{}:
      d1a_level(S.Fin{S.Heating2{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating2{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Heating2{} S.BothHs{}:
      d1a_level(S.Fin{S.Heating2{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating2{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Heating2{} S.Blind{}:
      d1a_level(S.Fin{S.Heating2{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating2{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Termination{} S.Slow{}:
      d1a_level(S.Fin{S.Termination{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Termination{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Termination{} S.Fast{}:
      d1a_level(S.Fin{S.Termination{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Termination{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Termination{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Termination{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LJtt{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LJtt{} S.Termination{} S.Mchs{}:
      d1a_level(S.Fin{S.Termination{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Termination{}), S.Mchs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Termination{} S.Dhs{}:
      d1a_level(S.Fin{S.Termination{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Termination{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Termination{} S.BothHs{}:
      d1a_level(S.Fin{S.Termination{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Termination{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LJtt{} S.Termination{} S.Blind{}:
      d1a_level(S.Fin{S.Termination{}, j, S.LJtt{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Termination{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Breakdown{} S.Slow{}:
      d1a_level(S.Fin{S.Breakdown{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Breakdown{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Breakdown{} S.Fast{}:
      d1a_level(S.Fin{S.Breakdown{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Breakdown{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Breakdown{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Breakdown{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Breakdown{} S.Mchs{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Breakdown{} S.Dhs{}:
      d1a_level(S.Fin{S.Breakdown{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Breakdown{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Breakdown{} S.BothHs{}:
      d1a_level(S.Fin{S.Breakdown{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Breakdown{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Breakdown{} S.Blind{}:
      d1a_level(S.Fin{S.Breakdown{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Breakdown{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.IpRise{} S.Slow{}:
      d1a_level(S.Fin{S.IpRise{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.IpRise{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.IpRise{} S.Fast{}:
      d1a_level(S.Fin{S.IpRise{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.IpRise{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.IpRise{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.IpRise{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.IpRise{} S.Mchs{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.IpRise{} S.Dhs{}:
      d1a_level(S.Fin{S.IpRise{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.IpRise{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.IpRise{} S.BothHs{}:
      d1a_level(S.Fin{S.IpRise{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.IpRise{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.IpRise{} S.Blind{}:
      d1a_level(S.Fin{S.IpRise{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.IpRise{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Limiter{} S.Slow{}:
      d1a_level(S.Fin{S.Limiter{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Limiter{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Limiter{} S.Fast{}:
      d1a_level(S.Fin{S.Limiter{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Limiter{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Limiter{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Limiter{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Limiter{} S.Mchs{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Limiter{} S.Dhs{}:
      d1a_level(S.Fin{S.Limiter{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Limiter{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Limiter{} S.BothHs{}:
      d1a_level(S.Fin{S.Limiter{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Limiter{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Limiter{} S.Blind{}:
      d1a_level(S.Fin{S.Limiter{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Limiter{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Xpoint{} S.Slow{}:
      d1a_level(S.Fin{S.Xpoint{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Xpoint{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Xpoint{} S.Fast{}:
      d1a_level(S.Fin{S.Xpoint{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Xpoint{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Xpoint{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Xpoint{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Xpoint{} S.Mchs{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Xpoint{} S.Dhs{}:
      d1a_level(S.Fin{S.Xpoint{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Xpoint{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Xpoint{} S.BothHs{}:
      d1a_level(S.Fin{S.Xpoint{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Xpoint{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Xpoint{} S.Blind{}:
      d1a_level(S.Fin{S.Xpoint{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Xpoint{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Heating1{} S.Slow{}:
      d1a_level(S.Fin{S.Heating1{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating1{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Heating1{} S.Fast{}:
      d1a_level(S.Fin{S.Heating1{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating1{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Heating1{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Heating1{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Heating1{} S.Mchs{}:
      d1a_level(S.Fin{S.Heating1{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating1{}), S.Mchs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Heating1{} S.Dhs{}:
      d1a_level(S.Fin{S.Heating1{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating1{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Heating1{} S.BothHs{}:
      d1a_level(S.Fin{S.Heating1{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating1{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Heating1{} S.Blind{}:
      d1a_level(S.Fin{S.Heating1{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating1{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Heating2{} S.Slow{}:
      d1a_level(S.Fin{S.Heating2{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating2{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Heating2{} S.Fast{}:
      d1a_level(S.Fin{S.Heating2{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating2{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Heating2{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Heating2{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Heating2{} S.Mchs{}:
      d1a_level(S.Fin{S.Heating2{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating2{}), S.Mchs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Heating2{} S.Dhs{}:
      d1a_level(S.Fin{S.Heating2{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating2{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Heating2{} S.BothHs{}:
      d1a_level(S.Fin{S.Heating2{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating2{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Heating2{} S.Blind{}:
      d1a_level(S.Fin{S.Heating2{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Heating2{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Termination{} S.Slow{}:
      d1a_level(S.Fin{S.Termination{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Termination{}), S.Slow{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Termination{} S.Fast{}:
      d1a_level(S.Fin{S.Termination{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Termination{}), S.Fast{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Termination{} S.Mhd{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Termination{} S.MhdB{}:
      clash_tf({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LRtps{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_cfg)
    case S.LRtps{} S.Termination{} S.Mchs{}:
      d1a_level(S.Fin{S.Termination{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Termination{}), S.Mchs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Termination{} S.Dhs{}:
      d1a_level(S.Fin{S.Termination{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Termination{}), S.Dhs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Termination{} S.BothHs{}:
      d1a_level(S.Fin{S.Termination{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Termination{}), S.BothHs{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LRtps{} S.Termination{} S.Blind{}:
      d1a_level(S.Fin{S.Termination{}, j, S.LRtps{}, d, pl, ip, nb, rf}, S.dms_req(S.wave_go(j, S.Termination{}), S.Blind{}), Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()))
    case S.LPtn{} S.Breakdown{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Breakdown{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Breakdown{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Breakdown{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Breakdown{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Breakdown{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Breakdown{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Breakdown{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Breakdown{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.IpRise{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.IpRise{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.IpRise{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.IpRise{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.IpRise{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.IpRise{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.IpRise{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.IpRise{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.IpRise{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Limiter{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Limiter{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Limiter{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Limiter{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Limiter{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Limiter{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Limiter{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Limiter{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Limiter{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Xpoint{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Xpoint{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Xpoint{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Xpoint{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Xpoint{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Xpoint{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Xpoint{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Xpoint{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Xpoint{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating1{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating1{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating1{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating1{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating1{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating1{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating1{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating1{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating1{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating2{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating2{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating2{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating2{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating2{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating2{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating2{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Heating2{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Heating2{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Termination{} S.Slow{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Slow{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Termination{} S.Fast{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Fast{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Termination{} S.Mhd{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mhd{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Termination{} S.MhdB{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.MhdB{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Termination{} S.Mchs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Mchs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Termination{} S.Dhs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Dhs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Termination{} S.BothHs{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.BothHs{}})))) == True{} : Bool}, h_soft)
    case S.LPtn{} S.Termination{} S.Blind{}:
      clash_ft({S.is_ptn(S.level_of(S.fin_of(S.step_c(S.Inst4{}, S.St{S.Fin{S.Termination{}, j, S.LPtn{}, d, pl, ip, nb, rf}, hb, tack}, S.XAlarm{S.Blind{}})))) == True{} : Bool}, h_soft)

def Laws.inst4_second_alarm_ptn(s, t, h_soft, h_cfg):
  match s:
    case S.St{S.Fin{p, +j, l, +d, +pl, +ip, +nb, +rf}, +hb, +tack}:
      i4_go(l, p, t, j, d, pl, ip, nb, rf, hb, tack, h_soft, h_cfg)

# ---------------------------------------------------------------------------
# V1: the verdict domain. Outside the Tick arm, step_fin, upd_hb and upd_tack do not read
# the verdicts at all -- each of the eleven remaining event constructors selects a branch
# that never mentions bt or bh, so the two sides are the same normal form and {==} closes
# it. The Tick case is refuted by the hypothesis is_tick(e) == False.
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
    case S.Ip{ok}:
      {==}
    case S.CommFault{dms, en}:
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
    case S.Ip{ok}:
      {==}
    case S.CommFault{dms, en}:
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
    case S.Ip{ok}:
      {==}
    case S.CommFault{dms, en}:
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
  Bool.and(E.cor_jtt(S.Heating2{}), E.cor_jtt(S.Termination{}))

def kf5() -> Bool:
  Bool.and(E.cor_jtt(S.Heating1{}), kf6())

def kf4() -> Bool:
  Bool.and(E.cor_jtt(S.Xpoint{}), kf5())

def kf3() -> Bool:
  Bool.and(E.cor_jtt(S.Limiter{}), kf4())

def kf2() -> Bool:
  Bool.and(E.cor_jtt(S.IpRise{}), kf3())

def cor_phase(p: S.Phase, h: {E.check_cor() == True{} : Bool}) -> {E.cor_jtt(p) == True{} : Bool}:
  match p:
    case S.Breakdown{}:
      and_l(E.cor_jtt(S.Breakdown{}), kf2(), h)
    case S.IpRise{}:
      and_l(E.cor_jtt(S.IpRise{}), kf3(), and_r(E.cor_jtt(S.Breakdown{}), kf2(), h))
    case S.Limiter{}:
      and_l(E.cor_jtt(S.Limiter{}), kf4(), and_r(E.cor_jtt(S.IpRise{}), kf3(), and_r(E.cor_jtt(S.Breakdown{}), kf2(), h)))
    case S.Xpoint{}:
      and_l(E.cor_jtt(S.Xpoint{}), kf5(), and_r(E.cor_jtt(S.Limiter{}), kf4(), and_r(E.cor_jtt(S.IpRise{}), kf3(), and_r(E.cor_jtt(S.Breakdown{}), kf2(), h))))
    case S.Heating1{}:
      and_l(E.cor_jtt(S.Heating1{}), kf6(), and_r(E.cor_jtt(S.Xpoint{}), kf5(), and_r(E.cor_jtt(S.Limiter{}), kf4(), and_r(E.cor_jtt(S.IpRise{}), kf3(), and_r(E.cor_jtt(S.Breakdown{}), kf2(), h)))))
    case S.Heating2{}:
      and_l(E.cor_jtt(S.Heating2{}), E.cor_jtt(S.Termination{}), and_r(E.cor_jtt(S.Heating1{}), kf6(), and_r(E.cor_jtt(S.Xpoint{}), kf5(), and_r(E.cor_jtt(S.Limiter{}), kf4(), and_r(E.cor_jtt(S.IpRise{}), kf3(), and_r(E.cor_jtt(S.Breakdown{}), kf2(), h))))))
    case S.Termination{}:
      and_r(E.cor_jtt(S.Heating2{}), E.cor_jtt(S.Termination{}), and_r(E.cor_jtt(S.Heating1{}), kf6(), and_r(E.cor_jtt(S.Xpoint{}), kf5(), and_r(E.cor_jtt(S.Limiter{}), kf4(), and_r(E.cor_jtt(S.IpRise{}), kf3(), and_r(E.cor_jtt(S.Breakdown{}), kf2(), h))))))

def cor_lvl_jtt(+p: S.Phase, j: Bool, h: {E.cor_jtt(p) == True{} : Bool}) -> {E.cor_level(p, j) == True{} : Bool}:
  match j:
    case False{}:
      and_l(E.cor_level(p, False{}), E.cor_level(p, True{}), h)
    case True{}:
      and_r(E.cor_level(p, False{}), E.cor_level(p, True{}), h)

def cor_lvl_level(+p: S.Phase, +j: Bool, l: S.Level, h: {E.cor_level(p, j) == True{} : Bool}) -> {E.cor_dms(p, j, l) == True{} : Bool}:
  match l:
    case S.LNone{}:
      and4_1(E.cor_dms(p, j, S.LNone{}), E.cor_dms(p, j, S.LJtt{}), E.cor_dms(p, j, S.LRtps{}), E.cor_dms(p, j, S.LPtn{}), h)
    case S.LJtt{}:
      and4_2(E.cor_dms(p, j, S.LNone{}), E.cor_dms(p, j, S.LJtt{}), E.cor_dms(p, j, S.LRtps{}), E.cor_dms(p, j, S.LPtn{}), h)
    case S.LRtps{}:
      and4_3(E.cor_dms(p, j, S.LNone{}), E.cor_dms(p, j, S.LJtt{}), E.cor_dms(p, j, S.LRtps{}), E.cor_dms(p, j, S.LPtn{}), h)
    case S.LPtn{}:
      and4_4(E.cor_dms(p, j, S.LNone{}), E.cor_dms(p, j, S.LJtt{}), E.cor_dms(p, j, S.LRtps{}), E.cor_dms(p, j, S.LPtn{}), h)

def cor_lvl_dms(+p: S.Phase, +j: Bool, +l: S.Level, d: S.Dms, h: {E.cor_dms(p, j, l) == True{} : Bool}) -> {E.cor_plasma(p, j, l, d) == True{} : Bool}:
  match d:
    case S.DmsIdle{}:
      and3_1(E.cor_plasma(p, j, l, S.DmsIdle{}), E.cor_plasma(p, j, l, S.DmsArmed{}), E.cor_plasma(p, j, l, S.DmsFired{}), h)
    case S.DmsArmed{}:
      and3_2(E.cor_plasma(p, j, l, S.DmsIdle{}), E.cor_plasma(p, j, l, S.DmsArmed{}), E.cor_plasma(p, j, l, S.DmsFired{}), h)
    case S.DmsFired{}:
      and3_3(E.cor_plasma(p, j, l, S.DmsIdle{}), E.cor_plasma(p, j, l, S.DmsArmed{}), E.cor_plasma(p, j, l, S.DmsFired{}), h)

def cor_lvl_plasma(+p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, pl: Bool, h: {E.cor_plasma(p, j, l, d) == True{} : Bool}) -> {E.cor_ip(p, j, l, d, pl) == True{} : Bool}:
  match pl:
    case True{}:
      and_l(E.cor_ip(p, j, l, d, True{}), E.cor_ip(p, j, l, d, False{}), h)
    case False{}:
      and_r(E.cor_ip(p, j, l, d, True{}), E.cor_ip(p, j, l, d, False{}), h)

def cor_lvl_ip(+p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, +pl: Bool, ip: Bool, h: {E.cor_ip(p, j, l, d, pl) == True{} : Bool}) -> {E.cor_nb(p, j, l, d, pl, ip) == True{} : Bool}:
  match ip:
    case True{}:
      and_l(E.cor_nb(p, j, l, d, pl, True{}), E.cor_nb(p, j, l, d, pl, False{}), h)
    case False{}:
      and_r(E.cor_nb(p, j, l, d, pl, True{}), E.cor_nb(p, j, l, d, pl, False{}), h)

def cor_lvl_nb(+p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, +pl: Bool, +ip: Bool, nb: S.Heat, h: {E.cor_nb(p, j, l, d, pl, ip) == True{} : Bool}) -> {E.cor_rf(p, j, l, d, pl, ip, nb) == True{} : Bool}:
  match nb:
    case S.Off{}:
      and4_1(E.cor_rf(p, j, l, d, pl, ip, S.Off{}), E.cor_rf(p, j, l, d, pl, ip, S.Ramping{}), E.cor_rf(p, j, l, d, pl, ip, S.Reduced{}), E.cor_rf(p, j, l, d, pl, ip, S.On{}), h)
    case S.Ramping{}:
      and4_2(E.cor_rf(p, j, l, d, pl, ip, S.Off{}), E.cor_rf(p, j, l, d, pl, ip, S.Ramping{}), E.cor_rf(p, j, l, d, pl, ip, S.Reduced{}), E.cor_rf(p, j, l, d, pl, ip, S.On{}), h)
    case S.Reduced{}:
      and4_3(E.cor_rf(p, j, l, d, pl, ip, S.Off{}), E.cor_rf(p, j, l, d, pl, ip, S.Ramping{}), E.cor_rf(p, j, l, d, pl, ip, S.Reduced{}), E.cor_rf(p, j, l, d, pl, ip, S.On{}), h)
    case S.On{}:
      and4_4(E.cor_rf(p, j, l, d, pl, ip, S.Off{}), E.cor_rf(p, j, l, d, pl, ip, S.Ramping{}), E.cor_rf(p, j, l, d, pl, ip, S.Reduced{}), E.cor_rf(p, j, l, d, pl, ip, S.On{}), h)

def cor_lvl_rf(+p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, +pl: Bool, +ip: Bool, +nb: S.Heat, rf: S.Heat, h: {E.cor_rf(p, j, l, d, pl, ip, nb) == True{} : Bool}) -> {E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, rf}) == True{} : Bool}:
  match rf:
    case S.Off{}:
      and4_1(E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Off{}}), E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Ramping{}}), E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Reduced{}}), E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.On{}}), h)
    case S.Ramping{}:
      and4_2(E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Off{}}), E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Ramping{}}), E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Reduced{}}), E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.On{}}), h)
    case S.Reduced{}:
      and4_3(E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Off{}}), E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Ramping{}}), E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Reduced{}}), E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.On{}}), h)
    case S.On{}:
      and4_4(E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Off{}}), E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Ramping{}}), E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Reduced{}}), E.cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.On{}}), h)

# every control state satisfies cor_at
def cor_cell(f: S.Fin) -> {E.cor_at(f) == True{} : Bool}:
  match f:
    case S.Fin{+p, +j, +l, +d, +pl, +ip, +nb, +rf}:
      cor_lvl_rf(p, j, l, d, pl, ip, nb, rf, cor_lvl_nb(p, j, l, d, pl, ip, nb, cor_lvl_ip(p, j, l, d, pl, ip,
        cor_lvl_plasma(p, j, l, d, pl, cor_lvl_dms(p, j, l, d, cor_lvl_level(p, j, l,
          cor_lvl_jtt(p, j, cor_phase(p, Laws.corollaries_check()))))))))

# the four consequents of cor_at
def k1(+f: S.Fin) -> Bool:
  S.implies(S.is_ptn(S.level_of(f)), Bool.and(S.unpowered(S.nb_of(f)), S.unpowered(S.rf_of(f))))

def k2(+f: S.Fin) -> Bool:
  S.implies(Bool.not(S.is_idle(S.dms_of(f))), Bool.and(S.unpowered(S.nb_of(f)), S.unpowered(S.rf_of(f))))

def k3(+f: S.Fin) -> Bool:
  S.implies(Bool.not(S.is_none(S.level_of(f))), Bool.and(Bool.not(S.is_hot(S.nb_of(f))), Bool.not(S.is_hot(S.rf_of(f)))))

def k4(+f: S.Fin) -> Bool:
  S.implies(S.is_term(S.wave_of(f)), Bool.and(Bool.not(S.is_hot(S.nb_of(f))), Bool.not(S.is_hot(S.rf_of(f)))))

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
