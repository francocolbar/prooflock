# PROOF_JETPROT_FIN.bend - the finite certificate under the chosen urgency order, by
# computation (80 640 cells). PROOF_JETPROT.bend imports this file and turns it into universal laws.
import Base
import ./jetprot.bend as S
import ./enum_jetprot.bend as E
import ./LAWS_JETPROT.bend as Laws

def Laws.finite_check():
  {==}
