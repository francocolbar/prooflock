# jetprot.bend - a reference model of the JET wall-protection chain: the RTPS "Stop
# Selector" (Stephen et al., ICALEPCS 2011), its interface to the Pulse Termination Network
# (PTN) and the arming sequence of the Disruption Mitigation System (DMS). Design and
# sources: docs/fase3-diseno.md, docs/fase3-fuente.md (requirements R-n, hypotheses A-n).
#
# Pattern (v2/seq3): the state is a FINITE control `Fin` plus two counters driven by
# commands; every decision is finite, so every property of `step_fin` is decided by the
# checker by computation over the whole domain (enum_jetprot.bend) and lifted to universal
# laws by reflection (PROOF_JETPROT.bend). Two layers:
#   * the ABSTRACT alphabet `Ev` carries the configuration as event payload (which response
#     an alarm asks for, whether the stop arms the DMS), so the laws hold for EVERY
#     configuration;
#   * the CONCRETE alphabet `CEv` is the plant's (seven stop triggers, ...); `concretize`
#     maps it to `Ev` through a configuration instance (`Inst`).
# The urgency order between the two soft responses (JTT, RTPS: hypothesis A-1) is a
# parameter `Ord`, so the sensitivity check C3 is a theorem, not a gate.

import Base

# ---------------------------------------------------------------------------
# Types
# ---------------------------------------------------------------------------

# pulse phases (instance of configuration, R-1/R-5, A-5), in program order
type Phase is Data:
  Breakdown{}
  IpRise{}
  Limiter{}
  Xpoint{}
  Heating1{}
  Heating2{}
  Termination{}

# stop response in force: none, jump-to-termination, programmable RTPS stop, PTN (latched)
type Level is Data:
  LNone{}
  LJtt{}
  LRtps{}
  LPtn{}

# the disruption-mitigation sequence
type Dms is Data:
  DmsIdle{}
  DmsArmed{}
  DmsFired{}

# one heating unit: off; inhibited by local protection; ramping down under a stop; at
# full requested power
type Heat is Data:
  Off{}
  Inhibited{}
  Ramping{}
  On{}

# the two heating units (A-6): neutral beams, radio-frequency
type Who is Data:
  Nb{}
  Rf{}

# which of the two soft responses is the more urgent (A-1): Ord1 = JTT < RTPS (chosen),
# Ord2 = RTPS < JTT (the sensitivity check C3)
type Ord is Data:
  Ord1{}
  Ord2{}

# the finite control state
type Fin is Data:
  Fin{phase: Phase, level: Level, dms: Dms, plasma: Bool, nb: Heat, rf: Heat}

# a command to a counter
type Upd is Data:
  CKeep{}
  CReset{}
  CInc{}

# control + counters: hb = ticks without heartbeat, tack = ticks waiting for the DMS ack
type St is Data:
  St{fin: Fin, hb: Nat, tack: Nat}

# the ABSTRACT alphabet (configuration as payload)
type Ev is Data:
  Advance{}
  Stop{req: Level, dms: Bool}
  Local{u: Who}
  HeatOn{u: Who}
  HeatOff{u: Who}
  Plasma{ok: Bool}
  CommFault{dms: Bool}
  Heartbeat{}
  Tick{dms: Bool}
  HeatAck{}
  Reset{}

# the seven stop triggers of R-2
type Trig is Data:
  Slow{}
  Fast{}
  Mhd{}
  MhdB{}
  Mchs{}
  Dhs{}
  BothHs{}

# the CONCRETE alphabet (the plant's events)
type CEv is Data:
  XAdvance{}
  XAlarm{t: Trig}
  XLocal{u: Who}
  XHeatOn{u: Who}
  XHeatOff{u: Who}
  XPlasma{ok: Bool}
  XCommFault{}
  XHeartbeat{}
  XTick{}
  XHeatAck{}
  XReset{}

# configuration instances: Inst1 = Table 1 of [S1] as published (+ A-4); Inst2 = the same
# with the MHD triggers routed to PTN from X-point on (the path JET operated, [S6]/[S7])
type Inst is Data:
  Inst1{}
  Inst2{}

def hb_max() -> Nat:
  3n

def ack_max() -> Nat:
  2n

# ---------------------------------------------------------------------------
# Small predicates
# ---------------------------------------------------------------------------

