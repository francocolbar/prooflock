# enum_jetprot.bend - the finite certificate of jetprot.bend, written as NESTED FIRST-ORDER
# checks so that PROOF_JETPROT.bend can turn "check_fin(o) == True" into universal
# statements with one small lemma per quantifier level (reflection).
#
# One cell = (order, control state, abstract event, verdicts). The next control state is
# computed ONCE per cell and every property is evaluated on it (docs/phase3-design.md C1).
# The counter verdicts (bt, bh) only reach the Tick arm of step_fin, so the certificate
# enumerates them for Tick, and for the three events whose counter command is a
# reset_if(...) on a guard of the state (Reset, CommFault{True, True}, Stop{LPtn, True}):
# there the checker cannot discharge the verdicts symbolically in PROOF_JETPROT.bend, so the
# cell is certified at all four verdict pairs. 10 752 states x (23 + 5 x 4) = 462 336 cells
# per order. That the other 23 columns may be certified at (True, True) alone is not an
# assumption: it is the law `verdict_frame_step` / `_hb` / `_tack` of LAWS_JETPROT.bend (V1),
# which says that outside the Tick arm neither the step nor either counter command reads a
# verdict.
#
# Revision 2026-09-21 (blocker 4): eight control fields (7 x 2 x 4 x 3 x 2 x 2 x 4 x 4), the
# events Ip{ok} and CommFault{dms, en}, the property group g_f (F1/F2/F3/IP), and the
# concrete-layer check over three instances x program phase x waveform flag.
# Revision 4 (2026-09-22): the group g_j of the named PTN/primary-stop laws; the concrete-layer
# check gains the fourth instance, the secondary table (m_sec) and a level axis (whether a stop
# is in force).

import Base
import ./jetprot.bend as S
import ./spec_jetprot.bend as Spec

# ---------------------------------------------------------------------------
# The property of one cell, in seven named groups (for the projections in the proof)
# ---------------------------------------------------------------------------

# preservation of the control invariant and the two counter shapes
def g_pres(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_pres(f, f2), Bool.and(Spec.pr_hb(f, e, bh, f2), Spec.pr_tack(f, e, bt, bh, f2)))

# P1..P4
def g_a(+o: S.Ord, +f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p1(o, f, e, f2), Bool.and(Spec.pr_p2(f, f2), Bool.and(Spec.pr_p3(f, f2), Spec.pr_p4(f, e, f2))))

# P5, P6, P7, P9
def g_b(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p5(f, e, f2), Bool.and(Spec.pr_p6(f, f2), Bool.and(Spec.pr_p7(f, e, f2), Spec.pr_p9(f, e, bt, bh, f2))))

# P10, P12, P14..P21
def g_c(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p10(f, e, bh, f2), Bool.and(Spec.pr_p12(e, f2), Bool.and(Spec.pr_p14(f, e, f2), Bool.and(Spec.pr_p15(f, e, f2),
  Bool.and(Spec.pr_p16(f, e, bh, f2), Bool.and(Spec.pr_p17(f, e, bh, f2), Bool.and(Spec.pr_p18(f, e, bt, bh),
  Bool.and(Spec.pr_p19(f, e, bt, bh, f2), Bool.and(Spec.pr_p20(f, e, bt, bh, f2), Spec.pr_p21(f, e, bt, bh, f2))))))))))

# D1..D18 (demand and frame): the sequencer does its job, and nothing else moves
def g_d(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_d1(o, f, e, f2), Bool.and(Spec.pr_d2(o, f, e, f2), Bool.and(Spec.pr_d3(f, e, f2),
  Bool.and(Spec.pr_d4(f, e, bh, f2), Bool.and(Spec.pr_d5(f, e, bh), Bool.and(Spec.pr_d6(f, e, bh),
  Bool.and(Spec.pr_d7(f, e, bt, f2), Bool.and(Spec.pr_d8(f, e, bt, bh), Bool.and(Spec.pr_d9(f, e, f2),
  Bool.and(Spec.pr_d10(f, e, bt, bh, f2), Bool.and(Spec.pr_d11(f, e, f2), Bool.and(Spec.pr_d12(f, e, f2),
  Bool.and(Spec.pr_d13(e, f2), Bool.and(Spec.pr_d14(f, e, f2), Bool.and(Spec.pr_d15(f, e, bt, bh, f2),
  Bool.and(Spec.pr_d16(f, e, bt, bh, f2), Bool.and(Spec.pr_d17(f, e, bt, bh, f2), Spec.pr_d18(f, e, bt, bh, f2))))))))))))))))))

