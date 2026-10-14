# 20 — Phase 1–2 實作前待決清查、授權預設與重大驗收點（2026-10-14）

> **範圍：** 以 ChatGPT Library `/docs/combat/00`～`19` 的 P1/P2 合約為清查依據，並比對 GitHub `master` 當前文件。這是經使用者要求「幫我決策」後，新增的**授權設計預設（DELEGATED_DEFAULT）**，不是過往逐項由使用者明示選 A/B/C 的 APPROVED 決議；不變更先前 P1-D、P2-D、P2-S、M-D 的已核准契約。工程預設可以作為 Phase 2 規格驗收案例與 Phase 3 headless engine 的第一版明文規則；**BALANCE_PROVISIONAL** 與 **CORE_CONFIRM** 不得宣告最終核准，更不等於 Godot 測試 PASS。

> **閱讀順序：** `00` → `01` → 既有 P1/P2 相關領域文件 → `16`/`18`/`19` 已核准快照 → **本文件 20 的新增工程邊界與剩餘待確認清單** → `13` 驗收矩陣。Library 的第19檔名是 `19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md`，GitHub 原有第19檔名是 `19_PHASE2_FINAL_APPROVED_M_D18_D31_P2_D10_D16.md`；兩者皆記錄同一批已核准方向。除非特別註明，歷史 OPEN 不得反過來覆寫已核准規則。

## 1. 待決事項分類與裁決權限

| 狀態 | 定義 | 本階段處理 |
|---|---|---|
| `RESOLVED_PREVIOUSLY` | P1/P2/M 後續裁決已處理，但舊文件仍標 OPEN | 改為歷史參考，不重複詢問 |
| `DELEGATED_DEFAULT` | 依使用者本次授權，AI 選定一致且可測試的實作細則 | Phase 2 可驗收，Phase 3 可寫入規則版本；若影響核心玩法須重新審議 |
| `BALANCE_PROVISIONAL` | 候選係數、數值、特定卡牌/敵人資料 | 集中於平衡設定，測試比較後才固定；禁止散落程式碼 |
| `CORE_CONFIRM` | 對故事/勝敗/遊戲體驗有實質重大影響的分歧 | 提供建議與暫定模擬政策；正式遊玩版上線前須明確確認 |
| `CONTENT_DEFERRED` | 卡面、敵人表、稀有度、地圖/位置、商業與 UI 動畫等 | 不阻塞 headless engine 的骨架，需求出現再另開卡片或 ADR |
| `SPECIFIED_NOT_TESTED` | 已寫測試案例，但未實際運行 Godot | 不得標 PASS |

## 2. 已解決但舊文件仍保留 OPEN 的事項

- P1：共享 BaseAP=6、逐次 Player Phase、1/2 RP 基本 Guard/Protect、RP 一般 cap=6 且 Enemy Phase 結束清零；同窗口每角色最多一次已執行 Reaction、多人佇列後確認、失效未執行者免耗。
- P2-D01～D09：百分比線性命中（一般 5–95%）、攻防模型、小幅 seeded 傷害浮動方向、暴擊與敵方自訂元素弱點；不使用舊 d20/Nat1/Nat20 通則。
- P2-D10～D16：可追溯確定性傷害流水線、最終取整、Barrier/Focus Ward 資源分離、狀態逐項定義、HP0 Incapacitated、合法事件完成後判勝敗、seeded replay 已**核准方向**，並非相關所有數值已確定。
- M-D18～M-D31：無 `CurrentAP` 硬 cap、無自然 MP 自動回復、MaxMP 各角色可成長、雙模式 SP 預設同 MP、Full Chant 因 Casting Interrupt 立即部分退 MP 而不退 AP/Overload、每角手牌 cap8 且補至4、每人每 Player Phase 免費換1、不可抽回同一 CardInstance、抽棄牌合法事件與完整事件順序。
- `M-D04` 特別註記：跨多個 Player Phase 償還 APDebt **仍是 PROVISIONAL 試行**；不能因本清查將它悄悄轉成永久最終平衡。

## 3. 授權裁決：規則與結算邊界（DELEGATED_DEFAULT）

### A. Guard／Protect／Reaction（PRE3-R01～R05）

