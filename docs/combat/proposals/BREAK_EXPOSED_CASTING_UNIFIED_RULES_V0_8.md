# Arbitrium Nexus — Break／Exposed／Casting Disruption 整合規則 v0.8

> **日期：2026-10-20｜狀態：DESIGN DIRECTION APPROVED (Option C) / DETAILED RULES PROPOSED / NOT IMPLEMENTED**  
> **使用者已確認的高階決策**：採用簡化方案 **C**：Boss 失衡值歸零時，**下一次合格普通行動可被取消、特殊大招降級**，**同時建立一次 Exposed 戰術機會**。Casting Disruption 保留為專門應對有效詠唱的獨立系統。  
> **仍待後續正式批准的細節**：本文提出的 Cancel／Downgrade 分類、Exposed 期限、Break 恢復保護期、倍率、與硬控制／Casting Interrupt 的衝突政策，均屬**提案建議**；不能以本文件自行修改 Gameplay。  
> **繼承**：[魔法統一設計 v0.7](MAGIC_SYSTEM_UNIFIED_V0_7.md)。**現行已實作／權威規則**： [戰鬥總覽](../README.md)、[失衡與破綻](../失衡與破綻系統.md)、[詠唱／干擾](../詠唱與魔法干擾系統.md)、[角色連攜](../角色連攜系統.md)、[敵人/Boss](../敵人與Boss圖鑑.md)。  
> **源碼核對**：`master 8e16c8f4e7205d256b230953fd9dda07087a90a1`，主要 `boss_ai_policy.gd`、`tactical_sp_resolver.gd`、`enemy_action_scheduler.gd`、`m5_domain_resolver.gd`、`phase_engine.gd`。**不改 Godot 程式、已核准 Combat Rules、卡片數值或 master**。只有後續正式 ADR 可使新規則生效。

---

## 0. 玩家一分鐘理解版

**Break 失衡：「把 Boss 的失衡條削到零，削掉／削弱牠下一招，並給你一次追擊弱點的機會。」**  
**Exposed 暴露：「Boss 身上出現一次可以利用的破綻；後續一張合法的攻擊 SP 可趁勢輸出。」**  
**Casting Disruption 詠唱干擾：「敵人正在準備魔法時，破壞那一次施法的穩定度，符合條件可阻止法術釋放。」**

玩家平時只需 HP／**失衡量表**／公開 Intent，Break 後顯示「下一招已取消／降級」＋「破綻 ×1」；只有 Boss 處在合法詠唱狀態時才追加顯示「詠唱穩定度＋Focus Ward」。玩家不用同時盯三條永久存在的計量表。

### 0.1 兩種「弱點」不要混為一談

`WEAKNESS` 是敵人個別**元素／傷害抗性**（FIRE 等），屬 HP 傷害倍率；`EXPOSED` 是單次可利用的**破綻狀態**。Break 歸零自動 Exposed 不代表 FIRE 命中自動造成 Break，也不代表任何元素附帶 Burn／Paralyze；只有特定合法 SP／Boss Profile 明示額外效果才可例外。

## 1. 必須維持的現行硬規則

1. 三個可操作隊員各12 SP、共享每玩家階段基準6 AP、獨立 MP；未用 AP 可能在階段末轉為 RP。**不能因新 Break 機制免費重抽、返 AP 或觸發 Combo。**
2. **只有**合法明示 `break_damage` 的技能才削失衡量表；沒有 Break 標記的普通元素傷害**不會**削 Break。打不中時如要求 on-hit 則無 Break。HP Barrier 吸收 HP 傷害不自動吸收 Break；狀態／命中事件政策需版本化。
3. **多 Hit SP** 先結算全部合法 Hit／效果，再統一處理本張 SP 的 Break 觸發；不能第1 Hit 歸零就中止其餘合法 Hit，不能同卡「產生 Exposed 又用自己新產生的」。
4. Boss 的 **BreakGauge** 與任一 **CastingInstance** 的 **CastingStability**、HP、Focus Ward 是不同狀態；`BreakDamage != CastingDisruption != HPDamage`。
5. **已公布的敵方意圖／目標／可反應時點不會隱形被改寫**；Break 取消或降級只能落在事先公示有合法反應分支的、**尚未開始**的合格 EnemyAction。
6. `R01/R07` 依2026-10-17已核准設定：合法命中可製造**攻擊 ComboOpportunity**，不需要 `CORE_OPEN`；Exposed 的舊姿態來源仍依各 Boss 設定，現在再追加「Break 成功」作為**新建議的共通來源**。Combo Setup／Finisher 仍是不同人兩張 SP 正常支付。
7. Last Spell 的 Full Chant／中斷例外、成功後 `EXHAUSTED` **真正退場**等已核准規則不動。

