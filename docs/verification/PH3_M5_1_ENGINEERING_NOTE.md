# Phase 3 M5.1 — Hit / Crit / Real Damage Engineering Note

**Status: M5.1 DAMAGE DOMAIN VERIFIED — HEADLESS FIXTURE SCOPE; full M5 NOT VERIFIED.**

## Source and prerequisite

Combat authority: current `docs/combat/` rules and engineering contracts, plus `docs/verification/PH3_M5_EXECUTION_PLAN.md`. Historical predecessor CI receipts were removed after completion; current test entrypoints are in `docs/ci/CI_TEST_MATRIX.md` and `tools/ci/integration_suites.txt`.

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


## Official real Godot 4.7.2 acceptance — 2026-10-15 Taipei

**Final code source:** 407ca2c9e3f7ffc67de45e2150300465420192d1. Official completed SUCCESS [GitHub Actions #38668678354](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38668678354), job 116206382905; Godot 4.7.2.stable.official.ed1daf0bf, SHA512 ZIP verified, project editor import passed. M5.1 **44/44** named assertions passed; M1–M4.5 **897/897** passed; cumulative **941/941** and all four legacy headless prototype runners passed, process exits zero. No skipped oracles.

Actual **10 accepted commands**, Seed **20261014**. Initial SHA256 **ed2a46bfe3d0483d1da78c21ea249bf467219ab775d54415dd5e40dd8e44f609**, aggregate Events SHA256 **62f244f463941b9b9d2d79344bdc53b308554d70571554015f71fafe72810db8**, final State SHA256 **9988c6cd48b65ab98a5acb269906e52cf9e960d3f79aac23c50dd4b3634608b2**. M5.replay reproduced Event and State hashes. Authenticated M2/M3/M4 paths: Chantless Boss HP100→84, Basic HP84→68, enemy published two-hit A HP100→80, B Full due next Player Phase Boss HP68→52 before AP/hand refresh, no extra AP/MP payment and no card duplication. Pure oracles also cover hit clamp, seeded Crit, Guard before Barrier, Protect defender, real HP0→existing M4.4 incapacitation, atomic rejection of arbitrary client HP/damage fields.

### Observed failures and repairs

1. First source 63599f1da4d7244bc2c4b415e12d4cb96569617d: [CI #38668367180](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38668367180) failed workflow YAML parsing; **no jobs or Godot tests ran**. Full YAML rebuilt from known-valid M4.5 and verified by readback before commit d4ffa47256c791356734c4e3273859b9cc47fc9e.
2. First actual Godot execution [CI #38668475789](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38668475789): download SHA512 and editor import succeeded, M5.1 fixture failed to parse illegal GDScript static const. Corrected to legal const by commit 54eaf81f91ab58288b04b4699a4f2910cbd45a71; CI fixture trigger added in verified source 407ca2c9e3f7ffc67de45e2150300465420192d1.
3. Actual complete CI #38668678354 passed **all** cases with zero assertion changes and no gameplay rule concessions. Correction count within initial plus two corrective retests per failing group. Original logs retained.

### Scope and next owner

**M5.1 DAMAGE DOMAIN VERIFIED — HEADLESS FIXTURE SCOPE ONLY.** It implements actual registered single-target Hit/Crit/HP, two-hit actions, basic attack, Chantless and normal Full due, enemy declared action receipt, existing M2 AP/MP/card conservation, CORE-02 HP0 bridge and canonical Replay. Last Spell actual M5 damage hook exists but has **not** been independently exercised in the 44-case integrated test, so do not claim that branch independently verified. All numeric coefficients (K100, BaseHit8500 bp, k100 bp, Guard4000 bp, element12500 bp, etc.) are BALANCE_PROVISIONAL fixture data, not permanently approved balancing.

M5.2 (Status stack/tick/Barrier lifetime/DoT/HoT/real Revive), M5.3 (Boss FSM/Break/Exposed/Combo), M5.4 (full Action Outcome CORE-01), M5.5 (100-seed complete battle) and playable UI/animations/i18n remain **NOT VERIFIED**. The trusted M4-only HP0 fixtures are not public M5 commands.

**Final verdict M5.1 Verified, not full M5 Verified.**
