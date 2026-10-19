# Arbitrium Nexus — 統一魔法系統設計 v0.4
## 學科 × 傷害共鳴 × Buff／Debuff × Overload × Weakness／Break／Exposed

> **狀態：INTEGRATED DESIGN PROPOSAL / NOT A NEW COMBAT RULES BASELINE / NOT IMPLEMENTED**  
> 更新：2026-10-19　｜　Repo 基準：`master` `8e16c8f4e7205d256b230953fd9dda07087a90a1`  
> 本文件**統一替代先前 v0.1、v0.2、24 學科矩陣 v0.1 和 v0.3 的閱讀入口**，舊版本保留為研究歷史。  
> **已由使用者明確確認**：世界觀可以深且複雜，實戰須簡單、易懂、優先重用現有機制。  
> **這次僅核准「整合成一個設計版本並推送」**；不是核准 24 學科全部內容、任何新卡數值、Overload 平衡調整或新 Domain 能力。  
> **權威優先序**：`docs/combat/README.md` → 對應現行中文戰鬥規則／最新 USER_APPROVED 決策 → 工程契約與實際代碼；**本文件的戰鬥描述是對現有規則的索引與映射，不構成覆寫**。  
> 變更範圍僅 `docs/combat/proposals/`：**不更動 `master`、Domain、既有卡、CI、i18n、UI、Replay 或遊戲平衡**。

---

## 0. 統一設計結論（給玩家與 Codex 的最短版本）

**一張卡，玩家只需知道：這張卡對誰、花多少 AP/MP/RP、現在還是下階段生效、主要做什麼、是否有特殊條件。**

遊戲背後可保留 24 個魔法研究學科；學科**不等於**抗性、職能、施法速度、卡牌稀有度或自動附加的 Buff／Debuff。技能實際效果由**已有 Domain 規則、逐張合法配置、事件順序**決定。

```text
世界觀研究（24 個候選學科）
   └── 圖鑑／身份／術式敘事與可選的複合學科
        ↓ [不直接改遊戲數值]
卡牌定義（CardDefinition / Owner / Eligibility / Casting / Costs / Effects）
   ├── 效果語法：Damage、Heal、Barrier、Focus Ward、Status、Disruption、Break 等
   ├── 傷害共鳴：每段合格 HP Damage 對每名敵人的抗性，非學科自帶倍率
   └── 特別支付：僅合格卡片的 Overload → APDebt；不是另一種元素
        ↓ [真實支付、目標合法性、時序與事件]
既有 M1～M5 Domain / ordered DomainEvents / Replay
        ↓
玩家 UI：目標／成本／效果／詠唱／弱點／狀態／可反制的威脅
```

唯一可實作玩法來源依然是現行 `docs/combat/` 規格和正式核准的版本化 Card Content。

## 1. 六個彼此正交的概念層

| 概念層 | 回答的問題 | 典型欄位／概念 | 不應自動產生 |
|---|---|---|---|
| **Discipline 研究學科** | 施法操縱什麼？ | ARCANUM、PYROMANCY、CHRONOMANCY 等**候選敘事標籤** | 戰鬥倍率、元素相剋、詠唱時長 |
| **Damage Kind** | 這段是否造成物理或魔法 HP 傷害？ | 現有 PHYSICAL／MAGICAL 與對應攻防 | 「真實傷害」等未授權新 kind |
| **Damage Affinity / Resistance** | 這段傷害遇到誰的弱點／抗性？ | 現有 FIRE／ARCANE／NEUTRAL Lv40 fixture；後續全集待決 | 火一定剋冰、雙學科雙倍相剋 |
| **Effect & Status** | 實際觸發什麼效果？ | Damage、Heal、HP Barrier、Focus Ward、BUFF、DEBUFF、DOT、HOT、Break 等 | 火系必燃燒、時間系必跳階段 |
| **Access / Cost / Casting** | 誰能用、何時能用、付出什麼？ | UNIVERSAL／ROLE_TAG／CHARACTER／VARIANT、AP／MP／RP、Instant／Dual／Full、個別 Overload eligible | 所有高階魔法免費超載 |
| **Presentation / Readability** | 玩家看得懂什麼？ | 一個主效果、成本、目標、時機、公開資訊、Tooltip | UI 自行修改結算、從 FX 顏色推算傷害 |

