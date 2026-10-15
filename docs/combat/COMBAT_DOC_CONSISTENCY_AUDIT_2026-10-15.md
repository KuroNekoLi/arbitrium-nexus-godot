# Combat Documentation Consistency Audit — 2026-10-15

> **DOCS-ONLY / EVIDENCE-BOUNDED**：審查對象為原 `docs/combat/` 35 份 Markdown（含 archive），不改 Godot Engine 或素材；不宣稱文件修訂後 Domain CI 重新執行。核對來源：現行 GitHub master Tree、逐檔全文的標題/權威/歷史快照/核准內容、`AGENTS.md`、當時的 M5.4 工程筆記與官方 CI。**本報告原 §1～§5 是 M5.5 尚未驗收時的歷史稽核；目前最新狀態見 §6**。

## 1. 每個原始檔案的處理紀錄

| 檔案 | 類型／真實現行角色 | 主要一致性處理 |
|---|---|---|
| 00 | Canonical historical rules index | 明確從現行索引進入；舊 Library-only 提示標為原快照 |
| 01 | Approved P1 decision registry | 後續 M/P2 決策優先；不反問 P2-D08 |
| 02 | Approved lifecycle detail / historical TBD | CORE-01～04、M5.4 優先於歷史勝敗/事件待決表 |
| 03 | Approved AP/MP/RP detail | M-D18 CurrentAP 無全域硬 cap、RP 正常6上限、MP 不自然補滿 |
| 04 | Approved deck/detail | 每角12、補至4／cap8、免費換牌；舊 TODO 僅史料 |
| 05 | Approved casting detail | Last Spell CORE-02；一般中斷 MP 部分退款 vs 釋放死亡取消分開 |
| 06 | Approved Boss design | M5.3 單 Boss fixture verified，不等於所有 Boss 內容或 Casting 分支 |
| 07 | Approved Reaction & Protect | CORE-04 無倒數、Protect→Guard→Barrier、窗口由玩家確認 |
| 08 | Approved Last Spell | HP0 pre-release forced invalidate；post-release irreversible；Exhausted≠Incapacitated |
| 09 | Approved Combo | 第二張卡不同角色真實付費；Full Chant CastingCombo 尚未完整驗證 |
| 10 | Approved Variant concepts | 主角初期劍士 25 §1，後續新 Variant 解鎖 |
| 11 | Detailed damage/status with historical d20 | d20/Nat1/Nat20 已過時；M5.1–M5.4 各自驗證範圍 |
| 12 | Engineering architecture | 只允許單一 BattleState/Domain Reducer；M1 replay |
| 13 | Acceptance matrix | SPECIFIED 舊表與真正 CI run 必須分開 |
| 14 | Historical decisions backlog | 舊 OPEN 不覆蓋 18/19/20/21 後續核准 |
| 15 | Historical v0.7.1 simulator | 不視作已批准新版數值 |
| 16 | P2 approvals snapshot to D07 | P2-D08/D09 已在18選擇；舊「下一題」歷史 |
| 17 | Historical handoff/open questions | M-D18～31、CORE-01～04 已處理，舊下一題不可重問 |
| 18 | Approved M-D01–17 & P2-D08/09 | 部分先前 OPEN 以 19/20/21 解決 |
| 19 | Approved M-D18–31 & P2-D10–16 direction | 單一現行檔名；archive 異名 19 只供稽核 |
| 20 | Delegated defaults + user CORE-01–04 | 最終 §7 USER_APPROVED 高於前文舊 CORE 方案 |
| 21 | Phase 2 spec acceptance record | 只證明文件規格，不能當 Godot 測試；CORE 最終 |
| 22 | Agent process contract | 過時「docs-only / 找不到 Godot」為原撰寫背景；本倉有 project.godot |
| 23 | Historical Phase3 execution plan | `NOT IMPLEMENTED` 是當時狀態；目前 M1～M5.5 已有 Master CI [#38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741) |
| 24 | Historical G0/M1 execution report | 舊源 repo 和 M1 14/14 只能描述當時，不是現 master 綜合進度 |
| 25 | Approved Variant direction + content candidates | 26 v0.3 覆蓋 25 的通用卡池／起始 decks；其他內容值 provisional |
| 26 | Latest approved universal basic magic direction | 起始 12SP 配牌 v0.3 為候選，角色限制不排斥基本治療 |
| 27 | Level40 Boss provisional spec | 尚不能宣稱 Godot playable/parity verified |
| 28 | Historical Python v0.1 simulation | 與 v0.2、Godot 引擎測試分開 |
| 29 | Python v0.2 balance research | 實際 Python 數據不等於 Godot parity 或平衡批准 |
| 30 | Historical Godot Agent handoff | `NO GITHUB PUSH` 是原 handoff 當時紀錄；目前已存在目標倉 |
| 31 | Historical other-repo Agent handoff | 執行目標改以本倉、保留外部 repo 作 provenance；勿自動改場景 |
| UPSTREAM_RECONCILIATION_A | 2026-10-15 A semantic merge audit | 原文件保留；後續非同批改動應另追溯 |
| UPSTREAM_TRANSFER_STATUS | Original import progress | 初期 `UNRESOLVED` 是移交前狀態，A 已完成 |
| archive/upstream_19 | Explicit historical upstream copy | 不是另一份生效 19，僅來源比較 |

## 2. 衝突處理方式

- **沒有刪除原核准決議**；舊快照正文保留以利 ADR/時間序列追溯，於檔首加上 `Documentation status / 2026-10-15` 醒目欄位，統一導向 Index 和當前測試範圍。
- 已核准的跨檔優先順序與版本繼承寫入 Index；已批准玩法與候選數字清楚分層。
- 對 22/23/24/30/31 舊 repo/狀態及 00/01/02/…「LIBRARY ONLY」原文：**不做範圍外的歷史竄改**；後續 Agent 必读檔首現行說明而非摘錄舊正文斷章取義。
- 已核准但仍沒有完整內容／窗口測試者（Spell Counter、Analyze）、全隊 Exhausted 正HP Outcome、Lv40 Godot-parity 另列；**M5.5 Headless Domain 已完成**，不得與 UI/Playtest 驗證混同。
- 文件巡覽參考 [COMBAT_SPEC_INDEX.md](COMBAT_SPEC_INDEX.md)；工程 API 接合及遷移參考 [COMBAT_IMPLEMENTATION_CONTRACT.md](COMBAT_IMPLEMENTATION_CONTRACT.md)。

## 3. 驗證方法與限制

以 GitHub Tree 列出所有 `docs/combat/**/*.md`，逐檔檢查正文、追溯其核准/過時文字，確認索引相對連結指向實際檔案。**此報告不是新 Godot 程式碼的執行證據**。比對各階段數字：897+44+48+44+48=1,081；M5.5 的後續實作與正式 Headless CI 已通過，見下方 §6。GitHub Actions 的 success 是舊 Commit 的可信紀錄，不保證日後更動永不回歸。

## 4. 後續維護

每次更新：同步 Index、Open Issues、Requirements Traceability，保留原始規格決策來源；新版規格必須有新決策 ID、測試、及正反情境。UI/美術與 Python 平衡可逐步做，但不擅自修改 core Gameplay。

## 5. 實際 GitHub 回讀與相對連結驗證結果（2026-10-15）

- **範圍確定**：原有 35/35 份 `docs/combat/**/*.md` 已各自新增現行狀態 banner，另外新增 5 份文件治理與 Phase4 handoff，完成後目標共 40 份 Markdown。
- **GitHub Tree/Readback**：分批逐檔從 `master` 重新讀取 40/40 份 Markdown，檢查狀態 banner（原有35/35）與檔案連結的目標路徑。
- **相對檔案連結**：共抽取並解析 **196** 個相對連結；目標路徑存在：**196/196**；缺失檔案路徑：**0**。僅驗證 GitHub Tree 中是否有該路徑，**不宣稱** URL fragment/標題錨點、外部網站或渲染後的所有互動都已檢查。
- **修改邊界**：從整理前 `472195ed69bdaad82a76533dd2f73f27213e8dec` 對照整理後的 GitHub Compare，40 個修改／新增路徑**全部位於 `docs/combat/`**，沒有改動 `scripts/`、`tests/`、`scenes/`、`assets/` 或 Godot CI 工作流程。
- **實際 CI 證據**：已存在的 M5.4 Godot 4.7.2 Run [#38676746490](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38676746490) 為 success；**本次純文件改動不等於重新執行 Godot**。這行記錄的是整理當時的狀態；M5.5 正式驗收已完成，見 §6。
- **變更策略**：保留核准決策及全部歷史文本；只移除早期檔案中重複且會誤導的 `2026-10-14 LIBRARY Phase 2 最新補充（現行 SoT）` 開頭樣板段落，並針對 03 的重複普通攻擊、25 起始牌組覆寫增補精準說明。其他歷史主張於檔首明標優先順序。

## 6. M5.5 正式完成後的增量一致性稽核（2026-10-15）

> **CURRENT STATUS — VERIFIED HEADLESS DOMAIN / NOT PLAYABLE**：以官方 [Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741) 為 M5.5 實際 Gate。2026-10-15 先前 M5.4 的 §1～§5 數字只作前置歷史證據；不再讓舊 banner 誤導 Codex。

- **官方執行環境**：Godot 4.7.2；合併 Commit `9c8b14b873047ca181a229cfaab5d2351541ceab`；CI **completed/success**，工作 `m5-5-acceptance` success、無 failed steps。後續 `81f4e3a7` 修改檔案限文件，不曾修改 Domain 程式。
- **逐階段測試**：M1～M4.5 897、M5.1 44、M5.2 48、M5.3 44、M5.4 48、M5.5 **32+15+110=157**，總計 **1,238/1,238**；四個 Legacy smoke suites 成功。
- **完整對局與決定性 Replay**：100 個固定 Seed（`20261014..20261113`），每場都合法到 terminal 並完整重播；Golden seed `20261014`、49 commands、5 rounds、VICTORY、Event SHA256 `588cb04d22911bd9d4b1a4d006eb5aa41fe2b7fa90a02a4fe879086e2928dfb1`、Final State SHA256 `c510227726170562d623b3737226439f3dffa0e4cea1ee9dfc4150117671acdd`。100/100 victories **僅屬 Provisional Fixture**，不代表正式平衡／難度已證明。
- **文件變更**：同步更新既有 35 份 `docs/combat/` 原始文件的**現行狀態 Banner**，並修正 Spec Index、Open Issues、Implementation Contract、Phase4 Handoff；原有歷史內容、CORE-01～04 已核准規則以及內容 Provisional 身分維持不變。現行完整證據：[M5.5 Acceptance Report](../verification/PH3_M5_5_ACCEPTANCE_REPORT.md)、[M5 Handoff](../verification/PH3_M5_HANDOFF.md)。
- **仍需獨立驗收**：Spell Counter 合法窗口/內容、Analyze/Enemy Intel、全隊 Exhausted 正HP 終局、正式 Lv40 卡牌與 Boss 內容、Godot 2.5D Scene/HUD/i18n、真人可玩與平衡。**下一階段為 Phase 4，不再稱呼 M5.5 未完成**。
- 此項更新僅修改文件；**不宣稱此文件提交重新執行了 Godot CLI 或 GitHub Actions**。完整 Domain PASS 證據固定指向上述已實際跑過的 CI Commit。
