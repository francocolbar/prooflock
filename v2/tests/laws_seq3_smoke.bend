# laws_seq3_smoke.bend - the seq3 certificates at run time, before proving
import Base
import ./../seq3/seq3.bend as S
import ./../seq3/enum3.bend as E

def line(name: String, ok: Bool) -> String:
  match ok:
    case True{}:
      "ok    " ++ name ++ "\n"
    case False{}:
      "FALSE " ++ name ++ "\n"

def report() -> String:
  line("inv_init", S.inv_all(S.init())) ++
  line("check_fin: control invariants + counter shapes, 448 x 18 x 4", E.check_fin()) ++
  line("same_as_old: 7168 states x 18 events step identically to seq/seq.bend", E.same_as_old()) ++
  line("same_as_old (checker grid, 1792)", E.same_as_old_small()) ++
  "sample: " ++ S.show_st(S.run([S.Vac{True{}}, S.CmdCharge{}, S.Tf{True{}}, S.CmdPuff{}, S.CmdBreakdown{}, S.CmdFlatTop{}, S.Dens{True{}}, S.CmdHeatOn{}, S.Heartbeat{}, S.Tick{}, S.Heartbeat{}, S.Tick{}, S.Heartbeat{}, S.Tick{}, S.Heartbeat{}, S.Tick{}], S.init())) ++ "\n"

def main() -> IO(Unit):
  IO.write(report())