重要命名差異：**`ARCANUM`** 為研究提案中的「純魔力、符文與術式工程」學科；實際 `ARCANE` 是既有 Lv40 的傷害共鳴標籤；`ROLE_TAG:ARCANE` 則是卡牌資格標籤。三者**絕不混用為同一 Enum**，也不更名現有 ID。

## 2. 24 個魔法研究學科／七群（候選，不是 24 套 Domain）

| 學派群 | 學科 ID：名稱 | 研究主題 |
|---|---|---|
| 物質與自然（6） | `PYROMANCY` 炎熱、`HYDROMANCY` 水流、`CRYOMANCY` 寒霜、`AEROMANCY` 風氣、`GEOMANCY` 地脈、`FULGURMANCY` 雷電 | 熱、液態、結晶、氣流、岩石、電磁 |
| 光與影（2） | `LUMINOMANCY` 光輝、`UMBROMANCY` 幽影 | 光學訊號、遮蔽 |
| 生命與靈魂（2） | `VITAMANCY` 生命、`SOULCRAFT` 靈魂 | 生理恢復、靈性身份 |
| 時空法則（3） | `CHRONOMANCY` 時間、`SPATIOMANCY` 空間、`CAUSALITY` 因果律 | 何時、何處、條件→結果 |
| 心智與感知（4） | `COGNITION` 認知、`SENSATION` 感覺、`EMOTION` 情緒、`ONEIROMANCY` 夢境 | 理解、感官輸入、情感、內在夢境 |
| 構造與規約（3） | `ARCANUM` 奧術、`CONTRACT` 契約、`NOMOMANCY` 秩序 | 魔力結構、約定、規律 |
| 形上與可能性（4） | `FATEMANCY` 命運、`NIHILOMANCY` 虛無、`ONTOMANCY` 存在、`CHAOMANCY` 混沌 | 可能性、消散、本質、變化 |

**設計約束：** 保留 24 研究領域，**不**表示每科都須首發可玩、各有一種抗性、彼此一一相剋，或每科至少有一張換色技能。只有帶來可理解的**獨特決策**且能通過合法性、反制和 Replay 驗證，才進入可玩卡池。否則保留於圖鑑、職能背景或 Boss 劇情。

三組易混淆差異：
- **時間**操縱持續與時序；**因果**操縱條件到結果；**命運**描述未來可能性的偏向；**混沌**描述合法分支的變動。都不是現成可隨意修改 RNG 的權限。
- **認知**影響理解／記憶；**感覺**影響感官輸入；**夢境**影響內在經驗；**情緒**影響情感動機。都不天生取得敵方隱藏意圖。
- **幽影**是遮蔽；**虛無**是缺席／消散；**空間**是相對位置；**存在**是本體身份；**秩序**是規律；**契約**是約束／交換。抽象概念的宏大不等於技能數值更強。

**奧術的最終提議定義**：研究純魔力結構、符文、術式、護唱與魔力屏障；不是任何魔法的萬能上位類。範例 U01 奧術彈可作學科 ARCANUM 候選映射且保留 ARCANE 傷害屬性；U02 魔力屏障可作 ARCANUM 敘事，但不是「ARCANE 護盾抗性」。兩例都**不改**現有卡牌數值。

## 3. 戰鬥系統已有的 Buff／Debuff 與持續狀態

### 3.1 三層真實性

**已確認的規則**：狀態分成增益、減益、DoT、HoT、屏障等，每個生效點、到期點、層數、覆寫、驅散與事件順序由個別定義決定；不得把 Status、護盾、Focus Ward 和 Break 混為一條表。

**可查到的程式能力**：
- `scripts/domain/m5/status/status_resolver.gd` 定義 `DOT`、`HOT`、`BUFF`、`DEBUFF`、`BARRIER`，有 `STACK / REPLACE / REFRESH / IGNORE` 政策；StatusInstance、tick_trigger、duration_ticks、priority、dispel_tags 等受驗證。BUFF／DEBUFF 定義可指向 `patk / pdef / matk / mdef / accuracy / evasion` 的 `stat_id` 與 `stat_delta`。
- `tests/fixtures/m5_2_fixture.gd` 使用 `rage`（BUFF，`patk +14`）和 `frail`（DEBUFF，`pdef -10`）作**專用測試例**；不是在現有 Lv40 牌組普遍可玩。
- `scripts/domain/m5/lv40/lv40_content.gd` 有 `SCORCH_TEST`，`DOT`、`REFRESH`、兩次敵方階段末各 `45` HP 傷害的 **Lv40 provisional fixture**；不是火元素統一公式。

