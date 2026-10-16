# V3.4 — Hero Roster & Command Visual System

> 2026-10-15 Codex整合補記：以下為來源分支歷史收據，不代表最新master的GUI驗收。共用元件另修正legacy翻譯初始化錯誤；最新89871c9正式Master Fast/Full/Render全success，GUI未重跑。合併收據已清除；GUI／真人使用狀態以現行待驗收清單及專項視覺驗收紀錄為準。

> **IMPLEMENTED / CI PENDING**. Branch `ui/v3-visual-foundation-20261015`; based on V3.3 reviewed source `85d5c64b396145beca43153d66c644ab2497a269`. `master` and Codex-reviewing V2 remain unmodified.

## Objective and changes

- Keep the three real HeroRosterItem buttons, existing Kenney border + portrait sprites, and actor switching via `hero_selected` unchanged. Visual variants for selected/hover/focus are generated from `battle_visual_tokens.gd`; keyboard focus has a real visible cyan outline, not an empty StyleBox.
- The hero HP/MP have independent named **HeroHPBar / HeroMPBar** ProgressBars directly below their matching text labels within `Layout/Stats`, not tiny bars nested *inside* labels. Exact labels and bar values come from the existing actor projection, with safe zero max clamping only for the bar; HP green, MP blue. Legacy `update_status(hp,max_hp,mana,max_mana,hand_count)` signature remains positional-compatible but does **not** display a prohibited hand/deck counter.
- Command Menu retains the same Basic, Analyze, Item, Free Swap, Last Spell and End Player Phase controls and emits their **unchanged command names and field dictionaries**. Adds reusable control styles, hover/focus/pressed variants and a decorative input-transparent semantic accent rail. Utility placeholders are NOT presented as newly implemented gameplay. `hud.end_button`, language strings and disabled-in-enemy-phase behavior remain unchanged.
- No new art pack, font import, Godot plugin or Theme fork. All provisional colors live in `battle_visual_tokens.gd`. No changes to battle damage/AP/RP, cards, Reaction/Enemy actions or any `scripts/domain/` source.

## Verification gates

1. Godot 4.7.2 strict import, original V1/V2/V3.1–3.3 regressions and new `test_p4_v34_roster_command.gd` semantic/geometry suite.
2. Real rendered screen captures at 1280×720, 1920×1080, zh_TW/en, 0/1/4/8 card states and Boss Break projection fixture. Inspect 3× Hero frames and all buttons with original full-res PNG.
3. Dedicated mouse event test for hero A/B/C switching and command UI hit targets; keep existing 31/31 GUI card/context gate unchanged. No rerun/relabel of historical P4.4 14/16.
4. Preserve prior V2/WIP Codex review: after approval, V3 must be reconciled deliberately onto latest master rather than force-merging unreviewed V2 branch content.

## Engineering Learning

Analogous to extracting Jetpack Compose `HeroStatusCard(state, selected, onClick)` and `BattleCommandButton(command, onClick)`: domain/state dictates the numbers and command legality; the style factory owns gradients, semantic tint, and focus. A visual action rail is never an input target or independent gameplay command.


## Actual V3.4 CI evidence — 2026-10-15

**HEADLESS_VERIFIED + REAL_RENDER_VERIFIED + SCOPED_GUI_VERIFIED**. These are engineering gates, not final user-approved V3 high-fidelity art acceptance.

- Production UI source commit: [`53fdbdfe`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/53fdbdfec6f5fcdbfb9ae66087cd8c81ea84ac7f). Changed `scripts/ui/hero_roster_item.gd`, `scripts/battle/ui/components/command_menu.gd` and visual tokens; **no Domain source changed**.
- [Godot V3.4 headless Run #38749479988](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38749479988), **completed/success**, `V34_ROSTER_COMMAND_REPORT executed=102 passed=102 failed=0` on original production SHA `53fdbdf...`. Original unchanged V1, V2.1, V2.2, V2.4, V3.1, V3.2, V3.3, Scene, HUD, Integration, Localization and Lv40 suites passed. Godot 4.7.2 strict import and log gate passed. [Raw logs](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38749479988/artifacts/11979204876).
- [Actual rendered capture #38749480007](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38749480007), **completed/success**, `V23_CAPTURE_REPORT executed=30 passed=30 failed=0` covering nine player/hand/resolution/locale screenshots, and `V31_BOSS_RENDER_REPORT executed=20 passed=20 failed=0` covering three Boss projection-only Break fixtures. PNG signatures/dimensions and strict logs verified. [Original 12 screenshots and manifests](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38749480007/artifacts/11980244533).
- [Unmodified original card/context GUI regression #38749479919](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38749479919), **completed/success** `V25_GUI_REPORT executed=31 passed=31 failed=0`, on identical runtime UI.
- New scoped **V3.4 real GUI event test** added, testing actual mouse event dispatch to Hero A/B/C, isolated CommandMenu clicks to six original command signals, keyboard focus on Hero and Command, and physical 1920-window versus logical 1280-canvas coordinate transformation. First run [#38749791985](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38749791985) did **not create a job** due to invalid generated YAML; corrected without changing production UI. Second run [#38749955549](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38749955549) ran Godot successfully, `V34_GUI_REPORT executed=28 passed=28 failed=0`, but CI was red because the script mistakenly demanded 30 checks. Third run [#38750186193](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38750186193), at CI-only commit `921cc610df8ef4c7f7302f122f6275db850b4939`, **completed/success**: both `V25_GUI_REPORT 31/31` and `V34_GUI_REPORT 28/28`, strict logs 0 errors. No assertion or runtime behavior was weakened to obtain green. [Raw combined GUI logs](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38750186193/artifacts/11980976693).
- Visual review of rendered 640×360 output: three hero cards retain portrait identities and metallic borders, separate thin HP-green/MP-blue bars, selected-state emphasis; commands show modest semantic left rail and aligned buttons without overflowing the 248×266 sidebar. **This is not an exhaustive full-size pixel OCR/visual approval**; actual 1280/1920 PNGs remain the source.
- Historical P4.4 GUI 14/16 is not rerun, modified, or relabeled. No changes to Realm costs, Last Spell, CardInstanceID, item implementation, enemy Intent, Reaction, or battle result logic.

### Known limits and V3.5 exit gate

- This implementation only changes visual presentation of existing Hero and Command models. `BATTLE_ANALYZE` and `BATTLE_ITEM` remain exactly the existing `UNIMPLEMENTED` callback (not claimed playable).
- `update_status(..., hand_count)` legacy API is retained for compatibility, but no longer prints a permanent hand counter (consistent with approved HUD).
- Exact 1280/1920 font and texture contrast under real display conditions, long localized names, user approval against pinned canonical PNG reference, and all modals/overlays remain V3.5 QA. 12 screenshot render cases and the scoped GUI checks do not replace complete end-to-end playability.
- Keep V3 isolated while Codex reviews V2. Merge only after reconciling a reviewed master and latest V2, including optimized CI workflows; never blindly overwrite master workflows or domain state.
