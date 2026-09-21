# spec_jetprot.bend - the SPECIFICATION side of the JET protection-chain case: the Bool
# equality predicates of the finite types, the frame predicate `local_frame` and every cell
# property `pr_pN` / `pr_dN` / `pr_eN` that LAWS_JETPROT.bend quantifies over. Split out of
# jetprot.bend (STATUS 2026-09-21, blocker 1) so that the model and the properties it must
# satisfy live in different files: this file imports the model; the model imports nothing
# from here. The certificates (enum_jetprot.bend) and the proofs import both.
#
# Every predicate here is a Bool decided by computation. LAWS_JETPROT_SOUND.bend proves
# that the equality predicates are sound: `unit_eq(a, b) == True{}` implies `a == b`, and
# likewise for `beq`, `lvl_eq`, `dms_eq`, `phase_eq` and `fin_eq`; `lvl_le` is antisymmetric
# under both urgency orders. Those lemmas are what make a frame law that concludes
# `fin_eq(f, f2) == True{}` a statement about f and f2, not about the predicate.

import Base
import ./jetprot.bend as S

# ---------------------------------------------------------------------------
# Equality (and order) predicates on the finite types, by rank
# ---------------------------------------------------------------------------

def beq(a: Bool, b: Bool) -> Bool:
  match a b:
    case True{} True{}:
      True{}
    case False{} False{}:
      True{}
    case _ _:
      False{}

# ---------------------------------------------------------------------------
# Orders (finite, by rank)
# ---------------------------------------------------------------------------

def lvl_le(o: S.Ord, a: S.Level, b: S.Level) -> Bool:
  +o2 = o
  Bool.not(Nat.is_lt(S.lvl_rank(o2, b), S.lvl_rank(o2, a)))

def lvl_eq(a: S.Level, b: S.Level) -> Bool:
  Nat.is_eq(S.lvl_rank(S.Ord1{}, a), S.lvl_rank(S.Ord1{}, b))

def phase_le(a: S.Phase, b: S.Phase) -> Bool:
  Bool.not(Nat.is_lt(S.phase_rank(b), S.phase_rank(a)))

def phase_eq(a: S.Phase, b: S.Phase) -> Bool:
  Nat.is_eq(S.phase_rank(a), S.phase_rank(b))

def dms_le(a: S.Dms, b: S.Dms) -> Bool:
  Bool.not(Nat.is_lt(S.dms_rank(b), S.dms_rank(a)))

def dms_eq(a: S.Dms, b: S.Dms) -> Bool:
  Nat.is_eq(S.dms_rank(a), S.dms_rank(b))

def unit_eq(a: S.Heat, b: S.Heat) -> Bool:
  Nat.is_eq(S.unit_rank(a), S.unit_rank(b))

def fin_eq(a: S.Fin, b: S.Fin) -> Bool:
  match a b:
    case S.Fin{p, l, d, pl, nb, rf} S.Fin{p2, l2, d2, pl2, nb2, rf2}:
      Bool.and(phase_eq(p, p2), Bool.and(lvl_eq(l, l2), Bool.and(dms_eq(d, d2),
      Bool.and(beq(pl, pl2), Bool.and(unit_eq(nb, nb2), unit_eq(rf, rf2))))))

# ---------------------------------------------------------------------------
# The counter shapes (as in seq3): whenever the next control runs a counter, the command
# was a Reset, or a Keep from a state already running it, or an Inc allowed by the verdict
# ---------------------------------------------------------------------------

def shape_ok(u: S.Upd, was_running: Bool, verdict: Bool) -> Bool:
  match u:
    case S.CReset{}:
      True{}
    case S.CKeep{}:
      was_running
    case S.CInc{}:
      verdict

def hb_running(f: S.Fin) -> Bool:
  Bool.not(S.is_ptn(S.level_of(f)))

def tack_running(f: S.Fin) -> Bool:
  S.is_armed(S.dms_of(f))

