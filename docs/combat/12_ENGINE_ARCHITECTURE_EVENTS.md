# 12 — Godot 引擎架構、資料模型、事件佇列與可重播性

> **2026-10-14 LIBRARY Phase 2 最新補充（現行 SoT）**：請優先閱讀 [`19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md`](19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md) 與 [`18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md`](18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md)。M-D18～M-D31 已核准；P2-D10～D16 的**設計方向**已整體核准，數值／部分結算邊界仍 TBD。較早段落的「P2-D08 未決」「換牌僅提案」「手牌上限 TBD」「完整詠唱較貴 MP」等屬歷史文字，與 19 衝突時以 19 為準。**僅 Library 更新，未同步 GitHub；尚無 Godot 執行／CI PASS 證據。**


## 1. 核心架構

Godot 4 / GDScript 推薦**headless deterministic domain engine**：輸入 `BattleState + PlayerCommand + PRNGState`，輸出 `NewBattleState + DomainEvents + ErrorReason`。視覺層只消費事件與狀態生成動畫/UI；不可在 Tween、Animation callback、卡牌UI按鈕內自行扣HP/AP/MP。Godot Scene 只作 Presenter/Controller，戰鬥規則由純model/service 驅動。

```text
BattleController(Godot Scene/UI)
  → CommandValidation / BattleReducer
       → ActionEconomy, Deck, Casting, Disruption, BossAI,
         Reaction, Combo, LastSpell, Damage, Status
       → EventQueue + SeededRng
       → BattleState snapshot + CombatEvent[]
  → BattlePresenter / HUD / Animation (read-only state)
```

## 2. 建議資料實體（字段契約）

- `BattleConfig`: rules_version, starting_ap, rp_conversion_policy, hand_target, deck_size, formulas/config, RNG algorithm version。
- `BattleState`: battle_id, round, phase, team_ap, team_rp, player_units, enemy_units, casting_instances, combo_opportunities, statuses, active_intents, event_seq, rng_state, outcome。
- `Combatant`: unit_id, character_id, variant_id, hp/max_hp, mp/max_mp, attributes, active_statuses, draw_pile, hand, discard_pile, casting_zone, last_spell_used, action_flags, life_state。
- `CardDefinition`: card_id, rarity, tags, eligibility_rule, ap_cost_profile, mp_cost_profile, target_rule, casting_profiles, reaction_trigger, effects[]。
- `CardInstance`: id, owner_unit_id, card_id, zone, modifiers。
- `CastingInstance`: id, caster_id, source_card, started_round, resolves_at, status, stability, focus_ward, target_policy, last_spell_metadata。
- `ComboOpportunity`: id, originating_actor, action, target, tags, eligible_partners, eligible_card_tags, expires_at, consumed。
- `EnemyIntent`: enemy/skill/target/execute_at/stability/visible_info/branch_commitment。
- `CombatEvent`: seq, round, phase, type, actor, targets, deltas, source_action, rng_draw_index, post_state_hash。

不要依UI顯示名稱辨識角色或卡牌；全部ID穩定。所有顯示字串交i18n key管理（繁中/英文）。

## 3. 命令與交易

`Command {command_id, actor_id, action_kind, card_instance_id?, mode?, target_ids[], combo_confirmation?, reaction_window_id?}`；處理要原子性。先驗證合法性，合法才扣費+移區+效果；拒絕時回 `ErrorCode(INSUFFICIENT_AP|INSUFFICIENT_MP|NOT_IN_HAND|INVALID_PHASE|ACTOR_CONCENTRATING|EXHAUSTED|INVALID_TARGET|REACTION_WINDOW_CLOSED|COMBO_EXPIRED)`，且state hash不變。

## 4. Seeded RNG 與重播

RNG演算法固定版本（不能依Godot平台內建隨機版本默認保證跨平台一致），所有骰子/洗牌只透過共享PRNG實例抽，連RNG draw index都記錄。Replay包含 `config_version, content_version, initial_decks, character_variants, boss_ai_spec, seed, action_commands[]`，可重新演算每事件結果並hash比對；更新邏輯時若舊replay不再相容須明示版本遷移。

## 5. 事件循環安全性

觸發器不直接遞迴呼叫自身：enqueue到有界事件佇列，事件有 `source_effect_id`, `generation_depth`, `dedupe_key`, `max_events_per_command`（上限值 TBD）；超限回可診斷Error而不是卡死。處理命令／事件要檢查戰鬥是否已終止；動畫可播放，但不可超前施加事件。

## 6. 關鍵工程守則

- UI提供 `PreviewAction` 只讀合法成本／傷害/干擾可見範圍，用**同一套** domain resolver 純預覽或dry-run，避免計算不一致。
- 任何多段攻擊／Combo不可多扣一次資源。
- Boss意圖應有固定提交時間，避免AI在Reaction之後任意重骰。
- 打斷Spell從event queue中取消未執行effect，不只是改UI旗標。
- 快照不可持有Godot Node/Scene引用；只存穩定ID與數值。
- 在使用者決策尚未完成前，可把公式放入 `provisional_balancing.json`，且測試報告加水印「非Canon」。