# E2..E11 (audit #5): the holes D1..D18 still left open
def g_e(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_e2(f, e, bt, f2), Bool.and(Spec.pr_e3(o, f, e, f2), Bool.and(Spec.pr_e4(f, e, f2),
  Bool.and(Spec.pr_e5(f, e, bh), Bool.and(Spec.pr_e6(f, e, bh), Bool.and(Spec.pr_e7(f, e, bt, bh),
  Bool.and(Spec.pr_e8(f, e, bt, bh), Spec.pr_e11(f, e, f2))))))))

# P1a, P1b, D1a, D1b, PIW-after-PTN (revision 4): what P1 and D1 say about the PTN and the primary
# stop ([N1]), named (D1a, P1b and PIW-after-PTN add our formalisation: A-9, A-14);
# P1a..D1b are DERIVED from P1, D1, P2 and the frame laws; PIW-after-PTN also pins both counter
# commands of a non-PTN Stop under a latched PTN, which no earlier law did
def g_j(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_p1a(f, e, f2), Bool.and(Spec.pr_p1b(f, e, f2), Bool.and(Spec.pr_d1a(e, f2),
  Bool.and(Spec.pr_d1b(f, e, f2), Spec.pr_piw_noop(f, e, bt, bh, f2)))))

# F1b, F1d, F1e, F2a, F2d, F3b, F4, IP1, IP3, IP4 (blocker 4: fidelity and the frames it needed),
# then the group g_j of the named PTN/primary-stop laws (revision 4)
def g_f(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(Spec.pr_f1b(f, e, f2), Bool.and(Spec.pr_f1d(f, e, f2), Bool.and(Spec.pr_f1e(o, f, e, f2), Bool.and(Spec.pr_f2a(f, e, f2),
  Bool.and(Spec.pr_f2d(f, e, f2), Bool.and(Spec.pr_f3b(f, e, bt, bh, f2), Bool.and(Spec.pr_f4(f, e, f2),
  Bool.and(Spec.pr_ip1(f, f2), Bool.and(Spec.pr_ip3(e, f2), Bool.and(Spec.pr_ip4(f, e, f2), g_j(f, e, bt, bh, f2)))))))))))

def prop_at(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(g_pres(f, e, bt, bh, f2), Bool.and(g_a(o, f, e, f2), Bool.and(g_b(f, e, bt, bh, f2),
  Bool.and(g_c(f, e, bt, bh, f2), Bool.and(g_d(o, f, e, bt, bh, f2), Bool.and(g_e(o, f, e, bt, bh, f2), g_f(o, f, e, bt, bh, f2)))))))

# the next control state is computed once per cell
def prop(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> Bool:
  prop_at(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh))

# ---------------------------------------------------------------------------
# Quantifier levels (each is a conjunction over one constructor set)
# ---------------------------------------------------------------------------

# verdicts: enumerated for Tick, Reset, CommFault{True, True}, Stop{LPtn, True}; fixed
# (True, True) for the events whose commands the proof reduces symbolically
def all_bh(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool) -> Bool:
  Bool.and(prop(o, f, e, bt, True{}), prop(o, f, e, bt, False{}))

def all_bt(+o: S.Ord, +f: S.Fin, +e: S.Ev) -> Bool:
  Bool.and(all_bh(o, f, e, True{}), all_bh(o, f, e, False{}))

def one(+o: S.Ord, +f: S.Fin, e: S.Ev) -> Bool:
  prop(o, f, e, True{}, True{})

# the 28 event variants in 14 pairs
def ev_g1(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.Advance{}), one(o, f, S.Heartbeat{}))

def ev_g2(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.HeatAck{}), all_bt(o, f, S.Reset{}))

def ev_g3(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.Local{S.Nb{}}), one(o, f, S.Local{S.Rf{}}))

def ev_g4(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.HeatOn{S.Nb{}}), one(o, f, S.HeatOn{S.Rf{}}))

def ev_g5(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.HeatOff{S.Nb{}}), one(o, f, S.HeatOff{S.Rf{}}))

def ev_g6(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.Plasma{True{}}), one(o, f, S.Plasma{False{}}))

def ev_g7(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.Ip{True{}}), one(o, f, S.Ip{False{}}))

def ev_g8(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(all_bt(o, f, S.CommFault{True{}, True{}}), one(o, f, S.CommFault{True{}, False{}}))

def ev_g9(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.CommFault{False{}, True{}}), one(o, f, S.CommFault{False{}, False{}}))

def ev_g10(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(all_bt(o, f, S.Tick{True{}}), all_bt(o, f, S.Tick{False{}}))

def ev_g11(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.Stop{S.LNone{}, True{}}), one(o, f, S.Stop{S.LNone{}, False{}}))

def ev_g12(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.Stop{S.LJtt{}, True{}}), one(o, f, S.Stop{S.LJtt{}, False{}}))

def ev_g13(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.Stop{S.LRtps{}, True{}}), one(o, f, S.Stop{S.LRtps{}, False{}}))

