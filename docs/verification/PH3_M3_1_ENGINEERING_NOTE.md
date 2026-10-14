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

Status: SPECIFIED_NOT_TESTED until actual Godot 4.7.2 GitHub Actions verifies named positive and negative M3.1 tests plus M1-M2 regressions. M3 DOMAIN VERIFIED is explicitly NOT allowed at M3.1 alone.