def is_ptn(l: Level) -> Bool:
  match l:
    case LPtn{}:
      True{}
    case _:
      False{}

def is_none(l: Level) -> Bool:
  match l:
    case LNone{}:
      True{}
    case _:
      False{}

def is_jtt(l: Level) -> Bool:
  match l:
    case LJtt{}:
      True{}
    case _:
      False{}

def is_soft(l: Level) -> Bool:
  match l:
    case LJtt{}:
      True{}
    case LRtps{}:
      True{}
    case _:
      False{}

def is_term(p: Phase) -> Bool:
  match p:
    case Termination{}:
      True{}
    case _:
      False{}

# the heating enable window of the instance (A-5): both units, Heating 1 and 2
def heat_win(p: Phase) -> Bool:
  match p:
    case Heating1{}:
      True{}
    case Heating2{}:
      True{}
    case _:
      False{}

def is_idle(d: Dms) -> Bool:
  match d:
    case DmsIdle{}:
      True{}
    case _:
      False{}

def is_armed(d: Dms) -> Bool:
  match d:
    case DmsArmed{}:
      True{}
    case _:
      False{}

def is_on(u: Heat) -> Bool:
  match u:
    case On{}:
      True{}
    case _:
      False{}

def is_ramping(u: Heat) -> Bool:
  match u:
    case Ramping{}:
      True{}
    case _:
      False{}

def is_inh(u: Heat) -> Bool:
  match u:
    case Inhibited{}:
      True{}
    case _:
      False{}

def is_off(u: Heat) -> Bool:
  match u:
    case Off{}:
      True{}
    case _:
      False{}

# not On and not Ramping
def unpowered(u: Heat) -> Bool:
  match u:
    case Off{}:
      True{}
    case Inhibited{}:
      True{}
    case _:
      False{}

def implies(a: Bool, b: Bool) -> Bool:
  match a:
    case False{}:
      True{}
    case True{}:
      b

def lvl_rank(o: Ord, l: Level) -> Nat:
  match o l:
    case _ LNone{}:
      0n
    case Ord1{} LJtt{}:
      1n
    case Ord1{} LRtps{}:
      2n
    case Ord2{} LJtt{}:
      2n
    case Ord2{} LRtps{}:
      1n
    case _ LPtn{}:
      3n

def lvl_lt(o: Ord, a: Level, b: Level) -> Bool:
  +o2 = o
  Nat.is_lt(lvl_rank(o2, a), lvl_rank(o2, b))

def phase_rank(p: Phase) -> Nat:
  match p:
    case Breakdown{}:
      0n
    case IpRise{}:
      1n
    case Limiter{}:
      2n
    case Xpoint{}:
      3n
    case Heating1{}:
      4n
    case Heating2{}:
      5n
    case Termination{}:
      6n

def dms_rank(d: Dms) -> Nat:
  match d:
    case DmsIdle{}:
      0n
    case DmsArmed{}:
      1n
    case DmsFired{}:
      2n

def unit_rank(u: Heat) -> Nat:
  match u:
    case Off{}:
      0n
    case Inhibited{}:
      1n
    case Ramping{}:
      2n
    case On{}:
      3n

def is_keep(u: Upd) -> Bool:
  match u:
    case CKeep{}:
      True{}
    case _:
      False{}

def is_creset(u: Upd) -> Bool:
  match u:
    case CReset{}:
      True{}
    case _:
      False{}

# ---------------------------------------------------------------------------
# Field access
# ---------------------------------------------------------------------------

def phase_of(f: Fin) -> Phase:
  match f:
    case Fin{p, l, d, pl, nb, rf}:
      p

def level_of(f: Fin) -> Level:
  match f:
    case Fin{p, l, d, pl, nb, rf}:
      l

def dms_of(f: Fin) -> Dms:
  match f:
    case Fin{p, l, d, pl, nb, rf}:
      d

def plasma_of(f: Fin) -> Bool:
  match f:
    case Fin{p, l, d, pl, nb, rf}:
      pl

def nb_of(f: Fin) -> Heat:
  match f:
    case Fin{p, l, d, pl, nb, rf}:
      nb

def rf_of(f: Fin) -> Heat:
  match f:
    case Fin{p, l, d, pl, nb, rf}:
      rf

