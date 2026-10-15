# Phase4.5 Lv40 Domain handoff

原始交接基準 `5103e40a4b95da82f2561b29c2604e9514fd398b` (master / P4.3)，handoff 起始 commit `977a289654e1470bcda83c6c25c14d4cda4c86ab`。
2026-10-15 checkpoint 上的 Lv40 Domain 接線修改已提交到 `handoff/p4-lv40-chat-20261015`，**IMPLEMENTED_NOT_VERIFIED**；與原始交接所述「入口尚未接線」相比，此段為後續試驗實作，絕非 Godot runtime 或 CI PASS。先前提供的 Godot 4.7.2.stable.official.ed1daf0bf 是原交接環境記錄；接收對話目前無 Godot binary，未重新執行。P4.4 GUI Gate 仍有待授權，master 未改。

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

**IMPLEMENTED_NOT_VERIFIED / NOT_EXECUTED**：本次接收對話有 GitHub 讀寫能力，但沒有本機 Godot 4.7.2 binary 或 checkout；所有新增提交都限定在交接 WIP 分支。沒有執行任何新 Godot runner、全部 Domain regression、GUI input / screenshot、CI、真人 playtest，**不可宣稱 PASS**。以前的 32/32 Content、1238/1238 Domain、100 seeds 及 P4.4 14/16 GUI 只是原交接的歷史證據，不是接線後結果；既有 P4.4 GUI 三次嘗試額度未重置或重跑。

### 本次接線：Source → Code → Test（待執行）

| 受影響檔案 | 本次接線 / 保留條件 | 待執行測試與 Oracle |
|---|---|---|
| `scripts/domain/m5/integration/m5_domain_resolver.gd` | M5 shared untrusted payload / balance / terminal guard 之後，僅在 `m5_lv40_enabled` 時呼叫 Lv40 Extension；原 fixture/M53 流程不變 | `tests/test_lv40_domain.gd`：真卡支付、重複／stale／錯 owner／錯 target、Replay |
| `scripts/domain/m3/phase/phase_engine.gd` | 仍由 M3 驗證 declared action/window；交 Lv40Boss.resolve 實際結算 AoE、蓄力、release、B03 中斷、R05 counter；原 M5 single-target 保留 | domain / edge：B02 多 hit、B04 AoE、B05→B06、B08→B09、B10、B11、Guard / Protect |
| `scripts/domain/m4/casting/casting_timeline_resolver.gd` | M4 已排序 due cast，Lv40 以既有 payment/release authority 與 Damage pipeline 執行；非 Lv40 仍走舊路 | domain / edge：Full Chant、Last Spell、HP0 失效、事件順序 |
| `scripts/domain/m3/reaction/reaction_eligibility.gd`、`reaction_queue_resolver.gd` | 已宣告的單體窗口中 R05/T05 eligibility；維持 M2 confirm-time 真實扣費、JIT skip；不自動 Pass | domain / edge：R05/T05、先 R05 後 T05 skipped 且不付費、AoE 無 Protect |
| `scripts/domain/m5/status/status_resolver.gd` | 預設 NEXT_PLAYER_PHASE 繼續有效；新增明確 ENEMY_PHASE_END tick selector，validate/real instance/grant 一致 | content / edge：Scorch 不在玩家階段重複 tick、敵方階段結束 tick、非法 selector 拒絕 |
| `scripts/domain/m5/damage/damage_pipeline_resolver.gd` | 僅版本化 Lv40 opt-in 設定時，未列舉 element 中性 10000 bp；保留舊模式 fail-closed | edge：未知元素 Lv40 neutral；關閉 Lv40 後拒絕 |
| `scripts/domain/m5/lv40/lv40_domain_extension.gd` | 靜態呼叫既有 Status.tick；成功交易後額外檢查 Status.validate；拒絕仍還原原 snapshot/event/RNG | content / domain / edge：版本、Status、拒絕原子性與 Replay |
| `tests/test_lv40_content.gd`、`test_lv40_domain.gd`、`test_lv40_edges.gd` | 保留舊 assertions 並新增已註明的 content/status/payment/seed/rejection 測例 | 需要真 Godot 4.7.2.stable 才能報 PASS/FAIL |

### 驗收 Gate 與未解風險

- 必須從本次**最新 branch HEAD** 在 Godot 4.7.2 執行原有三個 Lv40 runner、完整 M1–M5.5 Domain regression（交接前 1238 assertions）及 100 個固定 seed、四組 legacy 回歸；記錄**每群實際** attempt 1/2/3、exit code、完整 raw log、重現 seed/tape、State/Event hash。若任一群第三次仍失敗，停止該 Gate，不能以改名重跑洗掉失敗。
- 無執行環境、無新 CI run URL、無執行後的 replay hash；本次只有**程式碼／測試提交**，沒有 runtime 或 GUI 證據。
- `resources/combat/lv40/pending_integration.patch` 是原未套用草稿：已逐段對照實際路徑，沒有直接將原檔案當作可執行 `git apply` patch；它仍為歷史提案，不再代表目前 HEAD 的待改入口。
- `M5.apply(state,command,config)` 仍為唯一外部入口；UI、`project.godot`、CI、素材、平衡值、RTM、P4.4 Gate 未修改。Lv40 Doc29 候選 A / `BALANCE_PROVISIONAL` 不轉成 USER_APPROVED。

### 授權與中斷交接

使用者明確回覆「授權擴充既有 M5」：僅在同一套引擎內擴充已文件化的 Lv40 功能，所有候選數值仍為 BALANCE_PROVISIONAL。這不授權第二套戰鬥規則、重大未批准玩法或最終美術採用。

Domain 子 Agent 因工具回報使用額度限制中止；主 Agent 接手。現有入口保持未修改，新增模組與測試保留，不宣稱完成接線。已存在的 `tests/test_lv40_content_attempt1.log` 報告32/32內容測試通過；此項不是 `M5.apply` 全整合、全部邊界或整場戰鬥證據。後續先審查新增模組與必要入口 patch，再依原測試群組計數執行，不重設配額。
