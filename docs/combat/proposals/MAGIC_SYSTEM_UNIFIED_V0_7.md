# Arbitrium Nexus — 魔法系統統一設計 v0.7（全面 Review 後版本）

> **Break／Exposed／Casting Disruption 的最新設計已升級為 [v0.8 方案 C](BREAK_EXPOSED_CASTING_UNIFIED_RULES_V0_8.md)**：使用者已選擇「普通招式取消、重大大招降級、同時建立一次 Exposed」；本 v0.7 所述舊 Break／Exposed 關係保留為歷史設計背景，不能再作最新方向。v0.8 尚未實裝，現行戰鬥仍以 `master` 的正式規則為準。


> **版本：v0.7｜日期：2026-10-19**  
> **狀態：DESIGN DIRECTION USER_APPROVED；CONTENTS/BALANCE PROVISIONAL；NEW MECHANICS NOT IMPLEMENTED**  
> **最新已確認方向：** 24 學科是豐富世界觀，不是 24 套戰鬥機制；Overload／Buff／Break 等舊規則保留；可使用明示機率異常，Boss 有逐敵／逐狀態的免疫與控制保護；高成本 SP 能讓未來 1～3 個玩家階段獲得暫時 AP 加成；**現在沿用公開 EnemyIntent，未來有需求才擴充混合式 EnemyActionBudget，不採玩家對稱敵方手牌/AP/MP 架構**。  
> **尚未核准：** 任何新 Status 定義、30% 麻痺、5AP+5MP、+2AP/3期、免疫比例、控制保護窗期限、敵方行動預算值、新卡、CardDefinition schema、UI 或 Domain 變更。以上所有數值皆為候選示例。
> **權威優先序：** [戰鬥總覽](../README.md) 和已核准最新決策 → [AP／Overload](../回合與行動點數系統.md)、[傷害與狀態](../傷害與異常狀態系統.md)、[失衡與破綻](../失衡與破綻系統.md)、[雙詠唱](../詠唱與魔法干擾系統.md)、[連攜](../角色連攜系統.md)、[終式](../終式與耗竭系統.md) → 工程規格與程式。**本文件是最新魔法設計入口，並非改寫 Combat Rules 的授權。**
> **實碼基準：** master `8e16c8f4e7205d256b230953fd9dda07087a90a1`；此版本僅文件修改，未執行 Godot 或 CI。

## 0. Review 結論（2026-10-19）

**架構審查通過，可作下一階段設計共同依據。** 但不能將「構想互相相容」誤稱「新玩法完成測試」。新版補正六個既有提案的主要歧義：

| 舊版問題 | Review 修正 |
|---|---|
| 24 學科像 24 種獨立抗性與引擎 | 分清 Lore、Damage Kind、Affinity、Effect、Cost/Casting、UI，沒有學科自帶額外效果 |
| 魔法 Buff／Debuff 都看似已可玩 | Status instance 和有效能力修正確實有程式；概率麻痺、敵方免疫、控制跳行動目前**不存在** |
| 「暫時增加最大 AP」像引入新的 MaxAP | 採明確的「未來 N 個玩家階段各 +XAP」，**不新增 MaxAP 硬上限、不永久改 BaseAP** |
| 一次性 next-player bonus 被說成支援 N 期 | M2 有內部一次性 bonus；持續 N 期須新的 `TimedPartyAPBonus` 與結算時序 ADR |
| EnemyScheduler 可排多個 Intent 被視為 Boss 有 AP/SP | 現行 BossAI 選**單一公開 Intent**，Scheduler 可排序多個；**Budget、多行動 AI、敵方消費都未實作** |
| 麻痺 vs Break 重複且可能永遠控制 Boss | 單主行動 Boss 的重要招式預設不直接被連續跳過；Boss 逐狀態抗性、硬控共同保護窗和公開替代效果 |

## 1. 五軸魔法模型：魔法學科不是戰鬥公式