## 7. 範例資料（示意）

```json
{"rules_version":"0.8-draft","seed":20261014,"party_ap":6,"rp_conversion_policy":"all_remaining_ap_to_rp_no_extra_cap","hand_target":4,"characters":[{"id":"yura","variant":"academy","deck_size":12,"mp":6}],"boss":{"id":"arbiter_core","hp":600},"note":"all numerical values except chosen deck/AP baseline are prototype inputs"}
```


---

## 8. Phase 1 Headless Engine 增補契約（ENGINEERING PROPOSAL，遵守 APPROVED 行為）

### 8.1 建議新資料結構

```text
BattleState:
  team_ap: int               # player phase <= initial6
  team_rp: int               # 由當回合剩餘AP轉成; 不跨敵方階段
  actor_basic_attack_mp_restored: Map<UnitId,bool>
  active_reaction_window?: ReactionWindowState
ReactionWindowState:
  window_id: WindowId
  enemy_action_id: ActionId
  phase: DRAFTING | CONFIRMED | RESOLVING | CLOSED
  queued_reactions: Array<ReactionIntent>
  executed_actor_ids: Set<UnitId>
  visible_enemy_intent_snapshot: IntentSnapshot
ReactionIntent:
  intent_id, actor_id, kind: BASIC_GUARD|BASIC_PROTECT|SP
  card_instance_id?: CardInstanceId
  intended_protected_ally?: UnitId
  target_id?: StableTargetId
  trigger_dependency: EnemyActionId | CastingId | IndependentEffectId
  rp_cost, mp_cost, selected_order, eligibility_snapshot
ReactionOutcome:
  result: EXECUTED | SKIPPED_INVALIDATED | REJECTED
  reason_code, resource_deltas, card_zone_deltas, event_sequence
```

以上型別與欄位名稱供實作協作，使用者核准的是**可觀察規則**；序列化格式可調整但須一致、可重播。`eligible_actor_count` 不等同隊伍共同可用 Reaction 次數；角色最多一次，且 RP池共同扣減。

### 8.2 命令協定（建議）

`OpenReactionWindow(enemy_action_id)`、`DraftReaction(window_id, actor_id, kind, target, card_instance_id?)`、`ReorderDraft(window_id, ids[])`、`RemoveDraft(...)`、`ConfirmReactionQueue(window_id, expected_state_version)`、`SkipReactionWindow(...)`、`ResolveEnemyAction(...)`。Draft為零狀態消耗；Confirm再整體校驗；實際每個子Intent按順序重新校驗並執行。使用 `window_id` 與 `command_id` idempotency key 防連點扣重。若確認資料版本過舊，UI須重新預覽，不可偷偷用不同目標提交。

### 8.3 執行器參考偽碼

```python
# 純伪码，非正式GDScript實作

def resolve_reaction_queue(state, window):
    assert window.phase == 'CONFIRMED'
    seen_executed = set()
    for intent in window.queue:              # 保留玩家指定順序
        state = current_authoritative_state()
        legal = validate_reaction(intent, state, window)
        if legal.is_trigger_or_target_invalidated_by_prior_effect:
            emit('ReactionSkipped', intent=intent, reason='TRIGGER_OR_TARGET_GONE')
            # 不扣RP/MP、不移卡、不加入seen_executed
            continue
        if not legal.ok:
            emit('ReactionResolutionError', intent=intent, reason=legal.reason)
            # 本來就缺RP/MP的方案應在Confirm前拒絕；此處不能默默無息略過
            continue_or_abort_according_to_explicit_engine_policy() # TBD for non-D16 failures
        atomic_transaction(lambda: [
            pay_cost_once(intent),
            transfer_card_if_SP(intent),
            apply_reaction_effect(intent),
            mark_actor_executed_in_window(intent.actor_id),
            emit('ReactionExecuted', intent=intent),
        ])
    close_window_idempotently()
```

`ReactionSkipped` 本身是有意義的 log，仍有序列號及重播價值，但不是 `ReactionExecuted`。防止因 `PreviewAction` 假扣資源而觸發手牌遺失。工程上對超時、斷線、初始違法排隊、資源在隊列執行中被其他效果改變時的失敗政策仍需明確規範；此部分不以本偽碼的 placeholder 視為已核准。

### 8.4 Attack / Cast 依賴與防禦結算事件（建議）

