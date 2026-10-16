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