## 2. 玩家可感知的新主循環（方案 C）

`text
玩家看見已公開 Boss 下一行動及 Break 分支
    ↓
玩家用明示 BreakDamage 的合法 SP 壓低 BreakGauge
    ↓
[本張 SP 完整結算後] BreakGauge <= 0 ?
    ├─ 否 → 持續作戰；下一招按預告執行
    └─ 是 → BREAK_PENDING，鎖定下一個合格且尚未開始的 EnemyAction
                ├─ REGULAR → CANCEL；敵方不造成該次行動效果
                └─ MAJOR   → DOWNGRADE；按預先公布的較弱分支執行
             同時建立 EXPOSED ×1（如果尚無未消耗的 Exposed）
                ↓
          可於合法窗口由之後的攻擊 SP 趁機追擊
                ↓
          受影響 EnemyAction 被結算／取消 → Boss 恢復量表＋保護窗口
`

**「普通招式取消、大招降級」不等於「Boss 永久不能行動」**：兩者都只針對**一個**合格 EnemyAction。若未來一個 Boss 在同一敵方階段公開三個行動，只壓制符合目標政策的一個，不整階段清空。

## 3. BreakGauge 的觸發、行動資格、分類與消耗時點

### 3.1 計量規則（方向）

- 每個 Boss 有 `break_max` 與 `break_gauge`，範圍0～max；示範 Lv40 `max=22` 是**PROVISIONAL fixture**。未達0的累積是否在 Boss 各階段重置按敵人內容配置；**本次建議在尚未 Break 前跨階段保留**，可讓玩家用兩階段完成目標。
- SP 有明確 `break_damage`；本張 SP 完成、命中與傷害記錄完成後，套用合法 BreakDamage。若由 N 降至0，只觸發**一次** Break；溢出的破勢量不變成第二次 Break／免費 AP。
- `BreakPending` 中（已失衡、待處理下一行動）再受到 BreakDamage 不累加或產生第二張 Exposed：事件顯示「失衡鎖定，額外失衡無效」，卡牌原本 HP 傷害照常；避免無限 Break 封鎖。
- 只有 `next_eligible_enemy_action` 可以消耗 Break。**合格**明確是 Boss Profile 容許 Break 對應且未正式開始的 EnemyAction，不會跳過已結算的動作，也不能打斷某個正在播放且已完成 Domain commit 的攻擊。
- Boss HP 歸0導致終局，採現行勝敗優先序；不為不存在的後續行動再兌現 Break／Exposed 獎勵。

### 3.2 公開分支決定方式：不是實時讓 AI 隨便換招

**新必備技能資料（建議名稱，非現行 schema）**：

| 欄位 | 意義 |
|---|---|
| `break_response` | `CANCEL`（普通）／`DOWNGRADE`（重大）／`NOT_ELIGIBLE`（需明示且不得濫用） |
| `fallback_skill_id` / `cancel_result_id` | 預先指定取消或降級的合法結果，不在結算後重新抽招 |
| `public_break_preview` | UI 顯示「失衡時：取消」或「失衡時：降級為 XXX」，含目標／範圍等受影響之合法資訊 |
| `eligible_before_action_start` | 明確是否能壓制該尚未開始的行動，不可逆向對已開始攻擊套用 |
| `break_recovery_policy` | 本次效果結算後的量表恢復及保護時點 |

