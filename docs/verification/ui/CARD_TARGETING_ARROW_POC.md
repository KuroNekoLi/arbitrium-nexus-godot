# Card Targeting Arrow — isolated POC

Branch: `poc/card-targeting-arrow-20261016`, baseline: `master@50bf7b19b2f9c3d66c1a8cd267bd20ef7f56b4cd`.

## Open-source evaluation

- [TargetingArrow2D](https://github.com/antoinecharruel/TargetingArrow2D) (MIT, Godot 4.5): Bézier + Sprite2D chain, but requires head/node textures and plugin setup.
- [CurvedArrow2D](https://godotengine.org/asset-library/asset/3600) (MIT, Godot 4.3): ready-to-use curved drawing node with configurable outline; must verify 4.7.2.
- [Godot Slay the Spire Clone](https://github.com/acyu9/Slay_the_Spire_Clone) (MIT): reference state machine for card dragging/aiming/release.

**Decision for this experiment:** implement a small native Control `CardTargetingArrowOverlay` inspired by the arrow geometry, without importing assets or replacing SimpleCards. This avoids an additional addon/texture dependency and preserves the complete existing drop/click contracts. Source implementation is original, not a copy of external source; linked repositories are implementation references.

## Scope and interaction

- Real SimpleCards `drag_started` signals through `BattleCardView → HandView → BattleHUD → BattleScreen`.
- Drag begins → existing `select_card(instance, false)` computes the **real** legal target set → overlay draws a cubic Bézier trail, head and subtle reticle while mouse moves.
- Hover inside an existing legal `TargetHitRegions` rectangle → tip snaps to its center; illegal targets never snap.
- For Full Chant hold, legality refreshes through the existing Domain preview; overlay itself never checks AP, MP, target kind, or changes game state.
- Existing `_drop_card()` remains authoritative for release & confirmation. Cancelling, modal state, empty hand, illegal card, and release hide the overlay without consuming resources.
- No change to Core Domain, CardInstanceID, Last Spell activation/confirmation, existing keyboard selection or SimpleCards addon.
- Overlay uses `mouse_filter = IGNORE`, no focus and design-space `Control` coordinates. Physical Xvfb mouse-to-canvas conversion remains owned by the existing GUI testing layer.

## Test expectations

Strict Godot 4.7.2 import; new scoped headless geometry/contract tests and true GUI drag test at logical 1280/physical 1920, along with existing V25 31/31 GUI card tests and project CI Fast. Publish screenshots/recording only if genuine Godot rendering is verified.

This branch must remain separate from master until design approval and CI confirmation.


## Verified result (2026-10-16)

Implementation source: [`e985ec88`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/e985ec888cc441dfb8dd54004dc01e0b0625b920), on dedicated `poc/card-targeting-arrow-20261016` branch. The feature originates from `master@50bf7b19b2f9c3d66c1a8cd267bd20ef7f56b4cd`. No `scripts/domain/`, `addons/simple_cards/` or `master` changes.

**CI: [GitHub Actions #38880082729](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38880082729) — completed/success, both jobs.**

- Godot 4.7.2 strict headless import and log gate: zero script errors.
- `TARGET_ARROW_REPORT executed=26 passed=26 failed=0` (legal target filtering, cubic curve control points, no input interception, cancellation, true CardInstanceID, Domain state-hash immutability).
- Legacy component `V1_COMPONENT_REPORT 24/24`, `P4_2_REPORT 36/36`, `V2_LAYOUT_REPORT 18/18`.
- `TARGET_ARROW_GUI_REPORT executed=19 passed=19 failed=0` **real X11 mouse drag**, target snap, release, unchanged Domain hash at both 1280×720 and 1920×1080, two real Godot Compatibility Renderer screenshots `arrow_1280.png` and `arrow_1920.png`.
- `TARGET_ARROW_HAND_REPORT executed=23 passed=23 failed=0`: 8 card-instance mouse clicks, 8 keyboard selections, no unwanted aiming overlay on normal selection, 1920 window last-card hit test, no Domain write. Test is scoped to unaffected card interactions.
- [Original genuine Godot PNGs and mouse logs (artifact 12037350913)](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38880082729/artifacts/12037350913); [Headless raw logs (artifact 12036763808)](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38880082729/artifacts/12036763808).

### Historical GUI regression scope (not misrepresented)

The unmodified `tests/test_p4_v25_gui_input.gd` was additionally invoked in an earlier POC CI attempt [#38879215128](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38879215128). It passed 8/8 real card clicks and 8/8 keyboard selections, then failed because it still assumes `Context/@VBoxContainer/PreferencesDisclosure` and `DetailScroll/.../PreferencesContent` exist at their **old positions**. The current master HUD moved the disclosure to the TopBar and preferences into its own panel. Those stale paths are unrelated to aiming; the POC neither edits nor claims to have cleared that historical GUI script. The replacement **focused** input suite has no assertions about the relocated preferences UI and therefore does not supersede a future dedicated preferences-modal regression.

### Remaining checks before merging

1. User visual approval of exact arrow thickness, glow, reticle and snap feel against screenshots.
2. Multi-enemy `EnemyActor` and ally-target anchors must be integrated dynamically when that arena work lands. The POC uses the current `TargetHitRegions` (Boss/A/B/C), not fake enemy targets.
3. Verify drag-and-drop submission against legal targets on a separate gameplay integration test. These isolated GUI tests deliberately release over empty space to avoid mutating the game, and do not claim that all card costs/Full Chant/Last Spell cases are fully exercised end to end.
4. If approved, evaluate cherry-picking into the reviewed branch after checking master drift and the historical V25 preferences test; do not automatically merge or overwrite master.

