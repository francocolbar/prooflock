# seq.bend - a miniature tokamak discharge sequencer with machine-protection interlocks.
#
# Discrete abstraction of a pulse: the plant control system (PCS) drives the phases
#   Idle -> Charged (TF coils at field) -> Prefill (gas puffed) -> Breakdown (CS ramp,
#   plasma initiation) -> FlatTop -> RampDown -> Idle,
# and the machine-protection interlocks force Shutdown (all actuators off) on a
# disruption, an abort, a lost vacuum or field during a plasma phase, or a missed
# heartbeat (watchdog). Heating is only allowed in flat-top with the density in its
# window; the flat-top length is bounded (coil heating).
#
# Written PROOF-SHAPED: every handler matches one thing; every decision that depends
# on a computed value (a comparison, a predicate on the phase) is passed to a helper as
# a Bool parameter, so proofs can match the same Bool. LAWS_SEQ.bend states the
# invariants; PROOF_SEQ.bend proves them for every trace. No IO here: this file is also
# loaded from JavaScript (bridge.mjs) as the golden model for differential testing.

import Base

# ---------------------------------------------------------------------------
# Types
# ---------------------------------------------------------------------------

type Phase is Data:
  Idle{}
  Charged{}
  Prefill{}
  Breakdown{}
  FlatTop{}
  RampDown{}
  Shutdown{}

# sensors: vac (vacuum ok), tf (toroidal field at nominal), dens (density in window)
# actuators: gas (prefill valve), cs (central solenoid energized), heat (auxiliary heating)
# counters: t_flat (ticks in flat-top), hb (ticks since the last PCS heartbeat)
type St is Data:
  St{phase: Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t_flat: Nat, hb: Nat}

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

# pulse-length limit (ticks of flat-top) and watchdog limit (ticks without heartbeat)
def t_max() -> Nat:
  4n

def hb_max() -> Nat:
  3n

# ---------------------------------------------------------------------------
# Phase predicates
# ---------------------------------------------------------------------------

# gas or plasma in the vessel: vacuum and field are mandatory
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

# phases in which the PCS heartbeat is required
def is_watched(p: Phase) -> Bool:
  match p:
    case Idle{}:
      False{}
    case Shutdown{}:
      False{}
    case _:
      True{}

# phases in which the central solenoid may be energized
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

# ---------------------------------------------------------------------------
# The controller
# ---------------------------------------------------------------------------

def init() -> St:
  St{Idle{}, False{}, False{}, False{}, False{}, False{}, False{}, 0n, 0n}

# the safe state: every actuator off, sensors and counters kept
def shutdown(s: St) -> St:
  match s:
    case St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      St{Shutdown{}, vac, tf, dens, False{}, False{}, False{}, t, hb}

# -- interlock re-evaluated after every sensor update --

# heating needs the density in its window
def guard_heat(dens: Bool, s: St) -> St:
  match dens s:
    case True{} s2:
      s2
    case False{} St{phase, vac, tf, d, gas, cs, heat, t, hb}:
      St{phase, vac, tf, d, gas, cs, False{}, t, hb}

def guard_dens(s: St) -> St:
  match s:
    case St{phase, vac, tf, +dens, gas, cs, heat, t, hb}:
      guard_heat(dens, St{phase, vac, tf, dens, gas, cs, heat, t, hb})

# a plasma phase without vacuum or field shuts the machine down
def guard(plasma: Bool, field_ok: Bool, s: St) -> St:
  match plasma field_ok:
    case True{} False{}:
      shutdown(s)
    case _ _:
      guard_dens(s)

def interlock(s: St) -> St:
  match s:
    case St{+phase, +vac, +tf, dens, gas, cs, heat, t, hb}:
      guard(is_plasma(phase), Bool.and(vac, tf), St{phase, vac, tf, dens, gas, cs, heat, t, hb})

def on_vac(s: St, ok: Bool) -> St:
  match s:
    case St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock(St{phase, ok, tf, dens, gas, cs, heat, t, hb})

def on_tf(s: St, ok: Bool) -> St:
  match s:
    case St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock(St{phase, vac, ok, dens, gas, cs, heat, t, hb})

def on_dens(s: St, ok: Bool) -> St:
  match s:
    case St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock(St{phase, vac, tf, ok, gas, cs, heat, t, hb})

