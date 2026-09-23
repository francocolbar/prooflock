# PROOF_JETPROT_LIVE.bend - the gate for LAWS_JETPROT_LIVE.bend: the two bounded-response
# theorems of PROOF_JETPROT_LIVE_CORE.bend (watchdog_from, dms_from), proven there by
# induction on the trace over template hypotheses (the cell facts), instantiated here with
# the laws of LAWS_JETPROT.bend as proven by reflection in PROOF_JETPROT.bend:
#   step_safe  <- P0.step_safe (pres_fin + pres_i5 + pres_i6, rebuilt as inv_all)
#   P1         <- L0.latched
#   D4         <- L0.d4_watchdog_latches
#   D7         <- L0.d7_ack_timeout_fires
#   D8         <- L0.d8_ack_counts
#   P15        <- L0.dms_monotone
#   P18        <- L0.tack_frame
#   E11        <- L0.e11_heatack_exact
# Checking this file re-checks PROOF_JETPROT.bend and its certificates (the longest check of the
# gate; measured times in README section 4).
import Base
import ./jetprot.bend as S
import ./spec_jetprot.bend as Spec
import ./enum_jetprot.bend as E
import ./LAWS_JETPROT.bend as L0
import ./PROOF_JETPROT.bend as P0
import ./LAWS_JETPROT_SOUND.bend as LS
import ./PROOF_JETPROT_SOUND.bend as PS
import ./LAWS_JETPROT_LIVE.bend as Laws
import ./PROOF_JETPROT_LIVE_CORE.bend as Core

# L1: hb_max ticks without a heartbeat latch the PTN
def Laws.watchdog_responds(o, s, h_inv, trace, h_nohb, h_len):
  Core.watchdog_from(~P0.step_safe, ~L0.d4_watchdog_latches, ~L0.latched, o, s, h_inv, trace, h_nohb, h_len)

# L2: an armed DMS fires within ack_max ticks
def Laws.dms_responds(o, s, h_inv, h_armed, trace, h_noreset, h_len):
  Core.dms_from(~P0.step_safe, ~L0.d7_ack_timeout_fires, ~L0.d8_ack_counts, ~L0.dms_monotone, ~L0.tack_frame, ~L0.e11_heatack_exact,
    o, s, h_inv, h_armed, trace, h_noreset, h_len)
