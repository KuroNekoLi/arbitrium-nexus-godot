# Phase 3 M5.1 — Hit / Crit / Real Damage Engineering Note

**Status: IMPLEMENTED_NOT_VERIFIED — awaiting actual official Godot 4.7.2 CI.**

## Source and prerequisite

Combat authority: docs/combat/11, 16, 19, 20, 21, 23 plus docs/verification/PH3_M5_EXECUTION_PLAN.md and PH3_M4_HANDOFF.md. Predecessor completed CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38665990612 with 897/897 named M1–M4.5 Domain assertions and 4 prototype runners; prior HEAD da6731a6314ca9681c956eb850b1bbe1bf7d1216, M5 plan-only HEAD 0229c0eca3050257aa4c68288e3279d3e44249d7.

## Added modules and integration

- scripts/domain/m5/damage/hit_resolver.gd — percentage Hit RANDOM_PERCENT/GUARANTEED/CONDITIONAL, regular 5–95 clamp, independent Accuracy/Evasion, seeded M1 Park–Miller PRNG draw_index, no historic d20.
- scripts/domain/m5/damage/critical_resolver.gd — Hit before Crit, CritRate/CritDamage independently configured, eligible HP damage only; no Crit RNG on Miss or ineligible effect.
- scripts/domain/m5/damage/damage_pipeline_resolver.gd — versioned authoritative HP writer with real target/Protect, hit, crit, PAtk/PDef or MAtk/MDef, target-specific element resistance, optional seeded variance, Guard then HP Barrier, one floor(max(0)) HP deduction, event trace, legitimate ally HP0 via existing M4.4 invalidation. No M2 double payment.
- scripts/domain/m5/integration/m5_domain_resolver.gd — thin existing M4/M3/M2 delegation; rejects user-supplied HP/damage fields, legacy fixture-only public commands and absent M5 authority; seeded replay.
- scripts/domain/m3/phase/phase_engine.gd — M2 committed basic resource-only attack conditionally applies real M5 HP effect before outcome, and supports RESOLVE_ENEMY_ATTACK_M5 using M3 committed public enemy action / Reaction receipt / true Protect/Guard recipient and versioned registered enemy skill. Existing fixture behavior remains unchanged.
- scripts/domain/m4/integration/m4_domain_resolver.gd — Chantless M5 HP resolution immediately after genuine M2 commit, before PlayerActionSettled and outcome, only with explicit enabled M5 catalogue.
- scripts/domain/m4/casting/casting_timeline_resolver.gd — existing real Full/LastSpell due settlement and M5 HP effect before next Player Phase resource refill/outcome. Legacy DeferredToM5 events unchanged in non-M5 config.
- tests/fixtures/m5_1_fixture.gd — three 12-card Allies + 1 Boss with completely BALANCE_PROVISIONAL stats, HP profiles and versioned config. No consumer balancing approved.
- tests/test_m5_damage.gd — 44 named cases (including actual AP/MP payments, attack damage, Full due, Enemy two hits, deterministic Replay, no unauthorized HP command).
- .github/workflows/godot-m5-1-damage.yml — standalone SHA512 official Godot 4.7.2, headless M5.1 44 tests, all earlier M1–M4.5 897 assertions, four legacy smoke scripts, full log artifacts.

## Mandatory limitations

M5.1 only: genuine registered single-target normal, Chantless, Full, LastSpell and enemy HP hits; no M5.2 status stacks/DoT/HoT/Revive, M5.3 real Boss FSM/Exposed/Break/Combo, M5.4 full outcome, M5.5 full encounter. HP Barrier in the test is a versioned active capacity snapshot, not a completed status lifecycle. Hit base8500, accuracy coefficient100, defense K100, Guard4000, element1.25, variance0 and 50% crit bonus are BALANCE_PROVISIONAL fixture numbers only. No player-facing UI. M4.2/M4.4 legacy fixture endpoints cannot be called via the M5 public entrypoint.

## Acceptance to append from actual CI

Record commit, job/run, actual Godot version/checksum and import result, executed/passed counts, exact seed/tape/state and event SHA256, corrections and M5.2 handoff. Per failing group initial + max TWO corrective reruns; do not relax confirmed rules, assertions or test counts to make CI green.
