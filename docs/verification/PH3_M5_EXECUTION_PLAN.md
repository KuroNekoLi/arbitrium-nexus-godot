# Phase 3 — M5 可驗收戰鬥結算引擎實作計畫

> 日期：2026-10-15（Asia/Taipei）  
> 文件狀態：**PLAN_ONLY / NOT IMPLEMENTED / NOT TESTED**。本文件只規劃 M5.1～M5.5，沒有新增任何 M5 程式碼、測試或 CI；不能從檔案存在推論戰鬥已可玩。  
> 正確專案：KuroNekoLi/arbitrium-nexus-godot，`master` 參考 HEAD `da6731a6314ca9681c956eb850b1bbe1bf7d1216`。  
> 前置認證：M4.5 最終官方 Godot 4.7.2 CI [#38665990612](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38665990612) 在相同 HEAD **897/897** named Domain assertions 全通過、四組 legacy headless smoke 成功。M4 狀態為 **DOMAIN VERIFIED — HEADLESS FIXTURE SCOPE**，不等於真實傷害或可操作 Boss 戰鬥。

## 0. 核准範圍與來源優先級

1. **唯一戰鬥權威文件**：`docs/combat/00`～`23`。本計畫**細化** `23_PHASE3_EXECUTION_PLAN.md` `6 的五個子工作包，**不改寫**原正式 Gameplay Rules；也不得引用舊 Flutter Astraea GDD、過時 d20/Nat1/Nat20 或已廢除 Counter-Function。
2. 依序適用：**USER_APPROVED CORE-01～04** → 已核准 P1/P2/M-D/P2-S 決議 → `20` 中 PRE3-R01～R18 **DELEGATED_DEFAULT** → **BALANCE_PROVISIONAL** 的數值及逐卡／逐 Boss 內容設定。
3. 核准重點：命中為「需要擲骰／必中／依條件」混合、一般線性百分比命中 5～95% clamp（除明文特殊0/100%）；PAtk/PDef、MAtk/MDef 分開；CritRate 與 CritDamage 各自屬性，命中後且符合資格才判暴擊；每個敵人個別元素抗性；Protect 先轉移目標再判定命中與防禦；Guard 固定比例在 Barrier 前；FocusWard 保護 Casting Stability 而非 HP。
4. **CORE-01** 同一合法行動＋必要事件整體結算後，敵全滅 **VICTORY 優先**，即使同時我方全員 HP0；敵仍存活且我方全員 Incapacitated 為 DEFEAT。不得顯示 DRAW。
5. **CORE-02** 未釋放 Last Spell 的施法者 HP0 時立即 ActorIncapacitated → LastSpellInvalidated → ScheduledEffectCancelled，不退 AP/MP/Overload/使用權，不可 Revive 後續唱；已釋放完成才 HP0 不可追溯取消。
6. **CORE-03** Phase 3 不新增自由走位 Command；2.5D 只影響 Presentation。**CORE-04** 有合法 Reaction 時必須明示 Confirm/Pass，絕不依秒數、FPS、Quick/Smart 模式自動 Pass。
7. Exposed：`P2-S17～S24` — 一次可利用機會、具正式跨階段期限；成功利用才消耗；同一張 SP 不可立即利用自己建立的 Exposed；持有 Exposed 時新觸發忽略不刷新；可與 Break 共存。
8. Break：`P2-S25～S31` — **整張 SP** 結算後才正式 Break，降級 **下一個合格且未開始**的 Boss Action 為公布的 BreakFallbackAction；不打斷既有 Casting；鎖定中不預存額外 Gauge 損失；已開始的 fallback Action 結束後（成功/反制/中斷皆然）復原 Gauge。
9. Combo：一般雙人連攜需**不同角色**及第二張確實合法提交的 SP；兩張各自付原本 AP/MP，Combo 本身額外 AP=0；沒有免費「連攜卡」、不能同一張 SP 自行 setup/finisher；Full Chant 尚未釋放不能假冒立即命中連攜。
10. 現有使用者認可的 M4 release 判定和 M2/M3 API 優先保留；對不確定的數值／內容 **新增明確版本化測試資料**，不得硬編成 permanent canon。

## 1. 真實程式碼接合點：絕對不另建 BattleState

| 現有已驗證檔案 / API | 實際現況 | M5 接合方式 |
|---|---|---|
| `scripts/domain/m1/combat_model.gd`、`combat_rng.gd` | 唯一 snapshot、事件與 state SHA256；PRNG 是 Park–Miller 48271 v1，使用 draw_index | 所有命中、暴擊及傷害 variance 共用此 PRNG；決定性固定點／有理數精度並記錄 draw_index |
| `scripts/domain/m2/integration/m2_domain_resolver.gd` / economy / card_zone | AP/MP/RP、支付收據、CardInstance 牌區及 Draw 守恆 | M5 **只取已確認的合法 M2 payment/卡牌交易**；不自行再扣一次 AP/MP |
| `scripts/domain/m3/phase/phase_engine.gd` | 開敵方意圖、Reaction/Confirm/Pass，`COMPLETE_ENEMY_ACTION_FIXTURE` 目前不造成 HP 傷害 | M5 實際結算 EnemyAction 時讀取已宣告的 EnemyActionId、Reaction receipt/Guard/Protect，禁止讓 client 任意填 target、傷害、命中與 HP0 |
| `scripts/domain/m3/phase/phase_boundary_resolver.gd` | 已有勝利優先的基本 HP outcome()、M4 到期排程；真實 Status tick 仍 fail-closed | 在同一個權威 Phase/Action Boundary 插入真正到期 Status/HP/Outcome 決議，不改動畫計時器 |
| `scripts/domain/m4/integration/m4_domain_resolver.gd` | Chantless/Full/Last 已合法扣費與排程；`SpellEffectDeferredToM5`／`LastSpellEffectDeferredToM5` 尚未扣 HP | 由 M5 整合 resolver 在**正確 effect-resolve boundary**結算已授權技能效果，絕不能在已完成的 action 外任意追加第二筆傷害 |
| `scripts/domain/m4/casting/casting_invalidation_resolver.gd` | HP0→Incapacitated、普通 Full Casting→Discard、CORE-02 Last Spell 強制取消、Revive 狀態紀錄已驗證 | 真實 HP 傷害歸零即重用它；不新寫另一套「死亡／取消」判定 |
| `scripts/domain/m3/enemy/enemy_action_scheduler.gd` | 依已公開 Intent 排序，尚未具備策略性 Boss AI | M5.3 加入能重播的有限狀態/條件權重 policy，先鎖定並公布意圖再進 M3 原有排程 |
| M4 trusted hit/HP0/Revive boundary | **FIXTURE_ONLY** | M5 使用真正 authoritative effect flow；fixture 留在現役測試中，不公開成玩家任意扣血 API |

### 明確設計的唯一 M5 整合入口

規劃 `scripts/domain/m5/integration/m5_domain_resolver.gd` 為薄封裝（若 existing M4 主入口已有完整委派能力，優先擴充既有位置），遵守 `apply(previous_state, command, config) → accepted / error / state / events / state_hash / event_hash`；不複製 M2 Battle、M3 Phase 或 M4 Casting State。使用同一 event_seq、command_id、ruleset/content/Seed，每筆失敗交易保證 State、Event、RNG、牌區、AP/MP/RP 完全不變。

**關鍵非同步／費用陷阱：** Full Chant 到期事件目前由 M3 Phase Boundary 觸發，不能在 `START_PLAYER_PHASE` 已刷新 AP、補牌或 Outcome 判定後，才另跑一次魔法傷害。合法立即效果與到期效果需在原 reducer 的正確交易邊界完成整體效果；不能用 UI 回調觸發二度提交或雙倍扣費。

## 2. 五個獨立子階段（嚴格依 `23`）

### M5.1 — Hit / Crit / Damage

**目標**：用實際合法效果產出命中及暴擊判定、PAtk/PDef 或 MAtk/MDef 傷害、元素抗性、Guard/Barrier 與**真實 HP 更新**，而不是只算一個不會反映到 BattleState 的數學值。

**本階段工作邊界**

1. 先定 `HitProfile`：`RANDOM_PERCENT`、`GUARANTEED`、`CONDITIONAL`；命中判定只對合格受擊目標，Protect 後先依**承受者**的 Accuracy/Evasion，再用 **5～95%** clamp；有明文的特殊0/100%條件另走合法支線。Miss 不再進入暴擊或 HP Damage，不是 0 傷命中。
2. `DamageProfile` 需具 atk_stat、def_stat、skill_multiplier、flat_bonus、K、element_id、per_target_resistance、crit_eligible、crit_rate/crit_damage、variance、barrier/guard 適用標記。現有 P2-D05 形式 (Attack×SkillMultiplier+FlatBonus)×K/(K+Defense) 保留；數值從 ContentConfig/ProvisionalBalance 讀取。
3. **順序依 PRE3-R06～R07**：合法 target → Protect redirect → Hit →（命中且符合資格才）Crit → HP公式、元素及防禦／抗性 → Guard → Barrier → 最終 floor(max(0,結果)) → ApplyHP → HP0 立即委派既有 M4 incapacitation（同交易）→ 記錄完整 trace。Barriers 的精度／穿透例外必須明文配置，數值浮動 ±5% 只是 provisional。
4. M1 PRNG 承擔每次實際亂數消費，未抽的 Miss/必中效果不得額外暗抽 Crit 或 variance；明示 draw_index / roll / chance 和版本。浮點誤差有風險時可用具版本的整數固定精度實作；此為工程建議，不是調整傷害玩法。
5. 玩家 `BasicAttack`、`Chantless`、`Full` 在可合法結算的時間點調用同一 Damage pipeline。M3 確認後的 EnemyAction 也應從已鎖定的技能定義／Intent 觸發同套 pipeline，不能讓外部 Command 自行填 final_damage。
6. **M5.1 必須能真正扣 HP**。若達0則在同一 action 事件流委派 M4.4；不要因 M5.2 尚未做 Status 而留下「HP0 但角色還 ACTIVE」的非法瞬間。普通 healing、DoT/HoT/全狀態留到 M5.2。
7. 先支援最小可驗證的物理/魔法單體傷害（必要時依已核准多段/Guard 規則加入至少一個多 hit 反例）；未設定的 AOE/特別穿透/元素 combo **fail-closed**，不默默算成單體必中。

**建議新檔（非硬性檔數）**：`m5/integration/m5_domain_resolver.gd`、`m5/damage/hit_resolver.gd`、`m5/damage/critical_resolver.gd`、`m5/damage/damage_pipeline_resolver.gd`、`m5/damage/damage_trace.gd`、`tests/test_m5_damage.gd`、`.github/workflows/godot-m5-1-damage.yml`、`docs/verification/PH3_M5_1_ENGINEERING_NOTE.md`。現有 M3/M4 接合文件按實際 API 決定最小必要修改。

**Gate / 必要案例**：`P2-D01～D11`、`P2-D10-001`、`P2-D11-001`、`P1-PRT`、`P1-GUARD`、`RNG-001`；具名新增 M51-HIT/M51-CRIT/M51-DMG/M51-MISS/M51-ATOMIC。涵蓋 0/100%、5/95% clamp、同 Seed roll、一個 Miss 不抽無關 RNG、Crit 不保證 Hit、魔法不預設皆可 Crit、各敵人元素抗性、不同角色防禦後 Protect、Guard→Barrier、0 傷不保底1、多 hit 不多扣成本、真實扣 HP 與立即 CORE-02、支付一次、拒絕零狀態/零 RNG 變更。

**允許的完成宣告**：`M5.1 DAMAGE DOMAIN VERIFIED`，不是全 Status/Boss/Outcome 完成。

### M5.2 — Status / Targeting / Barrier / HP Lifecycle

**目標**：使 Phase Boundary 可處理**真正版本化 StatusInstance**，而非之前的假 tick hook；把 Buffer/Barrier/DoT/HoT、失能與一般治療銜接到 M5.1 已驗證的 HP writer。

1. Status data 採 `status_instance_id, source_actor_id, target_actor_id, status_id, stacks, stack_policy, stack_cap, tick_trigger, duration/expires_at, priority, dispel_tags, definition_version`。各種狀態的生效時間與免疫需**明文逐個設定**，不可讓全局 DoT 預設每回合扣血。
2. Tick 排序：先 priority 再 status_instance_id；同一 action 觸發鏈在合法 event boundary 完成，避免遞迴回饋造成無限事件（max events/source id/dedupe key 設版本化上限）。
3. HP Barrier 只吸收 HP damage（數量和消耗時點可被 trace）；Focus Ward 只吸收 Casting Disruption，兩者不互相代用。Barrier 生效前 Guard 已以承受者防禦與合法 hit 做減傷。
4. Buff/Debuff、DoT、HoT、dispel 遵守各自 stack、duration、source、expire，分別驗證 refresh/replace/stack/reject。在 HP0 tick 時**立即**使用 M4 invalidator，並確保排程 Last Spell 被取消、非干擾不退 MP。
5. `Incapacitated`：普通治療不能自動 revive；只有明文带 `revive` 的合法效果能恢復 HP與正確狀態；Frozen Hand 不自動棄牌。`Exhausted`：允許被打/治療/Protect，但戰鬥結束前不能再主動行動，Revive 亦不可洗掉已記錄的 exhausted_lifetime。
6. Protect 對 `follows_damage_recipient` 的 on-hit status/Disruption 必須跟著實際受擊者重新檢查；直接 `casting_id` 的效果不轉向。AOE/多目標按效果實際 eligible recipient 處理，不得普通 Protect 一口氣攔整場 AOE。

**建議新檔**：`m5/status/status_resolver.gd`、`m5/status/status_tick_resolver.gd`、`m5/status/hp_barrier_resolver.gd`、`m5/status/hp_lifecycle_bridge.gd`、`tests/test_m5_status.gd`、`.github/workflows/godot-m5-2-status.yml`、`docs/verification/PH3_M5_2_ENGINEERING_NOTE.md`。若 M4 invalidator 足以擔任 HP lifecycle 不新增重複 resolver。

**Gate / 必要案例**：`P2-D12-001`、`P2-D13-001`、`P2-D14-001`、`PRE3-R03/R06/R07/R08/R09/R13/R14/R15`。具名 M52-STATUS/M52-TICK/M52-BARRIER/M52-REVIVE。至少兩種具有不同 stack/tick 規則的狀態；DoT 同一合法事件使 Last Spell caster HP0 的實際強制失效；普通治療不得 revive；Exhausted 仍可承傷/治療但不可出牌；失能手牌保留且 frozen；同一 Seed 不因 Godot frame order 改變。

### M5.3 — Boss FSM / Intent / Break / Exposed / Combo

**目標**：將已存在「敵方宣告清單」補成**真正可重播 Boss 行動選擇及執行**，並使整張 SP 的 Break/Exposed/Combo 不可早於效果完成。

1. Boss policy 第一版僅 `FSM + condition + stable priority/seeded tie-break`，不做 ML。先根據合法可用技能與狀態**提交行動和目標**，顯示 protectability、on-hit/direct disruption、必要範圍/合法變招條件；再交給既有 M3 EnemyAction scheduler 公告。公開後玩家 Confirm Reaction，Boss 不可暗改成另一攻擊規避 Protect。
2. Break Gauge 和 Casting Stability 雙獨立欄位；同張多 hit SP 中 Gauge=0 → `BreakPending`，但直到整張合法 SP 結束才 `BreakTriggered`。新的 Break 鎖定並安排**下一個合格未開始的 EnemyAction**替換成明文 BreakFallbackAction；不得 retroactively 改已公開或開始的 action。無合格動作時保留到下一次；fallback 已開始就依 S31 在行動結束清除，即使被合法 Counter。
3. Exposed 有單一獨立 Opportunity 和期限，不疊加；同一張 SP 即使後段 hit 也不可利用自己剛建立的 Exposed；目標已有 Exposed 時新建立 ignore，不重設期限；合格另一張 SP **成功利用**才消耗，Miss 不消耗；Break 與 Exposed 可共存。
4. Combo 需要不同兩名角色、明文 tag 和第二個合法真正付費/出牌的 CardInstance。提供可查詢的 ComboOpportunity；finisher 可由玩家選「普通」或「Combo」，**不自動**。兩張技能各只付一次成本，額外 Combo AP=0，沒有免費額外抽牌；不同角色支援聯動、目前 Concentrating 不可自己突然提交 finisher。
5. Full Chant 的 CastingCombo / Last Spell 共鳴：只可在既有 CastingInstance 上由**另一個合法已付費效果**增益，不把未釋放 Spell 視為已命中的瞬發設置；共鳴數字／配方為 ContentConfig，無配置時 fail-closed。
6. 需單獨核對 `P2-S15/S16` Spell Counter：它不同於 Casting Interrupt，必須在「已釋放、效果尚未作用」且有**合法 Reaction Window**時，透過有資格的 Reaction SP 取消符合條件的效果；不得無成本自動 counter 或暗賦予 Break/Exposed。若尚無可核准的具體 Counter 卡牌及窗口，必須具名標 `BLOCKED_CONTENT` 並維持可關閉 hook，不可默默標全功能 PASS。
7. `P2-S02～S12` Analyze/Enemy Intel 是已核准且與 Boss 公開意圖相關的獨立領域能力，若本次完整戰鬥 fixture 不測，必須於 RTM 寫明 `DEFERRED_CONTENT / NOT_VERIFIED`，不得宣稱已完成 Analyze。

**建議新檔**：`m5/boss/boss_ai_policy.gd`、`m5/boss/boss_action_resolver.gd`、`m5/break/break_resolver.gd`、`m5/exposed/exposed_resolver.gd`、`m5/combo/combo_opportunity_resolver.gd`、`m5/combo/combo_execution_resolver.gd`、`tests/test_m5_boss_break.gd`、`tests/test_m5_exposed_combo.gd`、`.github/workflows/godot-m5-3-boss-combo.yml`、`docs/verification/PH3_M5_3_ENGINEERING_NOTE.md`。單次任務只做本工作包，該子階段可在內部先測 Boss→Break→Exposed→Combo，但不得宣稱整個 M5 提前完成。

**Gate / 必要案例**：`BREAK-001`、`COMBO-001～004`、`P2-S17～S31`、`P1-RXN`、`P2-S15/S16`。具名 M53-BOSS/M53-BREAK/M53-EXP/M53-COMBO。多 hit 中途 Gauge0 不能立刻觸發 Break；合法 fallback 只一次，S31 清除並 reset；已開始 Casting 不受 Break retroactive 影響；Exposed Miss 不消耗、同張不得自觸即用、期限正確、不能 refresh；第二張卡付款一次、同人不可冒充雙人 Combo；Boss 應選定前先公開。

### M5.4 — Final Outcome / CORE-01

**目標**：統一 Action／Status Tick／Casting Effect 的合法 outcome boundary，不讓同一張合法多段 SP 被提前截斷，不允許 DRAW；整合 M4 CORE-02。

1. 結算中的 Action/Effect queue 按 source_action_id、effect_id、phase/casting/hit index 有序、有限界；必要事件先完成，才由唯一 Outcome authority 檢查。
2. 終局判定優先級：敵全滅 ⇒ **VICTORY**（即便同一次 Action 全隊 HP0）；否則如果敵仍存活、我方全員 Incapacitated ⇒ **DEFEAT**；否則 ONGOING。Enemy HP0 與 Ally HP0 的即時局部轉換照生命週期處理，**不要把「終局檢查延後」誤當「Last Spell HP0 失效延後」**。
3. 若已合法釋放的 Last Spell/多 hit 效果在單次行動後續造成雙方 HP0，依約完成合格效果後 VICTORY；若 Last Spell 還在 Casting 且 caster 先 HP0，先立即 CANCEL，不可用待效補尾刀。
4. 立即勝敗進入終止狀態後，不可再接受 EndPhase/Spell/Reaction 或再排新的實際傷害。等待中隊列有已合法承諾效果時按已核准完成邊界處理，禁止 UI 一時閃白就直接宣告敗北。
5. `EXHAUSTED` 全員 HP>0 卻不能主動行動時，是否判定戰敗仍可能缺精確核准；不得偷當成所有人 Incapacitated，標註 `CORE_RULE_EDGE_PENDING` 並設需授權的實際案例，避免誤編 DEFEAT/ONGOING 並宣稱全部已解。

**建議新檔**：優先擴充現有 `m3/phase/phase_boundary_resolver.gd` 和真正處理 HP Action 的 `m5/integration`，只有現有邏輯無法避免重複才建立 `m5/outcome/outcome_resolver.gd`；另有 `tests/test_m5_outcome.gd`、`.github/workflows/godot-m5-4-outcome.yml`、`docs/verification/PH3_M5_4_ENGINEERING_NOTE.md`。

**Gate / 必要案例**：`P2-OUT-01/02/03`、`P2-D15-001`、`CORE-01/02`、`PRE3-R09/R15`。具名 M54-OUT/M54-TICK/M54-LAST。最後 Boss/全隊同次 HP0 → VICTORY；全隊 HP0 但 Boss 存活 → DEFEAT；單張多 hit 中途敵倒仍不漏合法副作用；Last 未釋放已取消不能「死後補刀」；已釋放後 HP0 不回溯；拒絕終局新命令且不耗 RNG。

### M5.5 — Full Battle Fixture / Seeded Replay / Regression

**目標**：在 Godot 4.7.2 **Headless 真正跑完一場具有合法傷害與勝負結果的三人對 Boss 戰鬥**，而不只是 M4 那種永不扣 Boss HP 的 fixture。

1. 建立版本化 `M5_BATTLE_FIXTURE`：3 人×每人恰12張 SP CardInstances、不同職責技能、獨立 MP、共享 AP/RP、Boss HP/屬性/元素抗性/Action/Intent/BreakFallback、至少一種 Barrier + 一個不同 stack/tick 的狀態、Exposed、兩人 Combo、Chantless/Full、Last Spell。全部例用 `FIXTURE_ONLY / BALANCE_PROVISIONAL`，不是已核准可販售的卡牌與 Boss 數值。
2. 從初始化 → PlayerPhase → EnemyAction Intent → 合法 Reaction window 的 Queue/Confirm/Pass → 真正 Hit/Crit/Guard/Protect/Barrier/HP → Casting 到期 → Status tick → Boss BreakFallback → Exposed/Combo → 明確 VICTORY 或 DEFEAT，以**真實 reducer** 自己逐筆更新狀態；Tape 由實際 accepted commands 記錄，禁止手寫結果狀態替代真實結算。
3. Replay 同 Seed + 初始 State + 完整 Content/Rules/PRNG 版本 + 完整 Tape 產生**完全相同** per-step receipts、event hash、final state hash、outcome；不同 FPS / 2D/2.5D mock / Smart-Quick-AlwaysAsk 對 Domain 不能有作用。
4. **至少 100 個固定 Seeds** 的不同合法對局／屬性壓力回歸：0 命令例外、不可負 AP/MP/RP/HP、無重複卡牌/亂數非法消費、無無限 trigger/事件列、無 Last 死後釋放、無 Break/Exposed 跨 battle 洩漏、無 Reaction 超時、無「已勝利還可扣血」。此為**工程穩定性**，不是已完成遊戲平衡。
5. 輸出各 seed 的 seed/content version、合法/拒絕命令數、回合/事件數、第一次 HP0、Boss fallback 次數、終局、狀態/事件 Hash、耗時/例外；若某個固定 Seed 合法進入玩家決策但無輸入，不准偷偷自動 Pass。Driver 應採可重播有策略的 fixture policy，與 Domain 本體分層。
6. 狀態只在完整 M5.1～M5.5+舊 897 回歸、100 seed suite 全通過才標 `M5 DOMAIN VERIFIED — HEADLESS BATTLE SCOPE`。若缺某個已核准但無 content 的功能，不可虛稱「全部已實作」，需列 SPEC_GAP / DEFERRED_CONTENT 的明確適用範圍。

**原始交付清單（已完成）**：`tests/fixtures/m5_full_battle_fixture.gd`、`tests/test_m5_integration.gd`、`tests/test_m5_replay.gd`、`tests/test_m5_100_seeds.gd`、`.github/workflows/godot-m5-5-acceptance.yml`。完成後的 acceptance receipt 與 handoff 已清除；目前測試入口見 `docs/ci/CI_TEST_MATRIX.md`。

**Gate / 必要案例**：`P2-D16-001`、`P2-REPLAY-01`、`P2-VIS-01/02`、`RNG-001`、`P2-OUT-01～03`、`BREAK-001`、`COMBO-001～004`，當期所有 M51～M55 cases，**全部前置 M1～M4.5 897 cases**，4 組 legacy scripts。不得只重跑各子階段而沒有完整 Boss 戰鬥與 deterministic Replay。

## 3. 關鍵事件序與 trace contract（設計，不是實測）

### 玩家立即/延遲法術（應結算效果的位置）

合法 Payment/Hand Zone（M2）→ 命令提交（M4）→ 
- Chantless：立即 M5 effect resolution → 命中/暴擊/傷害與 HP → OnHit/OnDamage/狀態（若 M5.2 已支援）→ BreakPending/Exposed/Combo 全卡 boundary（M5.3）→ Outcome（M5.4）。
- Full：Casting Zone → Concentration → 到期/合法 release（M3/M4）→ **同一 Phase Boundary 內先執行 M5 effect** → Status due/ticks and necessary event chain → Outcome → M2 AP/RP renewal → draw-to-four。失敗取消後不允許滯後損傷，不能二次扣費。
- Last Spell：成功釋放後完成合法 effect resolution + Exhausted，不重付 cost；若 release 前 HP0 ⇒ M4.4 即時 Invalidated，原定到期不能計傷。

### 已宣告敵方行動

Committed & publicly declared Intent → M3 optional Reaction Window（若有合法可用反應）→ 玩家明示 Queue/Confirm/Pass → M3 實際已執行 Guard/Protect/Reaction receipt → 若 action 未被合法取消：先受擊者重導向，M5 Hit/Crit/HP/OnHit 與 M4 Casting Disruption（依 effect tag）→ action end / Status / BreakFallback advancement → Outcome。Boss action 不能在 Reaction 後換成不同未公開技能。

### 最小 trace schema（概念欄位，具體以現有事件封裝為準）

`{action_id, effect_id, source_card_instance_id, actor_id, target_before_protect, actual_recipient_id, is_hit_eligible, hit_chance, hit_roll_index?, hit_result, crit_eligible, crit_roll_index?, crit_result, attack_stat, defense_stat, element_id, resistance, variance_roll_index?, guard_applied, barrier_absorbed, damage_unrounded, final_hp_damage, hp_before, hp_after, incapacitation_event_id?, break_pending?, exposed_consumed?, outcome_boundary_id, ruleset_version, content_version, config_hash}`

若命令本來不合法，應回具名拒絕理由與原狀態 Hash，不記假命中事件或消耗 PRNG。實際事件資料不應有非決定性時間戳或 Godot Scene Node 引用。

## 4. Test Matrix / Gate 制度（每階段只開當期）

| 階段 | 具名測試主軸 | 回歸 |
|---|---|---|
| M5.1 | Hit clamp/redirect/crit/element/variance/Guard/Barrier/真 HP/HP0/拒絕 atomic | 897/897 M1～M4.5 + M5.1 |
| M5.2 | Status tick 順序/stack/Barrier/Revive/DoT→CORE-02/Exhausted | M1～M5.1 全部 |
| M5.3 | Intent committed、Break whole-SP、fallback one-shot、Exposed use/expiry、Combo second card | M1～M5.2 全部 |
| M5.4 | CORE-01 VICTORY優先、DEFEAT、多段事件完整、終局不可再動 | M1～M5.3 全部 |
| M5.5 | 真實 Boss 連續戰鬥 + 100 seeds + Replay + predecessor | M1～M5.4 全部、4 legacy |

所有 GitHub Actions 必須：
- 使用**實際 Repo 已驗證的官方 Godot 4.7.2** 下載 SHA512 驗證、project import/CLI runner；保持失敗 nonzero exit 和上傳 raw logs/artifacts。
- 先生成 Requirement-ID→test-name 的正例/反例/邊界/Replay 矩陣，再補 production code；不能因 assertions 沒寫到就宣告功能完成。
- 同一 failing test group 限 **第一次執行＋最多兩輪修復重測**；第三次還紅燈立刻停下，保存 log，不改核准玩法、不刪 assertions 換綠燈。
- 日誌列 `code_sha`、`source_spec_sha`、`ruleset_version`、`content_version`、`balance_provisional_version`、`Godot_version`、`seed`、`PRNG_algorithm`、`command_tape_hash`、`initial/event/final_state_hash`、cases executed/passed/failed/skipped、Godot exit code。
- 每個子階段都提交一份獨立 Engineering Note、變動檔案、測試原始 log、Commit SHA、已知限制、下一階段入口；Push 後確認 latest master HEAD 並於**最終文件提交後**再次 CI。
- 只有當期 CI+完整前置回歸實際 PASS 才可宣告該 **子階段** VERIFIED。M5.1～M5.4 先後驗收並不等同整個 M5 verified。

## 5. 不得偷偷變成最終 Canon 的數值與待定邊界

| 類別 | 已核准固定契約 | 可供測試、尚非 Canon 的參數或缺口 |
|---|---|---|
| 命中 | 一般百分比 5～95%、線性 Accuracy-Evasion；明文特殊 0/100% | BaseHit、k、各卡 hit_mode |
| HP 公式 | PAtk/PDef、MAtk/MDef 分開、P2-D05 結構、命中後判 Crit | K、技能倍率、元素抗性個別數值、CritDamage、variance（±5% 候選） |
| HP 防護 | 防禦/元素 → Guard → Barrier、Focus Ward 不吸HP | Guard 40% 候選、盾精度/層數、穿透例外 |
| 傷害取整 | PRE3-R07 工程預設最終 floor、最小0 | 例外直傷與最低 chip；要修改需新 ADR |
| Status | 各自 stack、priority、tick/expiry/dispel | 實際燃燒/毒/治癒/免疫/多層數值與具體列表 |
| Break/Exposed | Break 整卡觸發，降級下一可開始 action；Exposed 一次機會與正式期限 | Boss Gauge、fallback 動作資料、觸發條件、各卡利用 bonus |
| Combo | 雙人不同角色＋兩張真正 paid SP，額外 AP=0 | 觸發 tags、增益數值/Resonance 上限、是否支持反應式專屬 Combo |
| Outcome | CORE-01 敵全滅 VICTORY 最高、CORE-02 待效 Last 死亡強制 cancel | 全員 EXHAUSTED 但未 HP0 的 no-action 終局政策，不能擅自決定 |
| 額外已核准功能 | P2-S15/S16 Spell Counter、P2-S02～S12 Analyze/Enemy Intel | 合格 Counter 卡、Reaction Window 觸發細節、Analyze 各情報 content；若未驗證須明列限制 |

避免以下高危錯誤：把 M3 的 `COMPLETE_ENEMY_ACTION_FIXTURE` 當真命中、把 M4 的 `SpellEffectDeferredToM5` 當真傷害、重複扣 AP/MP 或 MP 中斷退款、Protect 後用原目標防禦、Guard/Barrier/FocusWard 混為一層、Break 在卡牌中途生效、Exposed 同卡建立即利用、Combo 第二張免費發動、HP0 待釋放 Last Spell 死後補刀、相互全滅輸出 DRAW、允許因動畫 FPS/120秒導致 Reaction auto-Pass。

## 6. Agent 執行協議與交接入口

此計畫是歷史里程碑紀錄，不再是施工入口。新工作依根目錄 `AGENTS.md`、`docs/combat/README.md`、現行工程契約與缺口表執行，以實際 HEAD 和 Actions 為準；未解決的 BLOCKED_CONTENT／UNRESOLVED_CORE_EDGE 仍依現行待實作與待驗證清單處理。