```text
EnemyActionCommitted
  -> ReactionWindowOpened
  -> ReactionQueueDrafted (ui state only)
  -> ReactionQueueConfirmed
  -> ReactionExecuted|ReactionSkipped (ordered)
  -> EnemyActionStillValid?               # 被Interrupt取消則不再執行該攻擊
  -> AttackRecipientRedirected?            # Protect，單體且可守護
  -> HitResolution?                        # 命中與轉向先後尚未核准
  -> BaseDamageWithRecipientDefenses
  -> GuardDamageReduction?                 # 比例 TBD
  -> BarrierAbsorb?                        # 與Guard排序 TBD
  -> ApplyHPDamage
  -> OnHitCastingDisruption?               # 隨攻擊承受者改指
  -> DirectCastingInstanceDisruption?      # 不受Protect轉向
  -> WindowClosed
```

事件名稱、`?`部分代表要與後續ADR結合，**不能從圖上的先後推定未核准的命中、Barrier、狀態、特殊護盾精確時序**。同一命令的重入、動畫重播不能重複執行事件。每筆事件包含 `ruleset_version`, `decision_refs`, `window_id`, `intent_id`, `recipient_before/after`, `paid_rp/mp`, `card_zone_change`, `skip_reason`, `post_state_hash`，支援Replay比較。

### 8.5 核心不變量與監控

- `team_rp` 在敵方階段結束必為0；多窗口共用RP餘額，不能個別重設。
- 每個 `(window_id, actor_id)` 的 `ReactionExecuted` 次數≤1；其他角色可以有自己的有效事件。
- D16 跳過前後 `rp`, `mp`, `card_zone`, `executed_actor_ids` 對該Intent的變化全為0。
- 同時多次點擊 Confirm 只接受一次，其餘回應 idempotent 或已關閉窗口理由。
- UI選Smart/Quick/AlwaysAsk不改同一提交命令的核心推演事件、費用與傷害。
- Determinism: 相同 ruleset/content版本、seed、完整命令序列與反應排序應產生相同事件 hash。

### 8.6 Migration note

原先 `BattleConfig.max_rp=2` **不可保留作為實際截斷**；可改為 `rp_from_remaining_ap=true`, `rp_expiry=ENEMY_PHASE_END`。若既有 `max_rp` 欄位仍須兼容舊Replay，必須明示舊規則版本轉換並拒絕拿舊版 seed 當新版規則的平衡回歸測試。新的 `guard_damage_reduction` 可先用 `provisional` 參數40%，但測試輸出必標示「PROVISIONAL」，不是產品預設最終值。

## 8. Phase 2 事件可重播／資源／換牌（APPROVED DIRECTION）

P2-D16：固定 RNG seed、command tape、規格版本、完整 domain event 日誌可重播；相同輸入必產生相同事件序列與狀態雜湊。P2-D10：傷害日誌需能分辨 Hit/Crit/元素/防禦/Guard/Barrier/HP/Break/Exposed，各步不在 UI Tween 內計算或扣資源。M-D30 免費換牌採合法替代牌預檢→原實例暫隔離→`CardDiscarded` 及觸發效果→`CardDrawn` 及觸發效果→原實例入棄牌區；每張卡確保持有區唯一。M-D24 `CastingInterrupted` 成立時立即執行部分 MP 返還、不能撤銷既付 AP 或 Overload Debt。以上為驗收規格而非已執行測試紀錄。

## Phase 1–2 新事件契約與穩定性（20，DELEGATED_DEFAULT）

請實作可序列化 `EnemyActionId`、`ReactionQueued/Executed/Skipped(reason)`、`CardDrawFailed(POOL_CHANGED)`、`ProtectRedirected`、`CastingCancelled(reason=CASTER_INCAPACITATED)`、`BattleOutcome(DRAW|VICTORY|DEFEAT)`（DRAW 先屬 CORE_CONFIRM）。隊列執行前才支付實際費用；同一 EnemyAction 一個 Reaction Window，作用於多 hit 的防禦由該 Action 綁定。傷害 trace 完整記錄 `actor,target_redirect,hit,crit,element,defense,guard,barrier,final_round,HP,outcome`；固定 seed 與命令序列重播不得依 UI FPS 改變。已有類似事件契約可保留並明確對應，不要求重複命名事件。見20與13。

## 2026-10-14 決定性事件合約：Last Spell／勝敗／Reaction
新增可 replay 的 Domain Events：`ActorIncapacitated(actor_id, action_id, event_seq)`、`LastSpellInvalidated(instance_id, reason=CASTER_INCAPACITATED, action_id, event_seq)`、`ScheduledEffectCancelled(instance_id, scheduled_event_id)`、`BattleOutcomeEvaluated(victory_priority=true, outcome, action_id)` 與既有 `ReactionConfirmed/ReactionPassed`。HP0 transition 立刻令該 actor 的尚未釋放 Last Spell 失效並使排程待效指令無法執行；至 action 結算邊界評估 `all_enemies_defeated` 優先於 `all_allies_incapacitated`。同 seed + 同 command tape + 同規則版本必得到相同事件序列與 outcome。**UI 使用 2.5D 或不同動畫 FPS 不得進 Domain 計時；不存在秒數強制 Reaction Timeout 或預設 Pass。**