**尚不應聲稱已實裝**：全域睡眠、冰凍、恐懼、石化、致盲、洗腦、暈眩、隨意延長任意狀態的通用效果。新增狀態仍須命中、目標、抗性、優先權、驅散與 Replay 逐項定義。

### 3.2 Buff、Debuff 與其他相近概念的界線

| 概念 | 玩家理解 | 結算歸屬與限制 |
|---|---|---|
| **Buff** | 暫時強化一項能力或下一次合法行動 | Stat modifier 或個別明示的「下一卡強化」；不表示所有 Buff 都是 StatusInstance |
| **Debuff** | 暫時削弱敵人的明示能力 | 按合法目標、期限、可驅散條件設計；不預設「讓 Boss 不能動」 |
| **DoT / HoT** | 指定時點的傷害／回復 | 有 tick trigger、層數與時序；DoT 是否受 HP Barrier 依定義 |
| **HP Barrier** | 吸收合格 HP 傷害 | 不吸收直接 Casting Disruption |
| **Focus Ward** | 保護某一有效 CastingInstance 的穩定度 | 不能當普通 HP Barrier |
| **Break / Exposed** | Boss 行動弱化／一次性攻擊機會 | 獨立戰術資源，不可用一般 Debuff 覆蓋其流程 |
| **Incapacitated / Exhausted** | HP0 失能／終式成功退場 | 屬生命周期與目標資格；不是可清除的普通 Debuff |

**既有卡例（成本與數值為候選）**：
- `A03 凝火`：自己下一張合法成功魔法 SP 的 HP 傷害 `+20%`；個別強化效果，別隨便對應成任意可疊 BUFF。
- `A07 紅蓮餘燼`：命中後可施加上列 `SCORCH_TEST` 持續傷害。
- `A08 超越限界`：下一張合法魔法 SP 的合格 HP 傷害 `+30%`，每戰有候選次數限制；**不在目前起始牌組**。
- `T02 淨化祈禱`：移除一個合格 `DISPELLABLE` Debuff；**不在目前起始牌組**，不淨化 EXHAUSTED／INCAPACITATED。
- `U02 魔力屏障` 和 `U03 專注護符`：前者 HP Barrier，後者有效施法實例 Focus Ward。

### 3.3 學科應如何使用狀態

學科只是**題材／可能的專精方向**，不會自動上狀態。例：火焰可能專精部分合法 DoT；寒霜可能偏向明示減益；情緒可能偏向明示護唱；認知可能作情報支援。但**燃燒、凍結、恐懼、混亂**皆須各張卡明確效果與獨立核准機制，不能只靠學科標籤成立。

## 4. Overload（AP 超載）——屬成本策略，不是新元素或學科

### 4.1 現行概念與支付流程

- 全隊玩家階段基準 `6 AP`，不是每人 6；當期 CurrentAP 可因合法效果超過基準，不應額外加 6 的暗上限。
- 只有被明示標記 `overload_eligible` 的卡，在**實際 AP 不足**時，才可以合法借差額。每張卡有 `max_borrow_per_card`，全隊債務受版本化 `max_ap_debt` 限制。
- 合法超載先支付當期可支付的 AP，其餘進 **APDebt**；`CurrentAP` 不會負值。未來玩家階段 `base AP + 合法 bonus` **先還債**，剩餘才成為可用 AP。
- 一般「返還 AP」**不自動沖銷既有 APDebt**；只有明示 `ReduceAPDebt` 的效果才可能減債。
- `MP` 仍由該角色支付；Overload **不**等於 MP 免費、無風險額外回合或轉換成 RP。
- 完整詠唱受合法中斷所退還的**部分 MP**，不退 AP 或取消 Overload 債務。終式若於釋放前因 HP0 強制失效，已付 AP/MP、超載債務及本場使用次數都不退。

