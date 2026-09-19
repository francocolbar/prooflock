# LAWS_SEQ_FINITE.bend - the finite certificate, decided by the checker's evaluator:
# on 1792 states (every phase, every sensor and actuator combination, counters at 0
# and at the limit - 1) and all 18 events, every invariant is preserved and the
# step-level laws hold. Weaker than LAWS_SEQ.bend (the counters are not universal) but
# it is one line of proof ({==}) and it is the technique "certificate by computation".
# Proven in PROOF_SEQ_FINITE.bend. Its cost in the checker is measured in the findings.

import Base
import ./seq.bend as S
import ./seq_enum.bend as E

law finite_check:
  {E.check_small() == True{} : Bool}
