# enum3.bend - the finite certificates of seq3, written as NESTED FIRST-ORDER checks so
# that PROOF_SEQ3.bend can turn "check == True" into universal statements with one small
# lemma per quantifier level (reflection), and the equivalence with seq/seq.bend.

import Base
import ./seq3.bend as S
import ./../seq/seq.bend as Old

# ---------------------------------------------------------------------------
# The property of one (control state, event, verdicts) cell
# ---------------------------------------------------------------------------

# invariant preservation on the control, and the two counter shapes
def prop_at(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool, +f2: S.Fin) -> Bool:
  Bool.and(S.implies(S.inv_fin(f), S.inv_fin(f2)),
  Bool.and(S.implies(S.is_flattop(S.phase_of(f2)), S.shape_ok(S.upd_t(f, e, bt, bh), S.is_flattop(S.phase_of(f)), bt)),
           S.implies(S.is_watched(S.phase_of(f2)), S.shape_ok(S.upd_hb(f, e, bh), S.is_watched(S.phase_of(f)), bh))))

# the next control state is computed once per cell
def prop(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> Bool:
  prop_at(f, e, bt, bh, S.step_fin(f, e, bt, bh))

# ---------------------------------------------------------------------------
# Quantifier levels (each is a conjunction over one constructor set)
# ---------------------------------------------------------------------------

def all_bh(f: S.Fin, e: S.Ev, bt: Bool) -> Bool:
  +f2 = f
  +e2 = e
  +bt2 = bt
  Bool.and(prop(f2, e2, bt2, True{}), prop(f2, e2, bt2, False{}))

def all_bt(f: S.Fin, e: S.Ev) -> Bool:
  +f2 = f
  +e2 = e
  Bool.and(all_bh(f2, e2, True{}), all_bh(f2, e2, False{}))

# the 15 event constructors (18 with the sensor Bools), in 9 pairs
def ev_g1(+f: S.Fin) -> Bool:
  Bool.and(all_bt(f, S.Tick{}), all_bt(f, S.Heartbeat{}))

def ev_g2(+f: S.Fin) -> Bool:
  Bool.and(all_bt(f, S.Vac{True{}}), all_bt(f, S.Vac{False{}}))

def ev_g3(+f: S.Fin) -> Bool:
  Bool.and(all_bt(f, S.Tf{True{}}), all_bt(f, S.Tf{False{}}))

def ev_g4(+f: S.Fin) -> Bool:
  Bool.and(all_bt(f, S.Dens{True{}}), all_bt(f, S.Dens{False{}}))

def ev_g5(+f: S.Fin) -> Bool:
  Bool.and(all_bt(f, S.CmdCharge{}), all_bt(f, S.CmdPuff{}))

def ev_g6(+f: S.Fin) -> Bool:
  Bool.and(all_bt(f, S.CmdBreakdown{}), all_bt(f, S.CmdFlatTop{}))

def ev_g7(+f: S.Fin) -> Bool:
  Bool.and(all_bt(f, S.CmdHeatOn{}), all_bt(f, S.CmdHeatOff{}))

def ev_g8(+f: S.Fin) -> Bool:
  Bool.and(all_bt(f, S.CmdRampDown{}), all_bt(f, S.Disruption{}))

def ev_g9(+f: S.Fin) -> Bool:
  Bool.and(all_bt(f, S.Abort{}), all_bt(f, S.Reset{}))

def all_ev(+f: S.Fin) -> Bool:
  Bool.and(Bool.and(Bool.and(ev_g1(f), ev_g2(f)), Bool.and(ev_g3(f), ev_g4(f))),
           Bool.and(Bool.and(ev_g5(f), ev_g6(f)), Bool.and(Bool.and(ev_g7(f), ev_g8(f)), ev_g9(f))))

# the six Bool fields, innermost first
def all_heat(+p: S.Phase, +v: Bool, +tf: Bool, +d: Bool, +g: Bool, +c: Bool) -> Bool:
  Bool.and(all_ev(S.Fin{p, v, tf, d, g, c, True{}}), all_ev(S.Fin{p, v, tf, d, g, c, False{}}))

def all_cs(+p: S.Phase, +v: Bool, +tf: Bool, +d: Bool, +g: Bool) -> Bool:
  Bool.and(all_heat(p, v, tf, d, g, True{}), all_heat(p, v, tf, d, g, False{}))

def all_gas(+p: S.Phase, +v: Bool, +tf: Bool, +d: Bool) -> Bool:
  Bool.and(all_cs(p, v, tf, d, True{}), all_cs(p, v, tf, d, False{}))

def all_dens(+p: S.Phase, +v: Bool, +tf: Bool) -> Bool:
  Bool.and(all_gas(p, v, tf, True{}), all_gas(p, v, tf, False{}))

def all_tf(+p: S.Phase, +v: Bool) -> Bool:
  Bool.and(all_dens(p, v, True{}), all_dens(p, v, False{}))

def all_vac(+p: S.Phase) -> Bool:
  Bool.and(all_tf(p, True{}), all_tf(p, False{}))

# the seven phases: 448 control states x 18 events x 4 verdict pairs
def check_fin() -> Bool:
  Bool.and(all_vac(S.Idle{}), Bool.and(all_vac(S.Charged{}), Bool.and(all_vac(S.Prefill{}),
  Bool.and(all_vac(S.Breakdown{}), Bool.and(all_vac(S.FlatTop{}), Bool.and(all_vac(S.RampDown{}), all_vac(S.Shutdown{})))))))

# ---------------------------------------------------------------------------
# Equivalence with seq/seq.bend on the counter grid {0, 2, 3, 4}^2 (7168 states x 18 events)
# ---------------------------------------------------------------------------

def bool_of(n: Nat) -> Bool:
  match n:
    case 0n:
      False{}
    case 1n+_:
      True{}

def phase_new(n: Nat) -> S.Phase:
  match n:
    case 0n:
      S.Idle{}
    case 1n:
      S.Charged{}
    case 2n:
      S.Prefill{}
    case 3n:
      S.Breakdown{}
    case 4n:
      S.FlatTop{}
    case 5n:
      S.RampDown{}
    case 6n+_:
      S.Shutdown{}

def phase_old(n: Nat) -> Old.Phase:
  match n:
    case 0n:
      Old.Idle{}
    case 1n:
      Old.Charged{}
    case 2n:
      Old.Prefill{}
    case 3n:
      Old.Breakdown{}
    case 4n:
      Old.FlatTop{}
    case 5n:
      Old.RampDown{}
    case 6n+_:
      Old.Shutdown{}

def cnt_of_idx(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n:
      2n
    case 2n:
      3n
    case 3n+_:
      4n

def decode_new(+i: Nat) -> S.St:
  S.St{S.Fin{phase_new(Nat.mod(i, 7n)),
             bool_of(Nat.mod(Nat.div(i, 7n), 2n)),
             bool_of(Nat.mod(Nat.div(i, 14n), 2n)),
             bool_of(Nat.mod(Nat.div(i, 28n), 2n)),
             bool_of(Nat.mod(Nat.div(i, 56n), 2n)),
             bool_of(Nat.mod(Nat.div(i, U32.to_nat(112)), 2n)),
             bool_of(Nat.mod(Nat.div(i, U32.to_nat(224)), 2n))},
       cnt_of_idx(Nat.mod(Nat.div(i, U32.to_nat(448)), 4n)),
       cnt_of_idx(Nat.mod(Nat.div(i, U32.to_nat(1792)), 4n))}

def decode_old(+i: Nat) -> Old.St:
  Old.St{phase_old(Nat.mod(i, 7n)),
         bool_of(Nat.mod(Nat.div(i, 7n), 2n)),
         bool_of(Nat.mod(Nat.div(i, 14n), 2n)),
         bool_of(Nat.mod(Nat.div(i, 28n), 2n)),
         bool_of(Nat.mod(Nat.div(i, 56n), 2n)),
         bool_of(Nat.mod(Nat.div(i, U32.to_nat(112)), 2n)),
         bool_of(Nat.mod(Nat.div(i, U32.to_nat(224)), 2n)),
         cnt_of_idx(Nat.mod(Nat.div(i, U32.to_nat(448)), 4n)),
         cnt_of_idx(Nat.mod(Nat.div(i, U32.to_nat(1792)), 4n))}

def events_new() -> List<&2, S.Ev>:
  [S.Tick{}, S.Heartbeat{}, S.Vac{True{}}, S.Vac{False{}}, S.Tf{True{}}, S.Tf{False{}},
   S.Dens{True{}}, S.Dens{False{}}, S.CmdCharge{}, S.CmdPuff{}, S.CmdBreakdown{}, S.CmdFlatTop{},
   S.CmdHeatOn{}, S.CmdHeatOff{}, S.CmdRampDown{}, S.Disruption{}, S.Abort{}, S.Reset{}]

def events_old() -> List<&2, Old.Ev>:
  [Old.Tick{}, Old.Heartbeat{}, Old.Vac{True{}}, Old.Vac{False{}}, Old.Tf{True{}}, Old.Tf{False{}},
   Old.Dens{True{}}, Old.Dens{False{}}, Old.CmdCharge{}, Old.CmdPuff{}, Old.CmdBreakdown{}, Old.CmdFlatTop{},
   Old.CmdHeatOn{}, Old.CmdHeatOff{}, Old.CmdRampDown{}, Old.Disruption{}, Old.Abort{}, Old.Reset{}]

def phase_idx_new(p: S.Phase) -> Nat:
  match p:
    case S.Idle{}:
      0n
    case S.Charged{}:
      1n
    case S.Prefill{}:
      2n
    case S.Breakdown{}:
      3n
    case S.FlatTop{}:
      4n
    case S.RampDown{}:
      5n
    case S.Shutdown{}:
      6n

def phase_idx_old(p: Old.Phase) -> Nat:
  match p:
    case Old.Idle{}:
      0n
    case Old.Charged{}:
      1n
    case Old.Prefill{}:
      2n
    case Old.Breakdown{}:
      3n
    case Old.FlatTop{}:
      4n
    case Old.RampDown{}:
      5n
    case Old.Shutdown{}:
      6n

def beq(a: Bool, b: Bool) -> Bool:
  match a b:
    case True{} True{}:
      True{}
    case False{} False{}:
      True{}
    case _ _:
      False{}

# structural equality of a new state and an old state
def same_st(sn: S.St, so: Old.St) -> Bool:
  match sn so:
    case S.St{S.Fin{p, v, tf, d, g, c, h}, t, hb} Old.St{p2, v2, tf2, d2, g2, c2, h2, t2, hb2}:
      Bool.and(Nat.is_eq(phase_idx_new(p), phase_idx_old(p2)),
      Bool.and(beq(v, v2), Bool.and(beq(tf, tf2), Bool.and(beq(d, d2), Bool.and(beq(g, g2), Bool.and(beq(c, c2), Bool.and(beq(h, h2),
      Bool.and(Nat.is_eq(t, t2), Nat.is_eq(hb, hb2)))))))))

# the two models reach the same state after every event
def same_go(es: List<&2, S.Ev>, os: List<&2, Old.Ev>, +sn: S.St, +so: Old.St) -> Bool:
  match es os:
    case Con{e, et} Con{o, ot}:
      Bool.and(same_st(S.step(sn, e), Old.step(so, o)), same_go(et, ot, sn, so))
    case _ _:
      True{}

def same_state(+i: Nat) -> Bool:
  Bool.and(same_st(decode_new(i), decode_old(i)),
           same_go(events_new(), events_old(), decode_new(i), decode_old(i)))

def same_from(n: Nat, acc: Bool) -> Bool:
  match n:
    case 0n:
      acc
    case 1n++p:
      same_from(p, Bool.and(acc, same_state(p)))

def same_as_old() -> Bool:
  same_from(U32.to_nat(7168), True{})

# a smaller grid for the checker (counters 0 and limit-1): indices below 1792 use
# t in {0, 3} and hb in {0, 2} through decode_small of the same layout
def decode_small_new(+i: Nat) -> S.St:
  S.St{S.Fin{phase_new(Nat.mod(i, 7n)),
             bool_of(Nat.mod(Nat.div(i, 7n), 2n)),
             bool_of(Nat.mod(Nat.div(i, 14n), 2n)),
             bool_of(Nat.mod(Nat.div(i, 28n), 2n)),
             bool_of(Nat.mod(Nat.div(i, 56n), 2n)),
             bool_of(Nat.mod(Nat.div(i, U32.to_nat(112)), 2n)),
             bool_of(Nat.mod(Nat.div(i, U32.to_nat(224)), 2n))},
       Nat.mul(3n, Nat.mod(Nat.div(i, U32.to_nat(448)), 2n)),
       Nat.mul(2n, Nat.mod(Nat.div(i, U32.to_nat(896)), 2n))}

def decode_small_old(+i: Nat) -> Old.St:
  Old.St{phase_old(Nat.mod(i, 7n)),
         bool_of(Nat.mod(Nat.div(i, 7n), 2n)),
         bool_of(Nat.mod(Nat.div(i, 14n), 2n)),
         bool_of(Nat.mod(Nat.div(i, 28n), 2n)),
         bool_of(Nat.mod(Nat.div(i, 56n), 2n)),
         bool_of(Nat.mod(Nat.div(i, U32.to_nat(112)), 2n)),
         bool_of(Nat.mod(Nat.div(i, U32.to_nat(224)), 2n)),
         Nat.mul(3n, Nat.mod(Nat.div(i, U32.to_nat(448)), 2n)),
         Nat.mul(2n, Nat.mod(Nat.div(i, U32.to_nat(896)), 2n))}

def same_small_state(+i: Nat) -> Bool:
  same_go(events_new(), events_old(), decode_small_new(i), decode_small_old(i))

def same_small_from(n: Nat, acc: Bool) -> Bool:
  match n:
    case 0n:
      acc
    case 1n++p:
      same_small_from(p, Bool.and(acc, same_small_state(p)))

def same_as_old_small() -> Bool:
  same_small_from(U32.to_nat(1792), True{})
