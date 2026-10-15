# V2.3 — Real Godot Screenshot / Visual Fidelity Review

> **2026-10-15 | REAL_CAPTURE_VERIFIED / VISUAL_NEEDS_REVISION**. This is a rendered review, NOT P4.4 input-GUI acceptance or V3 Art acceptance. Reviewing commit: `c05b82ef6494d875873c630c31679d21e99d3886`.
>
> Runtime: official **Godot 4.7.2**, X11 via Xvfb, Mesa software-rendered Compatibility viewport; original PNGs (not AI-generated) recorded by `tests/capture_p4_v23_layout.gd` and `scripts/qa/screenshot_writer.gd`. No change to Gameplay Domain.

## Source and evidence

- [Successful renderer CI #38733719215](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38733719215) · first CI for Dummy audio correction, **completed/success**, `V23_CAPTURE_REPORT executed=30 passed=30 failed=0`. Official import and strict job-log error check both passed; only expected virtual-display V-Sync warning remained.
- [Nine original PNGs, thumbnail, manifest and raw logs — artifact #11970879615](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38733719215/artifacts/11970879615) (14-day Actions artifact retention). PNG decode + exact 1280×720 or 1920×1080 dimensions validated for all cases. See run-scoped manifest `v23_38733719215_1/v23_capture_manifest.json`.
- Historical [first CI #38733469958](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38733469958) failed **strict log policy** because Xvfb had no ALSA device (Godot `ERR_CANT_OPEN`), even though screenshots passed 30/30. Added `--audio-driver Dummy`; **did not** weaken log gate or alter Domain/test fixtures.
- Reference concept: chat-local user image `星淵之戰_玩家階段.png`, 1672×941, SHA-256 `f1892eab3e5d01631c7959a5466862770bb0e56ae1962c6fa9034f72296a1673` (verified from original provided image). The PNG file itself **is not committed**, so this is a visually reviewed reference, not a repository-pinned automated golden-image comparison. Art characters/card texts from the concept **are not** Gameplay canon.

## Exact scene captures (all nine)

| Screenshot file | Purpose | Evidence |
|---|---|---|
| `v23_idle_1280_zh.png` | Player idle / 4 cards / zh_TW | Independent AP, phase, utility header & side panels |
| `v23_idle_1920_zh.png` | High-resolution zh_TW | Viewport stretching, sidebar text |
| `v23_idle_1280_en.png` | English 1280 | Long labels and command row |
| `v23_idle_1920_en.png` | English 1920 | English sizing and sidebars |
| `v23_selected_1280_zh.png` | UI-selected SP | Preview updated; raised/highlight card is missing |
| `v23_hand8_1280_zh.png` | Full hand / 8 cards | Severe card overlap, most content hidden |
| `v23_hand8_1920_en.png` | 8 cards / English | Same usability issue at scale |
| `v23_hand1_1280_zh.png` | 1 card | Card centered, remains inside design bounds |
| `v23_hand0_1280_zh.png` | Empty hand | **Defect**: empty-label becomes vertical Chinese text |

## Measured reference geometry, from V2.3 real manifest (1280×720 zh_TW)

| UI component | Actual global bounds x,y,w,h | Observation |
|---|---|---|
| TopBar | `16,12,1248,64` | Root transparent, 3 internal islands; approved split |
| PartyStatusPanel | `16,98,260,318` | 3 cards stack, no second character switch strip |
| Command Menu | `16,432,248,266` | Remains separated from HandView |
| EnemyStatus | `984,98,280,238` | HP and Intent still plain text |
| Action Context | `984,348,280,220` | Preview visible, preference controls crowd the fixed footer |
| BattleLogPanel | `984,580,280,118` | Independent but a mostly empty, opaque panel |
| HandView | `290,470,686,240` | 4 cards near bottom; arc too subtle |
| Confirm Button | `996,495,40,38` | Inside Context and technically visible; near scroller controls |

Measurements are from Godot `get_global_rect`; rotated card polygons and actual pointer coverage require separate input/focus validation.

## Visual evaluation (0–4, reviewer-assessed, not user-approved)

| Dimension | Score | Rationale |
|---|---:|---|
| Spatial layout | **3/4** | Left/center/right layout, independent top islands and battle visibility largely match design direction |
| Hand presentation | **1/4** | Almost flat 4-card row, **8-card obscuration**, no selected-card lift; empty state broken |
| HUD visual language | **1/4** | Plain navy Godot rectangles and unthemed command buttons versus ornate thin glowing reference; planned V3 Theme |
| Typography / localization | **2/4** | English 1920 normal labels render; Chinese empty state wraps vertically and settings controls crowd |
| Information hierarchy | **2/4** | AP/phase clear; Boss HP/Break visual bars & separate Intent hierarchy still missing |
| Interaction feedback | **1/4** | Selected card does not visibly stand out, scroll-and-confirm click safety not yet input-tested |
| **Total** | **10/24** | **NEEDS_REVISION**. V2 exit requires Spatial/Hand/Hierarchy each ≥3 and mandatory layout behavior PASS |

These are review judgments against the target design direction, not pixel-distance metrics or a final usability study.

## Prioritized actionable defects

| Priority | Defect / file | Required correction & gate |
|---|---|---|
| **P0 V2.4-01** | **0-card vertical text**: `scripts/battle/ui/components/hand_view.gd` adds a `Label` to the `Control` without an allocated `size` or horizontal alignment | Implement a center-aligned empty-state label constrained to HandView; assert font bounding box and 1280/1920 screenshot no vertical wrap. Keep no hand-count text |
| **P0 V2.4-02** | **8-card unreadable overlap**: `HandView._arrange_hand()` arc nominal min step ≈71px but cards are ≈164px wide | Preserve all 8 instances/targets, use adaptive fan spacing + clear focused-card elevation/foreground. Mouse/keyboard must reach EVERY playable card, including overlaps. No arbitrary hiding/deck-cap change |
| **P1 V2.4-03** | **Selected card not raised / highlighted**: `BattleCardView` and `HandView` do not expose selected instance to a persistent visual state; `BattleHUD.render` resets card instances | Pass selection identity from `BattleScreen` via a UI-only contract; add elevated state without duplicating payments or changing gameplay. Check selected + cancel + locale rebind + Drag |
| **P1 V2.4-04** | **Settings/footer congestion**: `action_context_panel.gd` has preferences inside `DetailScroll` competing visually with pinned `ActionButtons` | Use compact preferences disclosure or utility area, maintain `reduced_toggle`/`mute_toggle` façade; real scroll + focus + mouse click tests, no lost Confirm/Cancel |
| **P1 V3** | Flat card frames, command buttons, over-wide opaque Log background, Boss HP/Break absent as distinct visual bars | After V2 geometry is safe, apply Godot Theme, NinePatch and asset pipeline; do **not** fake Boss data or bake text into static art |

### Secondary observations

- The 4-card capture shows repeated `破綻斬擊` artwork. This is **fixture/content selection**, not evidence that card-instance IDs collide; UI refactor must not invent/replace Gameplay cards to match concept artwork.
- No extra hand-count/deck/discard or fixed action-order panel was observed in the real 4-card screen. Reaction Queue is contextual and is not prohibited.
- V2.3 captures are image-only; there was **no mouse/keyboard test, no reattempt of historical P4.4 14/16**, and no verification of modal focus leakage or cards being clickable when overlapped.
- Original user concept image is ≈16:9 (1672×941); for qualitative 1280×720 comparison it should be uniformly resized or letterboxed to preserve aspect ratio. The character art and names are intentionally different.

## Next engineering gate

**V2.4 targeted UX/layout repair** on `ui/v2-layout-fidelity-20261015`: fix P0 empty hand, 8-card discoverability/accessibility and selected-card elevation, then fix Context footer clipping. Keep the existing V1/P4/V2.1/V2.2 test oracles intact; add new geometry/renderer screenshots and necessary focused input tests *without relabelling* old P4.4. Re-run branch-scoped true-render capture with SHA evidence and review side-by-side. Do not merge to master or mark full V2 Visual VERIFIED until those defects are resolved and user approves.
