# ADR-BKC-01 — Break 方案 C、Exposed 來源與 Boss 行動壓制

> 日期：2026-10-20  
> 狀態：**DIRECTION_APPROVED / IMPLEMENTATION_CONTRACT_PROPOSED / NOT_IMPLEMENTED**  
> Decision owner：使用者。使用者已選 **Break 方案 C**，並確認 **Boss 不必主動露破綻、但可透過招式／姿態主動或條件式露出破綻**。本 ADR 的細節尚需逐項核准，不得將提案列為 master 當前可玩規則。  
> Base：`master@8e16c8f4e7205d256b230953fd9dda07087a90a1`；閱讀 [戰鬥總覽](../README.md)、[現行 Break 規則](../失衡與破綻系統.md)、[現行詠唱](../詠唱與魔法干擾系統.md)、[Combo](../角色連攜系統.md)、[Boss 圖鑑](../敵人與Boss圖鑑.md)。前期設計研究：[v0.8 Break-C 詳細提案（另一設計分支，供溯源）](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/design/magic-taxonomy-v0-20261019/docs/combat/proposals/BREAK_EXPOSED_CASTING_UNIFIED_RULES_V0_8.md)。  
> 本階段 BKC-01 **僅文件**；沒有改變 Domain State、事件順序、Boss AI、卡牌數值、UI 或 fixture；沒有執行 Godot／CI。

## 1. 已核准的「產品決策」與未核准的細節

| 規則 ID | 高階決策（已選 C） | 本階段範圍 |
|---|---|---|
| `BKC-001` | 明示有 BreakDamage 的合法 SP 令 Boss BreakGauge 歸零後，**壓制下一個合格、尚未開始的 Boss EnemyAction** | **方向核准**；具體命中、事件介面待工程契約 |
| `BKC-002` | 普通招式失衡後 **取消**；重大招式失衡後按**事先可知的弱化分支**降級 | **方向核准**；每個 Boss Skill 的類別與 fallback 是候選內容 |
| `BKC-003` | Break 同時創建一次 **Exposed**；後續合格 SP 可以利用，不能同卡自建自用 | **方向核准**；增益值、過期策略、資格與數值順序待核准 |
| `BKC-004` | Boss **可以沒有任何自行暴露弱點招式**；可額外設計 Boss 主動暴露或「進姿態後須被 SP 命中」的來源 | **方向核准**；來源種類、條件與公告政策見 [Boss 資料契約](../engineering/BKC_01_BOSS_BEHAVIOR_CONTRACT.md) |
| `BKC-005` | Casting Disruption 與 Boss Break 是不同資源，不能免費混算；公開 Intent 不得被無聲改寫 | **延續已核准規則**；同目標同時結算優先序待正式 ADR |
| `BKC-006` | 不用新增敵方 AP/SP；保留現行 Boss Intent／Reaction 流程 | **延續已核准方向**；未來多行動 Boss 是另一工程提案 |

**不要誤解：**本次「完成 BKC-01」是文件與可驗證的遷移契約完成，**不是**新 Break C 已寫進正式 Domain 或全部數值被使用者核准。

## 2. 玩家可讀的概念

- **失衡 Break**：「用有失衡效果的技能，把失衡條打空，就能打亂 Boss 下一招，並創造一次追擊破綻。」
- **暴露 Exposed**：「Boss 出現一次可利用的破綻；後一張符合條件的 SP 可以利用。」
- **詠唱干擾**：「Boss 正在詠唱時，針對這次法術的穩定度施加干擾。」
- **元素弱點 Weakness**：每敵人自己的傷害抗性，不是 Exposed；擊中元素弱點**不自動**削 Break 或產生 Exposed。
- **連攜 ComboOpportunity**：需要兩個角色、真實兩張 SP、兩次合法付費；與 Exposed 不同。

## 3. 方案 C 的「單一受壓制 Action」契約

```text
合法 SP 各 Hit 與其它效果結算完 → BreakGauge 首次由 >0 降為 0
    → BreakTriggered(一次) + ExposedApplied(當下無 Exposed 才成立)
    → BreakPending(對下一個合格未開始的 Boss EnemyAction)
    → 解析該已公佈 Action 的 Break 回應
          REGULAR：CANCEL → 該 Action 計為已處理，**不執行原攻擊／Buff／召喚等效果**
          MAJOR：DOWNGRADE → 按已預告且合法的弱化分支結算
    → 恢復 Gauge + 進入防止連續 Break 的恢復狀態（具體期數仍待核准）
```

