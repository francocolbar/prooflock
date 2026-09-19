# LAWS_JETPROT_CONF.bend - conformance of the configuration instances (P11): the 28 cells of the
# published Table 1 (R-5; 15 printed, 13 by ditto mark) and the 21 assumed cells (A-4), transcribed a
# SECOND time, independently of table1_pub/table1 in jetprot.bend; instance 2 and the DMS wiring.
# Proven in PROOF_JETPROT_CONF.bend by computation, one law per cell.

import Base
import ./jetprot.bend as S
import ./enum_jetprot.bend as E

law pub_Breakdown_Slow:
  {S.lvl_eq(S.table1(S.Breakdown{}, S.Slow{}), S.LPtn{}) == True{} : Bool}

law pub_IpRise_Slow:
  {S.lvl_eq(S.table1(S.IpRise{}, S.Slow{}), S.LPtn{}) == True{} : Bool}

law pub_Limiter_Slow:
  {S.lvl_eq(S.table1(S.Limiter{}, S.Slow{}), S.LPtn{}) == True{} : Bool}

law pub_Xpoint_Slow:
  {S.lvl_eq(S.table1(S.Xpoint{}, S.Slow{}), S.LPtn{}) == True{} : Bool}

law pub_Heating1_Slow:
  {S.lvl_eq(S.table1(S.Heating1{}, S.Slow{}), S.LRtps{}) == True{} : Bool}

law pub_Heating2_Slow:
  {S.lvl_eq(S.table1(S.Heating2{}, S.Slow{}), S.LRtps{}) == True{} : Bool}

law pub_Termination_Slow:
  {S.lvl_eq(S.table1(S.Termination{}, S.Slow{}), S.LPtn{}) == True{} : Bool}

