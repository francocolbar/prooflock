# PROOF_SEQ_B.bend - preservation of L4 (gas valve), L5 (flat-top counter), L6 (watchdog).
# One lemma per handler / helper, per invariant, mirroring the recursion of seq.bend.
# Handlers written with a `case s2:` catch-all are split explicitly here (the checker
# does not reduce a handler applied to a catch-all-bound variable), so every arm's goal
# computes and closes with `{==}` or with the refined hypothesis.
import Base
import ./seq.bend as S
import ./LAWS_SEQ.bend as Laws

# ===========================================================================
# L4: the prefill valve is open only during prefill
# ===========================================================================

def shutdown_l4(s: S.St) -> {S.l4_gas(S.shutdown(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

def guard_heat_l4(d: Bool, phase: S.Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, hb: Nat, h4: {S.l4_gas(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l4_gas(S.guard_heat(d, S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match d:
    case True{}:
      h4
    case False{}:
      h4

def guard_dens_l4(s: S.St, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.guard_dens(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, +dens, gas, cs, heat, t, hb}:
      guard_heat_l4(dens, phase, vac, tf, dens, gas, cs, heat, t, hb, h4)

def guard_l4(plasma: Bool, field_ok: Bool, s: S.St, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.guard(plasma, field_ok, s)) == True{} : Bool}:
  match plasma field_ok:
    case True{} False{}:
      shutdown_l4(s)
    case True{} True{}:
      guard_dens_l4(s, h4)
    case False{} True{}:
      guard_dens_l4(s, h4)
    case False{} False{}:
      guard_dens_l4(s, h4)

def interlock_l4(s: S.St, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.interlock(s)) == True{} : Bool}:
  match s:
    case S.St{+phase, +vac, +tf, dens, gas, cs, heat, t, hb}:
      guard_l4(S.is_plasma(phase), Bool.and(vac, tf), S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h4)

def on_vac_l4(s: S.St, ok: Bool, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.on_vac(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l4(S.St{phase, ok, tf, dens, gas, cs, heat, t, hb}, h4)

def on_tf_l4(s: S.St, ok: Bool, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.on_tf(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l4(S.St{phase, vac, ok, dens, gas, cs, heat, t, hb}, h4)

def on_dens_l4(s: S.St, ok: Bool, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.on_dens(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l4(S.St{phase, vac, tf, ok, gas, cs, heat, t, hb}, h4)

# -- the control cycle --

def tick_flat_l4(b: Bool, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, hb: Nat, h4: {S.l4_gas(S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l4_gas(S.tick_flat(b, S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match b:
    case True{}:
      h4
    case False{}:
      h4

def tick_phase_l4(phase: S.Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, +t: Nat, hb: Nat, h4: {S.l4_gas(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l4_gas(S.tick_phase(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match phase:
    case S.Idle{}:
      h4
    case S.Charged{}:
      h4
    case S.Prefill{}:
      h4
    case S.Breakdown{}:
      h4
    case S.FlatTop{}:
      tick_flat_l4(Nat.is_lt(1n+t, S.t_max()), vac, tf, dens, gas, cs, heat, t, hb, h4)
    case S.RampDown{}:
      h4
    case S.Shutdown{}:
      h4

def tick_hb_l4(b: Bool, phase: S.Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, hb: Nat, h4: {S.l4_gas(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l4_gas(S.tick_hb(b, S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match b:
    case True{}:
      tick_phase_l4(phase, vac, tf, dens, gas, cs, heat, t, 1n+hb, h4)
    case False{}:
      shutdown_l4(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})

def watched_l4(w: Bool, phase: S.Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, +hb: Nat, h4: {S.l4_gas(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l4_gas(S.watched(w, S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match w:
    case False{}:
      tick_phase_l4(phase, vac, tf, dens, gas, cs, heat, t, hb, h4)
    case True{}:
      tick_hb_l4(Nat.is_lt(1n+hb, S.hb_max()), phase, vac, tf, dens, gas, cs, heat, t, hb, h4)

def on_tick_l4(s: S.St, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.on_tick(s)) == True{} : Bool}:
  match s:
    case S.St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      watched_l4(S.is_watched(phase), phase, vac, tf, dens, gas, cs, heat, t, hb, h4)

def on_heartbeat_l4(s: S.St, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.on_heartbeat(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      h4

# -- commands --

def on_charge_l4(s: S.St, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.on_charge(s)) == True{} : Bool}:
  match s:
    case S.St{S.Idle{}, True{}, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Idle{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4

def on_puff_l4(s: S.St, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.on_puff(s)) == True{} : Bool}:
  match s:
    case S.St{S.Charged{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Charged{}, True{}, False{}, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Charged{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4

def on_breakdown_l4(s: S.St, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.on_breakdown(s)) == True{} : Bool}:
  match s:
    case S.St{S.Prefill{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Prefill{}, True{}, False{}, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Prefill{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4

def on_flattop_l4(s: S.St, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.on_flattop(s)) == True{} : Bool}:
  match s:
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4

def on_heat_on_l4(s: S.St, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.on_heat_on(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, True{}, gas, cs, heat, t, hb}:
      h4
    case S.St{S.FlatTop{}, vac, tf, False{}, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4

def on_heat_off_l4(s: S.St, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.on_heat_off(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      h4

def on_rampdown_l4(s: S.St, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.on_rampdown(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4

def on_reset_l4(s: S.St, h4: {S.l4_gas(s) == True{} : Bool}) -> {S.l4_gas(S.on_reset(s)) == True{} : Bool}:
  match s:
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h4

def Laws.pres_l4(s, h1, h2, h3, h4, h5, h6, e):
  match e:
    case S.Tick{}:
      on_tick_l4(s, h4)
    case S.Heartbeat{}:
      on_heartbeat_l4(s, h4)
    case S.Vac{ok}:
      on_vac_l4(s, ok, h4)
    case S.Tf{ok}:
      on_tf_l4(s, ok, h4)
    case S.Dens{ok}:
      on_dens_l4(s, ok, h4)
    case S.CmdCharge{}:
      on_charge_l4(s, h4)
    case S.CmdPuff{}:
      on_puff_l4(s, h4)
    case S.CmdBreakdown{}:
      on_breakdown_l4(s, h4)
    case S.CmdFlatTop{}:
      on_flattop_l4(s, h4)
    case S.CmdHeatOn{}:
      on_heat_on_l4(s, h4)
    case S.CmdHeatOff{}:
      on_heat_off_l4(s, h4)
    case S.CmdRampDown{}:
      on_rampdown_l4(s, h4)
    case S.Disruption{}:
      shutdown_l4(s)
    case S.Abort{}:
      shutdown_l4(s)
    case S.Reset{}:
      on_reset_l4(s, h4)

# ===========================================================================
# L5: the flat-top counter stays below the pulse-length limit
# ===========================================================================

def shutdown_l5(s: S.St) -> {S.l5_flat(S.shutdown(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

def guard_heat_l5(d: Bool, phase: S.Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, hb: Nat, h5: {S.l5_flat(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l5_flat(S.guard_heat(d, S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match d:
    case True{}:
      h5
    case False{}:
      h5

def guard_dens_l5(s: S.St, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.guard_dens(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, +dens, gas, cs, heat, t, hb}:
      guard_heat_l5(dens, phase, vac, tf, dens, gas, cs, heat, t, hb, h5)

def guard_l5(plasma: Bool, field_ok: Bool, s: S.St, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.guard(plasma, field_ok, s)) == True{} : Bool}:
  match plasma field_ok:
    case True{} False{}:
      shutdown_l5(s)
    case True{} True{}:
      guard_dens_l5(s, h5)
    case False{} True{}:
      guard_dens_l5(s, h5)
    case False{} False{}:
      guard_dens_l5(s, h5)

def interlock_l5(s: S.St, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.interlock(s)) == True{} : Bool}:
  match s:
    case S.St{+phase, +vac, +tf, dens, gas, cs, heat, t, hb}:
      guard_l5(S.is_plasma(phase), Bool.and(vac, tf), S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h5)

def on_vac_l5(s: S.St, ok: Bool, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.on_vac(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l5(S.St{phase, ok, tf, dens, gas, cs, heat, t, hb}, h5)

def on_tf_l5(s: S.St, ok: Bool, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.on_tf(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l5(S.St{phase, vac, ok, dens, gas, cs, heat, t, hb}, h5)

def on_dens_l5(s: S.St, ok: Bool, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.on_dens(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l5(S.St{phase, vac, tf, ok, gas, cs, heat, t, hb}, h5)

# -- the control cycle: the verdict b = (1+t < t_max) comes with its evidence --

def tick_flat_l5(b: Bool, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, hb: Nat, e: {Nat.is_lt(1n+t, S.t_max()) == b : Bool}) -> {S.l5_flat(S.tick_flat(b, S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match b:
    case True{}:
      e
    case False{}:
      {==}

def tick_phase_l5(phase: S.Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, +t: Nat, hb: Nat, h5: {S.l5_flat(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l5_flat(S.tick_phase(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match phase:
    case S.Idle{}:
      h5
    case S.Charged{}:
      h5
    case S.Prefill{}:
      h5
    case S.Breakdown{}:
      h5
    case S.FlatTop{}:
      tick_flat_l5(Nat.is_lt(1n+t, S.t_max()), vac, tf, dens, gas, cs, heat, t, hb, {==})
    case S.RampDown{}:
      h5
    case S.Shutdown{}:
      h5

def tick_hb_l5(b: Bool, phase: S.Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, hb: Nat, h5: {S.l5_flat(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l5_flat(S.tick_hb(b, S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match b:
    case True{}:
      tick_phase_l5(phase, vac, tf, dens, gas, cs, heat, t, 1n+hb, h5)
    case False{}:
      shutdown_l5(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})

def watched_l5(w: Bool, phase: S.Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, +hb: Nat, h5: {S.l5_flat(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l5_flat(S.watched(w, S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match w:
    case False{}:
      tick_phase_l5(phase, vac, tf, dens, gas, cs, heat, t, hb, h5)
    case True{}:
      tick_hb_l5(Nat.is_lt(1n+hb, S.hb_max()), phase, vac, tf, dens, gas, cs, heat, t, hb, h5)

def on_tick_l5(s: S.St, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.on_tick(s)) == True{} : Bool}:
  match s:
    case S.St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      watched_l5(S.is_watched(phase), phase, vac, tf, dens, gas, cs, heat, t, hb, h5)

def on_heartbeat_l5(s: S.St, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.on_heartbeat(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      h5

# -- commands --

def on_charge_l5(s: S.St, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.on_charge(s)) == True{} : Bool}:
  match s:
    case S.St{S.Idle{}, True{}, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Idle{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5

def on_puff_l5(s: S.St, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.on_puff(s)) == True{} : Bool}:
  match s:
    case S.St{S.Charged{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Charged{}, True{}, False{}, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Charged{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5

def on_breakdown_l5(s: S.St, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.on_breakdown(s)) == True{} : Bool}:
  match s:
    case S.St{S.Prefill{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Prefill{}, True{}, False{}, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Prefill{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5

def on_flattop_l5(s: S.St, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.on_flattop(s)) == True{} : Bool}:
  match s:
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5

def on_heat_on_l5(s: S.St, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.on_heat_on(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, True{}, gas, cs, heat, t, hb}:
      h5
    case S.St{S.FlatTop{}, vac, tf, False{}, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5

def on_heat_off_l5(s: S.St, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.on_heat_off(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      h5

def on_rampdown_l5(s: S.St, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.on_rampdown(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5

def on_reset_l5(s: S.St, h5: {S.l5_flat(s) == True{} : Bool}) -> {S.l5_flat(S.on_reset(s)) == True{} : Bool}:
  match s:
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h5

def Laws.pres_l5(s, h1, h2, h3, h4, h5, h6, e):
  match e:
    case S.Tick{}:
      on_tick_l5(s, h5)
    case S.Heartbeat{}:
      on_heartbeat_l5(s, h5)
    case S.Vac{ok}:
      on_vac_l5(s, ok, h5)
    case S.Tf{ok}:
      on_tf_l5(s, ok, h5)
    case S.Dens{ok}:
      on_dens_l5(s, ok, h5)
    case S.CmdCharge{}:
      on_charge_l5(s, h5)
    case S.CmdPuff{}:
      on_puff_l5(s, h5)
    case S.CmdBreakdown{}:
      on_breakdown_l5(s, h5)
    case S.CmdFlatTop{}:
      on_flattop_l5(s, h5)
    case S.CmdHeatOn{}:
      on_heat_on_l5(s, h5)
    case S.CmdHeatOff{}:
      on_heat_off_l5(s, h5)
    case S.CmdRampDown{}:
      on_rampdown_l5(s, h5)
    case S.Disruption{}:
      shutdown_l5(s)
    case S.Abort{}:
      shutdown_l5(s)
    case S.Reset{}:
      on_reset_l5(s, h5)

# ===========================================================================
# L6: in a watched phase the heartbeat counter stays below the watchdog limit
# ===========================================================================

def shutdown_l6(s: S.St) -> {S.l6_hb(S.shutdown(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

def guard_heat_l6(d: Bool, phase: S.Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, hb: Nat, h6: {S.l6_hb(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l6_hb(S.guard_heat(d, S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match d:
    case True{}:
      h6
    case False{}:
      h6

def guard_dens_l6(s: S.St, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.guard_dens(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, +dens, gas, cs, heat, t, hb}:
      guard_heat_l6(dens, phase, vac, tf, dens, gas, cs, heat, t, hb, h6)

def guard_l6(plasma: Bool, field_ok: Bool, s: S.St, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.guard(plasma, field_ok, s)) == True{} : Bool}:
  match plasma field_ok:
    case True{} False{}:
      shutdown_l6(s)
    case True{} True{}:
      guard_dens_l6(s, h6)
    case False{} True{}:
      guard_dens_l6(s, h6)
    case False{} False{}:
      guard_dens_l6(s, h6)

def interlock_l6(s: S.St, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.interlock(s)) == True{} : Bool}:
  match s:
    case S.St{+phase, +vac, +tf, dens, gas, cs, heat, t, hb}:
      guard_l6(S.is_plasma(phase), Bool.and(vac, tf), S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h6)

def on_vac_l6(s: S.St, ok: Bool, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.on_vac(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l6(S.St{phase, ok, tf, dens, gas, cs, heat, t, hb}, h6)

def on_tf_l6(s: S.St, ok: Bool, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.on_tf(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l6(S.St{phase, vac, ok, dens, gas, cs, heat, t, hb}, h6)

def on_dens_l6(s: S.St, ok: Bool, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.on_dens(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l6(S.St{phase, vac, tf, ok, gas, cs, heat, t, hb}, h6)

# -- the control cycle: tick_flat / tick_phase keep hb; tick_hb's True branch stores
#    1n+hb and carries the evidence that the new counter is still in bounds --

def tick_flat_l6(b: Bool, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, hb: Nat, h6: {S.l6_hb(S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l6_hb(S.tick_flat(b, S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match b:
    case True{}:
      h6
    case False{}:
      h6

def tick_phase_l6(phase: S.Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, +t: Nat, hb: Nat, h6: {S.l6_hb(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l6_hb(S.tick_phase(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match phase:
    case S.Idle{}:
      h6
    case S.Charged{}:
      h6
    case S.Prefill{}:
      h6
    case S.Breakdown{}:
      h6
    case S.FlatTop{}:
      tick_flat_l6(Nat.is_lt(1n+t, S.t_max()), vac, tf, dens, gas, cs, heat, t, hb, h6)
    case S.RampDown{}:
      h6
    case S.Shutdown{}:
      h6

# e ties the verdict b to the bound on the incremented counter (as seen by l6_hb)
def tick_hb_l6(b: Bool, phase: S.Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, hb: Nat, e: {S.l6_hb(S.St{phase, vac, tf, dens, gas, cs, heat, t, 1n+hb}) == b : Bool}) -> {S.l6_hb(S.tick_hb(b, S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match b:
    case True{}:
      tick_phase_l6(phase, vac, tf, dens, gas, cs, heat, t, 1n+hb, e)
    case False{}:
      shutdown_l6(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})

# on_tick is split on the phase so that is_watched computes and the evidence is {==}
def on_tick_l6(s: S.St, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.on_tick(s)) == True{} : Bool}:
  match s:
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, +hb}:
      tick_hb_l6(Nat.is_lt(1n+hb, S.hb_max()), S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb, {==})
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, +hb}:
      tick_hb_l6(Nat.is_lt(1n+hb, S.hb_max()), S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb, {==})
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, +hb}:
      tick_hb_l6(Nat.is_lt(1n+hb, S.hb_max()), S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb, {==})
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, +hb}:
      tick_hb_l6(Nat.is_lt(1n+hb, S.hb_max()), S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb, {==})
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, +hb}:
      tick_hb_l6(Nat.is_lt(1n+hb, S.hb_max()), S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb, {==})
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

# a fresh counter is in bounds whether or not the phase is watched
def cnt_go_zero(w: Bool) -> {S.cnt_go(w, 0n, S.hb_max()) == True{} : Bool}:
  match w:
    case True{}:
      {==}
    case False{}:
      {==}

def on_heartbeat_l6(s: S.St) -> {S.l6_hb(S.on_heartbeat(s)) == True{} : Bool}:
  match s:
    case S.St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      cnt_go_zero(S.is_watched(phase))

# -- commands --

def on_charge_l6(s: S.St, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.on_charge(s)) == True{} : Bool}:
  match s:
    case S.St{S.Idle{}, True{}, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Idle{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6

def on_puff_l6(s: S.St, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.on_puff(s)) == True{} : Bool}:
  match s:
    case S.St{S.Charged{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Charged{}, True{}, False{}, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Charged{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6

def on_breakdown_l6(s: S.St, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.on_breakdown(s)) == True{} : Bool}:
  match s:
    case S.St{S.Prefill{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Prefill{}, True{}, False{}, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Prefill{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6

def on_flattop_l6(s: S.St, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.on_flattop(s)) == True{} : Bool}:
  match s:
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6

def on_heat_on_l6(s: S.St, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.on_heat_on(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, True{}, gas, cs, heat, t, hb}:
      h6
    case S.St{S.FlatTop{}, vac, tf, False{}, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6

def on_heat_off_l6(s: S.St, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.on_heat_off(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      h6

def on_rampdown_l6(s: S.St, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.on_rampdown(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6

def on_reset_l6(s: S.St, h6: {S.l6_hb(s) == True{} : Bool}) -> {S.l6_hb(S.on_reset(s)) == True{} : Bool}:
  match s:
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h6

def Laws.pres_l6(s, h1, h2, h3, h4, h5, h6, e):
  match e:
    case S.Tick{}:
      on_tick_l6(s, h6)
    case S.Heartbeat{}:
      on_heartbeat_l6(s)
    case S.Vac{ok}:
      on_vac_l6(s, ok, h6)
    case S.Tf{ok}:
      on_tf_l6(s, ok, h6)
    case S.Dens{ok}:
      on_dens_l6(s, ok, h6)
    case S.CmdCharge{}:
      on_charge_l6(s, h6)
    case S.CmdPuff{}:
      on_puff_l6(s, h6)
    case S.CmdBreakdown{}:
      on_breakdown_l6(s, h6)
    case S.CmdFlatTop{}:
      on_flattop_l6(s, h6)
    case S.CmdHeatOn{}:
      on_heat_on_l6(s, h6)
    case S.CmdHeatOff{}:
      on_heat_off_l6(s, h6)
    case S.CmdRampDown{}:
      on_rampdown_l6(s, h6)
    case S.Disruption{}:
      shutdown_l6(s)
    case S.Abort{}:
      shutdown_l6(s)
    case S.Reset{}:
      on_reset_l6(s, h6)
