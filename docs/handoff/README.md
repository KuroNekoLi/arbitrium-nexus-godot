# 交接與待辦入口

此目錄只保留仍具操作價值的交接／檢查點。每個新工作項目由較強的 AI 完成實作與 code review 後，建立一份精簡、任務限定的 handoff，交給較省 token 的 AI 測試與驗收；驗收通過後刪除該 handoff 及此處索引。失敗或待續項目則保留並更新 handoff。已完成的 handoff、merge receipt 與分支清理收據不長期留存；Git 歷史仍可追溯曾提交的文件。

## 仍需保留

- [Codex Context Policy](CODEX_CONTEXT_POLICY_20261016.md)：供 `AGENTS.md` 指定的探索與檔案讀取方式使用。
- [SP 拖曳優先詠唱模式驗收](SP_DRAG_FIRST_CHANT_MODE_20261017.md)：請低成本 AI 對提交 `2a0fc02075d0a13243c18aeed087e60119964bc7` 執行獨立 GUI 驗收；通過後刪除此交接及此索引項。
- [高解析角色狀態 CG 驗收](HIGH_RES_CHARACTER_STATE_CG_20261017.md)：請低成本 AI 對提交 `8594cd4a4c24484d548a4bc8c3b3439de21d5ce0` 執行獨立驗收；通過後刪除此交接及此索引項。
- [連攜不依賴核心開放與示範起手牌](COMBO_CORE_INDEPENDENT_DEMO_OPENING_20261017.md)：請低成本 AI 對本次規則與開局調整執行獨立驗收；通過後刪除此交接及此索引項。
- [Astriom Boss 圖層場景](BOSS_ASTRIOM_LAYERED_SCENE_20261017.md)：請低成本 AI 對提交 `da325e3` 執行獨立驗收；含補充參考圖的待機／法陣透視調整，通過後刪除此交接及此索引項。

## 現行工作入口

分工與 handoff 欄位依根目錄 [`AGENTS.md`](../../AGENTS.md) 的「Token-efficient development and handoff」執行。新工作仍以[戰鬥規則總覽](../combat/README.md)、[待實作與待驗證功能](../combat/engineering/待實作與待驗證功能.md) 和 [CI 測試矩陣](../ci/CI_TEST_MATRIX.md) 為正式入口；handoff 是暫時交接，不取代規格、測試或驗收證據。
