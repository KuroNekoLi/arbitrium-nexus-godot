# V1 — Battle HUD component extraction

> **IMPLEMENTED / NOT EXECUTED / NEEDS CODEX REVIEW AND GODOT GATES**. GitHub source branch `ui/hud-visual-refactor-20261015` originally forked from `master@5103e40a4b95da82f2561b29c2604e9514fd398b`. This is a source implementation report, **not** a claim of executable validation.

## Changed architecture

- `scripts/battle/ui/battle_hud.gd`: composition facade, forwarding the same eight external Signals, `render(projection, actor, cards, reaction_choices)` and `set_targets(ids)`.
- New reusable `.tscn` roots with their own presentation scripts: `TopBar` (TeamPhaseHeader), `PartyStatusPanel`, `Commands`, `EnemyStatus`, `Context`, `HandView`, `TargetHitRegions`, `ReactionQueue`.
- `ui_elements.gd`: only label/button/column creation. Scene internals remain built in `_ready` for V1; V2+ may serialize subnodes as needed. This is **not** a claim of high-fidelity visual quality.
- Existing `HeroRosterItem`, `BattleCardView`, `SimpleCards ArcShape`, Theme, Appearance Resources, rectangles and i18n remain in use; no changes to approved combat rules.
- Legacy `BattleHUD` fields used by `BattleScreen` and P42/P43 are forwarded: `card_views`, `hand`, `roster`, `end_button`, `details`, `feedback`, `mode`, `combo`, `confirm_button`, `log_label`, `target_buttons`, `reaction_panel`, `reaction_column`, `header`, `resources`, `boss_stats`, `intent`, `vm`, `selected`, `conditions`.
- ReactionQueue retains manual Confirm/Pass ordering, including original last-child Pass button assumption used by `tests/test_p4_input_capture.gd`.
- Existing `battle_screen.gd` and existing test oracles are **not rewritten**; new `tests/test_p4_component_contract.gd` is additive.

## Required review

1. Inspect `PackedScene.instantiate()` + `_ready()` lifecycles, typed `Control` members and signal forwarding. Ensure all refs exist before the first `BattleScreen.present()`.
2. Confirm the HandView's `card_views` reference alias after `clear()`, 0/4/8-card replacement, rotation bounds, drag/hover/click/release and no extra Domain transaction.
3. Confirm `TargetHitRegions` invisible overlay and legal target mouse event handling. Test real 1280×720 and 1920×1080 drag/drop.
4. Confirm locale rebuild of HUD, references and signals (zh_TW ↔ en), reaction draft row order, Focus and no implicit Pass.
5. Inspect active master/P4.4 Lv40 WIP diffs. This branch is based on the master P4.3 UI and intentionally does **not** cherry-pick unfinished P4.4 Result/scroll/reaction additions.
6. Report Godot4.7.2 parse/output, QA test names and IDs, CI links, test retry counts, screenshots, and raw logs; **do not label VERIFIED without executing**.

## Tests to execute by Codex

- `tests/test_p4_component_contract.gd` (new, NOT RUN).
- `tests/test_p4_scene.gd`, `tests/test_p4_hud.gd`, `tests/test_p4_integration.gd` (existing, NOT RERUN).
- Applicable GUI input `tests/test_p4_input_capture.gd` only under QA policy and existing P4.4 retry restrictions; do not bypass/relabel existing P4.4 failed 14/16 gate.
- Run relevant Domain/Replay smoke and collect true Godot runner return codes and evidence.

## Engineer learning note

This is a **Strangler Fig / Facade migration**: legacy `BattleScreen` continues calling the same API while individual scene-owned Controls take over presentation and their own child nodes. It parallels moving a monolithic Android Custom View into reusable Compose/View subcomponents while retaining a stable callback interface. A UI component handles rendering and input intents, not the authoritative battle reducer.
