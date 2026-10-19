# Arbitrium Nexus — 控制異常、限時 AP 與敵方行動架構評估 v0.6

> 日期：2026-10-19 ｜ 狀態：**PROPOSED / NOT APPROVED / NOT IMPLEMENTED**  
> 上游：[統一魔法 v0.4](MAGIC_SYSTEM_INTEGRATED_DESIGN_V0_4.md)＋[資源與異常／弱點 v0.5](MAGIC_RESOURCE_STATUS_WEAKNESS_OPTIMIZATION_V0_5.md)。此文件只設計／比較，不更改兩版已記錄的現行戰鬥規則。  
> 使用者提出的新方向（**需求建議，並非完整數值核准**）：(1) Boss 可免疫某些不能行動的異常，控制也可以機率觸發；(2) 類似 `5AP+5MP` 的高成本 SP，可讓未來 1／2／3 個玩家階段擁有更高 AP 額度，但不能永久強化；(3) 重新比較現有 EnemyIntent 敵方系統與「敵人也有 AP／SP」的架構。
> **正式 SoT**：[戰鬥總覽](../README.md)、[回合與 AP](../回合與行動點數系統.md)、[傷害與異常](../傷害與異常狀態系統.md)、[失衡與破綻](../失衡與破綻系統.md)、[Boss 圖鑑](../敵人與Boss圖鑑.md)、[詠唱](../詠唱與魔法干擾系統.md)。
> 截至 master `8e16c8f4e7205d256b230953fd9dda07087a90a1` 的設計／程式核對；**未驗證新功能，不改 Domain、CardDefinitions、Master 或現有 Boss／Buff。**

## 0. 執行摘要：分段引入，不搬一整套敵人玩家對稱經濟

推薦：
1. **玩家側**：Overload APDebt 與「未來三個玩家階段各 +N AP」是**不同**的資源機制；不新增硬性的 `MaxAP`。保留「暫時提高下期玩家階段 AP」高成本卡提案，未來需新的多期 Resource Status/Boundary ADR。
2. **控制側**：可以有「命中後 X% 麻痺」，Boss 具有個別 `IMMUNE / RESIST / CONVERT` 政策，但免疫／抗性**不自動增加任何新效果**；卡牌必須明示無效時的可用部分。機率＋Boss 免疫都不能單獨防止多次出牌 stun-lock；需共享強控制抗性窗口／連續控制抑制。
3. **敵人側**：**保留目前公開 Enemy Intent 及 Reaction 管線；不要立即替全敵加入與玩家相同的 AP/MP／抽卡／SP 手牌。** 若未來希望多招、敵方資源被操縱，採**混合式「Intent + Enemy Action Budget」**，AI 先用成本與冷卻選擇招式清單，提前公開已選行動，M3 Scheduler 循目前 Reaction Window/Resolve。這比完整對稱 AP/SP 經濟更合適。
4. **弱點／Break**：元素抗性仍逐敵人，Break 下次合格行動弱化、Exposed 一次性窗口；新的 Frozen／Paralyzed 不能默默同時扣 Break 或撤銷已宣告且開始的行動。

## 1. 研究參照（結構參考，不照搬數值）