```text
假設：共享 AP=1，某卡花 3AP 且可借 2AP
→ 支付當期 1AP，產生 APDebt=2
→ 若下一玩家階段基準 6AP 且無其他修正
→ 先償 2AP，只剩 4AP 可行動
```

注意：此例僅說明成本計算；**不代表某張現役 Lv40 卡已獲准借款**。

### 4.2 已有程式與待審平衡

- `scripts/domain/m2/economy/overload_debt.gd`：`borrow_quote` 檢查卡片資格、單卡借款限制、總債務上限；`open_player_phase` 處理還債。
- `scripts/domain/m2/economy/cost_resolver.gd`：成本交易產生 `ap_borrowed`、支付及債務事件；拒絕非法費用。
- `resources/combat/rulesets/m2_2_provisional_costs.json`：`max_ap_debt=8` 和 `PROVISIONAL_MULTI_PHASE` 是**測試／平衡候選，不是永遠固定的已核准公式**。
- 檢查目前 `lv40_content.gd` 未見當前 starter magic 被明示設成 `overload_eligible`；**引擎支持機制 ≠ 現有角色拿得出可超載的正式技能**。完整真人操作仍須另行驗收。

### 4.3 與學科的關係：提案，而非免費特權

Overload 是**技能特性**，不是「混沌／命運／時間必定有超載權限」。高階術式可被設計為超載候選，作為短期火力與未來 AP 防禦資源之間的取捨；但須考慮 `AP→RP` 共享、守護需求與詠唱風險。若每種學科都能自由超載，就失去獨特策略代價。

## 5. Weakness、Break、Exposed：不要混成一個「弱點」Buff

### 5.1 Weakness / Resistance —— 逐敵人 HP 傷害係數

同一段合格傷害有 Damage Kind、可選 Damage Affinity 與由**受擊敵人自己的**配置給出的抗性／弱點。物理和魔法基礎攻防先後遵從既有傷害管線。**不建立全域火剋冰輪**。

現有 `TEST_BOSS_ARCANE_SENTRY` Lv40 候選例（均非全遊戲正式值）：

| Affinity | 該 Boss 候選倍率 | 含義 |
|---|---:|---|
| `FIRE` | ×1.15 | 火系 HP 傷害相對弱點 |
| `ARCANE` | ×0.90 | 奧術 HP 傷害相對抗性 |
| `NEUTRAL` | ×1.00 | 中性傷害 |

*先前完整元素清單仍未核准*；`PHYSICAL` 是 Damage Kind 不是元素。`NONE` 代表該支援／治療效果不進 HP 傷害共鳴計算，不等於中性傷害 `NEUTRAL`。

### 5.2 Break —— Boss 本體的行動弱化條

- 合格技能有獨立 `break_damage`，才可消耗 Boss Break Gauge；`6 Break ≠ 6HP ≠ 6 Casting Disruption`。
- 歸零觸發後，影響**下一次符合條件且尚未開始的 Boss 行動**（如降級或 fallback），不能事後刪除已完成或已開始結算的攻擊。
- 多 Hit 技能需按整張 SP 的合法效果完成後，在規定時點判 Break；不得第一次命中就自行終止後續 Hit。
- 與敵方公開 `Intent` 連動：玩家應能理解哪些行動可失衡、何時會改為 fallback。`Lv40` 現行 `break_max=22`、fallback `B11` 是**版本化 Boss 候選 fixture**，不是全敵共同上限。

### 5.3 Exposed —— 敵人條件觸發的一次性破綻

- 特定 Boss 姿態／指定技能／事件才可建立合法 `Exposed`；`Analyze` 不會免費上 Exposed。
- **同一張 SP 不能自己建立又立即利用該 Exposed**；後續另一張符合條件的 SP 才能消耗。
- 成功利用後消耗；失敗／失手後保留與否及有效期限由現行具體配置定義，不能默默無限疊層。
- 示例：`R01 破勢斬` 或 `R07 戰隙誘引` 在特定 Boss `CORE_OPEN` 姿態下才可能建立 `Exposed`。**但其攻擊 Combo Opportunity 在 2026-10-17 已核准不依賴 CORE_OPEN**，兩者嚴禁混為一個門檻。