**REGULAR / CANCEL**：此行動結算成明確的 `STAGGERED_NO_ACTION`，不產生原來的傷害／治療／Buff／詠唱；因無敵方攻擊，不建立假反應窗口、亦不是「有可用 Reaction 時自動 Pass」。**敵方階段仍要正常推進**，該次計作一個已消耗的 EnemyAction，以供其他敵人行動與 Status tick 正常結算。

**MAJOR / DOWNGRADE**：重大招式、蓄力／詠唱連段用事先定義的次級 `fallback`；**不是原本的強力攻擊繼續完整出招**。弱化可能是降低傷害、改較弱攻擊、冷卻校正或合法非傷害姿態，但**必須有公開可理解的分支**。現行 Lv40 `B11` 是候選失衡降級攻勢（物理×0.60／單體）；**不能不加區分就把所有 B05／B08 蓄力轉成 B11**，否則 Boss 可能由蓄力忽然變成沒公佈的單體攻擊。

**NOT_ELIGIBLE**：僅用於有足夠劇情／內容證據的指定行動，卡牌／Boss UI 應事先說明；不能讓所有 Boss 大招暗中「不吃 Break」，因本方案承諾重大招式也會降級。優先推薦重大招式走 DOWNGRADE。

### 3.3 真正的 Boss 意圖公布時點（本次 Review 的重要發現）

截至上述 `master`，`scripts/domain/m5/integration/m5_domain_resolver.gd` 在 `END_PLAYER_PHASE` 的 `_end_phase_m53()` 才調用 `BossAI.choose()` 並把 Intent 提交給 Scheduler；因此**當前技術實作不等於玩家在出牌前就必定看得到「下一招將如何被 Break 取消／降級」**。

**為了讓方案 C 公平、直覺，未來推薦的設計時序是：**
1. **玩家可操作前，先合法公開本次將應對的 Boss Intent 或至少固定的可信招式預告＋Break 分支**；AI 不因玩家行動後的內部 RNG 私自換目標／招式。
2. 在 PlayerPhase，Break SP 可以改變該 Intent 的**已公佈分支結果**；不是重新滾隨機 Boss 招式。
3. END_PLAYER_PHASE 只**確認及排程**經合法分支解析的敵方行動，並投影當前結果。
4. 若真的要保留選招於 END_PLAYER_PHASE，則玩家不能被宣稱已事先知道具體招式；必須另外做真正的 PREVIEW／Forecast 契約，或將「取消／降級」作為資訊不完整的承諾。**推薦前一種**。
5. 若途中 Boss 階段改變、目標死亡、合法姿態切換，依**事先公開的例外分支**處理，不直接偷偷重選。

**這是未來 Domain/UI 改造需求，不是本文件執行改造。**

## 4. Exposed 改成 Break 的自動獎勵，保留特殊姿態來源

### 4.1 建立來源

來源一：`BREAK_TRIGGERED` → 如果 Boss 沒有有效 Exposed，建立 **1 份** `EXPOSED`。  
來源二：特定 Boss 的 `CORE_OPEN` 等**已公開合法**姿態，配合指定真實 SP（例 R01／R07）可以建立 **同一種 Exposed**。  
**兩種來源不創造兩個 Exposed 槽位，不疊層、不把相同漏洞多次刷新**。已存在 Exposed 時再觸發 Break，仍獲得行動壓制，但不再送第二次／不延長原本期限。

### 4.2 利用條件（推薦為新系統統一規則）

