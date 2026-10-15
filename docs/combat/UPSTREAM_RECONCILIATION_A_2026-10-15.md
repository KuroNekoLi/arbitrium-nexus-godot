# 上游戰鬥規格語義合併稽核 — 方案 A（2026-10-15）

> **文件合併：已完成。Godot 程式規則遷移：未執行。** 這是 `master` 文件整合和衝突追溯，不是 Godot 戰鬥測試或後續里程碑的執行驗收。

## 來源、邊界、決策

- 來源：`KuroNekoLi/astraea-combat-rules@cac49361e1cbc0e783fbdf75699080724f1c70a9`。
- 目標合併前：`KuroNekoLi/arbitrium-nexus-godot@4357be301ad0c7e306bd781186d16c7a2124f312` (`master`)。
- 使用者選擇 **A**：「保留目標現有規格，逐份比對來源，只合併缺漏的新版核准事項／測試，不覆蓋已實作架構」。
- 比對方法：兩倉 Git tree/blobs，對同路徑 Markdown 正規化行尾與行末空白，逐行語義比對；19 為異名同主題文件，依 M-D/P2-D ID 交叉核對。沒有假裝 Git blobs 不同就一定是玩法衝突。
- 規則優先序：**最新 USER_APPROVED** → 已核准 P1/P2/M → 20 的 DELEGATED_DEFAULT（未被覆蓋時）→ CONTENT/BALANCE_PROVISIONAL。20/21 CORE-01–04 最終裁決優先於歷史 OPEN/TBD（例如同時雙方倒地 = VICTORY；Last Spell 釋放前施術者 HP0 立即失效）。
- 來源 `25`–`31` 的角色/卡牌/Boss/Python設計已於前次 Commit `4357be30` **SHA 相同完整匯入**；但只有 Variant 初期劍士後期解鎖和 Universal 基礎攻/治/防等明確決策為 USER_APPROVED；具體數值和配置仍 PROVISIONAL。

## 00–24 逐份審核結果

| ID | 正規化後比較 | 方案 A 處理 | 理由／裁決 |
|---|---|---|---|
| 00 | 內容不同 | **保留目標 + 更新現行導覽** | 目標有較新 20/21 裁決與 Library 入口；來源 19 使用另一檔名；加入 25–31 導覽、版本優先級。 |
| 01 | 內容不同 | **保留目標 + 補 ADR** | 目標詳述核准與 Open 管理；追加 A 方案及 Lv40 候選地位。 |
| 02 | 內容不同 | 保留目標 | 目標有較詳盡的 P2-D14–16 註記；來源簡述舊 tie-break TBD，20/21 已覆蓋。 |
| 03 | 內容不同 | 保留目標 | 目標有較完整 CurrentAP 無 cap／MP 跨回合／部分退款規則；來源為較短摘要。 |
| 04 | 內容不同 | 保留目標 | 目標有更多免費換牌／hand cap8／抽棄牌事件工程細節。 |
| 05 | 內容不同 | 保留目標 | 目標對同 MP、詠唱中斷與退款條件更完整。 |
| 06 | **正規化一致** | 不動 | 只有字元空白或換行差異，不構成規則衝突。 |
| 07 | 來源有額外 P2-D12 摘要 | 保留目標 | 目標已在 PRE3／Reaction 段明列 Barrier 防HP、Focus Ward 防 Stability 與 Guard→Barrier，且規則 19/20 更完整，無需雙重摘要。 |
| 08 | **Git Blob 完全一致** | 不動 | Last Spell 正式規則無差異。 |
| 09 | **正規化一致** | 不動 | Combo 文意相同。 |
| 10 | **正規化一致** | 不動 | Character Variant 文意相同。 |
| 11 | 內容不同 | 保留目標 | 目標對傷害流水線、Guard、狀態時序與 tie-break 備註更完整；CORE-01 覆蓋舊 TBD。 |
| 12 | 內容不同 | 保留目標 | 目標有更詳細 Replay 與換牌事件順序。 |
| 13 | **來源獨有 10 個 Case ID** | **保留目標 + 新增 10 案例** | 已新增 `P2-AP-01`, `P2-MP-01`, `P2-CAST-01/02`, `P2-DECK-01`, `P2-MULL-01/02`, `P2-DMG-01`, `P2-STATUS-01`, `P2-END-01`。與目標既有 ID 不重複；是否有相同語義 Godot 測試待 Agent 對映。 |
| 14 | 內容不同 | 保留目標 | 目標已將 M-D18～31/P2-D10～16 從歷史 OPEN 收斂；來源僅另有簡短摘要。 |
| 15 | **正規化一致** | 不動 | 只有空白／換行差異。 |
| 16 | 兩份皆為歷史快照 | 保留目標 | 目標有新版歷史警示；以19及20/21為現行規則。 |
| 17 | 內容不同 | **保留目標 + 插入現行 handoff 警示** | 目標持續保存歷史「下一題 M-D18」；新導覽禁止重問已決策事項。 |
| 18 | 內容不同 | 保留目標 | 目標已有新版 19 的優先級提醒；M-D01～17 保持原核准。 |
| 19 | **不同檔名／不同詳盡程度** | **保留目標為唯一現行19；補 provenance；封存來源全文** | 核對 M-D18～31 / P2-D10～16 後，未發現互斥的核准方向；來源有較長追溯表，但其舊 P2-D15 tie-break TBD 已由 20/21 CORE-01 更晚裁決。來源全文另放 `archive/` 並標非 Canon。 |
| 20 | **Git Blob 完全一致** | 不動 | 最新 PRE3/CORE 決策。 |
| 21 | **Git Blob 完全一致** | 不動 | Phase2 接受報告。 |
| 22 | **正規化一致** | 不動 | 工程契約相同。 |
| 23 | **正規化一致** | 不動 | Phase3 五階段計畫相同；其中歷史里程碑狀態以目前 Godot code/CI 為準。 |
| 24 | **正規化一致** | 不動 | 歷史 M1 報告相同；不得冒充目前 M5 進度。 |