def ev_g14(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(all_bt(o, f, S.Stop{S.LPtn{}, True{}}), one(o, f, S.Stop{S.LPtn{}, False{}}))

def ev_q1(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(Bool.and(ev_g1(o, f), ev_g2(o, f)), Bool.and(ev_g3(o, f), ev_g4(o, f)))

def ev_q2(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(Bool.and(ev_g5(o, f), ev_g6(o, f)), Bool.and(ev_g7(o, f), ev_g8(o, f)))

def ev_q3(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(Bool.and(ev_g9(o, f), ev_g10(o, f)), Bool.and(ev_g11(o, f), ev_g12(o, f)))

def ev_q4(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(ev_g13(o, f), ev_g14(o, f))

def all_ev(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(ev_q1(o, f), Bool.and(ev_q2(o, f), Bool.and(ev_q3(o, f), ev_q4(o, f))))

# the control fields, innermost first: rf, nb, ip, plasma, dms, level, jtt, prog
def all_rf(+o: S.Ord, +p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, +pl: Bool, +ip: Bool, +nb: S.Heat) -> Bool:
  Bool.and(Bool.and(all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Off{}}), all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Ramping{}})),
           Bool.and(all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.Reduced{}}), all_ev(o, S.Fin{p, j, l, d, pl, ip, nb, S.On{}})))

def all_nb(+o: S.Ord, +p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, +pl: Bool, +ip: Bool) -> Bool:
  Bool.and(Bool.and(all_rf(o, p, j, l, d, pl, ip, S.Off{}), all_rf(o, p, j, l, d, pl, ip, S.Ramping{})),
           Bool.and(all_rf(o, p, j, l, d, pl, ip, S.Reduced{}), all_rf(o, p, j, l, d, pl, ip, S.On{})))

def all_ip(+o: S.Ord, +p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, +pl: Bool) -> Bool:
  Bool.and(all_nb(o, p, j, l, d, pl, True{}), all_nb(o, p, j, l, d, pl, False{}))

def all_plasma(+o: S.Ord, +p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms) -> Bool:
  Bool.and(all_ip(o, p, j, l, d, True{}), all_ip(o, p, j, l, d, False{}))

def all_dms(+o: S.Ord, +p: S.Phase, +j: Bool, +l: S.Level) -> Bool:
  Bool.and(all_plasma(o, p, j, l, S.DmsIdle{}), Bool.and(all_plasma(o, p, j, l, S.DmsArmed{}), all_plasma(o, p, j, l, S.DmsFired{})))

def all_level(+o: S.Ord, +p: S.Phase, +j: Bool) -> Bool:
  Bool.and(Bool.and(all_dms(o, p, j, S.LNone{}), all_dms(o, p, j, S.LJtt{})),
           Bool.and(all_dms(o, p, j, S.LRtps{}), all_dms(o, p, j, S.LPtn{})))

def all_jtt(+o: S.Ord, +p: S.Phase) -> Bool:
  Bool.and(all_level(o, p, False{}), all_level(o, p, True{}))

# the seven program phases: 10 752 control states x 43 columns, for one order
def check_fin(+o: S.Ord) -> Bool:
  Bool.and(all_jtt(o, S.Breakdown{}), Bool.and(all_jtt(o, S.IpRise{}), Bool.and(all_jtt(o, S.Limiter{}),
  Bool.and(all_jtt(o, S.Xpoint{}), Bool.and(all_jtt(o, S.Heating1{}), Bool.and(all_jtt(o, S.Heating2{}),
           all_jtt(o, S.Termination{})))))))

# ---------------------------------------------------------------------------
# The state corollaries (docs/phase3-design.md §2): under inv_fin, PTN and an armed/fired
# DMS leave no unit powered, a stop leaves no unit delivering power (full or partial), and so
# does the termination waveform. 10 752 control states, one level per field.
# ---------------------------------------------------------------------------

def cor_at(+f: S.Fin) -> Bool:
  S.implies(S.inv_fin(f),
    Bool.and(S.implies(S.is_ptn(S.level_of(f)), Bool.and(S.unpowered(S.nb_of(f)), S.unpowered(S.rf_of(f)))),
    Bool.and(S.implies(Bool.not(S.is_idle(S.dms_of(f))), Bool.and(S.unpowered(S.nb_of(f)), S.unpowered(S.rf_of(f)))),
    Bool.and(S.implies(Bool.not(S.is_none(S.level_of(f))), Bool.and(Bool.not(S.is_hot(S.nb_of(f))), Bool.not(S.is_hot(S.rf_of(f))))),
             S.implies(S.is_term(S.wave_of(f)), Bool.and(Bool.not(S.is_hot(S.nb_of(f))), Bool.not(S.is_hot(S.rf_of(f)))))))))

def cor_rf(+p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, +pl: Bool, +ip: Bool, +nb: S.Heat) -> Bool:
  Bool.and(Bool.and(cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Off{}}), cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Ramping{}})),
           Bool.and(cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.Reduced{}}), cor_at(S.Fin{p, j, l, d, pl, ip, nb, S.On{}})))

