# 戰鬥畫面 GUI 編輯：人工驗收交接

> 2026-10-18 review 更新：修復提交 `842b294820530fcf8e00fa7ca8de8bb2753a4988`，完整結果見 [審查與修復紀錄](../verification/ui/EDITOR_LAYOUT_REVIEW_20261018.md)。Master merge／push 等待 editor-authored layout 與 P4 HUD 各追加一次測試的授權；不要在等待時自動 push 觸發同一組 CI。HeroRosterSkin 增加 RS-21，期待數量為 21；第二次因新 fixture 的 Dictionary 型別中止，已修正，第三次尚待 CI。新 target geometry 在 headless 為 19，rendered 為 21；下一次 CI 為本輪第三次。Boss、feedback edges 的下一次亦為第三次。原限制與全部失敗紀錄保留。

- 分支：`refactor/editor-authored-battle-layout`；以 `git rev-parse HEAD` 記錄實際受測提交。
- 需求：使用者要求常駐畫面可經 Godot GUI 調整並保存，自行手動驗收後決定是否合併。正式入口、角色定義和 M1–M5 規則保持現行契約。
- 範圍：固定 HUD／彈窗子場景、角色欄模板、角色視覺／陰影／TargetRegion、原地切換語言。包含前置 Boss GUI 座標提交 `ff52438`。
- 補充外觀需求：角色欄新增 `HeroRosterSkin`／`resources/ui/hero_roster_skin.tres`，固定狀態皮膚由 Inspector 設定；FantasyBorder 的圖片、色調與顯示狀態不再由選角程式覆寫。
- 工程分工：本輪完成實作與另一次差異審查；GUI 由使用者驗收。若交由較低成本 AI，僅執行下列指定檢查與記錄結果，未自動切換模型。
- 操作與架構說明：[GUI 編輯指南](../ui/EDITOR_AUTHORED_BATTLE_LAYOUT.md)。主要檔案為 `scenes/battle/ui/*.tscn`、`hero_roster_item.tscn`、`battle_actor.tscn`、對應 UI／角色腳本及 `battle_screen.gd`。

## 手動驗收

1. 於正確分支開啟 `lv40_playable_battle.tscn`。展開 `Design/HUD`，確認可選取真實面板與控制項，而非只有空 HUD。
2. 移動 `PartyStatusPanel`、`Commands`、`HandView`、`EnemyStatus`；存檔、關閉再開場景、執行，確認配置保留。在 1280×720 與 1920×1080 檢查畫布縮放。
3. 移動角色 A／B／C 與 Boss；調整 `Visuals`、`Body`、`StateCG`、`Shadow`，並調整 `TargetRegion`。確認開局、普通攻擊返回、施法與狀態切換保留自訂 Transform，目標高亮／點擊跟隨命中區。
4. 下移 `Boss/MagicCircle`；確認執行時仍在設定位置旋轉，Body 浮動與 Aura 呼吸正常。
5. 更改 `hero_roster_item.tscn` 的頭像範圍、資源條尺寸或列最小高度，確認三列採用相同模板，Container 的間距有效。
6. 繁中／英文來回切換，確認配置不重置、無重複面板、固定文字與動態狀態更新。確認換牌、卡牌拖曳／長按詠唱、指令按鈕仍可操作。
7. 開啟／取消終式與連攜確認，測設定彈窗、減少動態與靜音。檢查反應視窗 Confirm／Pass，以及戰鬥結束後的重新開始。GUI 可達性與焦點仍需人工確認。
8. 將 Inspector 的 Editor Preview Mode 切至終式預覽、保存再執行，確認遊戲不以編輯器預覽狀態開啟彈窗。
9. 開啟 `hero_roster_item.tscn`，更換 FantasyBorder Texture 與 Modulate；修改 Skin 的 Normal／Selected／Focus、Name Color 和狀態標籤。純色可用 StyleBoxFlat，圖片可用 StyleBoxTexture。關閉角色色混合後，自訂框色應保留；選角、連攜、失能、切語言後仍使用設定的圖片與樣式。改共用 Skin 會影響三列；單獨變體先 Make Unique。

預期：靜態布局從場景讀取，動態卡牌／反應與戰鬥資料正常。大幅改名／更動階層須檢查匯出引用和固定路徑；資料驅動的文字／貼圖／狀態樣式與容器子節點位置仍受腳本或 Container 管理。

## 定向自動檢查（可交給測試 AI）

使用 Godot `4.7.2.stable.official.ed1daf0bf`，先確認正確專案路徑。Windows 需使用 console binary 以保留 exit code／log。各命令的輸出存檔，再使用 `tools/ci/assert_godot_logs.py <log>`；零 exit code 不代表可忽略 SCRIPT ERROR。

```text
Godot --headless --path . --script res://tests/test_editor_authored_battle_layout.gd
Godot --headless --path . --script res://tests/test_p4_component_contract.gd
Godot --headless --path . --script res://tests/test_p4_v35_command.gd
Godot --headless --path . --script res://tests/test_p4_v34_legacy_roster.gd
Godot --headless --path . --script res://tests/test_character_editor_preview.gd
Godot --headless --path . --script res://tests/test_hero_roster_skin.gd
Godot --headless --path . --script res://tests/test_p4_v35_party.gd
Godot --headless --path . --script res://tests/test_p4_v34_roster_command.gd
```

預期 reports：`EDITOR_AUTHORED_LAYOUT_REPORT` 15、`V1_COMPONENT_REPORT` 24、`V35_COMMAND_REPORT` 30、`V34_LEGACY_ROSTER_REPORT` 18、`CHARACTER_EDITOR_PREVIEW_REPORT` 39，全部 failed=0。新布局測試已加入 Fast CI。

外觀補充測試預期：`HERO_ROSTER_SKIN_REPORT` 20、`V35_PARTY_REPORT` 57、`V34_ROSTER_COMMAND_REPORT` 102。Skin 測試亦加入 Fast CI。審查重點：共享模板不可被染色／選角修改、換 Skin 與離場清理 Resource.changed 訂閱，退場 disabled 不依賴是否有皮膚。

本機開發原始 logs 與使用者原有差異備份位於 `%TEMP%/arbitrium-gui-layout-backup-20261017/`；該路徑不會隨 Git push 傳送。`test_p4_hud` 本次開發已執行三次（前兩次揭露遷移缺口，第三次36/36），不要為交接自動重跑。新布局群組目前最多第三次；失敗須回報，不重設計數。其他曾用的 `test_p4_integration` 31/31、`test_p4_lv40_playable` 32/32 是開發期結果，不能替代最終提交 GUI 驗收。

未聲稱實機 GUI、fresh import、整套 CI 或遠端 Actions 已通過。驗收完成後刪除此交接及 README 索引；保留編輯指南與測試。失敗請記錄 commit、操作、節點路徑、預期／實際及原始錯誤，不變更戰鬥規則或放寬測試。
