# 14 — 待使用者決定事項與 ADR 決策模板

> **2026-10-14 LIBRARY Phase 2 最新補充（現行 SoT）**：請優先閱讀 [`19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md`](19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md) 與 [`18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md`](18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md)。M-D18～M-D31 已核准；P2-D10～D16 的**設計方向**已整體核准，數值／部分結算邊界仍 TBD。較早段落的「P2-D08 未決」「換牌僅提案」「手牌上限 TBD」「完整詠唱較貴 MP」等屬歷史文字，與 19 衝突時以 19 為準。**僅 Library 更新，未同步 GitHub；尚無 Godot 執行／CI PASS 證據。**


> 這是一份「不能由 Agent 擅自補完」的決策清單。依依賴排序逐題確認，既不以一口氣問很多問題阻塞討論，也不假定沉默=同意。

> **2026-10-14 版本提醒**：本文是 Phase 1 時代 backlog；P2-D01～D07、P2-S02～S13、P2-S15～S31 **已核准，不得再次視為待決**。詳見 `16_PHASE2_APPROVED_DECISIONS_WIP.md`。下一題 `P2-D08` 尚未決定；其餘待議／Phase 2 進度請參照 `17_PHASE2_HANDOFF_AND_OPEN_QUESTIONS.md`。舊 `LEGACY-Q09` 的 d20 假說已被 P2 百分比命中取代，但具體係數仍未決。

## P0：阻塞完整實戰規則

| ID | 問題 | 推薦方向（未核准） | 影響範圍 |
|---|---|---|---|
| LEGACY-Q01 | 普通攻擊可否同角多次？ | **RESOLVED by P1-D01**：可多次，但首次每回合才回MP | 03 / AP公平性 |
| LEGACY-Q02 | RP到下一玩家階段是否歸零？ | **RESOLVED by P1-D09**：敵方階段末清零、絕不跨輪 | 02/03/07 |
| LEGACY-Q03 | HP0死亡/倒地：手牌、Casting、道具、revive如何處理？ | 停止主動行動；其他由設計者選 | 02/04/11 |
| LEGACY-Q04 | Exhausted能否被新技能選為目標、範圍傷害/治療？ | 不作一般敵方新目標，但群傷另定 | 08/11/06 |
| LEGACY-Q05 | Concentrating角色被治療、受異常、主動道具？ | 可由隊友治療、本人不使用一般道具 | 02/05/11 |
| LEGACY-Q06 | 同時到期的玩家完整詠唱、Boss蓄力、反應和回合tick的優先級？ | 事件隊列固定優先級；先精確定義時間表 | 02/05/06/07 |
| LEGACY-Q07 | 敵方行動內多個窗口的開窗政策？ | P1-D04已批准每人每窗口一次；同敵行動是否多次開窗仍待決 | 07 |
| LEGACY-Q08 | 自動觸發連鎖是否允許與最大深度？ | 有界事件隊列，循環上限 | 09/12 |
| LEGACY-Q09 | 命中/閃避/暴擊使用舊d20還是百分比？魔法必中否？ | 設計者先確定，再寫公式 | 11/13 |
| LEGACY-Q10 | 勝利／失敗／雙方同時死亡的優先級？ | 同時事件明確一個一致結果 | 02/11 |

## P1：影響卡牌與戰鬥平衡

