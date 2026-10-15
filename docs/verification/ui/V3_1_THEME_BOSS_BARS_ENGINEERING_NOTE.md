# V3.1 — Battle Visual Foundation and Boss Resource Bars

> **Source implementation / NOT VERIFIED until CI** (2026-10-15). Isolated branch `ui/v3-visual-foundation-20261015`, based on V2 candidate `822b1ce6d573cad6634b11c161634d5360eda456`. No write to Codex-reviewing V2 branch or master.

## Design decisions

- Extends the existing canonical `resources/ui/battle_theme.tres`: subdued dark-navy translucent panel, restrained metallic-gold stroke, cyan keyboard/hover focus, pressed, disabled styles, readable font colors and shared ProgressBar track/fill. All values are **provisional visual tokens** from `docs/ui/BATTLE_UI_DESIGN_SYSTEM.md`; final reference PNG/pixel match not yet approved.
- Introduces `scripts/battle/ui/components/battle_visual_tokens.gd` only for semantic accents (HP vs Break). Uses standard Godot `StyleBoxFlat` — no new plugin and no unlicensed asset import.
- Refactors `EnemyStatusPanel` contents to distinguish `BossHPBar` (HP) and `BossBreakBar` (M5 tactical gauge). Keeps V1 public aliases `boss_stats`, `intent`, `boss_title`; adds `break_stats` and bars. Values and visibility derive **exclusively** from projection/Domain, not from timers or a guessed percentage. Safe max=1 for zero totals, values clamped only for rendering.
- Keeps real published Enemy Intent with actual names/targets; removes unconditionally visible "protect available" teaser because it could imply an ability without a legal Domain response.
- Does **not** change `BattleScreen`, `BattleController`, `scripts/domain/`, `CardAppearance`, Hero assets, or fight results. Card gold/hover remain V2; V3.2 will address frame family/art consistency separately after V3.1 screenshots.

## Required CI and visual gate

1. Godot 4.7.2 strict import + existing P4/V1/V2 suites without oracle weakening, plus new V3.1 visual style/readmodel test.
2. True Compatibility renderer screenshots at 1280/1920, zh_TW/en, plus a fixture with Break visible and unavailable; inspect Boss HP/Break labels, separation, clipping and Intent.
3. Preserve original Domain state hash before and after UI-only rendering. Ensure Break gauge is **not** confused with Casting Stability or Barrier.
4. No high-fidelity claim until approved concept PNG is pinned, licensed asset choices reviewed, actual screenshot differences assessed and user accepts visuals.
5. V2 merge/review boundary: after Codex approves and integrates V2, compare and selectively rebase/cherry-pick V3 changes. Never overwrite master CI or V2 programmatic HUD changes.

## Learning (Android analogy)

This is a **Design System Token/Theme** separation. A Godot `Theme` plays the same role as a Compose MaterialTheme; a locally overridden ProgressBar fill serves semantic color for an individual status. Its display must subscribe to read-model state, not introduce a parallel reducer or data transaction.