| ID | 決策（須版本化、可測試） | 依據與邊界 |
|---|---|---|
| **PRE3-R01** | 對可 Protect 的**單一主要攻擊目標**，合法 Protect 先改寫實際承受者，再以守護者的 Evasion/DEF/RES 判命中與傷害；不能先對原目標擲命中再搬傷害。同一敵方行動的**第一個成功 Protect** 取得重導向權；後序以相同攻擊轉向為前提的 Protect 不再連鎖，判為失效而跳過不扣費。 | 保留 P1-D12～D14 的真正承受者計算與 Reaction 失效免耗；不允許 A→B→C 無限轉向。 |
| **PRE3-R02** | 一個敵方 **EnemyAction** 原則上開一個可用 Reaction Window；同一動作的單目標多段 hit 屬該窗口，1 次 Guard 作用於該角色在該次動作內所有**符合防禦資格**的 HP hit。符合單目標的多段攻擊若 Protect，整個動作所有依附該目標的 hit 都指向守護者；多目標/AoE、獨立 CastingInstance 直接干擾不可被基本 Protect 攔截。 | 不會因三連擊強制開三次、令 1 RP Guard 僅擋第一擊。個別「多段內有獨立宣告行動」必須在 EnemyAction 資料明示不同 ActionId。 |
| **PRE3-R03** | Protect 後，**命中綁定且標為 `follows_damage_recipient`** 的異常／擊退／命中型干擾，跟隨實際承受者重新驗證；未帶標記的獨立效果照原規格，不能因 Protect 默認全部轉移。對 CastingInstance 直指的 Disruption 不轉向。 | 逐效果明列：status/knockback/mark/interrupt 的跟隨標記；無標記時不得推論可轉。 |
| **PRE3-R04** | 已確認的 Reaction Queue **不預先扣資源或棄卡**；輪到每筆時即時重驗 `actor/target/hand/RP/MP/effect`。若前序效果、角色倒地、資源不足、目標失效導致該筆不能合法執行，發 `ReactionSkipped(reason)`，**不扣費、不棄卡、不占每人已執行配額**；其餘獨立合法隊列照順序執行。 | P1-D16 對已失效後續免耗的必要擴展；不允許隊列中途強制買非法效果。UI 應顯示預估費用與確認前警示。 |
| **PRE3-R05** | 正常 `RP cap=6`，只有明文 SP 才能暫時抬升 cap；新增 RP、AP→RP 一律受**當前有效 cap** 截斷，多餘溢出消失；每個 Enemy Phase 末 RP 仍歸零。 | 延續 M-D08/09，移除舊 `no RP cap` 誤解。 |

### B. HP 傷害／防護／回合事件（PRE3-R06～R09）

| ID | 決策 | 邊界 |
|---|---|---|
| **PRE3-R06** | 固定 trace：合法性與資源 → Protect 重導向 → 命中（若需）→ 暴擊適用性／抽樣（若需）→ SP HP 公式與元素、防禦及抗性 → Guard 固定比例 → **Barrier HP 吸收** → 最後取整／扣 HP → 附帶狀態及 Break/Exposed 的合法時點。Focus Ward **只**參與另一路 Casting Stability 干擾。 | 先 Guard 再 Barrier，可避免無謂消耗護盾；公式非所有技能共用必中、暴擊、元素。順序如未定價的特殊直傷/穿透有例外，須由效果 tag 明文，不能硬套。P2-D08 的暴擊倍率在 HP 傷害階段依適用性作用。 |
| **PRE3-R07** | HP 傷害最後統一以 **`floor(max(0,final_unrounded_damage))`** 取整，**預設最低 HP 傷害為 0**，不暗定保底 1 傷。Barrier 的吸收、持續量使用獨立精度安全的可重播非負運算，不能中間每一修正都取整；真實傷害／ShieldPiercing 由逐效果明文設定。 | `floor`、最低0是本次**工程預設**，非過去逐題核准的平衡數值；如測試偏差需新 ADR 調整。 |
| **PRE3-R08** | 各 Buff/Debuff/DoT/HoT 明列 `tick_trigger`、`expires_at`、`stacks`、`stack_policy`、`priority` 與 `dispel_tags`；同一 tick 點先依 priority，再以 `status_instance_id` 決定穩定排序，逐個結算；**沒有全部狀態共同在每輪扣血的隱形規則**。當前合法事件及其觸發完成，才按既有 P2-D15 進行勝敗檢查。 | 各狀態數值、免疫、堆疊上限仍逐狀態 CONTENT_DEFERRED；不能讓 UI FPS 改變順序。 |
| **PRE3-R09** | Player Phase 開始時，先結算明定於此時到期的 Casting/Status 事件與合法觸發，再檢查結束條件，再重置/計算可行動角色與共享 APDebt，最後補其手牌至4（最多8）。敵方多個宣告行動依其已揭露/資料定義 `action_order` 穩定排序；同優先度按事件建立序號。 | 禁止使用動畫完成時間當 tick；卡片可自行宣告其他施法到期點，特例須可重播。 |

