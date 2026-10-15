# V2.2 — Action Details and Battle Log Split (2026-10-15)

> **IMPLEMENTED / ENGINE TEST PENDING**, scope `ui/v2-layout-fidelity-20261015`. Review and run actual Godot 4.7.2 CI before promotion.

## Design and implementation

- Original `Context` held preview, Chantless/Full, Combo, Confirm/Cancel, Feedback, reduced-motion controls and Battle Log in the same scroll region. This put critical confirmation controls at risk of being scrolled offscreen.
- `ActionContextPanel` now owns a `DetailScroll` containing preview, casting/Combo and presentation settings. A sibling `ActionButtons` row and feedback stay outside the ScrollContainer. Existing `confirm_requested`, `cancel_requested`, `command_requested` signals are unchanged.
- New independent `BattleLogPanel` scene + script owns a local label and scrollable three-line log display; `BattleHUD.log_label` is a **compatibility alias** pointing at that same label. `BattleScreen._on_resolved` is deliberately unchanged.
- `BattleHUD._context` is now (984,348,280,220) and `BattleLogPanel` is (984,580,280,118), leaving a 12px vertical gap. Left `CommandMenu` is (16,432,248,266); its scene and game commands remain unmodified; three-person roster stays at (16,98,260,318).
- No card cost/target/reaction logic, domain, fixtures or i18n dictionaries were modified. The SimpleCards hand is unchanged from V2.1.

## Testing & review

- Additive `tests/test_p4_v2_context_layout.gd`: test independent log ownership, sticky Confirm/Cancel, safe rectangles, preview hash unchanged, facades and locale reconstruction, 1280/1920.
- Preserve `test_p4_v2_layout.gd` 18/18, V1 Component Contract 24/24 and P4 base suites without weakening them.
- **Headless tests are not proof of render fidelity.** Need visual PNG comparison in true Godot at 1280/1920 and both locales, plus input/focus test for scrolling action details while Confirm remains operable.
- Original P4.4 GUI 14/16 failure remains recorded, not rerun or relabelled.
- Use latest canonical `master` CI workflow on eventual merge; do not overwrite other agents' newer CI optimization.

## Engineering learning

This decomposition maps to Compose's `Column { LazyColumn(weight(1f)) { preview }; ConfirmRow(); Feedback() }` with a separate `BattleLog` view. Keeping `hud.log_label` as a facade is the migration-friendly step: callers remain stable while the child owner changes. Unlike `LazyColumn`, a Godot `ScrollContainer` owns input and may affect focus traversal; true mouse and keyboard verification remains necessary.
