# 18 — 魔法／AP 行動經濟核准決策（M-D01～M-D17）與 Phase 2 最新補記

> **Documentation status · 2026-10-15 — APPROVED_P2_D08_D09_AND_M_D01_D17**：P2-D08/09、M-D01～17 已核准之方向仍有效；M-D04 的跨輪債務為 PROVISIONAL，M-D18～31 與 P2-D10～16 見19，CORE-01～04 見20/21。 先讀 [Combat Spec Index](COMBAT_SPEC_INDEX.md)；目前未驗證項目見 [Open Issues](COMBAT_OPEN_ISSUES.md)。**M1～M5.4 1,081 項 Domain CI 有證據，M5.5 仍未驗證。** 舊正文的「當時狀態」僅供歷史追溯，不得升格為新核准或新 CI。


> **後續決策更新**：此檔只記錄 M-D01～M-D17。M-D18～M-D31、P2-D10～D16 設計方向已核准，請繼續閱讀 [`19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md`](19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md)。M-D04 跨輪債務仍是 PROVISIONAL。


> **決策快照：2026-10-14｜設計狀態：M-D01～M-D17 已逐題選擇；M-D04 為「試試看 B」的 PROVISIONAL 試行，並非不可變更的最終平衡結論。** 本文件記錄玩法契約，不宣告 Godot 實作、CI 或平衡測試通過。
> **閱讀順序：** 先讀 `00`、`01`、本文件及 `02`／`03`；較早 `16`／`17` 中「P2-D08 未決」「P2-D09 未決」的快照文字已失效。P1 核准契約仍有效，除非後續決策明確擴展（如 RP cap 規則）。

## 1. P2-D08、P2-D09 補記（APPROVED）

| ID | 核准決議 | 尚未核准／不得誤推 |
|---|---|---|
| **P2-D08** | `CritRate` 與 `CritDamage` 為兩個**可獨立養成**的角色屬性；命中後才判定暴擊；暴擊率可經技能/狀態加成或明文保證暴擊，暴擊率限制在 0%～100%；`CritDamage = NormalHPDamage × (1 + CritDamageBonus)`。保證暴擊不等於必中，僅符合資格的 HP 傷害受影響；不自動增強 Break / Casting Disruption、製造 Exposed / Combo 或免費 AP/RP。 | 初始暴擊率、暴擊傷害係數、各段攻擊判定單位、結算順序與取整仍 TBD；不同卡的魔法暴擊資格仍由卡明定。 |
| **P2-D09** | 元素弱點／抗性採**敵人個別配置**而非全遊戲通用相剋表。相同學科或類似種族的敵人也可以不同弱點；魔法學科分類不等於戰鬥元素，一張複合學科 SP 可以只配置一個主要戰鬥元素。 | 七自然學科＋無屬性的戰鬥元素候選集合**尚未核准**；單一技能何時額外削 Break、複合元素計算、元素倍率與結算順序皆不能擅自推定。 |

## 2. 已決策：魔法/AP/RP/Overload（M-D01～M-D17）

以下 `APPROVED` 表示使用者已選擇所述方向；未列出的固定數字、技能效果及例外均非自動核准。

