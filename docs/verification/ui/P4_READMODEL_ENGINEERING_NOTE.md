# P4 Lv40 ReadModel — Engineering Note

**IMPLEMENTED_NOT_VERIFIED / NOT_EXECUTED** (2026-10-15).

## Source / approved boundaries

入口 `docs/handoff/TASK_READMODEL.md` 與 `docs/combat/COMBAT_SPEC_INDEX.md`；`M5.apply` 持續是唯一Domain命令交易；Presentation只是projector，不能把 `hp` / `ap_cost` / `damage` 從UI傳給 reducer，也不可偷看未公開的Boss `pending_cast`。

## Implementation

- `BattleCommandFactory.card(state, actor, instance, target, mode="CHANTLESS", combo=false, config={}) -> Dictionary`：末尾可選config，未啟用Lv40維持原Fixture命令。啟用則組成 `PLAY_LV40_CARD`：`type,command_id,expected_event_seq,actor_id,card_instance_id,target_actor_id,casting_mode,combo_mode`。缺卡或錯owner也只建立嚴格受限的intent，須由M5拒絕；不能假裝已提交成功。`build`仍可選 serial 產生穩定ID。`preview`不重新實作合法性，而是在深複本上走正式M5，不能修改原BattleState或RNG。
- `BattlePresentationAdapter.project(state, config={}) -> Dictionary`：舊 `project(state)` 與全部舊欄位保留。Lv40 opt-in補 `actor_name_keys`（actor ID與呈現分離）、`hand_cards`（真實Hand中的CardInstance ID、definition、兩語keys、內容權威成本及mode）、`public_intent_labels`（已公開Intent的名稱key、targets、scope、hit_count）、`boss_cast_public`（只取公開的casting/time欄位）。保持 `casts`、`barriers`、`tactical` 分離，不將FocusWard或Boss隱藏FSM塞入VM。不呼叫 `tr()`。
- `tests/test_p4_lv40_readmodel.gd`：新增內容和舊Fixture雙模式、禁信任payload、缺卡與錯owner穩定命令、preview無副作用、hand真實性、Boss只顯示public meta、detached deep copy、legacy相容 assertions。

## Dependency / planned UI caller

Domain 接線在另一分支 `handoff/p4-lv40-chat-20261015`：**在本分支未審查整合的前提下**，不把Domain API接受與Replay視為已驗證。Encounter UI 要取得已review的整合SHA後，呼叫 `Factory.card(...,config)` 和 `Adapter.project(state,config)`；在畫面層用 TranslationServer 轉 key；不要在Adapter新增隱藏欄位或誤當手牌UI持有費用權限。

測試命令：`godot --headless --path . --editor --import --quit` 然後 `godot --headless --path . --script res://tests/test_p4_lv40_readmodel.gd`；實際 Godot version / attempt / executed / PASS/FAIL / log：**NOT_EXECUTED**；尚無 runtime hash 或 CI 證據。

## Engineering rationale / Android mapping

此做法等同 Kotlin `sealed interface UiIntent` → ViewModel的Command Factory → domain reducer → immutable UiState Mapper；避免把業務邏輯綁在Compose或Godot Control；先製作內容投影，再讓Scene只消費資料。Alternatives：在UI直接調Domain副函式（破壞權威）、複製第二套戰鬥狀態（Replay無法等價），均拒絕。

面試追問：為何preview不能只檢查AP？（MP、Owner、phase、target、status、rng/多個條件都必須相同判定器）；怎麼避免ViewModel改回State？（深拷貝/不可變契約）；如何保證Boss資訊沒有提早透露？（只投影已公開Intent）；如何保留舊客戶端？（末尾可選config＋fixture feature flag）。

## Limits / rollback

本包不改Domain、Screen/HUD、翻譯、CI、project.godot或RTM；撤銷僅針對Factory/Adapter/new test/note。P4.4第三輪14/16尚未驗收，不能重跑換名重置。