| 遊戲 | 可查證的設計重點 | 對本專案的含義 |
|---|---|---|
| [Bravely Default Nintendo 官方手冊](https://www.nintendo.com/eu/media/downloads/games_8/emanuals/nintendo_3ds_2/bravely_default/ElectronicManual_BravelyDefault_EN.pdf) | `Brave` 可預支行動（負 BP），`Default` 儲存 BP；**敵人也能使用**這兩個命令 | 正反雙方經濟可以做得對稱，但那是此遊戲的**核心戰鬥概念**，並非一般 JRPG 必需 |
| [《歧路旅人 II》Square Enix 介紹](https://www.square-enix.com/asia/newsportal/en/sg/octopathii/) | 明確宣傳以敵人弱點建立 Break，搭配 Boost 選擇攻擊時機 | 讓弱點互動被玩家理解；**不**將其「命中弱點自動 Break」規則直接取代現行分離的 Break |
| [《Darkest Dungeon II》戰鬥規則彙整](https://darkestdungeon.wiki.gg/wiki/Regeneration) | 一般單位每輪一動，部分 Boss 每輪多次行動，不必全員同種 AP 經濟 | Boss 可用多個 `EnemyAction` 呈現難度與節奏，無需讓玩家去猜其隱藏 AP |
| [《崩壞：星穹鐵道》HoYoWiki DoT 命中與抵抗](https://wiki.hoyolab.com/pc/hsr/entry/1241?lang=ja-jp) | 將基礎效果命中、一般效果抵抗、特殊狀態抵抗獨立 | 我們可以採簡化版單步 `proc_chance` + `status_resistance`，無須照搬多層乘法 |
| [《Into the Breach》Subset Games](https://subsetgames.com/itb.html) | 明示敵方攻擊，玩家以有限行動反制 | 保留 Boss Intent 的時間公平性與目標預告，比新增敵方隱藏 AP 更重要 |

## 2. 狀態：允許有機率麻痺，但對 Boss 設計可讀的控制抗性

### 2.1 「技能命中」與「異常附著」分兩道檢驗

**候選簡化版：**
1. 按既有 `PLAY_SP` 管線驗證施術角色、目標、AP/MP、施法模式；未經合法支出不能擲任何 RNG。
2. 如果卡片效果要求「命中後有 X% 機率麻痺」，先按既有命中／迴避結算。未命中不得觸發命中後狀態檢驗。
3. 在合格命中後先檢查敵人狀態免疫／可轉化政策。完全免疫時直接明示 `IMMUNE`，不必消耗無意義的麻痺 RNG。
4. 若 `RESIST`，再根據該次有效 `base_proc`、明示狀態抗性與強控制遞減計算**一次**種子 RNG 判定；沒有暗中的第二次再擲。
5. 如果成功施加，建立有期限、有次數、有事件時點、可查驗的 `StatusInstance`；失敗則保留已合法造成的 HP 傷害／其他明示效果，不重新支付 MP。
6. 在宣告／結算合法 EnemyAction 時，按**公開且確定的**控制政策決定是否跳過**下一個尚未開始的合格行動**；不擅自移除已開始的 Reaction Window，也不變更已結算結果。

是否「命中造成 0HP 因 Barrier 吸收」仍可觸發 `on-hit`，以及「Full Chant 延後生效時才擲狀態 RNG」都必須在個別 CardDefinition/ADR 裡明示，不由 UI 另算。

### 2.2 免疫／抵抗／轉換：逐 Boss 與逐 Status 設定

| Policy | 意義 | 擬定示例 |
|---|---|---|
| `IMMUNE` | 不能被此類強控制奪走行動 | BOSS_X 免疫睡眠，但麻痺並非必然免疫 |
| `RESIST` | 基礎觸發概率按配置降低 | 某菁英對麻痺 50% 抵抗，卡原始 30% → 示意最終 15% |
| `CONVERT` | 強控制被替代成明確的較弱合法效果 | Boss 不失去行動，但可被技能**明示**改為攻擊能力下降或施法干擾；若替代機制尚未定義則不可轉換 |

`CONVERT` **不是**「所有麻痺自動獲得 SHOCK」；需在技能和 Boss 兩邊的 profile 明示，以及 UI 預覽相應可見結果。

**建議：** 玩家看得到某 Boss 是否免疫「無法行動」；未公開的其它抵抗資訊按目前資訊權限顯示「未知」，不能由 UI 偷揭露。卡牌如果主效果是控制且對 Boss 完全無效，要在合法性／提示預覽中說明，不要讓玩家誤以為能封鎖 Boss。

### 2.3 防止 Stun-lock：強控制加上「同類控制保護窗口」

機率和免疫都不是完整解法。例：四張有 30% 觸發的麻痺卡，若彼此獨立且無抗性，多次嘗試至少一次成功的機率會明顯增加；多角色連攜更容易形成永久控制。

建議**強控制**（FROZEN / PARALYZED / SLEEP 等**奪走行動類**）共享同一 `HARD_CC` 控制組別，並定義：
- 一次生效只影響**一個**合格、尚未開始的敵人行動；不得跨多個 Boss 行動重複剝奪。
- 控制成功後短暫進入「強控制抗性／保護窗口」（例如 1～2 個敵方行動），期限內同類強控制**不再造成第二次行動取消**，或轉成明示較弱效果；完整細節留待 ADR。
- 即使有多張 Frozen + Paralyzed 也按同一組統計，不能交互洗掉抗性；其抗性窗口和 `Break` 降級同一行動的優先權必須另行規定。
- 若 Boss 為 `IMMUNE`，完全不觸發不能行動，但其卡片原有傷害照規則結算；是否附替代效果須明示。
- 不採隱藏「每回合 20% 自動跳過」造成公開 Intent 結果不可理解；若未來採隨機跳過，實際觸發需在該行動開始前以 DomainEvent 公開，能重播、能提供一致 Reaction 選項。

### 2.4 候選卡面範例（不是既有 SP）

`雷縛：對一名敵人造成雷電傷害；命中後有 30% 基礎機率麻痺，若成功則跳過敵人下一次合格普通行動。`

- 為何是「基礎機率」：敵人的抵抗與保護窗口可改變最終成功率。
- 對 Boss `IMMUNE` 時，仍造成這張卡正常的元素 HP 傷害，除非技能還有其他明示替代效果；不免費追加 Break 或 Exposed。
- 攻擊命中與麻痺附著需可分別記錄事件，例如（**概念性事件名，非已存在 API**）`AttackHit` → `StatusProcChecked` → `StatusApplied / StatusResisted / StatusImmune`。
- 若目前 Boss 每輪只有一個公開 Intent，該次麻痺是否允許跳過它**是一項重大決策**；建議首發 Boss 禁止直接取消該已公布主要行動，優先弱化為可測試之對抗效果。

## 3. 「增加最大 AP」改為限期玩家階段基準 AP 加成

### 3.1 既有資源不應誤解

現有 `BaseAP=6`，沒有 `CurrentAP≤6` 的硬上限。`current_ap` 表示當期可花費；`next_player_ap_bonus` 已能安排**一次下階段**的額外 AP；`ap_debt` 表示未來先還的借款。

故「限時提高最大 AP」**推薦呈現名稱**為 `未來 N 個玩家階段各 +X AP` 或 `時間增幅`，而不是去加一個未存在的 `max_ap` 字段。

### 3.2 建議卡牌（成本與數值僅例示）

| 方案 | 本期成本 | 受影響的未來玩家階段 | 每階段 AP 加成 | 合計未來新增 AP | 只比較名目 AP 收支 |
|---|---|---|---|---|---|
| 一期增幅（示意） | 5 AP＋5 MP | 下一個玩家階段 | +2 | 2 | -3 AP，代價偏高 |
| 兩期增幅（示意） | 5 AP＋5 MP | 接下來 2 個玩家階段 | +3 | 6 | +1 AP（未扣時間價值／MP） |
| 三期增幅（示意） | 5 AP＋5 MP | 接下來 3 個玩家階段 | +2 | 6 | +1 AP（未扣時間價值／MP） |

因此**不要設計一張固定「5AP+5MP、未來每期+2AP」的卡，然後只延長從1期到3期而不改其它數值**；一期版本明顯太弱，三期若當前 Boss 戰只剩兩個階段就無法回本。正確的平衡維度還包括回合先後、詠唱風險、MP 來源、後期牌庫、Boss 突破視窗與 `AP→RP` 轉換。

**注意**：即時付 5 AP 可能使本玩家階段只留 1 AP，縮小可轉 RP 的份額；未來得到的額外 AP 若沒花完，仍按當時有效 RP cap 轉換，**不能因此偷偷提升 RP cap**。當期合法其他加成可使 CurrentAP 超過 6；不預設硬上限。

### 3.3 Domain 生命週期（新 ADR 必需）

建議實作為 **`TimedPartyAPBonus`**，而不是「更改角色永久 MaxAP」：
- 初次合法施放後，記錄 `source_card_instance_id`、`source_actor_id`、`bonus_ap_per_phase`、`first_eligible_player_phase`、`remaining_player_phases`、`stack_policy`、`version`；**概念字段不是現有 API**。
- **從下一個玩家階段開始**，每次 `PlayerPhaseStart` 僅生效一次；先確定這一階段的 bonus，再依現有規則償還合法 `APDebt`，最後確定 `current_ap`。
- 例如 +2 持續 3 個下一期玩家階段且無 APDebt：下一、下下、第三個玩家階段可用基準 AP 分別 8／8／8；第四個恢復正常基準 6（若無其它加成）。
- 開始／應用／剩餘回合／到期都應有明確 Domain Event 與狀態；不隨 Tween 或 UI 過幾秒就失效。
- **建議初版不可疊加**：同類不變成 +4、+6 等，每個玩家階段只能有一項有效的時間增幅；新施放的 `IGNORE/REPLACE/REFRESH` 細節必須依卡的公告明示，不能從現有 `StatusResolver` 直接套用。
- 當施術者失能、耗竭時，已合法施加的**全隊資源增益是否保留**須事前定義（我偏向團隊性既存效果保留，但不得對退場者作一般治療／Buff 或回場）；因 `EXHAUSTED` 真正退場不應被新時空技能撤銷。
- 若本期末直接終局，尚未到期的加成沒有返還 AP 的通則。

### 3.4 無限資源循環風險

檢查：
- 5AP 支付後能否透過另一張費用減免與 AP 返還反覆免費施放？
- 多張 AP Bonus 是否反覆刷新持續時間，變成全程永久 +N？
- 被延後的 AP Bonus 如何與 APDebt 及 `Overload` 報價相互影響？
- 付費 5AP 時玩家的防禦資源（RP）受到什麼壓縮？
- Enemy Reaction 無限刷卡與 0成本 SP 組合是否使每期總 AP 無限制增長？

## 4. 敵人行動經濟：比較三種架構

### 4.1 Repo 現況（已核對實碼）

- `scripts/domain/m5/boss/boss_ai_policy.gd`：Boss 依內容政策選擇並發布**一個**公開 Intent，帶 `skill_id`、`target_scope`、`reaction_window`、`break_fallback` 等。
- `scripts/domain/m3/enemy/enemy_action_scheduler.gd`：支援接受**多個已公開 Intent**，按 `action_order`、`created_seq`、`intent_id` 安排 EnemyAction；不負責 AI、成本或 RNG。
- `scripts/domain/m3/phase/phase_engine.gd`：每個 EnemyAction 依 `DECLARE_NEXT_ENEMY_ACTION`／`OPEN_REACTION_WINDOW`／`QUEUE/CONFIRM/PASS_REACTION`／`RESOLVE_ENEMY_ATTACK_M5` 結算；不得在有合法反應時自動 Pass。
- Boss 有 `B01..B11` **命名技能／skill_id**，**已是敵方技能定義，但不是玩家式 12 張 SP 牌組，亦未見獨立敵方 AP/MP 與手牌**。
- `scripts/domain/m5/integration/m5_domain_resolver.gd` 將 BossAI 選擇與 Domain 包裝串接，已宣告之 EnemyAction 不能被未公告政策更動事後偷偷替換。

### 4.2 選項比較

| 比較面向 | A. 現行 Intent（無敵 AP） | B. 玩家對稱敵 AP＋SP／手牌 | **C. Intent＋內部 EnemyActionBudget（推薦長期）** |
|---|---|---|---|
| 玩家易讀 | **高**：下一招是什麼 | 中：須理解敵人的 AP、SP、可能出手數 | **高**：只看已預告的技能與行動數 |
| Boss 行動多樣化 | 可用多 Intent / Phase / 特殊能力，需擴充 AI 選擇 | 很高，可自由組技 | **高**：技能成本＋每期選多招 |
| 用「減少敵人 AP」干擾 | **不適用**；以 Break／Weaken／Disruption | **可以**，但會牽動支付／AI／公開意圖 | 可設「降低下個未公佈行動 Budget」，需 ADR |
| 敵人要抽卡／棄牌 | 不需要 | 若 SP = 真正卡牌，可能需要，成本最高 | **不需要**：用命名技能與 CD／Budget |
| 與現有 Combo／Break 相容 | **最好** | 需重做敵方費用、意圖、失衡互動 | **中高**：保留每個 Intent，但 AI 要新增一層選擇政策 |
| QA／Replay 工作量 | 低至中 | **最高**：AI 費用、規則、抽牌、時機倍增 | 中：Budget 和多 Intent 合法性 |
| 平衡 | 靠 scripted Intent／CD／階段 | 可對稱但數值負擔最大 | **可預算化 Boss 招式組合** |
| 大量普通敵人 | 一敵一公開 Intent 易懂 | 很多敵人的成本決策很難讀 | 一般怪沿用 A，精英／Boss 才用 C |

**選項 B 細分：**「敵人有自己的 AP 與可配置技能」**不必然**等於「敵人也有手牌、抽牌、12-card deck」；若玩家需要真正可以被削減的 enemy.AP，可以先只加資源和技能費，而不移植玩家完整牌庫。即便如此仍須建立預算分配、AI 費用驗證、不可支付時 fallback、已宣告行動不被私改、公開透明度和 Replay。

### 4.3 我推薦 C 的具體樣貌（未來需求出現時才開發）

- **目前 P0**：保留 A；每名普通敵人一個預告、Boss 當前一個 Intent，玩家用 Break、Debuff、Casting Disruption 反制。
- **未來 P1**：挑一隻需多招的 Boss，給予 `EnemyActionBudget`（例：4 個「威脅點」），每個命名 `BossSkill` 配 `action_budget_cost`／`cooldown`／`requirements`。這是敵方 AI **內部排程數值**，不等於玩家可以轉 RP 的 AP。
- AI 選擇的行動**清單先公布**：例如 `[蓄力(1), 單體攻擊(2)]`，累計花 3／4，剩餘無用；不用畫「Boss 手牌」。
- M3 `EnemyActionScheduler` 目前可處理多個已公開 Action；要將 BossAI 從單一 intent 擴充為多 intent 的**新的 Domain 改動**，不能以 scheduler 可排序就宣稱完整支援。
- 已公佈後，玩家能依規則合法消除／弱化部分 Intent 的**範圍須事前清楚列出**；沒有這些政策，就不能用「扣 Budget」回溯撤掉公佈過的招式。
- 如果真的出現「減少下階段敵方 AP/Budget」的玩家卡，應先令它影響**下一個尚未選定的敵方行動清單**；玩家得知預告時點與生效範圍，不能在已公開既定 Intent 後無提示刪除招式。
- 一個敵方階段最多幾個 Action、每個 Action 的 Reaction Window、Break 只降級哪一個合格 Action、強控制只能移除哪一個 Action、狀態 tick 在多 Action 下是否只每 phase 一次，都需要獨立 ADR。
- **無須內建敵方 MP、過熱資源、法術 SP 手牌**；只有當特定 Boss 的設計真的需要「儲存力量／蓄能」時，才加可讀的**Boss 專屬 Charge／Stability**，不擴散到每隻怪。

## 5. 迷你情境：為何 C 比 B 更符合目前三角色 RPG

**玩家可見：**
`text
Boss：雙相守衛（未來候選，不是現有 Lv40 Boss）
下次敵方階段：
  ① [核心聚能]　建立已明示施法實例
  ② [追擊斬]　攻擊蓮
玩家現在有：蓮破勢斬（Break）、朱音雷縛（30%麻痺候選）、紬保護卡
`

**採 A（目前）**：選一個合格 Boss Intent；玩家依公開意圖分配 AP/RP；簡單，最少改動。

**採 B（全對稱）**：玩家還要看敵人 AP/MP、技能成本、其手牌／抽牌（若有）、下次是否能使用加成、何時被麻痺暫停；策略可能深但資訊負擔和實作成本很高。

**採 C（長期推薦）**：Boss 使用看不見或按需要可解釋的 Action Budget 先排出兩個 Intent，玩家只需要看下一回合**兩個明示行動**。麻痺若允許控制該 Boss，也只會影響一個合格 Action，避免直接封殺整個敵方階段。Break 和 Casting Disruption 仍各自對應本來的規則。

可讀性決勝條件：**不是玩家必須理解 Boss 的成本公式，而是公開哪些攻擊／施法將發生、可以保護誰、哪個效果能改變哪一次 Action。**

## 6. 下一步 ADR Gate（按風險由低到高）

| ADR | 題目 | 新能力要求／驗證 |
|---|---|---|
| `MAG-CC-01` | 一張卡的 on-hit `proc_chance`、個別敵人免疫／抗性／轉化 | 使用 Domain RNG、單次有序擲骰；拒絕非法命令不得改 RNG；StatusApplied/Immune/Resisted、i18n、Replay |
| `MAG-CC-02` | 強控制與 Boss Break／公開 Intent 的先後關係 | 一個強控消耗多少合格 EnemyAction、免疫、連續控制保護窗、多行動 Boss 的次序 |
| `MAG-AP-03` | 限時 Team AP Phase Bonus（下 1～3 個玩家階段） | 不能變永久 BaseAP；施法當期不加；phase start 一次；債務償還後總額；不疊加；狀態移除、失能與終局 |
| `MAG-ENEMY-04` | 多 Intent 的 BossAI ActionBudget／Cooldown | 技能成本、總 Budget、公開順序、Boss Phase、Reaction Window、Break fallback、保存 seed 與 replay |
| `MAG-ENEMY-05` | 玩家技能減少敵方下一階段 ActionBudget | 只能在尚未提交的選招階段生效、最小一個合格 Action、禁止破壞 Intent 公平性 |

**不作為本輪範圍**：敵人完整 `CardInstanceID`／抽棄牌堆／玩家同款 `Overload`，全域「每怪必有 6AP」，所有 Boss 一律免疫所有狀態，隨機跳過當前已公佈行動卻不在 UI 告知。

## 7. 尚待使用者確認的決策，禁止當成已批准規格

1. **控制**：Boss 對「不能行動」的狀態採**逐敵／逐狀態**配置；允許機率，但高強度 Boss 需要強控制抗性／保護窗。是否接受？
2. **限時 AP**：高消費 SP 不改 `MaxAP`，改為未來 N 個玩家階段 `+X AP`、無限疊加禁用、候選 `5AP+5MP`。是否接受？
3. **敵方經濟**：現在沿用 A；當 Boss 多行動或有敵方資源干擾玩法的必要時採 C「已公布的技能行動清單＋隱性或公開 ActionBudget」，而不是立刻實作 B 全對稱敵方 AP/SP 手牌。是否接受？
4. **Boss 控制目標**：想讓特定 Boss *有機率跳過 1 個合格 EnemyAction*，還是 Boss 一律不能真正跳行動，只允許降級／施法干擾？若選前者，會另立重複控制防鎖與意圖時序 ADR。

> 本文件是 v0.6 設計比較與候選決策，未執行 Godot 變更／CI；現行戰鬥規則完全不變。
