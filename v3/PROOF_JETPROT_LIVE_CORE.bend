# PROOF_JETPROT_LIVE_CORE.bend - the two bounded-response laws of LAWS_JETPROT_LIVE.bend
# (watchdog_responds, dms_responds) by induction on the trace, from a handful of CELL FACTS
# (restatements of laws of LAWS_JETPROT.bend). This file checks in seconds: it imports no
# certificate.
#
# Bend 2.0.24 refuses live code that calls an unfilled law ("an unfilled law is a dead
# claim"), so the facts cannot be open laws here: each lemma that needs one takes it as a
# template hypothesis (`for ~fact: @+o: S.Ord -> ... -> {...}`, usable any number of times),
# and the two closed theorems `watchdog_from` / `dms_from` are quantified over all the facts.
# PROOF_JETPROT_LIVE.bend instantiates them with the laws of LAWS_JETPROT.bend (through
# PROOF_JETPROT.bend) and fills Laws.watchdog_responds / Laws.dms_responds; here those two
# stay open, so `bend PROOF_JETPROT_LIVE_CORE.bend` must report exactly `Error: 2 TODOs found.`
#
# Facts used: step_safe (pres_fin+pres_i5+pres_i6), P1 latched, D4, D7, D8, P15, P18, E11.
#
# Shape: the claim carried by the induction is a Bool disjunction,
#   W(trace, s) = ptn latched in s  OR  hb_max <= ticks(trace) + hb(s)
#   D(trace, s) = dms fired in s    OR  (dms armed in s AND ack_max <= ticks(trace) + tack(s))
# Nil: the invariant (I6 / I5) refutes the right disjunct. Con: a step lemma re-establishes
# the claim on step_o(o, s, e) from the facts; the induction only threads it.
import Base
import ./jetprot.bend as S
import ./spec_jetprot.bend as Spec
import ./LAWS_JETPROT_SOUND.bend as LS
import ./PROOF_JETPROT_SOUND.bend as PS
import ./LAWS_JETPROT_LIVE.bend as Laws

# ---------------------------------------------------------------------------
# Bool facts (as in PROOF_JETPROT.bend)
# ---------------------------------------------------------------------------

def At(A: Type, b: Bool) -> Type:
  match b:
    case True{}:
      A
    case False{}:
      Unit

def clash_ft(-A: Type, e: {False{} == True{} : Bool}) -> A:
  %e : At(A, _)
  Unit{}

