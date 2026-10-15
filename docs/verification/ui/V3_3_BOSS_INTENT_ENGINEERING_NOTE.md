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

