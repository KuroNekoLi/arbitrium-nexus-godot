# Combat Specification Index — 戰鬥規格唯一閱讀入口

2026-10-16 最新 USER_APPROVED：[終式真正退場與無在場成員敗北](LAST_SPELL_RETIREMENT_APPROVED_20261016.md)。本議題明確取代舊耗竭仍可受擊／治療、全耗竭待決部分；歷史Replay保留原配置，不回溯改Hash。

2026-10-15 all-branches續作：新增獨立Lv40正向場景接線，不修改Domain規則；驗收狀態見 requirements_traceability 與 P4_LV40_POSITIVE_INTEGRATION_NOTE。原GUI/已用盡測試預算不重設。

2026-10-15 CI補記：新增CI-EVIDENCE-01/02失敗傳遞／日誌閘門與legacy UI測試清理，未改玩法。詳見[工程Note](../verification/CI_EVIDENCE_GATE_ENGINEERING_NOTE.md)；P4.4 GUI仍未驗收，依使用者決定不額外重跑。

> 狀態：**CANONICAL NAVIGATION / DOCUMENT GOVERNANCE**｜審核：2026-10-15｜作用域：`KuroNekoLi/arbitrium-nexus-godot` 的 `docs/combat/`。本文件只規範閱讀、依據、版本及驗證邊界，不創造新戰鬥玩法。
> **本次掃描來源**：2026-10-15 於 `master` 實際盤點原有 **35** 份 Markdown（含一份 archive）；文件正文中保留的「當時尚未做」只代表**歷史快照**。請用最新 GitHub 工程紀錄及執行 CI 核對當前狀態。
> 入口：[`00_README_COMBAT_RULES_BASELINE_V0_8.md`](00_README_COMBAT_RULES_BASELINE_V0_8.md) 是 **v0.8 分散式規格的舊入口**；本文件是現行 Agent 的 **導航入口**。兩者並不相互廢止；任何原本已批准的規則均原樣保留。

## 1. 權威與衝突優先級（依**議題**比對，非檔案編號或日期一律覆寫）

1. **USER_APPROVED**：2026-10-14 最終 CORE-01～04：[`20 §7`](20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md)、[`21 §1`](21_PHASE2_SPEC_ACCEPTANCE_REPORT.md)。其餘已明示核准 P1／P2／M-D／P2-S：[`01`](01_DECISIONS_AND_CONFLICTS.md)、[`16`](16_PHASE2_APPROVED_DECISIONS_WIP.md)、[`18`](18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md)、[`19`](19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md)。同一項目如有後續核准，僅後續**明確變更部分**覆寫早期決策。
2. **USER_APPROVED_CONTENT_DIRECTION**：[`25 §1`](25_STARTER_PARTY_CARD_CONTENT_V0_2.md) 初期劍士、未來 Variant 解鎖；[`26 §1`](26_UNIVERSAL_BASIC_MAGIC_AND_STARTER_DECK_V0_3.md) 三角皆可裝備通用基本攻擊、HP 治療與防護**魔法卡**。25 的起始牌組和通用卡候選被 **26 v0.3 的該部分取代**；其餘角色和高級卡候選繼續僅為候選。角色名及具體數值沒有因此自動升格為核准 Canon。
3. **DELEGATED_DEFAULT**：[`20 §3`](20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md) PRE3-R01～R18 的已授權工程預設，**不等同逐題核准**，不得逆向推翻 USER_APPROVED。
4. **APPROVED DETAIL / EXPLANATORY**：[`02`](02_BATTLE_LIFECYCLE_TIMELINE.md)～[`13`](13_TEST_MATRIX_ACCEPTANCE.md) 各領域章節中標明的現行規則。舊版 OPEN、d20、6 Prepared／無抽牌、2 RP 上限、每階段最多兩次出牌、可以死後補 Last Spell、Reaction timeout、同時雙方倒地 DRAW 等段落僅歷史，不准實作。
5. **CONTENT_PROVISIONAL / BALANCE_PROVISIONAL**：[`25`](25_STARTER_PARTY_CARD_CONTENT_V0_2.md)～[`29`](29_LEVEL40_BOSS_PYTHON_V0_2_RESEARCH_AND_BALANCE_REPORT.md)。可做版本化 fixture；不得因 Python 研究或 Godot headless 測試通過就當作已批准平衡數值。
6. **HISTORICAL / EVIDENCE**：[`14`](14_DECISION_BACKLOG_AND_ADRS.md)～[`17`](17_PHASE2_HANDOFF_AND_OPEN_QUESTIONS.md) 之舊待決表、[`15`](15_SIMULATOR_AUDIT_AND_MIGRATION.md)、[`24`](24_PHASE3_G0_M1_EXECUTION_REPORT.md)、[`28`](28_LEVEL40_PYTHON_BALANCE_PILOT_V0_1.md)～[`31`](31_LEVEL40_DEMO_GODOT_AGENT_START_HERE.md)、上游匯入報告及 [archive](archive/upstream_19_phase2_final_2026-10-14.md)，只證明當時的規劃／研究／工作。

