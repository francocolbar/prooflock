# LAWS_JETPROT_CONF.bend - conformance of the configuration instances (P11): the 28 cells of the
# published Table 1 (R-5; 15 printed, 13 by ditto mark) and the 21 assumed cells (A-4), transcribed a
# SECOND time, independently of table1_pub/table1 in jetprot.bend; instance 2, the blind row (A-25),
# instance 3 and the masks (A-21), and the DMS wiring.
# Proven in PROOF_JETPROT_CONF.bend by computation, one law per cell.

import Base
import ./jetprot.bend as S
import ./spec_jetprot.bend as Spec
import ./enum_jetprot.bend as E

law pub_Breakdown_Slow:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.Slow{}), S.LPtn{}) == True{} : Bool}

law pub_IpRise_Slow:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.Slow{}), S.LPtn{}) == True{} : Bool}

law pub_Limiter_Slow:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.Slow{}), S.LPtn{}) == True{} : Bool}

law pub_Xpoint_Slow:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.Slow{}), S.LPtn{}) == True{} : Bool}

law pub_Heating1_Slow:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.Slow{}), S.LRtps{}) == True{} : Bool}

law pub_Heating2_Slow:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Slow{}), S.LRtps{}) == True{} : Bool}

law pub_Termination_Slow:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.Slow{}), S.LPtn{}) == True{} : Bool}

law pub_Breakdown_Mhd:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_IpRise_Mhd:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_Limiter_Mhd:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_Xpoint_Mhd:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_Heating1_Mhd:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_Heating2_Mhd:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_Termination_Mhd:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law pub_Breakdown_Mchs:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.Mchs{}), S.LNone{}) == True{} : Bool}

law pub_IpRise_Mchs:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.Mchs{}), S.LNone{}) == True{} : Bool}

law pub_Limiter_Mchs:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.Mchs{}), S.LNone{}) == True{} : Bool}

law pub_Xpoint_Mchs:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.Mchs{}), S.LNone{}) == True{} : Bool}

law pub_Heating1_Mchs:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.Mchs{}), S.LRtps{}) == True{} : Bool}

law pub_Heating2_Mchs:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Mchs{}), S.LRtps{}) == True{} : Bool}

law pub_Termination_Mchs:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.Mchs{}), S.LPtn{}) == True{} : Bool}

law pub_Breakdown_Dhs:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}

law pub_IpRise_Dhs:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}

law pub_Limiter_Dhs:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}

law pub_Xpoint_Dhs:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}

law pub_Heating1_Dhs:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}

law pub_Heating2_Dhs:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Dhs{}), S.LJtt{}) == True{} : Bool}

law pub_Termination_Dhs:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.Dhs{}), S.LPtn{}) == True{} : Bool}

law asm_Breakdown_Fast:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_IpRise_Fast:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_Limiter_Fast:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_Xpoint_Fast:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_Heating1_Fast:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_Heating2_Fast:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_Termination_Fast:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.Fast{}), S.LPtn{}) == True{} : Bool}

law asm_Breakdown_MhdB:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_IpRise_MhdB:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_Limiter_MhdB:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_Xpoint_MhdB:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_Heating1_MhdB:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_Heating2_MhdB:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_Termination_MhdB:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law asm_Breakdown_BothHs:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}

law asm_IpRise_BothHs:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}

law asm_Limiter_BothHs:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}

law asm_Xpoint_BothHs:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}

law asm_Heating1_BothHs:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}

law asm_Heating2_BothHs:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.BothHs{}), S.LRtps{}) == True{} : Bool}

law asm_Termination_BothHs:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.BothHs{}), S.LPtn{}) == True{} : Bool}

law inst2_Breakdown_Mhd:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law inst2_IpRise_Mhd:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law inst2_Limiter_Mhd:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.Mhd{}), S.LNone{}) == True{} : Bool}

law inst2_Xpoint_Mhd:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.Mhd{}), S.LPtn{}) == True{} : Bool}

