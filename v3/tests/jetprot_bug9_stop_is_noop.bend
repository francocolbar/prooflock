import Base
import ./../jetprot.bend as S

# NEGATIVE 9 (the adversarial audit's mutant M26, the worst survivor of the old law set) -
# a stop request that reaches the PTN is IGNORED unless the instance also wires it to the
# DMS. With the published matrix that turns almost every PTN cell of Table 1 into a no-op --
# Slow, DHS, BothHs, MCHS and Fast outside the DMS window -- and the old law set could not
# see it: P1 only said the level never drops, and P2/P3 are conditional on the step actually
# reaching the level. D1 (stop_honoured) is the law that catches it.
def soft_bug(o: S.Ord, +req: S.Level, +f: S.Fin) -> S.Fin:
  S.soft_if(S.lvl_lt(o, S.level_of(f), req), req, f)

def stop_fin_bug(o: S.Ord, f: S.Fin, req: S.Level, d: Bool) -> S.Fin:
  match req d:
    case S.LPtn{} True{}:
      S.arm_dms(S.to_ptn(f))
    case S.LPtn{} False{}:
      f
    case r2 _:
      soft_bug(o, r2, f)

def witness() -> S.Fin:
  S.Fin{S.Heating1{}, S.LNone{}, S.DmsIdle{}, True{}, S.On{}, S.Off{}}

law stop_is_honoured_without_dms:
  {S.pr_d1(S.Ord1{}, witness(), S.Stop{S.LPtn{}, False{}}, stop_fin_bug(S.Ord1{}, witness(), S.LPtn{}, False{})) == True{} : Bool}

def stop_is_honoured_without_dms():
  {==}