**重要**：已實作程式碼／CI 是「現有 API 行為與測試」的證據，不會自動核准**新玩法**。若正式玩法與目前 Godot 原型不一致，建立差距與測試，不能以「程式比較新」逕行改規則。

## 2. 當前工程事實（2026-10-15 GitHub 可查；不是文件發布即驗收）

- **正確執行倉庫**：[`KuroNekoLi/arbitrium-nexus-godot`](https://github.com/KuroNekoLi/arbitrium-nexus-godot)；本倉根目錄有 `project.godot`、`scripts/domain/`、`tests/`、`scenes/`；不是歷史的 `Astraea-Academy` 或 docs-only `astraea-combat-rules`。舊文件提及其他倉庫只作原始來源紀錄。
- **前置階段的歷史測試基線**：M1～M4.5 897/897；M5.1 44/44；M5.2 48/48；M5.3 44/44；M5.4 48/48。**累計 1,081/1,081 headless Domain 測試**已由 Godot 4.7.2 [Actions #38676335088](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38676335088) 通過，另有較新 [M5.4 主分支 CI #38676746490](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38676746490) 成功；這些 CI **僅證明各自 Commit 的範圍**。
- **M5.5 Full Battle / 100 seeds 已完成 HEADLESS BATTLE DOMAIN Gate**：正式程式碼於 [PR #3](https://github.com/KuroNekoLi/arbitrium-nexus-godot/pull/3) 合併至 [master 9c8b14b8](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/9c8b14b873047ca181a229cfaab5d2351541ceab)。Godot 4.7.2 [M5.5 功能分支 CI #38677695295](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38677695295) 與 [PR CI #38678188918](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678188918) 均成功，**新增 157/157、全部 M1～M5.5 1,238/1,238 Domain assertions**，100 個固定 Seed 的真正開戰→終局+Replay PASS，四組舊版回歸成功。**Scope = M5 DOMAIN VERIFIED — HEADLESS BATTLE / FIXTURE_ONLY，非全遊戲戰鬥功能或可玩 UI**。正式合併後的 [Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741) 已核對為 **completed / success**，執行程式碼 Commit `9c8b14b873047ca181a229cfaab5d2351541ceab`；後續至 `81f4e3a7` 僅有文件修改。Lv40 Godot 內容 parity、真人可玩、2.5D/UI、英文繁中、正式平衡及 Counter/Analyze **仍 NOT VERIFIED**。詳見 [M5.5 報告](../verification/PH3_M5_5_ACCEPTANCE_REPORT.md)／[M5 Handoff](../verification/PH3_M5_HANDOFF.md)。
- **Golden Battle 驗收**：Seed `20261014`、49 個已接受 Command、5 回合、`VICTORY`；Event SHA256 `588cb04d22911bd9d4b1a4d006eb5aa41fe2b7fa90a02a4fe879086e2928dfb1`；Final State SHA256 `c510227726170562d623b3737226439f3dffa0e4cea1ee9dfc4150117671acdd`。100 seeds 的 100 場勝利只代表測試專用策略與配置可合法終局，**不能據此宣稱零敗率平衡已核准**。詳見 [M5.5 Acceptance Report](../verification/PH3_M5_5_ACCEPTANCE_REPORT.md)。
- 可靠工程證據：[`docs/verification/PH3_M5_4_ENGINEERING_NOTE.md`](../verification/PH3_M5_4_ENGINEERING_NOTE.md)、[`docs/verification/PH3_M5_3_ENGINEERING_NOTE.md`](../verification/PH3_M5_3_ENGINEERING_NOTE.md)、[`docs/verification/PH3_M5_EXECUTION_PLAN.md`](../verification/PH3_M5_EXECUTION_PLAN.md)、[`requirements_traceability.md`](../verification/requirements_traceability.md)。`23_PHASE3_EXECUTION_PLAN.md` 的 `PLANNED` 標頭是**原計畫發表時快照**。

## 3. 必讀次序（Codex／Agent）

1. 倉庫根目錄 [`AGENTS.md`](../../AGENTS.md) 與 **本索引**。
2. [`00`](00_README_COMBAT_RULES_BASELINE_V0_8.md)、[`01`](01_DECISIONS_AND_CONFLICTS.md)、[`18`](18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md)、[`19`](19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md)、[`20`](20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md) 和 [`21`](21_PHASE2_SPEC_ACCEPTANCE_REPORT.md)（CORE-01～04）。
3. 按工作讀 `02`–`13` 領域細章，及 [`25`](25_STARTER_PARTY_CARD_CONTENT_V0_2.md)、[`26`](26_UNIVERSAL_BASIC_MAGIC_AND_STARTER_DECK_V0_3.md)（後者的起始牌組候選優先），或 [`27`](27_LEVEL40_DEMO_BOSS_ENCOUNTER_V0_1.md)／[`29`](29_LEVEL40_BOSS_PYTHON_V0_2_RESEARCH_AND_BALANCE_REPORT.md) 的**候選內容**。
4. [`COMBAT_IMPLEMENTATION_CONTRACT.md`](COMBAT_IMPLEMENTATION_CONTRACT.md)；驗證 [`22`](22_PHASE12_AGENT_IMPLEMENTATION_CONTRACT.md)、[`23`](23_PHASE3_EXECUTION_PLAN.md) 和 `docs/verification` **實際** reducer/command/event/CI。
5. [`COMBAT_OPEN_ISSUES.md`](COMBAT_OPEN_ISSUES.md)、[`COMBAT_PHASE4_HANDOFF.md`](COMBAT_PHASE4_HANDOFF.md)、[`COMBAT_DOC_CONSISTENCY_AUDIT_2026-10-15.md`](COMBAT_DOC_CONSISTENCY_AUDIT_2026-10-15.md) 與 UI 資料夾 [`docs/ui/README.md`](../ui/README.md)。

## 4. 已盤點的原有 35 個 Markdown（含 archive）

| 檔案群組 | 完整清單 | 現行角色 |
|---|---|---|
| 00–01 | [00](00_README_COMBAT_RULES_BASELINE_V0_8.md)、[01](01_DECISIONS_AND_CONFLICTS.md) | v0.8 索引、P1 決策；早期文字須受後續核准覆寫 |
| 02–07 | [02](02_BATTLE_LIFECYCLE_TIMELINE.md)、[03](03_PARTY_ACTIONS_RESOURCES.md)、[04](04_DECK_DRAW_CARD_RULES.md)、[05](05_DUAL_CASTING_AND_INTERRUPTION.md)、[06](06_BOSS_AI_INTENT_BREAK.md)、[07](07_REACTIONS_PROTECTION.md) | 各系統領域詳細條款，部分舊 TBD 為快照 |
| 08–13 | [08](08_LAST_SPELL_EXHAUSTED.md)、[09](09_COMBO_SYSTEM.md)、[10](10_CHARACTER_VARIANTS_COLLECTION.md)、[11](11_DAMAGE_STATUS_TARGETING.md)、[12](12_ENGINE_ARCHITECTURE_EVENTS.md)、[13](13_TEST_MATRIX_ACCEPTANCE.md) | 設計細節、事件架構、測試規格 |
| 14–17 | [14](14_DECISION_BACKLOG_AND_ADRS.md)、[15](15_SIMULATOR_AUDIT_AND_MIGRATION.md)、[16](16_PHASE2_APPROVED_DECISIONS_WIP.md)、[17](17_PHASE2_HANDOFF_AND_OPEN_QUESTIONS.md) | 歷史 backlog、遷移及中間核准快照 |
| 18–21 | [18](18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md)、[19](19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md)、[20](20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md)、[21](21_PHASE2_SPEC_ACCEPTANCE_REPORT.md) | 核准／授權預設／CORE-01～04 最終裁決 |
| 22–24 | [22](22_PHASE12_AGENT_IMPLEMENTATION_CONTRACT.md)、[23](23_PHASE3_EXECUTION_PLAN.md)、[24](24_PHASE3_G0_M1_EXECUTION_REPORT.md) | 工程約束、原計畫、M1 里程碑歷史報告 |
| 25–27 | [25](25_STARTER_PARTY_CARD_CONTENT_V0_2.md)、[26](26_UNIVERSAL_BASIC_MAGIC_AND_STARTER_DECK_V0_3.md)、[27](27_LEVEL40_DEMO_BOSS_ENCOUNTER_V0_1.md) | 主角與通用魔法方向已核准；其他具體內容候選 |
| 28–31 | [28](28_LEVEL40_PYTHON_BALANCE_PILOT_V0_1.md)、[29](29_LEVEL40_BOSS_PYTHON_V0_2_RESEARCH_AND_BALANCE_REPORT.md)、[30](30_LEVEL40_GODOT_AGENT_HANDOFF_AFTER_PYTHON_V0_2.md)、[31](31_LEVEL40_DEMO_GODOT_AGENT_START_HERE.md) | Python 研究／候選平衡／歷史 Godot Agent 交接 |
| 上游/歸檔 | [A 方案稽核](UPSTREAM_RECONCILIATION_A_2026-10-15.md)、[來源移交狀態](UPSTREAM_TRANSFER_STATUS.md)、[archive/19](archive/upstream_19_phase2_final_2026-10-14.md) | 來源及衝突稽核紀錄，不是第二套 Canon |

## 5. 修改規則與防回歸

- 新增玩法：先標出既有 ID、檢查 USER_APPROVED、必要時由使用者另行決定 ADR，再編寫測試與配置；**不改寫歷史證據**。
- 變更 Domain：維持 **M1～M5.5 全部 1,238 項既有測試**（另有四組舊版 smoke）；新功能需自身測試、Domain Event replay、CI，再調整文件狀態。僅文件整理不可宣稱 Godot tests executed。
- 每次工程提交至少同步：領域章節、`requirements_traceability.md`、Engineering Note、Open Issues、Index 的進度。如果尚未實作，明標 `SPECIFIED_NOT_VERIFIED`。