law inst2_Heating1_Mhd:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.Mhd{}), S.LPtn{}) == True{} : Bool}

law inst2_Heating2_Mhd:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.Mhd{}), S.LPtn{}) == True{} : Bool}

law inst2_Termination_Mhd:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.Mhd{}), S.LPtn{}) == True{} : Bool}

law inst2_Breakdown_MhdB:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law inst2_IpRise_MhdB:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law inst2_Limiter_MhdB:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.MhdB{}), S.LNone{}) == True{} : Bool}

law inst2_Xpoint_MhdB:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.MhdB{}), S.LPtn{}) == True{} : Bool}

law inst2_Heating1_MhdB:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.MhdB{}), S.LPtn{}) == True{} : Bool}

law inst2_Heating2_MhdB:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.MhdB{}), S.LPtn{}) == True{} : Bool}

law inst2_Termination_MhdB:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.MhdB{}), S.LPtn{}) == True{} : Bool}

law inst2_same_Breakdown_Slow:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.Slow{}), S.table1(S.Breakdown{}, S.Slow{})) == True{} : Bool}

law inst2_same_IpRise_Slow:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.Slow{}), S.table1(S.IpRise{}, S.Slow{})) == True{} : Bool}

law inst2_same_Limiter_Slow:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.Slow{}), S.table1(S.Limiter{}, S.Slow{})) == True{} : Bool}

law inst2_same_Xpoint_Slow:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.Slow{}), S.table1(S.Xpoint{}, S.Slow{})) == True{} : Bool}

law inst2_same_Heating1_Slow:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.Slow{}), S.table1(S.Heating1{}, S.Slow{})) == True{} : Bool}

law inst2_same_Heating2_Slow:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.Slow{}), S.table1(S.Heating2{}, S.Slow{})) == True{} : Bool}

law inst2_same_Termination_Slow:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.Slow{}), S.table1(S.Termination{}, S.Slow{})) == True{} : Bool}

law inst2_same_Breakdown_Fast:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.Fast{}), S.table1(S.Breakdown{}, S.Fast{})) == True{} : Bool}

law inst2_same_IpRise_Fast:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.Fast{}), S.table1(S.IpRise{}, S.Fast{})) == True{} : Bool}

law inst2_same_Limiter_Fast:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.Fast{}), S.table1(S.Limiter{}, S.Fast{})) == True{} : Bool}

law inst2_same_Xpoint_Fast:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.Fast{}), S.table1(S.Xpoint{}, S.Fast{})) == True{} : Bool}

law inst2_same_Heating1_Fast:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.Fast{}), S.table1(S.Heating1{}, S.Fast{})) == True{} : Bool}

law inst2_same_Heating2_Fast:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.Fast{}), S.table1(S.Heating2{}, S.Fast{})) == True{} : Bool}

law inst2_same_Termination_Fast:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.Fast{}), S.table1(S.Termination{}, S.Fast{})) == True{} : Bool}

law inst2_same_Breakdown_Mchs:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.Mchs{}), S.table1(S.Breakdown{}, S.Mchs{})) == True{} : Bool}

law inst2_same_IpRise_Mchs:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.Mchs{}), S.table1(S.IpRise{}, S.Mchs{})) == True{} : Bool}

law inst2_same_Limiter_Mchs:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.Mchs{}), S.table1(S.Limiter{}, S.Mchs{})) == True{} : Bool}

law inst2_same_Xpoint_Mchs:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.Mchs{}), S.table1(S.Xpoint{}, S.Mchs{})) == True{} : Bool}

law inst2_same_Heating1_Mchs:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.Mchs{}), S.table1(S.Heating1{}, S.Mchs{})) == True{} : Bool}

law inst2_same_Heating2_Mchs:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.Mchs{}), S.table1(S.Heating2{}, S.Mchs{})) == True{} : Bool}

