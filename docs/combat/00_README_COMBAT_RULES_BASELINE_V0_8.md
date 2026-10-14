# Combat Rules v0.8 — 文件入口與閱讀契約（Phase 1 已批准修訂，2026-10-14）

> **2026-10-14 LIBRARY Phase 2 最新補充（現行 SoT）**：請優先閱讀 [`19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md`](19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md) 與 [`18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md`](18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md)。M-D18～M-D31 已核准；P2-D10～D16 的**設計方向**已整體核准，數值／部分結算邊界仍 TBD。較早段落的「P2-D08 未決」「換牌僅提案」「手牌上限 TBD」「完整詠唱較貴 MP」等屬歷史文字，與 19 衝突時以 19 為準。**僅 Library 更新，未同步 GitHub；尚無 Godot 執行／CI PASS 證據。**


> **狀態：工程規格基線草案（Approved decisions + Provisional mechanics + TBD）**  
> 日期：2026-10-14｜語言：繁體中文｜目標：Godot 4 / GDScript、可重播 headless simulation。  
> **Source of Truth（SoT）= 本資料夾整套文件，而非單一超長檔案。** 本檔是入口與索引。文件已保存到 ChatGPT Library 不代表自動同步 GitHub。

## 1. 使用者已確認的產品定位

**傳統 JRPG + 卡牌技能**：角色是戰鬥主體；普通攻擊／Guard／道具不需抽牌；戰技、魔法、干擾、支援、Reaction 主要透過技能卡；三人共享行動資源；高風險完整詠唱、Boss 可干擾；Last Spell 導致永久 Exhausted；連攜由實際卡牌／狀態／順序觸發。

## 2. 文件閱讀順序與地圖

| 順序 | 文件 | Agent 應讀情境 |
|---|---|---|
| 00 | 本檔 | **所有戰鬥相關工作必讀** |
| 01 | `01_DECISIONS_AND_CONFLICTS.md` | **所有戰鬥相關工作必讀**，判斷批准／待決／衝突 |
| 02 | `02_BATTLE_LIFECYCLE_TIMELINE.md` | 回合、事件順序、Reaction、勝敗 |
| 03 | `03_PARTY_ACTIONS_RESOURCES.md` | AP、RP、MP、普通指令、道具 |
| 04 | `04_DECK_DRAW_CARD_RULES.md` | 每角12卡、4手牌、抽棄牌、配置資格 |
| 05 | `05_DUAL_CASTING_AND_INTERRUPTION.md` | 破棄／完整詠唱、韌性、干擾、護盾 |
| 06 | `06_BOSS_AI_INTENT_BREAK.md` | Boss 意圖、蓄力、Break 與目標選擇 |
| 07 | `07_REACTIONS_PROTECTION.md` | Reaction 窗口、RP、Barrier/Focus Ward |
| 08 | `08_LAST_SPELL_EXHAUSTED.md` | Last Spell 的一次性承諾與 Exhausted |
| 09 | `09_COMBO_SYSTEM.md` | Combo Opportunity、一般／專屬／詠唱連攜 |
| 10 | `10_CHARACTER_VARIANTS_COLLECTION.md` | 角色與 Variant/Skin、卡池、資格和稀有度 |
| 11 | `11_DAMAGE_STATUS_TARGETING.md` | 傷害、命中、閃避、狀態、死亡待決問題 |
| 12 | `12_ENGINE_ARCHITECTURE_EVENTS.md` | 可重播純邏輯架構、資料契約、序列化 |
| 13 | `13_TEST_MATRIX_ACCEPTANCE.md` | 單元／整合／模擬／UI 驗收 |
| 14 | `14_DECISION_BACKLOG_AND_ADRS.md` | 依優先順序引導產品決策，不得私自定案 |
| 15 | `15_SIMULATOR_AUDIT_AND_MIGRATION.md` | v0.7.1實測問題、舊資料遷移、差異 |
| **16** | **`16_PHASE2_APPROVED_DECISIONS_WIP.md`** | **Phase 2 已核准完整決策（必讀）；最新至 P2-D07** |
| **17** | **`17_PHASE2_HANDOFF_AND_OPEN_QUESTIONS.md`** | **Phase 2 未決清單、下一題 P2-D08、續談流程（必讀）** |