- **一份 Exposed 可以由一張後續合法且命中 Boss 的「造成 HP 傷害的 SP」利用**；首版推薦預設任何合法傷害 SP 都具基本追擊資格，未明示的普通 Basic Attack／HP Damage over Time／純治療／純護盾不消耗。Boss 個別姿態可用明示 profile 限制或提供額外 bonus，但避免過度細分許多看不懂的資格。
- **來源 SP 不可使用自己剛建立的 Exposed**。若已有舊 Exposed，單一 SP 不可在同一行動「消耗舊 Exposed 並重建新的 Exposed」來無限續接。
- 建議用 **整張 SP 作為消耗單位**：多 Hit SP 若至少一次合法命中，將 Exposed 增益套用到該張 SP 符合條件的命中傷害，**只消耗一次**；全數失手則不消耗。這需與舊 `tactical_sp_resolver.gd` 的 `success` 語義一致或另寫版本化規則。
- 「命中但 HP Barrier 吸光 HP」**仍算成功命中，消耗 Exposed**（符合現行成功命中才消耗的方向；且可讓強化傷害對 Barrier 有效），UI 在預估傷害時必須明示會先打到 Barrier。
- **Exposed 不預設免費 BreakDamage、ComboOpportunity、抽卡、AP 或第二次攻擊**。追擊加成可由內容 profile 提供，例如「下一張合格攻擊 SP 傷害 +20%」（**示例未核准**），但不能將此數值當全世界統一值。
- 同一張合法 Finisher 若同時利用原先的 ComboOpportunity 與 Exposed，應讓兩個效果**各自按照版本化規則結算**；不可由新 Exposed 偷偷把既有 Combo 的額外傷害再乘一遍。倍率／加法次序和上限必須用專門 ADR 確認，**v0.8 不修改既有 Combo fixture**。

### 4.3 生存期（避免「我打破時 AP 用完，完全無法追擊」）

**推薦：** Exposed 最早在觸發 Break 的技能**完整結算後**才能利用；最晚存活到**下一個玩家階段結束**，期間如果被合格 SP 消耗便立即結束。若是玩家階段內建立，**不在本階段結束就逾期**；若在敵方階段建立，則至少延續到緊接的玩家階段結束。

本提案將 Exposed 看成**一次性可追擊資格而非整個時間窗內無限增傷**。一張合格 SP 成功利用後立即消失，即使尚有剩餘有效時間。

若前述「本回合已用 AP＝0」而選擇結束階段，玩家在**下一玩家階段**仍有合理機會消耗 Exposed；同時既有 Full Chant 若在該邊界成功釋放且命中，亦可按已核准的詠唱時序結算為合法後續攻擊，**不能先讓 Exposed 在開始邊界逾期，導致失去應有追擊**。

**和現行實作的差異**：目前 `m5_domain_resolver.gd` 在 `END_PLAYER_PHASE` 具有 Exposed 到期檢查，並依 `expires_round` 處理。上述全期保障需要明示的相容性 ADR／調整，**不可宣稱已完成**。

## 5. Break 結算、恢復與防永久壓制

### 5.1 推薦狀態機

`text
BALANCED (BreakGauge>0)
   └─合法 BreakDamage 使 gauge→0 → BREAK_PENDING + 建立 EXPOSED(如不存在)
BREAK_PENDING
   └─下一個合格尚未開始的 EnemyAction
       ├─CANCEL：以 STAGGERED_NO_ACTION 結算一個行動
       └─DOWNGRADE：按公開 fallback 結算一個行動
           ↓
RECOVERY：BreakGauge 回到該 Boss 定義的恢復值（初版建議回滿）
           ↓
POST_BREAK_RESILIENCE：下一整個 PlayerPhase 不能再次觸發 Break
           ↓
BALANCED（後續可重新打破失衡）
`

**理由**：若 Boss 每輪只有一個主要行動，玩家每階段都能把 Gauge 打空、每階段都取消普通招式，Boss 將永久無法施壓；與新增 Frozen／Paralyzed 後更嚴重。

**首版推薦最容易說清楚的防鎖方式**：
- 完成被取消／降級的行動時 **Gauge 回滿**。
- 下一個完整 **PLAYER_PHASE** 標示「姿態保護／穩定中」：BreakDamage **不扣 Gauge、不觸發 Break**，但該 SP 其它合法 HP 傷害仍有效，卡 UI 明示「此時無法造成失衡」。
- 這個保護只阻止 Break，不額外賦予元素免疫／Status 免疫；接著正常解除；**保護期長度與抵抗細節仍屬需要核准的提案**。
- 如果某 Boss 在相同敵方階段有多個 Action，僅一個受到 Break 壓制，按既定 Scheduler 順序完成其它合法 EnemyAction。恢復窗口的開始以**本次 Break 對應行動的正式結算**為準，不依動畫長短。
- 若 Boss 正處於 `BREAK_PENDING`，所有額外 BreakDamage 不會排隊累積跨多個回合的免費 Break。
- 下一個合格行動長時間未出現時，`BREAK_PENDING` 必須有可見的**有效期限／回收事件**，避免永久鎖住 Gauge；推薦「最多到下一個敵方階段結束」，但如果該階段沒有合格行動，則回收／恢復，不產生免費行動壓制。**到期的 Exposed 各自獨立，不應因此撤銷已合法獲得的追擊。**