### 5.4 Casting Disruption —— 施法實例的穩定度

`Casting Stability` 屬**某一次 CastingInstance**，與 Boss 本體 Break Gauge 不同；`Focus Ward` 先吸收詠唱干擾。一般合法 Full Chant 被打斷有專用 MP 部分退款；Last Spell 有**延遲／削弱專用規則**，除施術者釋放前 HP0 才強制失效。不能因技能叫「破魔」就同時扣 HP、Break 和 Stability，除非 Card Effect 逐項明示。

### 5.5 從玩家角度四者如何辨識

| 玩家看到 | 需要顯示的真實資料 | 讓玩家做的抉擇 |
|---|---|---|
| **元素弱點** | 公開且合法揭示的 Affinity／抗性 | 這個 Boss 適合哪一種攻擊？ |
| **Break 條** | 真實 Boss Break Gauge、可削減效果 | 先壓制下一次敵人行動，還是直接輸出？ |
| **Exposed 標記** | 真正已建立的弱點機會、合法消耗時機 | 誰用下一張符合條件的牌追擊？ |
| **Casting Stability** | 目前有效施法實例與已公開的可干擾條件 | 用干擾破術，或用 Guard／Protect 挺過去？ |

不顯示伺服器／Domain 尚未公開的額外敵情資訊；UI 顏色、圖示與數字只投影 Domain，不得自行建立 Exposed 或重算 Weakness。

## 6. Buff／Overload／Weakness／Break／Exposed 如何產生戰術深度

可理解的「一張卡一個主要目的」並不阻止**已有規則之間的組合**，但請勿把以下假設當成新的已核准配方：

| 合法或候選的情境 | 玩家選擇 | 不得暗改的規則 |
|---|---|---|
| **Buff → Full Chant → Boss 弱點** | 現在花 AP 強化下一張攻擊，還是立刻小傷害？ | Buff 只在它本來的有效時點生效；雙詠唱照卡定義支付 |
| **造成 Break vs 留 AP→RP** | 多花 AP 爭取讓 Boss 下招降級，或留資源在敵方階段 Guard／Protect？ | RP 常態上限依現行配置；不是用 Break 直接免費給 RP |
| **建立 Exposed → 另一張合法 SP** | 誰有手牌能吃到破綻？是自己後手還是由夥伴追擊？ | 不可自建自用、目標失效要重驗 |
| **Combo Setup → Finisher** | 是否為搭檔保留第二張卡的真實 AP／MP 成本？ | 兩角色，第二人真正持卡出牌，不能免費多打一張 |
| **有限 Overload → 未來 APDebt** | 這一回合強攻，下一回合可能只剩少量 AP，能承擔嗎？ | 只有卡片明示可借才成立；不無限借且可能壓縮 RP |
| **DOT / Debuff → 支援／淨化** | 該先治療、護盾還是移除一個合法狀態？ | 失能或耗竭不能被普通 Heal／淨化恢復戰鬥資格 |
| **護唱 Focus Ward → Casting Stability** | 保護延後高傷施法，還是換成立即施法降低風險？ | Focus Ward 只吸收干擾，不等於 Boss Break 或 HP Barrier |

**示範回合（只描述現有合格策略選擇，不宣告固定 Combo 配方）**：

1. 玩家看到 Boss 公開的下次大招 Intent，且手上有蓮的 Break 技能、朱音的火系傷害和紬的防護。
2. 蓮可以嘗試造成合格 Break；如果 Boss 的 CORE_OPEN 條件成立，還可能額外建立 Exposed，但沒有該姿態也可能建立已核准的攻擊 Combo 機會。
3. 朱音可以依目前牌費與角色狀態選擇 Chantless／Full Chant，若使用真正合格的 Combo Finisher，照常支付第二張卡成本；是否有元素弱點取決於這名 Boss 的真實配置。
4. 紬可用合法手牌護盾、治療或保護有效 CastingInstance；團隊也可少花 AP，在階段末換取 RP。
5. **如果某張未來的技能明示 Overload**，才可在 AP 不足時借差額並留下 APDebt；不能因為此輪策略理想而假設現有朱音卡皆可 Overload。
6. 所有支付、命中、狀態 tick、Break／Exposed、敵人行動及勝敗都仍由原 Domain 及事件順序決定。