# -- the control cycle --

# b = (1 + t_flat < t_max): stay in flat-top, or ramp down (heating off) at the limit
def tick_flat(b: Bool, s: St) -> St:
  match b s:
    case True{} St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      St{phase, vac, tf, dens, gas, cs, heat, 1n+t, hb}
    case False{} St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      St{RampDown{}, vac, tf, dens, gas, cs, False{}, t, hb}

# the flat-top counter advances only in flat-top
def tick_phase(s: St) -> St:
  match s:
    case St{FlatTop{}, vac, tf, dens, gas, cs, heat, +t, hb}:
      tick_flat(Nat.is_lt(1n+t, t_max()), St{FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb})
    case s2:
      s2

# b = (1 + hb < hb_max): count the missed heartbeat, or shut down at the limit
def tick_hb(b: Bool, s: St) -> St:
  match b s:
    case True{} St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      tick_phase(St{phase, vac, tf, dens, gas, cs, heat, t, 1n+hb})
    case False{} s2:
      shutdown(s2)

# the watchdog only runs in watched phases
def watched(w: Bool, s: St) -> St:
  match w s:
    case False{} s2:
      tick_phase(s2)
    case True{} St{phase, vac, tf, dens, gas, cs, heat, t, +hb}:
      tick_hb(Nat.is_lt(1n+hb, hb_max()), St{phase, vac, tf, dens, gas, cs, heat, t, hb})

def on_tick(s: St) -> St:
  match s:
    case St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      watched(is_watched(phase), St{phase, vac, tf, dens, gas, cs, heat, t, hb})

def on_heartbeat(s: St) -> St:
  match s:
    case St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      St{phase, vac, tf, dens, gas, cs, heat, t, 0n}

# -- operator / PCS commands: each is accepted only in its phase and with its permissives --

# charge the TF coils: only from Idle with vacuum; enters the watched phases with a fresh watchdog
def on_charge(s: St) -> St:
  match s:
    case St{Idle{}, True{}, tf, dens, gas, cs, heat, t, hb}:
      St{Charged{}, True{}, tf, dens, gas, cs, heat, t, 0n}
    case s2:
      s2

