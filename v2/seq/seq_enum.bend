# seq_enum.bend - exhaustive instantiation of the sequencer laws on the finite part of
# the state space (every phase, every sensor/actuator combination) with the counters at
# the values around their limits. Two uses:
#   (1) tests/laws_seq_smoke.bend runs check_all() at run time BEFORE the proofs are
#       attempted (7168 states x 18 events): a false law shows up in seconds;
#   (2) LAWS_SEQ_FINITE.bend states {check_small() == True{}} and the checker decides it
#       by computation (a smaller grid: the checker's evaluator is unary).

import Base
import ./seq.bend as S

def bool_of(n: Nat) -> Bool:
  match n:
    case 0n:
      False{}
    case 1n+_:
      True{}

def phase_of_idx(n: Nat) -> S.Phase:
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

# counter values around the limits: 0, 2, 3, 4
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

# decode a state index in 0 .. 7 * 64 * 4 * 4 - 1
def decode(+i: Nat) -> S.St:
  S.St{phase_of_idx(Nat.mod(i, 7n)),
       bool_of(Nat.mod(Nat.div(i, 7n), 2n)),
       bool_of(Nat.mod(Nat.div(i, 14n), 2n)),
       bool_of(Nat.mod(Nat.div(i, 28n), 2n)),
       bool_of(Nat.mod(Nat.div(i, 56n), 2n)),
       bool_of(Nat.mod(Nat.div(i, U32.to_nat(112)), 2n)),
       bool_of(Nat.mod(Nat.div(i, U32.to_nat(224)), 2n)),
       cnt_of_idx(Nat.mod(Nat.div(i, U32.to_nat(448)), 4n)),
       cnt_of_idx(Nat.mod(Nat.div(i, U32.to_nat(1792)), 4n))}

def n_states() -> Nat:
  U32.to_nat(7168)

def events() -> List<&2, S.Ev>:
  [S.Tick{}, S.Heartbeat{}, S.Vac{True{}}, S.Vac{False{}}, S.Tf{True{}}, S.Tf{False{}},
   S.Dens{True{}}, S.Dens{False{}}, S.CmdCharge{}, S.CmdPuff{}, S.CmdBreakdown{}, S.CmdFlatTop{},
   S.CmdHeatOn{}, S.CmdHeatOff{}, S.CmdRampDown{}, S.Disruption{}, S.Abort{}, S.Reset{}]

def implies(a: Bool, b: Bool) -> Bool:
  match a:
    case False{}:
      True{}
    case True{}:
      b

# inv_all(s) -> inv_all(step(s, e)) for every event e
def preserved_by(es: List<&2, S.Ev>, +s: S.St) -> Bool:
  match es:
    case Nil{}:
      True{}
    case Con{e, t}:
      Bool.and(implies(S.inv_all(s), S.inv_all(S.step(s, e))), preserved_by(t, s))

# the step-level laws: a disruption or an abort lands in Shutdown; L7 follows from the invariants
def step_laws(+s: S.St) -> Bool:
  Bool.and(S.is_shutdown(S.phase_of(S.step(s, S.Disruption{}))),
  Bool.and(S.is_shutdown(S.phase_of(S.step(s, S.Abort{}))),
           implies(S.inv_all(s), S.l7_safe(s))))

def check_state(+s: S.St) -> Bool:
  Bool.and(preserved_by(events(), s), step_laws(s))

# tail-recursive sweep over the state indices below n
def check_from(n: Nat, acc: Bool) -> Bool:
  match n:
    case 0n:
      acc
    case 1n++p:
      check_from(p, Bool.and(acc, check_state(decode(p))))

def check_all() -> Bool:
  check_from(n_states(), True{})

def bool_nat(b: Bool) -> Nat:
  match b:
    case True{}:
      1n
    case False{}:
      0n

# how many of the enumerated states satisfy the invariants (a sanity number)
def count_from(n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n++p:
      count_from(p, Nat.add(acc, bool_nat(S.inv_all(decode(p)))))

# a smaller grid for the checker: phases x sensors x actuators, counters fixed at 0 and at the limit-1
def decode_small(+i: Nat) -> S.St:
  S.St{phase_of_idx(Nat.mod(i, 7n)),
       bool_of(Nat.mod(Nat.div(i, 7n), 2n)),
       bool_of(Nat.mod(Nat.div(i, 14n), 2n)),
       bool_of(Nat.mod(Nat.div(i, 28n), 2n)),
       bool_of(Nat.mod(Nat.div(i, 56n), 2n)),
       bool_of(Nat.mod(Nat.div(i, U32.to_nat(112)), 2n)),
       bool_of(Nat.mod(Nat.div(i, U32.to_nat(224)), 2n)),
       Nat.mul(3n, Nat.mod(Nat.div(i, U32.to_nat(448)), 2n)),
       Nat.mul(2n, Nat.mod(Nat.div(i, U32.to_nat(896)), 2n))}

def check_small_from(n: Nat, acc: Bool) -> Bool:
  match n:
    case 0n:
      acc
    case 1n++p:
      check_small_from(p, Bool.and(acc, check_state(decode_small(p))))

# 7 * 64 * 2 * 2 = 1792 states x 18 events
def check_small() -> Bool:
  check_small_from(U32.to_nat(1792), True{})
