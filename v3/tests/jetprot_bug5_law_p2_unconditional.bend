import Base
import ./../jetprot.bend as S
import ./../enum_jetprot.bend as E

# NEGATIVE 5 (H12) - a FALSE LAW over the CORRECT model: P2 stated without "level != PTN"
# ("level' = PTN => no unit powered") fails on a spurious cell where the level already is
# PTN and a unit is On, with an event that changes nothing (Heartbeat). The checker must
# reject: step laws must hold on every cell of the domain, reachable or not.
def pr_p2_unconditional(+f2: S.Fin) -> Bool:
  S.implies(S.is_ptn(S.level_of(f2)), Bool.and(S.unpowered(S.nb_of(f2)), S.unpowered(S.rf_of(f2))))

def witness() -> S.Fin:
  S.Fin{S.Breakdown{}, S.LPtn{}, S.DmsIdle{}, False{}, S.Off{}, S.On{}}

law p2_without_the_reaching_condition:
  {pr_p2_unconditional(S.step_fin(S.Ord1{}, witness(), S.Heartbeat{}, True{}, True{})) == True{} : Bool}

def p2_without_the_reaching_condition():
  {==}
