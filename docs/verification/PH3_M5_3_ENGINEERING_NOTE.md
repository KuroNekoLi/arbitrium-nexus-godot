# Phase 3 M5.3 — Boss FSM / Intent / Break / Exposed / Combo Engineering Note

**Verdict: M5.3 BOSS/BREAK/EXPOSED/COMBO DOMAIN VERIFIED — HEADLESS FIXTURE SCOPE ONLY.** Full M5 NOT VERIFIED; playable Boss battle NOT VERIFIED.

## Predecessor and authority

- Correct repository: `KuroNekoLi/arbitrium-nexus-godot`; branch `phase3/m5-3-boss-break-exposed-combo` from master `81f04531af7cad2b387d04b8646e204054bbabcf`.
- M5.2 predecessor Godot CI [#38670492488](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38670492488) = **989/989** Domain assertions PASS.
- Authoritative rules: `docs/combat/06_BOSS_AI_INTENT_BREAK.md`, `09_COMBO_SYSTEM.md`, `16_PHASE2_APPROVED_DECISIONS_WIP.md` P2-S17–31, `19`, `20`, `21`, `23`, and `docs/verification/PH3_M5_EXECUTION_PLAN.md`.
- Numeric Boss and SP effects are `BALANCE_PROVISIONAL` from `tests/fixtures/m5_3_fixture.gd`. Not retail balance, not a final skill catalogue.

## Implemented scope

1. **Deterministic, transparent Boss policy**: `scripts/domain/m5/boss/boss_ai_policy.gd` selects a legal single-target Boss action by conditional HP percentage and stable priority / skill ID; active ally targeting uses deterministic FIRST_ACTIVE or LOWEST_HP. M5 pre-commits the selected template on `END_PLAYER_PHASE`, then delegates to the existing M3 Scheduler and all M3 Reaction state. `BossIntentCommitted` preserves the exact announced target/skill, Protect does not trigger policy re-evaluation. No machine learning or second EnemyAction executor.
2. **Break is independent of Casting Stability**: `scripts/domain/m5/combo/tactical_sp_resolver.gd` processes every M5.1 DamageTrace and actual HP change before SP-level BreakGaugeChanged → BreakPending → BreakTriggered. The gauge locks at zero, ignores extra break damage while locked, and the next eligible Boss action is **publicly replaced** by `boss_fallback`; the engine restores max Gauge after its real action resolution. Current fixture limits fallback to a single-target live EnemyAttack. It does not cancel already started Casting.
3. **Exposed is a one-use opportunity**: a successful registered tactical SP sets Exposed on a target, with `expires_round=created_round+1`; phase-end expires it at the end of the subsequent Player Phase. A subsequent separate SP consumes it only on actual success; miss preserves it. Additional exposure cannot refresh/replace an existing opportunity. A card cannot consume the Exposed that it itself creates; one SP, including multi-hit, consumes at most once.
4. **Combo costs cannot be forged**: `PLAY_TACTICAL_SP_M53` resolves actual `CardInstanceID` and M2 `COMMIT_SP_CARD_FIXTURE`, so the finisher really spends its own AP/MP once and moves from Hand to Discard. A tagged setup offers a `ComboOpportunity`; a player explicitly chooses `NORMAL` or `COMBO`. `COMBO` demands a **different** actor, correct tag/target and still-valid opportunity. Extra Combo AP=0. Its guaranteed no-extra-roll bonus goes through the same M5.1 HP writer. No free finisher, no same-person impersonation.
5. **Atomic and replayable M5 entry**: `scripts/domain/m5/integration/m5_domain_resolver.gd` is the only new command bridge, retains M2 payment, M3 phase/reaction, M4 casting, and M5.1/5.2 HP+status engines. All errors reject with unchanged state/event/RNG, and M1 hashes remain the replay authority. `BossIntentCommitted`, `BreakTriggered`, `ComboExecuted`, `ExposedApplied/Consumed/Expired`, and `BossBreakRecovered` are explicit Domain events.

## Official executable evidence — 2026-10-15 Asia/Taipei

- [Godot M5.3 workflow run #38674222091](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38674222091): **completed/success** on code SHA `e9e33ce86bd1232aa1323c4a9c8a97ce85ef12b0`.
- Official Godot **4.7.2** headless editor import and test runner executed.
- `tests/test_m5_boss_combo.gd`: **44 executed / 44 PASS / 0 FAIL**. CI required key IDs including multi-hit before Break, second-party real payment, Exposed consume, public fallback, Gauge recovery, Event replay, same-card cannot exploit Exposed, and expiration.
- Predecessor `M5.2=48/48`, `M5.1=44/44`, all pre-existing M1–M4.5 tests and four legacy prototype runners passed in the **same successful job**. **Cumulative named Domain: 1,033/1,033** (= prior 989 + M5.3 44), no removed assertions.
- Actual accepted Replay command count = **9**, Seed = **20261014**:
  - Initial state SHA256: `c96738c4f4bc66e08aa6c5825648f086baac22d7527acf2275e554c045bfdbde`
  - Canonical event SHA256: `ab66610a558b00751c56920924dddb915b2bc11915768479ceb5cf7d970ff9bc`
  - Final state SHA256: `a4d00e293e09cbb9f39b7a05e3f8eeb776ae972745b37e2f4f97099800fcdf22`
- Failure and repair history: first draft workflow had YAML replacement error (no jobs); corrected workflow. The next test execution surfaced a GDScript reserved-keyword parser issue in the new test script; fixed `pass` identifier. The subsequent official CI succeeded. Do not count the invalid-YAML workflow as a gameplay test execution; there was **one parser correction** before accepted Godot run.

## Key engineering decisions and interview-grade learning

- **Commitment vs execution:** Boss AI is a deterministic **planner**, M3 is the authoritative **scheduler/executor**. Planning cannot occur after Reaction/Protect to select a more damaging hidden branch. This is similar to event-sourced command validation: a committed intent is immutable input to action settlement.
- **Transactional integrity:** The setup and finisher cards are each charged by M2. Tactical resolution does not invent a parallel AP counter or remove cards manually. If a command fails, the outer M5 reducer discards its working snapshot. This prevents partial-charge and double-spend bugs.
- **Whole-action boundary:** Break is committed after every hit of the actual SP, so hit 1 cannot grant an illegitimate hit-2 bonus. Exposed likewise cannot self-consume. The true HP writer remains M5.1 and its HP0 bridge remains M4.4.
- **Deterministic test oracle:** 44 named oracles + seed/tape/event/final hashes are regression evidence, independent of animation speed, editor render frames, or player UX.
- **Separated lifetimes:** Exposed expires at an explicit Player Phase boundary; Break instead persists until a qualifying Boss action starts and finishes. Treating both as generic `duration=1` status would violate P2-S17/P2-S29.

## Explicit out-of-scope and risks

- **P2-S15/S16 Spell Counter: `BLOCKED_CONTENT / NOT VERIFIED`**. No approved Counter card, targetable spell-release Reaction Window or payment policy exists; cannot silently treat Casting Interrupt as Spell Counter.
- **P2-S02–S12 Analyze/Enemy Intel: `DEFERRED_CONTENT / NOT VERIFIED`**.
- Boss tactical catalogue currently supports a single enemy, single-target damage actions and stable-priority tie resolution. Multiple Boss units, active-Casting fallback edge, AoE alternatives, and actual Counter-interrupted fallback action need additional approved effect content and gameplay tests.
- Provisional `break_max=9`, BreakDamage values, **which skill exposes** and Combo damage profiles are fixture-only; no lasting balance approvals. The Exposed expiry boundary itself is **user-approved P2-S17**, not provisional.
- CastingCombo/LastSpell resonance requires real qualifying registered Cards/Reaction windows, not instant or unpaid enhancement. Full Chant tactical SP is intentionally **fail-closed**, not declared supported.
- M5.4 is still required to prove full CORE-01 multi-effect simultaneous Outcome; M5.5 still requires one complete 3-person Boss encounter and at least 100 seeded full battles. Final HUD, i18n, animation and player-facing action preview remain future work.
- `M5.3 DOMAIN VERIFIED` never means complete M5 or PLAYABLE VERIFIED.

## Handoff — M5.4

Read the exact latest master, this note, `docs/verification/PH3_M5_EXECUTION_PLAN.md`, M5.1 and M5.2 engineering notes, and `docs/combat/21` CORE-01/02. Preserve real single M2 cost and M3/M4/M5 reducers. Implement final whole-action Outcome priority (enemy-all-HP0 => Victory even if all allies zero, no DRAW), correct Last Spell pre/post release HP0, and fail-closed unresolved `all EXHAUSTED but positive HP` edge. Independent CI must rerun **1,033** predecessor Domain assertions plus four legacy headless runners; never proceed to M5.5 or claim full combat completeness on M5.4-only tests.
