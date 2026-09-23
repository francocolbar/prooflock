# LAWS_JETPROT_SOUND.bend - soundness of the Bool equality predicates of spec_jetprot.bend
# (docs/STATUS_2026-09-21.md, blocker 1). Every frame law of LAWS_JETPROT.bend concludes
# `Spec.fin_eq(f, f2) == True{}`, `Spec.unit_eq(u, u2) == True{}` or `Spec.lvl_eq(l, l2) == True{}`:
# a Bool decided by comparing ranks. Until now nothing tied that Bool to the propositional
# equality, so a predicate that confused two constructors (Reduced with On, say) would have
# made those laws vacuous without Bend noticing. These laws are the bridge: each says that the
# predicate answering True{} forces the two values to be the same term. Proven in
# PROOF_JETPROT_SOUND.bend by exhaustive case split, no induction. `lvl_le_sound` is the
# antisymmetry of the rank order under BOTH urgency orders (what makes P1, stated with
# `lvl_le`, a statement about levels rather than about the predicate); `lvl_le_refl` its
# reflexivity.

import Base
import ./jetprot.bend as S
import ./spec_jetprot.bend as Spec

# beq is Bool equality
law beq_sound:
  for a: Bool
  for b: Bool
  for h: {Spec.beq(a, b) == True{} : Bool}
  {a == b : Bool}

# unit_eq is equality on Heat (4 constructors, by unit_rank)
law unit_eq_sound:
  for a: S.Heat
  for b: S.Heat
  for h: {Spec.unit_eq(a, b) == True{} : Bool}
  {a == b : S.Heat}

# dms_eq is equality on Dms (3 constructors, by dms_rank)
law dms_eq_sound:
  for a: S.Dms
  for b: S.Dms
  for h: {Spec.dms_eq(a, b) == True{} : Bool}
  {a == b : S.Dms}

# lvl_eq is equality on Level (4 constructors, by lvl_rank under Ord1)
law lvl_eq_sound:
  for a: S.Level
  for b: S.Level
  for h: {Spec.lvl_eq(a, b) == True{} : Bool}
  {a == b : S.Level}

# phase_eq is equality on Phase (7 constructors, by phase_rank)
law phase_eq_sound:
  for a: S.Phase
  for b: S.Phase
  for h: {Spec.phase_eq(a, b) == True{} : Bool}
  {a == b : S.Phase}

# lvl_le is reflexive under both urgency orders
law lvl_le_refl:
  for o: S.Ord
  for a: S.Level
  {Spec.lvl_le(o, a, a) == True{} : Bool}

# lvl_le is antisymmetric under both urgency orders: two levels below each other are the same
law lvl_le_sound:
  for o: S.Ord
  for a: S.Level
  for b: S.Level
  for h1: {Spec.lvl_le(o, a, b) == True{} : Bool}
  for h2: {Spec.lvl_le(o, b, a) == True{} : Bool}
  {a == b : S.Level}

# fin_eq is equality on the control state (the conjunction of the five above, field by field)
law fin_eq_sound:
  for a: S.Fin
  for b: S.Fin
  for +h: {Spec.fin_eq(a, b) == True{} : Bool}
  {a == b : S.Fin}