law pub_Breakdown_Mhd:
  {S.lvl_eq(S.table1(S.Breakdown{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_IpRise_Mhd:
  {S.lvl_eq(S.table1(S.IpRise{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_Limiter_Mhd:
  {S.lvl_eq(S.table1(S.Limiter{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_Xpoint_Mhd:
  {S.lvl_eq(S.table1(S.Xpoint{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_Heating1_Mhd:
  {S.lvl_eq(S.table1(S.Heating1{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_Heating2_Mhd:
  {S.lvl_eq(S.table1(S.Heating2{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_Termination_Mhd:
  {S.lvl_eq(S.table1(S.Termination{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_Breakdown_Mchs:
  {S.lvl_eq(S.table1(S.Breakdown{}, S.Mchs{}), S.LNone{}) == True{} : Bool}

law pub_IpRise_Mchs:
  {S.lvl_eq(S.table1(S.IpRise{}, S.Mchs{}), S.LNone{}) == True{} : Bool}

law pub_Limiter_Mchs:
  {S.lvl_eq(S.table1(S.Limiter{}, S.Mchs{}), S.LNone{}) == True{} : Bool}

law pub_Xpoint_Mchs:
  {S.lvl_eq(S.table1(S.Xpoint{}, S.Mchs{}), S.LNone{}) == True{} : Bool}

law pub_Heating1_Mchs:
  {S.lvl_eq(S.table1(S.Heating1{}, S.Mchs{}), S.LRtps{}) == True{} : Bool}

law pub_Heating2_Mchs:
  {S.lvl_eq(S.table1(S.Heating2{}, S.Mchs{}), S.LRtps{}) == True{} : Bool}

law pub_Termination_Mchs:
  {S.lvl_eq(S.table1(S.Termination{}, S.Mchs{}), S.LPtn{}) == True{} : Bool}

law pub_Breakdown_Dhs:
  {S.lvl_eq(S.table1(S.Breakdown{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}

law pub_IpRise_Dhs:
  {S.lvl_eq(S.table1(S.IpRise{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}

law pub_Limiter_Dhs:
  {S.lvl_eq(S.table1(S.Limiter{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}

law pub_Xpoint_Dhs:
  {S.lvl_eq(S.table1(S.Xpoint{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}

law pub_Heating1_Dhs:
  {S.lvl_eq(S.table1(S.Heating1{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}

law pub_Heating2_Dhs:
  {S.lvl_eq(S.table1(S.Heating2{}, S.Dhs{}), S.LJtt{}) == True{} : Bool}

law pub_Termination_Dhs:
  {S.lvl_eq(S.table1(S.Termination{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}

law asm_Breakdown_Fast:
  {S.lvl_eq(S.table1(S.Breakdown{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_IpRise_Fast:
  {S.lvl_eq(S.table1(S.IpRise{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_Limiter_Fast:
  {S.lvl_eq(S.table1(S.Limiter{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_Xpoint_Fast:
  {S.lvl_eq(S.table1(S.Xpoint{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_Heating1_Fast:
  {S.lvl_eq(S.table1(S.Heating1{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_Heating2_Fast:
  {S.lvl_eq(S.table1(S.Heating2{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_Termination_Fast:
  {S.lvl_eq(S.table1(S.Termination{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_Breakdown_MhdB:
  {S.lvl_eq(S.table1(S.Breakdown{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_IpRise_MhdB:
  {S.lvl_eq(S.table1(S.IpRise{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_Limiter_MhdB:
  {S.lvl_eq(S.table1(S.Limiter{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_Xpoint_MhdB:
  {S.lvl_eq(S.table1(S.Xpoint{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_Heating1_MhdB:
  {S.lvl_eq(S.table1(S.Heating1{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_Heating2_MhdB:
  {S.lvl_eq(S.table1(S.Heating2{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_Termination_MhdB:
  {S.lvl_eq(S.table1(S.Termination{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_Breakdown_BothHs:
  {S.lvl_eq(S.table1(S.Breakdown{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}

law asm_IpRise_BothHs:
  {S.lvl_eq(S.table1(S.IpRise{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}

law asm_Limiter_BothHs:
  {S.lvl_eq(S.table1(S.Limiter{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}

law asm_Xpoint_BothHs:
  {S.lvl_eq(S.table1(S.Xpoint{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}

law asm_Heating1_BothHs:
  {S.lvl_eq(S.table1(S.Heating1{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}

law asm_Heating2_BothHs:
  {S.lvl_eq(S.table1(S.Heating2{}, S.BothHs{}), S.LRtps{}) == True{} : Bool}

law asm_Termination_BothHs:
  {S.lvl_eq(S.table1(S.Termination{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}

law inst2_Breakdown_Mhd:
  {S.lvl_eq(S.table2(S.Breakdown{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law inst2_IpRise_Mhd:
  {S.lvl_eq(S.table2(S.IpRise{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law inst2_Limiter_Mhd:
  {S.lvl_eq(S.table2(S.Limiter{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law inst2_Xpoint_Mhd:
  {S.lvl_eq(S.table2(S.Xpoint{}, S.Mhd{}), S.LPtn{}) == True{} : Bool}

law inst2_Heating1_Mhd:
  {S.lvl_eq(S.table2(S.Heating1{}, S.Mhd{}), S.LPtn{}) == True{} : Bool}

law inst2_Heating2_Mhd:
  {S.lvl_eq(S.table2(S.Heating2{}, S.Mhd{}), S.LPtn{}) == True{} : Bool}

law inst2_Termination_Mhd:
  {S.lvl_eq(S.table2(S.Termination{}, S.Mhd{}), S.LPtn{}) == True{} : Bool}

law inst2_Breakdown_MhdB:
  {S.lvl_eq(S.table2(S.Breakdown{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law inst2_IpRise_MhdB:
  {S.lvl_eq(S.table2(S.IpRise{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law inst2_Limiter_MhdB:
  {S.lvl_eq(S.table2(S.Limiter{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law inst2_Xpoint_MhdB:
  {S.lvl_eq(S.table2(S.Xpoint{}, S.MhdB{}), S.LPtn{}) == True{} : Bool}

law inst2_Heating1_MhdB:
  {S.lvl_eq(S.table2(S.Heating1{}, S.MhdB{}), S.LPtn{}) == True{} : Bool}

law inst2_Heating2_MhdB:
  {S.lvl_eq(S.table2(S.Heating2{}, S.MhdB{}), S.LPtn{}) == True{} : Bool}

law inst2_Termination_MhdB:
  {S.lvl_eq(S.table2(S.Termination{}, S.MhdB{}), S.LPtn{}) == True{} : Bool}

law inst2_same_Breakdown_Slow:
  {S.lvl_eq(S.table2(S.Breakdown{}, S.Slow{}), S.table1(S.Breakdown{}, S.Slow{})) == True{} : Bool}

law inst2_same_IpRise_Slow:
  {S.lvl_eq(S.table2(S.IpRise{}, S.Slow{}), S.table1(S.IpRise{}, S.Slow{})) == True{} : Bool}

law inst2_same_Limiter_Slow:
  {S.lvl_eq(S.table2(S.Limiter{}, S.Slow{}), S.table1(S.Limiter{}, S.Slow{})) == True{} : Bool}

law inst2_same_Xpoint_Slow:
  {S.lvl_eq(S.table2(S.Xpoint{}, S.Slow{}), S.table1(S.Xpoint{}, S.Slow{})) == True{} : Bool}

law inst2_same_Heating1_Slow:
  {S.lvl_eq(S.table2(S.Heating1{}, S.Slow{}), S.table1(S.Heating1{}, S.Slow{})) == True{} : Bool}

law inst2_same_Heating2_Slow:
  {S.lvl_eq(S.table2(S.Heating2{}, S.Slow{}), S.table1(S.Heating2{}, S.Slow{})) == True{} : Bool}

law inst2_same_Termination_Slow:
  {S.lvl_eq(S.table2(S.Termination{}, S.Slow{}), S.table1(S.Termination{}, S.Slow{})) == True{} : Bool}

law inst2_same_Breakdown_Fast:
  {S.lvl_eq(S.table2(S.Breakdown{}, S.Fast{}), S.table1(S.Breakdown{}, S.Fast{})) == True{} : Bool}

law inst2_same_IpRise_Fast:
  {S.lvl_eq(S.table2(S.IpRise{}, S.Fast{}), S.table1(S.IpRise{}, S.Fast{})) == True{} : Bool}

law inst2_same_Limiter_Fast:
  {S.lvl_eq(S.table2(S.Limiter{}, S.Fast{}), S.table1(S.Limiter{}, S.Fast{})) == True{} : Bool}

law inst2_same_Xpoint_Fast:
  {S.lvl_eq(S.table2(S.Xpoint{}, S.Fast{}), S.table1(S.Xpoint{}, S.Fast{})) == True{} : Bool}

law inst2_same_Heating1_Fast:
  {S.lvl_eq(S.table2(S.Heating1{}, S.Fast{}), S.table1(S.Heating1{}, S.Fast{})) == True{} : Bool}

law inst2_same_Heating2_Fast:
  {S.lvl_eq(S.table2(S.Heating2{}, S.Fast{}), S.table1(S.Heating2{}, S.Fast{})) == True{} : Bool}

law inst2_same_Termination_Fast:
  {S.lvl_eq(S.table2(S.Termination{}, S.Fast{}), S.table1(S.Termination{}, S.Fast{})) == True{} : Bool}

law inst2_same_Breakdown_Mchs:
  {S.lvl_eq(S.table2(S.Breakdown{}, S.Mchs{}), S.table1(S.Breakdown{}, S.Mchs{})) == True{} : Bool}

law inst2_same_IpRise_Mchs:
  {S.lvl_eq(S.table2(S.IpRise{}, S.Mchs{}), S.table1(S.IpRise{}, S.Mchs{})) == True{} : Bool}

law inst2_same_Limiter_Mchs:
  {S.lvl_eq(S.table2(S.Limiter{}, S.Mchs{}), S.table1(S.Limiter{}, S.Mchs{})) == True{} : Bool}

law inst2_same_Xpoint_Mchs:
  {S.lvl_eq(S.table2(S.Xpoint{}, S.Mchs{}), S.table1(S.Xpoint{}, S.Mchs{})) == True{} : Bool}

law inst2_same_Heating1_Mchs:
  {S.lvl_eq(S.table2(S.Heating1{}, S.Mchs{}), S.table1(S.Heating1{}, S.Mchs{})) == True{} : Bool}

law inst2_same_Heating2_Mchs:
  {S.lvl_eq(S.table2(S.Heating2{}, S.Mchs{}), S.table1(S.Heating2{}, S.Mchs{})) == True{} : Bool}

law inst2_same_Termination_Mchs:
  {S.lvl_eq(S.table2(S.Termination{}, S.Mchs{}), S.table1(S.Termination{}, S.Mchs{})) == True{} : Bool}

law inst2_same_Breakdown_Dhs:
  {S.lvl_eq(S.table2(S.Breakdown{}, S.Dhs{}), S.table1(S.Breakdown{}, S.Dhs{})) == True{} : Bool}

law inst2_same_IpRise_Dhs:
  {S.lvl_eq(S.table2(S.IpRise{}, S.Dhs{}), S.table1(S.IpRise{}, S.Dhs{})) == True{} : Bool}

law inst2_same_Limiter_Dhs:
  {S.lvl_eq(S.table2(S.Limiter{}, S.Dhs{}), S.table1(S.Limiter{}, S.Dhs{})) == True{} : Bool}

law inst2_same_Xpoint_Dhs:
  {S.lvl_eq(S.table2(S.Xpoint{}, S.Dhs{}), S.table1(S.Xpoint{}, S.Dhs{})) == True{} : Bool}

law inst2_same_Heating1_Dhs:
  {S.lvl_eq(S.table2(S.Heating1{}, S.Dhs{}), S.table1(S.Heating1{}, S.Dhs{})) == True{} : Bool}

law inst2_same_Heating2_Dhs:
  {S.lvl_eq(S.table2(S.Heating2{}, S.Dhs{}), S.table1(S.Heating2{}, S.Dhs{})) == True{} : Bool}

law inst2_same_Termination_Dhs:
  {S.lvl_eq(S.table2(S.Termination{}, S.Dhs{}), S.table1(S.Termination{}, S.Dhs{})) == True{} : Bool}

law inst2_same_Breakdown_BothHs:
  {S.lvl_eq(S.table2(S.Breakdown{}, S.BothHs{}), S.table1(S.Breakdown{}, S.BothHs{})) == True{} : Bool}

law inst2_same_IpRise_BothHs:
  {S.lvl_eq(S.table2(S.IpRise{}, S.BothHs{}), S.table1(S.IpRise{}, S.BothHs{})) == True{} : Bool}

law inst2_same_Limiter_BothHs:
  {S.lvl_eq(S.table2(S.Limiter{}, S.BothHs{}), S.table1(S.Limiter{}, S.BothHs{})) == True{} : Bool}

law inst2_same_Xpoint_BothHs:
  {S.lvl_eq(S.table2(S.Xpoint{}, S.BothHs{}), S.table1(S.Xpoint{}, S.BothHs{})) == True{} : Bool}

law inst2_same_Heating1_BothHs:
  {S.lvl_eq(S.table2(S.Heating1{}, S.BothHs{}), S.table1(S.Heating1{}, S.BothHs{})) == True{} : Bool}

law inst2_same_Heating2_BothHs:
  {S.lvl_eq(S.table2(S.Heating2{}, S.BothHs{}), S.table1(S.Heating2{}, S.BothHs{})) == True{} : Bool}

law inst2_same_Termination_BothHs:
  {S.lvl_eq(S.table2(S.Termination{}, S.BothHs{}), S.table1(S.Termination{}, S.BothHs{})) == True{} : Bool}

law dms_trig_Fast:
  {S.dms_trig(S.Fast{}) == True{} : Bool}

law dms_trig_Mhd:
  {S.dms_trig(S.Mhd{}) == True{} : Bool}

law dms_trig_MhdB:
  {S.dms_trig(S.MhdB{}) == True{} : Bool}

law dms_trig_Slow:
  {S.dms_trig(S.Slow{}) == False{} : Bool}

law dms_trig_Mchs:
  {S.dms_trig(S.Mchs{}) == False{} : Bool}

law dms_trig_Dhs:
  {S.dms_trig(S.Dhs{}) == False{} : Bool}

law dms_trig_BothHs:
  {S.dms_trig(S.BothHs{}) == False{} : Bool}

law dms_window_Breakdown:
  {S.dms_window(S.Breakdown{}) == False{} : Bool}

law dms_window_IpRise:
  {S.dms_window(S.IpRise{}) == False{} : Bool}

law dms_window_Limiter:
  {S.dms_window(S.Limiter{}) == False{} : Bool}

law dms_window_Xpoint:
  {S.dms_window(S.Xpoint{}) == True{} : Bool}

law dms_window_Heating1:
  {S.dms_window(S.Heating1{}) == True{} : Bool}

law dms_window_Heating2:
  {S.dms_window(S.Heating2{}) == True{} : Bool}

law dms_window_Termination:
  {S.dms_window(S.Termination{}) == True{} : Bool}

law dms_on_commfault_off:
  {S.dms_on_commfault() == False{} : Bool}

law dms_on_watchdog_off:
  {S.dms_on_watchdog() == False{} : Bool}

# P13 fast_ptn: the Fast trigger reaches the PTN in every phase, from any state, through
# either configuration instance (A-4: the cells are assumed, the mechanism is R-7)
law fast_ptn:
  for +i: S.Inst
  for +s: S.St
  {S.is_ptn(S.level_of(S.fin_of(S.step_c(i, s, S.XAlarm{S.Fast{}})))) == True{} : Bool}

# C1. The concrete layer: `concretize` is exactly the configuration -- value by value -- and the
# constructor wiring, for every instance, phase and plant event (294 cells). The expectation it is
# compared against (enum_jetprot.bend: m_table1/m_table2/m_trig/m_win) is a fourth, independent
# transcription of R-5 + A-4 and of the DMS wiring, so a wrong table cell or a wrong enable window
# is caught here, not only a mis-wired column or a swapped command constructor (audit #5 section 4).
law concretize_is_the_table:
  {E.check_concretize() == True{} : Bool}

# C3. The concrete layer is USED as declared: a concrete step is the abstract step, under the
# order this instance is certified for (Ord1, A-1), on the phase the state is in BEFORE the
# transition, through THIS instance's configuration. Nothing else constrained step_c: reading
# instance 1's matrix from instance 2, or the next phase instead of the current one, or the other
# urgency order, were all invisible (audit #5 mutants N05/N06/N07).
law step_c_is_the_concrete_step:
  for +i: S.Inst
  for +s: S.St
  for +c: S.CEv
  {S.step_c(i, s, c) == S.step_o(S.Ord1{}, s, S.concretize(i, S.phase_of(S.fin_of(s)), c)) : S.St}