| ID | 狀態 | 正式規則 |
|---|---|---|
| **M-D01** | APPROVED B | **受控資源型 AP 經濟**：全隊每 Player Phase 基線 6 AP 是起點，不是每回合可執行行動的硬上限。個別 SP 可即時增加 AP、在條件達成後返還 AP、減少其他 SP 的 AP 成本、賦予下一個 Player Phase 的 AP 增益；少數帶 Overload 的 SP 可預支未來 AP。沒有批准全域「每回合最多幾張 SP」硬限制。 |
| **M-D02** | APPROVED B | Overload 必須由**該 SP 明確標示資格**，非全角色／全 SP 通用行動；角色天賦解鎖 Overload 只能視為**未來擴充**，目前不實作。 |
| **M-D03** | APPROVED C | 各 Overload SP 自行定義 `MaxBorrowPerCard`；實際借用量是有效成本超過當前 AP 的**不足差額**，不能任意超借。 |
| **M-D04** | **PROVISIONAL B** | 使用者選擇「試試看 B」：未還的 Overload APDebt **暫定可以跨多個 Player Phase** 持續償還，可能造成整回合 0 AP；不因過一回合而自動免債。必須透過模擬驗證體感，保留調整權。 |
| **M-D05** | APPROVED B（數字暫定） | 設定獨立的**全隊最大 AP 債務** `MaxAPDebt`，與每張 SP 的借用上限同時成立。**8 AP 只是 PROVISIONAL 調校候選**，不是最終核准數值；不得無上限負債。 |
| **M-D06** | APPROVED B | 每個 Player Phase 開始：`Pool = max(0, BaseAP + APBonus)`；`CurrentAP = max(0, Pool - PriorAPDebt)`；`RemainingAPDebt = max(0, PriorAPDebt - Pool)`。同一 AP 只能用一次：先抵舊債，再留下可使用 AP。跨期增加的 AP Bonus 也可償債。 |
| **M-D07** | APPROVED A | 當回合所有可使用 AP **匯入同一個全隊共享 CurrentAP 池**，不區分自然回復、SP 增益或即時返還來源；Player Phase 結束時未用 AP 以 1:1 轉 RP，受 RP cap 限制。 |
| **M-D08** | APPROVED B | **預設全隊 RP cap = 6**；明文特定 SP 可於相應 Enemy Phase **提高 RP cap**（例如 9 僅為示例），讓剩餘 AP 可以轉出超過 6 RP。單純增加 AP 不會隱含提高 RP cap。這是對早期「沒有額外 RP cap」文字的**後續明確覆寫**。 |
| **M-D09** | APPROVED A | **RP 無條件於緊接的 Enemy Phase 結束後歸零**。任何 SP 不能讓 RP 留存至更後面回合；持續的 Barrier / Focus Ward 等是不同狀態，不等於持續 RP。 |
| **M-D10** | APPROVED B | 減費 SP 可以個別設定**持續時間、適用 SP／角色／條件、使用次數**；不是一律只減下一張，也非一律整場持續。減費不能憑超額折扣額自動變成 AP 返還。 |
| **M-D11** | APPROVED B | 多個合格的**數值型 AP 減費可累加**：`EffectiveAPCost=max(0, BaseOrChosenAPCost - sum(EligibleAPDiscounts))`；Overload 依此最終有效成本判定缺額。設定成本為 0 等非數值特殊覆寫的優先序仍 TBD。 |
| **M-D12** | APPROVED B | **不設全域每回合 SP 出牌數上限**。0 AP 出牌合法但仍受 MP、手牌、時序及其他成本；抽牌、回收、返 AP 等必須用單卡條件／使用次數／有限資源避免無成本無限循環。引擎需事件循環防護，但不等同遊戲硬性出牌上限。 |
| **M-D13** | APPROVED B（修正版） | **僅特定 SP** 可由玩家在該卡允許範圍內自選 AP **宣告投入量**；投入量決定效果規模，**破棄詠唱／完整詠唱是獨立維度**，決定施法風險、時序與卡明文差異。減費不降低已宣告的投入等級。具 Overload 標籤者才能透支。 |
| **M-D14** | APPROVED B | 可變 AP 的效果以**宣告投入量**而非實付 AP 決定，合格減費甚至可讓高投入效果實付 **0 AP**。`ActualAPCost=max(0,ChosenAPInvestment-EligibleAPDiscounts)`；`EffectStrength=f(ChosenAPInvestment,CastingMode)`，函數細節由 SP 定義。 |
| **M-D15** | APPROVED A | Overload **只有 AP 不足時才可補足差額**，AP 充足時不能主動選擇透支以保留當回合 AP。順序：宣告投入／模式 → 合格減費 → 有效成本 → 若不足且 SP 有資格，校驗逐卡及全隊債務上限 → 支付 AP／建立債務。 |
| **M-D16** | APPROVED B | 當前 Player Phase 中 SP **即時返還 AP 直接進 `CurrentAP`**；**不自動還 Overload 債務**。該 AP 可供繼續出牌或回合末轉 RP（遵守 cap）；未償債務在未來 Player Phase 依 M-D06 清償。 |
| **M-D17** | APPROVED B | **特定 SP 可明文 `Reduce AP Debt`**，但須具有有效成本、觸發條件或使用次數限制；只減少尚未償還債務、不直接增加當回合 `CurrentAP`，不得形成無限免費清債循環。完整清債效果不是一般通用權限。 |

## 3. Player Phase 與 Reaction 的既有核准界線（P1-D01、P1-D15/16）