def cor_nb(+p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, +pl: Bool, +ip: Bool) -> Bool:
  Bool.and(Bool.and(cor_rf(p, j, l, d, pl, ip, S.Off{}), cor_rf(p, j, l, d, pl, ip, S.Ramping{})),
           Bool.and(cor_rf(p, j, l, d, pl, ip, S.Reduced{}), cor_rf(p, j, l, d, pl, ip, S.On{})))

def cor_ip(+p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms, +pl: Bool) -> Bool:
  Bool.and(cor_nb(p, j, l, d, pl, True{}), cor_nb(p, j, l, d, pl, False{}))

def cor_plasma(+p: S.Phase, +j: Bool, +l: S.Level, +d: S.Dms) -> Bool:
  Bool.and(cor_ip(p, j, l, d, True{}), cor_ip(p, j, l, d, False{}))

def cor_dms(+p: S.Phase, +j: Bool, +l: S.Level) -> Bool:
  Bool.and(cor_plasma(p, j, l, S.DmsIdle{}), Bool.and(cor_plasma(p, j, l, S.DmsArmed{}), cor_plasma(p, j, l, S.DmsFired{})))

def cor_level(+p: S.Phase, +j: Bool) -> Bool:
  Bool.and(Bool.and(cor_dms(p, j, S.LNone{}), cor_dms(p, j, S.LJtt{})), Bool.and(cor_dms(p, j, S.LRtps{}), cor_dms(p, j, S.LPtn{})))

def cor_jtt(+p: S.Phase) -> Bool:
  Bool.and(cor_level(p, False{}), cor_level(p, True{}))

def check_cor() -> Bool:
  Bool.and(cor_jtt(S.Breakdown{}), Bool.and(cor_jtt(S.IpRise{}), Bool.and(cor_jtt(S.Limiter{}),
  Bool.and(cor_jtt(S.Xpoint{}), Bool.and(cor_jtt(S.Heating1{}), Bool.and(cor_jtt(S.Heating2{}),
           cor_jtt(S.Termination{})))))))

# ---------------------------------------------------------------------------
# The concrete layer under law: `concretize` must be exactly the table lookup, the masks and
# the constructor wiring. Nothing in the certificate above constrains it, so a mis-wired column
# (XAlarm{Dhs} reading the MCHS column), a mis-wired constructor (XHeatOn -> HeatOff), a table
# read on the WAVEFORM phase instead of the program phase (F1a), or an ignored mask (F3) would
# be invisible to every law. Which phase the table is read at is HYP A-24 (our reading: the
# programme phase, advancing also during a soft stop, A-30); m_alarm below pins that reading.
# Revision 4: an alarm with a stop in force reads the instance's SECONDARY table (m_sec), so the
# check also runs over the level in force. 4 instances x 7 program phases x 2 waveform flags x
# 4 levels x 24 concrete events = 5 376 cells.
# ---------------------------------------------------------------------------

def ev_tag(e: S.Ev) -> Nat:
  match e:
    case S.Advance{}:
      0n
    case S.Stop{req, dms}:
      1n
    case S.Local{u}:
      2n
    case S.HeatOn{u}:
      3n
    case S.HeatOff{u}:
      4n
    case S.Plasma{ok}:
      5n
    case S.Ip{ok}:
      6n
    case S.CommFault{dms, en}:
      7n
    case S.Heartbeat{}:
      8n
    case S.Tick{dms}:
      9n
    case S.HeatAck{}:
      10n
    case S.Reset{}:
      11n

def ev_lvl(e: S.Ev) -> S.Level:
  match e:
    case S.Stop{req, dms}:
      req
    case _:
      S.LNone{}

def ev_bit(e: S.Ev) -> Bool:
  match e:
    case S.Stop{req, dms}:
      dms
    case S.Plasma{ok}:
      ok
    case S.Ip{ok}:
      ok
    case S.CommFault{dms, en}:
      dms
    case S.Tick{dms}:
      dms
    case _:
      False{}

def ev_bit2(e: S.Ev) -> Bool:
  match e:
    case S.CommFault{dms, en}:
      en
    case _:
      False{}

def ev_who(e: S.Ev) -> S.Who:
  match e:
    case S.Local{u}:
      u
    case S.HeatOn{u}:
      u
    case S.HeatOff{u}:
      u
    case _:
      S.Nb{}

def ev_eq(+a: S.Ev, +b: S.Ev) -> Bool:
  Bool.and(Nat.is_eq(ev_tag(a), ev_tag(b)),
  Bool.and(Spec.lvl_eq(ev_lvl(a), ev_lvl(b)),
  Bool.and(Spec.beq(ev_bit(a), ev_bit(b)),
  Bool.and(Spec.beq(ev_bit2(a), ev_bit2(b)), Spec.who_eq(ev_who(a), ev_who(b))))))

