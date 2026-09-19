# seq3.bend - the discharge sequencer of seq/seq.bend, redesigned for cheap proofs.
#
# Same phases, events, rules and invariants (LAWS_SEQ3.bend states the same laws), but
# the state is split into a FINITE control part and two counters, and every decision
# is finite: the two comparisons on the counters enter the control as Bool verdicts
# (bt, bh), and the control answers with counter COMMANDS (Keep / Reset / Inc) instead
# of touching the counters itself. Consequences:
#   * the finite control `step_fin(f, e, bt, bh)` is a function on a finite domain
#     (448 states x 18 events x 4 verdicts): every property of it is decided by the
#     checker by computation, and, because bt/bh are quantified over Bool, the
#     certificate covers EVERY counter value, not a grid;
#   * the only inductive proofs left are two small lemmas about apply(Inc, n).
# enum3.bend also certifies that this model steps exactly like seq/seq.bend.

import Base

type Phase is Data:
  Idle{}
  Charged{}
  Prefill{}
  Breakdown{}
  FlatTop{}
  RampDown{}
  Shutdown{}

# the finite control state: phase, sensors (vac, tf, dens), actuators (gas, cs, heat)
type Fin is Data:
  Fin{phase: Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool}

# a command to a counter
type Upd is Data:
  CKeep{}
  CReset{}
  CInc{}

type St is Data:
  St{fin: Fin, t_flat: Nat, hb: Nat}

type Ev is Data:
  Tick{}
  Heartbeat{}
  Vac{ok: Bool}
  Tf{ok: Bool}
  Dens{ok: Bool}
  CmdCharge{}
  CmdPuff{}
  CmdBreakdown{}
  CmdFlatTop{}
  CmdHeatOn{}
  CmdHeatOff{}
  CmdRampDown{}
  Disruption{}
  Abort{}
  Reset{}

def t_max() -> Nat:
  4n

def hb_max() -> Nat:
  3n

# ---------------------------------------------------------------------------
# Phase predicates
# ---------------------------------------------------------------------------

def is_plasma(p: Phase) -> Bool:
  match p:
    case Prefill{}:
      True{}
    case Breakdown{}:
      True{}
    case FlatTop{}:
      True{}
    case RampDown{}:
      True{}
    case _:
      False{}

def is_watched(p: Phase) -> Bool:
  match p:
    case Idle{}:
      False{}
    case Shutdown{}:
      False{}
    case _:
      True{}

def is_cs_phase(p: Phase) -> Bool:
  match p:
    case Breakdown{}:
      True{}
    case FlatTop{}:
      True{}
    case RampDown{}:
      True{}
    case _:
      False{}

def is_flattop(p: Phase) -> Bool:
  match p:
    case FlatTop{}:
      True{}
    case _:
      False{}

def is_prefill(p: Phase) -> Bool:
  match p:
    case Prefill{}:
      True{}
    case _:
      False{}

def is_shutdown(p: Phase) -> Bool:
  match p:
    case Shutdown{}:
      True{}
    case _:
      False{}

def phase_of(f: Fin) -> Phase:
  match f:
    case Fin{phase, vac, tf, dens, gas, cs, heat}:
      phase

# ---------------------------------------------------------------------------
# The finite control
# ---------------------------------------------------------------------------

def init_fin() -> Fin:
  Fin{Idle{}, False{}, False{}, False{}, False{}, False{}, False{}}

def init() -> St:
  St{init_fin(), 0n, 0n}

def shutdown_fin(f: Fin) -> Fin:
  match f:
    case Fin{phase, vac, tf, dens, gas, cs, heat}:
      Fin{Shutdown{}, vac, tf, dens, False{}, False{}, False{}}

# interlock after a sensor update
def guard_heat(dens: Bool, f: Fin) -> Fin:
  match dens f:
    case True{} f2:
      f2
    case False{} Fin{phase, vac, tf, d, gas, cs, heat}:
      Fin{phase, vac, tf, d, gas, cs, False{}}

def guard_dens(f: Fin) -> Fin:
  match f:
    case Fin{phase, vac, tf, +dens, gas, cs, heat}:
      guard_heat(dens, Fin{phase, vac, tf, dens, gas, cs, heat})

def guard(plasma: Bool, field_ok: Bool, f: Fin) -> Fin:
  match plasma field_ok:
    case True{} False{}:
      shutdown_fin(f)
    case _ _:
      guard_dens(f)

def interlock(f: Fin) -> Fin:
  match f:
    case Fin{+phase, +vac, +tf, dens, gas, cs, heat}:
      guard(is_plasma(phase), Bool.and(vac, tf), Fin{phase, vac, tf, dens, gas, cs, heat})

