import Base
import ./fsm.bend as M
import ./fsm_LAWS.bend as Laws

def Laws.fire_guard(s, e):
  match s e:
    case M.Idle{} M.Arm{}:
      {==}
    case M.Idle{} M.Fire{True{}}:
      {==}
    case M.Idle{} M.Fire{False{}}:
      {==}
    case M.Idle{} M.Abort{}:
      {==}
    case M.Armed{} M.Arm{}:
      {==}
    case M.Armed{} M.Fire{True{}}:
      {==}
    case M.Armed{} M.Fire{False{}}:
      {==}
    case M.Armed{} M.Abort{}:
      {==}
    case M.Firing{} M.Arm{}:
      {==}
    case M.Firing{} M.Fire{True{}}:
      {==}
    case M.Firing{} M.Fire{False{}}:
      {==}
    case M.Firing{} M.Abort{}:
      {==}

def BoolClash.at(A: Type, b: Bool) -> Type:
  match b:
    case True{}:
      Unit
    case False{}:
      A

# any A follows from True == False
def clash_tf(-A: Type, e: {True{} == False{} : Bool}) -> A:
  %e : BoolClash.at(A, _)
  Unit{}

# any A follows from False == True
def clash_ft(-A: Type, e: {False{} == True{} : Bool}) -> A:
  clash_tf(A, Equal.sym(Bool, False{}, True{}, e))

# generalization: from any non-firing start state, a no-permit trace never reaches Firing
def run_not_firing(trace: List<M.Ev>, s: M.St, hs: {M.St.is_firing(s) == False{} : Bool}, h: {M.no_permit(trace) == True{} : Bool}) -> {M.St.is_firing(M.run(trace, s)) == False{} : Bool}:
  match trace:
    case Nil{}:
      hs
    case Con{e, t}:
      match e:
        case M.Arm{}:
          match s:
            case M.Idle{}:
              run_not_firing(t, M.Armed{}, {==}, h)
            case M.Armed{}:
              run_not_firing(t, M.Armed{}, {==}, h)
            case M.Firing{}:
              clash_tf({M.St.is_firing(M.run(t, M.step(M.Firing{}, M.Arm{}))) == False{} : Bool}, hs)
        case M.Fire{True{}}:
          clash_ft({M.St.is_firing(M.run(t, M.step(s, M.Fire{True{}}))) == False{} : Bool}, h)
        case M.Fire{False{}}:
          match s:
            case M.Idle{}:
              run_not_firing(t, M.Idle{}, {==}, h)
            case M.Armed{}:
              run_not_firing(t, M.Armed{}, {==}, h)
            case M.Firing{}:
              clash_tf({M.St.is_firing(M.run(t, M.step(M.Firing{}, M.Fire{False{}}))) == False{} : Bool}, hs)
        case M.Abort{}:
          match s:
            case M.Idle{}:
              run_not_firing(t, M.Idle{}, {==}, h)
            case M.Armed{}:
              run_not_firing(t, M.Idle{}, {==}, h)
            case M.Firing{}:
              run_not_firing(t, M.Idle{}, {==}, h)

def Laws.never_firing(trace, h):
  run_not_firing(trace, M.Idle{}, {==}, h)