def unit_of(w: Who, f: Fin) -> Heat:
  match w:
    case Nb{}:
      nb_of(f)
    case Rf{}:
      rf_of(f)

def fin_of(s: St) -> Fin:
  match s:
    case St{fin, hb, tack}:
      fin

def hb_of(s: St) -> Nat:
  match s:
    case St{fin, hb, tack}:
      hb

def tack_of(s: St) -> Nat:
  match s:
    case St{fin, hb, tack}:
      tack

# ---------------------------------------------------------------------------
# Shared helpers (docs/fase3-diseno.md §1)
# ---------------------------------------------------------------------------

def init_fin() -> Fin:
  Fin{Breakdown{}, LNone{}, DmsIdle{}, False{}, Off{}, Off{}}

def init() -> St:
  St{init_fin(), 0n, 0n}

# powered units go off; an inhibit is PRESERVED
def deenergize(u: Heat) -> Heat:
  match u:
    case On{}:
      Off{}
    case Ramping{}:
      Off{}
    case u2:
      u2

# a unit at full power starts ramping down; nothing else changes
def ramp(u: Heat) -> Heat:
  match u:
    case On{}:
      Ramping{}
    case u2:
      u2

def close_if(b: Bool, u: Heat) -> Heat:
  match b:
    case True{}:
      deenergize(u)
    case False{}:
      u

# the only way to PTN: latch the level and de-energize (R-0, R-11, A-9)
def to_ptn(f: Fin) -> Fin:
  match f:
    case Fin{p, l, d, pl, nb, rf}:
      Fin{p, LPtn{}, d, pl, deenergize(nb), deenergize(rf)}

# arm the DMS from Idle only (A-11)
def arm_dms(f: Fin) -> Fin:
  match f:
    case Fin{p, l, DmsIdle{}, pl, nb, rf}:
      Fin{p, l, DmsArmed{}, pl, nb, rf}
    case f2:
      f2

def arm_if(b: Bool, f: Fin) -> Fin:
  match b:
    case True{}:
      arm_dms(f)
    case False{}:
      f

def jtt_phase(req: Level, p: Phase) -> Phase:
  match req:
    case LJtt{}:
      Termination{}
    case _:
      p

# a soft stop: the level, the ramp-down of both units, and the jump for JTT (A-9, A-5)
def soft_apply(+req: Level, f: Fin) -> Fin:
  match f:
    case Fin{p, l, d, pl, nb, rf}:
      Fin{jtt_phase(req, p), req, d, pl, ramp(nb), ramp(rf)}

def soft_if(gt: Bool, req: Level, f: Fin) -> Fin:
  match gt:
    case True{}:
      soft_apply(req, f)
    case False{}:
      f

# ---------------------------------------------------------------------------
# The rules
# ---------------------------------------------------------------------------

# rule 1: a stop request. PTN always wins (and arms the DMS if configured, also when the
# level already was PTN); a soft request applies only if more urgent than the current one
def stop_fin(o: Ord, f: Fin, req: Level, d: Bool) -> Fin:
  match req:
    case LPtn{}:
      arm_if(d, to_ptn(f))
    case r2:
      +r3 = r2
      +f2 = f
      soft_if(lvl_lt(o, level_of(f2), r3), r3, f2)

# rule 2: local protection inhibits one unit and nothing else (R-9)
def local_fin(f: Fin, w: Who) -> Fin:
  match f w:
    case Fin{p, l, d, pl, nb, rf} Nb{}:
      Fin{p, l, d, pl, Inhibited{}, rf}
    case Fin{p, l, d, pl, nb, rf} Rf{}:
      Fin{p, l, d, pl, nb, Inhibited{}}

# rule 3: the enable permissive (R-12, A-5, A-8, A-9)
def permit_go(p: Phase, pl: Bool, l: Level) -> Bool:
  Bool.and(heat_win(p), Bool.and(pl, is_none(l)))

def permit(f: Fin) -> Bool:
  match f:
    case Fin{p, l, d, pl, nb, rf}:
      permit_go(p, pl, l)

def turn_on(ok: Bool, u: Heat) -> Heat:
  match ok u:
    case True{} Off{}:
      On{}
    case _ u2:
      u2