# The configuration, transcribed a FOURTH time as its own function, so that the concrete-layer
# check stops being self-referential: conc_expected used to build its expectation from the very
# S.table / S.dms_req that concretize calls, so it detected a mis-wired constructor or column but
# NOT a wrong table value and NOT a wrong DMS window (audit #5 section 4). Below are two matrices of
# 7 phases x 8 triggers of R-5 + A-4 + A-25 written out cell by cell (m_table1, read by instances
# 1, 3 and 4; m_table2, instance 2), the
# DMS wiring is the trigger set {Fast, Mhd, MhdB} and the window {Xpoint .. Termination} as
# two independent predicates, and the masks are two predicates on the instance. Nothing here
# mentions jetprot's own tables or masks.

# instance 1 (Table 1 of [S1] as published, R-5, plus the assumed cells of A-4 and the blind row of A-25)
def m_table1(p: S.Phase, t: S.Trig) -> S.Level:
  match p t:
    case S.Breakdown{} S.Slow{}:
      S.LPtn{}
    case S.Breakdown{} S.Fast{}:
      S.LPtn{}
    case S.Breakdown{} S.Mhd{}:
      S.LNone{}
    case S.Breakdown{} S.MhdB{}:
      S.LNone{}
    case S.Breakdown{} S.Mchs{}:
      S.LNone{}
    case S.Breakdown{} S.Dhs{}:
      S.LPtn{}
    case S.Breakdown{} S.BothHs{}:
      S.LPtn{}
    case S.Breakdown{} S.Blind{}:
      S.LPtn{}
    case S.IpRise{} S.Slow{}:
      S.LPtn{}
    case S.IpRise{} S.Fast{}:
      S.LPtn{}
    case S.IpRise{} S.Mhd{}:
      S.LNone{}
    case S.IpRise{} S.MhdB{}:
      S.LNone{}
    case S.IpRise{} S.Mchs{}:
      S.LNone{}
    case S.IpRise{} S.Dhs{}:
      S.LPtn{}
    case S.IpRise{} S.BothHs{}:
      S.LPtn{}
    case S.IpRise{} S.Blind{}:
      S.LPtn{}
    case S.Limiter{} S.Slow{}:
      S.LPtn{}
    case S.Limiter{} S.Fast{}:
      S.LPtn{}
    case S.Limiter{} S.Mhd{}:
      S.LNone{}
    case S.Limiter{} S.MhdB{}:
      S.LNone{}
    case S.Limiter{} S.Mchs{}:
      S.LNone{}
    case S.Limiter{} S.Dhs{}:
      S.LPtn{}
    case S.Limiter{} S.BothHs{}:
      S.LPtn{}
    case S.Limiter{} S.Blind{}:
      S.LPtn{}
    case S.Xpoint{} S.Slow{}:
      S.LPtn{}
    case S.Xpoint{} S.Fast{}:
      S.LPtn{}
    case S.Xpoint{} S.Mhd{}:
      S.LNone{}
    case S.Xpoint{} S.MhdB{}:
      S.LNone{}
    case S.Xpoint{} S.Mchs{}:
      S.LNone{}
    case S.Xpoint{} S.Dhs{}:
      S.LPtn{}
    case S.Xpoint{} S.BothHs{}:
      S.LPtn{}
    case S.Xpoint{} S.Blind{}:
      S.LPtn{}
    case S.Heating1{} S.Slow{}:
      S.LRtps{}
    case S.Heating1{} S.Fast{}:
      S.LPtn{}
    case S.Heating1{} S.Mhd{}:
      S.LNone{}
    case S.Heating1{} S.MhdB{}:
      S.LNone{}
    case S.Heating1{} S.Mchs{}:
      S.LRtps{}
    case S.Heating1{} S.Dhs{}:
      S.LPtn{}
    case S.Heating1{} S.BothHs{}:
      S.LPtn{}
    case S.Heating1{} S.Blind{}:
      S.LPtn{}
    case S.Heating2{} S.Slow{}:
      S.LRtps{}
    case S.Heating2{} S.Fast{}:
      S.LPtn{}
    case S.Heating2{} S.Mhd{}:
      S.LNone{}
    case S.Heating2{} S.MhdB{}:
      S.LNone{}
    case S.Heating2{} S.Mchs{}:
      S.LRtps{}
    case S.Heating2{} S.Dhs{}:
      S.LJtt{}
    case S.Heating2{} S.BothHs{}:
      S.LRtps{}
    case S.Heating2{} S.Blind{}:
      S.LPtn{}
    case S.Termination{} S.Slow{}:
      S.LPtn{}
    case S.Termination{} S.Fast{}:
      S.LPtn{}
    case S.Termination{} S.Mhd{}:
      S.LNone{}
    case S.Termination{} S.MhdB{}:
      S.LNone{}
    case S.Termination{} S.Mchs{}:
      S.LPtn{}
    case S.Termination{} S.Dhs{}:
      S.LPtn{}
    case S.Termination{} S.BothHs{}:
      S.LPtn{}
    case S.Termination{} S.Blind{}:
      S.LPtn{}

