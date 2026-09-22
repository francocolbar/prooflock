# LAWS_JETPROT_LIVE.bend - bounded RESPONSE over traces (docs/STATUS_2026-09-21.md, blocker 5).
# Every other law of the case says what never happens (traces_safe) or what one step does. These
# two say that the protection ARRIVES within a bound, for every trace, every configuration and
# every value of the counters -- and they are universal in hb_max / ack_max: nothing here reads
# the certificate, so they hold whatever the limits are set to.
#
#   watchdog_responds : from any state that satisfies the invariant, a trace with no heartbeat and
#                       no end of pulse that contains at least hb_max ticks ends with the PTN latched.
#   dms_responds      : from any state that satisfies the invariant with the DMS armed, a trace with
#                       no end of pulse that contains at least ack_max ticks ends with the DMS fired.
#
# Proven in PROOF_JETPROT_LIVE_CORE.bend by induction on the trace from eight cell facts (the
# preservation theorem step_safe and the laws P1, D4, D7, D8, P15, P18, E11 of LAWS_JETPROT.bend),
# taken there as template hypotheses (Bend refuses live code that calls an unfilled law, so the
# facts cannot be open laws; the two closed theorems watchdog_from / dms_from quantify over them).
# PROOF_JETPROT_LIVE.bend instantiates them with the laws as proven by reflection in
# PROOF_JETPROT.bend and is the gate: it re-checks the certificates (11-18 min).

import Base
import ./jetprot.bend as S
import ./spec_jetprot.bend as Spec

# the number of Tick events in a trace
def ticks(trace: List<&2, S.Ev>) -> Nat:
  match trace:
    case Nil{}:
      0n
    case Con{e, t}:
      match e:
        case S.Tick{dms}:
          1n+ticks(t)
        case _:
          ticks(t)

# a trace that contains no Heartbeat and no Reset (the two events that restart the watchdog)
def no_hb(trace: List<&2, S.Ev>) -> Bool:
  match trace:
    case Nil{}:
      True{}
    case Con{e, t}:
      match e:
        case S.Heartbeat{}:
          False{}
        case S.Reset{}:
          False{}
        case _:
          no_hb(t)

# a trace that contains no Reset (the only event that disarms the DMS)
def no_reset(trace: List<&2, S.Ev>) -> Bool:
  match trace:
    case Nil{}:
      True{}
    case Con{e, t}:
      match e:
        case S.Reset{}:
          False{}
        case _:
          no_reset(t)

# L1: hb_max ticks without a heartbeat latch the PTN (R-13, A-12), whatever else happens in between
law watchdog_responds:
  for +o: S.Ord
  for +s: S.St
  for +h_inv: {S.inv_all(s) == True{} : Bool}
  for +trace: List<&2, S.Ev>
  for +h_nohb: {no_hb(trace) == True{} : Bool}
  for +h_len: {Nat.is_le(S.hb_max(), ticks(trace)) == True{} : Bool}
  {S.is_ptn(S.level_of(S.fin_of(S.run_o(o, trace, s)))) == True{} : Bool}

# L2: an armed DMS fires within ack_max ticks (R-11, A-11: the acknowledgement or the timeout)
law dms_responds:
  for +o: S.Ord
  for +s: S.St
  for +h_inv: {S.inv_all(s) == True{} : Bool}
  for +h_armed: {S.is_armed(S.dms_of(S.fin_of(s))) == True{} : Bool}
  for +trace: List<&2, S.Ev>
  for +h_noreset: {no_reset(trace) == True{} : Bool}
  for +h_len: {Nat.is_le(S.ack_max(), ticks(trace)) == True{} : Bool}
  {Spec.is_fired(S.dms_of(S.fin_of(S.run_o(o, trace, s)))) == True{} : Bool}
