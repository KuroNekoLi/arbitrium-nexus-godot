# 01 — 已批准決策、候選數值與來源衝突

> **Documentation status · 2026-10-15 — APPROVED_P1_REGISTRY + HISTORICAL_OPEN**：已核准 P1 行為依此追溯；舊待決、2RP上限、每人回合出牌上限與 d20 候選須服從 18/19/20/21 後續明示決策，不可將 P2-D08 或 CORE-01～04 重列未決。 現行導航：[Combat Spec Index](COMBAT_SPEC_INDEX.md)；缺口：[Open Issues](COMBAT_OPEN_ISSUES.md)。**Godot domain M1～M5.4：1,081/1,081 已有 CI 證據；M5.5、完整可玩戰鬥未驗證。** 以下舊段落保留歷史脈絡，不是新測試或新核准。



> **Phase 2 checkpoint 更新（2026-10-14）**：新增 `16_PHASE2_APPROVED_DECISIONS_WIP.md`（完整 **36 項**已核准決策）及 `17_PHASE2_HANDOFF_AND_OPEN_QUESTIONS.md`（下一題 **P2-D08 OPEN**）。兩者優先於本文件中**同主題**較早的 TBD / 歷史 d20 方案；Phase 1 已核准事項仍具效力。下方舊章節的尚待議題不代表 P2-D01～D07 或 P2-S02～S13、S15～S31 尚未核准。

## 1. 已批准（APPROVED）

| ID | 規則（不得自行變更） |
|---|---|
| A-01 | 戰鬥定位是傳統 JRPG + 卡牌技能；基本攻擊、防禦、道具是固定指令。 |
| A-02 | 玩家控制三名角色，**共享隊伍 AP**，每角自己的 MP、牌庫、手牌、施法／狀態。可自由切換行動順序。 |
| A-03 | 每名角色可配置**12 張技能卡**，混搭符合資格的通用、職能、角色與戰鬥形態專屬卡。 |
| A-04 | 初始每角抽 4 張，每個玩家回合補至 4 張；未使用手牌保留；用過進棄牌；牌庫不足重洗棄牌。 |
| A-05 | 全隊原型基準每玩家回合 6 AP；結束玩家階段時剩餘 AP 全部可按 1:1 轉 RP，正常最多 6 RP；無額外 RP cap，且每個敵方階段結束歸零；不另加每人獨立 AP / 固定出牌張數限制。（Phase 1 D01、D09） |
| A-06 | MP 每角獨立、跨回合持續，並非每回合自動回滿；普通攻擊可恢復 MP，原則上每角每回合僅首次普通攻擊可回 MP。 |
| A-07 | 魔法卡可破棄詠唱（瞬發、較小效果）或完整詠唱（延遲、較大效果）；完整詠唱需 Concentration。 |
| A-08 | 完整詠唱尚在 Concentration：施法者不得進行一般主動行動／再開完整詠唱，可接受隊友保護；特定標籤的 Reaction 例外。 |
| A-09 | 角色個別有 Casting Resilience 和 Disruption Power；Casting Stability 是法術實例資源，與目標本體 Break Gauge 完全分開。 |
| A-10 | 干擾為累積削減詠唱穩定度；Focus Ward 專防詠唱干擾、Barrier 防 HP 傷害；Boss 有公開意圖與可打斷蓄力。 |
| A-11 | Last Spell 不進一般牌組、每角色戰鬥形態專屬、每場最多使用一次、強制完整詠唱、不可主動取消；成功後 Exhausted 本場不能再行動。 |
| A-12 | Last Spell 即使受到干擾也不可直接當一般法術取消；可延遲／削弱的機制為目前採用的設計方向，具體量化仍須驗證。 |
| A-13 | Combo 不需抽專用連攜卡。由不同角色的卡牌標籤／狀態／出牌次序建立機會；提示後玩家確認；通用與角色專屬共用一套機制。 |
| A-14 | **一般雙人連攜額外 AP = 0**；兩張實際觸發卡仍付各自 AP/MP。不可沿用舊模擬器的額外 1 AP 連攜。 |
| A-15 | 完整詠唱可受隊友支援／詠唱連攜（不用 Concentrating 角色額外行動）；Last Spell 共鳴有限，不能改成瞬發。 |
| A-16 | Pure Skin 不改能力；Character Variant 可改基礎屬性、專屬卡資格與被動；卡牌稀有度 R / SR / SSR / UR。 |
| A-17 | 2D 橫向 Godot 戰鬥，deterministic headless core 優先，UI / 動畫無權直接改狀態。 |

## 2. 數值／細節待驗證（PROVISIONAL）