> **Player Phase 採逐次行動、按效果時序結算（Sequential Action / Immediate-or-Scheduled Effect Resolution）**：玩家每次從任一合法角色選擇**單一合法動作**，先校驗及支付後立即執行其合法即時部分，完成此動作應有的結算，再自由選擇**同一名或其他角色**執行下一個合法動作，直到主動結束 Player Phase。**不是全隊三角先排完所有行動才一起執行；也不強制三人輪流。**

- **Full Chant 例外**：提交動作當下開始 Concentration 並成立 CastingInstance，**後續魔法效果在其規定時點**完成；不得誤解成提交時必已造成延遲魔法傷害。精確同時事件次序仍 TBD。
- **Reaction Window 相反**：已核准多名角色 Reaction 先以佇列排序，玩家確認後依序驗證及執行；後序因前序導致觸發條件失效者 **SKIP_WITHOUT_PAYMENT**。這不是 Player Phase 的全隊統一排程。
- **Analyze 不屬於 SP**（P2-S02）：所有角色可用的獨立情報指令，0 AP／MP／RP，每場全隊共享 2 次主動解析；可在 Player Phase 或尚未確認的合法 Reaction Window 使用，不能插入已開始的效果結算、不佔 Reaction 配額、不直接製造 Exposed。分析專長角色另有被動觀察（P2-S09），不是「分析型 SP」。

## 4. 待決／必須維持 TBD 的邊界

- **M-D18（下一題）**：當回合獲得大量即時 AP 後，是否為 `CurrentAP` 設獨立容量上限？尚未決策；全隊 `BaseAP=6` 不等於 `CurrentAP` 硬上限，RP 預設 cap 6 則已確定。
- RP cap 增加 SP 的效果期限、最高上限與完整模擬測試；AP 增益是否可疊加、超量的即時 AP 如何處理，均未另訂數值。
- AP 減費中的「設定成本＝0」、特殊最低支付成本、同時減費的**消耗順序／優先度**，尚未決策；已核准的只有合格**數值型**效果可相加，最低 0。
- 跨回合 MP / AP / RP 交互作用的卡面細節、Overload 尚未確認的精確 UI、減債 SP 卡數值與免費資源連鎖平衡、退費時序（尤其詠唱被打斷時 AP 或 MP 返還）仍未完成。
- **P2-D10～D16 仍 OPEN**：完整傷害結算順序、取整／最小傷、Barrier/Focus Ward 詳細規則、Buff／Debuff／DOT、HP0／復活／Exhausted 邊界、勝敗、數值模擬與驗收。
- M-D04 跨回合債務試行及 M-D05 `MaxAPDebt=8` 示意值都不得寫成不可更動的正式平衡承諾。
- 魔法學科的 20 類世界觀候選、七自然元素作為戰鬥元素的全集、卡牌樣板和傷害倍率**沒有因為 M-D 系列而自動核准**。

## 5. 核心流程驗收案例（規格，非實測）

1. **自由行動順序**：角色 A 行動 → 立即結算 → A 再行動 → B 再行動；不要求 C 已選指令才開始動畫／傷害。
2. **完整詠唱**：A 提交 Full Chant → 扣合法成本並建立 CastingInstance → B 可依合法狀態行動 → 法術到期時才結算實際效果。
3. **跨階段 RP**：BaseAP 6，Player Phase 末餘 2 → RP 2；Enemy Phase 末 RP 0，無論是否使用。額外 AP 不自動將 RP cap 提升至超過 6。
4. **透支＋返還**：CurrentAP 1，SP 實付 3 且允許借 2 → CurrentAP 0、APDebt 2；合法成功觸發返還 2 AP → CurrentAP 2、APDebt **仍為 2**。
5. **減費＋可變投入**：投入 4，合格折扣 1+3 → 實付 0，效果仍以投入 4 + CastingMode 計算。
6. **減債非補 AP**：CurrentAP 2、APDebt 4，合法 `ReduceAPDebt(2)` 效果 → CurrentAP 2、APDebt 2（不變成 CurrentAP 4）。
7. **Analyze 零 AP**：使用 Analyze 選擇未知敵方情報，不消耗 AP、手牌、反應次數；2 次耗盡後當場不能再主動解析，已知情報仍免費看。
8. **反應佇列**：A/B 反應先排再確認；A 成功取消敵方行動，B 若因失去合法目標而跳過，不扣 RP／MP／卡，且不消耗 B 反應配額。

> **文檔狀態與 GitHub / Library 的同步情況需以實際寫入、讀回及 SHA 檢查為準**。本文本身不是同步成功證明。