**Phase 2 checkpoint（2026-10-14）**：P2-D01～D07、P2-S02～S13、P2-S15～S31（合計 **36 項 APPROVED**）已保存至 16；**P2-D08 尚未決定**。舊文件中關於 d20、命中/傷害/Break 全部 TBD 的敘述，**若與 16 的已核准決策相衝突，以 16 為準**；Phase 1 已核准 AP/RP/Reaction/Protect/Combo/Last Spell 仍維持效力。16/17 是 WIP checkpoint，**不是 Phase 2 完成驗收**。

**關鍵相依關係**：02→03/04→05/07→06→08/09→11→12→13；調整任一規則必須重新檢查受影響文件。所有檔案使用相對檔名互相引用。

## 3. 狀態分類：不可混淆

- **APPROVED**：使用者已直接確認的玩法方向或具體規則，除非再次核准，不得改寫。
- **PROVISIONAL**：原型值／建議機制／仍可調平衡。可放在獨立參數配置，但**不能**宣稱為永久 Canon。
- **TBD / BLOCKED**：未決，會影響結果一致性的問題；不得以無標註假設直接進正式程式碼。
- **LEGACY / SUPERSEDED**：舊文件原有規則，不代表最新有效版本。

任何 Agents 的任務 PR 應附 `decision impact` 清單：變更哪些 rules、是否要求使用者批准、對應測試與 replay seed。

## 4. 規格衝突的處理

本套 v0.8 **就已確認事項**優先於 `/COMBAT_SYSTEM.md` 和 `/Life_RPG_Astraea_GDD_v1.1.md` 中衝突的舊機制；無衝突的世界觀，例如 魔法的世界觀原理與 Spell Card 的術式媒介設定、Last Spell 為不可逆承諾等，繼續保留。v0.7.1 模擬器報告是**測試證據與未核准示例數值**，不是規則權威。

特別禁止將舊 6 張可任選 Prepared Deck／無抽牌設計誤植到最新 12 張抽牌版本。詳見 01 與 15。

## 5. 開發准入條件

1. 先讀 00、01，以及任務涉及的模組；若改動戰鬥核心，再讀 02、12、13。
2. 遇到 `BLOCKED` 需求先提出最小精準問題（含推薦方案、後果）；暫可隔離開發的機制以 feature flag/config stub 運作。
3. 不把模擬器「有運作」等同於「已平衡」「已符合最新設計」。
4. 每個事件應可記錄前後狀態、合法性、成本、seed；不得由 Godot 動畫自行改變權威戰鬥數值。
5. 同一版 deterministic replay 必須生成一致的狀態／事件雜湊。
6. 每次批准新設計，更新 01 的 ADR 與相應規格、13 的測試、並檢查 15 的舊規格衝突；若破壞相容性提高基線版本。

## 6. 文件範圍與排除

本版提供工程契約、已確認機制、候選參數及決策問題，**不是**全部角色卡牌平衡資料、已完成 Godot 引擎、可操作 UI 或最新 repo 代碼驗證。具體命中係數／暴擊倍率（P2-D08）／死亡勝敗／Boss AI 權重等仍須使用者定案；命中百分比制、5%～95%、線性 Accuracy−Evasion 與 Break 行動降級方向已由 Phase 2 核准，見 14。

## 7. 上游參考文件（作為歷史證據）

- Library：`COMBAT_SYSTEM.md`（約 2026-10-05 版本，原本 6 Prepared Cards）。
- Library：`Life_RPG_Astraea_GDD_v1.1.md`（魔法世界觀、舊牌組規格）。
- Library：`貼上的文字 (1)(3).txt`（Combat Simulator v0.7.1：seed 20261014，600 HP、8回合、四策略事件紀錄）。
- 2026-10-14 對話確認：v0.5–v0.8 重要決策，尤其一般連攜由1 AP改為0額外 AP。

## 8. Agent 交付檢查清單

- [ ] `APPROVED`規則未被候選值覆蓋。
- [ ] 沒有主動實作 `BLOCKED` TBD 為正式預設。
- [ ] 事件與狀態轉移有可重播測試，失敗有具體輸入與 seed。
- [ ] 影響 AP/MP/手牌/詠唱/RP/連攜/Last Spell 的邊界案例已覆蓋。
- [ ] 中英雙語 UI 字串採 i18n key，不把顯示文案作判定 ID。
- [ ] 變更同步回寫本文件集、版本與決策紀錄。


---

## 9. Phase 1 核准凍結點（APPROVED，自 2026-10-14 生效）

本節是 **Phase 1 Reactive Defense / AP–RP Economy** 的正式版本差分，與本文件原先任何 `2 RP cap`、單窗口「僅一張反應卡」、必須持卡才可防禦的文字衝突時，**以本節及 01 的 P1-D 決策為準**。文件檔名保留 `V0_8` 以避免既有索引失效；新增規則標識為 `v0.8+P1`，不代表全戰鬥系統平衡完成。

