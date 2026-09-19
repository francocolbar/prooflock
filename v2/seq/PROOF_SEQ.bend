# PROOF_SEQ.bend - the sequencer laws that are not per-invariant preservation:
# inv_init, shutdown_safe, disruption/abort, and the trace theorem traces_safe, which
# glues the six preservation laws (PROOF_SEQ_A.bend: L1-L3, PROOF_SEQ_B.bend: L4-L6).

import Base
import ./seq.bend as S
import ./LAWS_SEQ.bend as Laws
import ./PROOF_SEQ_A.bend as PA
import ./PROOF_SEQ_B.bend as PB

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

# from and(a, b) == True: a == True
def and_l(a: Bool, -b: Bool, h: {Bool.and(a, b) == True{} : Bool}) -> {a == True{} : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      h

# from and(a, b) == True: b == True
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

# ---------------------------------------------------------------------------
# The closed / step-level laws
# ---------------------------------------------------------------------------

def Laws.inv_init():
  {==}

def Laws.disruption_shuts_down(s):
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

def Laws.abort_shuts_down(s):
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

# the safe state has every actuator off: in Shutdown, L4 forces gas = False, L3 cs = False, L2 heat = False
def Laws.shutdown_safe(s, h2, h3, h4):
  match s:
    case S.St{S.Shutdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      match gas cs heat:
        case False{} False{} False{}:
          {==}
        case True{} c h:
          clash_ft({S.l7_safe(S.St{S.Shutdown{}, vac, tf, dens, True{}, c, h, t, hb}) == True{} : Bool}, h4)
        case False{} True{} h:
          clash_ft({S.l7_safe(S.St{S.Shutdown{}, vac, tf, dens, False{}, True{}, h, t, hb}) == True{} : Bool}, h3)
        case False{} False{} True{}:
          clash_ft({S.l7_safe(S.St{S.Shutdown{}, vac, tf, dens, False{}, False{}, True{}, t, hb}) == True{} : Bool}, h2)
    case S.St{S.Idle{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Charged{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Prefill{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.Breakdown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.FlatTop{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}
    case S.St{S.RampDown{}, vac, tf, dens, gas, cs, heat, t, hb}:
      {==}

# ---------------------------------------------------------------------------
# The trace theorem
# ---------------------------------------------------------------------------

# one safe step: split inv_all(s) into its six components, push each through its
# preservation law, and rebuild inv_all(step(s, e))
def step_safe(+s: S.St, +hall: {S.inv_all(s) == True{} : Bool}, +e: S.Ev) -> {S.inv_all(S.step(s, e)) == True{} : Bool}:
  +h1 = and_l(S.l1_field(s), Bool.and(S.l2_heat(s), Bool.and(S.l3_cs(s), Bool.and(S.l4_gas(s), Bool.and(S.l5_flat(s), S.l6_hb(s))))), hall)
  +r1 = and_r(S.l1_field(s), Bool.and(S.l2_heat(s), Bool.and(S.l3_cs(s), Bool.and(S.l4_gas(s), Bool.and(S.l5_flat(s), S.l6_hb(s))))), hall)
  +h2 = and_l(S.l2_heat(s), Bool.and(S.l3_cs(s), Bool.and(S.l4_gas(s), Bool.and(S.l5_flat(s), S.l6_hb(s)))), r1)
  +r2 = and_r(S.l2_heat(s), Bool.and(S.l3_cs(s), Bool.and(S.l4_gas(s), Bool.and(S.l5_flat(s), S.l6_hb(s)))), r1)
  +h3 = and_l(S.l3_cs(s), Bool.and(S.l4_gas(s), Bool.and(S.l5_flat(s), S.l6_hb(s))), r2)
  +r3 = and_r(S.l3_cs(s), Bool.and(S.l4_gas(s), Bool.and(S.l5_flat(s), S.l6_hb(s))), r2)
  +h4 = and_l(S.l4_gas(s), Bool.and(S.l5_flat(s), S.l6_hb(s)), r3)
  +r4 = and_r(S.l4_gas(s), Bool.and(S.l5_flat(s), S.l6_hb(s)), r3)
  +h5 = and_l(S.l5_flat(s), S.l6_hb(s), r4)
  +h6 = and_r(S.l5_flat(s), S.l6_hb(s), r4)
  n1 = Laws.pres_l1(s, h1, h2, h3, h4, h5, h6, e)
  n2 = Laws.pres_l2(s, h1, h2, h3, h4, h5, h6, e)
  n3 = Laws.pres_l3(s, h1, h2, h3, h4, h5, h6, e)
  n4 = Laws.pres_l4(s, h1, h2, h3, h4, h5, h6, e)
  n5 = Laws.pres_l5(s, h1, h2, h3, h4, h5, h6, e)
  n6 = Laws.pres_l6(s, h1, h2, h3, h4, h5, h6, e)
  and_intro(S.l1_field(S.step(s, e)), Bool.and(S.l2_heat(S.step(s, e)), Bool.and(S.l3_cs(S.step(s, e)), Bool.and(S.l4_gas(S.step(s, e)), Bool.and(S.l5_flat(S.step(s, e)), S.l6_hb(S.step(s, e)))))), n1,
  and_intro(S.l2_heat(S.step(s, e)), Bool.and(S.l3_cs(S.step(s, e)), Bool.and(S.l4_gas(S.step(s, e)), Bool.and(S.l5_flat(S.step(s, e)), S.l6_hb(S.step(s, e))))), n2,
  and_intro(S.l3_cs(S.step(s, e)), Bool.and(S.l4_gas(S.step(s, e)), Bool.and(S.l5_flat(S.step(s, e)), S.l6_hb(S.step(s, e)))), n3,
  and_intro(S.l4_gas(S.step(s, e)), Bool.and(S.l5_flat(S.step(s, e)), S.l6_hb(S.step(s, e))), n4,
  and_intro(S.l5_flat(S.step(s, e)), S.l6_hb(S.step(s, e)), n5, n6)))))

# induction on the trace, generalized to any safe start state
def run_safe(trace: List<&2, S.Ev>, +s: S.St, +hall: {S.inv_all(s) == True{} : Bool}) -> {S.inv_all(S.run(trace, s)) == True{} : Bool}:
  match trace:
    case Nil{}:
      hall
    case Con{+e, t}:
      run_safe(t, S.step(s, e), step_safe(s, hall, e))

def Laws.traces_safe(trace):
  run_safe(trace, S.init(), Laws.inv_init())