# instance 2 (the MHD triggers routed to the PTN from X-point on, [S6]/[S7])
def m_table2(p: S.Phase, t: S.Trig) -> S.Level:
  match p t:
    case S.Breakdown{} S.Slow{}:
      S.LPtn{}
    case S.Breakdown{} S.Fast{}:
      S.LPtn{}
    case S.Breakdown{} S.Mhd{}:
      S.LNone{}
    case S.Breakdown{} S.MhdB{}:
      S.LNone{}
    case S.Breakdown{} S.Mchs{}:
      S.LNone{}
    case S.Breakdown{} S.Dhs{}:
      S.LPtn{}
    case S.Breakdown{} S.BothHs{}:
      S.LPtn{}
    case S.Breakdown{} S.Blind{}:
      S.LPtn{}
    case S.IpRise{} S.Slow{}:
      S.LPtn{}
    case S.IpRise{} S.Fast{}:
      S.LPtn{}
    case S.IpRise{} S.Mhd{}:
      S.LNone{}
    case S.IpRise{} S.MhdB{}:
      S.LNone{}
    case S.IpRise{} S.Mchs{}:
      S.LNone{}
    case S.IpRise{} S.Dhs{}:
      S.LPtn{}
    case S.IpRise{} S.BothHs{}:
      S.LPtn{}
    case S.IpRise{} S.Blind{}:
      S.LPtn{}
    case S.Limiter{} S.Slow{}:
      S.LPtn{}
    case S.Limiter{} S.Fast{}:
      S.LPtn{}
    case S.Limiter{} S.Mhd{}:
      S.LNone{}
    case S.Limiter{} S.MhdB{}:
      S.LNone{}
    case S.Limiter{} S.Mchs{}:
      S.LNone{}
    case S.Limiter{} S.Dhs{}:
      S.LPtn{}
    case S.Limiter{} S.BothHs{}:
      S.LPtn{}
    case S.Limiter{} S.Blind{}:
      S.LPtn{}
    case S.Xpoint{} S.Slow{}:
      S.LPtn{}
    case S.Xpoint{} S.Fast{}:
      S.LPtn{}
    case S.Xpoint{} S.Mhd{}:
      S.LPtn{}
    case S.Xpoint{} S.MhdB{}:
      S.LPtn{}
    case S.Xpoint{} S.Mchs{}:
      S.LNone{}
    case S.Xpoint{} S.Dhs{}:
      S.LPtn{}
    case S.Xpoint{} S.BothHs{}:
      S.LPtn{}
    case S.Xpoint{} S.Blind{}:
      S.LPtn{}
    case S.Heating1{} S.Slow{}:
      S.LRtps{}
    case S.Heating1{} S.Fast{}:
      S.LPtn{}
    case S.Heating1{} S.Mhd{}:
      S.LPtn{}
    case S.Heating1{} S.MhdB{}:
      S.LPtn{}
    case S.Heating1{} S.Mchs{}:
      S.LRtps{}
    case S.Heating1{} S.Dhs{}:
      S.LPtn{}
    case S.Heating1{} S.BothHs{}:
      S.LPtn{}
    case S.Heating1{} S.Blind{}:
      S.LPtn{}
    case S.Heating2{} S.Slow{}:
      S.LRtps{}
    case S.Heating2{} S.Fast{}:
      S.LPtn{}
    case S.Heating2{} S.Mhd{}:
      S.LPtn{}
    case S.Heating2{} S.MhdB{}:
      S.LPtn{}
    case S.Heating2{} S.Mchs{}:
      S.LRtps{}
    case S.Heating2{} S.Dhs{}:
      S.LJtt{}
    case S.Heating2{} S.BothHs{}:
      S.LRtps{}
    case S.Heating2{} S.Blind{}:
      S.LPtn{}
    case S.Termination{} S.Slow{}:
      S.LPtn{}
    case S.Termination{} S.Fast{}:
      S.LPtn{}
    case S.Termination{} S.Mhd{}:
      S.LPtn{}
    case S.Termination{} S.MhdB{}:
      S.LPtn{}
    case S.Termination{} S.Mchs{}:
      S.LPtn{}
    case S.Termination{} S.Dhs{}:
      S.LPtn{}
    case S.Termination{} S.BothHs{}:
      S.LPtn{}
    case S.Termination{} S.Blind{}:
      S.LPtn{}