# gas prefill: only with coils charged, vacuum and field
def on_puff(s: St) -> St:
  match s:
    case St{Charged{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      St{Prefill{}, True{}, True{}, dens, True{}, cs, heat, t, hb}
    case s2:
      s2

# CS ramp / breakdown: only after prefill, with vacuum and field; the valve closes, the solenoid goes on
def on_breakdown(s: St) -> St:
  match s:
    case St{Prefill{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      St{Breakdown{}, True{}, True{}, dens, False{}, True{}, heat, t, hb}
    case s2:
      s2

# plasma current at target: flat-top starts with a fresh pulse-length counter
def on_flattop(s: St) -> St:
  match s:
    case St{Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      St{FlatTop{}, vac, tf, dens, gas, cs, heat, 0n, hb}
    case s2:
      s2

# auxiliary heating: only in flat-top with the density in its window
def on_heat_on(s: St) -> St:
  match s:
    case St{FlatTop{}, vac, tf, True{}, gas, cs, heat, t, hb}:
      St{FlatTop{}, vac, tf, True{}, gas, cs, True{}, t, hb}
    case s2:
      s2

def on_heat_off(s: St) -> St:
  match s:
    case St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      St{phase, vac, tf, dens, gas, cs, False{}, t, hb}

# controlled termination from breakdown or flat-top; heating off
def on_rampdown(s: St) -> St:
  match s:
    case St{FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      St{RampDown{}, vac, tf, dens, gas, cs, False{}, t, hb}
    case St{Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      St{RampDown{}, vac, tf, dens, gas, cs, False{}, t, hb}
    case s2:
      s2

# back to Idle after a completed ramp-down or from the safe state; actuators and counters cleared
def on_reset(s: St) -> St:
  match s:
    case St{RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      St{Idle{}, vac, tf, dens, False{}, False{}, False{}, 0n, 0n}
    case St{Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      St{Idle{}, vac, tf, dens, False{}, False{}, False{}, 0n, 0n}
    case s2:
      s2

def step(s: St, e: Ev) -> St:
  match e:
    case Tick{}:
      on_tick(s)
    case Heartbeat{}:
      on_heartbeat(s)
    case Vac{ok}:
      on_vac(s, ok)
    case Tf{ok}:
      on_tf(s, ok)
    case Dens{ok}:
      on_dens(s, ok)
    case CmdCharge{}:
      on_charge(s)
    case CmdPuff{}:
      on_puff(s)
    case CmdBreakdown{}:
      on_breakdown(s)
    case CmdFlatTop{}:
      on_flattop(s)
    case CmdHeatOn{}:
      on_heat_on(s)
    case CmdHeatOff{}:
      on_heat_off(s)
    case CmdRampDown{}:
      on_rampdown(s)
    case Disruption{}:
      shutdown(s)
    case Abort{}:
      shutdown(s)
    case Reset{}:
      on_reset(s)

def run(trace: List<&2, Ev>, s: St) -> St:
  match trace:
    case Nil{}:
      s
    case Con{e, t}:
      run(t, step(s, e))

def phase_of(s: St) -> Phase:
  match s:
    case St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      phase

# ---------------------------------------------------------------------------
# The safety invariants (decidable; each reads one field group). The `_go`
# helpers take the decision inputs as Bools so proofs can match on them.
# ---------------------------------------------------------------------------

def l1_go(plasma: Bool, vac: Bool, tf: Bool) -> Bool:
  match plasma:
    case False{}:
      True{}
    case True{}:
      Bool.and(vac, tf)

# L1: gas or plasma in the vessel only with vacuum and field
def l1_field(s: St) -> Bool:
  match s:
    case St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      l1_go(is_plasma(phase), vac, tf)

def l2_go(heat: Bool, flat: Bool, dens: Bool) -> Bool:
  match heat:
    case False{}:
      True{}
    case True{}:
      Bool.and(flat, dens)

# L2: heating only in flat-top with the density in its window
def l2_heat(s: St) -> Bool:
  match s:
    case St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      l2_go(heat, is_flattop(phase), dens)

# an actuator flag is only allowed when its permissive holds
def act_go(on: Bool, ok: Bool) -> Bool:
  match on:
    case False{}:
      True{}
    case True{}:
      ok

# L3: the solenoid is energized only in breakdown / flat-top / ramp-down
def l3_cs(s: St) -> Bool:
  match s:
    case St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      act_go(cs, is_cs_phase(phase))

# L4: the prefill valve is open only during prefill
def l4_gas(s: St) -> Bool:
  match s:
    case St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      act_go(gas, is_prefill(phase))

# a counter is only bounded where it is running
def cnt_go(running: Bool, n: Nat, limit: Nat) -> Bool:
  match running:
    case False{}:
      True{}
    case True{}:
      Nat.is_lt(n, limit)

# L5: the flat-top counter stays below the pulse-length limit
def l5_flat(s: St) -> Bool:
  match s:
    case St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      cnt_go(is_flattop(phase), t, t_max())

# L6: in a watched phase the heartbeat counter stays below the watchdog limit
def l6_hb(s: St) -> Bool:
  match s:
    case St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      cnt_go(is_watched(phase), hb, hb_max())

def l7_go(sd: Bool, gas: Bool, cs: Bool, heat: Bool) -> Bool:
  match sd:
    case False{}:
      True{}
    case True{}:
      Bool.and(Bool.not(gas), Bool.and(Bool.not(cs), Bool.not(heat)))

# L7 (a consequence of L2-L4, stated because it is what an operator wants to read):
# the safe state has every actuator off
def l7_safe(s: St) -> Bool:
  match s:
    case St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      l7_go(is_shutdown(phase), gas, cs, heat)

def inv_all(+s: St) -> Bool:
  Bool.and(l1_field(s), Bool.and(l2_heat(s), Bool.and(l3_cs(s), Bool.and(l4_gas(s), Bool.and(l5_flat(s), l6_hb(s))))))

# ---------------------------------------------------------------------------
# Printing (for the smoke tests and the JS bridge)
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
    case St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      show_phase(phase) ++ " vac=" ++ Bool.show(vac) ++ " tf=" ++ Bool.show(tf) ++ " dens=" ++ Bool.show(dens) ++
      " gas=" ++ Bool.show(gas) ++ " cs=" ++ Bool.show(cs) ++ " heat=" ++ Bool.show(heat) ++
      " t=" ++ Nat.show(t) ++ " hb=" ++ Nat.show(hb)