| 分類 | 責任 | 例子／嚴格限制 |
|---|---|---|
| **Discipline 研究學科** | 世界觀、故事、圖鑑、術式主題 | 時間、雷電、認知、奧術；不自動給技能加傷害／Debuff |
| **Damage Kind** | 物理／魔法 HP 傷害管線 | `PHYSICAL`／`MAGICAL`；不是元素 |
| **Affinity／Resistance** | 每名敵人自己的元素弱點／抗性 | 目前 Lv40 有 `FIRE`／`ARCANE`／`NEUTRAL` 候選；沒有全域相剋表 |
| **Effect／Status** | 讓 Domain 真的結算效果 | DAMAGE、HEAL、DOT、HOT、BUFF、DEBUFF、HP_BARRIER、FOCUS_WARD、BREAK、EXPOSED、CASTING_DISRUPTION、COMBO，各走合法規則 |
| **Access／Cost／Casting／UX** | 誰能用、花多少、何時生效與玩家如何理解 | UNIVERSAL／ROLE_TAG／CHARACTER／VARIANT；AP／MP／RP、Overload；INSTANT／DUAL／FULL；卡面一個主要目的 |

`ARCANUM` = 提案的「純魔力與符文工程」研究學科；`ARCANE` = 現有傷害共鳴；`ROLE_TAG:ARCANE` = 職能／配牌資格；三者不可用同一 enum。`NEUTRAL` 指中性 HP 傷害；對 HEAL／BARRIER 等非傷害效果的 `NONE` 是「無此欄」，不可混淆。

**複合學科（例如雷＋奧術）不會自動兩種共鳴同時乘算，也不會免費觸發雙人 Combo。**

### 1.1 24 學科／七群：保留研究廣度，首發不求全部可玩

| 群組 | 學科 |
|---|---|
| 自然物質 6 | 炎熱 PYROMANCY／水流 HYDROMANCY／寒霜 CRYOMANCY／風氣 AEROMANCY／地脈 GEOMANCY／雷電 FULGURMANCY |
| 光影 2 | 光輝 LUMINOMANCY／幽影 UMBROMANCY |
| 生命靈魂 2 | 生命 VITAMANCY／靈魂 SOULCRAFT |
| 時空法則 3 | 時間 CHRONOMANCY／空間 SPATIOMANCY／因果律 CAUSALITY |
| 心智感知 4 | 認知 COGNITION／感覺 SENSATION／情緒 EMOTION／夢境 ONEIROMANCY |
| 構造規約 3 | 奧術 ARCANUM／契約 CONTRACT／秩序 NOMOMANCY |
| 形上可能性 4 | 命運 FATEMANCY／虛無 NIHILOMANCY／存在 ONTOMANCY／混沌 CHAOMANCY |

**24 個學科名稱本身仍為內容候選**。要讓一種研究領域變成可玩學科，必須有具辨識度的卡牌選擇；不能為了湊數給時間、秩序、夢境、存在四系各發一張完全同效果的護盾。時間＝持續／時序；因果＝條件到結果；命運＝可能性傾向；混沌＝合法變化分支；彼此不同，也都不能無授權回溯已結算事件。

## 2. 資源魔法：Overload、AP 加成與 SP 減費

| 功能 | 玩家可讀敘述 | 現行實作／限制 |
|---|---|---|
| Overload／APDebt | 「本張卡 AP 不足時可借差額，下階段先還。」 | `scripts/domain/m2/economy/overload_debt.gd` 已有 quote + 債務；限標註 `overload_eligible` 的卡 |
| 當期 AP 取得 | 「本階段增加 X AP。」 | M2 `AP_REFUND_EFFECT` 為內部資源效果基礎，正式 SP 仍需接線 |
| 下期 AP 加成 | 「下個玩家階段增加 X AP。」 | M2 `SCHEDULE_NEXT_PHASE_AP_BONUS` 存在單期候選，不能假設多期 |
| **未來 N 期 AP 加成** | 「接下來 N 個玩家階段，每階段增加 X AP。」 | **新效果／未實作**，需要專用團隊資源增益生命週期 |
| AP SP 減費 | 「下一張符合條件的 SP 消耗減少 X AP。」 | M2 `SET_COST / DISCOUNT` 是 AP quote 基礎；需限制適用對象與到期 |
| MP SP 減費 | 「下一張合格 SP 少消耗 X MP。」 | **未有通用 MP 折扣**，需獨立 quote、最小費與重播事件 |
| 降敵方 AP | 「限制下一次敵方行動。」 | Boss 目前**沒有玩家式 AP**，可先使用 Break／能力 Debuff／施法干擾；敵 Budget 只有未來方案 |