# instance 3 reads the published matrix (instance 1) with both reliability checks masked out;
# instance 4 reads it with both checks on (it differs from instance 1 in its secondary table only)
def m_table(i: S.Inst, p: S.Phase, t: S.Trig) -> S.Level:
  match i:
    case S.Inst1{}:
      m_table1(p, t)
    case S.Inst2{}:
      m_table2(p, t)
    case S.Inst3{}:
      m_table1(p, t)
    case S.Inst4{}:
      m_table1(p, t)

# the triggers wired to the DMS (A-10), as a set
def m_trig(t: S.Trig) -> Bool:
  match t:
    case S.Fast{}:
      True{}
    case S.Mhd{}:
      True{}
    case S.MhdB{}:
      True{}
    case S.Slow{}:
      False{}
    case S.Mchs{}:
      False{}
    case S.Dhs{}:
      False{}
    case S.BothHs{}:
      False{}
    case S.Blind{}:
      False{}

# the DMV enable window (R-14), as a set, read on the waveform phase
def m_win(p: S.Phase) -> Bool:
  match p:
    case S.Breakdown{}:
      False{}
    case S.IpRise{}:
      False{}
    case S.Limiter{}:
      False{}
    case S.Xpoint{}:
      True{}
    case S.Heating1{}:
      True{}
    case S.Heating2{}:
      True{}
    case S.Termination{}:
      True{}

# the masks (R-13, A-21): communication check / blind alarms enabled
def m_comm(i: S.Inst) -> Bool:
  match i:
    case S.Inst1{}:
      True{}
    case S.Inst2{}:
      True{}
    case S.Inst3{}:
      False{}
    case S.Inst4{}:
      True{}

def m_blind(i: S.Inst) -> Bool:
  match i:
    case S.Inst1{}:
      True{}
    case S.Inst2{}:
      True{}
    case S.Inst3{}:
      False{}
    case S.Inst4{}:
      True{}

# the row a blind alarm reads: its table row when enabled, no response when masked
def m_blind_row(en: Bool, i: S.Inst, p: S.Phase) -> S.Level:
  match en:
    case True{}:
      m_table(i, p, S.Blind{})
    case False{}:
      S.LNone{}

def m_alarm(+i: S.Inst, p: S.Phase, t: S.Trig) -> S.Level:
  match t:
    case S.Blind{}:
      m_blind_row(m_blind(i), i, p)
    case t2:
      m_table(i, p, t2)

# the secondary stop response (revision 4), from the rule and independently of jetprot's
# sec_table: instances 1-3 ask again for their primary entry (the reading of revisions 1-3);
# instance 4 (ILLUSTRATIVE, A-35) asks for the PTN wherever its primary entry asks for anything
def m_sec_of(l: S.Level) -> S.Level:
  match l:
    case S.LNone{}:
      S.LNone{}
    case S.LJtt{}:
      S.LPtn{}
    case S.LRtps{}:
      S.LPtn{}
    case S.LPtn{}:
      S.LPtn{}

def m_sec(+i: S.Inst, +p: S.Phase, +t: S.Trig) -> S.Level:
  match i:
    case S.Inst1{}:
      m_alarm(S.Inst1{}, p, t)
    case S.Inst2{}:
      m_alarm(S.Inst2{}, p, t)
    case S.Inst3{}:
      m_alarm(S.Inst3{}, p, t)
    case S.Inst4{}:
      m_sec_of(m_alarm(S.Inst4{}, p, t))

# no stop in force (the expectation's own copy of is_none)
def m_is_none(l: S.Level) -> Bool:
  match l:
    case S.LNone{}:
      True{}
    case S.LJtt{}:
      False{}
    case S.LRtps{}:
      False{}
    case S.LPtn{}:
      False{}

# the request of a concrete alarm: the primary table with no stop in force, the secondary one otherwise
def m_pick(none: Bool, +i: S.Inst, +p: S.Phase, +t: S.Trig) -> S.Level:
  match none:
    case True{}:
      m_alarm(i, p, t)
    case False{}:
      m_sec(i, p, t)

# the waveform phase of a state with program phase p and flag j (the expectation's own copy)
def m_wave(j: Bool, p: S.Phase) -> S.Phase:
  match j:
    case True{}:
      S.Termination{}
    case False{}:
      p

# the wiring, restated independently of concretize() AND of table()/dms_req()/mask_of()
def conc_expected(+i: S.Inst, +p: S.Phase, +j: Bool, +l: S.Level, c: S.CEv) -> S.Ev:
  match c:
    case S.XAdvance{}:
      S.Advance{}
    case S.XAlarm{+t}:
      S.Stop{m_pick(m_is_none(l), i, p, t), Bool.and(m_trig(t), m_win(m_wave(j, p)))}
    case S.XLocal{u}:
      S.Local{u}
    case S.XHeatOn{u}:
      S.HeatOn{u}
    case S.XHeatOff{u}:
      S.HeatOff{u}
    case S.XPlasma{ok}:
      S.Plasma{ok}
    case S.XIp{ok}:
      S.Ip{ok}
    case S.XCommFault{}:
      S.CommFault{False{}, m_comm(i)}
    case S.XHeartbeat{}:
      S.Heartbeat{}
    case S.XTick{}:
      S.Tick{False{}}
    case S.XHeatAck{}:
      S.HeatAck{}
    case S.XReset{}:
      S.Reset{}

