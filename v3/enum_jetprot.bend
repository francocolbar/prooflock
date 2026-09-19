# enum_jetprot.bend - the finite certificate of jetprot.bend, written as NESTED FIRST-ORDER
# checks so that PROOF_JETPROT.bend can turn "check_fin(o) == True" into universal
# statements with one small lemma per quantifier level (reflection).
#
# One cell = (order, control state, abstract event, verdicts). The next control state is
# computed ONCE per cell and every property is evaluated on it (docs/fase3-diseno.md C1).
# The counter verdicts (bt, bh) only reach the Tick arm of step_fin, so the certificate
# enumerates them for Tick, and for the three events whose counter command is a
# reset_if(...) on a guard of the state (Reset, CommFault{True}, Stop{LPtn, True}): there the
# checker cannot discharge the verdicts symbolically in PROOF_JETPROT.bend, so the cell is
# certified at all four verdict pairs. 2688 states x (19 + 5 x 4) = 104 832 cells per order.
# That the other 19 columns may be certified at (True, True) alone is not an assumption: it is
# the law `verdict_frame_step` / `_hb` / `_tack` of LAWS_JETPROT.bend (V1), which says that
# outside the Tick arm neither the step nor either counter command reads a verdict.
# That the other 19 columns may be certified at (True, True) alone is not an assumption: it is
# the law `verdict_frame_step` / `_hb` / `_tack` of LAWS_JETPROT.bend (V1), which says that
# outside the Tick arm neither the step nor either counter command reads a verdict.

import Base
import ./jetprot.bend as S

# ---------------------------------------------------------------------------
# The property of one cell, in six named groups (for the projections in the proof)
# ---------------------------------------------------------------------------

