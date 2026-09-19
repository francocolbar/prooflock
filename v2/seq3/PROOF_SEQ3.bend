# PROOF_SEQ3.bend - the laws of seq3, by REFLECTION on the finite certificate:
# PROOF_SEQ3_FIN.bend decides `check_fin() == True` by computation; here one small
# lemma per quantifier level turns that Bool into a universal statement about every
# (control state, event, verdicts) cell, and three short lemmas turn a cell into the
# preservation laws. The only induction is on the trace.
import Base
import ./seq3.bend as S
import ./enum3.bend as E
import ./LAWS_SEQ3.bend as Laws
import ./PROOF_SEQ3_FIN.bend as PF

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

# ---------------------------------------------------------------------------
# Reflection: from check_fin() == True down to one cell
# ---------------------------------------------------------------------------

# the tails of the phase conjunction in check_fin
def cf5() -> Bool:
  Bool.and(E.all_vac(S.RampDown{}), E.all_vac(S.Shutdown{}))

def cf4() -> Bool:
  Bool.and(E.all_vac(S.FlatTop{}), cf5())

def cf3() -> Bool:
  Bool.and(E.all_vac(S.Breakdown{}), cf4())

def cf2() -> Bool:
  Bool.and(E.all_vac(S.Prefill{}), cf3())

def cf1() -> Bool:
  Bool.and(E.all_vac(S.Charged{}), cf2())

def lvl_phase(p: S.Phase, h: {E.check_fin() == True{} : Bool}) -> {E.all_vac(p) == True{} : Bool}:
  match p:
    case S.Idle{}:
      and_l(E.all_vac(S.Idle{}), cf1(), h)
    case S.Charged{}:
      and_l(E.all_vac(S.Charged{}), cf2(), and_r(E.all_vac(S.Idle{}), cf1(), h))
    case S.Prefill{}:
      and_l(E.all_vac(S.Prefill{}), cf3(), and_r(E.all_vac(S.Charged{}), cf2(), and_r(E.all_vac(S.Idle{}), cf1(), h)))
    case S.Breakdown{}:
      and_l(E.all_vac(S.Breakdown{}), cf4(), and_r(E.all_vac(S.Prefill{}), cf3(), and_r(E.all_vac(S.Charged{}), cf2(), and_r(E.all_vac(S.Idle{}), cf1(), h))))
    case S.FlatTop{}:
      and_l(E.all_vac(S.FlatTop{}), cf5(), and_r(E.all_vac(S.Breakdown{}), cf4(), and_r(E.all_vac(S.Prefill{}), cf3(), and_r(E.all_vac(S.Charged{}), cf2(), and_r(E.all_vac(S.Idle{}), cf1(), h)))))
    case S.RampDown{}:
      and_l(E.all_vac(S.RampDown{}), E.all_vac(S.Shutdown{}), and_r(E.all_vac(S.FlatTop{}), cf5(), and_r(E.all_vac(S.Breakdown{}), cf4(), and_r(E.all_vac(S.Prefill{}), cf3(), and_r(E.all_vac(S.Charged{}), cf2(), and_r(E.all_vac(S.Idle{}), cf1(), h))))))
    case S.Shutdown{}:
      and_r(E.all_vac(S.RampDown{}), E.all_vac(S.Shutdown{}), and_r(E.all_vac(S.FlatTop{}), cf5(), and_r(E.all_vac(S.Breakdown{}), cf4(), and_r(E.all_vac(S.Prefill{}), cf3(), and_r(E.all_vac(S.Charged{}), cf2(), and_r(E.all_vac(S.Idle{}), cf1(), h))))))

def lvl_vac(+p: S.Phase, v: Bool, h: {E.all_vac(p) == True{} : Bool}) -> {E.all_tf(p, v) == True{} : Bool}:
  match v:
    case True{}:
      and_l(E.all_tf(p, True{}), E.all_tf(p, False{}), h)
    case False{}:
      and_r(E.all_tf(p, True{}), E.all_tf(p, False{}), h)

def lvl_tf(+p: S.Phase, +v: Bool, tf: Bool, h: {E.all_tf(p, v) == True{} : Bool}) -> {E.all_dens(p, v, tf) == True{} : Bool}:
  match tf:
    case True{}:
      and_l(E.all_dens(p, v, True{}), E.all_dens(p, v, False{}), h)
    case False{}:
      and_r(E.all_dens(p, v, True{}), E.all_dens(p, v, False{}), h)

