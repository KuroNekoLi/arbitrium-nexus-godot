# 現役 P4 UI 驗收狀態

最新本機驗收基準：依 `master@bbab424` 的工作樹修正，Godot `4.7.2.stable.official.ed1daf0bf`，Windows disposable checkout。最新 25 組 headless logs 位於 `%TEMP%\arbitrium-contracts-postdrag`；互動與截圖證據位於 `%TEMP%\arbitrium-drag-final`、`%TEMP%\arbitrium-final-gui-last` 及同一 disposable checkout 的 `outputs/p4_input_capture`。這些本機路徑不是可攜 CI artifact。

## 已驗收的現役範圍

- P4 UI contracts：25 suites / 1,149 assertions PASS。
- 真實畫面 capture：63/63 checks PASS，18 張畫面涵蓋 1280/1920、zh_TW/en、多手牌狀態、Lv40 開局及 Last Spell 預覽。
- `test_p4_integration`: 31/31；`test_p4_lv40_playable`: 32/32。
- 角色狀態 CG: 39/39；法術與角色呈現：46/46；目標標記契約：26/26。
- V2.5 GUI：31/31；V2.6 GUI：48/48；V3.4 roster/command GUI：28/28。
- SP drag gesture：25/25；P4.3 input capture：20/20。拖曳期間手牌仍顯示於手牌區，游標只顯示瞄準箭頭，箭頭目標有標記。
- 角色戰場靜止 CG 原圖只有 128×180，實際放大至 163–200px 高，因此會顯糊。大尺寸角色 CG 帶不透明背景，不能直接替代透明戰場貼圖；需另備高解析透明站姿素材。

## 現役未通過或尚未驗收

- 高保真美術尚未取得使用者最終核准；渲染檢查 PASS 不代表視覺定稿。
- 完整真人 Lv40 Boss 勝利流程及效能／平衡驗收未執行。這兩項仍是遊戲級範圍，不能以 headless contracts 或靜態截圖替代。

不再沿用 V2/V3/V3.5 歷史階段的 GUI quota 說法；本輪直接檢查目前 `master` 的現役功能。舊階段報告和 Editor-only quota checkpoint 已清理，現行未完成項目只在本檔與 [Battle UI Visual Acceptance](../../ui/BATTLE_UI_VISUAL_ACCEPTANCE.md) 維護。