def set_vac(f: Fin, ok: Bool) -> Fin:
  match f:
    case Fin{phase, vac, tf, dens, gas, cs, heat}:
      interlock(Fin{phase, ok, tf, dens, gas, cs, heat})

def set_tf(f: Fin, ok: Bool) -> Fin:
  match f:
    case Fin{phase, vac, tf, dens, gas, cs, heat}:
      interlock(Fin{phase, vac, ok, dens, gas, cs, heat})

def set_dens(f: Fin, ok: Bool) -> Fin:
  match f:
    case Fin{phase, vac, tf, dens, gas, cs, heat}:
      interlock(Fin{phase, vac, tf, ok, gas, cs, heat})

# the control cycle: bt = (1 + t_flat < t_max), bh = (1 + hb < hb_max)
# in flat-top, at the pulse-length limit, ramp down with heating off
def tick_flat(bt: Bool, f: Fin) -> Fin:
  match bt f:
    case True{} f2:
      f2
    case False{} Fin{phase, vac, tf, dens, gas, cs, heat}:
      Fin{RampDown{}, vac, tf, dens, gas, cs, False{}}

def tick_phase(bt: Bool, f: Fin) -> Fin:
  match f:
    case Fin{FlatTop{}, vac, tf, dens, gas, cs, heat}:
      tick_flat(bt, Fin{FlatTop{}, vac, tf, dens, gas, cs, heat})
    case f2:
      f2

# a missed-heartbeat limit shuts down; otherwise the flat-top logic runs
def tick_hb(bh: Bool, bt: Bool, f: Fin) -> Fin:
  match bh:
    case True{}:
      tick_phase(bt, f)
    case False{}:
      shutdown_fin(f)

def tick_watched(w: Bool, bt: Bool, bh: Bool, f: Fin) -> Fin:
  match w:
    case False{}:
      tick_phase(bt, f)
    case True{}:
      tick_hb(bh, bt, f)

def tick_fin(f: Fin, bt: Bool, bh: Bool) -> Fin:
  match f:
    case Fin{+phase, vac, tf, dens, gas, cs, heat}:
      tick_watched(is_watched(phase), bt, bh, Fin{phase, vac, tf, dens, gas, cs, heat})

def charge_fin(f: Fin) -> Fin:
  match f:
    case Fin{Idle{}, True{}, tf, dens, gas, cs, heat}:
      Fin{Charged{}, True{}, tf, dens, gas, cs, heat}
    case f2:
      f2

def puff_fin(f: Fin) -> Fin:
  match f:
    case Fin{Charged{}, True{}, True{}, dens, gas, cs, heat}:
      Fin{Prefill{}, True{}, True{}, dens, True{}, cs, heat}
    case f2:
      f2

def breakdown_fin(f: Fin) -> Fin:
  match f:
    case Fin{Prefill{}, True{}, True{}, dens, gas, cs, heat}:
      Fin{Breakdown{}, True{}, True{}, dens, False{}, True{}, heat}
    case f2:
      f2

def flattop_fin(f: Fin) -> Fin:
  match f:
    case Fin{Breakdown{}, vac, tf, dens, gas, cs, heat}:
      Fin{FlatTop{}, vac, tf, dens, gas, cs, heat}
    case f2:
      f2

def heat_on_fin(f: Fin) -> Fin:
  match f:
    case Fin{FlatTop{}, vac, tf, True{}, gas, cs, heat}:
      Fin{FlatTop{}, vac, tf, True{}, gas, cs, True{}}
    case f2:
      f2

def heat_off_fin(f: Fin) -> Fin:
  match f:
    case Fin{phase, vac, tf, dens, gas, cs, heat}:
      Fin{phase, vac, tf, dens, gas, cs, False{}}

def rampdown_fin(f: Fin) -> Fin:
  match f:
    case Fin{FlatTop{}, vac, tf, dens, gas, cs, heat}:
      Fin{RampDown{}, vac, tf, dens, gas, cs, False{}}
    case Fin{Breakdown{}, vac, tf, dens, gas, cs, heat}:
      Fin{RampDown{}, vac, tf, dens, gas, cs, False{}}
    case f2:
      f2

def reset_fin(f: Fin) -> Fin:
  match f:
    case Fin{RampDown{}, vac, tf, dens, gas, cs, heat}:
      Fin{Idle{}, vac, tf, dens, False{}, False{}, False{}}
    case Fin{Shutdown{}, vac, tf, dens, gas, cs, heat}:
      Fin{Idle{}, vac, tf, dens, False{}, False{}, False{}}
    case f2:
      f2