### C. 資源、抽牌、詠唱及失能（PRE3-R10～R15）

| ID | 決策 | 邊界 |
|---|---|---|
| **PRE3-R10** | 數值 AP 折扣先按既有 M-D11 累加，費用不低於0；**明文 SetCost/Override** 在數值減費**之前**生效，之後再套合格減費與卡牌個別最低成本覆寫。折扣若有限次，使用後依 `priority`、授予時間、穩定 `effect_instance_id` 順序消耗；由規則 trace 公開實付 AP。 | 沒有 SetCost 的普通 SP 不受影響；使用該覆寫仍須明列特殊成本，不能偷偷免費。Overload 只在計算最終有效支付成本後借缺額。 |
| **PRE3-R11** | 免費換牌於 PRECHECK 時確認有合法替代牌；通過後暫隔離棄卡、結算 `CardDiscarded` 及其觸發，再執行 `Draw`. 若棄牌觸發在中途耗盡／移走最後一張替代卡，發 `CardDrawFailed(POOL_CHANGED)`，**不回滾已合法結算的棄牌事件，換牌額度視為已使用**；不得抽回暫隔離的原 CardInstance，也不得捏造牌。 | M-D29 的「沒替代卡不消耗次數」適用**PRECHECK 就失敗**情況；本裁決補充開始後牌庫突變的稀有事件。若該卡自身技能另定交易式抽牌例外，需獨立驗證。 |
| **PRE3-R12** | Full Chant 的卡片實例提交後從手牌轉入 Casting Zone；**合法施法完成或中斷後**按普通流程移入原持有者 discard（除非 SP 明示 `exile/return_to_hand` 等替代路徑）。一般 Full Chant 不提供「無代價通用主動取消」按鈕；M-D22 **僅**因明確 `CastingInterrupted` 的干擾才有部分 MP 退款。 | 玩家可另透過有明文代價的特殊效果取消；主動取消、目標失效、已釋放 Spell Counter 均不能偷套 M-D22 refund。 |
| **PRE3-R13** | HP 歸 0 即進 `INCAPACITATED`：不能一般主動行動/Reaction、手牌和 draw/discard **保留但暫時凍結**，不會自動補牌、棄光或復活；一般敵方單體攻擊不再合法指定 HP0 隊友，只有明文 `targets_incapacitated` 的特殊效果可選。普通治療不能自動復活；必須有 `revive` 標記的合法效果。 | 失能發生時一般 Full Chant 尚未釋放效果視為失效並移 discard，**不等於** CastingInterrupt，故不啟用 M-D22 MP 退款。復活時解除失能、HP>0，能否在當前窗口行動仍遵守當時行動資格與資源。 |
| **PRE3-R14** | `EXHAUSTED` 是**戰鬥剩餘期間不得再行動**而非死亡：仍可被 Boss 攻擊、一般治療／Buff 選取、也可由合法隊友 Protect；不能自己 Guard、Protect、Reaction 或出牌，普通治療不能解除 Exhausted。既存 DoT／Barrier／Buff 依原到期規則繼續。 | 若此角色被打至 HP0，HP 狀態另為 INCAPACITATED，兩者不能互相當成復活；Last Spell 使用紀錄仍保留。 |
| **PRE3-R15 (REVISION 2026-10-14)** | **USER_APPROVED**：Last Spell 已提交後仍不得由玩家主動取消，一般 Casting Disruption 維持專用的延遲／削弱流程；**若施法者在釋放前 HP 歸零變成 `INCAPACITATED`，立即強制使 pending `LastSpellInstance` 失效並取消預定釋放**，不得延遲到生效日、不得死後釋放，也不得在同一場戰鬥自動重開。 | 這是 `LAST_SPELL_CASTER_INCAPACITATED` 所造成的 **forced invalidation**，不是玩家 Cancel、不是普通 Counter、也不是 Casting Stability 到零造成的 `CastingInterrupted`。已提交成本及使用次數不退；不啟用 M-D22 一般中斷部分 MP 返還。 |

