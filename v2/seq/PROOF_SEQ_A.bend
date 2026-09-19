# PROOF_SEQ_A.bend - preservation of L1 (field), L2 (heat) and L3 (solenoid) by every
# event. One lemma per handler / helper, mirroring seq.bend: every helper that branches
# on a computed Bool (guard, watched, tick_hb, tick_flat) gets a lemma quantified over
# that Bool; the sensor handlers go through interlock, the tick goes through watched.
# pres_l4..pres_l6 live in PROOF_SEQ_B.bend; the remaining laws in a third file.

import Base
import ./seq.bend as S
import ./LAWS_SEQ.bend as Laws

# ===========================================================================
# L1: gas or plasma in the vessel only with vacuum and field
# ===========================================================================

def shutdown_l1(s: S.St) -> {S.l1_field(S.shutdown(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

# guard_dens keeps phase, vac and tf, so L1 is unchanged (guard_dens on the right: rewrite target)
def guard_dens_l1_eq(s: S.St) -> {S.l1_field(s) == S.l1_field(S.guard_dens(s)) : Bool}:
  match s:
    case S.St{phase, vac, tf, True{}, gas, cs, heat, t, hb}:
      {==}
    case S.St{phase, vac, tf, False{}, gas, cs, heat, t, hb}:
      {==}

# the interlock re-establishes L1 by itself: p = is_plasma(phase), ok = vac and tf
def guard_l1(p: Bool, ok: Bool, phase: S.Phase, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, hb: Nat, ep: {p == S.is_plasma(phase) : Bool}, eok: {ok == Bool.and(vac, tf) : Bool}) -> {S.l1_field(S.guard(p, ok, S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match p ok:
    case True{} False{}:
      {==}
    case True{} True{}:
      %guard_dens_l1_eq(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}) : {_ == True{} : Bool}
      %ep : {S.l1_go(_, vac, tf) == True{} : Bool}
      %eok : {_ == True{} : Bool}
      {==}
    case False{} True{}:
      %guard_dens_l1_eq(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}) : {_ == True{} : Bool}
      %ep : {S.l1_go(_, vac, tf) == True{} : Bool}
      {==}
    case False{} False{}:
      %guard_dens_l1_eq(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}) : {_ == True{} : Bool}
      %ep : {S.l1_go(_, vac, tf) == True{} : Bool}
      {==}

def interlock_l1(s: S.St) -> {S.l1_field(S.interlock(s)) == True{} : Bool}:
  match s:
    case S.St{+phase, +vac, +tf, dens, gas, cs, heat, t, hb}:
      guard_l1(S.is_plasma(phase), Bool.and(vac, tf), phase, vac, tf, dens, gas, cs, heat, t, hb, {==}, {==})

def on_vac_l1(s: S.St, ok: Bool) -> {S.l1_field(S.on_vac(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l1(S.St{phase, ok, tf, dens, gas, cs, heat, t, hb})

def on_tf_l1(s: S.St, ok: Bool) -> {S.l1_field(S.on_tf(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l1(S.St{phase, vac, ok, dens, gas, cs, heat, t, hb})

def on_dens_l1(s: S.St, ok: Bool) -> {S.l1_field(S.on_dens(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l1(S.St{phase, vac, tf, ok, gas, cs, heat, t, hb})

# -- tick chain --

def tick_flat_l1(b: Bool, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, hb: Nat, h: {S.l1_field(S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l1_field(S.tick_flat(b, S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match b:
    case True{}:
      h
    case False{}:
      h

def tick_phase_l1(s: S.St, h: {S.l1_field(s) == True{} : Bool}) -> {S.l1_field(S.tick_phase(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, +t, hb}:
      tick_flat_l1(Nat.is_lt(1n+t, S.t_max()), vac, tf, dens, gas, cs, heat, t, hb, h)
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def tick_hb_l1(b: Bool, s: S.St, h: {S.l1_field(s) == True{} : Bool}) -> {S.l1_field(S.tick_hb(b, s)) == True{} : Bool}:
  match b s:
    case True{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      tick_phase_l1(S.St{phase, vac, tf, dens, gas, cs, heat, t, 1n+hb}, h)
    case False{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

def watched_l1(w: Bool, s: S.St, h: {S.l1_field(s) == True{} : Bool}) -> {S.l1_field(S.watched(w, s)) == True{} : Bool}:
  match w s:
    case False{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      tick_phase_l1(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h)
    case True{} S.St{phase, vac, tf, dens, gas, cs, heat, t, +hb}:
      tick_hb_l1(Nat.is_lt(1n+hb, S.hb_max()), S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h)

def on_tick_l1(s: S.St, h: {S.l1_field(s) == True{} : Bool}) -> {S.l1_field(S.on_tick(s)) == True{} : Bool}:
  match s:
    case S.St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      watched_l1(S.is_watched(phase), S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h)

def on_heartbeat_l1(s: S.St, h: {S.l1_field(s) == True{} : Bool}) -> {S.l1_field(S.on_heartbeat(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      h

# -- commands --

def on_charge_l1(s: S.St, h: {S.l1_field(s) == True{} : Bool}) -> {S.l1_field(S.on_charge(s)) == True{} : Bool}:
  match s:
    case S.St{S.Idle{}, True{}, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Idle{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_puff_l1(s: S.St, h: {S.l1_field(s) == True{} : Bool}) -> {S.l1_field(S.on_puff(s)) == True{} : Bool}:
  match s:
    case S.St{S.Charged{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Charged{}, True{}, False{}, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_breakdown_l1(s: S.St, h: {S.l1_field(s) == True{} : Bool}) -> {S.l1_field(S.on_breakdown(s)) == True{} : Bool}:
  match s:
    case S.St{S.Prefill{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Prefill{}, True{}, False{}, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_flattop_l1(s: S.St, h: {S.l1_field(s) == True{} : Bool}) -> {S.l1_field(S.on_flattop(s)) == True{} : Bool}:
  match s:
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_heat_on_l1(s: S.St, h: {S.l1_field(s) == True{} : Bool}) -> {S.l1_field(S.on_heat_on(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, True{}, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, False{}, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_heat_off_l1(s: S.St, h: {S.l1_field(s) == True{} : Bool}) -> {S.l1_field(S.on_heat_off(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_rampdown_l1(s: S.St, h: {S.l1_field(s) == True{} : Bool}) -> {S.l1_field(S.on_rampdown(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_reset_l1(s: S.St, h: {S.l1_field(s) == True{} : Bool}) -> {S.l1_field(S.on_reset(s)) == True{} : Bool}:
  match s:
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def Laws.pres_l1(s, h1, h2, h3, h4, h5, h6, e):
  match e:
    case S.Tick{}:
      on_tick_l1(s, h1)
    case S.Heartbeat{}:
      on_heartbeat_l1(s, h1)
    case S.Vac{ok}:
      on_vac_l1(s, ok)
    case S.Tf{ok}:
      on_tf_l1(s, ok)
    case S.Dens{ok}:
      on_dens_l1(s, ok)
    case S.CmdCharge{}:
      on_charge_l1(s, h1)
    case S.CmdPuff{}:
      on_puff_l1(s, h1)
    case S.CmdBreakdown{}:
      on_breakdown_l1(s, h1)
    case S.CmdFlatTop{}:
      on_flattop_l1(s, h1)
    case S.CmdHeatOn{}:
      on_heat_on_l1(s, h1)
    case S.CmdHeatOff{}:
      on_heat_off_l1(s, h1)
    case S.CmdRampDown{}:
      on_rampdown_l1(s, h1)
    case S.Disruption{}:
      shutdown_l1(s)
    case S.Abort{}:
      shutdown_l1(s)
    case S.Reset{}:
      on_reset_l1(s, h1)

# ===========================================================================
# L2: heating only in flat-top with the density in its window
# ===========================================================================

def shutdown_l2(s: S.St) -> {S.l2_heat(S.shutdown(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

def guard_heat_l2(d: Bool, s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.guard_heat(d, s)) == True{} : Bool}:
  match d s:
    case True{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case False{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

def guard_dens_l2(s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.guard_dens(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, +dens, gas, cs, heat, t, hb}:
      guard_heat_l2(dens, S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h)

# the hypothesis is about guard_dens(s): the sensor handlers can establish it even when
# the raw new state violates L2 (density lost with heating on: guard_heat turns it off)
def guard_l2(p: Bool, ok: Bool, s: S.St, h: {S.l2_heat(S.guard_dens(s)) == True{} : Bool}) -> {S.l2_heat(S.guard(p, ok, s)) == True{} : Bool}:
  match p ok:
    case True{} False{}:
      shutdown_l2(s)
    case True{} True{}:
      h
    case False{} True{}:
      h
    case False{} False{}:
      h

def interlock_l2(s: S.St, h: {S.l2_heat(S.guard_dens(s)) == True{} : Bool}) -> {S.l2_heat(S.interlock(s)) == True{} : Bool}:
  match s:
    case S.St{+phase, +vac, +tf, dens, gas, cs, heat, t, hb}:
      guard_l2(S.is_plasma(phase), Bool.and(vac, tf), S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h)

def interlock_l2_pre(+s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.interlock(s)) == True{} : Bool}:
  interlock_l2(s, guard_dens_l2(s, h))

def on_vac_l2(s: S.St, ok: Bool, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.on_vac(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l2_pre(S.St{phase, ok, tf, dens, gas, cs, heat, t, hb}, h)

def on_tf_l2(s: S.St, ok: Bool, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.on_tf(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l2_pre(S.St{phase, vac, ok, dens, gas, cs, heat, t, hb}, h)

# L2 with the density flag set to True follows from L2 with any density flag
def l2_go_dens_true(heat: Bool, f: Bool, dens: Bool, e: {S.l2_go(heat, f, dens) == True{} : Bool}) -> {S.l2_go(heat, f, True{}) == True{} : Bool}:
  match heat f:
    case False{} True{}:
      {==}
    case False{} False{}:
      {==}
    case True{} True{}:
      {==}
    case True{} False{}:
      e

def on_dens_l2(ok: Bool, s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.on_dens(s, ok)) == True{} : Bool}:
  match ok s:
    case False{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l2(S.St{phase, vac, tf, False{}, gas, cs, heat, t, hb}, {==})
    case True{} S.St{+phase, vac, tf, dens, gas, cs, +heat, t, hb}:
      interlock_l2(S.St{phase, vac, tf, True{}, gas, cs, heat, t, hb}, l2_go_dens_true(heat, S.is_flattop(phase), dens, h))

# -- tick chain --

def tick_flat_l2(b: Bool, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, hb: Nat, h: {S.l2_heat(S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l2_heat(S.tick_flat(b, S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match b:
    case True{}:
      h
    case False{}:
      {==}

def tick_phase_l2(s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.tick_phase(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, +t, hb}:
      tick_flat_l2(Nat.is_lt(1n+t, S.t_max()), vac, tf, dens, gas, cs, heat, t, hb, h)
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def tick_hb_l2(b: Bool, s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.tick_hb(b, s)) == True{} : Bool}:
  match b s:
    case True{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      tick_phase_l2(S.St{phase, vac, tf, dens, gas, cs, heat, t, 1n+hb}, h)
    case False{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

def watched_l2(w: Bool, s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.watched(w, s)) == True{} : Bool}:
  match w s:
    case False{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      tick_phase_l2(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h)
    case True{} S.St{phase, vac, tf, dens, gas, cs, heat, t, +hb}:
      tick_hb_l2(Nat.is_lt(1n+hb, S.hb_max()), S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h)

def on_tick_l2(s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.on_tick(s)) == True{} : Bool}:
  match s:
    case S.St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      watched_l2(S.is_watched(phase), S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h)

def on_heartbeat_l2(s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.on_heartbeat(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      h

# -- commands --

def on_charge_l2(s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.on_charge(s)) == True{} : Bool}:
  match s:
    case S.St{S.Idle{}, True{}, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_puff_l2(s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.on_puff(s)) == True{} : Bool}:
  match s:
    case S.St{S.Charged{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, True{}, False{}, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_breakdown_l2(s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.on_breakdown(s)) == True{} : Bool}:
  match s:
    case S.St{S.Prefill{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, True{}, False{}, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

# entering flat-top: heating was off in breakdown (or h is False == True, which is the goal too)
def on_flattop_l2(s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.on_flattop(s)) == True{} : Bool}:
  match s:
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, False{}, t, hb}:
      {==}
    case S.St{S.Breakdown{}, vac, tf, True{}, gas, cs, True{}, t, hb}:
      {==}
    case S.St{S.Breakdown{}, vac, tf, False{}, gas, cs, True{}, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_heat_on_l2(s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.on_heat_on(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, True{}, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.FlatTop{}, vac, tf, False{}, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_heat_off_l2(s: S.St) -> {S.l2_heat(S.on_heat_off(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

def on_rampdown_l2(s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.on_rampdown(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_reset_l2(s: S.St, h: {S.l2_heat(s) == True{} : Bool}) -> {S.l2_heat(S.on_reset(s)) == True{} : Bool}:
  match s:
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def Laws.pres_l2(s, h1, h2, h3, h4, h5, h6, e):
  match e:
    case S.Tick{}:
      on_tick_l2(s, h2)
    case S.Heartbeat{}:
      on_heartbeat_l2(s, h2)
    case S.Vac{ok}:
      on_vac_l2(s, ok, h2)
    case S.Tf{ok}:
      on_tf_l2(s, ok, h2)
    case S.Dens{ok}:
      on_dens_l2(ok, s, h2)
    case S.CmdCharge{}:
      on_charge_l2(s, h2)
    case S.CmdPuff{}:
      on_puff_l2(s, h2)
    case S.CmdBreakdown{}:
      on_breakdown_l2(s, h2)
    case S.CmdFlatTop{}:
      on_flattop_l2(s, h2)
    case S.CmdHeatOn{}:
      on_heat_on_l2(s, h2)
    case S.CmdHeatOff{}:
      on_heat_off_l2(s)
    case S.CmdRampDown{}:
      on_rampdown_l2(s, h2)
    case S.Disruption{}:
      shutdown_l2(s)
    case S.Abort{}:
      shutdown_l2(s)
    case S.Reset{}:
      on_reset_l2(s, h2)

# ===========================================================================
# L3: the solenoid is energized only in breakdown / flat-top / ramp-down
# ===========================================================================

def shutdown_l3(s: S.St) -> {S.l3_cs(S.shutdown(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

def guard_heat_l3(d: Bool, s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.guard_heat(d, s)) == True{} : Bool}:
  match d s:
    case True{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case False{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def guard_dens_l3(s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.guard_dens(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, +dens, gas, cs, heat, t, hb}:
      guard_heat_l3(dens, S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h)

def guard_l3(p: Bool, ok: Bool, s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.guard(p, ok, s)) == True{} : Bool}:
  match p ok:
    case True{} False{}:
      shutdown_l3(s)
    case True{} True{}:
      guard_dens_l3(s, h)
    case False{} True{}:
      guard_dens_l3(s, h)
    case False{} False{}:
      guard_dens_l3(s, h)

def interlock_l3(s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.interlock(s)) == True{} : Bool}:
  match s:
    case S.St{+phase, +vac, +tf, dens, gas, cs, heat, t, hb}:
      guard_l3(S.is_plasma(phase), Bool.and(vac, tf), S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h)

def on_vac_l3(s: S.St, ok: Bool, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.on_vac(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l3(S.St{phase, ok, tf, dens, gas, cs, heat, t, hb}, h)

def on_tf_l3(s: S.St, ok: Bool, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.on_tf(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l3(S.St{phase, vac, ok, dens, gas, cs, heat, t, hb}, h)

def on_dens_l3(s: S.St, ok: Bool, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.on_dens(s, ok)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_l3(S.St{phase, vac, tf, ok, gas, cs, heat, t, hb}, h)

# -- tick chain --

def tick_flat_l3(b: Bool, vac: Bool, tf: Bool, dens: Bool, gas: Bool, cs: Bool, heat: Bool, t: Nat, hb: Nat, h: {S.l3_cs(S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}) == True{} : Bool}) -> {S.l3_cs(S.tick_flat(b, S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb})) == True{} : Bool}:
  match b:
    case True{}:
      h
    case False{}:
      h

def tick_phase_l3(s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.tick_phase(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, +t, hb}:
      tick_flat_l3(Nat.is_lt(1n+t, S.t_max()), vac, tf, dens, gas, cs, heat, t, hb, h)
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def tick_hb_l3(b: Bool, s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.tick_hb(b, s)) == True{} : Bool}:
  match b s:
    case True{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      tick_phase_l3(S.St{phase, vac, tf, dens, gas, cs, heat, t, 1n+hb}, h)
    case False{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

def watched_l3(w: Bool, s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.watched(w, s)) == True{} : Bool}:
  match w s:
    case False{} S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      tick_phase_l3(S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h)
    case True{} S.St{phase, vac, tf, dens, gas, cs, heat, t, +hb}:
      tick_hb_l3(Nat.is_lt(1n+hb, S.hb_max()), S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h)

def on_tick_l3(s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.on_tick(s)) == True{} : Bool}:
  match s:
    case S.St{+phase, vac, tf, dens, gas, cs, heat, t, hb}:
      watched_l3(S.is_watched(phase), S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}, h)

def on_heartbeat_l3(s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.on_heartbeat(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      h

# -- commands --

def on_charge_l3(s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.on_charge(s)) == True{} : Bool}:
  match s:
    case S.St{S.Idle{}, True{}, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_puff_l3(s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.on_puff(s)) == True{} : Bool}:
  match s:
    case S.St{S.Charged{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, True{}, False{}, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_breakdown_l3(s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.on_breakdown(s)) == True{} : Bool}:
  match s:
    case S.St{S.Prefill{}, True{}, True{}, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Prefill{}, True{}, False{}, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, False{}, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_flattop_l3(s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.on_flattop(s)) == True{} : Bool}:
  match s:
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_heat_on_l3(s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.on_heat_on(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, True{}, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, False{}, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_heat_off_l3(s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.on_heat_off(s)) == True{} : Bool}:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_rampdown_l3(s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.on_rampdown(s)) == True{} : Bool}:
  match s:
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def on_reset_l3(s: S.St, h: {S.l3_cs(s) == True{} : Bool}) -> {S.l3_cs(S.on_reset(s)) == True{} : Bool}:
  match s:
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      h

def Laws.pres_l3(s, h1, h2, h3, h4, h5, h6, e):
  match e:
    case S.Tick{}:
      on_tick_l3(s, h3)
    case S.Heartbeat{}:
      on_heartbeat_l3(s, h3)
    case S.Vac{ok}:
      on_vac_l3(s, ok, h3)
    case S.Tf{ok}:
      on_tf_l3(s, ok, h3)
    case S.Dens{ok}:
      on_dens_l3(s, ok, h3)
    case S.CmdCharge{}:
      on_charge_l3(s, h3)
    case S.CmdPuff{}:
      on_puff_l3(s, h3)
    case S.CmdBreakdown{}:
      on_breakdown_l3(s, h3)
    case S.CmdFlatTop{}:
      on_flattop_l3(s, h3)
    case S.CmdHeatOn{}:
      on_heat_on_l3(s, h3)
    case S.CmdHeatOff{}:
      on_heat_off_l3(s, h3)
    case S.CmdRampDown{}:
      on_rampdown_l3(s, h3)
    case S.Disruption{}:
      shutdown_l3(s)
    case S.Abort{}:
      shutdown_l3(s)
    case S.Reset{}:
      on_reset_l3(s, h3)