# the state concretize reads: the program phase, the waveform flag and the level in force (which
# table an alarm reads, revision 4); the other fields are fixed (the law over every Fin is F1a in
# LAWS_JETPROT.bend)
def conc_at(+i: S.Inst, +p: S.Phase, +j: Bool, +l: S.Level, +c: S.CEv) -> Bool:
  ev_eq(S.concretize(i, S.Fin{p, j, l, S.DmsIdle{}, True{}, True{}, S.Off{}, S.Off{}}, c), conc_expected(i, p, j, l, c))

def conc_alarms(+i: S.Inst, +p: S.Phase, +j: Bool, +l: S.Level) -> Bool:
  Bool.and(Bool.and(conc_at(i, p, j, l, S.XAlarm{S.Slow{}}), conc_at(i, p, j, l, S.XAlarm{S.Fast{}})),
  Bool.and(Bool.and(conc_at(i, p, j, l, S.XAlarm{S.Mhd{}}), conc_at(i, p, j, l, S.XAlarm{S.MhdB{}})),
  Bool.and(Bool.and(conc_at(i, p, j, l, S.XAlarm{S.Mchs{}}), conc_at(i, p, j, l, S.XAlarm{S.Dhs{}})),
  Bool.and(conc_at(i, p, j, l, S.XAlarm{S.BothHs{}}), conc_at(i, p, j, l, S.XAlarm{S.Blind{}})))))

def conc_rest(+i: S.Inst, +p: S.Phase, +j: Bool, +l: S.Level) -> Bool:
  Bool.and(Bool.and(Bool.and(conc_at(i, p, j, l, S.XAdvance{}), conc_at(i, p, j, l, S.XHeartbeat{})),
                    Bool.and(conc_at(i, p, j, l, S.XTick{}), conc_at(i, p, j, l, S.XHeatAck{}))),
  Bool.and(Bool.and(Bool.and(conc_at(i, p, j, l, S.XReset{}), conc_at(i, p, j, l, S.XCommFault{})),
                    Bool.and(conc_at(i, p, j, l, S.XLocal{S.Nb{}}), conc_at(i, p, j, l, S.XLocal{S.Rf{}}))),
  Bool.and(Bool.and(Bool.and(conc_at(i, p, j, l, S.XHeatOn{S.Nb{}}), conc_at(i, p, j, l, S.XHeatOn{S.Rf{}})),
                    Bool.and(conc_at(i, p, j, l, S.XHeatOff{S.Nb{}}), conc_at(i, p, j, l, S.XHeatOff{S.Rf{}}))),
  Bool.and(Bool.and(conc_at(i, p, j, l, S.XPlasma{True{}}), conc_at(i, p, j, l, S.XPlasma{False{}})),
           Bool.and(conc_at(i, p, j, l, S.XIp{True{}}), conc_at(i, p, j, l, S.XIp{False{}}))))))

def conc_cell(+i: S.Inst, +p: S.Phase, +j: Bool, +l: S.Level) -> Bool:
  Bool.and(conc_alarms(i, p, j, l), conc_rest(i, p, j, l))

def conc_lvl(+i: S.Inst, +p: S.Phase, +j: Bool) -> Bool:
  Bool.and(Bool.and(conc_cell(i, p, j, S.LNone{}), conc_cell(i, p, j, S.LJtt{})),
           Bool.and(conc_cell(i, p, j, S.LRtps{}), conc_cell(i, p, j, S.LPtn{})))

def conc_phase(+i: S.Inst, +p: S.Phase) -> Bool:
  Bool.and(conc_lvl(i, p, False{}), conc_lvl(i, p, True{}))

def conc_inst(+i: S.Inst) -> Bool:
  Bool.and(conc_phase(i, S.Breakdown{}), Bool.and(conc_phase(i, S.IpRise{}), Bool.and(conc_phase(i, S.Limiter{}),
  Bool.and(conc_phase(i, S.Xpoint{}), Bool.and(conc_phase(i, S.Heating1{}), Bool.and(conc_phase(i, S.Heating2{}),
           conc_phase(i, S.Termination{})))))))

def check_concretize() -> Bool:
  Bool.and(Bool.and(conc_inst(S.Inst1{}), conc_inst(S.Inst2{})), Bool.and(conc_inst(S.Inst3{}), conc_inst(S.Inst4{})))