### 5.2 針對 Lv40 的測試範例（不代表新卡已可玩）

Lv40 Boss 目前 `BreakMax=22` 候選；`R01` 成功命中破勢量6、`R06` 破勢量5、`R07` 未明示破勢時不是 Break SP。例：Boss 現剩 BreakGauge=5，蓮成功打出 `R01`（BreakDamage 6）→ Gauge=0 → Break 觸發；**先完整結算 R01 的合法 HP Damage**，之後才新建一次 Exposed，**R01 自己不吃新 Exposed**。

同一 R01 仍可按已核准條件在 `CORE_OPEN` 關閉時創建攻擊 ComboOpportunity；它不是 Exposed 的門檻。玩家若此階段無 AP 可追擊，新 Exposed 最少保留到下一個玩家階段結束；在 Boss 行動被 Cancel／Downgrade 後玩家可以追擊。

## 6. 詠唱干擾：與 Break 保持獨立，但 UI 按情境顯示

**玩家規則**：「Boss 正在蓄力施法時，可用明示 `Casting Disruption` 的 SP 破壞**這一次法術**；與打空 Boss 身體失衡條無關。」

建議結算：
1. 必須存在**有效且可干擾的 CastingInstance**，只看該法術的 `CastingStability`；不是對 Boss 全身施加 Disruption。
2. 若該實例有 `Focus Ward`，依現行規則**先扣 Ward，再扣 Stability**；不能由 HP Barrier 替代 Ward。
3. `Stability→0` 且是一般可中斷完整詠唱，按**現行 Casting Interrupt** 判定法術取消及對應費用政策；特殊 Last Spell 的失衡／延遲例外不變。
4. 某 Boss 大招的**蓄力行動**和**法術釋放**可能屬兩個不同 EnemyAction／CastingInstance 時點。必須由 Boss 設計明示：Break 降級的是「蓄力動作」、「預定釋放」還是下一次其它合格行動；Casting Interrupt 則直接處理該詠唱實例。
5. HUD 常態只顯示 HP＋BreakGauge＋Boss Intent；**只有有效詠唱才顯示 CastingStability／Focus Ward**。不需要玩家平時盯一條常駐「干擾槽」。

**主要衝突政策推薦（新 ADR）**：
- 如果某次 Boss 重大法術已被**合法 Casting Interrupt** 取消，不能再對**同一次已消失的法術**再進行 Break「降級攻擊」；**Casting Interrupt 對該法術優先**。若 Break 也鎖定同一次釋放行動，該次 Break 的行動壓制**隨被取消之行動一起視為已結算／不自動排隊多取消下一招**；已建立的 Exposed 仍可合法消耗。
- 如果只是 Break 成功而詠唱 Stability 尚未歸零，Boss 不一定失去詠唱實例；它依已公佈的**Major Downgrade** 將該次行動改成較弱合法分支。不能將「Break 了 Boss」錯畫成「Casting Interrupt 了 Boss」。
- 對玩家側 Full Chant、普通 MP 部分退款、Last Spell 特殊中斷，一律維持現行規則，不因這個 Boss Break 方案重算支付。
- 如果同一行動同時有合法硬控與 Break，也只能實際壓制一次，不得產生兩次取消。

## 7. 麻痺／冰凍與 Break 的控制重疊

使用者已接受「有機率的麻痺／冰凍，Boss 可逐狀態免疫／抵抗，禁止永久封鎖」的大方向；以下為對 Break C 的交集政策。