### D. 其他工程準入規則（PRE3-R16～R18）

| ID | 決策 | 邊界 |
|---|---|---|
| **PRE3-R16** | 每名角色進場牌組**必須恰好 12 張合法 SP**；未滿直接 loadout validation fail，不默默塞空白卡。抽牌不足時只抽到可取得的實例；重複卡上限／稀有度／職能卡比例留給 ContentDeckRules 個別明訂，**不得在 engine 偷設全域2張同名上限**。 | M-D25 手8上限、Start補4及單次免費換牌仍適用；Analyze 和 Last Spell 不在12張內。 |
| **PRE3-R17** | 使用 RP 的 Reaction 視為 `source_enemy_action_id` 的一次窗口；同一動作中用自己的 Guard 即作用於該攻擊的所有符合資格 hit，但**不**自動延續到下一獨立 EnemyAction；只有卡牌有明確持續標籤時才有跨動作防護。 | 防止多段攻擊與多敵方行動測試漏算；Buff Barrier 本身依各自期限獨立。 |
| **PRE3-R18** | 2D 橫向戰場是表現層，Phase 3 **先不加入玩家可操控的自由走位指令**；技能射程／近遠距與目標資格以卡片及 Encounter 的資料 `target_scope/range_tag` 描述。Near/Mid/Far 或格子移動成本屬另行提案，**不是本輪偷改成已核准戰術移動**。 | 不阻塞基本牌卡 Domain Engine；若將來決定導入戰場位置，必須另立重大玩法 ADR。 |

## 4. 數值候選：可直接配置測試，不能視為最終 Canon

| SettingKey | 供首輪 simulation 使用的候選 | 性質／正確解讀 |
|---|---|---|
| `guard_damage_reduction_ratio` | `0.40` | BALANCE_PROVISIONAL；P1-D11 只批准固定比例及順序，沒批准40% |
| `basic_attack_mp_gain` | `2` | BALANCE_PROVISIONAL；每角色每 Player Phase 首次成功普通攻擊才觸發 |
| `base_max_mp_by_archetype` | `{melee:6, hybrid:8, mage:12}` | BALANCE_PROVISIONAL，只有 M-D31 的角色獨立與可成長方向已正式批准 |
| `full_chant_interrupt_mp_refund_ratio` | `0.50` | BALANCE_PROVISIONAL；於中斷成功時立即退款，固定點整數 MP 首輪採 floor，若成本1點則退款0點；AP與Debt不退 |
| `max_ap_debt` | `8` | BALANCE_PROVISIONAL；M-D04 跨多 Player Phase 償還本身亦只是試行 |
| `hp_damage_variance` | `±0.05`（seeded） | BALANCE_PROVISIONAL；P2-D06 只有小幅獨立浮動的方向獲准 |
| `status_stack_cap`/`barrier_lifetime`/`boss_weights`/`crit_base`/`element_multipliers` | **未提供通用固定數值** | 逐狀態、逐敵人、逐 SP 和測試案例決定，不假稱共通 Canon |

**工程限制：** 所有候選放進具有 `ruleset_version` 的 `provisional_balance` 設定檔，測試 log 要列 seed、起始角色/敵人資料、配置版本、命令序列與結果；之後若調整需重新跑回歸，不可用未測候選值替代已批准的遊戲機制。

## 5. 核心重大事項：採推薦基線，但正式可玩版前仍需確認

