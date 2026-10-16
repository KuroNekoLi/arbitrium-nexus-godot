# 現役 P4 UI 驗收狀態

最新本機驗收基準：`master@481cf8bfdd2baa0326829dfc6d4b2a7c5702b219`，Godot `4.7.2.stable.official.ed1daf0bf`，Windows disposable checkout。原始輸出位於執行者 `%TEMP%\arbitrium-qa-481cf8b-logs`；截圖位於同 checkout 的 `outputs/p4_input_capture/v35_481cf8b`。這些本機路徑不是可攜 CI artifact。

## 已驗收的現役範圍

- P4 UI contracts：25 suites / 1,149 assertions PASS。
- 真實畫面 capture：63/63 checks PASS，18 張畫面涵蓋 1280/1920、zh_TW/en、多手牌狀態、Lv40 開局及 Last Spell 預覽。
- `test_p4_integration`: 31/31；`test_p4_lv40_playable`: 32/32。
- 角色狀態 CG: 39/39；法術與角色呈現：46/46；目標標記契約：26/26。
- 現役 V3.4 roster/command GUI：28/28。

## 現役未通過或尚未驗收

- `test_p4_v25_gui_input` 的滑鼠／鍵盤手牌操作前 20 項通過，之後因 runner 使用過期節點路徑查找偏好設定而中止；不能宣稱整套 GUI 通過。更新 runner 路徑後再驗收此剩餘範圍。
- `test_p4_sp_drag_gesture`: 23/25；兩種預覽模式的 `SPG-AIM-RETICLE-ON-ARROW-TARGET` 均失敗。玩家可看見箭頭且拖曳時不顯示卡面，但被指向角色沒有通過應有的高亮／標記驗收。
- `test_p4_input_capture`: 13/16；真實 addon 拖曳、合法目標 drop、鍵盤確認並扣費造成傷害三項失敗。完整 P4.3 GUI 輸入仍未接受。
- 高保真美術未經使用者最終核准；角色戰場位置仍緊密重疊，指令排版及框架樣式與參考圖有差異。渲染檢查 PASS 不代表視覺定稿。
- 完整真人 Lv40 Boss 勝利流程及效能／平衡驗收未執行。這兩項仍是遊戲級範圍，不能以 headless contracts 或靜態截圖替代。

不再沿用 V2/V3/V3.5 歷史階段的 GUI quota 說法；本輪直接檢查目前 `master` 的現役功能。舊階段報告和 Editor-only quota checkpoint 已清理，現行未完成項目只在本檔與 [Battle UI Visual Acceptance](../../ui/BATTLE_UI_VISUAL_ACCEPTANCE.md) 維護。
