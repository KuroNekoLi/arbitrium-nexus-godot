# 現役 P4 UI 驗收狀態

2026-10-18 的 `refactor/editor-authored-battle-layout` 審查、修復與最新驗證見 [Editor Layout Review](EDITOR_LAYOUT_REVIEW_20261018.md)。該分支仍待測試追加授權及 Master CI；下列較早結果不代表此次分支已驗收或合併。

最新 UI 驗收基準包含 `master@de4d201` 互動修正與本次高解析狀態圖工作樹，Godot `4.7.2.stable.official.ed1daf0bf`，Windows disposable checkout。原 P4 合約 logs 位於 `%TEMP%\arbitrium-contracts-postdrag`；本次素材驗收 logs 與畫面位於 `%TEMP%\arbitrium-cg-assets-qa-20261017`。這些本機路徑不是可攜 CI artifact。

## 已驗收的現役範圍

- P4 UI contracts：25 suites / 1,149 assertions PASS。
- 真實畫面 capture：63/63 checks PASS，18 張畫面涵蓋 1280/1920、zh_TW/en、多手牌狀態、Lv40 開局及 Last Spell 預覽。
- `test_p4_integration`: 31/31；`test_p4_lv40_playable`: 32/32。
- 角色狀態 CG: 39/39；法術與角色呈現：46/46；目標標記契約：26/26。
- V2.5 GUI：31/31；V2.6 GUI：48/48；V3.4 roster/command GUI：28/28。
- SP drag gesture：25/25；P4.3 input capture：20/20。拖曳期間手牌仍顯示於手牌區，游標只顯示瞄準箭頭，箭頭目標有標記。
- 使用者提供的高解析透明角色狀態圖已接入執行路徑，舊 128×180 狀態貼圖已移除。PNG 尺寸／透明通道已檢查；Godot 狀態測試 39/39、真實 HUD capture 63/63、失能／退場渲染 37/37 PASS。各角色裁切線依原圖透明分界為 Ren y=536、Akane y=512、Tsumugi y=504。

## 現役未通過或尚未驗收

- 高保真美術尚未取得使用者最終核准；渲染檢查 PASS 不代表視覺定稿。
- 完整真人 Lv40 Boss 勝利流程及效能／平衡驗收未執行。這兩項仍是遊戲級範圍，不能以 headless contracts 或靜態截圖替代。

不再沿用 V2/V3/V3.5 歷史階段的 GUI quota 說法；本輪直接檢查目前 `master` 的現役功能。舊階段報告和 Editor-only quota checkpoint 已清理，現行未完成項目只在本檔與 [Battle UI Visual Acceptance](../../ui/BATTLE_UI_VISUAL_ACCEPTANCE.md) 維護。