| ID | 問題 | 選項／候選 |
|---|---|---|
| LEGACY-Q11 | 每人保留4張手牌卡死如何換牌？ | 不換／付 AP 換／每回合免費棄1抽1（未批准） |
| LEGACY-Q12 | 同名卡可裝幾張，稀有/專屬比例？ | 2張/特殊1張是提案，尚未批准 |
| LEGACY-Q13 | MP最大值與普通攻擊回魔數？ | 6/回2 vs 8/回1；請多種子對照 |
| LEGACY-Q14 | 完整詠唱中斷的MP返還、卡牌移區？ | 返一半MP、不返AP候選 |
| LEGACY-Q15 | Casting Resilience/Disruption倍率與取整？ | floor(base×倍率) 候選 |
| LEGACY-Q16 | Focus Ward/Barrier持續期限與容量？ | 依當前施法實例保留是候選 |
| LEGACY-Q17 | Boss Break恢復／失衡持續與是否取消其Casting？ | 指定可見窗口 |
| LEGACY-Q18 | Last Spell第一次/第二次失衡與死亡結算精確效果？ | 首次延後一次、第二次削弱的方向已確立，細節待決 |
| LEGACY-Q19 | Combo機會持續到何時、同時多個怎麼挑、每回合發動上限？ | 每回合最多1次、當回合失效候選 |
| LEGACY-Q20 | Boss目標選擇、同場多敵人、Phase切換？ | 公平可預告／明示條件式變招 |
| LEGACY-Q21 | 多回合狀態DOT/HoT、沉默暈眩與其他觸發的tick點？ | 依事件優先級明文規定 |
| LEGACY-Q22 | 位置範圍與移動是否耗 AP？ | 2D橫向表現，但範圍/Zone尚未定案 |
| LEGACY-Q23 | 手上 >4、牌庫/棄牌皆空、Exhausted是否抽牌？ | 卡牌守恆，行動資格與抽牌資格分開 |

## P2：產品擴充

- 角色Variant稀有度與卡片掉落保底／重複轉化。
- 高難 Boss 特殊機制與三人連攜。
- 裝備、元素抗性、位置、地形、時間／空間系魔法特殊規則。
- Last Spell個別動畫與台詞；App語系字串規範。

## 推薦逐題決策方法

每次只取**一個P0題**：先描述玩家可見情境，列2–3選項和優缺點，推薦一項，等待使用者明確核准。核准後：更新ADR、01表、對應模組及13測試，並在GitHub commit訊息註明ADR ID。

## ADR 模板

```markdown
### ADR-YYYYMMDD-NN — 名稱
- 狀態：APPROVED / REJECTED / SUPERSEDED
- 背景：玩家場景、已存在規則與衝突
- 選項：A / B / C（成本、可理解性、平衡、工程複雜度）
- 決議：由使用者明確核准的文字（非 Agent 推測）
- 範圍：更新規格、資料模型、UI、測試
- 驗收：至少一個 positive/negative/boundary replay seed
- 日期／取代的 ADR：...
```


---

## Phase 1 已完成決議（與舊待決表編號隔離）

**P1-D01～P1-D16** 是2026-10-14使用者逐題核准的 Reaction/Resource 決策，完整表見01§6；P1-D02、P1-D07已被同階段後續 D09、D10 正式取代。**本文件前面的 `LEGACY-Qxx`** 是v0.8時期尚未完成之其他問題；重名問題已消除。不要把 `LEGACY-Q09` 的命中閃避議題誤當 `P1-D09` 的 RP上限結論。

### Phase 1 決策備忘錄（簡版 ADR，可追溯）

| ADR | 用户選擇／原因摘要 | 舊方案處置 | 涉及實作 |
|---|---|---|---|
| P1-D01 | 自由共享AP，限制每人首擊回MP以防普攻刷魔 | 原先同角次數疑慮結案 | ActionEconomy/Combatant |
| P1-D03/04 | 基本防禦常駐、多人可在同窗合作、每人限一次 | 取代僅一張反應卡原型 | Hand/ReactionValidator |
| P1-D05 | Smart預設、Always Ask/Quick選項以控制中斷節奏 | 只影響UI不影響domain | Settings/ReactionHUD |
| P1-D06/D08 | Guard自身減傷、Protect守護，特殊SP提供額外效果；Bond保留未來 | 基本Evade不普遍提供 | ActionDef/SPDefinition |
| P1-D09 | 對「2RP是否過度限制」的反思後選擇剩餘AP全轉RP，不跨回合 | **SUPERSEDES P1-D02=2RP** | RP conversion/Expiry |
| P1-D10 | Guard1RP、Protect2RP | **SUPERSEDES P1-D07候選** | ResourceCosts |
| P1-D11 | Guard固定比例放在防禦/抗性之後 | 40%只是候選 | DamageResolver |
| P1-D12 | Protect按守護者DEF/RES重算，無免費減傷 | 禁止搬動受護者最終傷害 | DamageTargeting |
| P1-D13/14 | 單體物理+魔法可攔；附帶詠唱干擾可轉，直接詠唱不可 | AOE/多體不可基本守護 | EffectTags/Intent |
| P1-D15/16 | 玩家排順序、一次確認、後序失效免耗、獨立效果照常 | 禁止隱藏速度排序或預先扣費 | ReactionQueue/Events |