# ---------------------------------------------------------------------------
# The step laws as Bool properties of one cell (o, f, e, bt, bh) with f2 = step_fin(...)
# (docs/fase3-diseno.md §2, P1..P20). Each is decided by computation in the certificate.
# ---------------------------------------------------------------------------

def is_reset(e: S.Ev) -> Bool:
  match e:
    case S.Reset{}:
      True{}
    case _:
      False{}

def is_tick(e: S.Ev) -> Bool:
  match e:
    case S.Tick{dms}:
      True{}
    case _:
      False{}

def is_advance(e: S.Ev) -> Bool:
  match e:
    case S.Advance{}:
      True{}
    case _:
      False{}

def is_stop(e: S.Ev) -> Bool:
  match e:
    case S.Stop{req, dms}:
      True{}
    case _:
      False{}

def is_commfault(e: S.Ev) -> Bool:
  match e:
    case S.CommFault{dms}:
      True{}
    case _:
      False{}

def who_eq(a: S.Who, b: S.Who) -> Bool:
  match a b:
    case S.Nb{} S.Nb{}:
      True{}
    case S.Rf{} S.Rf{}:
      True{}
    case _ _:
      False{}

def is_heaton_of(e: S.Ev, w: S.Who) -> Bool:
  match e:
    case S.HeatOn{u}:
      who_eq(u, w)
    case _:
      False{}

def is_local_of(e: S.Ev, w: S.Who) -> Bool:
  match e:
    case S.Local{u}:
      who_eq(u, w)
    case _:
      False{}

# does this event demand the DMS (a stop that reaches PTN and is wired to it)?
def demands_dms(e: S.Ev, bh: Bool, l: S.Level) -> Bool:
  match e:
    case S.Stop{req, dms}:
      Bool.and(S.is_ptn(req), dms)
    case S.CommFault{dms}:
      dms
    case S.Tick{dms}:
      Bool.and(dms, Bool.and(Bool.not(bh), Bool.not(S.is_ptn(l))))
    case _:
      False{}

# P1 latched
def pr_p1(+o: S.Ord, +f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.not(is_reset(e)), lvl_le(o, S.level_of(f), S.level_of(f2)))

# P2 ptn_deenergizes: the step that REACHES PTN leaves no unit powered
def pr_p2(+f: S.Fin, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(Bool.not(S.is_ptn(S.level_of(f))), S.is_ptn(S.level_of(f2))), Bool.and(S.unpowered(S.nb_of(f2)), S.unpowered(S.rf_of(f2))))

# P3 stop_reduces_power: the step that starts a soft stop takes every unit out of full power
def pr_p3(+f: S.Fin, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(S.is_none(S.level_of(f)), S.is_soft(S.level_of(f2))), Bool.and(Bool.not(S.is_on(S.nb_of(f2))), Bool.not(S.is_on(S.rf_of(f2)))))

# P4 ramping_never_returns
def p4_unit(u: S.Heat, u2: S.Heat, e: S.Ev) -> Bool:
  S.implies(Bool.and(S.is_ramping(u), Bool.not(is_reset(e))), Bool.not(S.is_on(u2)))