- 本次 Break 對**單一 EnemyAction** 生效，不取消整個 ENEMY_PHASE；未來 Boss 同階段多次行動不應整階段癱瘓。
- 一張多 Hit SP 應先結算全卡，再判斷一次 Break；不能 hit1 歸零後截斷 hit2。
- 同一回合的溢出 BreakDamage 不能儲存第二個 BreakPending、不能因此生成第二份 Exposed。
- 未加入 `break_damage` 的 SP 不因 FIRE 弱點、冰凍、麻痺、Casting Disruption 免費造成 Break。
- BreakGauge、Casting Stability、HP、Focus Ward 完全分離。
- **不得更動已進入正式結算的 EnemyAction 或已開始的 Reaction Window**；若發生控制變化，必須遵循事前定義的合法分支。
- 具體 `CANCEL` 的取消事件是**新的 Domain 概念**，現有 Boss `fallback_skill_id` 並未提供完整 CANCEL 支援。沒有合法 Reaction 機會時不能製造假的反應窗口；有合法 Reaction 時不得自動 Pass。

### 3.1 Boss Skill 類型

- **REGULAR + CANCEL**：普通單體／普通範圍／普通增益等可被合法 Break 壓制的行動。
- **MAJOR + DOWNGRADE**：重大蓄力、戰階法術或劇情大招，需指定**相同敘事與合法目標範圍**的弱化分支。不預設全部變 B11；若原招是純蓄力，不能突然換成未預告的單體物攻。
- **NOT_ELIGIBLE**：只為極少數明確公示不可受 Break 的特殊行動保留；若大量 Boss 都使用，違背方案 C 的玩家預期，必須另行內容審查。

每個 Skill 的分類、fallback、公開文字與合法目標，都屬 Boss Content 定義，不由執行中的 AI 根據傷害臨時猜測。

### 3.2 現行 Intent 發布時機的必修差異

在 `master`：`m5_domain_resolver.gd::_end_phase_m53()` 於 `END_PLAYER_PHASE` 才透過 `BossAI.choose()` 選招並提交 Intent。現有排程器能排序多個已公開行動，但並沒有「玩家階段開始前固定下個 Intent」的保證。

**BKC-02／03 實作前置契約**：先決定並明示玩家可操作前的可信 Intent 或固定預告，包含 Break 結果分支；同一招一旦被鎖定且公告，後續 Break 只能選它的合法預告分支，不能偷重擲換招、偷換目標或擅自提前啟動已公開 Reaction。

> 這項時序重整涉及 BossAI、M3 Phase、M5 Domain、Replay；**尚未實作／仍需專門審查**。若選擇較弱的「非固定預告」方案，必須明示玩家資訊不完整，不可宣稱玩家看得到具體下一招。

## 4. Exposed 有「多種來源，一個狀態」

### 4.1 來源與 Boss 變化

| 來源 | 觸發條件 | 適用情境 |
|---|---|---|
| `ON_BREAK` | Boss 本體合格 Break 首次觸發 | **所有使用方案 C 的合格 Boss 共通來源** |
| `ON_BOSS_ACTION` | Boss 特定技能**已合法結算**並明示直接露出破綻 | Boss 自行露出核心，不要求玩家再用 SP 製造 |
| `ON_POSTURE_AND_SP` | Boss 進入特殊可利用姿態（如 `CORE_OPEN`），玩家以合格 SP 命中／符合規則 | Boss 只提供窗口，玩家實際將其轉成 Exposed |
| `NONE`（Boss 自主來源） | Boss 沒有直接暴露／可被突破姿態 | 玩家仍能透過 `ON_BREAK` 建立 Exposed |

**不是四種不同的 Debuff。**四種設定都寫入同一份目標的 Exposed opportunity；同時最多一份，不能無限疊加／重刷。Boss 可以**零主動暴露來源**，但不可因此禁止玩家使用 Break 的共通來源（除非有另行清楚核准的例外）。

例如 `TEST_BOSS_ARCANE_SENTRY` 的 `CORE_OPEN` 只是**可觸發條件**，仍需如 R01/R07 等卡配合（具體內容仍為 Demo 候選）。其他 Boss 可以設直接露破綻，或完全不自行露出。

### 4.2 利用、期限與來源去重（提案，待核准）

- Exposed 可由**後續不同 SP** 的一次合法成功攻擊利用；不允許來源 SP 自建自用，也不因建立而自動 Combo。
- 候選 UX 簡化：一張合格 SP 成功利用一次，Exposed 即消耗；多 Hit 也只算該張 SP 一次；DoT/普通攻擊是否具資格按正式內容定義。
- **候選期限：至少維持到下一個完整玩家階段結束**，避免最後 1AP 造成 Break 而無法追擊；現行以 `expires_round` 在 END_PLAYER_PHASE 處理，BKC-02 必須版本化遷移，不能直接改既有 Replay 的結果。
- 有 Exposed 時新 Break 仍可壓制 Boss，但**不新增第二份／不延長**原有 Exposed；來源不同也不可疊加。
- `ON_BOSS_ACTION` 自主暴露要明確設立**已成功結算才生效**的政策；若行動被 CANCEL，不應憑空發出該招的自主 Exposed；DOWNGRADE 是否露出取決於**已公佈的 fallback 分支**。
- **破綻收益倍率與傷害公式待核准**（例如 +20% 只是示例），不得以 ADR 名義暗改現行卡牌數值。

