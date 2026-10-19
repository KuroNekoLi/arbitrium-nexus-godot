# Arbitrium Nexus — 資源魔法、異常狀態與弱點：最終優化建議 v0.5

> 2026-10-19 ｜ **DESIGN PROPOSAL / NOT USER APPROVED / NOT IMPLEMENTED**
> **整合母版**：[魔法系統統一設計 v0.4](MAGIC_SYSTEM_INTEGRATED_DESIGN_V0_4.md)。本文件補充資源操縱、狀態、弱點的具體設計，**不取代已核准的戰鬥規則**。
> **現行 SoT**：[戰鬥總覽](../README.md) → [回合與行動點數](../回合與行動點數系統.md)、[傷害與異常狀態](../傷害與異常狀態系統.md)、[失衡與破綻](../失衡與破綻系統.md)、[詠唱與干擾](../詠唱與魔法干擾系統.md)、[角色連攜](../角色連攜系統.md)。以 master `8e16c8f4e7205d256b230953fd9dda07087a90a1` 現行規則核對。
> **本輪只改 proposal 文件，不改 Domain、CardDefinition、Boss、平衡、UI、測試、master。** 所有建議數字／新增技能和負面狀態屬平衡或機制候選，未獲核准前 Codex 不得當正式 Card Effect 寫入。

## 0. 主要推薦：深世界觀＋四類資源魔法＋小規模狀態＋三層弱點

玩家從卡牌上只需看懂「此刻多做什麼、未來付出什麼、對敵造成何種影響」。
- **資源**：`AP 取得`（現在）、`AP 儲備`（下一玩家階段）、`Overload`（借未來的 AP）、`SP 減費`（使某張卡更省 AP/MP）。**不同技能語義，不合併成「最大 AP」**。
- **敵方干擾**：目前 Boss 沒有與玩家相同的 AP 池。想「降低敵方下一回合 AP」時，優先用 Boss 的**已公布下一個 Intent、Break fallback、Casting Disruption 或可反制的攻擊削弱**表達，而不是添加不存在的 enemy.ap。
- **異常狀態**：先聚焦**灼燒、寒霜、感電、攻擊弱化、防禦破損、再生**六種易讀玩法候選；強力的**冰凍（剝奪行動）**和**麻痺（剝奪行動）**暫不納入 Boss 初版。
- **弱點**：分開 **元素 HP 弱點／抗性**、**Break 本體失衡**、**Exposed 可利用破綻**；別自動把「命中弱點」轉成「Boss 眩暈」。

## 1. 遊戲參考：可採的規則，以及不能直接複製的部分