- **P1-D01**：三名角色自由交錯使用全隊共享 6 AP；沒有每人固定行動數量上限。同一角色可多次 Basic Attack，但同角色每個玩家回合只有**第一次**普通攻擊可觸發 MP 回復；回復數值尚未決定。
- **P1-D02 → P1-D09（SUPERSEDED）**：舊的「最多保留 2 RP」不再有效。玩家結束階段時剩餘 AP 以 1:1 全部轉 RP；正常每回合最多6 RP；RP 只能供緊接敵方階段使用，該敵方階段結束即歸零。
- **P1-D03**：基本 Guard / Protect 無須抽取卡牌；特殊 Reaction SP 必須在合格角色手牌並符合觸發、RP/MP與狀態限制。抽不到 SP 不等於不能基本防禦。
- **P1-D04**：同一角色在同一敵方行動 Reaction Window 至多實際執行一次 Reaction；不同角色可在同窗口協作，受共享 RP、角色 MP、合法觸發與狀態限制。
- **P1-D05**：預設 Smart Reaction；另有 Always Ask 與 Quick UI模式。模式控制詢問／呈現，不改變戰鬥核心、資源與已授權的 Reaction，不能自動擅自花費 RP。
- **P1-D06**：基本 Reaction 提供 Guard（僅自身傷害減輕）及 Protect（替隊友攔截攻擊）；基本 Evade 不普遍開放。玩家階段主動 Guard 仍是另一指令，其成本/效果 TBD。
- **P1-D07**：已由後續 D10 的費用決策取代，不單獨作為裁決來源。
- **P1-D08**：基礎 Guard / Protect 只降低損失，不附加反擊、打斷、Combo 或免費 Focus Ward 等優勢；特殊 Reaction SP 可以設計這些額外戰術功能。角色防禦屬性會間接使基本防禦更強；未來羈絆 Protect 減傷僅是擴充想法，不是 MVP。
- **P1-D09**：取消額外 RP 上限／AP轉RP上限；轉換的是當回合*剩餘 AP*，不跨輪囤積。外部 RP 產生效果的上溢政策 TBD。
- **P1-D10**：基本 Guard **1 RP**；基本 Protect **2 RP**。
- **P1-D11**：Guard 的**固定減傷比例**必須在角色防禦、抗性等一般傷害計算之後套用；40% 只是待測候選，並非獲批准數值。Guard 不能保證無傷，也不自動免疫狀態與 詠唱 干擾。
- **P1-D12**：Protect 重新指派單次可守護攻擊給守護者，再以**守護者自己的防禦與抗性**計算承傷；Protect 自身**沒有額外減傷**。
- **P1-D13**：可守護單體物理／魔法攻擊；不能守護全體或多目標攻擊；單體也可被特別標成不可守護，需事先清楚可見。
- **P1-D14**：命中附帶的 Casting Stability 干擾隨被攔截的單體攻擊改指向守護者，原施法者不受該命中型干擾；直接鎖定 Casting Instance 的獨立干擾，不受基本 Protect 影響。
- **P1-D15**：一個 Reaction Window 內玩家先排定多名角色的 Reaction 與順序，統一確認後依序結算；確認前可調整、取消及預覽，確認後不能任意撤銷已執行效果。
- **P1-D16**：確認後如果前序 Reaction 導致後續 Reaction 失去合法觸發／目標，後續無效 Reaction 自動跳過：**不扣 RP/MP、不棄卡、不算角色已反應**；仍獨立合法者正常執行。已實際執行並付費但效果遭抵銷者不追溯退款。

以上全屬本次使用者在對話核准的**玩法契約**；後續文件中為實作提出的狀態欄位、事件名稱、校驗方式若未明示核准，標記為 **ENGINEERING PROPOSAL**，可作為實作建議，但不能延伸成未經批准的玩法承諾。

## 10. Phase 1 文件優先級、兼容與驗收邊界

