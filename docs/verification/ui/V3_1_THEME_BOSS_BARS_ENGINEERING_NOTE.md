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


## Real CI receipts — 2026-10-15

**HEADLESS_VERIFIED + REAL_RENDER_VERIFIED for V3.1 scope.** This does not certify V3 as a finished commercial art release.

1. [Godot V3.1 Headless #38741223147](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38741223147) ran against implementation SHA `5ae9c7a08613ea473412bf4e8e83cfb33831d261` with **31/31 V31_VISUAL_REPORT PASS**. Also passed unmodified: Scene 8/8, P4 HUD 36/36, V1 Component 24/24, V2.1 Layout 18/18, V2.2 Context 23/23, V2.4 Hand 39/39, P4 Integration 31/31, Localization 198/198, Lv40 Playable 32/32. Godot import and each strict log had zero errors.
2. [Normal true-render #38741497546](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38741497546) produced the existing **nine** Godot 4.7.2 Xvfb/Mesa Compatibility screenshot states at 1280/1920, zh_TW/en and 0/1/4/8-card variants: `V23_CAPTURE_REPORT executed=30 passed=30 failed=0`.
3. [Dedicated Boss Break true-render #38742019804](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38742019804) ran at SHA `84dd52296b9a2409ea991b9810d362366b608252`: both the nine default screenshots **30/30** and three Break-scenario rendered screenshots **20/20** passed strict PNG decoding and Godot logs. [Original PNGs, manifest and runner logs (artifact #11976377981)](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38742019804/artifacts/11976377981) are retained for 14 days.
4. The three special Break screenshots (`v31_boss_break_1280_zh.png`, `v31_boss_locked_1280_zh.png`, `v31_boss_break_1920_en.png`) are **explicit projection-only MOCK fixtures** for presentation geometry. They never modify the Game Domain, real Break Gauge, BattleController or accepted combat commands.
5. I visually inspected the in-run 640×360 JPEG previews: the revised navy/gold theme renders throughout the HUD; Boss HP red fill, Break gold fill and public Intent occupy distinct lines within the enemy panel. Screenshot fixture assertion also checks the Intent Label global bottom stays within the panel rectangle. This is evidence of general placement, not exact text pixel-fitting or pointer GUI testing.
6. The real-render log emitted the graphics-driver V-Sync unsupported warning under Mesa/Xvfb, but **no script/import errors**. Strict error detection was preserved (no blanket ignore or altered test oracles).

**Review status: V3.1 implementation accepted by automated headless and renderer gates; final visual style requires user approval.** Outstanding: high-fidelity card frame/art family, Boss status ornaments and thinner typography hierarchy, long locked/exposed labels and narrow-viewport text overflow, hand selected/card art polishing, and reference image pinned into durable repo storage with hash. **V2 remains under independent Codex review.** This V3 branch is isolated and not merged into master. Do not copy an unreviewed V2 HUD wholesale over reviewed code; reconcile by selective integration once V2 is approved.
