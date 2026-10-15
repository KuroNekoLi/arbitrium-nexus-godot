# Phase 3 — M5 Engine Handoff (M1–M5.5)

## What is authoritative

Read `AGENTS.md`, `docs/combat/00`–`23` and `UPSTREAM_RECONCILIATION_A_2026-10-15.md` before touching the engine. Do not use the legacy Flutter GDD or an archived second combat baseline to override approved CORE/P2 decisions. Current executable target: `KuroNekoLi/arbitrium-nexus-godot`; documentation-only `KuroNekoLi/astraea-combat-rules` is upstream source, not the runnable project.

The existing battle state has only one authority per layer: M1 schema/event log/PRNG, M2 CardInstance/AP/MP/RP, M3 Phase/Reaction and boundary Outcome, M4 Casting/Last Spell, M5.1 Hit/Crit/HP, M5.2 Status/Barrier/Heal, M5.3 Boss FSM/Break/Exposed/Combo, M5.4 legal whole-action terminal outcome. M5.5 adds a **test-only deterministic external driver**, never an overlapping application implementation.

## What the M5.5 full-battle fixture actually proves

- All three new combatants start alive and fully set up; each has 12 real SP CardInstance IDs, independently seeded shuffled deck, initial hand four.
- Hero A: setup and burn, independent Last Spell slot; hero B: paid Combo finisher and ward; hero C: Full/Chantless normal magic and regen.
- Public EnemyIntent → explicit legal Reaction → true Hit/Crit/Guard/Barrier→HP. One Boss with a stable skill policy and BreakFallback, Exposed single use, Last Spell actually released, actual status tick, and real final outcome.
- The driver explicitly submits `PLAY_TACTICAL_SP_M53`, `USE_EFFECT_SP_M5`, `CAST_SPELL_M4`, `ACTIVATE_LAST_SPELL_M4`, basic/phase/Reaction commands through `M5.apply()`, with a complete accepted Command Tape, per-step invariants and deliberate resource bounds.
- Primary gate: `tests/test_m5_integration.gd` (**32 named oracles**); replay `tests/test_m5_replay.gd` (**15 named oracles**); seeded stress `tests/test_m5_100_seeds.gd` (**100 independent terminal scenarios and 10 aggregates**). CI downloads SHA512-verified Godot 4.7.2, runs **all predecessors** and four legacy smoke scripts. Exact results belong in [PH3_M5_5_ACCEPTANCE_REPORT.md](PH3_M5_5_ACCEPTANCE_REPORT.md), not guessed here.

## Safe next phase if and only if M5.5 CI is green

1. **Presentation Spike**, not M5.6: compare one very small `Node3D+Sprite3D` battlefield to `Node2D+Y-sort` prototype; retain actual Domain events, same seed/tape, M3 explicit Reaction. Measure tactical readability and mobile performance; do not write renderer-owned damage outcomes.
2. **Bilingual Godot UI**: use Godot translation resources and keys for English/Traditional Chinese. Combat HUD, card hand, casting timeline, intent preview, Guard/Protect, Exposed/Break/Combo hint, terminal screen must be driven by actual Domain state/events. No literal strings baked into game widgets.
3. **Playable Gate**: execute at least one human interactive complete legal battle, screenshot/video plus EventTape compared to Headless oracle; real controller/mouse/touch/Android runs. Run M5 regression again after presenter integration.
4. **Balance/content review**: provisional HP290, hit rates, damage multipliers, card distribution, Boss strike rules are *test engineering fixtures only*. Align separate level-40 Ashfang demo `docs/combat/25`–`31` and `tools/balance/` simulation with actual Godot engine **after** approvals, keeping a side-by-side comparison.
5. **Deferred and owner-dependent rules**: Spell Counter (`P2-S15/S16`) legal post-release Reaction Window and real skill content remain blocked; Analyze/Enemy Intel (`P2-S02～S12`) separate content and long-term knowledge not verified; all-three EXHAUSTED yet all HP>0 final outcome is `CORE_RULE_EDGE_PENDING` (must never silently auto-DEFEAT). Mixed AoE and other Boss archetypes are additional integration obligations before broad commercial claims.

## Strict status reporting

- Before the 100-seed gate and full predecessor regression succeed, state **M5.5 IMPLEMENTED / VERIFICATION PENDING**. Green M5.1–M5.4 (1,081/1,081) plus a golden battle is NOT sufficient for overall M5 VERIFIED.
- Once complete, include actual code/master commit SHA, CI link, Godot version, `157/157` M5.5 new assertions if all passed, `1,238/1,238` cumulative assertions if all passed, 100 fixed seeded full battles, 4 legacy smoke runner statuses, golden tape/initial/event/final SHA256, exact ruleset/content/PRNG versions and limitations.
- Even full green M5 Headless Battle Scope does NOT mean `PLAYABLE VERIFIED` or `FULL CANON CONTENT COMPLETENESS`.
