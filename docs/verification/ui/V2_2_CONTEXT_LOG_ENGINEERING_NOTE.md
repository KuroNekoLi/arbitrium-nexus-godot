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

## V2.2 CI evidence (authoritative receipt)

- **Scope:** Godot 4.7.2 headless source contract regression only; GUI rendering fidelity and original P4.4 GUI input remain **NOT VERIFIED**.
- Tested SHA: `e7f22221c13ac9bef211d6eaf9b2e8d885bb0ab9`.
- Successful Actions: [Run #38731749684](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38731749684), first run of corrected expectation, `completed/success`.
- `V2_CONTEXT_REPORT executed=23 passed=23 failed=0` and `V2_LAYOUT_REPORT executed=18 passed=18 failed=0`.
- Preserved: `V1_COMPONENT_REPORT 24/24`, P4 Scene 8/8, P4 HUD 36/36, P4 Integration 31/31, P4 Feedback 45/45, Feedback Edge 80/80, Lv40 positive 32/32, Screenshot Writer 46/46, Localization 198/198, ReadModel 29/29. No `SCRIPT ERROR` was reported in GitHub Actions Job Log.
- Historical first V2.2 job [#38731545566](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38731545566) failed due to CI **expecting 21** assertions while the new suite actually executed **23/23 PASS** (two cases execute at two resolutions). The follow-up changed only the expected CI count, did not modify the test source or weaken original oracles. Previous failure stays documented.
- Headless test cannot validate scroll gestures, mouse focus, card selection animations or pixel-level fidelity. Approval of visual reference PNG and fresh Godot screenshot comparisons remain outstanding.
- New documentary or CI-alignment commits after the tested SHA do not mean the test was rerun.