## 7. 對新魔法學科的實戰定位——重用機制，不重新發明規則

| 學科候選 | 首選玩家角色／用途（只是設計研究） | 可先複用 | 真正需要新 ADR 才能做 |
|---|---|---|---|
| 火焰 | 朱音，高傷與明示 DoT | DAMAGE、現有 `SCORCH_TEST` | 泛用元素附加狀態系統 |
| 寒霜 | 防護或明示屬性減益 | BARRIER、受限 BUFF/DEBUFF | 凍結回合、偷改命中政策 |
| 雷電 | 爆發、指定詠唱干擾 | DAMAGE、CASTING_DISRUPTION | 每次雷擊強制麻痺 |
| 奧術 | 通用魔力、屏障、Focus Ward、術式解析 | U01/U02/U03、Casting | 任意 Spell Counter／重寫技能 |
| 生命／光輝 | 紬的回復、防護、光學演出 | HEAL、BARRIER、MP 支援 | 自動 Revive、消除 EXHAUSTED |
| 空間 | 合法範圍／防護邊界 | BARRIER、現行合法目標政策 | 自由格子移動、任意 Protect Redirect |
| 時間 | 狀態時效管理（非首發實裝） | 現存 Status 的期限規則可作設計基礎 | **任意修改 duration / tick**；需 ADR |
| 因果／契約 | 明示條件→結果，未來支援／Combo 題材 | 現存 Combo 只能作敘事參照 | **新觸發佇列／誓約代價**；需 ADR |
| 認知／感覺／夢境 | 合法情報、感知／心智狀態研究 | 現有公開 Intent，部分 Status primitive | 偷看隱藏 Intent、睡眠／致盲／精神控制；需 ADR |
| 命運／混沌 | 可預期風險管理／事先揭露變化 | 故事層／Boss 研究，既有 seed 做背景 | 改 RNG、重擲、分歧表；需 ADR |
| 虛無／存在／秩序 | 稀有學理／特定 Boss 結界 | 適合圖鑑／劇情；可基於已有效果設計 | 強行消除敵人、封技、永久篡改身份；需 ADR |

表格不代表所有學科都已有可用技能。**不為了 24 個名稱湊 24 張換皮護盾**。角色職能／Universal 裝備資格仍依現有 `CardDefinition`；角色初期每人 12 SP、補 4、上限 8，Last Spell 單獨且每人每場一次。

## 8. UI／可讀性契約（設計候選，不修改 HUD）

### 8.1 玩家初看一張卡，最多先抓五件事

1. **主要效果**：攻擊／防護／恢復／施法支援／干擾／情報／連攜準備（UI 分類候選，不是新 Domain kinds）。
2. **資源成本**：真實 AP/MP/RP；若本卡允許 Overload，預覽**這次借多少、下一玩家階段會先還多少**，並顯示拒絕原因；不要誤導為當前可任意施放。
3. **目標／命中**：友／敵、單體／全體、目標是否合法；只顯示依現行規格可以公開的敵人弱點。
4. **時機**：Instant／Chantless／Full Chant／Reaction／Next trigger，必要時顯示合法干擾風險。
5. **次要標籤**：現有 BUFF／DEBUFF、DOT、Break、Exposed、ComboOpportunity；圖鑑再提供「學科」與敘事。

### 8.2 HUD 必須將數值分開

| 元件 | 正確標示 | 不要畫成 |
|---|---|---|
| 共享 AP / APDebt | AP 主資源＋有債時才顯示債務警示 | HP 負值、免費 MP |
| 共享 RP | 玩家階段留 AP 後的敵方反應資源 | 每角獨立 RP |
| HP / HP Barrier | 紅／綠血量，外層護盾等獨立 UI | 一條能吸收任何干擾的萬能盾 |
| Casting Stability / Focus Ward | 有效 CastingInstance 的穩定度／護唱資源 | Boss Break Gauge |
| Boss Break | 明確下次合格行動受影響的槽 | 所有攻擊都必然造成的暈眩條 |
| Exposed | 真實一次性破綻、有效時點 | 給 Boss 普遍加傷的永久 Debuff |
| 狀態列表 | BUFF／DEBUFF／DOT／HOT 的真實來源、層數、期限、驅散性 | 猜測敵人資訊，或只根據 FX 生成 Debuff |
| Weakness icon | 已合法揭示的抵抗 profile | 由學科顏色直接推論倍率 |

