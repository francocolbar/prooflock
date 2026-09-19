# laws_jetprot_smoke.bend - the jetprot certificates at run time, BEFORE proving: the
# whole domain for both urgency orders, the initial state, the published table cells, and
# a sample run through both configuration instances.
import Base
import ./../jetprot.bend as S
import ./../enum_jetprot.bend as E

def line(name: String, ok: Bool) -> String:
  match ok:
    case True{}:
      "ok    " ++ name ++ "\n"
    case False{}:
      "FALSE " ++ name ++ "\n"

def lvl_is(a: S.Level, b: S.Level) -> Bool:
  S.lvl_eq(a, b)

# a few printed cells of Table 1 (the full 28 + 21 are laws in LAWS_JETPROT_CONF.bend)
def table_cells() -> Bool:
  Bool.and(lvl_is(S.table1(S.Breakdown{}, S.Slow{}), S.LPtn{}),
  Bool.and(lvl_is(S.table1(S.Heating1{}, S.Mchs{}), S.LRtps{}),
  Bool.and(lvl_is(S.table1(S.Heating2{}, S.Dhs{}), S.LJtt{}),
  Bool.and(lvl_is(S.table1(S.Termination{}, S.Mhd{}), S.LNone{}),
  Bool.and(lvl_is(S.table1(S.IpRise{}, S.Dhs{}), S.LPtn{}),
           lvl_is(S.table2(S.Heating1{}, S.Mhd{}), S.LPtn{}))))))

# the happy path, then a divertor hotspot in Heating 2 (JTT), then a fast stop (PTN + DMS)
def sample() -> List<&2, S.CEv>:
  [S.XPlasma{True{}}, S.XAdvance{}, S.XAdvance{}, S.XAdvance{}, S.XAdvance{}, S.XHeatOn{S.Nb{}}, S.XHeartbeat{},
   S.XTick{}, S.XAdvance{}, S.XHeatOn{S.Rf{}}, S.XLocal{S.Nb{}}, S.XAlarm{S.Dhs{}}, S.XTick{}, S.XAlarm{S.Fast{}},
   S.XTick{}, S.XTick{}, S.XTick{}]

def report() -> String:
  line("inv_init", S.inv_all(S.init())) ++
  line("table cells (sample)", table_cells()) ++
  line("check_fin(Ord1): 2688 states x 39 columns, preservation + shapes + P1..P21", E.check_fin(S.Ord1{})) ++
  line("check_fin(Ord2): the same under the swapped urgency order (C3)", E.check_fin(S.Ord2{})) ++
  "sample (instance 1): " ++ S.show_st(S.run_c(S.Inst1{}, sample(), S.init())) ++ "\n" ++
  "sample (instance 2): " ++ S.show_st(S.run_c(S.Inst2{}, sample(), S.init())) ++ "\n" ++
  line("sample end state is safe", S.safe(S.fin_of(S.run_c(S.Inst1{}, sample(), S.init())))) ++
  line("sample end state satisfies inv_all", S.inv_all(S.run_c(S.Inst1{}, sample(), S.init())))

def main() -> IO(Unit):
  IO.write(report())
