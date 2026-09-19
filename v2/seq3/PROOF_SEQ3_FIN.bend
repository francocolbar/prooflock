# PROOF_SEQ3_FIN.bend - the finite certificate of the control (448 x 18 x 4 cells), by
# computation. PROOF_SEQ3.bend imports this file and turns it into universal laws.
import Base
import ./seq3.bend as S
import ./enum3.bend as E
import ./LAWS_SEQ3.bend as Laws

def Laws.finite_check():
  {==}