law inst2_same_Termination_Mchs:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.Mchs{}), S.table1(S.Termination{}, S.Mchs{})) == True{} : Bool}

law inst2_same_Breakdown_Dhs:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.Dhs{}), S.table1(S.Breakdown{}, S.Dhs{})) == True{} : Bool}

law inst2_same_IpRise_Dhs:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.Dhs{}), S.table1(S.IpRise{}, S.Dhs{})) == True{} : Bool}

law inst2_same_Limiter_Dhs:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.Dhs{}), S.table1(S.Limiter{}, S.Dhs{})) == True{} : Bool}

law inst2_same_Xpoint_Dhs:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.Dhs{}), S.table1(S.Xpoint{}, S.Dhs{})) == True{} : Bool}

law inst2_same_Heating1_Dhs:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.Dhs{}), S.table1(S.Heating1{}, S.Dhs{})) == True{} : Bool}

law inst2_same_Heating2_Dhs:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.Dhs{}), S.table1(S.Heating2{}, S.Dhs{})) == True{} : Bool}

law inst2_same_Termination_Dhs:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.Dhs{}), S.table1(S.Termination{}, S.Dhs{})) == True{} : Bool}

law inst2_same_Breakdown_BothHs:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.BothHs{}), S.table1(S.Breakdown{}, S.BothHs{})) == True{} : Bool}

law inst2_same_IpRise_BothHs:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.BothHs{}), S.table1(S.IpRise{}, S.BothHs{})) == True{} : Bool}

law inst2_same_Limiter_BothHs:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.BothHs{}), S.table1(S.Limiter{}, S.BothHs{})) == True{} : Bool}

law inst2_same_Xpoint_BothHs:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.BothHs{}), S.table1(S.Xpoint{}, S.BothHs{})) == True{} : Bool}

law inst2_same_Heating1_BothHs:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.BothHs{}), S.table1(S.Heating1{}, S.BothHs{})) == True{} : Bool}

law inst2_same_Heating2_BothHs:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.BothHs{}), S.table1(S.Heating2{}, S.BothHs{})) == True{} : Bool}

law inst2_same_Termination_BothHs:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.BothHs{}), S.table1(S.Termination{}, S.BothHs{})) == True{} : Bool}

law asm_Breakdown_Blind:
  {Spec.lvl_eq(S.table1(S.Breakdown{}, S.Blind{}), S.LPtn{}) == True{} : Bool}

law asm_IpRise_Blind:
  {Spec.lvl_eq(S.table1(S.IpRise{}, S.Blind{}), S.LPtn{}) == True{} : Bool}

law asm_Limiter_Blind:
  {Spec.lvl_eq(S.table1(S.Limiter{}, S.Blind{}), S.LPtn{}) == True{} : Bool}

law asm_Xpoint_Blind:
  {Spec.lvl_eq(S.table1(S.Xpoint{}, S.Blind{}), S.LPtn{}) == True{} : Bool}

law asm_Heating1_Blind:
  {Spec.lvl_eq(S.table1(S.Heating1{}, S.Blind{}), S.LPtn{}) == True{} : Bool}

law asm_Heating2_Blind:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Blind{}), S.LPtn{}) == True{} : Bool}

law asm_Termination_Blind:
  {Spec.lvl_eq(S.table1(S.Termination{}, S.Blind{}), S.LPtn{}) == True{} : Bool}

law inst2_same_Breakdown_Blind:
  {Spec.lvl_eq(S.table2(S.Breakdown{}, S.Blind{}), S.table1(S.Breakdown{}, S.Blind{})) == True{} : Bool}

law inst2_same_IpRise_Blind:
  {Spec.lvl_eq(S.table2(S.IpRise{}, S.Blind{}), S.table1(S.IpRise{}, S.Blind{})) == True{} : Bool}

law inst2_same_Limiter_Blind:
  {Spec.lvl_eq(S.table2(S.Limiter{}, S.Blind{}), S.table1(S.Limiter{}, S.Blind{})) == True{} : Bool}

