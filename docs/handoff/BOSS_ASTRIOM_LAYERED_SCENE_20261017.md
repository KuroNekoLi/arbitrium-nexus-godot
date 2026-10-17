# Astriom Boss 圖層場景：獨立驗收交接

## 分工

強模型已實作並完成獨立 code review。目標提交：`da325e3`（`fix: refine Astriom layered idle and ground rotation`），包含先前 `1193ace` 的整合。請低成本模型核對此提交並獨立驗收；不要更動實作、測試或斷言。完成驗收後刪除此交接及 README 索引項。此環境未自動切換模型。

## 需求與範圍

- 使用者提供的 Boss 身體、光環、魔法陣三張 PNG 位於 `assets/monsters/boss/`。
- `scenes/battle/enemies/boss_astriom.tscn` 以 `Node2D` 組合地面魔法陣、背後光環、Boss 身體及 `AnimationPlayer`，並由現行 `battle_screen.tscn` 的 `Design/Arena` 載入。
- `BossAstriom.gd` 提供 idle、hit、defeated；保留既有 presenter 的受擊、施法、攻擊、重設及目標圖像接口。戰鬥規則仍由 Domain 控制。
- MagicCircle 僅顯示原圖下半部地面法陣，避免高聳符印在旋轉時遮住戰場；Aura 與地面法陣圖層在背景上可見。
- 依使用者補充參考：主體每 2.4 秒浮動 10 px，Aura 縮放 0.96～1.04、alpha 0.75～1.0；法陣每秒 7.5°、alpha 0.82～0.94。以 UV 旋轉維持固定地面透視並加透明邊界防止斜角裁切。受擊閃白及微抖動，普通混色保留細節。
- 圖像來源、提示詞、模型及外部散佈授權未提供，依 manifest/CREDITS 標為使用者提供、暫定素材。

## 已執行的驗證

- Godot 4.7.2 headless `test_boss_astriom_scene.gd`: 14/14 PASS。
- Godot 4.7.2 GUI `test_boss_astriom_scene.gd`: 15/15 PASS，已目視 0°、30°、45°、60° 的真實截圖。
- `test_spell_visual_foundation.gd`: 46/46 PASS，Domain/replay 未變更。
- `git diff --check`: PASS。
- [本次證據與限制](../verification/ui/BOSS_ASTRIOM_REFERENCE_20261017.md)：含原始輸出及實際截圖；GitHub CI 狀態尚未查核，不宣稱 CI PASS。

## 獨立驗收重跑

在乾淨 checkout 的 Godot 4.7.2 專案目錄執行：

1. `godot --headless --path . --script res://tests/test_boss_astriom_scene.gd`；預期 `BOSS_ASTRIOM_REPORT executed=14 passed=14 failed=0`。
2. `godot --path . --script res://tests/test_boss_astriom_scene.gd`；預期 `BOSS_ASTRIOM_REPORT executed=15 passed=15 failed=0`，確認 `%TEMP%/arbitrium-boss-astriom-runtime.png`、`arbitrium-boss-astriom-30.png`、`arbitrium-boss-astriom-45.png`、`arbitrium-boss-astriom-60.png`。Windows 用 `Start-Process -Wait` 與輸出重新導向取得完整報告，退出碼 0 本身不足以證明 PASS。
3. `godot --headless --path . --script res://tests/test_spell_visual_foundation.gd`；預期 `SPELL_VISUAL_REPORT executed=46 passed=46 failed=0`。
4. 開啟 `res://scenes/battle/lv40_playable_battle.tscn`，確認獨立 Boss 存在、背景/角色不遮掉地面法陣與 Aura，Boss 區域仍與手牌及 HUD 可辨讀。GUI 截圖不是真人互動驗收；若執行 GUI 自動截圖，存檔路徑 `%TEMP%/arbitrium-boss-astriom-runtime.png`。

本次只涉及表現層，不需重跑完整 Domain、balance、多 seed 群組；依上述限定群組驗收。

## 限制

- 使用者尚未確認素材最終美術 Canon 或外部再散佈權利。
- GUI 截圖已自動驗證並人工目視；未執行真人操作測試。
- 如發現功能失敗，回報失敗 case 與輸出給強模型修正；不得藉由移除斷言或放寬預期來驗收。
