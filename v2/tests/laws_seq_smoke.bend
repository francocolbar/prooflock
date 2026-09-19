# laws_seq_smoke.bend - exhaustive instantiation of every sequencer law on the finite
# grid (7168 states x 18 events) at run time, BEFORE the proofs are attempted.
import Base
import ./../seq/seq.bend as S
import ./../seq/seq_enum.bend as E

def line(name: String, ok: Bool) -> String:
  match ok:
    case True{}:
      "ok    " ++ name ++ "\n"
    case False{}:
      "FALSE " ++ name ++ "\n"

def report() -> String:
  line("inv_init", S.inv_all(S.init())) ++
  line("preservation of L1..L6 + disruption/abort -> Shutdown + L7 corollary, 7168 states x 18 events", E.check_all()) ++
  line("same on the checker-sized grid (1792 states)", E.check_small()) ++
  "states satisfying inv_all: " ++ Nat.show(E.count_from(E.n_states(), 0n)) ++ " of " ++ Nat.show(E.n_states()) ++ "\n" ++
  "sample: run [CmdCharge, Vac T, Tf T, CmdPuff, CmdBreakdown, CmdFlatTop, Dens T, CmdHeatOn, Tick, Tick, Tick, Tick, Tick] = " ++
  S.show_st(S.run([S.Vac{True{}}, S.CmdCharge{}, S.Tf{True{}}, S.CmdPuff{}, S.CmdBreakdown{}, S.CmdFlatTop{}, S.Dens{True{}}, S.CmdHeatOn{}, S.Heartbeat{}, S.Tick{}, S.Heartbeat{}, S.Tick{}, S.Heartbeat{}, S.Tick{}, S.Heartbeat{}, S.Tick{}], S.init())) ++ "\n" ++
  "sample: missed heartbeats in flat-top = " ++
  S.show_st(S.run([S.Vac{True{}}, S.CmdCharge{}, S.Tf{True{}}, S.CmdPuff{}, S.CmdBreakdown{}, S.CmdFlatTop{}, S.Tick{}, S.Tick{}, S.Tick{}], S.init())) ++ "\n"

def main() -> IO(Unit):
  IO.write(report())