law inst2_same_Xpoint_Blind:
  {Spec.lvl_eq(S.table2(S.Xpoint{}, S.Blind{}), S.table1(S.Xpoint{}, S.Blind{})) == True{} : Bool}

law inst2_same_Heating1_Blind:
  {Spec.lvl_eq(S.table2(S.Heating1{}, S.Blind{}), S.table1(S.Heating1{}, S.Blind{})) == True{} : Bool}

law inst2_same_Heating2_Blind:
  {Spec.lvl_eq(S.table2(S.Heating2{}, S.Blind{}), S.table1(S.Heating2{}, S.Blind{})) == True{} : Bool}

law inst2_same_Termination_Blind:
  {Spec.lvl_eq(S.table2(S.Termination{}, S.Blind{}), S.table1(S.Termination{}, S.Blind{})) == True{} : Bool}

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

law dms_trig_Blind:
  {S.dms_trig(S.Blind{}) == False{} : Bool}

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

# --- blocker 4: the third instance and the masks of the two reliability checks (R-13, A-21) ---

# instance 3 reads the published matrix (instance 1) cell by cell
law inst3_uses_table1:
  for +p: S.Phase
  for +t: S.Trig
  {Spec.lvl_eq(S.table(S.Inst3{}, p, t), S.table1(p, t)) == True{} : Bool}

# which checks each instance enables (F3c): the two published instances run both, the third none
law mask_inst1_checks_on:
  {S.mask_of(S.Inst1{}) == S.Mask{True{}, True{}} : S.Mask}

law mask_inst2_checks_on:
  {S.mask_of(S.Inst2{}) == S.Mask{True{}, True{}} : S.Mask}

law mask_inst3_checks_off:
  {S.mask_of(S.Inst3{}) == S.Mask{False{}, False{}} : S.Mask}

# a blind alarm whose check is masked asks for no response, in every phase (F3, the blind half)
law blind_masked_no_response:
  for +p: S.Phase
  {Spec.lvl_eq(S.masked_table(S.Inst3{}, p, S.Blind{}), S.LNone{}) == True{} : Bool}

# P13 fast_ptn: the Fast trigger reaches the PTN in every phase, from any state, through
# either configuration instance (A-4: the cells are assumed, the mechanism is R-7)
law fast_ptn:
  for +i: S.Inst
  for +s: S.St
  {S.is_ptn(S.level_of(S.fin_of(S.step_c(i, s, S.XAlarm{S.Fast{}})))) == True{} : Bool}

# C1. The concrete layer: `concretize` is exactly the configuration -- value by value -- and the
# constructor wiring, for every instance, program phase, waveform flag and plant event (924 cells). The expectation it is
# compared against (enum_jetprot.bend: m_table1/m_table2/m_trig/m_win) is a fourth, independent
# transcription of R-5 + A-4 + A-25, of the DMS wiring and of the masks (A-21), so a wrong table
# cell, a wrong enable window, a table read on the waveform phase (F1a) or an ignored mask is caught
# here, not only a mis-wired column or a swapped command constructor (audit #5 section 4).
law concretize_is_the_table:
  {E.check_concretize() == True{} : Bool}

# C3. The concrete layer is USED as declared: a concrete step is the abstract step, under the
# order this instance is certified for (Ord1, A-1), on the control state BEFORE the
# transition, through THIS instance's configuration. Nothing else constrained step_c: reading
# instance 1's matrix from instance 2, or the next phase instead of the current one, or the other
# urgency order, were all invisible (audit #5 mutants N05/N06/N07).
law step_c_is_the_concrete_step:
  for +i: S.Inst
  for +s: S.St
  for +c: S.CEv
  {S.step_c(i, s, c) == S.step_o(S.Ord1{}, s, S.concretize(i, S.fin_of(s), c)) : S.St}
