# Phase 3 M4.1 — Dual Casting Foundation / Engineering Note

Current status: M4_1_DUAL_CAST_DOMAIN_VERIFIED. Official Godot 4.7.2 independent gate completed successfully.

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


## Executed official CI and final verdict — 2026-10-15 Taipei

- Tested source SHA: **8fcd65ee075664593a08448f3d44eede21a5c2bf**. Successful [Godot4.7.2 CI #38654007627](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38654007627) job 116159331211 completed/success, SHA512 official Godot ZIP verified, imported with version **4.7.2.stable.official.ed1daf0bf**.
- Actual new M4.1 test output: **47/47 PASS, failed=0**, marker M4_1_DUAL_CAST_DOMAIN_VERIFIED. SAME job ran ALL prior M1–M3.5 scripts **598/598 named Domain cases PASS** and 4 legacy prototype scripts exit0. Overall **645/645 Domain assertions PASS**.
- Fixed Seed **20261014**. Initial SHA256 **5dcd5282669b59f29c62fd1907299ac053a24a68d66da77e6e5e0c78fdc58e49**; Event SHA256 **6225fa6eb9949575437d7305057be8b7ad743d000e42625f8c8df9427118151b**; Final State SHA256 **42b5f311978d20fea048cf5a85e075ff79998d540c7332ae69343ad595794871**.
- First source commit 4df6e41e848bda350aa53fdec225466845f7f9a5 produced [initial run #38653818191](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38653818191): new M4.1 47/47 passed, but M3.1 legacy assertion M3_1_REAL_STATUS_FAIL_CLOSED failed because the new boundary changed its expected error name from UNIMPLEMENTED_REAL_TICKS. Repaired solely that unchanged pre-existing error contract in source commit 8fcd65ee075664593a08448f3d44eede21a5c2bf; no rules or assertions weakened. This was initial run + ONE corrective rerun, within stated repair cap.
- Canonical scope: same MP base for both modes, cost once at commit, real M2 Hand→Discard or Hand→Casting→Discard, Concentration and refusal of further actions, next Player Phase release BEFORE AP renewal and hand refill, cost/card atomicity and seeded replay. An explicit provisional stability=10 fixture does not approve balance; no actual damage or spell interruption.
- Deferred by design: M4.2 Focus Ward/Disruption and MP refund, M4.3 Last Spell, M4.4 HP0 forced invalidation, M4.5 combined acceptance, M5 HP damage and Presentation HUD. Dead caster or dead target at release intentionally fail closed. This Domain gate does not mean the whole M4 or playable battle is verified.

**Final independent acceptance: M4.1 VERIFIED; proceed to M4.2 only as a separate task.**