| ID | 暫用設定 | 非正式原因 |
|---|---|---|
| P-01 | 6 AP / 2 RP 僅是舊版歷史原型，**現已被 D09 正式廢止；不可當候選上限** | 仍允許平衡調整；RP重置精確窗口待決 |
| P-02 | 每角最大 MP 6（早期提案）或8（測試腳本） | 衝突，不得偷選為永久設定 |
| P-03 | 普通攻擊 1 AP，回 2 MP（早期）或1MP（實測）；傷害6或12 | 測試版本分歧，需定案 |
| P-04 | 破棄火球 1 AP/1 MP/18，完整2 AP/2 MP/40 | 示意卡數值 |
| P-05 | 法術韌性乘數／干擾倍率例130%；干擾公式 floor(base×character×effect) | 需確認增益疊加次序 |
| P-06 | Focus Ward 在同次 Casting 完成後消失；Barrier 持續時間 | 候選生命周期 |
| P-07 | 「窗口最多一張 Reaction」為舊候選，**已由 D04 多人響應、每人每窗口一次取代** | 原型推薦，複數敵人/連鎖事件待決 |
| P-08 | 每玩家回合最多一次雙人連攜；機會回合末失效 | 平衡候選 |
| P-09 | Last Spell 3 AP+4 MP；基礎150；共鳴層每層+25上限2 | 全屬示意測試數值 |
| P-10 | Last Spell 一次失衡延後一個玩家回合，第二次失衡降低威力 | 使用者接受方向，細節要補 |
| P-11 | Boss 在同次施法的 Stability 25/50/80，或測試用18 | 僅技能示例 |
| P-12 | 同名卡最多2、特殊卡1；稀有度不硬性上限；免費棄1抽1 | 尚未獲得使用者確認，不得實作為批准規則 |

## 3. 關鍵未決（TBD / BLOCKED）

詳見 `14_DECISION_BACKLOG_AND_ADRS.md`：角色死亡／Exhausted可否被攻擊、勝敗、命中與閃避、出牌卡手機制、RP跨輪已由 D09 定案為不保留；其他RP取得途徑與防禦細節、詠唱與敵方技能精準事件次序、MP返還、強力技能與 Boss 門檻、公平出牌限制、持續傷害與狀態生命周期、位置距離、同卡複數與裝備限制。

## 4. 明確版本衝突

| 主題 | 歷史文件 | 新基線 | 處理 |
|---|---|---|---|
| 牌組 | GDD及COMBAT_SYSTEM：6 Prepared Deck、可隨時選、無抽牌 | 每角12張技能卡、起手4、補至4、洗回棄牌 | **舊規則 superseded（僅此範圍）** |
| 行動系統 | 舊文件 Main/Quick/Movement/Reaction、個別行動與 d20 | 三人共享 AP＋RP 的核心流程 | 舊系統未對應者保留為TBD，不得雙重扣費 |
| 卡牌收藏 | 舊文件 Spell Card 非 collectible gacha card | 新設計有角色／卡牌雙卡池，含 R–UR | 世界觀媒介描述仍適用；經濟與取得方式由新設計取代 |
| Combo | 2026-10-14 實測用 Astral Flame Blade +1 AP | 已採納 0 額外 AP、要真正第二角色合格卡牌 | 模擬器需修正後重測 |
| 回魔 | 模擬器出現同角多次普攻多次回 MP | 每角色每回合僅第一次回MP（已確定方向） | 加測試強制執行 |
| Last Spell | 實測 Exhausted仍能被敵方指定 | 尚未決定 Exhausted 受擊規則 | 禁止假設為正式行為 |

## 5. 決策變更程序

每個 APPROVED 項目若要修正：新增 ADR（日期、提案、取捨、使用者核准）、修改本表、修改對應檔案與測試，最後更新 README。不得只在程式註解或聊天紀錄更新。


---

## 6. Phase 1 核准決策登錄表（P1-Dxx：權威裁決）

> 來源：2026-10-14 使用者逐題明確選項。所有 `APPROVED` 僅適用下表中的已表述範圍；演算法補強建議不能自動升格為核准事項。與第1～4節原草案衝突時，**本節優先**。

