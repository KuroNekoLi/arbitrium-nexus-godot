# V2.1 Battle UI Layout Fidelity — Engineering Note

> 2026-10-15 — **IMPLEMENTED_NOT_VERIFIED / REAL GODOT TESTS PENDING**.
> Source: `ui/v2-layout-fidelity-20261015` branched from `master@1c8b212f3245cd221f4efe09441af250926c392f`.

## Purpose

Implement **V2 layout slice 1**, not V3 art, based on `docs/ui/BATTLE_UI_DESIGN_SYSTEM.md` and `BATTLE_UI_VISUAL_ACCEPTANCE.md`. All dimensions are **1280×720 design-space candidate measurements**, not pixel-accurate verified target bounds. Target PNG hash is not yet pinned in this repository.

## Code scope / details

- `team_phase_header.gd` and matching scene root change from one wide solid PanelContainer to transparent `Control` named **TopBar**, which owns three narrow independently styled panel islands: `ResourcePanel` (AP/RP), `PhasePanel` (player/enemy phase and round), `UtilityPanel` (EN/繁中/Save Replay). Keeps existing phase/resources Label references, signals and named TopBar height=64.
- `battle_hud.gd` retains existing V1 façade and unchanged external signals; adjusts candidate Rects for party/commands, enemy/context, and shifts `HandView` from (292,458,680,246) to **(290,470,686,240)**, bottom design y=710, near 10px canvas inset. Existing SimpleCards ArcShape and `HandView.card_views` still own all card transforms; no UI-owned card costs/targets.
- Large always-on `Conditions` is now narrower at (312,98,640,36) and only shown if the *selected* actor has a real HP barrier, Guard or active Cast. Full string remains available in the label tooltip, and roster status remains visible; no Domain state is modified.
- Boss and Context regions remain separated and mostly unchanged. This stage intentionally **does not** redesign/tear apart ActionContext, ReactionQueue, card artwork or Theme; V2.2 may target Log/Details separation after real screen measurement.

## Candidate coordinates

| Element | x | y | width | height |
|---|---:|---:|---:|---:|
| TopBar composition | 16 | 12 | 1248 | 64 |
| Resource island (relative to TopBar) | 0 | 0 | 310 | 64 |
| Phase island (relative to TopBar) | 400 | 0 | 402 | 64 |
| Utility island (relative to TopBar) | 930 | 0 | 318 | 64 |
| Conditions | 312 | 98 | 640 | 36 |
| PartyStatusPanel | 16 | 98 | 260 | 318 |
| Commands | 16 | 426 | 260 | 274 |
| EnemyStatus | 984 | 98 | 280 | 238 |
| Context | 984 | 348 | 280 | 356 |
| HandView | 290 | 470 | 686 | 240 |
| ReactionQueue | 300 | 154 | 665 | 305 |

## Acceptance and verification

- New **`tests/test_p4_v2_layout.gd`** adds layout and state-hash checks; **not run yet**.
- Retain previous suites: `test_p4_component_contract.gd` (24 assertions), `test_p4_hud.gd` (36), `test_p4_scene.gd` (8), `test_p4_integration.gd` (31). Preserve original oracles.
- Capture true running screen at 1280×720, 1920×1080, zh_TW/en, and 0/1/4/8 hand states; compare each region with the **approved reference PNG** once pinned. Confirm TopBar labels/tool buttons don't overrun their island; the 8 rotated cards remain wholly visible; Reaction Queue remains click-safe.
- Existing P4.4 GUI 14/16 screenshot-run restriction remains. New scoped V2 layout test is separate, **not a relabeled rerun** of that existing input suite.
- CI and real Godot are unverified at this writing. Headless geometry alone does not establish visual fidelity or human playtest.
- No change to `scripts/domain/`, Card cost, combat specs, `battle_screen.gd`, or rendering engine.

## Reviewer instructions

First confirm SHA, then run strict 4.7.2 import/headless parser and the above tests. Any failure: fix on **this V2 branch**, commit targeted correction, record raw test/log/run evidence. Do not merge until V2.1 regression is green. After evidence, capture screenshots and report five largest mismatches before V2.2.

## Learning — Compose analogy

The V1 wrapper is analogous to a Compose screen composed from stateless subcomponents. V2 adjusts the **layout modifiers** without touching ViewModel state or navigation actions: breaking a full-width header into independently positioned islands corresponds to replacing a single oversized Row background with separated `Box` groups, while the controller and business-logic callbacks stay unchanged.