Overload 是**卡牌合法借款的權限**，可以用時間預支、因果交換、契約貸款、奧術迴路負荷當作敘事；不因卡片學科為時間就自動 `overload_eligible`。現有共享基準 `6 AP`、個人 MP 不每期回滿、階段末剩 AP 轉 RP（常態 cap6）；`CurrentAP` 可高於 6，沒有獨立 MaxAP 硬上限。

### 2.1 限時 AP：使用者已接受的正式設計方向

以`時序增幅`作為候選：付出 `5 AP + 5 MP`，未來 `N=1/2/3` 個玩家階段分別享受 `+X AP`，且只在未來階段有效、不是永久 BaseAP。

| 示意 | 花費 AP | 未來持續 | 每階段 +AP | 純名目 AP 收支（不考慮 MP／先後時機） |
|---|---:|---:|---:|---:|
| 一期版 | 5 | 下一階段 | +2 | -3 |
| 兩期版 | 5 | 下兩階段 | +3 | +1 |
| 三期版 | 5 | 下三階段 | +2 | +1 |

上列數字都是**例子，不是核准成本**。限時提高下一階段 AP 可能讓玩家在本期只剩少量可轉 RP 的 AP；後續如果有 `APDebt`，須先依現行規則還債後才能使用加成，且**不因此抬高 RP cap**。建議同類團隊限時 AP 增益**不累加**；刷新或替換的細節及最大有效期仍需 ADR。

**關鍵實作時序**：現行新玩家階段邊界先處理到期 Full Chant／Last Spell 和狀態 tick，再結算勝敗、AP 更新與補牌。因此若這張卡是 INSTANT，提議從**下一個玩家階段**開始計 N 次；若卡在 Full Chant 釋放邊界生效，**該邊界是否算第 1 次**需 ADR 明示，不允許暗中提前多領或漏領。`TimedPartyAPBonus` 是未來候選資料模型，不是現有 `StatusResolver` 的現成 Actor BUFF。

推薦團隊增益需要來源、開始 phase index、`remaining_phase_grants`、`bonus_ap`、疊加政策、到期事件；每個合格 `PlayerPhaseStart` 恰好加一次、失能／耗竭與終局處理不能出錯。普通 AP 返還不能自動減少既有 APDebt，只有明示 ReduceAPDebt 才能。

## 3. 狀態系統（Buff／Debuff／DoT／HoT）與可能的強控制

### 3.1 已有程式基礎

`scripts/domain/m5/status/status_resolver.gd` 支援 `DOT/HOT/BUFF/DEBUFF/BARRIER`、`STACK/REPLACE/REFRESH/IGNORE`、duration/tick/priority/dispel。`scripts/domain/m5/damage/damage_pipeline_resolver.gd` 的 `_effective_stats` 確實將 `patk/pdef/matk/mdef/accuracy/evasion` 的 BUFF/DEBUFF `stat_delta` 納入傷害／命中計算。`tests/fixtures/m5_2_fixture.gd` 的 `rage`、`frail` 是程式測試例，非 Lv40 全面上場技能；`SCORCH_TEST` 兩次指定末期傷害各45 HP 是 Lv40 候選數值。

