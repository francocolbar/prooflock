import Base

# A toy interlock: the coil may only fire when armed AND the permit is on.
type St is Data:
  Idle{}
  Armed{}
  Firing{}

type Ev is Data:
  Arm{}
  Fire{permit: Bool}
  Abort{}

def St.is_firing(s: St) -> Bool:
  match s:
    case Firing{}:
      True{}
    case _:
      False{}

def step(s: St, e: Ev) -> St:
  match s e:
    case Idle{} Arm{}:
      Armed{}
    case Armed{} Fire{True{}}:
      Firing{}
    case _ Abort{}:
      Idle{}
    case s2 _:
      s2

# spec: Firing is ENTERED only through Armed + Fire{True} (staying in Firing is not entering)
def entered_firing_ok(s: St, e: Ev) -> Bool:
  match s e:
    case Armed{} Fire{True{}}:
      True{}
    case Firing{} _:
      True{}
    case s2 e2:
      Bool.not(St.is_firing(step(s2, e2)))

def run(trace: List<Ev>, s: St) -> St:
  match trace:
    case Nil{}:
      s
    case Con{e, t}:
      run(t, step(s, e))

# a trace with no permitted Fire
def no_permit(trace: List<Ev>) -> Bool:
  match trace:
    case Nil{}:
      True{}
    case Con{Fire{True{}}, t}:
      False{}
    case Con{_, t}:
      no_permit(t)

def main() -> St:
  run([Arm{}, Fire{False{}}, Fire{True{}}, Abort{}], Idle{})