def lvl_dens(+p: S.Phase, +v: Bool, +tf: Bool, d: Bool, h: {E.all_dens(p, v, tf) == True{} : Bool}) -> {E.all_gas(p, v, tf, d) == True{} : Bool}:
  match d:
    case True{}:
      and_l(E.all_gas(p, v, tf, True{}), E.all_gas(p, v, tf, False{}), h)
    case False{}:
      and_r(E.all_gas(p, v, tf, True{}), E.all_gas(p, v, tf, False{}), h)

def lvl_gas(+p: S.Phase, +v: Bool, +tf: Bool, +d: Bool, g: Bool, h: {E.all_gas(p, v, tf, d) == True{} : Bool}) -> {E.all_cs(p, v, tf, d, g) == True{} : Bool}:
  match g:
    case True{}:
      and_l(E.all_cs(p, v, tf, d, True{}), E.all_cs(p, v, tf, d, False{}), h)
    case False{}:
      and_r(E.all_cs(p, v, tf, d, True{}), E.all_cs(p, v, tf, d, False{}), h)

def lvl_cs(+p: S.Phase, +v: Bool, +tf: Bool, +d: Bool, +g: Bool, c: Bool, h: {E.all_cs(p, v, tf, d, g) == True{} : Bool}) -> {E.all_heat(p, v, tf, d, g, c) == True{} : Bool}:
  match c:
    case True{}:
      and_l(E.all_heat(p, v, tf, d, g, True{}), E.all_heat(p, v, tf, d, g, False{}), h)
    case False{}:
      and_r(E.all_heat(p, v, tf, d, g, True{}), E.all_heat(p, v, tf, d, g, False{}), h)

def lvl_heat(+p: S.Phase, +v: Bool, +tf: Bool, +d: Bool, +g: Bool, +c: Bool, ht: Bool, h: {E.all_heat(p, v, tf, d, g, c) == True{} : Bool}) -> {E.all_ev(S.Fin{p, v, tf, d, g, c, ht}) == True{} : Bool}:
  match ht:
    case True{}:
      and_l(E.all_ev(S.Fin{p, v, tf, d, g, c, True{}}), E.all_ev(S.Fin{p, v, tf, d, g, c, False{}}), h)
    case False{}:
      and_r(E.all_ev(S.Fin{p, v, tf, d, g, c, True{}}), E.all_ev(S.Fin{p, v, tf, d, g, c, False{}}), h)

# the shape of all_ev(f): and(and(g12, g34), and(g56, and(g78, g9)))
def g12(+f: S.Fin) -> Bool:
  Bool.and(E.ev_g1(f), E.ev_g2(f))

def g34(+f: S.Fin) -> Bool:
  Bool.and(E.ev_g3(f), E.ev_g4(f))

def g56(+f: S.Fin) -> Bool:
  Bool.and(E.ev_g5(f), E.ev_g6(f))

def g78(+f: S.Fin) -> Bool:
  Bool.and(E.ev_g7(f), E.ev_g8(f))

def evL(+f: S.Fin) -> Bool:
  Bool.and(g12(f), g34(f))

def evR2(+f: S.Fin) -> Bool:
  Bool.and(g78(f), E.ev_g9(f))

def evR(+f: S.Fin) -> Bool:
  Bool.and(g56(f), evR2(f))

def grp1(+f: S.Fin, h: {E.all_ev(f) == True{} : Bool}) -> {E.ev_g1(f) == True{} : Bool}:
  and_l(E.ev_g1(f), E.ev_g2(f), and_l(g12(f), g34(f), and_l(evL(f), evR(f), h)))

def grp2(+f: S.Fin, h: {E.all_ev(f) == True{} : Bool}) -> {E.ev_g2(f) == True{} : Bool}:
  and_r(E.ev_g1(f), E.ev_g2(f), and_l(g12(f), g34(f), and_l(evL(f), evR(f), h)))

def grp3(+f: S.Fin, h: {E.all_ev(f) == True{} : Bool}) -> {E.ev_g3(f) == True{} : Bool}:
  and_l(E.ev_g3(f), E.ev_g4(f), and_r(g12(f), g34(f), and_l(evL(f), evR(f), h)))

def grp4(+f: S.Fin, h: {E.all_ev(f) == True{} : Bool}) -> {E.ev_g4(f) == True{} : Bool}:
  and_r(E.ev_g3(f), E.ev_g4(f), and_r(g12(f), g34(f), and_l(evL(f), evR(f), h)))

def grp5(+f: S.Fin, h: {E.all_ev(f) == True{} : Bool}) -> {E.ev_g5(f) == True{} : Bool}:
  and_l(E.ev_g5(f), E.ev_g6(f), and_l(g56(f), evR2(f), and_r(evL(f), evR(f), h)))