| 基礎狀態候選 | 建議易懂效果 | 與 Break/控制關係 |
|---|---|---|
| 灼燒 BURN | 指定 tick 扣 HP（DoT） | 不附贈 Break；不代表所有 FIRE 卡必燃燒 |
| 寒霜 CHILL | 降低 Evasion（較好命中） | **不**等於冰凍不能動 |
| 感電 SHOCK | 降低 Accuracy（需命中判定才生效） | **不**等於麻痺；對 `GUARANTEED` 攻擊**無效**，不應當作必中 Boss 的主力控制 |
| 衰弱 WEAKEN | 降低明示 `patk` 或 `matk` | 與敵人本體 Break Gauge 不同 |
| 破防 ARMOR_BREAK | 降低明示 `pdef` 或 `mdef` | 不等於元素弱點或 Break；先前候選名 `FRAIL` 可能與別的遊戲「格擋弱化」混淆，現有 fixture `frail` **不更名** |
| 再生 REGEN | 合法時點回復 HP（HoT） | 普通 HoT 不復活 HP0，不對 EXHAUSTED 目標生效 |

六種僅是**內容候選**；不表示六個玩家可玩 SP 已有卡牌資格、數值或所有 UI。中毒、睡眠、恐懼、致盲、石化、混亂可保留世界觀，但不宜同時加入每個基礎卡組。

### 3.2 使用者同意「機率性異常＋Boss 控制抗性」的設計方向

**硬控制＝實際剝奪敵人一個合格行動**，如高階 FROZEN／PARALYZED／SLEEP，**不是**普通 `stat_delta` BUFF/DEBUFF。目前尚無正式 Domain。

推薦未來單一強控技能／目標的合格結算：
1. 先合法性、AP/MP、攻擊實際命中結算；`ON_HIT_STATUS` 只在符合卡上條件時進入狀態處理。拒絕非法指令須完全不改狀態或 RNG。
2. 查逐敵人逐狀態的 `IMMUNE / RESIST / CONVERT`。**IMMUNE** 不剝奪行動，不代表免疫本卡 HP 傷害；**CONVERT** 必須在卡及 Boss Profile 明示某個合法的較弱替代效果；未寫則沒有替代。
3. 若可施加，依卡上公開的**基礎附著率**、Boss 合格抗性、硬控保護窗計算**一次**有效成功率，用唯一 Domain seeded RNG 判斷並記錄事件。
4. **預設建議一張 SP 對一名目標最多作一次硬控機率判定**，即使有多 hit；「至少一 hit 命中／每 hit 獨立、Barrier 全吸收0 HP 算不算命中、Protect 改變承受者後狀態落誰」都要 ADR，不得在 UI 端猜。
5. 成功時只安排對**下一個符合條件、尚未開始**的 EnemyAction 生效；不撤銷已開始的攻擊，也不對已公佈且沒有合法分支的 Intent 私自改寫。
6. FROZEN／PARALYZED／SLEEP 共享單一 `HARD_CC` 類別的短暫保護窗，防止輪流控住；保護窗長度與何時啟動待 ADR。
7. **目前單一主行動 Boss**：推薦不能直接以一次麻痺取消其唯一重要的已公開動作；可以有明示抵抗、降級或弱化替代。**未來多行動 Boss** 若個別設定允許，最多影響一個指定合格行動，其他仍依公開 Intent 執行。
8. `Break` 同時降級同一行動的優先權、免疫顯示、RNG trace、StatusProcApplied/Immune/Resisted 與 Replay 均要有獨立 ADR／測試。示範「命中後 30% 麻痺」的 30% **尚未核准**。

**Boss 不是全部免疫一切**：可以某隻免疫睡眠但怕電擊，某隻對麻痺有較高抗性；「對行動剝奪免疫」不表示不吃元素傷害或其它合法普通 DEBUFF。免疫資訊需依公開知識政策提示玩家，不暗中浪費整張主要控制牌。

## 4. 弱點、Break、Exposed 與 Casting Disruption 的清楚邊界

