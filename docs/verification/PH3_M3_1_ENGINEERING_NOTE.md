# Phase 3 — M3.1 Battle Phase Engine

Authority: docs/combat/02 P1-D01, 03 M-D08/09, 06 published enemy intents, 20 PRE3-R09/13 and CORE-01, 23 Phase3 Plan. Previous M2.5 run #38586810189 verified 249/249 named core-domain assertions. This work must NOT recode the M2 transaction, card, or resource resolver.

## Modules

- scripts/domain/m3/phase/phase_engine.gd: phase FSM, one Player action at a time, user-issued EndPlayerPhase, deterministic enemy declaration/fixture completion, EnemyPhase RP expiry, M2 phase start integration and unified M3 event/command ledger.
- scripts/domain/m3/phase/phase_boundary_resolver.gd: PRE3-R09 tick fixture first, CORE-01 outcome evaluation (victory even if simultaneous allied wipe), real M2 resource renewal and hand refill. REAL M4/M5 Casting/Status effects fail closed rather than silently tick.
- scripts/domain/m3/enemy/enemy_action_scheduler.gd: published intent IDs, explicit action_order, created_seq stable tie and immutable public EnemyAction ID. No AI choices, hit, damage or target changes.
- scripts/domain/m2/integration/m2_domain_resolver.gd: extends existing integration with BASIC_ATTACK_RESOURCE_ONLY by calling existing M2 ResourceLedger, no duplicate basic attack/MP logic.
- tests/test_m3_phase.gd: A->A->B->A actions with shared AP, zero-AP Free Swap allowed, explicit end, enemy ordering and no fake damage, RP expiry, newly opened PlayerPhase draws to 4 and resets quota, PRE3-R09 ordering, CORE-01 outcome priority, stale/duplicate atomic rejection and seeded replay.
- .github/workflows/godot-m3-1-phase.yml: Godot4.7.2 official binary with SHA512 and import checks; M3.1 + all 249 M1/M2 assertions + four legacy scripts; on failures upload actual logs.

## Interface and explicit deferred boundaries

M3.1 player actions are actual existing M2 resource/card fixture actions with immediately committed results. Player order is unrestricted; no 3-person advance planning, no automatic phase end at AP0. EndPlayerPhase invokes actual M2 AP->RP conversion cap6; end EnemyPhase invokes actual M2 RP expiry. Every EnemyAction is tied to an already-published intent and ordered by action_order, created_seq, stable intent_id. Completion is explicitly FIXTURE_ONLY and DOES NOT execute real enemy damage or silently resolve Reaction. M3.2 supplies Reaction windows/queue, M3.3 Guard/Protect, M3.4 UI mode policy, and M3.5 full combined acceptance.

At phase-start, only explicit fixture-only pending CASTING or STATUS hooks are accepted. CASTING_FIXTURE is a physical CastingZone->Discard transition via M2, and STATUS_FIXTURE is a test trace without effect application. Real CastingInstance/status effects reject before resetting AP or drawing. Once fixture hooks are done, outcome is evaluated with enemy-defeat priority, then the actual M2 START_PLAYER_RESOURCES handles APDebt (M-D04 carry PROVISIONAL), swap quota renewal and draw-to-four. No HP effect, attack hit, status tick, spell release, or fixed Guard 40% formula is claimed.

State is immutable by rejected commands, seeded and hashed via M1 canonical SHA256, with strict command IDs, event sequence and no UI timer. Balancing values such as MP gain2 and MaxAPDebt8 remain configurable BALANCE_PROVISIONAL, not approved permanent.

Status: M3_1_PHASE_DOMAIN_VERIFIED based on actual Godot 4.7.2 GitHub Actions; M3 DOMAIN VERIFIED remains prohibited until M3.2–M3.5 pass independently.


## Executed M3.1 certification — 2026-10-14

- Source commit 4c5e77fbce21aa354935296e42803019b43133ad. Official GitHub Actions run: https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38590076311, job 115942290809, completed/success.
- Godot 4.7.2.stable.official.ed1daf0bf, release ZIP SHA512 pass, editor import pass; M3.1 tests 61/61 PASS and failed=0. Same workflow re-ran all 249/249 M1–M2 Domain tests with no failures; four legacy scripts exit0. Named Domain assertion total: 310/310.
- First run https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38589915776 failed to parse the test because its Engine constant shadowed the native Godot Engine singleton; subsequent commit 4c5e77f renamed the constant to PhaseEngine. No oracle was removed or weakened.
- Seed 20261014. Initial state SHA256: 07d689c2e6d9ae72c02558b729623ad263f1233f56fd32d9fd396b3b440b8bdc. Event SHA256: a4fe01dcd239d3f2943c82879eb1848f06fe524dfb9eebceaaa7d9a57b6bdb5c. Final state SHA256: 1cf0ad2d7473c594ab4f687260f390db81ba3b224cd50cd6c9643f510bfab593.
- A->A->B->A immediate player action execution, explicit EndPlayerPhase, zero-AP valid Free Swap, public EnemyAction stable sort, duplicate/stale atomic rejects, 1:1 AP->RP cap, RP expiry, next Player Phase draw-to-four and quota refresh, fixture Casting and Status trace ordering, fail-closed real unresolved effects, simultaneous all-dead victory priority, and seeded full-phase replay have actual positive/negative test evidence.
- Explicit non-coverage: actual enemy damage, real Reaction Window/Queue, Guard/Protect, Smart/Always Ask/Quick UI contract, real Casting/Status tick effects, M5 enemy AI, UI countdown replacement. M3.2–M3.5 remain NOT_IMPLEMENTED, and the existing UI remains unchanged. APDebt Max8 and basic MP gain2 are BALANCE_PROVISIONAL, not USER_APPROVED.

Acceptance verdict: M3.1 PASS, allow subsequent M3.2 work only as a separate CI-gated work package. Do not announce M3 DOMAIN VERIFIED.