def grp6(+f: S.Fin, h: {E.all_ev(f) == True{} : Bool}) -> {E.ev_g6(f) == True{} : Bool}:
  and_r(E.ev_g5(f), E.ev_g6(f), and_l(g56(f), evR2(f), and_r(evL(f), evR(f), h)))

def grp7(+f: S.Fin, h: {E.all_ev(f) == True{} : Bool}) -> {E.ev_g7(f) == True{} : Bool}:
  and_l(E.ev_g7(f), E.ev_g8(f), and_l(g78(f), E.ev_g9(f), and_r(g56(f), evR2(f), and_r(evL(f), evR(f), h))))

def grp8(+f: S.Fin, h: {E.all_ev(f) == True{} : Bool}) -> {E.ev_g8(f) == True{} : Bool}:
  and_r(E.ev_g7(f), E.ev_g8(f), and_l(g78(f), E.ev_g9(f), and_r(g56(f), evR2(f), and_r(evL(f), evR(f), h))))

def grp9(+f: S.Fin, h: {E.all_ev(f) == True{} : Bool}) -> {E.ev_g9(f) == True{} : Bool}:
  and_r(g78(f), E.ev_g9(f), and_r(g56(f), evR2(f), and_r(evL(f), evR(f), h)))

def lvl_ev(+f: S.Fin, e: S.Ev, h: {E.all_ev(f) == True{} : Bool}) -> {E.all_bt(f, e) == True{} : Bool}:
  match e:
    case S.Tick{}:
      and_l(E.all_bt(f, S.Tick{}), E.all_bt(f, S.Heartbeat{}), grp1(f, h))
    case S.Heartbeat{}:
      and_r(E.all_bt(f, S.Tick{}), E.all_bt(f, S.Heartbeat{}), grp1(f, h))
    case S.Vac{ok}:
      match ok:
        case True{}:
          and_l(E.all_bt(f, S.Vac{True{}}), E.all_bt(f, S.Vac{False{}}), grp2(f, h))
        case False{}:
          and_r(E.all_bt(f, S.Vac{True{}}), E.all_bt(f, S.Vac{False{}}), grp2(f, h))
    case S.Tf{ok}:
      match ok:
        case True{}:
          and_l(E.all_bt(f, S.Tf{True{}}), E.all_bt(f, S.Tf{False{}}), grp3(f, h))
        case False{}:
          and_r(E.all_bt(f, S.Tf{True{}}), E.all_bt(f, S.Tf{False{}}), grp3(f, h))
    case S.Dens{ok}:
      match ok:
        case True{}:
          and_l(E.all_bt(f, S.Dens{True{}}), E.all_bt(f, S.Dens{False{}}), grp4(f, h))
        case False{}:
          and_r(E.all_bt(f, S.Dens{True{}}), E.all_bt(f, S.Dens{False{}}), grp4(f, h))
    case S.CmdCharge{}:
      and_l(E.all_bt(f, S.CmdCharge{}), E.all_bt(f, S.CmdPuff{}), grp5(f, h))
    case S.CmdPuff{}:
      and_r(E.all_bt(f, S.CmdCharge{}), E.all_bt(f, S.CmdPuff{}), grp5(f, h))
    case S.CmdBreakdown{}:
      and_l(E.all_bt(f, S.CmdBreakdown{}), E.all_bt(f, S.CmdFlatTop{}), grp6(f, h))
    case S.CmdFlatTop{}:
      and_r(E.all_bt(f, S.CmdBreakdown{}), E.all_bt(f, S.CmdFlatTop{}), grp6(f, h))
    case S.CmdHeatOn{}:
      and_l(E.all_bt(f, S.CmdHeatOn{}), E.all_bt(f, S.CmdHeatOff{}), grp7(f, h))
    case S.CmdHeatOff{}:
      and_r(E.all_bt(f, S.CmdHeatOn{}), E.all_bt(f, S.CmdHeatOff{}), grp7(f, h))
    case S.CmdRampDown{}:
      and_l(E.all_bt(f, S.CmdRampDown{}), E.all_bt(f, S.Disruption{}), grp8(f, h))
    case S.Disruption{}:
      and_r(E.all_bt(f, S.CmdRampDown{}), E.all_bt(f, S.Disruption{}), grp8(f, h))
    case S.Abort{}:
      and_l(E.all_bt(f, S.Abort{}), E.all_bt(f, S.Reset{}), grp9(f, h))
    case S.Reset{}:
      and_r(E.all_bt(f, S.Abort{}), E.all_bt(f, S.Reset{}), grp9(f, h))