1. **普通敵人**：硬控可於成功機率檢驗後限制一次合格行動；普通敵人是否有獨立 BreakGauge 由敵人 Profile 定義，不能偷假定每隻怪都有 Boss Break。
2. **現行單主行動 Boss**：首版推薦 `HARD_CC` 不直接把其唯一公佈的主要行動取消；可以部分抵抗或轉成**卡與 Boss 明示**的弱化效果，**Break 是唯一能取消普通主行動的可預測累積機制**。若目標已 `BREAK_PENDING`，UI 說明強控制無法再次取消該同一 Action。
3. **未來多行動 Boss**：單一 Break 只壓制**一個**合法行動；單一成功硬控至多限制**一個**另外符合條件的動作，且**同一 EnemyAction 不能同時被 Break 和硬控算作取消兩次**。可加整個敵方階段「最多取消一個 Boss 行動」保護，具體額度待 ADR。
4. 新硬控和 Break 必須共用一個**行動壓制決策點**，於 EnemyAction 正式開始之前以一個 Domain Event 確定本次 `CANCEL / DOWNGRADE / NORMAL`；不讓 UI 自己判定哪個狀態勝出。
5. **推薦優先權**：已有效的合法 `CASTING_INTERRUPT`（取消該法術）→ 已鎖定該行動的 `BREAK` → 合格的 `HARD_CC` → 普通能力 Debuff。若前者已取消，後者不得加倍取消、不能用同一次硬控效果自動越權改向下一個行動。數值性 Buff／Debuff 正常依其效果套用不構成新的壓制。
6. Boss 的 `POST_BREAK_RESILIENCE` 是 Break 防連鎖；`HARD_CC` 需自己的共享硬控保護窗，避免在 Break 保護期間改用麻痺無限跳行動。具體是否共用統一「行動免疫窗口」需正式 ADR 決策（**推薦對單主行動 Boss 用同一個跨系統硬控保護 policy**）。

## 8. 目標／時序／資源等必要邊界

| 邊界 | 推薦處理 |
|---|---|
| 敵方 Action 已進入正式開始／攻擊已結算 | Break 和硬控**不回溯取消**；若預告有合法 Reaction 中斷分支則各走相應專有政策 |
| EnemyIntent 已公佈但未開始 | 只允許**已公開的** Break Cancel／Downgrade 分支解析，不暗中改目標 |
| Break 與 Exposed 來自同一張 SP | 先完整結算 SP；Break 成功後建 Exposed；**同張不能吃自己新產生的 Exposed** |
| 同一 SP 多 Hit | 完整結算所有合法 hit；Break 一次；Exposed 利用計一次 |
| 現存 Exposed 又引發 Break | Break 行動壓制正常；Exposed 不疊加也不延長 |
| Exposed 消耗 SP 全 Miss | 保留 Exposed；合法命中但 Barrier 吸完，依本提案**會**消耗 |
| 同一 SP 同時是 Combo Finisher | Combo 仍兩角色真正支付；Exposed 不贈 AP／第二張卡；雙重 bonus 算式另依 ADR |
| Break 降級重大法術 vs Disruption | 依公開分支，Disruption 對該有效施法實例的實際取消優先，不產生雙重取消 |
| Break 觸發時 Boss 已死／全敵死 | 優先維持既有 VICTORY 判定，不對已不存在的 EnemyAction 發生壓制 |
| Boss 尚未宣告任何合格敵方動作 | Break Pending 有明確到期／恢復事件，避免永久卡死 |
| RP/Guard/Protect | Cancel 後不虛開 Reaction；DOWNGRADE 依法提供真正有合法選項的 Reaction Window；**有合法選項絕不可自動 Pass** |
| Time/AP／Overload 新魔法 | 不能讓不花費／不合格 SP 無限 Break；所有費用和 APDebt 在合法 Domain 交易時序結算 |
| i18n／無障礙 | `zh_TW/en`；中文「失衡」「暴露弱點」「詠唱被干擾」、圖示＋文字，不僅靠顏色 |
| Replay／RNG | Break 本身按明示數字確定結算，麻痺可另做種子 proc；UI 動畫不能擅自改事件順序 |

## 9. 驗收案例與測試 Gate（文件設計，不是已跑測試）

