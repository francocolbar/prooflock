import Base
import ./../jetprot.bend as S
import ./../spec_jetprot.bend as Spec

# NEGATIVE 12 (revision 4) - the secondary table is never read: the concrete layer answers every
# alarm with the primary table, also while a stop is in force. In instances 1-3 that is
# invisible (their secondary entry IS the primary one); in the illustrative instance 4 (A-35) a
# second Slow alarm during an RTPS stop begun in Heating 1 asks for RTPS again and is ignored,
# where the PTN secondary is configured. The law inst4_second_alarm_ptn must be FALSE on this
# cell: the checker must reject.
def concretize_bug(+i: S.Inst, f: S.Fin, t: S.Trig) -> S.Ev:
  +f2 = f
  +t2 = t
  S.Stop{S.masked_table(i, S.prog_of(f2), t2), S.dms_req(S.wave_of(f2), t2)}

def witness() -> S.St:
  S.St{S.Fin{S.Heating1{}, False{}, S.LRtps{}, S.DmsIdle{}, True{}, True{}, S.Ramping{}, S.Off{}}, 0n, 0n}

law inst4_second_alarm_ptn_survives_primary_reading:
  {S.is_ptn(S.level_of(S.fin_of(S.step(witness(), concretize_bug(S.Inst4{}, S.fin_of(witness()), S.Slow{}))))) == True{} : Bool}

def inst4_second_alarm_ptn_survives_primary_reading():
  {==}