| 系統 | 作用位置 | 何時發生 | 禁止的自動連動 |
|---|---|---|---|
| 元素 Weakness／Resistance | 每敵人逐種 HP Affinity | 真實合法 HP 傷害管線 | 命中弱元素不自動加 Burn／Break／Exposed |
| Break | Boss 本體 `break_gauge` | 合格技能明示 `break_damage`，影響下個合格未開始 Boss 行動 | 不等於扣 HP 或削 Casting Stability |
| Exposed | Boss 一次性破綻機會 | 合格姿態、技能或事件；**後一張** SP 消耗，不能同卡自建自用 | 不等於元素弱點、Combo 或永久 DEBUFF |
| Casting Disruption | 有效 `CastingInstance` 的穩定度 | 按施法與 Focus Ward 的真實干擾窗口 | 不是 Boss Break，不能隨意中斷 Last Spell |

Lv40 示例 Boss `FIRE×1.15`、`ARCANE×0.90`、`NEUTRAL×1.00`；Boss `break_max=22`；`SCORCH_TEST` 每次45；`max_ap_debt=8` 都是**versioned provisional**，不作全遊戲固定值。蓮 `R01/R07` 命中可建立**不依賴 CORE_OPEN** 的攻擊 ComboOpportunity，但其 Exposed 建立仍依各 Boss 姿態政策，不得混淆。

## 5. 敵方行動經濟：現行 A、未來 C，暫不採 B

| 方案 | 玩家體驗 | 工程成本 | 此次決策 |
|---|---|---|---|
| **A：公開 EnemyIntent，不使用玩家式敵 AP** | 下階段攻擊、目標、可反應性明確；用 Break 和 Reaction 應對 | 最低，現行已有 | **現在繼續採用** |
| **B：完全對稱敵方 AP/MP/手牌/SP 抽棄** | 深度高但資訊負擔、測試與 AI 費用俱增 | 最高 | **不採為主架構** |
| **C：公開 Intent＋內部 EnemyActionBudget** | Boss 可以預先規劃多招並公開，玩家不必看敵人手牌 | 中，需新 AI 選招與 Budget | **未來有具體多行動 Boss 需求才開發** |

實碼 `scripts/domain/m5/boss/boss_ai_policy.gd` 對現行 Lv40 Boss 選 **一個** Intent；`scripts/domain/m3/enemy/enemy_action_scheduler.gd` 能排序**多個已公開** Intent，但不負責敵方 AI／AP／MP；`scripts/domain/m3/phase/phase_engine.gd` 為每個敵方動作建立合法 Reaction Window／Resolve。不能因 Scheduler 能排序就宣稱 C 已可玩。

未來 C 若新增 `EnemyActionBudget`／`skill_cost`／`cooldown`，必須在發布行動清單**之前**選定，玩家可看到「①聚能、②單體斬擊」等完整可理解情報。若新增「降低敵下階段 Budget」卡，也僅能影響**尚未選定的下一期行動**，不能隱藏地刪除已宣告的攻擊；多個 Intent 的 Break、硬控、Reaction 和狀態 tick 時序需獨立 ADR。

## 6. 詠唱／Combo／Last Spell／角色系統仍遵守現行權威

- 每名上場角色各 12 SP，起手4、手牌不足4才補至4、硬上限8；三人共享基準6 AP；個別 MP 不自然回滿；剩 AP 在階段末嘗試轉 RP（常態 cap6）。
- `INSTANT`、`DUAL` 的 Chantless／Full 由個別卡決定；完整詠唱須等合法釋放時點、Concentrating 期間行動受限，詠唱穩定度與護唱 Focus Ward 只處理該次施法，不和 Break 混。
- `Combo` 必須 Setup＋另一位角色實際持有、合法支付與使用對應 SP，不能讓學科複合或狀態名字免費觸發第二卡；Boss `CORE_OPEN` 與 Combo 機會不同。
- `Last Spell` 每人每場一次、獨立欄位不佔12張、強制 Full；成功後 `EXHAUSTED` 真正退場，不能當作普通 Buff／Debuff 移除；釋放前 HP0 強制失效、不退已付費與次數。
- 角色身分由 CharacterDefinition/roster 取得，A/B/C 只是戰鬥槽位；不能把 24 學科直接變成固定三人的配牌限制或 24 個新職業。
- UI/i18n：卡片主要效果、AP/MP／預支 APDebt／未來 AP bonus 期數、合法目標、Full Chant、已公開 Weakness、Break/Exposed、Status 成功／免疫都要按合法 Domain 事件顯示，`zh_TW`／`en`，不以圖像／動畫決定 RNG。