### Phase 2 精準決策 Backlog（OPEN，按依賴排序）

| Ref | 決策問題 | 未核准選項或關鍵條件 | 影響範圍 | 阻塞級別 |
|---|---|---|---|---|
| OPEN-P0-GUARD-PCT | Guard 固定減傷率是多少？比例取整／零傷害保底？ | 30/40/50%為平衡候選；**40%未批准** | 07/11/13 | BALANCE_BLOCKED |
| OPEN-P0-HIT | 命中、閃避與暴擊公式，Protect改目標前後何時判定？ | 舊d20 vs 百分比，必須再選 | 11/12 | DESIGN_BLOCKED |
| OPEN-P0-BARRIER-ORDER | Guard與Barrier/Focus Ward、護盾耗損的結算次序？ | 先Guard後Barrier vs 先Barrier後Guard | 05/07/11 | DESIGN_BLOCKED |
| OPEN-P0-PROTECT-STATUS | 附帶中毒、沉默、位移、標記的單體命中效果如何轉移？ | 按技能標記分類，不得一律假設 | 07/11/12 | DESIGN_BLOCKED |
| OPEN-P0-MULTI-PROTECT | 多人先後Protect同一次攻擊能否反覆轉向？ | 拒絕連鎖/只許一重導向/逐次合法 | 07/12 | DESIGN_BLOCKED |
| OPEN-P0-MULTIHIT | 多段技一次窗口可Guard幾下？TargetScope與逐Hit粒度？ | 一個Action一窗口 vs 每Hit窗口 | 06/07/11 | DESIGN_BLOCKED |
| OPEN-P0-REACTION-FAIL | 確認後執行途中因非前序取消而缺RP/MP或角色失能，應報錯/跳過/中止？ | D16只核准前序造成目標/觸發失效時的免耗 | 07/12/13 | IMPLEMENTATION_BLOCKED |
| OPEN-P0-LIFE | HP0、Incapacitated、Exhausted能否被敵方指向/被保護/治療？ | 仍保留舊LEGACY-Q03/04 | 02/08/11 | DESIGN_BLOCKED |
| OPEN-P0-OUTCOME | Boss/全隊同時死亡、Last Spell解算和勝敗順序？ | 仍保留舊LEGACY-Q10 | 02/11 | DESIGN_BLOCKED |
| OPEN-P1-SMART | Smart/Quick 閾值、非阻塞React的公平窗口、無障礙/手把操作 | 禁止默默改勝敗或自動花RP | 07/UI | UX_BLOCKED |
| OPEN-P1-EXTRA-RP | 未來SP/天賦是否產額外RP、超過6怎辦？ | 不設RP cap≠批准無限印RP | 03/12 | FUTURE |
| OPEN-P1-BOND | 羈絆Protect額外減傷的啟動/疊加/倍率/優先級 | 僅未來候選，**不在MVP** | 10/11 | FUTURE |
| OPEN-P1-SP-REACTION-COST | 特殊SP各自RP/MP/觸發、護盾、反擊、Combo配方 | 目前只有效果類別，無正式卡面數字 | 07/09 | BALANCE_BLOCKED |

### 決策審核模板與階段出口

- 一個 Phase 2 問題只需一次提出一個具體玩家情境、2～3方案、推薦與反例，使用者明確選擇才改 APPROVED。
- 更新 01 決策表、受影響模組與13測試；保留既有決策被覆蓋的連結，禁止直接刪除爭議歷史。
- Phase1退出標準：16份文件間規則一致、01/07/12/13具可測契約、14未定完整揭露、GitHub與Library實際回讀內容一致。這**不等同 Godot戰鬥模擬器或UI實測已經通過**。

## 最新快照校正：已核准與尚未決（2026-10-14）

