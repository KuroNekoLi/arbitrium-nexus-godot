# Phase 3 M5.4 — Completed Action Outcome / CORE-01 & CORE-02 Engineering Note

**Scope verdict:** **M5.4 OUTCOME DOMAIN VERIFIED — HEADLESS FIXTURE SCOPE**. M5.5 **NOT VERIFIED**; full M5 **NOT VERIFIED**; playable combat and retail content **NOT VERIFIED**.

## Authority and exact predecessor

- Correct repository: [KuroNekoLi/arbitrium-nexus-godot](https://github.com/KuroNekoLi/arbitrium-nexus-godot), based on master `77dc6868f902a2e86fa24c7ea2b9e88052f618a5` (includes upstream semantic reconciliation Plan A). Do not mistakenly use the older `Astraea-Academy` prototype or the documentation-only `astraea-combat-rules`.
- Latest approved combat authority remains `docs/combat/00`–`23`, updated reconciliation audit, `docs/combat/21_PHASE2_SPEC_ACCEPTANCE_REPORT.md`, `23_PHASE3_EXECUTION_PLAN.md`, and `docs/verification/PH3_M5_EXECUTION_PLAN.md` §M5.4. **CORE-01** enemy-clear-first victory at the **completed legal action + necessary effects** boundary; **CORE-02** unreleased Last Spell caster HP0 invalidates scheduled spell immediately. M5.3 predecessor official master [CI #38674650325](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38674650325) = **1,033/1,033 Domain** plus four legacy runners.
- Numeric ContentConfig and test encounter properties are always **BALANCE_PROVISIONAL**. Registered Recoil is an isolated testing effect used to exercise CORE-01, **not approved permanent gameplay card content**.

## Implementation and boundaries

1. `scripts/domain/m3/phase/phase_boundary_resolver.gd` retains the existing **unique** outcome authority `outcome(battle)` / `check_action_outcome(core, config)`. The decision order is unchanged: enemy all HP0 → **VICTORY** even if all allies HP0; else if all allies HP0 → **DEFEAT**; otherwise **ONGOING**. No DRAW. Under `m5_4_outcome_enabled`, the outcome event labels the completed Action/Phase boundary explicitly and, if all three are positive-HP EXHAUSTED, records `ALL_EXHAUSTED_HP_POSITIVE_PENDING_DECISION`; does **not** invent DEFEAT.
2. `scripts/domain/m3/phase/phase_engine.gd` forwards provisional M5.4 config to the **same authoritative outcome function** for basic/EnemyAction/phase checks. The same-phase due casting and status ordering remains **Casting → StatusTick → Outcome → M2 resource/AP refresh & draw**. If terminal, no AP refill/draw or extra accepted Action.
3. `scripts/domain/m5/status/hp_lifecycle_bridge.gd` gains `registered_recoil()` as a thin adapter to **existing M5.2 `dot()` HP+Barrier+M4.4 incapacitation pipeline**. It never opens an external HP-setter; the numeric damage and shield mode arrive **only from versioned content definitions**, not the Command payload.
4. `scripts/domain/m5/combo/tactical_sp_resolver.gd` applies a registered successful-SP recoil **after full M5.1 damage/Combo but before whole-SP Break/Exposed/Outcome**. M2 still charges exactly once for the CardInstance, then the M5.4 terminal outcome is checked only **after all authorized per-SP effects**. No early DEFEAT can truncate a successful enemy-lethal action; HP0 invalidation from M4.4 happens **at the time HP actually reaches 0**, never deferred.
5. `scripts/domain/m4/casting/casting_timeline_resolver.gd` for M5.4-enabled content emits `LastSpellReleased` and `ActorExhausted` before the *released* Last Spell's true M5.1 damage and optional registered recoil. If that recoil kills its caster **after the released magic has dealt damage**, M4.4 records Incapacitated but **does not retroactively create LastSpellInvalidated or cancel damage**. A Poison DoT that drops a *pre-release* caster to HP0 continues to produce **ActorIncapacitated → LastSpellInvalidated → ScheduledEffectCancelled**, with no AP/MP/refund or once-used restoration.
6. `scripts/domain/m5/integration/m5_domain_resolver.gd` enables **terminal command atomicity** under the M5.4 flag: no EndPhase, SP, Reaction, Casting, BasicAttack, or M4 legacy fixture command after `battle.outcome != ONGOING`. Rejected instructions return the same original state/event/RNG/card zones/AP/MP and zero new events, including a replay tape that tries to append commands after VICTORY.
7. **No new BattleState, random source, card zone, or second terminal reducer**. Existing older fixtures without `m5_4_outcome_enabled` remain backward compatible.

## Actual acceptance evidence — 2026-10-15 (Asia/Taipei)

- Official Godot 4.7.2 [CI #38676335088](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38676335088), tested source SHA `117a41772fcccc193ef9b40dceac595710ccab1f`: **completed / success**.
- Godot binary verified against release SHA512; headless editor import succeeded.
- `tests/test_m5_outcome.gd`: **48/48 new named assertions PASS, 0 fail, 0 skipped**. CI explicitly greps CORE-01 simultaneous KO, outcome-after-recoil, terminal replay guard, actual Boss-survives DEFEAT, two DoT same-tick VICTORY, Last release irreversible, CORE-02 cancellation event order, and Exhausted pending edge.
- In the **same CI job** M5.3=44/44, M5.2=48/48, M5.1=44/44, every M1–M4.5 prior named test and all four legacy headless runners PASS. **Cumulative M1–M5.4 1,081/1,081** (previous 1,033 + 48), **0 failures**.
- Fixed seed **20261014**, one actual **M2-paid** setup card Command that kills the Boss, then applies registered recoil killing the last ally **within the same transaction**:
  - `initial_state_sha256 = dd1bbcb5cac91b62c6030e1f464eaca11f13fd1497b53450683c2748a58847ad`
  - `event_sha256 = 813a20b891cbb9c1c9c972121b1ab1b0c346b1c30430febca8b9aa1cf22f7372`
  - `final_state_sha256 = 7ae630e6ce03100d01efa37830bfc23fe8de6fa946f30e68a06888016caba502`
  - Expected final: Boss HP0; A/B/C all HP0; final `VICTORY`; no DRAW. Replay returns identical Event/State digests. A rejected post-Victory command cannot alter the final digest.
- **Repair history under project gate:** initial push had malformed workflow YAML and did **not** execute a test; workflow corrected. First executed Godot run [#38676165628](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38676165628) exposed missing fixture convenience function (`initial`) at GDScript parse; corrected. Second executed run [#38676231817](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38676231817) passed 42/43 executed cases but encountered an erroneously sent `PASS_REACTION` in an automatically closed **empty Reaction Window**, skipping 5 dependent Last-release assertions; corrected test harness to follow M3 CORE-04. Third executed Godot run [#38676335088](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38676335088) succeeded 48/48 and complete predecessor regression. **No assertions weakened/deleted**; no additional test attempts for this group beyond project limit.

## Trace and educational engineering rationale

- **Transaction boundary is not the HP0 event boundary.** A character reaching HP0 must undergo immediate `M4.4.Incapacitated` plus forced invalidation of *unreleased* spells. However, determining VICTORY/DEFEAT early after the first hit of a legally committed multi-effect Action would violate CORE-01; the authoritative outcome evaluation happens only after its complete legal event queue. This is a classic event sourcing distinction between **intra-transaction domain event causality** and the **aggregate transaction commit**.
- **Use a single writer rather than multiple ad hoc HP setters.** The M5.2 HP lifecycle owns barriers, HP clamping and casting invalidation. Adding a `Recoil` adapter to that writer preserves DRY / single-source-of-truth architecture, analogous to Android MVI reducer/effect boundaries.
- **Immutable terminal states** provide replay auditability. The Domain rejects a future command after WIN/LOSE without consuming RNG or payment. This prevents double-grant, late enemy attacks, or client UI callbacks running after battle completion.
- **Provisional content vs permanent canon** are separate: a one-shot test skill that kills both sides is evidence for CORE-01 arithmetic and ordering, not proof that a production skill or self-damage mechanic has been approved.

Interview discussion: Why isn't `if hp <= 0 { defeat() }` appropriate inside each damage hit? Why must a Last Spell that is already released behave differently from one still Casting? How do you assert command rejection is atomic including hidden RNG state? How does preserving one centralized Outcome authority reduce risk of contradictory screens or race conditions?

## Remaining explicit scope

- **M5.5 NOT VERIFIED**: still requires a full legal 3-person-vs-Boss battle from encounter start to terminal Victory/Defeat, multiple actual card/action rounds, **100 fixed seeds**, complete replay/invariant audit, legacy/UI boundaries.
- `P2-S15/S16` Spell Counter real eligible Reaction SP and window remain **BLOCKED_CONTENT/NOT VERIFIED**; Analyze/Enemy Intel `P2-S02～S12` remain **DEFERRED_CONTENT/NOT VERIFIED**.
- The fully resolved **all-party EXHAUSTED but positive HP** outcome is explicitly **CORE_RULE_EDGE_PENDING**, never auto-DEFEAT, and awaits user approval.
- User-facing bilingual i18n, real HUD, scene animation timing, AoE/mixed-target and content balance are outside M5.4 headless gate. The test-only recoil effect and mock incapacitated encounter initial states are not a replacement for a full real battle.
- For M5.5, read exact master HEAD and current official verification docs. Preserve M2 ledger, M3 Phase/Reaction, M4 Casting and M5.1–M5.4 action boundary; baseline **1,081 named Domain** plus four legacy runners, with independent Godot CI and seed/tape hashes. Do not claim full M5 until end-to-end battle is verified.