# the next finite state
def step_fin(f: Fin, e: Ev, bt: Bool, bh: Bool) -> Fin:
  match e:
    case Tick{}:
      tick_fin(f, bt, bh)
    case Heartbeat{}:
      f
    case Vac{ok}:
      set_vac(f, ok)
    case Tf{ok}:
      set_tf(f, ok)
    case Dens{ok}:
      set_dens(f, ok)
    case CmdCharge{}:
      charge_fin(f)
    case CmdPuff{}:
      puff_fin(f)
    case CmdBreakdown{}:
      breakdown_fin(f)
    case CmdFlatTop{}:
      flattop_fin(f)
    case CmdHeatOn{}:
      heat_on_fin(f)
    case CmdHeatOff{}:
      heat_off_fin(f)
    case CmdRampDown{}:
      rampdown_fin(f)
    case Disruption{}:
      shutdown_fin(f)
    case Abort{}:
      shutdown_fin(f)
    case Reset{}:
      reset_fin(f)

# ---------------------------------------------------------------------------
# Counter commands (finite functions of the control state, the event, the verdicts)
# ---------------------------------------------------------------------------

# the flat-top counter: +1 on a tick in flat-top that stays in flat-top (heartbeat ok,
# below the limit); reset when flat-top starts and on Reset; kept otherwise
def upd_t_tick(w: Bool, bh: Bool, flat: Bool, bt: Bool) -> Upd:
  match w bh flat bt:
    case True{} True{} True{} True{}:
      CInc{}
    case _ _ _ _:
      CKeep{}

def accepted_reset(p: Phase) -> Bool:
  match p:
    case RampDown{}:
      True{}
    case Shutdown{}:
      True{}
    case _:
      False{}

def reset_if(b: Bool) -> Upd:
  match b:
    case True{}:
      CReset{}
    case False{}:
      CKeep{}

def is_breakdown(p: Phase) -> Bool:
  match p:
    case Breakdown{}:
      True{}
    case _:
      False{}

def upd_t(f: Fin, e: Ev, bt: Bool, bh: Bool) -> Upd:
  match f:
    case Fin{+phase, vac, tf, dens, gas, cs, heat}:
      match e:
        case Tick{}:
          upd_t_tick(is_watched(phase), bh, is_flattop(phase), bt)
        case CmdFlatTop{}:
          reset_if(is_breakdown(phase))
        case Reset{}:
          reset_if(accepted_reset(phase))
        case _:
          CKeep{}

# the heartbeat counter: +1 on a tick in a watched phase below the limit; reset by a
# heartbeat, when the coils are charged (entering the watched phases) and on Reset
def upd_hb_tick(w: Bool, bh: Bool) -> Upd:
  match w bh:
    case True{} True{}:
      CInc{}
    case _ _:
      CKeep{}

def charge_accepted(p: Phase, vac: Bool) -> Bool:
  match p vac:
    case Idle{} True{}:
      True{}
    case _ _:
      False{}

def upd_hb(f: Fin, e: Ev, bh: Bool) -> Upd:
  match f:
    case Fin{+phase, vac, tf, dens, gas, cs, heat}:
      match e:
        case Tick{}:
          upd_hb_tick(is_watched(phase), bh)
        case Heartbeat{}:
          CReset{}
        case CmdCharge{}:
          reset_if(charge_accepted(phase, vac))
        case Reset{}:
          reset_if(accepted_reset(phase))
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
# The step, the run
# ---------------------------------------------------------------------------

def step_at(f: Fin, e: Ev, bt: Bool, bh: Bool, t: Nat, hb: Nat) -> St:
  +f2 = f
  +e2 = e
  +bt2 = bt
  +bh2 = bh
  St{step_fin(f2, e2, bt2, bh2), apply(upd_t(f2, e2, bt2, bh2), t), apply(upd_hb(f2, e2, bh2), hb)}

def step(s: St, e: Ev) -> St:
  match s:
    case St{fin, +t, +hb}:
      step_at(fin, e, Nat.is_lt(1n+t, t_max()), Nat.is_lt(1n+hb, hb_max()), t, hb)

def run(trace: List<&2, Ev>, s: St) -> St:
  match trace:
    case Nil{}:
      s
    case Con{e, t}:
      run(t, step(s, e))

# ---------------------------------------------------------------------------
# Invariants: four on the finite control, two on the counters
# ---------------------------------------------------------------------------

def l1_go(plasma: Bool, vac: Bool, tf: Bool) -> Bool:
  match plasma:
    case False{}:
      True{}
    case True{}:
      Bool.and(vac, tf)