| Decision | Status | 決議與關鍵取捨 | 主要檔案 |
|---|---|---|---|
| P1-D01 | APPROVED | 共享6 AP，角色可不限次交錯合法動作；同人每玩家回合僅首次普通攻擊能回MP。 | 02/03/12/13 |
| P1-D02 | SUPERSEDED by P1-D09 | 原2 RP上限不再生效；原討論保留作歷史。 | 03/07/15 |
| P1-D03 | APPROVED | 基本 Guard/Protect 非卡牌、無抽牌門檻；特殊 Reaction SP 需持卡。 | 03/04/07/13 |
| P1-D04 | APPROVED | 每位角色每 Reaction Window 最多實際 Reaction 一次；不同角色可合作，非全局僅一人。 | 02/07/12/13 |
| P1-D05 | APPROVED | Smart 預設；Always Ask、Quick 可切換；UI詢問節奏不變更領域規則。 | 07/12/13 |
| P1-D06 | APPROVED | 基本 Guard 自保、Protect 保護隊友；通用基本 Evade 不採用。 | 03/07/11 |
| P1-D07 | SUPERSEDED by P1-D10 | Guard/Protect 成本選項討論結束，以 D10 最終成本為準。 | 03/07 |
| P1-D08 | APPROVED | 基本防禦只能減損、不免費反擊/干擾/特殊Combo；特殊 SP 產生額外優勢。屬性防禦成長有效；羈絆為將來候選。 | 07/10/11 |
| P1-D09 | APPROVED | 玩家階段剩餘 AP 全部1:1轉RP；不另設上限（正常≤6）；敵方階段末歸零。 | 02/03/07/12/13/15 |
| P1-D10 | APPROVED | Guard 消耗1RP，Protect 消耗2RP。 | 03/07/13 |
| P1-D11 | APPROVED | Guard 固定比例乘於角色防禦/抗性結算之後；無完整免傷保證；比例未決（40%僅候選）。 | 07/11/13 |
| P1-D12 | APPROVED | Protect 改由守護者重算防禦/抗性；自身無額外減傷。 | 07/11/13 |
| P1-D13 | APPROVED | 單體物理或魔法攻擊可 Protect；群體/多目標不可；特殊不可守護需明示。 | 06/07/11/13 |
| P1-D14 | APPROVED | 命中依附干擾隨可守護攻擊轉移；直接作用 Casting Instance 的干擾不可攔。 | 05/07/11/13 |
| P1-D15 | APPROVED | 同窗口玩家先規劃所有 Reaction 順序，確認後依序執行。 | 02/07/12/13 |
| P1-D16 | APPROVED | 已失效尚未執行 Reaction 自動跳過，零扣費、不棄卡、不計次；獨立合法後續仍執行。 | 07/12/13 |

## 7. 重大衝突解決索引（必讀）

| Conflict ID | 過時來源（LEGACY） | 正式結果（APPROVED） | 禁止行為 |
|---|---|---|---|
| C-P1-01 | A-05 / P-01 / 02 / 03 / 07 / 12 舊 `max_rp=2`、最多轉2 | D09：全部剩餘AP轉RP，正常≤6；敵方階段末清零 | 不得殘留2RP硬限制或跨回合累積 |
| C-P1-02 | P-07 / 07 舊「每窗口最多一張卡」 | D03/D04：同人1次，不同角色可在同窗口多次 | 不得禁止第二名角色響應 |
| C-P1-03 | 07 舊「沒有手牌不能反應」 | D03：基本 Guard/Protect 無需卡 | 不得對基本防禦查驗手牌 |
| C-P1-04 | 03 舊「同角普攻重複未定」 | D01：允許重複；每人每玩家回合首次才回MP | 不得每次普攻都補MP |
| C-P1-05 | 11 舊傷害順序沒有重導向 | D11/D12：重導向到守護者後重算，Guard 在一般防禦之後套用 | 不得先按被保護者防禦扣血再挪傷害 |
| C-P1-06 | 07 舊一選一單步React | D15/D16：規劃隊列+確認+失效免耗 | 不得中間每次要求重新確認或先扣未實施成本 |
| C-P1-07 | 14 舊 `D01..D23` 待決表與 P1-D 同名 | 舊題轉名 `LEGACY-Q01..Q23`；新核准ID必加 `P1-` 前綴 | 不得以純D09混指命中與RP |
| C-P1-08 | 15 v0.7.1 模擬先前 `carried RP` 和混合Ward | RP不跨輪；Barrier/FocusWard分開 | 不得把固定種子模擬結果當規則證據 |

## 8. Phase 1 仍未核准（TBD / BLOCKED）