def heat_on_fin(f: Fin, w: Who) -> Fin:
  match f w:
    case Fin{+p, +l, d, +pl, nb, rf} Nb{}:
      Fin{p, l, d, pl, turn_on(permit_go(p, pl, l), nb), rf}
    case Fin{+p, +l, d, +pl, nb, rf} Rf{}:
      Fin{p, l, d, pl, nb, turn_on(permit_go(p, pl, l), rf)}

# rule 4
def heat_off_fin(f: Fin, w: Who) -> Fin:
  match f w:
    case Fin{p, l, d, pl, nb, rf} Nb{}:
      Fin{p, l, d, pl, deenergize(nb), rf}
    case Fin{p, l, d, pl, nb, rf} Rf{}:
      Fin{p, l, d, pl, nb, deenergize(rf)}

# rule 5: basic plasma conditions; losing them closes the window
def plasma_fin(f: Fin, ok: Bool) -> Fin:
  match f:
    case Fin{p, l, d, pl, nb, rf}:
      +ok2 = ok
      +bad = Bool.not(ok2)
      Fin{p, l, d, ok2, close_if(bad, nb), close_if(bad, rf)}

# rule 6: the pulse program moves to the next phase (frozen under PTN; identity in
# Termination); entering Termination ramps the heating down (the natural end); entering a
# phase outside the enable window closes it
def next_phase(p: Phase) -> Phase:
  match p:
    case Breakdown{}:
      IpRise{}
    case IpRise{}:
      Limiter{}
    case Limiter{}:
      Xpoint{}
    case Xpoint{}:
      Heating1{}
    case Heating1{}:
      Heating2{}
    case Heating2{}:
      Termination{}
    case Termination{}:
      Termination{}

def adv_unit(nxt: Phase, u: Heat) -> Heat:
  match nxt:
    case Termination{}:
      ramp(u)
    case n2:
      close_if(Bool.not(heat_win(n2)), u)

def advance_go(frozen: Bool, f: Fin) -> Fin:
  match frozen f:
    case True{} f2:
      f2
    case False{} Fin{p, l, d, pl, nb, rf}:
      +nxt = next_phase(p)
      Fin{nxt, l, d, pl, adv_unit(nxt, nb), adv_unit(nxt, rf)}

def advance_fin(f: Fin) -> Fin:
  match f:
    case Fin{+p, +l, d, pl, nb, rf}:
      advance_go(Bool.or(is_ptn(l), is_term(p)), Fin{p, l, d, pl, nb, rf})

# rule 8: the watchdog (bh = heartbeat below the limit) takes precedence; otherwise the
# ack timeout (bt = wait below the limit)
def fire_dms(f: Fin) -> Fin:
  match f:
    case Fin{p, l, DmsArmed{}, pl, nb, rf}:
      Fin{p, l, DmsFired{}, pl, nb, rf}
    case f2:
      f2

def fire_if(b: Bool, f: Fin) -> Fin:
  match b:
    case True{}:
      fire_dms(f)
    case False{}:
      f

def watchdog_due(f: Fin, bh: Bool) -> Bool:
  Bool.and(Bool.not(bh), Bool.not(is_ptn(level_of(f))))

def tick_go(wd: Bool, d: Bool, bt: Bool, f: Fin) -> Fin:
  match wd:
    case True{}:
      arm_if(d, to_ptn(f))
    case False{}:
      +f2 = f
      fire_if(Bool.and(is_armed(dms_of(f2)), Bool.not(bt)), f2)

def tick_fin(f: Fin, d: Bool, bt: Bool, bh: Bool) -> Fin:
  +f2 = f
  tick_go(watchdog_due(f2, bh), d, bt, f2)

# rule 11: end of pulse, guarded (A-14)
def reset_ok(f: Fin) -> Bool:
  match f:
    case Fin{+p, +l, +d, pl, nb, rf}:
      Bool.and(Bool.or(is_ptn(l), is_term(p)), Bool.not(is_armed(d)))

def reset_go(ok: Bool, f: Fin) -> Fin:
  match ok:
    case True{}:
      init_fin()
    case False{}:
      f

def reset_fin(f: Fin) -> Fin:
  +f2 = f
  reset_go(reset_ok(f2), f2)

