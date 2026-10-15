# Combat Open Issues / Known Gaps — 已決定與尚待裁決的邊界

> **CURRENT GAP REGISTER**（2026-10-15；不自行決定遊戲玩法）。比起歷史 [14](14_DECISION_BACKLOG_AND_ADRS.md)、[17](17_PHASE2_HANDOFF_AND_OPEN_QUESTIONS.md) 的舊 OPEN，應優先以此表追蹤現在的**開放狀態**，不能反推撤銷原本核准項。

| ID | 狀態 | 目前明確邊界與處理方式 | 來源 |
|---|---|---|---|
| M5-5-FULLBATTLE | **VERIFIED — HEADLESS BATTLE / FIXTURE_ONLY** | 已完成三人各12 SP 真 Reducer 開場到 VICTORY/DEFEAT、100 fixed seeds 逐場全 Tape Replay、Godot 4.7.2 Headless CI [#38677695295](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38677695295) 與 [PR #38678188918](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678188918) 全綠；M5.5 新增157/157、全程1,238/1,238 Domain +4 Legacy；已併入 [master 9c8b14b8](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/9c8b14b873047ca181a229cfaab5d2351541ceab)。全100場為 Provisional Fixture 勝利，**不代表已平衡、Lv40內容 Parity、UI或真人可玩**。本行保留為已解決 Gate 歷史。 | [M5.5 驗收](../verification/PH3_M5_5_ACCEPTANCE_REPORT.md)、[M5 Handoff](../verification/PH3_M5_HANDOFF.md) |
| FULL-PLAYABLE-UI | **NOT VERIFIED** | 尚需 Scene/HUD/動畫／Controller 及真人操作 Gate，不能用 Python 模型、Domain Fixture 取代。 | [Phase4 handoff](COMBAT_PHASE4_HANDOFF.md)、[UI 設計](../ui/README.md) |
| CONTENT-LV40 | **CONTENT_PROVISIONAL / NOT GODOT-PARITY VERIFIED** | 25/26/27 的卡牌、AI 招式、Lv40 stats、Boss phase、Last Spell 實際參數待 Godot fixture、模型 parity、實戰。Python v0.1/v0.2 記錄是原型研究，不是 Godot 平衡核准。 | [25](25_STARTER_PARTY_CARD_CONTENT_V0_2.md)–[31](31_LEVEL40_DEMO_GODOT_AGENT_START_HERE.md) |
| SPELL-COUNTER | **BLOCKED_CONTENT / NOT VERIFIED** | P2-S15/S16 反制與 Casting Interrupt 明確分離；欠缺已核准 Counter 對應卡牌、技能 Release/Reaction 合法窗口、耗費與取消結果。不得把現有 Interrupt 當成 Spell Counter 已完成。 | [16](16_PHASE2_APPROVED_DECISIONS_WIP.md)、[M5.3 note](../verification/PH3_M5_3_ENGINEERING_NOTE.md) |
| ANALYZE-INTEL | **DEFERRED_CONTENT / NOT VERIFIED** | P2-S02～S12 的免費 Analyze／Enemy Intel 規則已核准方向（不屬 SP、全隊每戰2次）；完整情報欄位、內容及實際 UI/引擎整合需專項測試。不要把基本情報 stub 宣稱全驗收。 | [16](16_PHASE2_APPROVED_DECISIONS_WIP.md)、[M5.3 note](../verification/PH3_M5_3_ENGINEERING_NOTE.md) |
| ALL-EXHAUSTED-POSITIVE-HP | **CORE_RULE_EDGE_PENDING (USER DECISION)** | 所有我方 EXHAUSTED 但 HP >0、Boss 仍活：不得自行判 DEFEAT、DRAW 或默默跳回合；目前保留 `ALL_EXHAUSTED_HP_POSITIVE_PENDING_DECISION` 狀態事件。可維持測試 fail-closed。 | [M5.4 note](../verification/PH3_M5_4_ENGINEERING_NOTE.md)、[20](20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md) |
| BOSS-FSM-ADVANCED | **CONTENT / EXTENSION NOT VERIFIED** | M5.3 已驗證單 Boss、單目標 deterministic policy / 公開意圖、Break fallback；多 Boss、AoE、執行中 Boss Casting 失衡及 Spell Counter 遭反制的完整例外仍無合格實際內容／測試。 | [M5.3 note](../verification/PH3_M5_3_ENGINEERING_NOTE.md) |
| FULL-CHANT-COMBO | **CONTENT / EXTENSION NOT VERIFIED** | M5.3 雙人真正付費即時 Combo 已通過；Full Chant CastingCombo、Last Spell 共鳴等需要個別註冊技能與合法事件窗口，不是默認實作。 | [09](09_COMBO_SYSTEM.md)、[M5.3 note](../verification/PH3_M5_3_ENGINEERING_NOTE.md) |
| BALANCE-UNAPPROVED | **BALANCE_PROVISIONAL** | 命中 K、傷害、Crit、狀態疊層、Guard 值、BossHP、Break 門檻、卡牌AP/MP/魔法退款比例、Overload Debt cap、傷害四捨五入例外等數值需版本化；已核准公式方向/權限與具體參數分開。 | [19](19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md)、[20](20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md)、[25](25_STARTER_PARTY_CARD_CONTENT_V0_2.md)–[29](29_LEVEL40_BOSS_PYTHON_V0_2_RESEARCH_AND_BALANCE_REPORT.md) |
| OLD-SCENE-VS-DOMAIN | **IMPLEMENTATION GAP / VERIFY AT CURRENT HEAD** | 舊 prototype README 描述每角8 SP/每階段兩次出牌，正式核准為每角12 SP/全隊 AP；不能以場景舊 UI 推翻新領域規則，亦不能假設目前 Scene 已完成新引擎接線。 | [A 方案衝突稽核](UPSTREAM_RECONCILIATION_A_2026-10-15.md)、[AGENTS](../../AGENTS.md) |
| REPO-PROVENANCE | **HISTORICAL PATHS / RECONCILED** | 22/24/30/31 等文件舊指向 docs-only `astraea-combat-rules`／`Astraea-Academy`。執行目標是 `arbitrium-nexus-godot`。保留原文供追溯，使用本索引規範解析。 | [A 方案稽核](UPSTREAM_RECONCILIATION_A_2026-10-15.md) |

## 已決定，不要再誤標 OPEN

- P2-D08 CritRate/CritDamage：**方向已批准**，細數值 PROVISIONAL（18）。
- P2-D09 元素抗性/弱點為每個敵人獨立配置：**方向已批准**（18）。
- M-D18～31、P2-D10～D16：已確認**具體玩法方向**，各自候選參數另議（19）。
- CORE-01：同一合法 Action 同歸於盡 **VICTORY**，無 DRAW（20/21；M5.4 以 headless fixture 驗證）。
- CORE-02：未釋放 Last Spell 的施術者 HP0 **立即取消**、不可死後補刀（20/21；M5.4 驗證）。
- CORE-03：無自由走位（20/21）；CORE-04：無 Reaction 倒數／自動 Pass（20/21）。
- 25 初期劍士 Variant 與 26 通用基本攻擊／治療／防護魔法配牌資格 **USER_APPROVED_DIRECTION**；25 的通用卡池/起始牌組具體候選由 26 v0.3 局部取代。

## 問題處理規則

`OPEN_RULE_DECISION` 才需要玩家新 ADR；`CONTENT_PROVISIONAL` 可以用版本化測試資料發展，但不能對外稱正式平衡；`NOT VERIFIED` 則要求真正 Godot CI/互動試玩驗收。先讀 [索引](COMBAT_SPEC_INDEX.md)；如同一項目有新決議，更新本表狀態、追溯矩陣與對應現行章節，不要刪改歷史討論。
