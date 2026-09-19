import Base
import ./fsm.bend as M

law fire_guard:
  for s: M.St
  for e: M.Ev
  {M.entered_firing_ok(s, e) == True{} : Bool}

law never_firing:
  for trace: List<M.Ev>
  for h: {M.no_permit(trace) == True{} : Bool}
  {M.St.is_firing(M.run(trace, M.Idle{})) == False{} : Bool}