| 作品／來源 | 官方描述的戰術概念 | Arbitrium Nexus 應借鏡 | 不採用 |
|---|---|---|---|
| [Bravely Default / Nintendo](https://csassets.nintendo.com/noaext/image/private/t_KA_PDF/manual-3DS-bravely-second-end-layer-en?_a=DATAg1AAZAA0)、[Square Enix 戰鬥提示](https://www.square-enix-games.com/en_US/news/bravely-default-tips-tricks) | Brave 可預支未來行動資源，負 BP 導致後續行動受限；Default 儲備 BP | Overload 必須將「現在得利、後續成本」在 UI 透明呈現 | 不增加與 AP 同義的第二個行動點數或每角色 BP |
| [Octopath Traveler 官方](https://www.square-enix-games.com/en_GB/news/octopath-traveler-i-and-ii-now-available-current-console-platforms) | 發掘敵人弱點、削減 Shield、Break，以及儲蓄 Boost 時機 | 學習「弱點揭露→何時施壓→獲得好時機」的清晰策略 | 不直接複製全體敵人以弱點命中必然削 Break；現有 Break 由技能明示 |
| [Honkai: Star Rail 官方 HoYoWiki](https://wiki.hoyolab.com/pc/hsr/entry/1618?lang=en-us) | 弱點與 Toughness 分開，特定屬性弱點擊破會改變敵方動作；Frozen／Action Delay 有專用效果 | 區分元素抗性、Break Gauge 與控制效果；若要 Freeze 應另有抗性／限制 | 不複製每系自動附加 Status 或創建第二條 Toughness |
| [Pokémon 官方狀態指南](https://www.pokemon.com/us/strategy/pokemon-rpgs-101/) | Burn/Poison 持續傷害、Paralysis／Sleep 影響行動 | 異常名稱必須對玩家造成可預期的不同機制 | 不照搬「每次麻痺機率跳過回合」到現有公開 Boss Intent |
| [Slay the Spire / Mega Crit](https://www.megacrit.com/) | 卡牌短文本、卡間資源與回合組合 | 每卡主要目的清楚、費用／效果有直接取捨 | 不複製能量池／抽牌／回合次序 |

**設計總結**：借用其它遊戲的可讀性與明確取捨，**不**換掉既有「三人共享 AP／個別 MP／敵方 RP 反應／雙施法／Boss 公開 Intent」架構。

## 2. Overload 究竟是哪類魔法？

**兩者都成立，但語義需分層**：
- **戰鬥機制**：Overload 是卡上的**成本權限**——不足 AP 時借差額建立 APDebt；絕不是一種元素，或一種隱性 Status。
- **世界觀表達**：時間術可以稱「預支未來時刻」，因果／契約術可以稱「向未來索取代價」，奧術可以稱「魔力迴路超載」。**學科只解釋為何能做，不自動獲得超載資格**。
- 應由技能的 `overload_eligible`、`max_borrow_per_card` 等合法配置決定；`max_ap_debt=8` 是現有 `BALANCE_PROVISIONAL` fixture，非已核准的固定上限。
- 未來共享 AP 首先還債，剩餘可用；現行 CurrentAP 不會是負數。已合法支付的 MP、失效的 Full Chant、Last Spell 等與債務仍按各自現行規格判斷。

## 3. 四類與 AP／MP 相關的魔法，一定要明確分開

| 類型 | 候選魔法名稱／學科歸屬 | 玩家看到的主效果 | 現有能力／缺口 |
|---|---|---|---|
| **即時 AP 取得** | 「魔力增幅」奧術／生命 | **本玩家階段立即獲得 1 AP** | M2 `AP_REFUND_EFFECT` 的內部測試邏輯已支持當前 AP 正向增加；新正式卡仍需合法 SP 接線與平衡 |
| **下一階段 AP 加成** | 「刻之儲備」時間／奧術 | **下個玩家階段獲得 +2 AP** | M2 `SCHEDULE_NEXT_PHASE_AP_BONUS` 已有內部效果；下階段計算時與既有 APDebt 一同處理 |
| **Overload 透支** | 「借時超載」時間／因果／契約 | **本張卡若 AP 不足，可借至多 2 AP；未來先償還** | M2 `borrow_quote`／APDebt 已有核心；須在**特定卡**啟用，數字僅例示 |
| **AP 技能減費** | 「術式精簡」奧術／秩序／認知 | **下一張符合條件的 SP 減少 1 AP** | M2 `SET_COST`／`DISCOUNT` 用於 AP quote；正式卡的修正範圍與到期仍需定義 |
| **MP 技能減費** | 「魔力效率化」奧術／認知 | **下一張符合條件的 SP 減少 2 MP** | **不是已實裝的通用能力**：目前 M2 quote 使用固定 `mp_cost` 並先行檢查 MP；需新設獨立 MP modifier、事件與負例 |
| **戰鬥長期 Base AP 強化** | 「永久提速」時間／秩序 | **每個未來玩家階段都多獲得 AP** | 高風險永久經濟改動；**不建議第一版引入**。需持續回合政策／上限／償債時序新 ADR |

### 3.1 「增加最大 AP」不等於目前需求

目前 `BaseAP=6` 是共享基準，而不是不可超過的硬上限；現有架構已有 `current_ap`、`next_player_ap_bonus`、`ap_debt`。所以：
- **現在直接多 2AP** 是「即時取得 AP」，不需要先增加 MaxAP。
- **下階段 +2AP** 是「下期加成」，不需要新增永久的 MaxAP 屬性。
- **所有後續階段 BaseAP 由 6 變 7** 才是持續修改經濟基線，會大幅影響 Combo／反應與連續回合，初版不建議。
- 若未來想設「可儲存 AP 上限」或「本期 AP 硬上限」，那是**新增另一套資源邊界**，需要 ADR，不能從目前 BaseAP 誤推。

例如下回合 BaseAP 6、Bonus 2、已有債務 3，正常先組成 8AP 額度，再還債 3，**可用 5AP**（只是數學示例；須符合真實流程和配置）。

### 3.2 降費必須避免免費連鎖

候選準則（**未核准**）：
1. 只影響**下一張符合明示條件**的實際 SP，持續最多一個有效窗口；不能永久讓所有隊友卡 -1AP。
2. 只有**真實被支付的合法 SP**才消耗 1 次 modifier；非法命令不扣減費額度。
3. 減至 0 或最低 AP/MP 的政策必須由逐卡 `min_ap_cost`／候選 `min_mp_cost` 決定，不私加現行全域「最低 1AP」規則。沒有 MP modifier 規格前不先實裝 `min_mp_cost`。
4. `SET_COST` 與 `DISCOUNT` 的順序照既有 M2 AP quote；MP 降費需要獨立 quote、可追蹤事件與 Replay。
5. 禁止 0AP／0MP 無限互相生產折扣或 AP，尤其注意資源支援卡對自己再施放的循環。需要針對可用卡池進行**循環收益檢查**。
6. 折扣生效順序在 Overload 借款報價之前，避免 UI 顯示的可借數量和真正支付的差額不符。不得事後退款替代合法 quote。

### 3.3 「削減敵方下回合 AP」目前沒有合法目標欄位

**現行 Boss 使用 EnemyIntent／敵方行動，不使用跟三人一樣的共享 AP。** 所以：
- 若期待「敵方下次攻擊變弱」：**WEAKEN** 或降低 PAtk/MAtk 的既有 Debuff 類型可設計，但須確認技能、狀態時效、命中；對 GUARANTEED 技能的 accuracy 下降不會有效。
- 若期待「敵方下一招被壓制」：優先使用已定義的 **Break → 下一次符合條件且未開始 Boss Action fallback**。
- 若期待「敵人正在蓄力的術式失敗」：使用合格 **Casting Disruption → Casting Stability**；不等於 Break。
- 若期待「敵人下回合少行動一個」：當前沒有通用 Enemy AP／行動預算系統；屬高風險**全新 EnemyAction Budget ADR**，**不推薦第一版做**。
- 若未來要引入「時間延遲」：只能作用於已公開合法意圖，且提前展示可被延後/降級的窗口；需要明確不能改寫已開始攻擊及不會形成無限迴圈。

## 4. 異常狀態的最小可玩版本：六個直觀候選

先把「看起來像異常的效果」分成 **DoT/HoT、屬性 Debuff、增益、一次性戰術事件、強控制**，不要把全部做成一個 `Status` 池。

現有 `scripts/domain/m5/status/status_resolver.gd` 支持 `DOT/HOT/BUFF/DEBUFF/BARRIER`，`STACK/REPLACE/REFRESH/IGNORE`，可配置 `tick_trigger`、`duration_ticks`、`priority`、`dispel_tags`；可支援的屬性增減涵蓋 `patk/pdef/matk/mdef/accuracy/evasion`。**這是 Domain 基礎，而非下列六個 Status 已正式可玩。**

| 候選狀態／提案 ID | 類型與玩家一句話 | 建議的最簡效果 | 為何和別的狀態不同 | 可用性 |
|---|---|---|---|---|
| **灼燒 BURN** | DoT：「每次指定敵方階段結束受傷。」 | 對應現有 `SCORCH_TEST` 的版本化 DoT；候選採 **REFRESH 而不無限 STACK** | 穩定持續壓血 | Lv40 已有 SCORCH_TEST 候選，BURN 僅是未來正式名候選 |
| **寒霜 CHILL** | Debuff：「迴避降低。」 | 以 `evasion` 負修正模擬遲緩，期限 1～2 個適用 trigger | 令後續命中更可靠；**不是冰凍不能行動** | 現有 stat modifier 可作基礎，還需新增卡／狀態定義 |
| **感電 SHOCK** | Debuff：「命中降低。」 | 以 `accuracy` 負修正表達動作不穩；**只影響需命中判定的攻擊** | 降低下一波攻擊風險；**不是必然麻痺** | 現有 stat modifier 可作基礎，還需新增卡／狀態定義 |
| **衰弱 WEAKEN** | Debuff：「攻擊能力降低。」 | 以明示的 `patk` 或 `matk` 擇一負修正；若要同時降低兩者，需兩段／新 ADR | 防守向替代選擇 | 現有 stat modifier 可作基礎，還需新增卡／狀態定義 |
| **破甲 FRAIL** | Debuff：「防禦能力降低。」 | 以明示的 `pdef` 或 `mdef` 擇一負修正 | 進攻向支援，且**與元素傷害抗性不同** | 現有 stat modifier 可作基礎，還需新增卡／狀態定義 |
| **再生 REGEN** | HoT：「按明示時點恢復 HP。」 | 個別 HoT，受滿 HP、失能與耗竭限制 | 持續治療而非立即 Heal | 現有 HOT 原型，還需正式卡／平衡 |

**Buff 的最低限度**：沿用個別的 PAtk/MAtk/防禦能力強化、現有 U02 的 HP Barrier、U03 的 Focus Ward、A03「凝火」對下一張技能的指定強化。不把「下一張技能減費」偽裝為一般 stat `BUFF`；它是 CostModifier，須在支付前結算。

### 4.1 為何不直接加入「冰凍」與「麻痺」？

使用者想要的 Frozen／Paralyzed 是合理的世界觀能力，**但玩家一般會理解成「不能動」**；這正好和現有 Break 造成下一個 Boss 行動弱化的核心價值高度重疊，還會破壞公開 Intent 的應對機制。

建議：
- **初版只做寒霜（減 Evasion）與感電（減 Accuracy）**，並在技能名稱／狀態徽章清楚顯示，**不得錯寫「冰凍」「麻痺」**。
- **冰凍 FROZEN（下一期或高階）**：候選可令某些普通敵人失去**一次**合格行動；Boss 預設不直接被剝奪已公開行動，可以有明示的抗性、轉為 CHILL 或與 Break fallback 對應。這需要新的控制合法性與「免疫／替代效果」ADR，不能先定為所有 Boss 自動免疫而不展示。
- **麻痺 PARALYZED（下一期或高階）**：如設計為一定機率跳過行動，會新增 RNG、Replay 邊界、玩家無法合理預測的結果；**不建議引入**。可研究「下一次特定命中型行動削弱／可干擾條件明示」替代，但要另有 ADR，不能冒充 SHOCK。
- **中毒 POISON（第二階段）**：可採「疊加強度、到期固定」與採 REFRESH 的 BURN 區分。未決前不用第二個換色 DoT 增加閱讀負擔。
- **恐懼／睡眠／沉默／魅惑／石化／混亂**：屬高風險行動限制或目標控制，暫保留於學科與未來敵人研究，不做首發通用狀態。

### 4.2 狀態抗性不等於元素弱點

即使 Boss 弱火，也**不代表它對灼燒必定易中**。要分：
- `damage_affinity_multiplier`：造成合格 HP Damage 的倍率；現有 Lv40 Boss 約 FIRE ×1.15、ARCANE ×0.90、NEUTRAL ×1.00（**候選**）。
- `status_susceptibility`：是否可施加 BURN/CHILL/SHOCK/FROZEN 等異常，或有**明示**的免疫與替代；這是新內容資料設計建議，不表示現有 M5 已有該字段。
- `break_gauge`：該敵人身體失衡進度；不是另一種 BURN 抗性。
- `casting_stability`：有效單次法術的施法穩定；與本體 Break 分開。

初版**優先用確定型效果與明示抵抗**，避免每張法術再加一個隱藏成功率。若要機率施加，使用版本化確定性 RNG 並提供可讀的命中／抵抗回饋；不能由 FX 決定。

### 4.3 狀態層數／時間的建議邊界

- 除 `POISON` 未來可能疊加外，首發 Status **優先一層／重施刷新或不刷新**，不開放無限層數；具體 `stack_policy`／`duration_ticks` 需個別設計，不能硬改現有 `SCORCH_TEST`。
- 所有持續時間都以**合法 Domain trigger** 計數，不以 UI 秒數或任意「每回合」代替。
- 狀態事件優先級與相同 trigger 的穩定 ID 排序，保持 Replay。
- Status dispel 僅解除有正確 `dispel_tags` 的實例；不允許普通淨化移除 `INCAPACITATED`／`EXHAUSTED`、Break 或已消耗的 Exposed。
- Boss 若具控制抗性，卡面／預覽至少提示有效性；避免使用者付完 MP 才知道 Boss 完全免疫、又沒有替代效果。

## 5. 弱點與 Break 最佳化：保留三個相互聯繫但不自動綁定的系統

**現行規則不可變的骨架**：
1. **Weakness／Resistance（HP 傷害）**：敵人逐個元素 profile；一般攻擊按 Damage Kind、防禦、抗性流程計傷。沒有全域「火剋冰」表；元素全表尚未核准。
2. **Break（行動壓制）**：技能**必須明示 Break Damage** 才扣 Boss Break Gauge；觸發時影響下一次符合條件、尚未開始的 Boss 行動，不能取消已開始行動。多 hit 應完成技能後才正式判定。
3. **Exposed（一次性戰術窗口）**：只在該 Boss 的合法姿態／事件／卡片符合時建立。**同卡不可建立又自行利用**，與 ComboOpportunity 不同。已核准的 R01/R07 連攜不需 CORE_OPEN，但 Exposed 仍看 Boss 姿態。
4. **Casting Disruption（施法干擾）**：作用於有效 CastingInstance 的 Casting Stability；`Focus Ward` 先吸收，和 Break 不是一條。

### 5.1 統一推薦的戰鬥回饋（玩家清楚看出「弱點能做什麼」）

| 玩家看到的事件 | HP 傷害倍率 | Break | Exposed | 螢幕回饋 |
|---|---|---|---|---|
| 命中 Boss 火弱點的 FIRE 魔法 | 使用這名 Boss 的 FIRE 倍率 | **只有 SP 明示 break_damage 才扣** | **不自動** | 火焰弱點標記＋最終傷害 |
| 蓮 R01 命中 Boss | 正常物理傷害 | 按 R01 合法配置削 Break | CORE_OPEN 等條件合格時才建立 | Break 條變動／Exposed 標記 |
| 朱音合法打中有效 Exposed | 技能本來傷害，並依合法利用規則加成 | 本 SP 有合法 Break 才扣 | 利用後依規則消耗 | Exposed consumed |
| A05 對有效 CastingInstance 施放 | **不是 HP Damage** | **不是 Break** | **不是 Exposed** | Focus Ward／Casting Stability 變動 |

### 5.2 是否讓「打到元素弱點」自動多削 Break？

**v0.5 推薦：首發不要自動增加。**

理由：
- 目前 Break 是卡與 Boss 姿態的戰術價值（蓮具有區別性），若全部元素攻擊弱點都自動追加 Break，會稀釋蓮與攻擊 Combo 的定位。
- 元素弱點已有 **HP 傷害收益**，若再白拿 Break、Exposed 或 Status，玩家會只用弱點元素，原來的 AP/RP、Full Chant 和支援變得沒有意義。
- Boss Break 原本是下一行動降級／fallback，而不是 Octopath 的普遍暈眩；直接複製弱點擊破會覆寫現行規則。

**將來可研究的可選擴充**（需要 ADR、內容權限，不是預設）：
- 某張 SP 明示 `ON_WEAKNESS_HIT: +N_BREAK` 的特性；只在實際 Weakness 觸發且技能合法時增加 Break。
- 某 Boss 特定 `CORE_OPEN` 或屬性姿態允許弱點攻擊製造一次性 Exposed。
- 某個 Variant 對特定元素有「弱點協同」專長，但按卡配置，不能偷偷加入全域規則。
- 只在新 Boss 需要時設置額外的弱點進度機制；優先避免第二條 Toughness Gauge。

### 5.3 弱點情報如何讓玩家學會，而不是猜規則

- **已公開／合法 Analyze 所揭示的弱點**：Boss Panel 可顯示「火弱、奧術抗」與實際數值（只有合法公開時才能顯示）。
- **尚未公開的 Profile**：UI 顯示「未知」，不根據卡牌顏色猜敵方弱點；如設計為玩家首次命中後推知某元素，需新 `Knowledge/Reveal` ADR 與事件。
- **傷害後回饋**：元素弱點命中時明示「弱點！」，並可查看傷害計算說明；若當次只有 HP Barrier 吸收，應分清「符合弱點倍率」與「實際扣血」。
- **行動前預覽**：僅顯示 Domain／Adapter 可依法提供的預測與合法目標，不透露 Boss 尚未公布的 Intent。

### 5.4 Boss 控制強度／失效防止

- Boss 控制不應由 **Frozen／Paralyzed 無限輪流跳過**；如果該效果沒有透明反制與限次，應移到 P2 高階研究。
- 同一 Boss 下一次合格行動能否受到 Break 和其他行動壓制疊加，須有優先權政策；**不能重複削掉同一個 Intent 或事後撤銷已執行的攻擊**。
- Boss **完全免疫／轉化控制**必須有視覺提示，避免技能暗中失效。
- 狀態削 PAtk/MAtk、命中率等**數值弱化**比強迫跳回合更適合早期版本。

## 6. 小型技能候選：一眼懂，只有 1 個主要目的（全部非現有卡）

| 例示卡 | 所屬研究學科（候選） | 卡上主要效果文字（需實際成本／目標） | 引擎狀態 |
|---|---|---|---|
| 「借時超載」 | 時間／因果 | 「這張技能 AP 不足時，可借用至多 2 AP，下階段先還。」 | M2 有 APDebt 基礎；新卡資格／數值待設 |
| 「魔力增幅」 | 奧術／生命 | 「立即獲得 1 AP。」 | M2 內部 AP 資源效果存在；新的正式 SP 接線待設 |
| 「術式精簡」 | 奧術／認知 | 「你下一張符合條件的 SP 減少 1 AP。」 | M2 AP discount 基礎；到期與實際支付需要檢查 |
| 「以太節流」 | 奧術 | 「你下一張符合條件的 SP 減少 2 MP。」 | **NEW ADR REQUIRED**：MP modifier／最小消耗／優先權 |
| 「霜晶束縛」 | 寒霜 | 「敵人迴避降低，直到指定時點。」 | DEBUFF stat 原型可用；需正式卡與配置 |
| 「電荷紊亂」 | 雷電 | 「敵人命中降低，直到指定時點。」 | DEBUFF stat 原型可用；對 GUARANTEED 攻擊無效 |
| 「破術雷紋」 | 雷電＋奧術 | 「干擾一個有效的敵方詠唱。」 | 已有 Casting Disruption 基礎；須逐卡合法權限 |
| 「斷勢宣言」 | 秩序／時間 | 「削弱 Boss 下一次符合條件的行動。」 | 優先以明示 Break／Weaken 設計，不新增敵方 AP 池 |

一律不可把示例當作已核准的實際 CardDefinition、卡牌費用、角色可裝備資格或戰鬥狀態。

## 7. 必要的版本化 ADR 與工程測試 Gate

| 編號 | 事項 | 建議優先級 | 驗收要點 |
|---|---|---|---|
| `ADR-MAG-RESOURCE-01` | 新正式 AP 增益／下階段 AP Bonus 的來源與限次 | P1 | 合法支付、Domain Event、APDebt 先還、AP→RP、無循環產 AP |
| `ADR-MAG-COST-02` | 下一張 SP AP 減費的目標、到期與消耗 | P1 | AP Quote／SET_COST／DISCOUNT、非法命令不消耗、指定最小成本 |
| `ADR-MAG-MP-03` | MP 減費 CostModifier | P2 | 目前無 MP discount；MP Quote、最小費、付款與 Replay、Casting 退款交互 |
| `ADR-MAG-STATUS-04` | BURN／CHILL／SHOCK／WEAKEN／FRAIL／REGEN 正式內容 | P1 | 每狀態 tick、stack、dispel、施加合法性、元素抗性分離、Boss 確定性 |
| `ADR-MAG-CC-05` | FROZEN／PARALYZED 控制 | P3 | Boss 免疫／降級提示、不可永久跳 Intent、強控制優先權、RNG／Replay |
| `ADR-MAG-WEAK-06` | 弱點 Reveal UI、特定 SP 弱點協同 | P2 | 不自動附送 Break、Exposed，獨立 status_susceptibility，不洩漏 Boss 資料 |
| `ADR-MAG-BOSS-07` | 敵方「減少行動」而不是傷害削弱 | P3/DEFER | 是否真的需要 EnemyActionBudget、Boss Intent 不被強制改寫、無無限控制循環 |

建議測試案例：
- AP=1、AP Cost=3、Borrow=2 合格；同樣不合格卡不得借款；下階段 Bonus 與 Debt 先後順序固定。
- 累積折扣、Overload、AP Bonus、RP 轉換與 MP 不足時，**非法命令保持 State/Events/RNG 原樣**。
- DoT 實際受 HP Barrier 和現有 fixture 政策影響；不能套 Focus Ward；不能對 EXHAUSTED 退場目標繼續施加／治療。
- CHILL／SHOCK 用合法命中修正驗證；Boss GUARANTEED 攻擊若不判命中，SHOCK 的 Accuracy Debuff 不應虛構效果。
- 不同敵人 FIRE 抵抗各自獨立；傷害抗性與狀態抗性不互相推導。
- Break 在多 Hit 完成後按現有時點判定；Exposed 自建自用拒絕；Casting Disruption 不影響 Boss Break；已開始 Intent 不取消。
- 選中卡牌、Boss Intent、狀態圖示、弱點情報有**zh_TW / en** 真實投影；與 100-seed Replay／過往版本內容測試隔離。
- 新機制每次只加一種，不因文檔標示 `P1` 就宣稱工程完成。

## 8. 決策：本輪最推薦立即採用的方向

**優先定下設計方向（仍需使用者確認）：**
1. **學科不是玩法機制**：時間學科很適合 Overload 的敘事，但 AP/MP 取得、費用降低、APDebt 是 4 種各自明示的成本能力。
2. **不新增 MaxAP 作為常駐數值**，先使用已有 CurrentAP、NextPlayerAPBonus、APDebt；若要持續 BaseAP 加成另立較高風險 ADR。
3. **不為 Boss 新增 Player-style AP**；想壓制下個敵方行動先用 Break／Casting Disruption／弱化。
4. **六個初版狀態候選**：BURN、CHILL、SHOCK、WEAKEN、FRAIL、REGEN；把「冰凍、麻痺＝不能動」與 Poison／精神控制等強新機制排到後續。
5. **弱點只先強化 HP 傷害**；Break 與 Exposed 保持獨立。未來再由個別卡明示「攻擊弱點額外 Break」才考慮互動。
6. **以 Card Design Record 與真實 Lv40 戰鬥做驗證**，而非一次增加 24 套 Domain、9 種自動異常或泛用負面狀態清除。

### 提案與現行機制邊界提醒

現有 Lv40 Boss FIRE ×1.15 / ARCANE ×0.90 / NEUTRAL ×1.00、Break max 22、SCORCH_TEST 每次45 HP、MaxAPDebt 8 等是**候選 fixture 數值**；本文件不改變也不批准其為全遊戲固定值。  
現行已核准 **Last Spell 成功後 EXHAUSTED 真正退場**；它不是可驅散 Debuff，也不能靠時間／存在／靈魂魔法免費恢復場上資格。  
既有 Team AP/RP、Dual Casting、Break/Exposed、Combo 以及 Boss Intent 規則不受本提案更動。

> **設計文件整合約定**：本專題與 v0.4 共用為下一階段規劃輸入，後續真實實作需要明確核准相應 ADR，不能直接更新 `master` 或改變現有戰鬥回歸。
