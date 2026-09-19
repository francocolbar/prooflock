# cfl_violation_PROOF.bend - a NEGATIVE test: the monotonicity certificate for the
# scheme r = 3/4 (Scheme{3n, 2n}) is FALSE (central weight -2), so this "proof" must
# be REJECTED by the checker. run.py asserts that `bend` fails on this file.
# Expected error at the {==} below: expected False{} (what all_nonneg computes) / observed True{}.

import Base
import ./../num/z.bend as Z
import ./../heat/ir.bend as IR

law weights_nonneg_bad:
  {IR.all_nonneg(IR.weights(IR.Scheme{3n, 2n})) == True{} : Bool}

def weights_nonneg_bad():
  {==}