def and_l(a: Bool, -b: Bool, h: {Bool.and(a, b) == True{} : Bool}) -> {a == True{} : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      h

def and_r(a: Bool, -b: Bool, h: {Bool.and(a, b) == True{} : Bool}) -> {b == True{} : Bool}:
  match a:
    case True{}:
      h
    case False{}:
      clash_ft({b == True{} : Bool}, h)

def and_intro(a: Bool, -b: Bool, ha: {a == True{} : Bool}, hb: {b == True{} : Bool}) -> {Bool.and(a, b) == True{} : Bool}:
  match a:
    case True{}:
      hb
    case False{}:
      clash_ft({Bool.and(False{}, b) == True{} : Bool}, ha)

def implies_e(a: Bool, -b: Bool, h: {S.implies(a, b) == True{} : Bool}, ha: {a == True{} : Bool}) -> {b == True{} : Bool}:
  match a:
    case True{}:
      h
    case False{}:
      clash_ft({b == True{} : Bool}, ha)

def or_l(a: Bool, -b: Bool, h: {a == True{} : Bool}) -> {Bool.or(a, b) == True{} : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      clash_ft({Bool.or(False{}, b) == True{} : Bool}, h)

def or_r(a: Bool, -b: Bool, h: {b == True{} : Bool}) -> {Bool.or(a, b) == True{} : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      h

# the right disjunct, when the left one is known false
def or_false_l(a: Bool, -b: Bool, ha: {False{} == a : Bool}, h: {Bool.or(a, b) == True{} : Bool}) -> {b == True{} : Bool}:
  match a:
    case True{}:
      clash_ft({b == True{} : Bool}, ha)
    case False{}:
      h

def not_of(b: Bool, e: {False{} == b : Bool}) -> {Bool.not(b) == True{} : Bool}:
  match b:
    case True{}:
      clash_ft({Bool.not(True{}) == True{} : Bool}, e)
    case False{}:
      {==}

# or(a, b) and c give or(a, and(b, c))
def or_and(a: Bool, b: Bool, -c: Bool, h1: {Bool.or(a, b) == True{} : Bool}, h2: {c == True{} : Bool}) -> {Bool.or(a, Bool.and(b, c)) == True{} : Bool}:
  match a b:
    case True{} True{}:
      {==}
    case True{} False{}:
      {==}
    case False{} True{}:
      h2
    case False{} False{}:
      clash_ft({Bool.or(False{}, Bool.and(False{}, c)) == True{} : Bool}, h1)

# ---------------------------------------------------------------------------
# Nat facts (over Base's Nat.is_lt / Nat.is_le / Nat.add)
# ---------------------------------------------------------------------------

def add_succ(a: Nat, -b: Nat) -> {1n+Nat.add(a, b) == Nat.add(a, 1n+b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, b) : {2n+Nat.add(p, b) == 1n+_ : Nat}
      {==}

def le_zero(c: Nat) -> {Nat.is_le(0n, c) == True{} : Bool}:
  match c:
    case 0n:
      {==}
    case 1n+p:
      {==}

# a <= b gives a <= b + c
def le_add_r(a: Nat, b: Nat, +c: Nat, h: {Nat.is_le(a, b) == True{} : Bool}) -> {Nat.is_le(a, Nat.add(b, c)) == True{} : Bool}:
  match a b:
    case 0n b:
      le_zero(Nat.add(b, c))
    case 1n+p 0n:
      clash_ft({Nat.is_le(1n+p, Nat.add(0n, c)) == True{} : Bool}, h)
    case 1n+p 1n+q:
      le_add_r(p, q, c, h)

# n < m and m <= n cannot both hold
def lt_le_absurd(n: Nat, m: Nat, h1: {Nat.is_lt(n, m) == True{} : Bool}, h2: {Nat.is_le(m, n) == True{} : Bool}) -> Empty:
  match n m:
    case 0n 0n:
      clash_ft(Empty, h1)
    case 0n 1n+q:
      clash_ft(Empty, h2)
    case 1n+p 0n:
      clash_ft(Empty, h1)
    case 1n+p 1n+q:
      lt_le_absurd(p, q, h1, h2)

# a <= 1 + (b + c) gives a <= b + (1 + c)
def le_shift(a: Nat, b: Nat, c: Nat, h: {Nat.is_le(a, 1n+Nat.add(b, c)) == True{} : Bool}) -> {Nat.is_le(a, Nat.add(b, 1n+c)) == True{} : Bool}:
  %add_succ(b, c) : {Nat.is_le(a, _) == True{} : Bool}
  h

# transport a bound along an equation on the summand
def le_cast(a: Nat, b: Nat, n: Nat, m: Nat, e: {n == m : Nat}, h: {Nat.is_le(a, Nat.add(b, n)) == True{} : Bool}) -> {Nat.is_le(a, Nat.add(b, m)) == True{} : Bool}:
  %e : {Nat.is_le(a, Nat.add(b, _)) == True{} : Bool}
  h

# ---------------------------------------------------------------------------
# Small corollaries on the finite types
# ---------------------------------------------------------------------------

# the PTN, once latched, stays (P1 + antisymmetry of lvl_le, by cases)
def ptn_stays.ptn(o: S.Ord, l2: S.Level, h: {Spec.lvl_le(o, S.LPtn{}, l2) == True{} : Bool}) -> {S.is_ptn(l2) == True{} : Bool}:
  match o l2:
    case S.Ord1{} S.LNone{}:
      clash_ft({S.is_ptn(S.LNone{}) == True{} : Bool}, h)
    case S.Ord1{} S.LJtt{}:
      clash_ft({S.is_ptn(S.LJtt{}) == True{} : Bool}, h)
    case S.Ord1{} S.LRtps{}:
      clash_ft({S.is_ptn(S.LRtps{}) == True{} : Bool}, h)
    case S.Ord1{} S.LPtn{}:
      {==}
    case S.Ord2{} S.LNone{}:
      clash_ft({S.is_ptn(S.LNone{}) == True{} : Bool}, h)
    case S.Ord2{} S.LJtt{}:
      clash_ft({S.is_ptn(S.LJtt{}) == True{} : Bool}, h)
    case S.Ord2{} S.LRtps{}:
      clash_ft({S.is_ptn(S.LRtps{}) == True{} : Bool}, h)
    case S.Ord2{} S.LPtn{}:
      {==}

def ptn_stays(o: S.Ord, l: S.Level, l2: S.Level, hl: {S.is_ptn(l) == True{} : Bool}, h: {Spec.lvl_le(o, l, l2) == True{} : Bool}) -> {S.is_ptn(l2) == True{} : Bool}:
  match l:
    case S.LNone{}:
      clash_ft({S.is_ptn(l2) == True{} : Bool}, hl)
    case S.LJtt{}:
      clash_ft({S.is_ptn(l2) == True{} : Bool}, hl)
    case S.LRtps{}:
      clash_ft({S.is_ptn(l2) == True{} : Bool}, hl)
    case S.LPtn{}:
      ptn_stays.ptn(o, l2, h)

# the DMS, once fired, stays (P15 by cases)
def fired_stays(d: S.Dms, +d2: S.Dms, hf: {Spec.is_fired(d) == True{} : Bool}, h: {Spec.dms_le(d, d2) == True{} : Bool}) -> {Spec.is_fired(d2) == True{} : Bool}:
  match d:
    case S.DmsIdle{}:
      clash_ft({Spec.is_fired(d2) == True{} : Bool}, hf)
    case S.DmsArmed{}:
      clash_ft({Spec.is_fired(d2) == True{} : Bool}, hf)
    case S.DmsFired{}:
      match d2:
        case S.DmsIdle{}:
          clash_ft({Spec.is_fired(S.DmsIdle{}) == True{} : Bool}, h)
        case S.DmsArmed{}:
          clash_ft({Spec.is_fired(S.DmsArmed{}) == True{} : Bool}, h)
        case S.DmsFired{}:
          {==}

# the DMS, once armed, is armed or fired afterwards (P15 by cases)
def armed_stays(d: S.Dms, +d2: S.Dms, ha: {S.is_armed(d) == True{} : Bool}, h: {Spec.dms_le(d, d2) == True{} : Bool}) -> {Bool.or(Spec.is_fired(d2), S.is_armed(d2)) == True{} : Bool}:
  match d:
    case S.DmsIdle{}:
      clash_ft({Bool.or(Spec.is_fired(d2), S.is_armed(d2)) == True{} : Bool}, ha)
    case S.DmsFired{}:
      clash_ft({Bool.or(Spec.is_fired(d2), S.is_armed(d2)) == True{} : Bool}, ha)
    case S.DmsArmed{}:
      match d2:
        case S.DmsIdle{}:
          clash_ft({Bool.or(Spec.is_fired(S.DmsIdle{}), S.is_armed(S.DmsIdle{})) == True{} : Bool}, h)
        case S.DmsArmed{}:
          {==}
        case S.DmsFired{}:
          {==}

def armed_not_idle(d: S.Dms, ha: {S.is_armed(d) == True{} : Bool}) -> {Bool.not(S.is_idle(d)) == True{} : Bool}:
  match d:
    case S.DmsIdle{}:
      clash_ft({Bool.not(S.is_idle(S.DmsIdle{})) == True{} : Bool}, ha)
    case S.DmsArmed{}:
      {==}
    case S.DmsFired{}:
      clash_ft({Bool.not(S.is_idle(S.DmsFired{})) == True{} : Bool}, ha)

# the acknowledgement of an armed DMS is a fired one
def ack_fired(d: S.Dms, ha: {S.is_armed(d) == True{} : Bool}) -> {Spec.is_fired(Spec.ack_exp(d)) == True{} : Bool}:
  match d:
    case S.DmsIdle{}:
      clash_ft({Spec.is_fired(Spec.ack_exp(S.DmsIdle{})) == True{} : Bool}, ha)
    case S.DmsArmed{}:
      {==}
    case S.DmsFired{}:
      clash_ft({Spec.is_fired(Spec.ack_exp(S.DmsFired{})) == True{} : Bool}, ha)

def fired_cast(a: S.Dms, b: S.Dms, e: {a == b : S.Dms}, h: {Spec.is_fired(b) == True{} : Bool}) -> {Spec.is_fired(a) == True{} : Bool}:
  %Equal.sym(S.Dms, a, b, e) : {Spec.is_fired(_) == True{} : Bool}
  h

# the counter commands, applied
def cinc_apply(u: S.Upd, n: Nat, h: {Spec.is_cinc(u) == True{} : Bool}) -> {1n+n == S.apply(u, n) : Nat}:
  match u:
    case S.CKeep{}:
      clash_ft({1n+n == S.apply(S.CKeep{}, n) : Nat}, h)
    case S.CReset{}:
      clash_ft({1n+n == S.apply(S.CReset{}, n) : Nat}, h)
    case S.CInc{}:
      {==}

def keep_apply(u: S.Upd, n: Nat, h: {S.is_keep(u) == True{} : Bool}) -> {n == S.apply(u, n) : Nat}:
  match u:
    case S.CKeep{}:
      {==}
    case S.CReset{}:
      clash_ft({n == S.apply(S.CReset{}, n) : Nat}, h)
    case S.CInc{}:
      clash_ft({n == S.apply(S.CInc{}, n) : Nat}, h)

# on a Tick below the limit with the PTN not latched, the watchdog counter increments
def hb_inc(f: S.Fin, d: Bool, hb: Nat, eb: {False{} == S.is_ptn(S.level_of(f)) : Bool}) -> {1n+hb == S.apply(S.upd_hb(f, S.Tick{d}, True{}), hb) : Nat}:
  %eb : {1n+hb == S.apply(S.inc_if(Bool.not(_)), hb) : Nat}
  {==}

# I4 out of the control invariant: a DMS not idle means the PTN is latched
def i4_of(f: S.Fin, h: {S.inv_fin(f) == True{} : Bool}) -> {S.implies(Bool.not(S.is_idle(S.dms_of(f))), S.is_ptn(S.level_of(f))) == True{} : Bool}:
  match f:
    case S.Fin{+p, +j, +l, +d, +pl, +ip, +nb, +rf}:
      +w = S.wave_go(j, p)
      and_r(S.implies(S.is_jtt(l), S.is_term(w)), S.implies(Bool.not(S.is_idle(d)), S.is_ptn(l)),
        and_r(Bool.and(S.ramp_ok(nb, w, pl, l), S.ramp_ok(rf, w, pl, l)),
              Bool.and(S.implies(S.is_jtt(l), S.is_term(w)), S.implies(Bool.not(S.is_idle(d)), S.is_ptn(l))),
          and_r(Bool.and(S.on_ok(nb, w, pl, l), S.on_ok(rf, w, pl, l)),
                Bool.and(Bool.and(S.ramp_ok(nb, w, pl, l), S.ramp_ok(rf, w, pl, l)),
                         Bool.and(S.implies(S.is_jtt(l), S.is_term(w)), S.implies(Bool.not(S.is_idle(d)), S.is_ptn(l)))),
            h)))

# ---------------------------------------------------------------------------
# The trace predicates, unpacked
# ---------------------------------------------------------------------------

def nohb_tail(e: S.Ev, t: List<&2, S.Ev>, h: {Laws.no_hb(Con{e, t}) == True{} : Bool}) -> {Laws.no_hb(t) == True{} : Bool}:
  match e:
    case S.Advance{}:
      h
    case S.Stop{req, dms}:
      h
    case S.Local{u}:
      h
    case S.HeatOn{u}:
      h
    case S.HeatOff{u}:
      h
    case S.Plasma{ok}:
      h
    case S.Ip{ok}:
      h
    case S.CommFault{dms, en}:
      h
    case S.Heartbeat{}:
      clash_ft({Laws.no_hb(t) == True{} : Bool}, h)
    case S.Tick{dms}:
      h
    case S.HeatAck{}:
      h
    case S.Reset{}:
      clash_ft({Laws.no_hb(t) == True{} : Bool}, h)

def nohb_not_reset(e: S.Ev, -t: List<&2, S.Ev>, h: {Laws.no_hb(Con{e, t}) == True{} : Bool}) -> {Bool.not(Spec.is_reset(e)) == True{} : Bool}:
  match e:
    case S.Advance{}:
      {==}
    case S.Stop{req, dms}:
      {==}
    case S.Local{u}:
      {==}
    case S.HeatOn{u}:
      {==}
    case S.HeatOff{u}:
      {==}
    case S.Plasma{ok}:
      {==}
    case S.Ip{ok}:
      {==}
    case S.CommFault{dms, en}:
      {==}
    case S.Heartbeat{}:
      {==}
    case S.Tick{dms}:
      {==}
    case S.HeatAck{}:
      {==}
    case S.Reset{}:
      clash_ft({Bool.not(Spec.is_reset(S.Reset{})) == True{} : Bool}, h)

def noreset_tail(e: S.Ev, t: List<&2, S.Ev>, h: {Laws.no_reset(Con{e, t}) == True{} : Bool}) -> {Laws.no_reset(t) == True{} : Bool}:
  match e:
    case S.Advance{}:
      h
    case S.Stop{req, dms}:
      h
    case S.Local{u}:
      h
    case S.HeatOn{u}:
      h
    case S.HeatOff{u}:
      h
    case S.Plasma{ok}:
      h
    case S.Ip{ok}:
      h
    case S.CommFault{dms, en}:
      h
    case S.Heartbeat{}:
      h
    case S.Tick{dms}:
      h
    case S.HeatAck{}:
      h
    case S.Reset{}:
      clash_ft({Laws.no_reset(t) == True{} : Bool}, h)

def noreset_not_reset(e: S.Ev, -t: List<&2, S.Ev>, h: {Laws.no_reset(Con{e, t}) == True{} : Bool}) -> {Bool.not(Spec.is_reset(e)) == True{} : Bool}:
  match e:
    case S.Advance{}:
      {==}
    case S.Stop{req, dms}:
      {==}
    case S.Local{u}:
      {==}
    case S.HeatOn{u}:
      {==}
    case S.HeatOff{u}:
      {==}
    case S.Plasma{ok}:
      {==}
    case S.Ip{ok}:
      {==}
    case S.CommFault{dms, en}:
      {==}
    case S.Heartbeat{}:
      {==}
    case S.Tick{dms}:
      {==}
    case S.HeatAck{}:
      {==}
    case S.Reset{}:
      clash_ft({Bool.not(Spec.is_reset(S.Reset{})) == True{} : Bool}, h)

# ---------------------------------------------------------------------------
# L1 watchdog_responds
# ---------------------------------------------------------------------------

# the claim: the PTN is latched, or the ticks still to come reach the limit
def W(trace: List<&2, S.Ev>, +s: S.St) -> Bool:
  Bool.or(S.is_ptn(S.level_of(S.fin_of(s))), Nat.is_le(S.hb_max(), Nat.add(Laws.ticks(trace), S.hb_of(s))))

def w_l(-t: List<&2, S.Ev>, +s2: S.St, h: {S.is_ptn(S.level_of(S.fin_of(s2))) == True{} : Bool}) -> {W(t, s2) == True{} : Bool}:
  or_l(S.is_ptn(S.level_of(S.fin_of(s2))), Nat.is_le(S.hb_max(), Nat.add(Laws.ticks(t), S.hb_of(s2))), h)

def w_r(t: List<&2, S.Ev>, +s2: S.St, h: {Nat.is_le(S.hb_max(), Nat.add(Laws.ticks(t), S.hb_of(s2))) == True{} : Bool}) -> {W(t, s2) == True{} : Bool}:
  or_r(S.is_ptn(S.level_of(S.fin_of(s2))), Nat.is_le(S.hb_max(), Nat.add(Laws.ticks(t), S.hb_of(s2))), h)

# Nil: I6 refutes the count (no ticks left, counter below the limit) unless the PTN is latched
def nil_or(b: Bool, n: Nat, lim: Nat, i6: {S.cnt_go(Bool.not(b), n, lim) == True{} : Bool}, hc: {Bool.or(b, Nat.is_le(lim, n)) == True{} : Bool}) -> {b == True{} : Bool}:
  match b:
    case True{}:
      {==}
    case False{}:
      Empty.absurd({False{} == True{} : Bool}, lt_le_absurd(n, lim, i6, hc))

def w_nil(s: S.St, h_inv: {S.inv_all(s) == True{} : Bool}, hc: {W(Nil{}, s) == True{} : Bool}) -> {S.is_ptn(S.level_of(S.fin_of(s))) == True{} : Bool}:
  match s:
    case S.St{+f, +hb, +tack}:
      nil_or(S.is_ptn(S.level_of(f)), hb, S.hb_max(),
        and_r(S.i5_ack(S.St{f, hb, tack}), S.i6_hb(S.St{f, hb, tack}),
          and_r(S.inv_fin(f), Bool.and(S.i5_ack(S.St{f, hb, tack}), S.i6_hb(S.St{f, hb, tack})), h_inv)),
        hc)

# an event that keeps the watchdog counter and is not a Tick
def w_other(+o: S.Ord, +f: S.Fin, +hb: Nat, +tack: Nat, +e: S.Ev, +t: List<&2, S.Ev>, +bt: Bool, +bh: Bool,
  hr: {Nat.is_le(S.hb_max(), Nat.add(Laws.ticks(t), hb)) == True{} : Bool},
  hk: {hb == S.apply(S.upd_hb(f, e, bh), hb) : Nat})
  -> {W(t, S.step_at(o, f, e, bt, bh, hb, tack)) == True{} : Bool}:
  w_r(t, S.step_at(o, f, e, bt, bh, hb, tack),
    le_cast(S.hb_max(), Laws.ticks(t), hb, S.apply(S.upd_hb(f, e, bh), hb), hk, hr))

# a Tick with the PTN not latched: the watchdog either fires now (D4) or counts (computation)
law w_tick:
  for ~fd4: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d4(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for +o: S.Ord
  for +f: S.Fin
  for +hb: Nat
  for +tack: Nat
  for +d: Bool
  for +t: List<&2, S.Ev>
  for +bt: Bool
  for bh: Bool
  for +eb: {False{} == S.is_ptn(S.level_of(f)) : Bool}
  for hr: {Nat.is_le(S.hb_max(), 1n+Nat.add(Laws.ticks(t), hb)) == True{} : Bool}
  {W(t, S.step_at(o, f, S.Tick{d}, bt, bh, hb, tack)) == True{} : Bool}

def w_tick(fd4, o, f, hb, tack, d, t, bt, bh, eb, hr):
  match bh:
    case False{}:
      w_l(t, S.step_at(o, f, S.Tick{d}, bt, False{}, hb, tack),
        implies_e(Bool.not(S.is_ptn(S.level_of(f))), S.is_ptn(S.level_of(S.step_fin(o, f, S.Tick{d}, bt, False{}))),
          fd4(o, f, S.Tick{d}, bt, False{}), not_of(S.is_ptn(S.level_of(f)), eb)))
    case True{}:
      w_r(t, S.step_at(o, f, S.Tick{d}, bt, True{}, hb, tack),
        le_cast(S.hb_max(), Laws.ticks(t), 1n+hb, S.apply(S.upd_hb(f, S.Tick{d}, True{}), hb),
          hb_inc(f, d, hb, eb), le_shift(S.hb_max(), Laws.ticks(t), hb, hr)))

# the PTN not latched: by event
law w_ev:
  for ~fd4: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d4(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for +o: S.Ord
  for +f: S.Fin
  for +hb: Nat
  for +tack: Nat
  for e: S.Ev
  for +t: List<&2, S.Ev>
  for +bt: Bool
  for +bh: Bool
  for h_nohb: {Laws.no_hb(Con{e, t}) == True{} : Bool}
  for eb: {False{} == S.is_ptn(S.level_of(f)) : Bool}
  for hr: {Nat.is_le(S.hb_max(), Nat.add(Laws.ticks(Con{e, t}), hb)) == True{} : Bool}
  {W(t, S.step_at(o, f, e, bt, bh, hb, tack)) == True{} : Bool}

def w_ev(fd4, o, f, hb, tack, e, t, bt, bh, h_nohb, eb, hr):
  match e:
    case S.Advance{}:
      w_other(o, f, hb, tack, S.Advance{}, t, bt, bh, hr, {==})
    case S.Stop{req, dms}:
      w_other(o, f, hb, tack, S.Stop{req, dms}, t, bt, bh, hr, {==})
    case S.Local{u}:
      w_other(o, f, hb, tack, S.Local{u}, t, bt, bh, hr, {==})
    case S.HeatOn{u}:
      w_other(o, f, hb, tack, S.HeatOn{u}, t, bt, bh, hr, {==})
    case S.HeatOff{u}:
      w_other(o, f, hb, tack, S.HeatOff{u}, t, bt, bh, hr, {==})
    case S.Plasma{ok}:
      w_other(o, f, hb, tack, S.Plasma{ok}, t, bt, bh, hr, {==})
    case S.Ip{ok}:
      w_other(o, f, hb, tack, S.Ip{ok}, t, bt, bh, hr, {==})
    case S.CommFault{dms, en}:
      w_other(o, f, hb, tack, S.CommFault{dms, en}, t, bt, bh, hr, {==})
    case S.Heartbeat{}:
      clash_ft({W(t, S.step_at(o, f, S.Heartbeat{}, bt, bh, hb, tack)) == True{} : Bool}, h_nohb)
    case S.Tick{dms}:
      w_tick(~fd4, o, f, hb, tack, dms, t, bt, bh, eb, hr)
    case S.HeatAck{}:
      w_other(o, f, hb, tack, S.HeatAck{}, t, bt, bh, hr, {==})
    case S.Reset{}:
      clash_ft({W(t, S.step_at(o, f, S.Reset{}, bt, bh, hb, tack)) == True{} : Bool}, h_nohb)

# split on whether the PTN is already latched
law w_go:
  for ~fd4: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d4(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fp1: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p1(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for +o: S.Ord
  for +f: S.Fin
  for +hb: Nat
  for +tack: Nat
  for +e: S.Ev
  for +t: List<&2, S.Ev>
  for +bt: Bool
  for +bh: Bool
  for h_nohb: {Laws.no_hb(Con{e, t}) == True{} : Bool}
  for hc: {W(Con{e, t}, S.St{f, hb, tack}) == True{} : Bool}
  for b: Bool
  for +eb: {b == S.is_ptn(S.level_of(f)) : Bool}
  {W(t, S.step_at(o, f, e, bt, bh, hb, tack)) == True{} : Bool}

def w_go(fd4, fp1, o, f, hb, tack, e, t, bt, bh, h_nohb, hc, b, eb):
  match b:
    case True{}:
      w_l(t, S.step_at(o, f, e, bt, bh, hb, tack),
        ptn_stays(o, S.level_of(f), S.level_of(S.step_fin(o, f, e, bt, bh)),
          Equal.sym(Bool, True{}, S.is_ptn(S.level_of(f)), eb),
          implies_e(Bool.not(Spec.is_reset(e)), Spec.lvl_le(o, S.level_of(f), S.level_of(S.step_fin(o, f, e, bt, bh))),
            fp1(o, f, e, bt, bh), nohb_not_reset(e, t, h_nohb))))
    case False{}:
      w_ev(~fd4, o, f, hb, tack, e, t, bt, bh, h_nohb, eb,
        or_false_l(S.is_ptn(S.level_of(f)), Nat.is_le(S.hb_max(), Nat.add(Laws.ticks(Con{e, t}), hb)), eb, hc))

# one step re-establishes the claim
law w_step:
  for ~fd4: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d4(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fp1: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p1(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for +o: S.Ord
  for s: S.St
  for +e: S.Ev
  for +t: List<&2, S.Ev>
  for h_nohb: {Laws.no_hb(Con{e, t}) == True{} : Bool}
  for hc: {W(Con{e, t}, s) == True{} : Bool}
  {W(t, S.step_o(o, s, e)) == True{} : Bool}

def w_step(fd4, fp1, o, s, e, t, h_nohb, hc):
  match s:
    case S.St{+f, +hb, +tack}:
      w_go(~fd4, ~fp1, o, f, hb, tack, e, t, Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()), h_nohb, hc, S.is_ptn(S.level_of(f)), {==})

# induction on the trace
law run_w:
  for ~fss: @+o: S.Ord -> @+s: S.St -> @+h: {S.inv_all(s) == True{} : Bool} -> @+e: S.Ev -> {S.inv_all(S.step_o(o, s, e)) == True{} : Bool}
  for ~fd4: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d4(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fp1: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p1(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for trace: List<&2, S.Ev>
  for +o: S.Ord
  for +s: S.St
  for +h_inv: {S.inv_all(s) == True{} : Bool}
  for +h_nohb: {Laws.no_hb(trace) == True{} : Bool}
  for +hc: {W(trace, s) == True{} : Bool}
  {S.is_ptn(S.level_of(S.fin_of(S.run_o(o, trace, s)))) == True{} : Bool}

def run_w(fss, fd4, fp1, trace, o, s, h_inv, h_nohb, hc):
  match trace:
    case Nil{}:
      w_nil(s, h_inv, hc)
    case Con{+e, +t}:
      run_w(~fss, ~fd4, ~fp1, t, o, S.step_o(o, s, e), fss(o, s, h_inv, e), nohb_tail(e, t, h_nohb), w_step(~fd4, ~fp1, o, s, e, t, h_nohb, hc))

# L1 from the facts (closed here; PROOF_JETPROT_LIVE.bend instantiates it)
law watchdog_from:
  for ~fss: @+o: S.Ord -> @+s: S.St -> @+h: {S.inv_all(s) == True{} : Bool} -> @+e: S.Ev -> {S.inv_all(S.step_o(o, s, e)) == True{} : Bool}
  for ~fd4: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d4(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fp1: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p1(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for +o: S.Ord
  for +s: S.St
  for +h_inv: {S.inv_all(s) == True{} : Bool}
  for +trace: List<&2, S.Ev>
  for +h_nohb: {Laws.no_hb(trace) == True{} : Bool}
  for +h_len: {Nat.is_le(S.hb_max(), Laws.ticks(trace)) == True{} : Bool}
  {S.is_ptn(S.level_of(S.fin_of(S.run_o(o, trace, s)))) == True{} : Bool}

def watchdog_from(fss, fd4, fp1, o, s, h_inv, trace, h_nohb, h_len):
  run_w(~fss, ~fd4, ~fp1, trace, o, s, h_inv, h_nohb, w_r(trace, s, le_add_r(S.hb_max(), Laws.ticks(trace), S.hb_of(s), h_len)))

# ---------------------------------------------------------------------------
# L2 dms_responds
# ---------------------------------------------------------------------------

# the claim: the DMS has fired, or it is armed and the ticks still to come reach the limit
def D(trace: List<&2, S.Ev>, +s: S.St) -> Bool:
  Bool.or(Spec.is_fired(S.dms_of(S.fin_of(s))),
          Bool.and(S.is_armed(S.dms_of(S.fin_of(s))), Nat.is_le(S.ack_max(), Nat.add(Laws.ticks(trace), S.tack_of(s)))))

def d_l(-t: List<&2, S.Ev>, +s2: S.St, h: {Spec.is_fired(S.dms_of(S.fin_of(s2))) == True{} : Bool}) -> {D(t, s2) == True{} : Bool}:
  or_l(Spec.is_fired(S.dms_of(S.fin_of(s2))), Bool.and(S.is_armed(S.dms_of(S.fin_of(s2))), Nat.is_le(S.ack_max(), Nat.add(Laws.ticks(t), S.tack_of(s2)))), h)

def d_r(t: List<&2, S.Ev>, +s2: S.St,
  hof: {Bool.or(Spec.is_fired(S.dms_of(S.fin_of(s2))), S.is_armed(S.dms_of(S.fin_of(s2)))) == True{} : Bool},
  hle: {Nat.is_le(S.ack_max(), Nat.add(Laws.ticks(t), S.tack_of(s2))) == True{} : Bool})
  -> {D(t, s2) == True{} : Bool}:
  or_and(Spec.is_fired(S.dms_of(S.fin_of(s2))), S.is_armed(S.dms_of(S.fin_of(s2))), Nat.is_le(S.ack_max(), Nat.add(Laws.ticks(t), S.tack_of(s2))), hof, hle)

# Nil: I5 refutes the count while armed; fired closes directly
def nil_or2(b: Bool, a: Bool, n: Nat, lim: Nat, i5: {S.cnt_go(a, n, lim) == True{} : Bool}, hc: {Bool.or(b, Bool.and(a, Nat.is_le(lim, n))) == True{} : Bool}) -> {b == True{} : Bool}:
  match b:
    case True{}:
      {==}
    case False{}:
      match a:
        case True{}:
          Empty.absurd({False{} == True{} : Bool}, lt_le_absurd(n, lim, i5, hc))
        case False{}:
          clash_ft({False{} == True{} : Bool}, hc)

def d_nil(s: S.St, h_inv: {S.inv_all(s) == True{} : Bool}, hc: {D(Nil{}, s) == True{} : Bool}) -> {Spec.is_fired(S.dms_of(S.fin_of(s))) == True{} : Bool}:
  match s:
    case S.St{+f, +hb, +tack}:
      nil_or2(Spec.is_fired(S.dms_of(f)), S.is_armed(S.dms_of(f)), tack, S.ack_max(),
        and_l(S.i5_ack(S.St{f, hb, tack}), S.i6_hb(S.St{f, hb, tack}),
          and_r(S.inv_fin(f), Bool.and(S.i5_ack(S.St{f, hb, tack}), S.i6_hb(S.St{f, hb, tack})), h_inv)),
        hc)

# an event that is neither Tick nor Reset while armed: the wait is kept (P18), the DMS stays armed or fired (P15)
def d_other(+o: S.Ord, +f: S.Fin, +hb: Nat, +tack: Nat, +e: S.Ev, +t: List<&2, S.Ev>, +bt: Bool, +bh: Bool,
  +harmed: {S.is_armed(S.dms_of(f)) == True{} : Bool},
  hle: {Nat.is_le(S.ack_max(), Nat.add(Laws.ticks(t), tack)) == True{} : Bool},
  hnt: {Bool.not(Spec.is_tick(e)) == True{} : Bool},
  +hnr: {Bool.not(Spec.is_reset(e)) == True{} : Bool},
  hp18: {Spec.pr_p18(f, e, bt, bh) == True{} : Bool},
  hp15: {Spec.pr_p15(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool})
  -> {D(t, S.step_at(o, f, e, bt, bh, hb, tack)) == True{} : Bool}:
  d_r(t, S.step_at(o, f, e, bt, bh, hb, tack),
    armed_stays(S.dms_of(f), S.dms_of(S.step_fin(o, f, e, bt, bh)), harmed,
      implies_e(Bool.not(Spec.is_reset(e)), Spec.dms_le(S.dms_of(f), S.dms_of(S.step_fin(o, f, e, bt, bh))), hp15, hnr)),
    le_cast(S.ack_max(), Laws.ticks(t), tack, S.apply(S.upd_tack(f, e, bt, bh), tack),
      keep_apply(S.upd_tack(f, e, bt, bh), tack,
        implies_e(Bool.and(S.is_armed(S.dms_of(f)), Bool.and(Bool.not(Spec.is_tick(e)), Bool.not(Spec.is_reset(e)))), S.is_keep(S.upd_tack(f, e, bt, bh)), hp18,
          and_intro(S.is_armed(S.dms_of(f)), Bool.and(Bool.not(Spec.is_tick(e)), Bool.not(Spec.is_reset(e))), harmed,
            and_intro(Bool.not(Spec.is_tick(e)), Bool.not(Spec.is_reset(e)), hnt, hnr)))),
      hle))

# a Tick while armed (hence under PTN by I4): the timeout fires (D7) or the wait counts (D8)
law d_tick:
  for ~fd7: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d7(f, e, bt, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fd8: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d8(f, e, bt, bh) == True{} : Bool}
  for ~fp15: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p15(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for +o: S.Ord
  for +f: S.Fin
  for +hb: Nat
  for +tack: Nat
  for +d: Bool
  for +t: List<&2, S.Ev>
  for bt: Bool
  for +bh: Bool
  for +harmed: {S.is_armed(S.dms_of(f)) == True{} : Bool}
  for +hptn: {S.is_ptn(S.level_of(f)) == True{} : Bool}
  for hle: {Nat.is_le(S.ack_max(), 1n+Nat.add(Laws.ticks(t), tack)) == True{} : Bool}
  {D(t, S.step_at(o, f, S.Tick{d}, bt, bh, hb, tack)) == True{} : Bool}

def d_tick(fd7, fd8, fp15, o, f, hb, tack, d, t, bt, bh, harmed, hptn, hle):
  match bt:
    case False{}:
      d_l(t, S.step_at(o, f, S.Tick{d}, False{}, bh, hb, tack),
        implies_e(Bool.and(S.is_armed(S.dms_of(f)), Bool.and(S.is_ptn(S.level_of(f)), True{})), Spec.is_fired(S.dms_of(S.step_fin(o, f, S.Tick{d}, False{}, bh))),
          fd7(o, f, S.Tick{d}, False{}, bh),
          and_intro(S.is_armed(S.dms_of(f)), Bool.and(S.is_ptn(S.level_of(f)), True{}), harmed, and_intro(S.is_ptn(S.level_of(f)), True{}, hptn, {==}))))
    case True{}:
      d_r(t, S.step_at(o, f, S.Tick{d}, True{}, bh, hb, tack),
        armed_stays(S.dms_of(f), S.dms_of(S.step_fin(o, f, S.Tick{d}, True{}, bh)), harmed, fp15(o, f, S.Tick{d}, True{}, bh)),
        le_cast(S.ack_max(), Laws.ticks(t), 1n+tack, S.apply(S.upd_tack(f, S.Tick{d}, True{}, bh), tack),
          cinc_apply(S.upd_tack(f, S.Tick{d}, True{}, bh), tack,
            implies_e(Bool.and(S.is_armed(S.dms_of(f)), Bool.and(S.is_ptn(S.level_of(f)), True{})), Spec.is_cinc(S.upd_tack(f, S.Tick{d}, True{}, bh)),
              fd8(o, f, S.Tick{d}, True{}, bh),
              and_intro(S.is_armed(S.dms_of(f)), Bool.and(S.is_ptn(S.level_of(f)), True{}), harmed, and_intro(S.is_ptn(S.level_of(f)), True{}, hptn, {==})))),
          le_shift(S.ack_max(), Laws.ticks(t), tack, hle)))

# armed and not fired: by event
law d_ev:
  for ~fd7: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d7(f, e, bt, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fd8: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d8(f, e, bt, bh) == True{} : Bool}
  for ~fp15: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p15(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fp18: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p18(f, e, bt, bh) == True{} : Bool}
  for ~fe11: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_e11(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for +o: S.Ord
  for +f: S.Fin
  for +hb: Nat
  for +tack: Nat
  for e: S.Ev
  for +t: List<&2, S.Ev>
  for +bt: Bool
  for +bh: Bool
  for h_noreset: {Laws.no_reset(Con{e, t}) == True{} : Bool}
  for +harmed: {S.is_armed(S.dms_of(f)) == True{} : Bool}
  for hptn: {S.is_ptn(S.level_of(f)) == True{} : Bool}
  for hle: {Nat.is_le(S.ack_max(), Nat.add(Laws.ticks(Con{e, t}), tack)) == True{} : Bool}
  {D(t, S.step_at(o, f, e, bt, bh, hb, tack)) == True{} : Bool}

def d_ev(fd7, fd8, fp15, fp18, fe11, o, f, hb, tack, e, t, bt, bh, h_noreset, harmed, hptn, hle):
  match e:
    case S.Advance{}:
      d_other(o, f, hb, tack, S.Advance{}, t, bt, bh, harmed, hle, {==}, {==}, fp18(o, f, S.Advance{}, bt, bh), fp15(o, f, S.Advance{}, bt, bh))
    case S.Stop{+req, +dms}:
      d_other(o, f, hb, tack, S.Stop{req, dms}, t, bt, bh, harmed, hle, {==}, {==}, fp18(o, f, S.Stop{req, dms}, bt, bh), fp15(o, f, S.Stop{req, dms}, bt, bh))
    case S.Local{+u}:
      d_other(o, f, hb, tack, S.Local{u}, t, bt, bh, harmed, hle, {==}, {==}, fp18(o, f, S.Local{u}, bt, bh), fp15(o, f, S.Local{u}, bt, bh))
    case S.HeatOn{+u}:
      d_other(o, f, hb, tack, S.HeatOn{u}, t, bt, bh, harmed, hle, {==}, {==}, fp18(o, f, S.HeatOn{u}, bt, bh), fp15(o, f, S.HeatOn{u}, bt, bh))
    case S.HeatOff{+u}:
      d_other(o, f, hb, tack, S.HeatOff{u}, t, bt, bh, harmed, hle, {==}, {==}, fp18(o, f, S.HeatOff{u}, bt, bh), fp15(o, f, S.HeatOff{u}, bt, bh))
    case S.Plasma{+ok}:
      d_other(o, f, hb, tack, S.Plasma{ok}, t, bt, bh, harmed, hle, {==}, {==}, fp18(o, f, S.Plasma{ok}, bt, bh), fp15(o, f, S.Plasma{ok}, bt, bh))
    case S.Ip{+ok}:
      d_other(o, f, hb, tack, S.Ip{ok}, t, bt, bh, harmed, hle, {==}, {==}, fp18(o, f, S.Ip{ok}, bt, bh), fp15(o, f, S.Ip{ok}, bt, bh))
    case S.CommFault{+dms, +en}:
      d_other(o, f, hb, tack, S.CommFault{dms, en}, t, bt, bh, harmed, hle, {==}, {==}, fp18(o, f, S.CommFault{dms, en}, bt, bh), fp15(o, f, S.CommFault{dms, en}, bt, bh))
    case S.Heartbeat{}:
      d_other(o, f, hb, tack, S.Heartbeat{}, t, bt, bh, harmed, hle, {==}, {==}, fp18(o, f, S.Heartbeat{}, bt, bh), fp15(o, f, S.Heartbeat{}, bt, bh))
    case S.Tick{dms}:
      d_tick(~fd7, ~fd8, ~fp15, o, f, hb, tack, dms, t, bt, bh, harmed, hptn, hle)
    case S.HeatAck{}:
      d_l(t, S.step_at(o, f, S.HeatAck{}, bt, bh, hb, tack),
        fired_cast(S.dms_of(S.step_fin(o, f, S.HeatAck{}, bt, bh)), Spec.ack_exp(S.dms_of(f)),
          LS.dms_eq_sound(S.dms_of(S.step_fin(o, f, S.HeatAck{}, bt, bh)), Spec.ack_exp(S.dms_of(f)), fe11(o, f, S.HeatAck{}, bt, bh)),
          ack_fired(S.dms_of(f), harmed)))
    case S.Reset{}:
      clash_ft({D(t, S.step_at(o, f, S.Reset{}, bt, bh, hb, tack)) == True{} : Bool}, h_noreset)

# split on whether the DMS has already fired
law d_go:
  for ~fd7: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d7(f, e, bt, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fd8: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d8(f, e, bt, bh) == True{} : Bool}
  for ~fp15: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p15(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fp18: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p18(f, e, bt, bh) == True{} : Bool}
  for ~fe11: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_e11(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for +o: S.Ord
  for +f: S.Fin
  for +hb: Nat
  for +tack: Nat
  for +e: S.Ev
  for +t: List<&2, S.Ev>
  for +bt: Bool
  for +bh: Bool
  for hi4: {S.implies(Bool.not(S.is_idle(S.dms_of(f))), S.is_ptn(S.level_of(f))) == True{} : Bool}
  for h_noreset: {Laws.no_reset(Con{e, t}) == True{} : Bool}
  for hc: {D(Con{e, t}, S.St{f, hb, tack}) == True{} : Bool}
  for b: Bool
  for eb: {b == Spec.is_fired(S.dms_of(f)) : Bool}
  {D(t, S.step_at(o, f, e, bt, bh, hb, tack)) == True{} : Bool}

def d_go(fd7, fd8, fp15, fp18, fe11, o, f, hb, tack, e, t, bt, bh, hi4, h_noreset, hc, b, eb):
  match b:
    case True{}:
      d_l(t, S.step_at(o, f, e, bt, bh, hb, tack),
        fired_stays(S.dms_of(f), S.dms_of(S.step_fin(o, f, e, bt, bh)),
          Equal.sym(Bool, True{}, Spec.is_fired(S.dms_of(f)), eb),
          implies_e(Bool.not(Spec.is_reset(e)), Spec.dms_le(S.dms_of(f), S.dms_of(S.step_fin(o, f, e, bt, bh))),
            fp15(o, f, e, bt, bh), noreset_not_reset(e, t, h_noreset))))
    case False{}:
      +ha = or_false_l(Spec.is_fired(S.dms_of(f)), Bool.and(S.is_armed(S.dms_of(f)), Nat.is_le(S.ack_max(), Nat.add(Laws.ticks(Con{e, t}), tack))), eb, hc)
      +harmed = and_l(S.is_armed(S.dms_of(f)), Nat.is_le(S.ack_max(), Nat.add(Laws.ticks(Con{e, t}), tack)), ha)
      d_ev(~fd7, ~fd8, ~fp15, ~fp18, ~fe11, o, f, hb, tack, e, t, bt, bh, h_noreset, harmed,
        implies_e(Bool.not(S.is_idle(S.dms_of(f))), S.is_ptn(S.level_of(f)), hi4, armed_not_idle(S.dms_of(f), harmed)),
        and_r(S.is_armed(S.dms_of(f)), Nat.is_le(S.ack_max(), Nat.add(Laws.ticks(Con{e, t}), tack)), ha))

# one step re-establishes the claim
law d_step:
  for ~fd7: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d7(f, e, bt, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fd8: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d8(f, e, bt, bh) == True{} : Bool}
  for ~fp15: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p15(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fp18: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p18(f, e, bt, bh) == True{} : Bool}
  for ~fe11: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_e11(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for +o: S.Ord
  for s: S.St
  for +e: S.Ev
  for +t: List<&2, S.Ev>
  for h_inv: {S.inv_all(s) == True{} : Bool}
  for h_noreset: {Laws.no_reset(Con{e, t}) == True{} : Bool}
  for hc: {D(Con{e, t}, s) == True{} : Bool}
  {D(t, S.step_o(o, s, e)) == True{} : Bool}

def d_step(fd7, fd8, fp15, fp18, fe11, o, s, e, t, h_inv, h_noreset, hc):
  match s:
    case S.St{+f, +hb, +tack}:
      d_go(~fd7, ~fd8, ~fp15, ~fp18, ~fe11, o, f, hb, tack, e, t, Nat.is_lt(1n+tack, S.ack_max()), Nat.is_lt(1n+hb, S.hb_max()),
        i4_of(f, and_l(S.inv_fin(f), Bool.and(S.i5_ack(S.St{f, hb, tack}), S.i6_hb(S.St{f, hb, tack})), h_inv)),
        h_noreset, hc, Spec.is_fired(S.dms_of(f)), {==})

# induction on the trace
law run_d:
  for ~fss: @+o: S.Ord -> @+s: S.St -> @+h: {S.inv_all(s) == True{} : Bool} -> @+e: S.Ev -> {S.inv_all(S.step_o(o, s, e)) == True{} : Bool}
  for ~fd7: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d7(f, e, bt, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fd8: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d8(f, e, bt, bh) == True{} : Bool}
  for ~fp15: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p15(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fp18: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p18(f, e, bt, bh) == True{} : Bool}
  for ~fe11: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_e11(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for trace: List<&2, S.Ev>
  for +o: S.Ord
  for +s: S.St
  for +h_inv: {S.inv_all(s) == True{} : Bool}
  for +h_noreset: {Laws.no_reset(trace) == True{} : Bool}
  for +hc: {D(trace, s) == True{} : Bool}
  {Spec.is_fired(S.dms_of(S.fin_of(S.run_o(o, trace, s)))) == True{} : Bool}

def run_d(fss, fd7, fd8, fp15, fp18, fe11, trace, o, s, h_inv, h_noreset, hc):
  match trace:
    case Nil{}:
      d_nil(s, h_inv, hc)
    case Con{+e, +t}:
      run_d(~fss, ~fd7, ~fd8, ~fp15, ~fp18, ~fe11, t, o, S.step_o(o, s, e), fss(o, s, h_inv, e), noreset_tail(e, t, h_noreset),
        d_step(~fd7, ~fd8, ~fp15, ~fp18, ~fe11, o, s, e, t, h_inv, h_noreset, hc))

# L2 from the facts (closed here; PROOF_JETPROT_LIVE.bend instantiates it)
law dms_from:
  for ~fss: @+o: S.Ord -> @+s: S.St -> @+h: {S.inv_all(s) == True{} : Bool} -> @+e: S.Ev -> {S.inv_all(S.step_o(o, s, e)) == True{} : Bool}
  for ~fd7: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d7(f, e, bt, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fd8: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_d8(f, e, bt, bh) == True{} : Bool}
  for ~fp15: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p15(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for ~fp18: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_p18(f, e, bt, bh) == True{} : Bool}
  for ~fe11: @+o: S.Ord -> @+f: S.Fin -> @+e: S.Ev -> @+bt: Bool -> @+bh: Bool -> {Spec.pr_e11(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}
  for +o: S.Ord
  for +s: S.St
  for +h_inv: {S.inv_all(s) == True{} : Bool}
  for +h_armed: {S.is_armed(S.dms_of(S.fin_of(s))) == True{} : Bool}
  for +trace: List<&2, S.Ev>
  for +h_noreset: {Laws.no_reset(trace) == True{} : Bool}
  for +h_len: {Nat.is_le(S.ack_max(), Laws.ticks(trace)) == True{} : Bool}
  {Spec.is_fired(S.dms_of(S.fin_of(S.run_o(o, trace, s)))) == True{} : Bool}

def dms_from(fss, fd7, fd8, fp15, fp18, fe11, o, s, h_inv, h_armed, trace, h_noreset, h_len):
  run_d(~fss, ~fd7, ~fd8, ~fp15, ~fp18, ~fe11, trace, o, s, h_inv, h_noreset,
    d_r(trace, s, or_r(Spec.is_fired(S.dms_of(S.fin_of(s))), S.is_armed(S.dms_of(S.fin_of(s))), h_armed),
      le_add_r(S.ack_max(), Laws.ticks(trace), S.tack_of(s), h_len)))

# Laws.watchdog_responds and Laws.dms_responds stay open here (2 TODOs): they are filled in
# PROOF_JETPROT_LIVE.bend by watchdog_from / dms_from at the laws of LAWS_JETPROT.bend.
