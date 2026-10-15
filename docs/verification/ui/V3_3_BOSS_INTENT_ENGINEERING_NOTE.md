# V3.3 — Boss Header, HP/Break Framing and Public Intent

> **IMPLEMENTATION AWAITING CI**, branch `ui/v3-visual-foundation-20261015`, based on independently tested V3.2 `97816644e`. `master` and Codex-reviewed V2 remain untouched.

## Scope

Refines `EnemyStatusPanel` as a distinct boss identity heading, a restrained metallic-gold rule, compact labeled HP/Break resources, and an inset warm-tone **PublishedIntentPanel**. Styling draws from the existing `battle_visual_tokens.gd`; no new fonts, art downloads, licenses, or third-party plugins.

The panel still has the same V1/V3.1 exposed references: `boss_title`, `boss_stats`, `break_stats`, `hp_bar`, `break_bar`, `intent`; no BattleHUD, Controller or Domain API was altered.

**Read-model rules:** exact Boss current/max HP, Break gauge/max and locked/exposed flags come from the supplied projection. Missing Break gauge hides the entire BreakSection; missing published Intent hides the whole warning panel (does not invent target/attack, countdown or a protection entitlement). Existing `BATTLE_INTENT_DETAIL` supports public skill/hit count/target ids, and this layer keeps that formatting and limits to the existing first announced Intent. Full text remains in tooltip when compact line-clamp truncates. Accent color does *not* imply damage classification or AI prediction.

## Acceptance scope

- 1280×720 and 1920×1080 zh_TW / English, valid/absent Break, visible/absent public Intent, Locked and Exposed.
- True projection values control progress bars, no mutation of `Model.state_hash`.
- All labels and right-panel ornament remain inside the **existing 280×238 layout** (no resizing other components); intent label does not collide with Context.
- No lost keyboard/mouse actions: retain V3.2 card GUI 31/31, V1/V2 contract and Lv40 regression.
- Review the actual Godot screenshot against the approved art direction; no declaration of pixel-accurate fidelity without a stable user-approved reference PNG.

## Engineering note

A Compose implementation would separate an `EnemyStatus(state)` into `BossIdentity`, `BossResourceBar`, `PublishedIntent(state.publicIntent)`. A color treatment communicates urgency without replacing a reducer or inventing AI intent. Hiding the Intent panel on absent information is semantically different from showing a misleading placeholder.


## Verified execution evidence — 2026-10-15

**Status: V3.3 HEADLESS_VERIFIED / REAL_RENDER_VERIFIED / SCOPED_GUI_REGRESSION_VERIFIED. Final user visual approval PENDING.**

- Implementation source SHA: [`8fc40de8`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/8fc40de8f5ed004f309d0f797b0d196875fe896b).
- [V3.3 scoped headless CI #38748033472](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38748033472) **Success**, `V33_BOSS_REPORT executed=47 passed=47 failed=0`. Verified legacy V1-facing HUD aliases, title plate, semantics of read-only HP and Break, break absent/locked/exposed, public Intent present/absent, localized rebuilding, tooltip for clamped text, no inferred target, no change to `Model.state_hash`, and panel Control bounds at both design resolutions. Original V1, V2, V3.1/V3.2, Localization and Lv40 tests were kept unchanged and passed; strict import/error gate passed. [Raw job logs](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38748033472/artifacts/11978334409).
- [V3.1 legacy headless #38748033260](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38748033260) **Success** at the same SHA (separate existing workflow).
- [True-render screenshot CI #38748033490](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38748033490) **Success**, using official Godot 4.7.2 + Xvfb/Mesa Compatibility. Nine ordinary player/hand/locale/resolution cases: `V23_CAPTURE_REPORT executed=30 passed=30 failed=0`. Three Boss Break projection-only cases: `V31_BOSS_RENDER_REPORT executed=20 passed=20 failed=0`. PNG and strict error gates passed. [12 original PNGs + manifests](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38748033490/artifacts/11978634256).
- [Actual mouse/keyboard GUI #38748033243](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38748033243) **Success**. The existing scoped V2.5 interaction harness passed on the V3.3 production files: 8 distinct 1280 card clicks, keyboard navigation, 1920 last-card click, fixed action footer, Domain hash unchanged. [Raw GUI logs](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38748033243/artifacts/11979582912). Historical P4.4 14/16 is NOT rerun or cleared.
- Visual observation (actual Godot screenshot preview at 640×360): narrow metallic-gold Boss heading rule and inset orange Intent warning panel are distinct from dark HP/Break tracks; visible Break fixture, while the default encounter does not show Break. Public attack description remains within right enemy panel, no overlapping Context in preview. This is **qualitative inspection**, not pixel-accurate or 1280-pixel text accessibility certification. Actual screenshot oracles confirm basic geometry, not all transformed glyph bounding boxes.
- Data boundary: synthetic published `BATTLE_ATTACK`/A+B/2-hit data in dedicated *test* is display-only; true normal screenshots and Domain continue using actual encounter data. All new appearance factory colors are provisional. No actual gameplay damage, turns, target inference, Break values or Reaction rules were changed.

**Outstanding:** user approval against pinned original art reference PNG; 1280 full-resolution font clipping review, semantic color choices, potential compact display of longer multiple-public-intent lists (V3.3 preserves prior first-published-intent behavior rather than redesigning combat scope); subsequent V3.4 Hero/Command UI and V3.5 high-fidelity sign-off. Branch remains isolated from Codex's V2 review and new master CI.