| ID | 目前建議／暫定模擬政策 | 為什麼保留 CORE_CONFIRM | Phase 3 前是否阻塞 |
|---|---|---|---|
| **CORE-01：全隊與最後敵人同時歸零** | **USER_APPROVED / CLOSED**：同一合法行動及必要事件完成結算後，若敵方全滅則 `BattleOutcome=VICTORY`，**即使我方全員同時 HP0**；視為劇情通關，正常進行勝利紀錄及通關流程。 | 若敵方仍有存活、我方全員失能，才判定 DEFEAT；勝敗只於合法行動結算邊界判定。 | **已確認，不再開放平手選項**。 |
| **CORE-02：Last Spell 施法者詠唱中 HP0** | **USER_APPROVED / CLOSED**：尚未釋放前 HP0，立即 `LastSpellInvalidated(reason=CASTER_INCAPACITATED)` 並取消原定效果；不能死後繼續詠唱，玩家本就不能主動取消。 | 即使先前設定兩回合後生效、隔一回合死亡，仍取消；已付成本與 once-per-battle 仍消耗。 | **已確認，不阻塞**。 |
| **CORE-03：戰場位置可操作性** | **USER_APPROVED / CLOSED**：Phase 3 無可自由走位的玩家操作，不新增移動 AP；**允許使用 2.5D 畫面表現**，僅呈現層效果，不改 domain 回合制邏輯。若已有靜態 range_tag、Near/Mid/Far encounter 定義則照舊。 | 2.5D 不表示玩家有自由走位或即時碰撞；未來可移動位置系統須另立重大 ADR。 | **已確認，不阻塞**。 |
| **CORE-04：Smart／Quick Reaction 的即時公平性** | **USER_APPROVED / CLOSED**：所有有合法選項的 Reaction Window 都**不設任何真實時間強制倒數或自動 Pass**；必須等待玩家明示 `Confirm` 或 `Pass`，Quick 僅縮短動畫與操作，不改判定。 | 沒有合法 Reaction 時可略過空視窗；Smart 視覺呈現可精簡，但不得因等待時長 forfeiture。 | **已確認，不阻塞**。 |

### 可安全延後、不阻塞 Phase 3 引擎骨架

- 卡牌與角色配置：同名 SP 上限、稀有度/職能/專屬比例、每張 SP 的 AP/RP/MP、Caster Stability/Disruption、元素 tag、Crit 資格、Counter 清單、Combo 配方與機會期限。
- 個別狀態：各 DoT/HoT/Buff 疊層、Tick、期限、免疫與驅散，及 Barrier/Focus Ward 的容量與到期。
- Boss：各敵方權重、BreakFallbackAction 卡面、戰鬥元素抗性、Intent UI 的數值閾值和特別劇本。
- 仍需實測的體驗與數字：M-D04 的 APDebt 多回合償還是否過度懲罰、First BasicAttack MP 回復、Guard40%、MaxAPDebt8、FullChant退款50%、LastSpell失衡削弱量。
- 獨立商業/表現系統：抽卡保底、角色 Variant 來源、動畫、英中 i18n、遊戲位置系統的自由走位。

## 6. Phase 2 規格驗收與 Phase 3 實作進入條件

1. 以本檔 PRE3-R01～R18 產生 test case；每個至少正向、拒絕、跨回合或事件時序案例，不得只驗理想路徑。
2. `00`、`01`、`14`、`17` 中歷史「M-D18 next」「P2-D08 OPEN」「免費換牌未決」「無RP cap」等，皆標 HISTORICAL/SUPERSEDED；前面原文可保留追溯，但後續閱讀先看 `18`/`19`/`20`。
3. Domain 不讀 UI 動畫時間決定戰鬥結果；`seed + ruleset_version + initial_state + command_tape` 應重播出同 events 與 final state hash。
4. `BALANCE_PROVISIONAL` 與 `CORE_CONFIRM` 不得冒用使用者逐項核准狀態；`SPECIFIED_NOT_TESTED` 不得自稱 `PASS`。
5. 驗收完成後才升級實作/測試狀態；GitHub push 和 Library save 需要各自實際讀回，不得因文件自述「同步」直接宣告成功。

## 7. 2026-10-14 使用者對 CORE-01～04 的正式確認（高優先級）
以上 CORE-01～04 **全部從 `CORE_CONFIRM` 升級為 `USER_APPROVED / CLOSED`**；本檔其餘歷史的 `DRAW`、死後 Last Spell 繼續結算、或無法確定 2.5D/限時的語句，都已失效。請以最新裁決、`08`、`13` 與 `21_PHASE2_SPEC_ACCEPTANCE_REPORT.md` 為準。原有 `PRE3-R15` 的舊設計不得回退；Last Spell 一般詠唱受敵人干擾的**延遲/削弱而非立即取消**特例仍然存在，唯施法者真正 HP0 屬高優先級強制失效事件。