文字需本地化 zh_TW／en；顏色不能成為唯一分類依據。不要在魔法學科設計任務中私自改 V3 戰鬥 HUD；這是後續獨立 UI 實作任務。

## 9. 正式工程現況與「已存在≠已完整可玩」

| 部分 | 目前證據 | 正確結論 |
|---|---|---|
| Buff／Debuff | `scripts/domain/m5/status/status_resolver.gd`、`tests/fixtures/m5_2_fixture.gd` | StatusInstance/STAT modifier 已有 Domain 與測試 fixture，不等於正式 Boss 可遇到所有狀態 |
| DoT | `lv40_content.gd` `SCORCH_TEST` | Lv40 候選固定傷害與期限，非全元素定律 |
| Overload／APDebt | `overload_debt.gd`、`cost_resolver.gd`、`m2_2_provisional_costs.json` | M2 成本機制有程式；MaxAPDebt=8 候選，不能宣稱當前 Starter 有超載卡 |
| Weakness／Resistance | `lv40_content.gd` 的 `m5_element_resistance` | 有示範 Boss 的 FIRE、ARCANE、NEUTRAL 候選配置 |
| Break／Exposed／Combo | 現行中文規則、`m5_domain_resolver.gd`、`lv40_content.gd` | 部分 Domain 具備，**完整真實 Boss 可玩驗收不足** |
| Casting Stability / Focus Ward | 現行雙詠唱規則與 M4 | 與 Break 不同的獨立系統 |
| 時間／因果／認知／命運等新機制 | 本提案世界觀表 | **未實作；需要 ADR／合法事件／可重播測試** |
| Last Spell / Exhausted | `終式與耗竭系統.md`、`LAST_SPELL_RETIREMENT_APPROVED_20261016.md` | 成功施放耗竭**真正退場**；不接受治療、Buff、復活或 Protect |

此列表是**代碼／文檔核對**，並非這次重新跑過 Godot CI。需以各次最新提交的真實測試和 Actions 證據判定 VERIFIED。

## 10. 新卡設計模板與准入 Gate

新增學科卡之前先寫一份 **Card Design Record**，逐項填：

| 必填欄位 | 意義與檢查 |
|---|---|
| `card_id / version / source` | 版本化內容，不覆蓋舊 CardInstanceID |
| `primary_discipline / optional secondary` | **敘事 metadata**（提案，未修改實際 schema） |
| `role / eligibility` | UNIVERSAL／ROLE_TAG／CHARACTER／VARIANT 的明確合法資格 |
| `main_effect / supporting_effect` | 一句話主動詞；次要效應有明確限制與成本 |
| `damage_kind / affinity` | 只在合法 HP Damage 時決定，逐敵人 profile 生效 |
| `cost / overload_eligible / borrow limits` | 無 Overload 便不可借款；確認 MP、APDebt、RP 互動 |
| `casting_mode / targeting / legality` | 瞬發／完整詠唱／反應、Concentrating 和目標存活政策 |
| `status / break / exposed / disruption` | 明示每項效果觸發時點、stack、限次與事件順序 |
| `combo_compatibility` | Setup／Finisher、真正第二張卡付費；複合學科不是自動 Combo |
| `counterplay / tell` | Boss Intent 是否公開、可否 Guard、Protect、Disrupt，避免無反制秒殺 |
| `i18n / UI` | 中文／英文主效果；不可烘焙硬編碼數值；長文字 Tooltip |
| `negative_tests / replay` | 非法目標、無 AP、超債務、失能、詠唱中、過期狀態、同 seed replay |

**強制准入條件**：新機制必須指出它創造的真實新決策；若與已存在低成本卡牌只差 FX 顏色，應保留為圖鑑而非新增可玩卡。平衡數值、卡池資格和新狀態均需要獨立核准，不能由此文自動授權。

## 11. 分期路線圖與決策狀態