1. `01` 的 **P1-D01～P1-D16** 決議與本節摘要最優先；`03`/`07` 是詳細機制契約；`02`/`11`/`12` 補結算時間、計算與工程；`13` 是必測規格。當敘述仍出現歧義，以明確未定的 `14` 追問，不允許自行猜定。
2. `14` 原始 v0.8 的 D01～D23 **已重新命名為 `LEGACY-Qxx`**，與 Phase1 的 P1-Dxx 完全不同；不得因編號相同而把「D09 命中閃避待決」誤認為 RP 決議。
3. 這是**設計決議與文件同步**，不是 Godot runtime 或平衡測試已通過的宣告。`13` 的案例為 Acceptance Specification；除非附實際執行 log，不得報告已 PASS。
4. 所有未核准的數字（包含 Guard 40%、HP範例、MP最大值、攻擊回魔量、Barrier容量、Boss攻擊頻率與特殊 Reaction SP費用）一律僅可寫在 `provisional` 配置與測試資料中。
5. 防止龜縮靠成本與效益對抗：基本 Guard 雖可重複在不同合法窗口減傷，但**不保證無傷且不推進輸出**；基本 Protect 僅轉移承傷；有反擊、干擾、複雜保護的技能仍需特殊 SP。6RP 的平衡有效性必須獨立多 seed 模擬驗證。

## 11. 2026-10-14 後續決策快照（請優先讀）

- **`18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md`**：含 P2-D08（可獨立養成暴擊率／暴擊傷害）、P2-D09（敵人個別元素抗性／弱點），以及魔法／AP 行動經濟 **M-D01～M-D17**，為目前相關主題最新版；M-D04 延期債務為 **PROVISIONAL 試行**，M-D05 `8 AP` 為 PROVISIONAL 候選值。
- **`02` / `03`**：Player Phase 採**逐次合法動作、立即執行／依技能時序結算、同一或其他角色自由接續**，並非三人預排全部動作才同時行動；Full Chant 延遲效果與 Reaction Window 確認佇列屬不同時序。
- **RP cap 規則更新**：早期本文及 `01`/`03` 所述「無額外 RP cap」已由 M-D08 明確取代：**預設 RP cap=6**，明文 SP 可暫時提高；M-D09 確認 RP 每個 Enemy Phase 末無條件歸零。
- 舊 `16`／`17` 的 P2-D08、P2-D09 OPEN 狀態只反映較早快照，後續以 `18`、更新後 `17` 為準；不得再說 P2-D08 尚未決策。

## Phase 2 完成狀態與閱讀順序（Library）

設計方向已由使用者全部同意，詳見 19；但需區分 **APPROVED CONTRACT / APPROVED DIRECTION / PROVISIONAL / CONFIGURABLE / IMPLEMENTED / TESTED**。基礎 Player Phase 逐次執行，Full Chant 開始 Concentration 後延時結算；Reaction Queue 先排後確認。手牌上限8、免費換1張及交換事件完整時序見 04/19；MaxMP／MP回復／中斷退款見03/05/19；傷害與狀態見11/19；驗收矩陣見13。過往索引檔數量與結束點為歷史快照，不代表只剩 P2-D08。

## 12. Phase 1–2 實作前待決清查（2026-10-14，授權設計預設）

請再讀 [`20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md`](20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md)。它逐項把歷史 `OPEN` 分為 **RESOLVED_PREVIOUSLY / DELEGATED_DEFAULT / BALANCE_PROVISIONAL / CORE_CONFIRM / CONTENT_DEFERRED**；主要新增明文規則包括 Protect 重導向前於命中、ActionScope 的 Guard、Guard→Barrier、防護與效果跟隨標籤、免費換牌中途牌池消失、Incapacitated/Exhausted/LastSpell 邊界及無走位 headless 首版。**此文件 20 不回退 P1、P2、M 的使用者已核准決議**。GitHub 第19快照可能使用別名 `19_PHASE2_FINAL_APPROVED_M_D18_D31_P2_D10_D16.md`，兩者為同主題紀錄；同步結果依實際 Commit/Library 讀回，不以歷史檔中的 `Library only` 註記推定目前狀態。

## Phase 2 規格驗收入口（2026-10-14）
最新使用者正式核准：**同一合法行動雙方全倒仍判 `VICTORY`**；Last Spell 在正式釋放前若施法者 HP0，**強制失效且不死後生效**（不可玩家主動 Cancel，與普通 Casting Interrupt 不同）；Phase 3 不提供自由走位、允許 2.5D 純視覺呈現；Reaction Smart/Quick/Always Ask 不設強制倒數或自動 Pass。前期文件20「DRAW／死後續唱」為歷史候選，已被本次決議取代。完整已確認事項與文檔驗收詳見 `20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md` 及 `21_PHASE2_SPEC_ACCEPTANCE_REPORT.md`。本次屬 spec-level acceptance，Godot 測試未執行。