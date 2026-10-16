# Last Spell Scope / Target Preview — Engineering Note

基準 master：f1ca5bb8f2a6a30b6cebf6330fbb6b4ee71bb4c1。分支：ui/last-spell-target-scope-20261016。

狀態：SCOPED_NATIVE_VERIFIED。新範圍群組經使用者明確追加一次後 29/29；完整既有回歸／CI 尚未重跑，尚未通過使用者高保真驗收。

## 功能與來源

[USER_APPROVED scope decision](../../ui/LAST_SPELL_TARGET_SCOPE_DECISION_20261016.md)、Combat 08、Combat 25 的三招候選內容及現有配置。原下拉選單改為大型肖像、下方金屬框、敵我／單全標籤、費用與時程、目標頭像卡、戰場菱形／腳底標記、右側獨立終極法術摘要與啟動／取消。保留戰場人物，預覽時收起手牌，取消或提交後恢復。

蓮敵單；朱音敵全；紬我方全體。未因參考圖添加新單體群療或復活效果。正常入口改為已存在的 lv40_playable_battle。

## 架構

- last_spell_targeting：M5 純資料 helper，讀 trusted ContentConfig，列陣營／有效 recipients。
- lv40_content / domain_extension / cast_effect：沿用單次 M2 付款、M4 到期及 M5 Damage/Heal；朱音補成逐敵結算，各自防禦／抗性。拒絕 UI 任意 target_ids。
- last_spell_read_model：detached inspection 與同一 M5 preview 合法性。
- last_spell_preview / target_card / target_marker：只持有顯示與選取；BattleScreen 協調記憶與原 Controller 提交。

新內容 provisional-2；舊 Tape 內嵌 provisional-1 配置保留歷史單 Boss 語義。不同初始配置不要求同一 hash，沒有變更 Command schema 或重建 Domain。

## QA

Godot 4.7.2.stable.official.ed1daf0bf；Windows GTX1650、Compatibility / OpenGL 3.3。

新群組 tests/test_last_spell_target_scope.gd，不是歷史群組改名：

| Run | 結果 | 問題與處理 |
|---|---|---|
| 1 headless | 22/22 assertions，另有 runtime error | 裝飾 marker 被當焦點；locale 重建後 log deferred callback 存取離場 tree。已修焦點 filtering 與 lifecycle guard。 |
| 2 native | 26/26，無上述 errors | 真滑鼠切換多敵目標卡、明確啟動／Replay；4 PNG 成功。 |
| 3 native | 26/28 | 新增釋放／Replay prepared fixture 漏同步 core.cards.phase / player_phase_index，已補正但未重跑。操作與 4 PNG 仍 PASS。 |
| 4 native（使用者明確授權一次） | 29/29；exit 0；無 script errors | 修正 prepared fixture 後 M5 到期 AoE／Replay 通過，另確認舊 v1 配置語義。4 PNG 寫入成功。 |

原始 logs 位於 evidence/last_spell_scope/batch1.log～batch4-authorized.log。2026-10-16 使用者明確同意一次追加，已執行，無剩餘執行次數。歷史 Last-preview25、V3.5 capture、P4.4 GUI14/16 未重跑。既有1238／100seeds也未重跑，不能將舊 CI 記為本次通過。

最後 PNG：outputs/p4_input_capture/last_scope_41924/real_A_1280_zh.png、real_B_1280_zh.png、real_C_1280_zh.png、real_C_1920_en.png。多敵只在 TEST_FIXTURE_ONLY 狀態，無正式額外敵人美術。截圖證明渲染，非完整戰鬥或效能驗收。

## 素材與仍有差距

REUSED：party_portraits、arcane_panel NinePatch、cmd_last/ap_core/status_barrier/cmd_basic 原創 SVG、既有卡圖。沒有外部下載、付費、插件或參考像素抽取。Portrait 來源仍為舊 manifest PROVENANCE_PENDING，不宣稱商用清權。

仍可見的五個差距：肖像不是專用終極 CG 姿勢；既有小圖示放大後不夠細；邊框比參考圖簡化；隊伍／Boss HUD 的字體與資源條密度仍不同；正式場景仍僅單 Boss。尚未宣告 High-Fidelity VERIFIED 或使用者核准。

## Godot / Android 學習

Container 負責測量、TextureRect 負責圖像比例、NinePatchRect 負責獨立邊框，對照 Compose 的 layout／painter／state 分工。右側長英文用 ScrollContainer，啟動／取消留在固定 footer。

選取 signal 相當於 onClick callback；ReadModel 類似 StateFlow 投影出的 UiState。預覽切換不付款，提交用同一 M5 重驗；Replay 依初始狀態／配置版本／Command，不依動畫時鐘。

候選替代方案：舊 OptionButton 資訊不足；新增角色切換欄會混淆選角與選擇對象。保留隱藏 target_selector 相容欄位，玩家使用目標卡。面試追問：scope 為何不能由 UI 猜？AoE 為何只付款一次？舊配置重播如何相容？deferred callback 如何保證離場安全？

回退僅需 revert 本分支提交，不刪任何舊素材／測試。延伸閱讀：Godot Control、Container、NinePatchRect、Signals 及 COMBAT_IMPLEMENTATION_CONTRACT。
