# Phase4.5 Lv40 Domain handoff

施工中；HEAD 5103e40a4b95da82f2561b29c2604e9514fd398b，Godot 4.7.2.stable.official.ed1daf0bf。
依使用者並行限制，P4.4 提交完成通知之前只新增 Lv40 模組／測試，既有入口尚未接線。

## 穩定公開接口

- `res://scripts/domain/m5/lv40/lv40_encounter.gd`: static `config() -> Dictionary`、`initial(seed: int = 20261014) -> Dictionary`。
- `config.m5_lv40_enabled = true`；版本 `lv40-starter-v0.3-boss-v0.2-A-provisional-1`，全部數值 `BALANCE_PROVISIONAL`。
- `initial()` 為現有 M3/M4/M5 envelope：`core.battle`、`core.cards`、`published_intents`、`reaction_window`、`events`、`event_seq`；沒有第二 BattleState 或 RNG。
- actor A/B/C 對應 ren/akane/tsumugi，Boss 固定 `Boss`；顯示 metadata 在 `core.battle.actors[id].meta`。
- `M5.apply(state, command, config)` 為唯一正式入口；新 `type=PLAY_LV40_CARD`，欄位 `command_id/expected_event_seq/actor_id/card_instance_id/target_actor_id/casting_mode`，可選 `combo_mode=NORMAL|COMBO`。瞬發卡接受 `INSTANT` 或 `CHANTLESS`；雙模式卡接受 `CHANTLESS|FULL`。
- 一般指令、免費換牌、Reaction queue/confirm/pass、Last Spell 沿用現有入口。
- 卡面 metadata：`config.definitions[id]` 與 `config.lv40_cards[id]` 皆含 `type/dualMode/namekey/descriptionkey`；canonical snake_case `kind/mode/name_key/description_key` 在 lv40_cards。
- `config.actorDisplayNames={A:朝霧蓮,B:九條朱音,C:白石紬}` 是 zh-TW fallback；`actor_name_keys` 是本地化 key。`bossname`/`boss_name_key`；`intent_name_keys[B01..B11]`，每個 public intent 亦含 `name_key`。
- Last Spell 使用現有 `ACTIVATE_LAST_SPELL_M4`，`actor_id/target_actor_id/confirmed:true/casting_mode:FULL`；A/B 指向 Boss，C 指向有效友軍。
- Reaction 使用現有 `QUEUE_REACTION`，`window_id` 與 `entry={kind:REACTION_SP_FIXTURE,actor_id,card_instance_id,target_actor_id}`；R05 是蓮保護另一位目前被單體攻擊的隊友，T05 是紬對目前實際單體承受者加盾；既有 `CONFIRM_REACTIONS/PASS_REACTION`。

## 事件／狀態契約

所有 accepted events 保持 outer `kind/details/event_seq/command_id/source/phase/round`；拒絕回傳原狀態與空 events，不改 RNG／成本／牌區。
重用 `DamageTrace/HPDamageApplied/HPHealed/CastingStarted/CastingReleased/LastSpellReleased/ActorExhausted/LastSpellInvalidated/ReactionExecuted/EnemyActionResolved/BattleOutcomeEvaluated`。
Lv40 附加 `BossIntentCommitted/BossPhaseChanged/BossCastingStarted/CastingDisruptionEvaluated/CastingStabilityChanged/CastingInterrupted/BossCastingReleased/BossCooldown/BossActionFizzled/HPBarrierGranted/HPBarrierExpired/PassiveTriggered`。
Boss FSM／pending casting 放 `core.battle.lv40`；Break/Exposed/Combo 沿用 `core.battle.m53`。
`published_intents` 明示 `skill_id/target_scope/target_ids/targeting_mode/is_protectable/unprotectable/hit_count/casting_id/expected_execute_phase/conditional_branches`。
若玩家中途跨 HP 門檻，已公布意圖仍保留到結算；新意圖於下一 PlayerPhase 前發布。

## 規格版本選擇

docs26 §5 精確三副12 SP，覆蓋 docs25 歷史配置。docs27 B01–B11 行為；docs29 §4 候選 A 明確更新數值：Boss HP2700、PAtk417、MAtk434、Break22；不再另乘 Python attack_factor 1.7。
這是使用者已授權的 provisional 內容擴充，不宣稱正式平衡或 Python parity。

## 驗證狀態

IMPLEMENTED_NOT_VERIFIED；入口接線、測試結果、精確 changed paths 會在交付時補上。
未執行 CI；依使用者限制不 commit/push、不改 RTM/UI/CI/project.godot。

### 授權與中斷交接

使用者明確回覆「授權擴充既有 M5」：僅在同一套引擎內擴充已文件化的 Lv40 功能，所有候選數值仍為 BALANCE_PROVISIONAL。這不授權第二套戰鬥規則、重大未批准玩法或最終美術採用。

Domain 子 Agent 因工具回報使用額度限制中止；主 Agent 接手。現有入口保持未修改，新增模組與測試保留，不宣稱完成接線。已存在的 `tests/test_lv40_content_attempt1.log` 報告32/32內容測試通過；此項不是 `M5.apply` 全整合、全部邊界或整場戰鬥證據。後續先審查新增模組與必要入口 patch，再依原測試群組計數執行，不重設配額。
