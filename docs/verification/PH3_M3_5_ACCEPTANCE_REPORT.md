# PH3 — M3.5 Integration Acceptance and Regression

Status: IMPLEMENTED_AWAITING_ACTUAL_CI. Never label M3 DOMAIN VERIFIED without real successful official Godot 4.7.2 CI and complete M1–M3.4 regression.

## Scope, authority, and gate

Sources: docs/combat/07_REACTIONS_PROTECTION.md, docs/combat/20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md, docs/combat/23_PHASE3_EXECUTION_PLAN.md and verified M1–M3.4. Predecessor test counts: M1–M2 249, M3.1 61, M3.2 50, M3.3 54, M3.4 83 — 497 authoritative named assertions. Reuse all previous resolvers without duplicating ResourceLedger, card zones, PhaseEngine, Reaction Window/Queue or UI Mode domain policy.

## Deliverables

- scripts/domain/m3/integration/m3_domain_resolver.gd: thin reducer boundary delegates to ACTUAL M3 PhaseEngine and authoritative M2 atomic resource/card transactions. It adds invariant checks, immutable rejection enforcement, canonical state/event hashes, deterministic replay receipts, and M3.4 read-only mode projection. Does not reimplement any mechanics.
- tests/fixtures/m3_5_fixture.gd: fixture-only 3 allies x12 SP instances + 1 Boss with 4 publicly ordered EnemyActions; explicit BALANCE_PROVISIONAL basic attack profile and synthetic reaction Counter and independent support. These are not actual M4/M5 magic or approved content cards.
- tests/fixtures/m3_5_scenario.gd: composes a real 2-full-round command tape from actual integrated transaction outcomes, with generated authoritative WindowIds, EnemyActionIds, event sequence and hand CardInstance IDs.
- tests/test_m3_integration.gd: 2-round workflow, first Action counter -> subsequent Protect skipped at zero cost while independent support executes, single-target 3-hit Guard then Protect redirect, AOE multi-hit Guard and invalid Protect, RP reaching zero then truly empty Window, enemy end, phase renewal and hands replenish to 4, second PlayerPhase A-A-B-A immediate action order, second Enemy Phase 4 explicit Passes, third player round opens. Resource/card guardrails and negative stale, duplicate, premature and no MOVEMENT.
- tests/test_m3_replay.gd: full tape with fixed seed, canonical event and final state SHA256, receipts, repeated same-seed/state and mode-independence across Smart, Always Ask, Quick; invalid stale, duplicate and premature commands; mutated configuration, changed seed and hand conservation.
- .github/workflows/godot-m3-5-integration.yml: official Godot 4.7.2 release with SHA512, real import and both new M3.5 suites; all 497 preceding Domain assertions, 4 legacy smoke scripts and full logs upload. Any failure must leave the Gate red.

## Scope boundaries

M3.5 verifies the **headless M3 fixture domain only**: Guard basic 1RP for all eligible multi-hits in one EnemyAction, Protect basic 2RP redirects a single-target attack before future hit; same-window execution quota and skipped invalidated Protect no debit/card, shared 6 RP cap from existing M2; empty Window only when truly no Reaction; never time-driven Pass even with Quick. Commands and their receipt hashes determine results, not UI prompts/FPS.

No actual enemy attack HP calculation, crit/hit/DEF/RES/Barrier, numerical Guard 40% coefficient, or Status effects: those belong to M5. Counter and Support are explicitly synthetic M3.2 reaction fixtures, not real M4 casting interruptions; true CastingInstance/LastSpell are M4 scope. Legacy scripts/main.gd 1.5s countdown, real HUD, input modes and translations remain a separate Presentation migration even after this Domain gate. Do not say PLAYABLE VERIFIED. Real queued incapacitation from M5 damage cannot be certified until actual HP/status pipeline exists; the PRE3-R04 cancellation fixture tests existing free-skip behavior only.

## Evidence to append after CI

Record exact source and document HEAD SHA, official Actions run and Godot version/SHA512, integration and replay case counts, all predecessor regression counts, seed, command count, event and final state hashes, repairs/retries and cross-milestone limits. Only with fully successful CI can the final verdict be M3 DOMAIN VERIFIED — HEADLESS FIXTURE SCOPE.