**P2-D08、P2-D09 已核准；M-D01～M-D17 已獲使用者逐題選擇（M-D04 只是 PROVISIONAL 試行）**，詳見 `18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md`。本文件上方舊「下一題 P2-D08」與「額外 RP 未決」為**歷史 backlog**，不能當作目前 OPEN：M-D08 已核准一般 RP cap=6，只有特定 SP 能提升；M-D09 已核准 RP 不跨 Enemy Phase。尚未裁決：當回合 `CurrentAP` 的額外容量上限（下一題 M-D18）、減費非數值覆寫優先級、Full Chant 中斷退款、P2-D10～D16 及其他原先明確 TBD 項目。**新的 ADR 應先核對最新 18，不能重複問已核准事項。**

## 最新決策清單：Phase 2 已收斂，以下只剩配置／工程邊界

**M-D18～M-D31 為 APPROVED；P2-D10～D16 設計方向經使用者整體批准**。舊 backlog 之「P2-D08 尚未決」「MP退款完全未決」「免費換牌 PROVISIONAL」「8張手牌上限 OPEN」已過時。現在仍須 CONFIGURABLE / TEST：普通攻擊恢復 MP 值、BaseMaxMP 與成長、Full Chant Casting Interrupt 部分 MP 返還比例／取整、傷害最後取整算法與 chipDamage、Guard 比例、Buff/DoT 實際時效、倒地/復活細節、同時死亡事件排序、MaxAPDebt 數值(8為候選)與 M-D04 跨輪負債 PROVISIONAL 試行。**不必為一般細節逐題要求使用者選 A/B/C**；只在影響核心玩法的大決策時再請其介入，配置以測試報告佐證。

## 2026-10-14 Phase 1–2 實作前清查裁決（現行狀態以20為準）

使用者本輪明確授權「幫我決策後更新 Library、推 GitHub」，允許對普通工程細節設定 **DELEGATED_DEFAULT**；這與舊版「每個 P0 只能逐題詢問」是不同的本輪工作授權，**不代表過去使用者逐題批准所有數值**。全面清查結果與 PRE3-R01～R18 見 [`20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md`](20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md)。

**歷史 OPEN 改列 RESOLVED_PREVIOUSLY：** P2-D08/09、P2-D10～16（方向）、M-D18～31、手牌補4上限8、免費換牌及順序、RP常態cap6、HP0 Incap（基本方向）、百分比命中。**由 DELEGATED_DEFAULT 處理：** Protect/Guard次序、多段Scope、多 Protect、狀態跟隨標記、隊列二次驗證、Barrier分離/先後、打斷／倒地移卡、換牌異常、確定性 Tick、Exhausted合法目標。**仍保留 BALANCE_PROVISIONAL：** Guard40%、首擊回魔2、MaxMP6/8/12、退款50% floor、APDebt8、浮動±5%等。**真正 CORE_CONFIRM：** 雙方同時殲滅後 DRAW/英雄勝利、Last Spell 詠唱者HP0後仍結算、是否擴充戰術走位、Smart/Quick限時公平性。其餘卡牌配方/敵人權重/狀態明細為 CONTENT_DEFERRED。實作狀態與測試證據另計。

## 2026-10-14 四項核心選擇已由使用者核准
`CORE-01`：同一合法結算雙方全滅，**玩家 VICTORY / 劇情通關**（取代早期 DRAW 提案）。
`CORE-02`：**尚未釋放** Last Spell 的施法者 HP0 時立即 forced invalidation、取消待效法術（取代 PRE3-R15「死後續唱」候選），不退 AP/MP/Overload、不恢復使用權；不可玩家主動取消及合法干擾的延遲/削弱機制仍有效。
`CORE-03`：**無玩家自由走位**；2.5D 畫面可以使用，表現不影響規則與現有 range_tag。
`CORE-04`：Reaction **沒有真實時間強制倒數**，有合法反應時必須由玩家明示 Confirm/Pass；Quick 僅 UI 精簡。
以上皆 `USER_APPROVED / CLOSED`，不再列為 CORE_CONFIRM。詳細 `20` 與規格驗收紀錄 `21_PHASE2_SPEC_ACCEPTANCE_REPORT.md`。