## 7. 新設計的工程 Gate：尚未實裝，不得跳關

| Gate | 一次只做一個明確目標 | 最低必需證據 |
|---|---|---|
| 0 本輪 | v0.7 與前版版本關係、一份可讀統一文檔 | 檔案核對、只改文件、標明設計核准與實作未完成 |
| 1 既有戰鬥資訊 | 把現有 Buff、弱點、APDebt、Break、Exposed 呈現在正確 UI | 合法公開情報、zh_TW/en、1280×720 玩家閱讀 |
| 2 限時 AP ADR | 一張明示未來 N 期 AP 加成的候選 SP | PhaseStart exactly-once、APDebt 先還、RP cap、Full Chant release、無限收益、終局與耗竭 |
| 3 機率性狀態 ADR | 先選一張 on-hit 狀態技能＋普通怪＋一隻有抗性的 Boss | 原子合法付款、1 proc/卡/目標、Immune/Resist、RNG seed、Replay |
| 4 硬控／Boss Intent ADR | 冰凍／麻痺／睡眠只選一種測試 | 不取消已開始動作、HARD_CC 共用防連鎖、Break 優先權、Reaction Window |
| 5 混合式敵 Budget ADR | **只有真實 Boss 需求才做**，做一隻多 Intent Boss | AI 技能成本、公開行動、M3 Scheduler、Break、CC、固定種子與 QA |
| 6 內容與平衡 | BURN、CHILL、SHOCK、WEAKEN、ARMOR_BREAK、REGEN 候選卡、學科圖鑑及效果呈現 | 一張卡一個主要目的、打 Boss 時有效、不能 0AP/0MP 永久連鎖 |

**重大未決，不得由 AI 自己拍板：** 麻痺機率公式及抗性、單卡多 Hit Proc、0HP Barrier 算命中否、免疫資訊揭露、HARD_CC 保護窗幾次敵方動作、與 Break 同時落在同一 Intent 的優先權；`5AP+5MP` 是否合理、1／2／3 期加多少 AP、Full Chant 成功釋放所在階段是否開始領加成、續期與失能之後效果的政策；何時需要敵 Budget 和敵方行動限制技能。

## 8. 獨立參考：借鑑玩法清晰，而非複製整套系統

- [Magic: The Gathering — Mechanical Color Pie 2021](https://magic.wizards.com/en/news/making-magic/mechanical-color-pie-2021-changes)：每系的機制身份和能力邊界。
- [Bravely Default／Nintendo](https://www.nintendo.com/eu/games/nintendo-3ds-games/bravely-default-270579.html)：預支行動成本與未來代價。
- [Octopath Traveler 系列／Square Enix](https://www.square-enix-games.com/en_GB/news/octopath-traveler-i-and-ii-now-available-current-console-platforms)：弱點與策略視窗的可理解設計。
- [Into the Breach／Subset](https://subsetgames.com/itb.html)：公開敵方意圖的公平性。
- [Pathfinder 2e 法術規則](https://2e.aonprd.com/Rules.aspx?ID=2221)：學科與個別技能效果分類可互相獨立。

---

**維護約定：v0.7 是下一次魔法設計的唯一最新版閱讀入口。** `v0.1～v0.6` 作研究歷史。沒有新的強控、限時 AP、敵方 AP/ActionBudget、MP 減費或全元素抗性表因本文件而自動進入正式戰鬥；任何可玩變更仍需相應 ADR、版本化內容、Domain、Replay、UI 與 CI 證據。