| 階段 | 交付內容 | 是否需本次新規則 |
|---|---|---|
| **G0（本次）** | 一份統一魔法設計，整合 24 研究學科與 Buff／Debuff、Overload、Weakness、Break、Exposed、Casting、Combo | **僅文件整合** |
| **G1** | 既有 Lv40 示範卡視覺／行動描述梳理；用既有 Status、Break、弱點與 APDebt 示範「能做／不能做」 | 不改 Domain；有些需獨立 fixture |
| **G2** | 少量真正有不同戰術身份的內容候選（例如火、奧術、生命；時空留作 Lore） | 個別卡與平衡審核 |
| **G3** | 第一個受限的新高概念玩法（候選：條件型因果、有限時間延長、認知狀態，**只選一種**） | **新 ADR＋測試＋UX 驗證** |
| **G4** | 複合術式與多角色高階內容、更多 Boss 反制 | 逐配方與角色資格審查 |
| **G5** | 首發專精與魔法圖鑑，兩語系、Replay、種子策略與玩家可讀性驗收 | 正式 QA／Balance Acceptance |

### 本次整合「已確認」vs「仍待決」

**已確認並維持（不重新審批）**：
- 世界觀可深、遊戲操作需簡單的產品原則。
- 現行戰鬥中已核准的 AP／RP、Status 行為原則、逐敵人弱點／抗性、Break／Exposed、Casting／Last Spell、Combo 的所有已批准邊界。
- 以既有 Domain 與 UI 契約作為未來設計的唯一合法來源。

**仍待使用者審批（不得假設同意）**：
1. 24 學科是否最終全部保留為世界觀分類；是否有任何學科要合併。
2. 是否將七種玩家主用途標籤用於真正 HUD／卡片畫面。
3. 哪些現有 SP 未來正式附加學科 Lore 標籤。
4. 新法術數值、Overload 卡資格與 MaxAPDebt 平衡、Status 效果／命中與抗性、時間／因果／命運類新機制及角色解鎖。
5. 何時由設計分支向 `master` 合併；目前並未獲授權合併或更改現行 Combat Rules。

## 12. 研究參考與權威來源

### 現行專案文件（本文件整合時已對照）
- [戰鬥總覽（唯一現行閱讀入口）](../README.md)
- [回合與行動點數：Overload／APDebt](../回合與行動點數系統.md)
- [魔力與反應點數：MP／RP](../魔力與反應點數系統.md)
- [傷害與異常狀態：Buff／Debuff、DoT、Barrier](../傷害與異常狀態系統.md)
- [失衡與破綻：Weakness／Break／Exposed 的時序](../失衡與破綻系統.md)
- [詠唱與干擾](../詠唱與魔法干擾系統.md)
- [角色連攜](../角色連攜系統.md)
- [卡牌圖鑑（內容候選）](../卡牌圖鑑.md)
- [終式與耗竭規則](../終式與耗竭系統.md)
- [工程對照／待驗收](../engineering/待實作與待驗證功能.md)

### 遊戲設計借鏡（機制原則，不複製數值）
- [D&D 2024 Spell Rules](https://www.dndbeyond.com/sources/dnd/br-2024/spells/)：學派描述與個別效果分開。
- [Pathfinder 2e Remaster](https://2e.aonprd.com/Rules.aspx?ID=2221)：魔法傳統與具體技能的多層分類。
- [Magic: The Gathering Color Pie](https://magic.wizards.com/en/news/making-magic/value-pie-2003-08-18-0)：每種流派有強項、弱點與越界限制。
- [Magicka 2](https://www.paradoxinteractive.com/games/magicka-2/about)：複合元素題材的創意；**不**移植即時任意學科配方。
- [Into the Breach](https://subsetgames.com/itb.html)：公開威脅支援可理解的風險取捨。
- [Slay the Spire](https://www.megacrit.com/)：短卡牌文字與順序／卡組的高策略性。

---

**維護約定：** 之後請優先讀 **本 v0.4 整合提案**；v0.1–v0.3 和 24 學科矩陣保存作為設計歷史。任何真正改變 APDebt／Status／Break／Casting／Combo、加入新 SP 或畫面欄位的任務，必須從當前 `master` 的戰鬥權威重新核對、立獨立 ADR 並取得使用者核准；不得把這份提案當作已批准的可實作全部內容。
