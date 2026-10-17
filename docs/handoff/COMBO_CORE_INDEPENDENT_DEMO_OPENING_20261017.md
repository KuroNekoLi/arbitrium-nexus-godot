# 連攜不依賴核心開放：獨立驗收

## 角色分工

強模型已更新實作、規則文件並檢視 diff；尚未執行測試。請低成本模型核對交付提交，執行下列驗收並記錄真實結果，不修改程式、測試或斷言。此環境無法自動切換模型。

## 需求與範圍

- 使用者於 2026-10-17 明確要求：蓮 R01/R07 的攻擊連攜不得再要求 Boss 核心開放；核心開放只決定額外 Exposed，不是連攜資格。
- Lv40 示範遭遇開手保證 Ren 的 R01、Akane 的 A06 在各自前四張手牌；其餘開手仍隨機。一般 `Draw.start_battle` 呼叫未指定保證牌時維持隨機洗牌。
- 目標 commit：`6aca95eac6281c36cf491d7f4b5f4cacc4c55ec9`（`feat: allow offense combo without exposed core`）。

## 驗收方式

使用 Godot 4.7.2 Windows，乾淨 checkout 目標提交後：

1. 執行 `res://tests/test_combo_preparation_v2.gd`，預期 `COMBO_V2_REPORT` 全部通過；它含 Boss core closed 的新期望，以及 fixed-seed replay。
2. 執行 `res://tests/test_lv40_content.gd`、`res://tests/test_lv40_roster.gd` 和現行 CI Fast／Integration 群組。
3. 對固定多個 seed 建立 `Lv40Encounter.initial(seed)`，確認 Ren 手牌含 R01、Akane 手牌含 A06、每手正好四張且各 12 張卡區守恆；一般未傳 `guaranteed_opening_cards` 的 M2 `Draw.start_battle` 仍按 seed 正常隨機。再真實啟動 `res://scenes/battle/lv40_playable_battle.tscn` 確認兩牌在起手可見。
4. 在 Boss 核心閉合時，使用蓮 R01 命中後確認 Combo Opportunity；以朱音 A06 及同一 Boss 目標完成準備連攜。確認兩張牌各自正常付費、產生 ComboExecuted，且沒有 ExposedApplied。核心開放時確認 Exposed 額外效果仍可用。
5. 保存實際輸出與截圖路徑；區分自動測試及真人操作證據。

## 預期範圍與限制

- Combo bonus 20% 仍為候選數值；這次只改連攜門檻，不調數值或其他配方。
- 目前沒有本提交的測試結果。不要引用舊版 Combo Preparation V2 測試報告作為本次通過證據。
- 若 Godot 缺少 Windows GitPlugin DLL，只能在暫存 checkout 移除 `project.godot` 中該插件設定，不改目標提交。
- 不刪除使用者工作區資料，不改牌組與抽牌規則。