def lvl_bt(+f: S.Fin, +e: S.Ev, bt: Bool, h: {E.all_bt(f, e) == True{} : Bool}) -> {E.all_bh(f, e, bt) == True{} : Bool}:
  match bt:
    case True{}:
      and_l(E.all_bh(f, e, True{}), E.all_bh(f, e, False{}), h)
    case False{}:
      and_r(E.all_bh(f, e, True{}), E.all_bh(f, e, False{}), h)

def lvl_bh(+f: S.Fin, +e: S.Ev, +bt: Bool, bh: Bool, h: {E.all_bh(f, e, bt) == True{} : Bool}) -> {E.prop(f, e, bt, bh) == True{} : Bool}:
  match bh:
    case True{}:
      and_l(E.prop(f, e, bt, True{}), E.prop(f, e, bt, False{}), h)
    case False{}:
      and_r(E.prop(f, e, bt, True{}), E.prop(f, e, bt, False{}), h)

# every cell of the certificate holds
def cell(f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {E.prop(f, e, bt, bh) == True{} : Bool}:
  match f:
    case S.Fin{+p, +v, +tf, +d, +g, +c, +ht}:
      +f2 = {S.Fin{p, v, tf, d, g, c, ht} : S.Fin}
      lvl_bh(f2, e, bt, bh, lvl_bt(f2, e, bt, lvl_ev(f2, e,
        lvl_heat(p, v, tf, d, g, c, ht, lvl_cs(p, v, tf, d, g, c, lvl_gas(p, v, tf, d, g,
          lvl_dens(p, v, tf, d, lvl_tf(p, v, tf, lvl_vac(p, v, lvl_phase(p, Laws.finite_check()))))))))))

# the three conjuncts of a cell
def P1(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> Bool:
  S.implies(S.inv_fin(f), S.inv_fin(S.step_fin(f, e, bt, bh)))

def P2(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> Bool:
  S.implies(S.is_flattop(S.phase_of(S.step_fin(f, e, bt, bh))), S.shape_ok(S.upd_t(f, e, bt, bh), S.is_flattop(S.phase_of(f)), bt))

def P3(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> Bool:
  S.implies(S.is_watched(S.phase_of(S.step_fin(f, e, bt, bh))), S.shape_ok(S.upd_hb(f, e, bh), S.is_watched(S.phase_of(f)), bh))

def cell1(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {P1(f, e, bt, bh) == True{} : Bool}:
  and_l(P1(f, e, bt, bh), Bool.and(P2(f, e, bt, bh), P3(f, e, bt, bh)), cell(f, e, bt, bh))

def cell2(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {P2(f, e, bt, bh) == True{} : Bool}:
  and_l(P2(f, e, bt, bh), P3(f, e, bt, bh), and_r(P1(f, e, bt, bh), Bool.and(P2(f, e, bt, bh), P3(f, e, bt, bh)), cell(f, e, bt, bh)))

def cell3(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> {P3(f, e, bt, bh) == True{} : Bool}:
  and_r(P2(f, e, bt, bh), P3(f, e, bt, bh), and_r(P1(f, e, bt, bh), Bool.and(P2(f, e, bt, bh), P3(f, e, bt, bh)), cell(f, e, bt, bh)))

# ---------------------------------------------------------------------------
# From a cell to the counter bound: a Reset restarts at 0, a Keep inherits the old
# bound, an Inc was allowed by the verdict
# ---------------------------------------------------------------------------

def cnt_of_shape(fl: Bool, u: S.Upd, was: Bool, v: Bool, -n: Nat, -lim: Nat,
                 hs: {S.implies(fl, S.shape_ok(u, was, v)) == True{} : Bool},
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
# The laws
# ---------------------------------------------------------------------------

def Laws.inv_init():
  {==}

def Laws.pres_fin(s, h, e):
  match s:
    case S.St{+f, +t, +hb}:
      +bt = Nat.is_lt(1n+t, S.t_max())
      +bh = Nat.is_lt(1n+hb, S.hb_max())
      implies_e(S.inv_fin(f), S.inv_fin(S.step_fin(f, e, bt, bh)), cell1(f, e, bt, bh),
        and_l(S.inv_fin(f), Bool.and(S.l5_flat(S.St{f, t, hb}), S.l6_hb(S.St{f, t, hb})), h))

def Laws.pres_l5(s, h, e):
  match s:
    case S.St{+f, +t, +hb}:
      +bt = Nat.is_lt(1n+t, S.t_max())
      +bh = Nat.is_lt(1n+hb, S.hb_max())
      cnt_of_shape(S.is_flattop(S.phase_of(S.step_fin(f, e, bt, bh))), S.upd_t(f, e, bt, bh), S.is_flattop(S.phase_of(f)), bt, t, S.t_max(),
        cell2(f, e, bt, bh), {==}, {==},
        and_l(S.l5_flat(S.St{f, t, hb}), S.l6_hb(S.St{f, t, hb}),
          and_r(S.inv_fin(f), Bool.and(S.l5_flat(S.St{f, t, hb}), S.l6_hb(S.St{f, t, hb})), h)))

def Laws.pres_l6(s, h, e):
  match s:
    case S.St{+f, +t, +hb}:
      +bt = Nat.is_lt(1n+t, S.t_max())
      +bh = Nat.is_lt(1n+hb, S.hb_max())
      cnt_of_shape(S.is_watched(S.phase_of(S.step_fin(f, e, bt, bh))), S.upd_hb(f, e, bh), S.is_watched(S.phase_of(f)), bh, hb, S.hb_max(),
        cell3(f, e, bt, bh), {==}, {==},
        and_r(S.l5_flat(S.St{f, t, hb}), S.l6_hb(S.St{f, t, hb}),
          and_r(S.inv_fin(f), Bool.and(S.l5_flat(S.St{f, t, hb}), S.l6_hb(S.St{f, t, hb})), h)))

# one safe step: the three preservation laws, rebuilt as inv_all
def step_safe(+s: S.St, +hall: {S.inv_all(s) == True{} : Bool}, +e: S.Ev) -> {S.inv_all(S.step(s, e)) == True{} : Bool}:
  and_intro(S.inv_fin(S.fin_of(S.step(s, e))), Bool.and(S.l5_flat(S.step(s, e)), S.l6_hb(S.step(s, e))), Laws.pres_fin(s, hall, e),
    and_intro(S.l5_flat(S.step(s, e)), S.l6_hb(S.step(s, e)), Laws.pres_l5(s, hall, e), Laws.pres_l6(s, hall, e)))

# induction on the trace, generalized to any safe start state
def run_safe(trace: List<&2, S.Ev>, +s: S.St, +hall: {S.inv_all(s) == True{} : Bool}) -> {S.inv_all(S.run(trace, s)) == True{} : Bool}:
  match trace:
    case Nil{}:
      hall
    case Con{+e, t}:
      run_safe(t, S.step(s, e), step_safe(s, hall, e))

def Laws.traces_safe(trace):
  run_safe(trace, S.init(), Laws.inv_init())

# in Shutdown, L2-L4 force every actuator off
def Laws.shutdown_safe(f, h):
  match f:
    case S.Fin{p, v, tf, d, g, c, ht}:
      match p:
        case S.Shutdown{}:
          match g c ht:
            case False{} False{} False{}:
              {==}
            case False{} False{} True{}:
              clash_ft({S.l7_go(True{}, False{}, False{}, True{}) == True{} : Bool}, h)
            case False{} True{} False{}:
              clash_ft({S.l7_go(True{}, False{}, True{}, False{}) == True{} : Bool}, h)
            case False{} True{} True{}:
              clash_ft({S.l7_go(True{}, False{}, True{}, True{}) == True{} : Bool}, h)
            case True{} False{} False{}:
              clash_ft({S.l7_go(True{}, True{}, False{}, False{}) == True{} : Bool}, h)
            case True{} False{} True{}:
              clash_ft({S.l7_go(True{}, True{}, False{}, True{}) == True{} : Bool}, h)
            case True{} True{} False{}:
              clash_ft({S.l7_go(True{}, True{}, True{}, False{}) == True{} : Bool}, h)
            case True{} True{} True{}:
              clash_ft({S.l7_go(True{}, True{}, True{}, True{}) == True{} : Bool}, h)
        case S.Idle{}:
          {==}
        case S.Charged{}:
          {==}
        case S.Prefill{}:
          {==}
        case S.Breakdown{}:
          {==}
        case S.FlatTop{}:
          {==}
        case S.RampDown{}:
          {==}

def Laws.disruption_shuts_down(s):
  match s:
    case S.St{S.Fin{p, v, tf, d, g, c, ht}, t, hb}:
      {==}

def Laws.abort_shuts_down(s):
  match s:
    case S.St{S.Fin{p, v, tf, d, g, c, ht}, t, hb}:
      {==}
