# LAWS_SEQ3_SAME.bend - the redesigned model steps exactly like seq/seq.bend on 1792
# states x 18 events (structural comparison). Decided by the checker in ~30 s, so it
# lives in its own file: PROOF_SEQ3_SAME.bend.

import Base
import ./seq3.bend as S
import ./enum3.bend as E

law same_as_old:
  {E.same_as_old_small() == True{} : Bool}