| 案例 ID | 情境 | 預期 |
|---|---|---|
| `BK-01` | gauge剩5，R01合法命中破勢6 | HP SP完整處理後Break只觸發1次、gauge到0 |
| `BK-02` | REGULAR預告含 `CANCEL` 分支 | 取消該一次 Action，無傷害、無假反應、敵方階段續行 |
| `BK-03` | MAJOR含合法次級招式 | 按公佈分支降級而非偷偷換招或完全取消 |
| `BK-04` | Boss正在BreakPending再打BreakDamage | 不再產生第二次Break或第二份Exposed |
| `BK-05` | Break後當期無AP追擊 | Exposed保留到至少下一玩家階段結束 |
| `BK-06` | 同一SP建立Exposed並想自用 | 不允許；另一合法SP可用一次 |
| `BK-07` | Exposed利用SP全Miss；或命中後Barrier吸光 | 前者不消耗，後者依此提案消耗且正常Barrier吸收 |
| `BK-08` | Exposed存在時Break；或利用後同卡重建 | 不疊加／不刷新，也不允許同卡消耗後重建 |
| `BK-09` | Break後恢復、下一PlayerPhase連續削破勢 | 恢復量表＋保護窗可見，不能連續壓制主行動 |
| `BK-10` | Break及CastingInterrupt針對同一施法釋放 | 不會被取消兩次、不免費壓制下一招；Exposed仍保留 |
| `BK-11` | 普通Boss/多行動Boss和 HARD_CC 碰撞 | 同一 Action不重複Cancel；依公開抗性與合法順序 |
| `BK-12` | Boss公開Intent後玩家造成 Break | 只走**原先已公開**分支，預覽與實際結果一致 |
| `BK-13` | 雙人 Combo＋Exposed | Combo要兩卡各付費；Exposed一次、傷害算式合法 |
| `BK-14` | Boss死亡、LastSpell退場／KO同時觸發 | 現行勝敗優先；不會非法復活／狀態退場 |
| `BK-15` | 100-seed固定重播與舊fixture | 事件與狀態hash決定性；標註版本差異，不假稱舊fixture原樣適用 |
| `BK-16` | UI 1280×720／1920×1080 | 常態只有Boss HP/Break/Intent，詠唱時多顯示Stability與Ward，Cancel／DownGrade有清楚提示 |

**工程順序建議：**
1. **ADR-BREAK-C-01：Intent 公示時點、分類、Cancel／Downgrade 與 Action 定義**（最優先；否則玩家無法先看到要應對的招式）。
2. **ADR-BREAK-C-02：Exposed 來源、一次性加成及期限**（保持 R01／R07 的 ComboOpportunity 與 CORE_OPEN 分離）。
3. **ADR-BREAK-C-03：BreakGauge 恢復／防連鎖與硬控交互**（避免永久取消）。
4. **ADR-BREAK-C-04：Casting Disruption／Break 同時作用、Buff／Barriers 與 Reaction Window**。
5. 逐一導入合法 Domain→固定seed／Replay→真正可玩 UI／i18n，最後實際 Boss 戰玩家測試。

## 10. 尚需使用者決定的三項平衡取捨

1. **暴露的收益**：首版要不要只增加「下一張合法傷害 SP 的 HP 傷害」，候選+20%，還是某些 SP 能以 Exposed 換 Break／詠唱效果？**為簡化 UX，推薦只做一次增傷，專有高級效果留給卡片例外。**
2. **Break 後一整個 PlayerPhase 的保護**：目前推薦Boss恢復滿 BreakGauge，下一個PlayerPhase不可再 Break，以換取每個 Boss 至少有時能出手；這可能使專破勢卡在保護期的額外 BreakDamage 暫時無用。**建議先實戰驗證，再調整。**
3. **重大蓄力招式 Break 的分支**：B05/B08 應該進入可理解的「蓄力失敗／冷卻」還是改成低威力攻擊？**推薦為每個 Boss Skill 定義，絕不強制全用 B11**。

> **本輪只更新設計文件，不修改程式。** 使用者批准方案 C 的原則；其餘內容仍須明確批准 ADR 後才可改現行玩法。舊 v0.7 提案的「Break 弱化或 fallback，Exposed 需特別條件」並未被暗中寫到 master；v0.8 是下一次實作規劃的提案入口。