# the next control state; the verdicts reach the Tick arm only
def step_fin(o: Ord, f: Fin, e: Ev, bt: Bool, bh: Bool) -> Fin:
  match e:
    case Advance{}:
      advance_fin(f)
    case Stop{req, dms}:
      stop_fin(o, f, req, dms)
    case Local{u}:
      local_fin(f, u)
    case HeatOn{u}:
      heat_on_fin(f, u)
    case HeatOff{u}:
      heat_off_fin(f, u)
    case Plasma{ok}:
      plasma_fin(f, ok)
    case CommFault{dms}:
      arm_if(dms, to_ptn(f))
    case Heartbeat{}:
      f
    case Tick{dms}:
      tick_fin(f, dms, bt, bh)
    case HeatAck{}:
      fire_dms(f)
    case Reset{}:
      reset_fin(f)

# ---------------------------------------------------------------------------
# Counter commands (finite functions of the control state, the event, the verdicts)
# ---------------------------------------------------------------------------

def inc_if(b: Bool) -> Upd:
  match b:
    case True{}:
      CInc{}
    case False{}:
      CKeep{}

def reset_if(b: Bool) -> Upd:
  match b:
    case True{}:
      CReset{}
    case False{}:
      CKeep{}

# hb: +1 on a tick below the limit while the PTN is not latched; reset by a heartbeat and
# by an accepted end of pulse
def upd_hb(f: Fin, e: Ev, bh: Bool) -> Upd:
  match e:
    case Tick{dms}:
      inc_if(Bool.and(bh, Bool.not(is_ptn(level_of(f)))))
    case Heartbeat{}:
      CReset{}
    case Reset{}:
      reset_if(reset_ok(f))
    case _:
      CKeep{}

# does this stop request arm the DMS now (from Idle)?
def arms_now(d: Bool, f: Fin) -> Bool:
  Bool.and(d, is_idle(dms_of(f)))

def tack_tick(wd: Bool, d: Bool, bt: Bool, f: Fin) -> Upd:
  match wd:
    case True{}:
      reset_if(arms_now(d, f))
    case False{}:
      inc_if(Bool.and(is_armed(dms_of(f)), bt))

# tack: reset when the DMS is armed; +1 on a tick while armed and below the limit; reset
# by an accepted end of pulse; kept otherwise (a repeated alarm never restarts the wait)
def upd_tack(f: Fin, e: Ev, bt: Bool, bh: Bool) -> Upd:
  match e:
    case Stop{req, dms}:
      reset_if(Bool.and(is_ptn(req), arms_now(dms, f)))
    case CommFault{dms}:
      reset_if(arms_now(dms, f))
    case Tick{dms}:
      +f2 = f
      tack_tick(watchdog_due(f2, bh), dms, bt, f2)
    case Reset{}:
      reset_if(reset_ok(f))
    case _:
      CKeep{}

def apply(u: Upd, n: Nat) -> Nat:
  match u:
    case CKeep{}:
      n
    case CReset{}:
      0n
    case CInc{}:
      1n+n

# ---------------------------------------------------------------------------
# The step, the run (abstract alphabet)
# ---------------------------------------------------------------------------

def step_at(o: Ord, f: Fin, e: Ev, bt: Bool, bh: Bool, hb: Nat, tack: Nat) -> St:
  +f2 = f
  +e2 = e
  +bt2 = bt
  +bh2 = bh
  St{step_fin(o, f2, e2, bt2, bh2), apply(upd_hb(f2, e2, bh2), hb), apply(upd_tack(f2, e2, bt2, bh2), tack)}

def step_o(o: Ord, s: St, e: Ev) -> St:
  match s:
    case St{fin, +hb, +tack}:
      step_at(o, fin, e, Nat.is_lt(1n+tack, ack_max()), Nat.is_lt(1n+hb, hb_max()), hb, tack)

def step(s: St, e: Ev) -> St:
  step_o(Ord1{}, s, e)

def run_o(+o: Ord, trace: List<&2, Ev>, s: St) -> St:
  match trace:
    case Nil{}:
      s
    case Con{e, t}:
      run_o(o, t, step_o(o, s, e))

def run(trace: List<&2, Ev>, s: St) -> St:
  run_o(Ord1{}, trace, s)

# ---------------------------------------------------------------------------
# The concrete layer: configuration instances (docs/fase3-fuente.md R-5, A-4, A-10)
# ---------------------------------------------------------------------------