def pr_p4(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  Bool.and(p4_unit(S.nb_of(f), S.nb_of(f2), e), p4_unit(S.rf_of(f), S.rf_of(f2), e))

# P5 heat_permissive: HeatOn{u} turns u on iff the permissive holds and u was Off; else no change
def p5_unit(+ok: Bool, +u: S.Heat, +u2: S.Heat) -> Bool:
  +acc = Bool.and(ok, S.is_off(u))
  Bool.and(beq(S.is_on(u2), Bool.or(acc, Bool.and(S.is_on(u), Bool.not(acc)))),
           S.implies(Bool.not(acc), unit_eq(u2, u)))

def pr_p5(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  Bool.and(S.implies(is_heaton_of(e, S.Nb{}), p5_unit(S.permit(f), S.nb_of(f), S.nb_of(f2))),
           S.implies(is_heaton_of(e, S.Rf{}), p5_unit(S.permit(f), S.rf_of(f), S.rf_of(f2))))

# P6 stop_overrides_heat: with a stop in force nothing switches on
def p6_unit(u: S.Heat, u2: S.Heat) -> Bool:
  Bool.not(Bool.and(Bool.not(S.is_on(u)), S.is_on(u2)))

def pr_p6(+f: S.Fin, +f2: S.Fin) -> Bool:
  S.implies(Bool.not(S.is_none(S.level_of(f))), Bool.and(p6_unit(S.nb_of(f), S.nb_of(f2)), p6_unit(S.rf_of(f), S.rf_of(f2))))

# P7 heat_frame: no unit energizes without its command
def p7_unit(u: S.Heat, u2: S.Heat, e: S.Ev, w: S.Who) -> Bool:
  S.implies(Bool.and(S.is_on(u2), Bool.not(S.is_on(u))), is_heaton_of(e, w))

def pr_p7(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  Bool.and(p7_unit(S.nb_of(f), S.nb_of(f2), e, S.Nb{}), p7_unit(S.rf_of(f), S.rf_of(f2), e, S.Rf{}))

# P8 inhibit_latched
def p8_unit(u: S.Heat, u2: S.Heat, e: S.Ev) -> Bool:
  S.implies(Bool.and(S.is_inh(u), Bool.not(is_reset(e))), S.is_inh(u2))

def pr_p8(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  Bool.and(p8_unit(S.nb_of(f), S.nb_of(f2), e), p8_unit(S.rf_of(f), S.rf_of(f2), e))

# P9 local_is_local: the unit is inhibited, everything else (control and counters) unchanged
def local_frame(f: S.Fin, f2: S.Fin, w: S.Who) -> Bool:
  match f f2 w:
    case S.Fin{p, l, d, pl, nb, rf} S.Fin{p2, l2, d2, pl2, nb2, rf2} S.Nb{}:
      Bool.and(S.is_inh(nb2), Bool.and(phase_eq(p, p2), Bool.and(lvl_eq(l, l2), Bool.and(dms_eq(d, d2), Bool.and(beq(pl, pl2), unit_eq(rf, rf2))))))
    case S.Fin{p, l, d, pl, nb, rf} S.Fin{p2, l2, d2, pl2, nb2, rf2} S.Rf{}:
      Bool.and(S.is_inh(rf2), Bool.and(phase_eq(p, p2), Bool.and(lvl_eq(l, l2), Bool.and(dms_eq(d, d2), Bool.and(beq(pl, pl2), unit_eq(nb, nb2))))))

def p9_go(+f: S.Fin, +w: S.Who, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(local_frame(f, f2, w), Bool.and(S.is_keep(S.upd_hb(f, S.Local{w}, bh)), S.is_keep(S.upd_tack(f, S.Local{w}, bt, bh))))

def pr_p9(+f: S.Fin, e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  match e:
    case S.Local{u}:
      p9_go(f, u, bt, bh, f2)
    case _:
      True{}

# P10 no_spurious_stop
def pr_p10(+f: S.Fin, +e: S.Ev, +bh: Bool, +f2: S.Fin) -> Bool:
  S.implies(Bool.not(lvl_eq(S.level_of(f), S.level_of(f2))),
          Bool.or(is_stop(e), Bool.or(is_commfault(e), Bool.or(is_reset(e),
                  Bool.and(is_tick(e), Bool.and(Bool.not(bh), Bool.not(S.is_ptn(S.level_of(f)))))))))

# P12 commfault_ptn
def pr_p12(+e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(is_commfault(e), S.is_ptn(S.level_of(f2)))

# P14 phase_monotone
def pr_p14(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.not(is_reset(e)), phase_le(S.phase_of(f), S.phase_of(f2)))

# P15 dms_monotone
def pr_p15(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.not(is_reset(e)), dms_le(S.dms_of(f), S.dms_of(f2)))

# P16 dms_armed_on_demand (positive)
def pr_p16(+f: S.Fin, +e: S.Ev, +bh: Bool, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(S.is_idle(S.dms_of(f)), demands_dms(e, bh, S.level_of(f))), S.is_armed(S.dms_of(f2)))

# P17 dms_frame: nothing arms the DMS but a demand
def pr_p17(+f: S.Fin, +e: S.Ev, +bh: Bool, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(S.is_idle(S.dms_of(f)), Bool.not(S.is_idle(S.dms_of(f2)))), demands_dms(e, bh, S.level_of(f)))

# P18 tack_frame: while armed, only Tick and Reset touch the wait counter
def pr_p18(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> Bool:
  S.implies(Bool.and(S.is_armed(S.dms_of(f)), Bool.and(Bool.not(is_tick(e)), Bool.not(is_reset(e)))),
          S.is_keep(S.upd_tack(f, e, bt, bh)))

# P19 advance_frozen: under PTN, Advance is the identity on control and counters
def pr_p19(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(is_advance(e), S.is_ptn(S.level_of(f))),
          Bool.and(fin_eq(f, f2), Bool.and(S.is_keep(S.upd_hb(f, e, bh)), S.is_keep(S.upd_tack(f, e, bt, bh)))))

# P20 reset_guarded (the control part; the counters are handled symbolically in the proof)
def reset_shape(ok: Bool, f: S.Fin, f2: S.Fin, hb_cmd: S.Upd, tack_cmd: S.Upd) -> Bool:
  match ok:
    case True{}:
      Bool.and(fin_eq(f2, S.init_fin()), Bool.and(S.is_creset(hb_cmd), S.is_creset(tack_cmd)))
    case False{}:
      Bool.and(fin_eq(f2, f), Bool.and(S.is_keep(hb_cmd), S.is_keep(tack_cmd)))

def pr_p20(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  S.implies(is_reset(e), reset_shape(S.reset_ok(f), f, f2, S.upd_hb(f, e, bh), S.upd_tack(f, e, bt, bh)))

# P21 reset_refused_mid_pulse: an end of pulse while the DMS is armed, or before the pulse has
# ended (no PTN, not in Termination), changes nothing (the guard of A-14 as an explicit law)
def pr_p21(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(is_reset(e), Bool.or(S.is_armed(S.dms_of(f)), Bool.and(Bool.not(S.is_ptn(S.level_of(f))), Bool.not(S.is_term(S.phase_of(f)))))),
          Bool.and(fin_eq(f, f2), Bool.and(S.is_keep(S.upd_hb(f, e, bh)), S.is_keep(S.upd_tack(f, e, bt, bh)))))

# the counter shapes as cell properties
def pr_hb(+f: S.Fin, +e: S.Ev, +bh: Bool, +f2: S.Fin) -> Bool:
  S.implies(hb_running(f2), shape_ok(S.upd_hb(f, e, bh), hb_running(f), bh))

def pr_tack(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  S.implies(tack_running(f2), shape_ok(S.upd_tack(f, e, bt, bh), tack_running(f), bt))

# preservation of the control invariant
def pr_pres(+f: S.Fin, +f2: S.Fin) -> Bool:
  S.implies(S.inv_fin(f), S.inv_fin(f2))


# ---------------------------------------------------------------------------
# DEMAND and FRAME laws D1..D18 (audit #4): P1..P21 say that nothing bad happens; these say
# that the sequencer DOES its job and that nothing else moves. Each is a property of the same
# cell (o, f, e, bt, bh) with f2 = step_fin(o, f, e, bt, bh), so every guard an invariant
# would provide is written into the hypothesis instead.
# ---------------------------------------------------------------------------

# the more urgent of two levels under o (their least upper bound in the rank order)
def lvl_lub(o: S.Ord, a: S.Level, b: S.Level) -> S.Level:
  +a2 = a
  +b2 = b
  S.lvl_pick(S.lvl_lt(o, a2, b2), a2, b2)

# the payload of a Stop / of a Plasma event, outside a match
def ev_req(e: S.Ev) -> S.Level:
  match e:
    case S.Stop{req, dms}:
      req
    case _:
      S.LNone{}

def ev_ok(e: S.Ev) -> Bool:
  match e:
    case S.Plasma{ok}:
      ok
    case _:
      False{}

def is_cinc(u: S.Upd) -> Bool:
  match u:
    case S.CInc{}:
      True{}
    case _:
      False{}

def is_fired(d: S.Dms) -> Bool:
  match d:
    case S.DmsFired{}:
      True{}
    case _:
      False{}

def is_heartbeat(e: S.Ev) -> Bool:
  match e:
    case S.Heartbeat{}:
      True{}
    case _:
      False{}

def is_heatack(e: S.Ev) -> Bool:
  match e:
    case S.HeatAck{}:
      True{}
    case _:
      False{}

def is_plasma(e: S.Ev) -> Bool:
  match e:
    case S.Plasma{ok}:
      True{}
    case _:
      False{}

def who_other(w: S.Who) -> S.Who:
  match w:
    case S.Nb{}:
      S.Rf{}
    case S.Rf{}:
      S.Nb{}

# the control frame WITHOUT the two heating units (phase, level, dms, plasma unchanged)
def frame_units(f: S.Fin, f2: S.Fin) -> Bool:
  match f f2:
    case S.Fin{p, l, d, pl, nb, rf} S.Fin{p2, l2, d2, pl2, nb2, rf2}:
      Bool.and(phase_eq(p, p2), Bool.and(lvl_eq(l, l2), Bool.and(dms_eq(d, d2), beq(pl, pl2))))

# the control frame WITHOUT the DMS (everything but the mitigation sequence unchanged)
def frame_dms(f: S.Fin, f2: S.Fin) -> Bool:
  match f f2:
    case S.Fin{p, l, d, pl, nb, rf} S.Fin{p2, l2, d2, pl2, nb2, rf2}:
      Bool.and(phase_eq(p, p2), Bool.and(lvl_eq(l, l2), Bool.and(beq(pl, pl2), Bool.and(unit_eq(nb, nb2), unit_eq(rf, rf2)))))

# a unit at full power must be ramping down after the step
def ramps_down(u: S.Heat, u2: S.Heat) -> Bool:
  S.implies(S.is_on(u), S.is_ramping(u2))

def both_ramp(+f: S.Fin, +f2: S.Fin) -> Bool:
  Bool.and(ramps_down(S.nb_of(f), S.nb_of(f2)), ramps_down(S.rf_of(f), S.rf_of(f2)))

def some_on(+f: S.Fin) -> Bool:
  Bool.or(S.is_on(S.nb_of(f)), S.is_on(S.rf_of(f)))

# unit w becomes `exp`, the other unit, the rest of the control and both counters unchanged
def one_unit(+f: S.Fin, +f2: S.Fin, +w: S.Who, exp: S.Heat, +e: S.Ev, +bt: Bool, +bh: Bool) -> Bool:
  Bool.and(unit_eq(S.unit_of(w, f2), exp),
  Bool.and(unit_eq(S.unit_of(who_other(w), f2), S.unit_of(who_other(w), f)),
  Bool.and(frame_units(f, f2), Bool.and(S.is_keep(S.upd_hb(f, e, bh)), S.is_keep(S.upd_tack(f, e, bt, bh))))))

# D1 a stop request is honoured: the level becomes the least upper bound of the response in
# force and the requested one (two-sided, where P1 is one-sided)
def pr_d1(+o: S.Ord, +f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(is_stop(e), lvl_eq(S.level_of(f2), lvl_lub(o, S.level_of(f), ev_req(e))))

# D2 an accepted soft stop takes a unit at full power into ramp-down (R-4, H16)
def pr_d2(+o: S.Ord, +f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  +req = ev_req(e)
  S.implies(Bool.and(S.is_soft(req), Bool.and(S.lvl_lt(o, S.level_of(f), req), some_on(f))), both_ramp(f, f2))

# D3 the natural end of the programme also ramps down
def pr_d3(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(is_advance(e), Bool.and(Bool.not(S.is_ptn(S.level_of(f))),
          Bool.and(phase_eq(S.phase_of(f), S.Heating2{}), some_on(f)))), both_ramp(f, f2))

# D4 the watchdog latches the PTN whatever the instance wires to the DMS
def pr_d4(+f: S.Fin, +e: S.Ev, +bh: Bool, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(is_tick(e), Bool.and(Bool.not(bh), Bool.not(S.is_ptn(S.level_of(f))))), S.is_ptn(S.level_of(f2)))

# D5 the heartbeat counter counts while the PTN is not latched (the positive dual of I6)
def pr_d5(+f: S.Fin, +e: S.Ev, +bh: Bool) -> Bool:
  S.implies(Bool.and(is_tick(e), Bool.and(bh, Bool.not(S.is_ptn(S.level_of(f))))), is_cinc(S.upd_hb(f, e, bh)))

# D6 only a heartbeat (or the accepted end of pulse) may reset the watchdog
def pr_d6(+f: S.Fin, +e: S.Ev, +bh: Bool) -> Bool:
  S.implies(S.is_creset(S.upd_hb(f, e, bh)), Bool.or(is_heartbeat(e), Bool.and(is_reset(e), S.reset_ok(f))))

# D7 the acknowledgement timeout fires the DMS (guarded by level = PTN: with the DMS armed and
# the PTN not latched -- a state I4 excludes -- the watchdog clause would run instead)
def pr_d7(+f: S.Fin, +e: S.Ev, +bt: Bool, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(S.is_armed(S.dms_of(f)), Bool.and(S.is_ptn(S.level_of(f)), Bool.and(is_tick(e), Bool.not(bt)))), is_fired(S.dms_of(f2)))

# D8 and the wait counts up while below the limit (the positive dual of I5)
def pr_d8(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> Bool:
  S.implies(Bool.and(S.is_armed(S.dms_of(f)), Bool.and(S.is_ptn(S.level_of(f)), Bool.and(is_tick(e), bt))), is_cinc(S.upd_tack(f, e, bt, bh)))

# D9 the acknowledgement from the heating plant fires the DMS
def pr_d9(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(S.is_armed(S.dms_of(f)), is_heatack(e)), is_fired(S.dms_of(f2)))

# D10 the end of pulse IS accepted when the pulse has ended and no mitigation is armed. The
# guard is spelled out, not taken from the model own reset_ok: that self-reference is why
# P20 cannot detect a wrong guard (audit #1).
def pr_d10(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(is_reset(e), Bool.and(Bool.or(S.is_ptn(S.level_of(f)), S.is_term(S.phase_of(f))), Bool.not(S.is_armed(S.dms_of(f))))),
          Bool.and(fin_eq(f2, S.init_fin()), Bool.and(S.is_creset(S.upd_hb(f, e, bh)), S.is_creset(S.upd_tack(f, e, bt, bh)))))

# D11 the programme advances exactly one phase
def pr_d11(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(is_advance(e), Bool.and(Bool.not(S.is_ptn(S.level_of(f))), Bool.not(S.is_term(S.phase_of(f))))),
          phase_eq(S.phase_of(f2), S.next_phase(S.phase_of(f))))

# D12 nothing else moves the phase
def pr_d12(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.not(phase_eq(S.phase_of(f), S.phase_of(f2))),
          Bool.or(is_advance(e), Bool.or(is_reset(e), S.is_jtt(ev_req(e)))))

# D13 the plasma conditions are an input ...
def pr_d13(+e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(is_plasma(e), beq(S.plasma_of(f2), ev_ok(e)))

# D14 ... and only that input (or the end of pulse) moves them
def pr_d14(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.not(beq(S.plasma_of(f), S.plasma_of(f2))), Bool.or(is_plasma(e), Bool.and(is_reset(e), S.reset_ok(f))))

# D15 a heating-off command de-energizes its own unit and touches nothing else (mirror of P9)
def pr_d15(+f: S.Fin, e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  match e:
    case S.HeatOff{u}:
      +u2 = u
      one_unit(f, f2, u2, S.deenergize(S.unit_of(u2, f)), S.HeatOff{u2}, bt, bh)
    case _:
      True{}

# D16 a heating-on command touches its own unit only (what it does to that unit is P5)
def pr_d16(+f: S.Fin, e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  match e:
    case S.HeatOn{u}:
      +u2 = u
      Bool.and(frame_units(f, f2),
      Bool.and(unit_eq(S.unit_of(who_other(u2), f2), S.unit_of(who_other(u2), f)),
      Bool.and(S.is_keep(S.upd_hb(f, S.HeatOn{u2}, bh)), S.is_keep(S.upd_tack(f, S.HeatOn{u2}, bt, bh)))))
    case _:
      True{}

# D17 an acknowledgement moves the DMS and nothing else
def pr_d17(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  S.implies(is_heatack(e), Bool.and(frame_dms(f, f2), Bool.and(S.is_keep(S.upd_hb(f, e, bh)), S.is_keep(S.upd_tack(f, e, bt, bh)))))

# D18 a heartbeat touches the heartbeat counter and nothing else
def pr_d18(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  S.implies(is_heartbeat(e), Bool.and(fin_eq(f, f2), S.is_keep(S.upd_tack(f, e, bt, bh))))
# ---------------------------------------------------------------------------
# The remaining DEMAND and FRAME laws E1..E11 (audit #5). D1..D18 still left eight holes:
# eleven of twenty-five new mutants survived them. These are properties of the same cell
# (o, f, e, bt, bh) with f2 = step_fin(o, f, e, bt, bh). D5 and D9 are kept: they are the
# one-sided halves of E6 and E11, documented as derived rather than removed.
# ---------------------------------------------------------------------------

def is_local(e: S.Ev) -> Bool:
  match e:
    case S.Local{u}:
      True{}
    case _:
      False{}

def upd_rank(u: S.Upd) -> Nat:
  match u:
    case S.CKeep{}:
      0n
    case S.CReset{}:
      1n
    case S.CInc{}:
      2n

def upd_eq(a: S.Upd, b: S.Upd) -> Bool:
  Nat.is_eq(upd_rank(a), upd_rank(b))

# no unit acquires an inhibit across the step
def no_new_inh(u: S.Heat, u2: S.Heat) -> Bool:
  S.implies(Bool.not(S.is_inh(u)), Bool.not(S.is_inh(u2)))

# E1 only a local alarm creates an inhibit. Without it, losing the plasma could LATCH the
# units instead of de-energizing them -- a permanent availability loss no operator action
# clears -- and every law would still pass, because they all say only `unpowered(u2)`.
def pr_e1(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(Bool.not(is_local(e)),
          Bool.and(no_new_inh(S.nb_of(f), S.nb_of(f2)), no_new_inh(S.rf_of(f), S.rf_of(f2))))

# E2 the DMS fires only on the plant acknowledgement or on the acknowledgement timeout
def pr_e2(+f: S.Fin, +e: S.Ev, +bt: Bool, +f2: S.Fin) -> Bool:
  S.implies(Bool.and(S.is_armed(S.dms_of(f)), is_fired(S.dms_of(f2))),
          Bool.or(is_heatack(e), Bool.and(is_tick(e), Bool.not(bt))))

# the phase a Stop leaves behind: Termination exactly when an ACCEPTED JTT asks for it
def e3_phase(jtt_accepted: Bool, p: S.Phase) -> S.Phase:
  match jtt_accepted:
    case True{}:
      S.Termination{}
    case False{}:
      p

# E3 a stop moves the phase to Termination exactly when an accepted JTT asks for it
def pr_e3(+o: S.Ord, +f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  +req = ev_req(e)
  S.implies(is_stop(e),
          phase_eq(S.phase_of(f2), e3_phase(Bool.and(S.is_jtt(req), S.lvl_lt(o, S.level_of(f), req)), S.phase_of(f))))

# E4 the units after an Advance are fully determined (D3 covered only one of the six)
def pr_e4(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  +nxt = S.next_phase(S.phase_of(f))
  S.implies(Bool.and(is_advance(e), Bool.and(Bool.not(S.is_ptn(S.level_of(f))), Bool.not(S.is_term(S.phase_of(f))))),
          Bool.and(unit_eq(S.nb_of(f2), S.adv_unit(nxt, S.nb_of(f))), unit_eq(S.rf_of(f2), S.adv_unit(nxt, S.rf_of(f)))))

# E5 a heartbeat always restarts the watchdog counter. Nothing demanded this: D18 framed the
# control and the wait counter and forgot hb, and D6 only PERMITS a heartbeat to reset.
def pr_e5(+f: S.Fin, +e: S.Ev, +bh: Bool) -> Bool:
  S.implies(is_heartbeat(e), S.is_creset(S.upd_hb(f, e, bh)))

# the exact watchdog command on a Tick, spelled out
def hb_tick_exp(bh: Bool, l: S.Level) -> S.Upd:
  match bh l:
    case True{} S.LPtn{}:
      S.CKeep{}
    case True{} _:
      S.CInc{}
    case False{} _:
      S.CKeep{}

# E6 the watchdog counter on a Tick is exactly determined (two-sided D5): without the
# verdict guard the counter runs past its limit and no law sees it, because the step that
# would have exposed it latches the PTN and vacates every hypothesis.
def pr_e6(+f: S.Fin, +e: S.Ev, +bh: Bool) -> Bool:
  S.implies(is_tick(e), upd_eq(S.upd_hb(f, e, bh), hb_tick_exp(bh, S.level_of(f))))

# E7 only a Tick with the DMS armed and the wait below the limit may increment it
def pr_e7(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> Bool:
  S.implies(is_cinc(S.upd_tack(f, e, bt, bh)), Bool.and(is_tick(e), Bool.and(S.is_armed(S.dms_of(f)), bt)))

# E8 only a demand that actually arms, or the accepted end of pulse, restarts the wait. The
# guard is spelled out, not taken from the model own reset_ok (same discipline as D10).
def pr_e8(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> Bool:
  S.implies(S.is_creset(S.upd_tack(f, e, bt, bh)),
          Bool.or(Bool.and(is_reset(e), Bool.and(Bool.or(S.is_ptn(S.level_of(f)), S.is_term(S.phase_of(f))), Bool.not(S.is_armed(S.dms_of(f))))),
                  Bool.and(demands_dms(e, bh, S.level_of(f)), S.is_idle(S.dms_of(f)))))

# the mitigation sequence after an acknowledgement, spelled out
def ack_exp(d: S.Dms) -> S.Dms:
  match d:
    case S.DmsArmed{}:
      S.DmsFired{}
    case d2:
      d2

# E11 the acknowledgement is two-sided (D9 is its positive half)
def pr_e11(+f: S.Fin, +e: S.Ev, +f2: S.Fin) -> Bool:
  S.implies(is_heatack(e), dms_eq(S.dms_of(f2), ack_exp(S.dms_of(f))))
