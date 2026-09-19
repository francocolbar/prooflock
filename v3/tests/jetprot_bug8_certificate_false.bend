import Base
import ./../jetprot.bend as S
import ./../enum_jetprot.bend as E

# NEGATIVE 8 (adequacy of the certificate) - the certificate claimed FALSE: the checker must
# evaluate the whole domain and reject, which shows that `{==}` on check_fin is decided by
# computation and not skipped.
law certificate_is_false:
  {E.check_fin(S.Ord1{}) == False{} : Bool}

def certificate_is_false():
  {==}