# Table 1 of [S1]: 28 published cells (R-5) ...
def table1_pub(p: Phase, t: Trig) -> Level:
  match p t:
    case Heating1{} Slow{}:
      LRtps{}
    case Heating2{} Slow{}:
      LRtps{}
    case _ Slow{}:
      LPtn{}
    case _ Mhd{}:
      LNone{}
    case Heating1{} Mchs{}:
      LRtps{}
    case Heating2{} Mchs{}:
      LRtps{}
    case Termination{} Mchs{}:
      LPtn{}
    case _ Mchs{}:
      LNone{}
    case Heating2{} Dhs{}:
      LJtt{}
    case _ Dhs{}:
      LPtn{}
    case _ _:
      LNone{}

# ... and the 21 assumed cells (A-4): Fast -> PTN everywhere; MHD-B = MHD; both hotspots
# = the more urgent of MCHS and DHS under Ord1
def lvl_pick(lt: Bool, a: Level, b: Level) -> Level:
  match lt:
    case True{}:
      b
    case False{}:
      a

def lvl_max1(a: Level, b: Level) -> Level:
  +a2 = a
  +b2 = b
  lvl_pick(lvl_lt(Ord1{}, a2, b2), a2, b2)

def table1(p: Phase, t: Trig) -> Level:
  match t:
    case Fast{}:
      LPtn{}
    case MhdB{}:
      table1_pub(p, Mhd{})
    case BothHs{}:
      +p2 = p
      lvl_max1(table1_pub(p2, Mchs{}), table1_pub(p2, Dhs{}))
    case t2:
      table1_pub(p, t2)

# instance 2: the MHD triggers reach PTN from X-point on ([S6], [S7])
def table2(p: Phase, t: Trig) -> Level:
  match p t:
    case Xpoint{} Mhd{}:
      LPtn{}
    case Heating1{} Mhd{}:
      LPtn{}
    case Heating2{} Mhd{}:
      LPtn{}
    case Termination{} Mhd{}:
      LPtn{}
    case Xpoint{} MhdB{}:
      LPtn{}
    case Heating1{} MhdB{}:
      LPtn{}
    case Heating2{} MhdB{}:
      LPtn{}
    case Termination{} MhdB{}:
      LPtn{}
    case p2 t2:
      table1(p2, t2)

def table(i: Inst, p: Phase, t: Trig) -> Level:
  match i:
    case Inst1{}:
      table1(p, t)
    case Inst2{}:
      table2(p, t)

# which triggers are wired to the DMS (A-10): the disruption precursors and the fast
# termination, inside the DMV enable window of R-14 (X-point .. Termination)
def dms_trig(t: Trig) -> Bool:
  match t:
    case Fast{}:
      True{}
    case Mhd{}:
      True{}
    case MhdB{}:
      True{}
    case _:
      False{}

def dms_window(p: Phase) -> Bool:
  match p:
    case Breakdown{}:
      False{}
    case IpRise{}:
      False{}
    case Limiter{}:
      False{}
    case _:
      True{}

def dms_req(p: Phase, t: Trig) -> Bool:
  Bool.and(dms_trig(t), dms_window(p))

# the hardwired paths do not arm the DMS in either instance (A-10, A-13)
def dms_on_commfault() -> Bool:
  False{}

def dms_on_watchdog() -> Bool:
  False{}

def concretize(i: Inst, p: Phase, c: CEv) -> Ev:
  match c:
    case XAdvance{}:
      Advance{}
    case XAlarm{t}:
      +t2 = t
      +p2 = p
      Stop{table(i, p2, t2), dms_req(p2, t2)}
    case XLocal{u}:
      Local{u}
    case XHeatOn{u}:
      HeatOn{u}
    case XHeatOff{u}:
      HeatOff{u}
    case XPlasma{ok}:
      Plasma{ok}
    case XCommFault{}:
      CommFault{dms_on_commfault()}
    case XHeartbeat{}:
      Heartbeat{}
    case XTick{}:
      Tick{dms_on_watchdog()}
    case XHeatAck{}:
      HeatAck{}
    case XReset{}:
      Reset{}

def step_c(i: Inst, s: St, c: CEv) -> St:
  +s2 = s
  step(s2, concretize(i, phase_of(fin_of(s2)), c))