比對結果：原 21 個**同名不同 Git Blob**檔案中，7 份為正規化一致（06、09、10、15、22、23、24），其餘 14 份有實質敘述差異；加上不同檔名的 19，以及 3 個已完全一致的 08／20／21，完成 00–24 全部核對。保留目標中已存在的後續核准內容，**沒有對全部 21 份做覆蓋或宣稱逐 byte 一致**。

## Root 檔案衝突

- **來源 `README.md` 只適用 docs-only 規格庫**；目標 README 描述真實 Godot 原型，因此保留原有操作說明，頂部補「目前原型 ≠ 最新 Combat Rules」提示。
- **來源 `AGENTS.md` 宣稱 docs-only**，不能搬到可執行 Godot repo；保留目標專屬 AGENTS 並更新此合併完成狀態。
- 目標 `docs/COMBAT_RULES_V1.md` / 舊 README 的 8-card、最多2張普通出牌描述是 **目前原型的舊契約**，與最新版 USER_APPROVED **12張 SP 每角、共享 BaseAP6、無全域每階段出牌張數硬 cap** 不同；這是**程式、測試和UI尚待改寫的實作缺口**，不是本次文檔合併未決。

## 版本與進度上不可混淆

- `docs/combat/00`～`24`：權威規則；`19` 目標檔名是現行 Canon，`archive/` 只是稽核史料。
- `docs/combat/25`～`26`：初始三人、每人12張卡、通用治療方向；明文 USER_APPROVED 與 CONTENT_PROVISIONAL 分開。
- `docs/combat/27`：Level40 Boss prototype (HP3000 為原 fixture)。
- `tools/balance/demo_level40_balance_candidate_v0_2.json`：Python 測試候選（HP2700／攻擊×1.7／Break22）；**不是直接改寫27或 Godot 正式 fixture**。
- `docs/combat/28`～`31`：Python v0.1/v0.2 研究與後續 Agent handoff；引用其他 Godot repo 的歷史路徑是原始紀錄，**此處真正實作目標為 `KuroNekoLi/arbitrium-nexus-godot`**。
- Python 模擬結果 ≠ Godot 4.x 執行結果；目標的既有 `docs/verification` 有 M1–M5 工程進度，需 Agent 以**當前 HEAD + CI logs**核對，不可把外部舊 repo 的 M1 狀態寫成現在的測試結論。

## 交付與下一步（不擅自修改遊戲）

**本輪僅修改文檔及交接入口，沒有修改** `project.godot`、`scripts/`、`scenes/`、`resources/`、`tests/`、`.github/workflows/` 或素材。沒有新跑 Godot CLI 或 CI，因此不聲稱新的 Godot PASS。

後續由 Codex/Godot Agent 在授權後，先做**實際程式契約差異對映**，提出保留舊 8-card Demo UI 還是分階段遷移到已核准 12-card 設計的實作計畫。就最新版 USER_APPROVED 決策而言，**正確方向是 12-card/共享 AP**，不需要再次投票決定核心規則；只是如何平滑遷移程式仍需分階段工程測試。
