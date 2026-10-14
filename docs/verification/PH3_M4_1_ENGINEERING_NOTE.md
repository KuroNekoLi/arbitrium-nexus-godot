# Phase 3 M4.1 — Dual Casting Foundation / Engineering Note

Status at authoring: IMPLEMENTED AWAITING REAL GODOT CI; no passed claim prior to actual logs.

## Authority and prerequisites
ChatGPT Library 05_DUAL_CASTING_AND_INTERRUPTION.md; 18/19 approved M-D01..31 (M-D21 same default MP for Chantless and Full); 20 PRE3-R12/13; 21 Phase2 specification; 23 Phase3 roadmap. Decision priority: USER_APPROVED > approved M/P1/P2 > DELEGATED_DEFAULT > BALANCE_PROVISIONAL. Latest previously verified master 87a01d27bc856462806faed71174ebcd6dae1743, official M3.5 GitHub Actions #38601440415 with 598/598 named Domain assertions.

## Deliverables and minimal changes
- scripts/domain/m4/integration/m4_domain_resolver.gd: new CAST_SPELL_M4 command modifies SAME existing M3 Phase State and uses M2 integrated cost and card transactions. Every other command passes through M3 PhaseEngine, including Reaction Queue and phase boundary. This is NOT another Battle State.
- scripts/domain/m4/casting/casting_profile_resolver.gd: legality based on owned CardInstance, explicit mode-allowed per-version spell profile, target and authoritative M2 cost definition. Does not accept player AP/MP price data.
- scripts/domain/m4/casting/casting_instance_resolver.gd: cast:command-id, one active Full per caster, Concentrating actor state, separate per-cast stability (provisional fixture only), associated Casting-zone CardInstance, next Player Phase scheduled release.
- scripts/domain/m4/casting/casting_timeline_resolver.gd: ordered real releases, Casting→Discard through M2 zone operation, clear Concentration, release and SpellEffectDeferredToM5 events before Outcome/AP renewal/draw-to-four. No invented HP damage.
- scripts/domain/m2/integration/m2_domain_resolver.gd: adds SETTLE_CASTING_CARD_M4 reusing existing authoritative Casting-zone move.
- scripts/domain/m3/phase/phase_boundary_resolver.gd: conditionally handles genuine due CastingInstances before M3 legacy fixture hooks, Outcome, AP and draw, and checks remaining casting zone/card links; existing M3 without active casts remains unchanged.
- tests/test_m4_dual_cast.gd: named CAST-001/002/003, M21-CAST-001, negative/stale/duplicate/cost/zone/timeline/Replay tests.
- .github/workflows/godot-m4-1-dual-cast.yml: official Godot4.7.2 SHA512 import, M4.1 script, ALL 598 named M1–M3.5 predecessor Domain cases, 4 prototype smoke tests and uploaded logs.

## Semantics, test boundaries and deferred work
Chantless: cost once and immediately publish a spell-effect contract, not actual M5 HP damage. Full: cost once at legal submission, Hand→Casting and CastingInstance, Concentrating blocks ordinary actions and second Full, no generic free Cancel; at next Player Phase start perform release before M2 AP & draw, clear Concentration, move card Casting→Discard without repaying cost.
M-D21 default MP cost equal across modes through M2 quote, AP modifications/overload still authoritative M2 rules. Stability base 10 in fixture is explicitly BALANCE_PROVISIONAL; Casting Disruption and Focus Ward (M4.2), Last Spell (M4.3), HP0 forced invalidation (M4.4), real M5 damage/status and actual HUD (Presentation) are NOT IMPLEMENTED. Unexpected dead caster at release fails closed CASTER_HP0_NEEDS_M4_4_INVALIDATION; target unavailable at release fails closed RELEASE_TARGET_TBD, no invented retarget/refund. No numerical balance promoted to canon.

## Hard gate and repair cap
M4.1 VERIFIED requires the actual GitHub Actions official Godot4.7.2 green job, named positive/negative cases, Seed event/state Hash, full M1–M3.5 regression, and verified committed HEAD. Same failing group: first attempt plus max two fixes; third failure stop, preserve logs, never relax assertions for green.