# preservation of the control invariant and the two counter shapes
def g_pres(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(S.pr_pres(f, f2), Bool.and(S.pr_hb(f, e, bh, f2), S.pr_tack(f, e, bt, bh, f2)))

# P1..P4
def g_a(+o: S.Ord, +f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  Bool.and(S.pr_p1(o, f, e, f2), Bool.and(S.pr_p2(f, f2), Bool.and(S.pr_p3(f, f2), S.pr_p4(f, e, f2))))

# P5..P9
def g_b(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(S.pr_p5(f, e, f2), Bool.and(S.pr_p6(f, f2), Bool.and(S.pr_p7(f, e, f2), Bool.and(S.pr_p8(f, e, f2), S.pr_p9(f, e, bt, bh, f2)))))

# P10, P12, P14..P21
def g_c(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(S.pr_p10(f, e, bh, f2), Bool.and(S.pr_p12(e, f2), Bool.and(S.pr_p14(f, e, f2), Bool.and(S.pr_p15(f, e, f2),
  Bool.and(S.pr_p16(f, e, bh, f2), Bool.and(S.pr_p17(f, e, bh, f2), Bool.and(S.pr_p18(f, e, bt, bh),
  Bool.and(S.pr_p19(f, e, bt, bh, f2), Bool.and(S.pr_p20(f, e, bt, bh, f2), S.pr_p21(f, e, bt, bh, f2))))))))))

# D1..D18 (demand and frame): the sequencer does its job, and nothing else moves
def g_d(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(S.pr_d1(o, f, e, f2), Bool.and(S.pr_d2(o, f, e, f2), Bool.and(S.pr_d3(f, e, f2),
  Bool.and(S.pr_d4(f, e, bh, f2), Bool.and(S.pr_d5(f, e, bh), Bool.and(S.pr_d6(f, e, bh),
  Bool.and(S.pr_d7(f, e, bt, f2), Bool.and(S.pr_d8(f, e, bt, bh), Bool.and(S.pr_d9(f, e, f2),
  Bool.and(S.pr_d10(f, e, bt, bh, f2), Bool.and(S.pr_d11(f, e, f2), Bool.and(S.pr_d12(f, e, f2),
  Bool.and(S.pr_d13(e, f2), Bool.and(S.pr_d14(f, e, f2), Bool.and(S.pr_d15(f, e, bt, bh, f2),
  Bool.and(S.pr_d16(f, e, bt, bh, f2), Bool.and(S.pr_d17(f, e, bt, bh, f2), S.pr_d18(f, e, bt, bh, f2))))))))))))))))))

# E1..E11 (audit #5): the eight holes D1..D18 still left open
def g_e(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(S.pr_e1(f, e, f2), Bool.and(S.pr_e2(f, e, bt, f2), Bool.and(S.pr_e3(o, f, e, f2),
  Bool.and(S.pr_e4(f, e, f2), Bool.and(S.pr_e5(f, e, bh), Bool.and(S.pr_e6(f, e, bh),
  Bool.and(S.pr_e7(f, e, bt, bh), Bool.and(S.pr_e8(f, e, bt, bh), S.pr_e11(f, e, f2)))))))))

def prop_at(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(g_pres(f, e, bt, bh, f2), Bool.and(g_a(o, f, e, f2), Bool.and(g_b(f, e, bt, bh, f2),
  Bool.and(g_c(f, e, bt, bh, f2), Bool.and(g_d(o, f, e, bt, bh, f2), g_e(o, f, e, bt, bh, f2))))))

# the next control state is computed once per cell
def prop(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> Bool:
  prop_at(o, f, e, bt, bh, S.step_fin(o, f, e, bt, bh))

# ---------------------------------------------------------------------------
# Quantifier levels (each is a conjunction over one constructor set)
# ---------------------------------------------------------------------------

# verdicts: enumerated for Tick, Reset, CommFault{True}, Stop{LPtn, True}; fixed (True, True) for
# the events whose commands the proof reduces symbolically
def all_bh(+o: S.Ord, +f: S.Fin, +e: S.Ev, +bt: Bool) -> Bool:
  Bool.and(prop(o, f, e, bt, True{}), prop(o, f, e, bt, False{}))

def all_bt(+o: S.Ord, +f: S.Fin, +e: S.Ev) -> Bool:
  Bool.and(all_bh(o, f, e, True{}), all_bh(o, f, e, False{}))

def one(+o: S.Ord, +f: S.Fin, e: S.Ev) -> Bool:
  prop(o, f, e, True{}, True{})

# the 24 event variants in 12 pairs
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
  Bool.and(all_bt(o, f, S.CommFault{True{}}), one(o, f, S.CommFault{False{}}))

def ev_g8(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(all_bt(o, f, S.Tick{True{}}), all_bt(o, f, S.Tick{False{}}))

def ev_g9(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.Stop{S.LNone{}, True{}}), one(o, f, S.Stop{S.LNone{}, False{}}))

def ev_g10(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.Stop{S.LJtt{}, True{}}), one(o, f, S.Stop{S.LJtt{}, False{}}))

def ev_g11(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(one(o, f, S.Stop{S.LRtps{}, True{}}), one(o, f, S.Stop{S.LRtps{}, False{}}))

def ev_g12(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(all_bt(o, f, S.Stop{S.LPtn{}, True{}}), one(o, f, S.Stop{S.LPtn{}, False{}}))

def ev_q1(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(Bool.and(ev_g1(o, f), ev_g2(o, f)), Bool.and(ev_g3(o, f), ev_g4(o, f)))

def ev_q2(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(Bool.and(ev_g5(o, f), ev_g6(o, f)), Bool.and(ev_g7(o, f), ev_g8(o, f)))

def ev_q3(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(Bool.and(ev_g9(o, f), ev_g10(o, f)), Bool.and(ev_g11(o, f), ev_g12(o, f)))

def all_ev(+o: S.Ord, +f: S.Fin) -> Bool:
  Bool.and(ev_q1(o, f), Bool.and(ev_q2(o, f), ev_q3(o, f)))

# the control fields, innermost first: rf, nb, plasma, dms, level, phase
def all_rf(+o: S.Ord, +p: S.Phase, +l: S.Level, +d: S.Dms, +pl: Bool, +nb: S.Heat) -> Bool:
  Bool.and(Bool.and(all_ev(o, S.Fin{p, l, d, pl, nb, S.Off{}}), all_ev(o, S.Fin{p, l, d, pl, nb, S.Inhibited{}})),
           Bool.and(all_ev(o, S.Fin{p, l, d, pl, nb, S.Ramping{}}), all_ev(o, S.Fin{p, l, d, pl, nb, S.On{}})))

def all_nb(+o: S.Ord, +p: S.Phase, +l: S.Level, +d: S.Dms, +pl: Bool) -> Bool:
  Bool.and(Bool.and(all_rf(o, p, l, d, pl, S.Off{}), all_rf(o, p, l, d, pl, S.Inhibited{})),
           Bool.and(all_rf(o, p, l, d, pl, S.Ramping{}), all_rf(o, p, l, d, pl, S.On{})))

def all_plasma(+o: S.Ord, +p: S.Phase, +l: S.Level, +d: S.Dms) -> Bool:
  Bool.and(all_nb(o, p, l, d, True{}), all_nb(o, p, l, d, False{}))

def all_dms(+o: S.Ord, +p: S.Phase, +l: S.Level) -> Bool:
  Bool.and(all_plasma(o, p, l, S.DmsIdle{}), Bool.and(all_plasma(o, p, l, S.DmsArmed{}), all_plasma(o, p, l, S.DmsFired{})))

def all_level(+o: S.Ord, +p: S.Phase) -> Bool:
  Bool.and(Bool.and(all_dms(o, p, S.LNone{}), all_dms(o, p, S.LJtt{})),
           Bool.and(all_dms(o, p, S.LRtps{}), all_dms(o, p, S.LPtn{})))

# the seven phases: 2688 control states x 39 columns, for one order
def check_fin(+o: S.Ord) -> Bool:
  Bool.and(all_level(o, S.Breakdown{}), Bool.and(all_level(o, S.IpRise{}), Bool.and(all_level(o, S.Limiter{}),
  Bool.and(all_level(o, S.Xpoint{}), Bool.and(all_level(o, S.Heating1{}), Bool.and(all_level(o, S.Heating2{}),
           all_level(o, S.Termination{})))))))

# ---------------------------------------------------------------------------
# The state corollaries (docs/fase3-diseno.md §2): under inv_fin, PTN and an armed/fired
# DMS leave no unit powered, a stop leaves no unit at full power, and so does Termination.
# 2688 control states, one level per field.
# ---------------------------------------------------------------------------

def cor_at(+f: S.Fin) -> Bool:
  S.implies(S.inv_fin(f),
    Bool.and(S.implies(S.is_ptn(S.level_of(f)), Bool.and(S.unpowered(S.nb_of(f)), S.unpowered(S.rf_of(f)))),
    Bool.and(S.implies(Bool.not(S.is_idle(S.dms_of(f))), Bool.and(S.unpowered(S.nb_of(f)), S.unpowered(S.rf_of(f)))),
    Bool.and(S.implies(Bool.not(S.is_none(S.level_of(f))), Bool.and(Bool.not(S.is_on(S.nb_of(f))), Bool.not(S.is_on(S.rf_of(f))))),
             S.implies(S.is_term(S.phase_of(f)), Bool.and(Bool.not(S.is_on(S.nb_of(f))), Bool.not(S.is_on(S.rf_of(f)))))))))

def cor_rf(+p: S.Phase, +l: S.Level, +d: S.Dms, +pl: Bool, +nb: S.Heat) -> Bool:
  Bool.and(Bool.and(cor_at(S.Fin{p, l, d, pl, nb, S.Off{}}), cor_at(S.Fin{p, l, d, pl, nb, S.Inhibited{}})),
           Bool.and(cor_at(S.Fin{p, l, d, pl, nb, S.Ramping{}}), cor_at(S.Fin{p, l, d, pl, nb, S.On{}})))

def cor_nb(+p: S.Phase, +l: S.Level, +d: S.Dms, +pl: Bool) -> Bool:
  Bool.and(Bool.and(cor_rf(p, l, d, pl, S.Off{}), cor_rf(p, l, d, pl, S.Inhibited{})),
           Bool.and(cor_rf(p, l, d, pl, S.Ramping{}), cor_rf(p, l, d, pl, S.On{})))

def cor_plasma(+p: S.Phase, +l: S.Level, +d: S.Dms) -> Bool:
  Bool.and(cor_nb(p, l, d, True{}), cor_nb(p, l, d, False{}))

def cor_dms(+p: S.Phase, +l: S.Level) -> Bool:
  Bool.and(cor_plasma(p, l, S.DmsIdle{}), Bool.and(cor_plasma(p, l, S.DmsArmed{}), cor_plasma(p, l, S.DmsFired{})))

def cor_level(+p: S.Phase) -> Bool:
  Bool.and(Bool.and(cor_dms(p, S.LNone{}), cor_dms(p, S.LJtt{})), Bool.and(cor_dms(p, S.LRtps{}), cor_dms(p, S.LPtn{})))

def check_cor() -> Bool:
  Bool.and(cor_level(S.Breakdown{}), Bool.and(cor_level(S.IpRise{}), Bool.and(cor_level(S.Limiter{}),
  Bool.and(cor_level(S.Xpoint{}), Bool.and(cor_level(S.Heating1{}), Bool.and(cor_level(S.Heating2{}),
           cor_level(S.Termination{})))))))

# ---------------------------------------------------------------------------
# The concrete layer under law: `concretize` must be exactly the table lookup and the
# constructor wiring. Nothing in the certificate above constrains it, so a mis-wired column
# (XAlarm{Dhs} reading the MCHS column) or a mis-wired constructor (XHeatOn -> HeatOff) was
# invisible to every law. 2 instances x 7 phases x 21 concrete events = 294 cells.
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
    case S.CommFault{dms}:
      6n
    case S.Heartbeat{}:
      7n
    case S.Tick{dms}:
      8n
    case S.HeatAck{}:
      9n
    case S.Reset{}:
      10n

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
    case S.CommFault{dms}:
      dms
    case S.Tick{dms}:
      dms
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
  Bool.and(S.lvl_eq(ev_lvl(a), ev_lvl(b)),
  Bool.and(S.beq(ev_bit(a), ev_bit(b)), S.who_eq(ev_who(a), ev_who(b)))))

# The configuration, transcribed a FOURTH time as its own function, so that the concrete-layer
# check stops being self-referential: conc_expected used to build its expectation from the very
# S.table / S.dms_req that concretize calls, so it detected a mis-wired constructor or column but
# NOT a wrong table value and NOT a wrong DMS window (audit #5 section 4). The matrix below is
# the 7 phases x 7 triggers x 2 instances of R-5 + A-4 written out cell by cell, and the DMS
# wiring is the trigger set {Fast, Mhd, MhdB} and the window {Xpoint, Heating1, Heating2,
# Termination} as two independent predicates. Nothing here mentions jetprot's own tables.

# instance 1 (Table 1 of [S1] as published, R-5, plus the assumed cells of A-4)
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

def m_table(i: S.Inst, p: S.Phase, t: S.Trig) -> S.Level:
  match i:
    case S.Inst1{}:
      m_table1(p, t)
    case S.Inst2{}:
      m_table2(p, t)

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

# the DMV enable window (R-14), as a set
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

# the wiring, restated independently of concretize() AND of table()/dms_req()
def conc_expected(i: S.Inst, +p: S.Phase, c: S.CEv) -> S.Ev:
  match c:
    case S.XAdvance{}:
      S.Advance{}
    case S.XAlarm{+t}:
      S.Stop{m_table(i, p, t), Bool.and(m_trig(t), m_win(p))}
    case S.XLocal{u}:
      S.Local{u}
    case S.XHeatOn{u}:
      S.HeatOn{u}
    case S.XHeatOff{u}:
      S.HeatOff{u}
    case S.XPlasma{ok}:
      S.Plasma{ok}
    case S.XCommFault{}:
      S.CommFault{False{}}
    case S.XHeartbeat{}:
      S.Heartbeat{}
    case S.XTick{}:
      S.Tick{False{}}
    case S.XHeatAck{}:
      S.HeatAck{}
    case S.XReset{}:
      S.Reset{}

def conc_at(+i: S.Inst, +p: S.Phase, +c: S.CEv) -> Bool:
  ev_eq(S.concretize(i, p, c), conc_expected(i, p, c))

def conc_alarms(+i: S.Inst, +p: S.Phase) -> Bool:
  Bool.and(Bool.and(conc_at(i, p, S.XAlarm{S.Slow{}}), conc_at(i, p, S.XAlarm{S.Fast{}})),
  Bool.and(Bool.and(conc_at(i, p, S.XAlarm{S.Mhd{}}), conc_at(i, p, S.XAlarm{S.MhdB{}})),
  Bool.and(Bool.and(conc_at(i, p, S.XAlarm{S.Mchs{}}), conc_at(i, p, S.XAlarm{S.Dhs{}})),
           conc_at(i, p, S.XAlarm{S.BothHs{}}))))

def conc_rest(+i: S.Inst, +p: S.Phase) -> Bool:
  Bool.and(Bool.and(Bool.and(conc_at(i, p, S.XAdvance{}), conc_at(i, p, S.XHeartbeat{})),
                    Bool.and(conc_at(i, p, S.XTick{}), conc_at(i, p, S.XHeatAck{}))),
  Bool.and(Bool.and(Bool.and(conc_at(i, p, S.XReset{}), conc_at(i, p, S.XCommFault{})),
                    Bool.and(conc_at(i, p, S.XLocal{S.Nb{}}), conc_at(i, p, S.XLocal{S.Rf{}}))),
  Bool.and(Bool.and(Bool.and(conc_at(i, p, S.XHeatOn{S.Nb{}}), conc_at(i, p, S.XHeatOn{S.Rf{}})),
                    Bool.and(conc_at(i, p, S.XHeatOff{S.Nb{}}), conc_at(i, p, S.XHeatOff{S.Rf{}}))),
           Bool.and(conc_at(i, p, S.XPlasma{True{}}), conc_at(i, p, S.XPlasma{False{}})))))

def conc_phase(+i: S.Inst, +p: S.Phase) -> Bool:
  Bool.and(conc_alarms(i, p), conc_rest(i, p))

def conc_inst(+i: S.Inst) -> Bool:
  Bool.and(conc_phase(i, S.Breakdown{}), Bool.and(conc_phase(i, S.IpRise{}), Bool.and(conc_phase(i, S.Limiter{}),
  Bool.and(conc_phase(i, S.Xpoint{}), Bool.and(conc_phase(i, S.Heating1{}), Bool.and(conc_phase(i, S.Heating2{}),
           conc_phase(i, S.Termination{})))))))

def check_concretize() -> Bool:
  Bool.and(conc_inst(S.Inst1{}), conc_inst(S.Inst2{}))