### 4.3 和 Combo 已核准關係

2026-10-17 更新：蓮 R01/R07 **成功命中即可建立攻擊 ComboOpportunity，無須 `CORE_OPEN`**。Exposed 則仍可由 `CORE_OPEN + 合格 SP` 或新的 `ON_BREAK` 產生。即使是同一張 R01：
- 可以合法建立 ComboOpportunity；
- 只有合格 Break（例如 R01 有明示 BreakDamage）才可能自動建立 Exposed；
- 或滿足 `CORE_OPEN` 才有既有姿態來源；
- 上述三件事**不是同一條條件**。

## 5. Break、Casting Interrupt、硬控制的邊界

- **Casting Disruption** 對單一有效 `CastingInstance` 生效，先用該實例的 `Focus Ward` 吸收；普通法術 Stability→0 的中斷、部分 MP 退款按現行 M4 規則。Last Spell 專用干擾／退場規則完全保留。
- 若同一 Boss 重大法術已被合法 Casting Interrupt 取消，不能再由 Break 在同一個法術上製造第二次取消／免費重新指定另一 Boss 行動；Exposed 若已合法建立不因此撤銷。
- **提案優先序**：確定已成立的 Casting Interrupt → 已鎖定該 Action 的 Break → 合格 Hard-CC → 普通減益。這是未來共用 Action Resolution 的順序候選，**尚未進 Domain**。
- 冰凍／麻痺若另有合法 proc 與 Boss 個別抗性，不自動扣 BreakGauge；Break 恢復期與 Hard-CC 保護窗如何共享、是否同一敵方階段最多取消 1 Action，需後續 ADR。**不能用「麻痺」和「Break」輪替永遠阻止 Boss 出手**。

## 6. 防連續失衡與資源公平（提案）

- 若 BreakPending/鎖定期間繼續受到 BreakDamage，不累積下一次壓制；卡原 HP 效果仍可依法結算。
- 推薦**已壓制行動正式解決後，Gauge 回滿，下一個完整 PlayerPhase 暫不可再 Break**，但這個恢復／保護期會令蓮的 Break SP 在此期間效果部分無效，因此仍需玩家決策與實戰 QA 再核准。
- 若下一個合格行動不存在，BreakPending 必須有明確到期政策，不能永久保留。
- AP/MP/RP、Overload/APDebt、雙人 Combo、Last Spell 真正退場、終局優先序維持現行。
- 場上 Boss 已死亡，遵循現行 VICTORY；不能為不存在的行動額外結算 Exposed。
- 每個有意義的狀態遷移需有 ordered Domain Event 與固定 seed Replay，不允許 UI／動畫決定結算時點。

## 7. 審查簽核門檻／BKC-02 啟動條件

**方向已核准（不可再自行改）**：C 的普通 CANCEL／重大 DOWNGRADE、Break 自動 Exposed、Boss 可選擇完全不自行露弱點、Casting Disruption 獨立、Combo 真實雙人付費。

**本 ADR 尚需使用者明示的「工程細則」核准才能變更 Gameplay**：
1. Exposed 消耗資格、傷害加成公式與存續到下一個玩家階段的期限；
2. Break 恢復期是否採「Gauge 回滿＋下一個完整 PlayerPhase 免 Break」；
3. Break／Casting Interrupt／Hard-CC 同行動的事件優先權；
4. 現行 Boss B01～B11 的具體 REGULAR／MAJOR 分類和每招公開 fallback，尤其 B05/B08/B06/B09；
5. Intent 在玩家可操作前公開的最小可用契約，與需按版本保留的舊 Replay。

上述項目一旦核准，再開 BKC-02/BKC-03 的單功能 Domain 實作。BKC-01 的文件完成**不等於已通過**這些玩法細則。

## 8. 反例和不可違反條件

- Break 改成所有技能／元素弱點必然扣 Gauge：**拒絕**。
- 每個 Boss 都必須用招式自行暴露弱點：**拒絕**。
- Boss 行動被 CANCEL 後仍結算其攻擊、又把 Exposed 疊兩層：**拒絕**。
- Break 能取消已開始或已結算的敵方 Action：**拒絕**。
- Break 可以無提示把一個全體蓄力大招改成未預告的單體 B11：**拒絕**。
- Exposed、ComboOpportunity、詠唱干擾共用一個免費攻擊資源：**拒絕**。
- 使用 BKC-01 的文件直接判定 BKC-02 程式已驗收：**拒絕**。

> 判定：**BKC-01 規則 ADR 完成（文件交付）／方向已核准／關鍵工程細節仍待使用者決定。** 本 ADR 自身不改寫 `master` 的現行已實裝行為。