def run_c(+i: Inst, trace: List<&2, CEv>, s: St) -> St:
  match trace:
    case Nil{}:
      s
    case Con{c, t}:
      run_c(i, t, step_c(i, s, c))

# ---------------------------------------------------------------------------
# Invariants (docs/fase3-diseno.md §2): four on the control, two on the counters
# ---------------------------------------------------------------------------

# I1: a unit at full power is inside the window, with plasma conditions and no stop
def on_ok(u: Heat, p: Phase, pl: Bool, l: Level) -> Bool:
  implies(is_on(u), Bool.and(heat_win(p), Bool.and(pl, is_none(l))))

# I2: a ramping unit has plasma conditions, no PTN, and a soft stop or the termination
def ramp_ok(u: Heat, p: Phase, pl: Bool, l: Level) -> Bool:
  +l2 = l
  implies(is_ramping(u), Bool.and(pl, Bool.and(Bool.not(is_ptn(l2)), Bool.or(Bool.not(is_none(l2)), is_term(p)))))

def inv_fin(f: Fin) -> Bool:
  match f:
    case Fin{+p, +l, +d, +pl, +nb, +rf}:
      Bool.and(Bool.and(on_ok(nb, p, pl, l), on_ok(rf, p, pl, l)),
      Bool.and(Bool.and(ramp_ok(nb, p, pl, l), ramp_ok(rf, p, pl, l)),
      Bool.and(implies(is_jtt(l), is_term(p)),
               implies(Bool.not(is_idle(d)), is_ptn(l)))))

def cnt_go(running: Bool, n: Nat, limit: Nat) -> Bool:
  match running:
    case False{}:
      True{}
    case True{}:
      Nat.is_lt(n, limit)

# I5: while the DMS is armed, the wait stays below the limit
def i5_ack(s: St) -> Bool:
  match s:
    case St{fin, hb, tack}:
      cnt_go(is_armed(dms_of(fin)), tack, ack_max())

# I6: while the PTN is not latched, the missed heartbeats stay below the limit
def i6_hb(s: St) -> Bool:
  match s:
    case St{fin, hb, tack}:
      cnt_go(Bool.not(is_ptn(level_of(fin))), hb, hb_max())

def inv_all(+s: St) -> Bool:
  Bool.and(inv_fin(fin_of(s)), Bool.and(i5_ack(s), i6_hb(s)))

# the defined safe state
def safe(f: Fin) -> Bool:
  match f:
    case Fin{p, +l, +d, pl, +nb, +rf}:
      Bool.and(is_ptn(l), Bool.and(unpowered(nb), Bool.and(unpowered(rf), Bool.not(is_armed(d)))))


# ---------------------------------------------------------------------------
# Printing
# ---------------------------------------------------------------------------

def show_phase(p: Phase) -> String:
  match p:
    case Breakdown{}:
      "Breakdown"
    case IpRise{}:
      "IpRise"
    case Limiter{}:
      "Limiter"
    case Xpoint{}:
      "Xpoint"
    case Heating1{}:
      "Heating1"
    case Heating2{}:
      "Heating2"
    case Termination{}:
      "Termination"

def show_level(l: Level) -> String:
  match l:
    case LNone{}:
      "None"
    case LJtt{}:
      "JTT"
    case LRtps{}:
      "RTPS"
    case LPtn{}:
      "PTN"

def show_dms(d: Dms) -> String:
  match d:
    case DmsIdle{}:
      "Idle"
    case DmsArmed{}:
      "Armed"
    case DmsFired{}:
      "Fired"

def show_unit(u: Heat) -> String:
  match u:
    case Off{}:
      "Off"
    case Inhibited{}:
      "Inhibited"
    case Ramping{}:
      "Ramping"
    case On{}:
      "On"

def show_st(s: St) -> String:
  match s:
    case St{Fin{p, l, d, pl, nb, rf}, hb, tack}:
      show_phase(p) ++ " " ++ show_level(l) ++ " dms=" ++ show_dms(d) ++ " plasma=" ++ Bool.show(pl) ++
      " nb=" ++ show_unit(nb) ++ " rf=" ++ show_unit(rf) ++ " hb=" ++ Nat.show(hb) ++ " tack=" ++ Nat.show(tack)