1. **Guard 固定減傷率**：40% 是測試候選，尚未通過；最後取整、小於1傷害是否保底、真實傷害是否可擋仍待決。`APPROVED`的是「固定比例、先防禦後Guard」。
2. **Protect 事件作用域**：重導向是否作用於命中率判定、同時附加的非詠唱狀態（中毒、沉默、標記）、穿透、擊退等逐效果分類；本次只核准單體攻擊及命中綁定的詠唱干擾。
3. **多重 Protect / 同時選目標**：兩位以上守護者預先排同次攻擊，是否允許連續重轉向；若不允許哪個優先；角色喪失目標時如何處理。不能推論無限攔截鏈。
4. **手牌／RP／MP的隊列預算**：本次核准先排後確認與無效跳過，工程可用資源預留與逐步校驗實現；若隊列中後序資源不足，明確的玩家提示與編輯政策需UX細化。
5. **Smart / Quick 非阻塞 UI**：關鍵威脅門檻、沒有自動暫停時如何保證公平輸入、無障礙設定及自動略過時間機制仍需裁決；不得在核心引入反應按鍵速度優劣。
6. **Reactive SP各卡成本、功能及分類**：沒有核准任何免費「護盾+反擊」具體卡、卡牌消耗數據或自動Combo觸發。
7. **多敵人、多段攻擊與多窗口**：每個敵方行動包含多 hit 時的 Guard 覆蓋次數、特別效果在反應前後的施放點需細定。
8. **RP 非AP來源**：卡片/天賦額外生成 RP 是否允許超過6、結轉處理未定；`不另設 cap` 不能解讀成獲准無限印RP。
9. **既有系統**：HP0、Exhausted受擊、最終勝敗、命中、MP回復數字、狀態 tick、Boss AI 權重、Last Spell 量化與Combo頻率仍保留待決；參考14。

## 9. 審查可追溯條款

規格審查輸出須記錄：`decision_id`、`status`、`affected_docs`、`positive_case`、`negative_case`、`boundary_case`、`implementation_status`、`test_execution_evidence`、`revision_reference`。只要缺少可執行Godot測試log，標 `SPECIFIED/NOT_EXECUTED` 而非 `PASS`。新的 APPROVED 必須由使用者確認後新增獨立 ADR，不可直接修改舊決議欄位抹去歷史。

## 10. 後續決策覆寫與時間序列（2026-10-14）

**APPROVED 後續決策，優先於本文件相同主題的舊 TBD／舊範例**：`18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md` 正式補記 P2-D08（Critical Rate／Critical Damage 可獨立養成，細係數未定）、P2-D09（**每敵人自訂元素弱點抗性**，元素類別未核准）以及 M-D01～M-D17。尤其：

- 上方 `A-05`、§8 第8項原句「無額外 RP cap」為 **HISTORICAL / SUPERSEDED**：**M-D08 已核准預設 RP cap=6，可由明文 SP 提高**；M-D09 RP 不能跨 Enemy Phase。原始 P1-D09 的 1:1 轉換比與同階段過期仍成立。
- **P1-D01 的 Player Phase 是逐次行動**：玩家每選一個合法行動就立即執行其即時效果／開始 Full Chant，之後再自由選同一或其他角色，不先為三人預排後集體執行。和 P1-D15/D16「Reaction Window 先排後確認」是不同系統。
- 「分析型 SP」不是現行規格：**Analyze 為獨立指令**，0 AP/MP/RP，全隊每戰 2 次（P2-S02～S09），不得占每角色12卡牌組。
- **M-D04 跨多回合 Overload 債務為 PROVISIONAL 試行**；全隊 MaxAPDebt 上限架構批准，但 8 AP 數值僅 PROVISIONAL。

本段是**決議溯源與增補，不是對 Phase 1 已核准決策的抹除**；詳見 `02`、`03`、`18`。

## Phase 2 後續決策優先級（19）

**M-D18～M-D31 = 使用者逐項核准**；**P2-D10～D16 = 使用者整體同意設計方向**，不能擴張成尚未具體提出的固定係數與特殊規則。實施時以 `19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md` 為最新 SoT，先前本章中同主題 OPEN 僅歷史記錄：**CurrentAP 沒有硬 cap、MP 預設不自然回復、手牌 cap8、每人每 Player Phase 免費棄1抽1、Full Chant 中斷部分 MP 立即返還且 AP/Overload 不退**。M-D04 仍 PROVISIONAL；所有未測平衡參數不提升為 APPROVED。

## 2026-10-15 上游/目標規格 A 方案語義合併

使用者核准 A：**保留本 Godot 倉庫既有 00–24 核准內容，對照 `astraea-combat-rules@cac49361` 新增的核准規則與測試項，避免直接覆蓋較新內容。** 本次沒有重新裁決 AP/MP/RP、抽牌、Full Chant、Reaction、Break、Exposed、Combo、Last Spell、同時終局或自由走位等核心規則。來源/目標的 Phase2 19 號文件屬同一批已批准決策快照，統一以本目標的 `19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md` 作為現行檔名。CORE-01～04 最終結果見20/21；M-D04及具體倍率維持候選。新增內容25/26的初期劍士後期Variant與全民可配基礎攻治防是 USER_APPROVED；Lv40 Boss HP2700、傷害×1.7、Break22 只是 Python 測試候選，不得視為正式核准或 Godot CI PASS。對照與決策追蹤請讀 `UPSTREAM_RECONCILIATION_A_2026-10-15.md`。