def act_go(on: Bool, ok: Bool) -> Bool:
  match on:
    case False{}:
      True{}
    case True{}:
      ok

# L1 gas/plasma only with vacuum and field; L2 heating only in flat-top with density;
# L3 solenoid only in its phases; L4 valve only in prefill
def inv_fin(f: Fin) -> Bool:
  match f:
    case Fin{+phase, vac, tf, dens, gas, cs, heat}:
      Bool.and(l1_go(is_plasma(phase), vac, tf),
      Bool.and(act_go(heat, Bool.and(is_flattop(phase), dens)),
      Bool.and(act_go(cs, is_cs_phase(phase)),
               act_go(gas, is_prefill(phase)))))

def cnt_go(running: Bool, n: Nat, limit: Nat) -> Bool:
  match running:
    case False{}:
      True{}
    case True{}:
      Nat.is_lt(n, limit)

# L5: in flat-top the counter stays below the pulse-length limit
def l5_flat(s: St) -> Bool:
  match s:
    case St{fin, t, hb}:
      cnt_go(is_flattop(phase_of(fin)), t, t_max())

# L6: in a watched phase the heartbeat counter stays below the watchdog limit
def l6_hb(s: St) -> Bool:
  match s:
    case St{fin, t, hb}:
      cnt_go(is_watched(phase_of(fin)), hb, hb_max())

def fin_of(s: St) -> Fin:
  match s:
    case St{fin, t, hb}:
      fin

def inv_all(+s: St) -> Bool:
  Bool.and(inv_fin(fin_of(s)), Bool.and(l5_flat(s), l6_hb(s)))

# L7: the safe state has every actuator off (a consequence of L2-L4)
def l7_go(sd: Bool, gas: Bool, cs: Bool, heat: Bool) -> Bool:
  match sd:
    case False{}:
      True{}
    case True{}:
      Bool.and(Bool.not(gas), Bool.and(Bool.not(cs), Bool.not(heat)))

def l7_safe(f: Fin) -> Bool:
  match f:
    case Fin{+phase, vac, tf, dens, gas, cs, heat}:
      l7_go(is_shutdown(phase), gas, cs, heat)

# ---------------------------------------------------------------------------
# The "shape" facts that make the counter proofs trivial: whenever the next control
# state runs a counter, the command sent to it is a Reset, a Keep from a state that was
# already running it (so the old bound applies), or an Inc whose verdict said "below
# the limit". Decided by computation over the finite domain in LAWS_SEQ3.bend.
# ---------------------------------------------------------------------------

def shape_ok(u: Upd, was_running: Bool, verdict: Bool) -> Bool:
  match u:
    case CReset{}:
      True{}
    case CKeep{}:
      was_running
    case CInc{}:
      verdict

def implies(a: Bool, b: Bool) -> Bool:
  match a:
    case False{}:
      True{}
    case True{}:
      b

def t_shape(f: Fin, e: Ev, bt: Bool, bh: Bool) -> Bool:
  +f2 = f
  +e2 = e
  +bt2 = bt
  +bh2 = bh
  implies(is_flattop(phase_of(step_fin(f2, e2, bt2, bh2))),
          shape_ok(upd_t(f2, e2, bt2, bh2), is_flattop(phase_of(f2)), bt2))

def hb_shape(f: Fin, e: Ev, bt: Bool, bh: Bool) -> Bool:
  +f2 = f
  +e2 = e
  +bh2 = bh
  implies(is_watched(phase_of(step_fin(f2, e2, bt, bh2))),
          shape_ok(upd_hb(f2, e2, bh2), is_watched(phase_of(f2)), bh2))

# ---------------------------------------------------------------------------
# Printing
# ---------------------------------------------------------------------------

def show_phase(p: Phase) -> String:
  match p:
    case Idle{}:
      "Idle"
    case Charged{}:
      "Charged"
    case Prefill{}:
      "Prefill"
    case Breakdown{}:
      "Breakdown"
    case FlatTop{}:
      "FlatTop"
    case RampDown{}:
      "RampDown"
    case Shutdown{}:
      "Shutdown"

def show_st(s: St) -> String:
  match s:
    case St{Fin{phase, vac, tf, dens, gas, cs, heat}, t, hb}:
      show_phase(phase) ++ " vac=" ++ Bool.show(vac) ++ " tf=" ++ Bool.show(tf) ++ " dens=" ++ Bool.show(dens) ++
      " gas=" ++ Bool.show(gas) ++ " cs=" ++ Bool.show(cs) ++ " heat=" ++ Bool.show(heat) ++
      " t=" ++ Nat.show(t) ++ " hb=" ++ Nat.show(hb)
