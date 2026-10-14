# Phase 3 M4.2 — Casting Disruption and Focus Ward / Engineering Note

Status: IMPLEMENTED_AWAITING_ACTUAL_CI. No CI success claims before raw Godot logs.

## Authority and prior gate
Library 05, 19 M-D22–24, 20 PRE3-R12–14, 21 and 23. Tested predecessor master 145dc24d2281f43a043f8a0dbb0fe9c8a7992e74; official Godot 4.7.2 M4.1 CI #38654241159 successful 645/645 named Domain cases. Only M4.2 in scope. Initial test plus max 2 corrective re-runs per same failing test group.

## Source implementation
- scripts/domain/m4/casting/casting_disruption_resolver.gd: immutable per-instance FocusWard → CastingStability before/after, event trace and interrupt threshold, Boss Break untouched.
- scripts/domain/m4/casting/focus_ward_resolver.gd: Focus Ward grants/absorbs ONLY casting disruption, not HP or Barrier.
- scripts/domain/m4/casting/casting_refund_policy.gd: M-D22 strictly partial MP quote from actual paid_mp in M2 cost receipt. Ratio and rounding explicitly BALANCE_PROVISIONAL, reject nonapproved settings, clamp at MaxMP, no free refund for cancellation, HP0 or Last Spell.
- scripts/domain/m4/integration/m4_domain_resolver.gd: Internal APPLY_CASTING_DISRUPTION_M4_FIXTURE under explicit gate and versioned effect catalogue; caller may not inject arbitrary power. Requires declared EnemyAction and closed Reaction Window; ON_HIT requires separately trusted M5 hit fixture and uses M3 Protect actual recipient. DIRECT requires matching casting_id and ignores Protect. Once Stability reaches zero: CastingInterrupted → ScheduledEffectCancelled → real M2 MPRestored → Casting CardInstance→Discard → ConcentrationEnded, atomic original-state transaction. Reject duplicate sources, invalid target/effects.
- scripts/domain/m2/integration/m2_domain_resolver.gd and m2/economy/resource_ledger.gd: use original RECOVER_MP authority and dedicated tagged Concentrating-CastCompatible reaction cost, not duplicated RP/MP logic.
- scripts/domain/m3/reaction/reaction_eligibility.gd and reaction_queue_resolver.gd: concentrated actor may react only when actual versioned SP definition explicitly declares cast_compatible, then pays RP+MP and moves held SP only on real Confirm. FOCUS_WARD_FIXTURE applies to matching active CastingInstance and emits FocusWardGranted. No basic Guard/Protect escalation.
- tests/test_m4_disruption.gd: positive, negative, atomicity and seed replay of two independent Full Chant actors, concentrated SP reaction, Protect forwarding, nonhit rejection, Focus Ward shielding, direct disruption, immediate partial MP refund, status/zone conservation.
- .github/workflows/godot-m4-2-disruption.yml: official Godot 4.7.2 SHA512/import; M4.2 new suite, predecessor M4.1 47, M3.5 101, M1–M3.4 497, four smoke scripts and saved failure logs.

## Scope limitations
M4.2 headless fixture-only API is NOT a public direct-stability-decrement command. This requires authoritative encounter effect content and trusted on-hit fixture input; full M5 hit/crit/Barrier/HP remains deferred. Focus Ward does not change HP. No Last Spell instability (M4.3) or caster HP0 invalidation (M4.4) or final M4.5 acceptance or UI countdown replacement. Testing uses provisional refund=1/2 FLOOR_FIXTURE and base stability10 without making either balance value canon.

## Evidence to add after actual CI
Record source HEAD, official CI run/job, M4.2 real executed cases, full 645 prior assertions, seed/event/final state hashes, repairs, remaining scope and final independent verdict.
