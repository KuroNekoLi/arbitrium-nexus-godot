# V2.4 — Hand UI Visual / Regression Evidence (2026-10-15)

> **Status: HEADLESS VERIFIED + REAL_RENDER CAPTURE VERIFIED / POINTER-ACCESSIBILITY AND FULL V2 VISUAL GATE STILL PENDING.** Branch: ui/v2-layout-fidelity-20261015.

## Implemented

- Empty state: stable full-rect Label with centered, non-wrapping, translated text in HandView. Actual 1280 zh_TW screenshot now displays a horizontal empty-hand message instead of vertical characters.
- Fan: SimpleCards ArcShape retained, radius and arc revised for a visible fanning layout. All eight distinct CardInstanceIDs remain in the actual hand; the cards do overlap by design to fit the 686px width. Hover/focus raises and enlarges the visual face above siblings, providing an inspection affordance; **do not claim every title is simultaneously readable without interaction**.
- Selection: BattleScreen keeps authoritative pending card ID. A presentation-only hud.set_selected_card() updates HandView.selected_instance and BattleCardView face. The selected face has gold highlight, elevated z-index, approx 38px face lift and 1.055x scale, while the Card root maintains SimpleCards hit rectangle/drag. Cancelling clears selection; re-rendering preserves it only for a still-present instance.
- No changes to Domain, Card zone ownership, mana/action costs, boss AI or combat rules.

## Authentic CI receipts

1. **V2.4 code:** commit [91d4c36a](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/91d4c36aecdb066b603f09ecc801cfd888c62bc8).
2. **Real renderer:** [GitHub Actions #38736209253](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38736209253) completed/success on code commit 91d4c36a. Godot 4.7.2/Xvfb Compatibility Renderer, nine original PNGs. Original artifact: [v23-screenshots, ID 11974136142](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38736209253/artifacts/11974136142). The unchanged V2.3 capture suite executed 30/30 assertions, verified PNG signatures, decoding/dimensions and strict Godot Log Gate.
3. **First V2.4 headless:** [#38736209274](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38736209274), failed due to ONE test checking one-card center while a legacy 0.18s transition tween was still running. The other 38 checks passed, including 8-card uniqueness and all eight presentation-selection IDs. The screenshot of the settled 1-card pose showed it correctly centered.
4. **Second V2.4 headless:** [#38736799268](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38736799268), completed/success at commit [b54fe6b3](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/b54fe6b3be61cedadd84a16ccaf36c3569ce64ef). Test-only fix: wait 0.22s to measure the same existing 0.18s transition; no reduction of the actual center-distance assertion. **V24_HAND_REPORT 39/39**. Also passed: P4 Scene 8/8, HUD 36/36, V1 components 24/24, V2.1 layout 18/18, V2.2 context/log 23/23, P4 integration 31/31, Localization 198/198, Lv40 playable integration 32/32. Strict Godot Log Gate reported zero errors on these tests.

## Visual comparison: original Godot pixels, not AI mockup

Comparison prepared from the complete previous V2.3 [Run #38733719215](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38733719215) and the V2.4 [Run #38736209253](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38736209253). The side-by-side image `v24_visual_before_after.png` has been saved to the user's ChatGPT Library; original PNGs remain in GitHub Actions artifacts.

| Test case | Previous V2.3 observation | New V2.4 observation | Assessment |
|---|---|---|---|
| 0-card idle, 1280 zh_TW | Vertically wrapped single-character text at x≈center | Horizontal centered `目前沒有手牌` | **Fixed visually** |
| 8-card idle, 1280 zh_TW | Flat, extremely compact overlap, hard to distinguish individual art/names | Clear arcing fan; exposed card tops and distinct silhouettes, one card can be elevated in Focus/Selected state | **Improved; still partial overlap by design**, no actual mouse/pointer reachability proof |
| 4-card selected, 1280 zh_TW | Preview text changes but card itself remains in flat row | Selected card noticeably lifted and gold highlighted, enlarged in front | **Fixed visually** |
| 1-card idle | Existing centered rendering, prior unit check measured transitional position too early | Actual settled screenshot remains centered; post-tween unit check passes | **No UI regression** |
| 1280/1920 / zh_TW/en | Correct baseline screenshots | Nine screenshot cases still pass through real renderer | **Render smoke passed, not full user acceptance** |

## Known remaining gates

- Actual pointer/keyboard traversal of *every* one of the eight overlapping cards is **not independently GUI-tested**. Headless checks ensure all eight have focus mode and UI selection works for every ID, but do not simulate overlap hit-testing.
- ActionDetails Context footer preference layout still visually dense (P1 from V2.3). Boss HP/Break presentation, ornate Theme, card art variety and original style-guide fidelity belong to V2.5/V3, not a Domain modification.
- The historic P4.4 GUI input suite failed 14/16 and retains its original rerun limit. **Do not relabel new V2.3 screenshot CI as P4.4 clearance.**
- No source reference mockup PNG has yet been pinned to the repo, so final full-fidelity matching cannot be claimed.
- Do not merge this branch to master before appropriate human approval and independent GUI interaction review. The workflow files for this UI branch are branch-scoped and need rationalization against the latest master CI before merge.

## Learning — Compose analogy

Treat the UI selected card as a Compose `rememberSaveable`-style view state keyed by **CardInstanceID**, distinct from the authoritative battle reducer state. A re-render may recreate all CardView nodes, but the selected ID can re-apply visual styling to the correct view. The Action pipeline still enters through BattleScreen/Controller; a glow never causes another transaction.
