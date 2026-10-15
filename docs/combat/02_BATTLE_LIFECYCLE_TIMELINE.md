# 02 — 戰鬥狀態機、回合與事件時序

> **Documentation status · 2026-10-15 — APPROVED_DETAIL + HISTORICAL_EVENT_TBD**：回合、Reaction 與合法 Action 邊界有核准內容；CORE-01/02/04 見 20/21；M5.4 已對勝敗時序進行 headless 驗證。早期事件排序未決清單是歷史快照。 現行導航：[Combat Spec Index](COMBAT_SPEC_INDEX.md)；缺口：[Open Issues](COMBAT_OPEN_ISSUES.md)。**Godot Domain M1～M5.5：1,238/1,238 通過；100 場固定 Seed 的完整戰鬥與 Replay 已驗證（[Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741)）。Scene／真人可玩／正式平衡仍未驗證。** 以下舊段落保留歷史脈絡，不是新測試或新核准。



## 1. 狀態模型

一場戰鬥至少包含：`INITIALIZING` → `ROUND_START` → `PLAYER_PHASE` → `PLAYER_PHASE_END` → `ENEMY_PHASE`（內含 `REACTION_WINDOW`）→ `ROUND_END` → 下一 ROUND 或 `VICTORY/DEFEAT/ABORTED`。角色另有 `ACTIVE / CONCENTRATING / EXHAUSTED / INCAPACITATED`；施法實例另有 `PREPARING / CHANNELING / DESTABILIZED / RESOLVED / INTERRUPTED`。

**必須分清**「敵方意圖預告」與「實際執行敵方行動」。Boss蓄力若有跨回合等待，使用獨立 `CastingInstance` 和 `execute_at`，而非使用 UI 文字當計時器。

## 2. 已確認的高階時間線

1. 開戰建立三角牌庫、洗牌、各抽至4張；確定 Boss 初始意圖。
2. 玩家回合開始：結算已到期且仍可執行的完整詠唱；依規則補牌；隊伍 AP 重置6；更新可見 Boss 意圖。
3. 玩家階段：**逐次選擇單一合法行動 → 立即執行並依該動作效果時序結算 → 再自由選擇同一或其他合法角色行動**，直到玩家主動結束 Player Phase；完整詠唱提交時開始 Concentration／CastingInstance，延遲部分按預定時點結算。
4. 玩家結束階段：剩餘 AP 以 1:1 轉 RP，**受預設 RP cap 6（M-D08）裁切；只有明文 SP 可提高相應 Enemy Phase 的 cap**。玩家 AP 歸零；緊接 Enemy Phase 結束時 RP 必須歸零（M-D09）。
5. 敵方階段：依公開的有效 Boss 意圖（含其他敵人）執行；在技能生效前適當處理 Reaction Window；先結算合法干擾／防護，再傷害與後續效果。
6. 回合末：檢查戰鬥結束、結算有明確 tick 時點的狀態效果、清理過期 Combo Opportunity／RP 等。

**注意**：同時涉及「新回合 Boss 意圖／先前 Boss 蓄力完成／玩家完整詠唱完成」的精準同時時序**TBD（BLOCKED）**；上述是最低可理解的框架，詳見 `14`。未批准前應用具名 resolution hooks 隔離。

## 3. 合法性優先於效果

每次動作必須 `ValidateAction(actor,action,target,phase,battleState)`：檢查角色存在/是否可行動、是否正在 Concentration、該卡是否在手上、AP/MP/RP足夠、目標合法、手牌實例屬於角色、每場/每回合限制、Reaction 窗口是否正確。**任一失敗不得部分扣資源**；回傳原因代碼，而非直接以 UI 決定。

在單筆行動成功後，依同一事件交易扣費 → 移卡 → 套效果／開始詠唱 → 產生事件 → 記錄；不允許 UI 重入時同一卡重複出牌。

## 4. 事件排序待決清單

| 同時發生 | 候選解決原則 | 狀態 |
|---|---|---|
| 玩家詠唱到期與補牌 | 先施法完成，再補牌 | PROVISIONAL |
| Boss受中斷與Boss傷害 | 先干擾取消法術、後核算傷害 | APPROVED方向 |
| 角色在施法完成同時死亡 | 應固定解算先後 | TBD |
| HP歸零、Last Spell完成、Boss歸零同一事件 | 應產出唯一明確勝敗結果 | TBD |
| 多敵人同一敵方階段 | 固定敵人順序/時間軸優先級 | TBD |
| DoT/HoT/盾到期 | 專用tick點不可任意 | TBD |
| 多個反應觸發 | 每人每窗口最多一次、多人可同行；整組排隊確認後依序結算，失效自動跳過 | APPROVED：P1-D04/LEGACY-Q15/LEGACY-Q16；多窗口邊界仍TBD |

## 5. 不變量

- AP、RP、MP、HP、手牌各區數量不可負值（若有超量需正規化）。
- 同一張實體卡不得同時在 draw/hand/discard/casting/exhaust 多區。
- `EXHAUSTED` 角色不得發起新玩家動作或 Reaction/連攜。
- `CONCENTRATING` 禁止一般主動指令，允許明示 CAST_COMPATIBLE 的例外。
- 每一個 CastingInstance 結束後不得再受傷害／干擾結算。
- 任何回合中止前應先檢查戰鬥終止與未結算事件優先級（TBD）。

## 6. 最小事件 log 格式

`{seq,round,phase,actor_id,target_ids,action_id,card_instance_id,source_effect_id,costs_before,costs_after,seed_rng_index,events,visible_intent,battle_state_hash}`。資料契約詳見12。


---

## 7. Phase 1 玩家/敵方階段參考流程（已決議部分）

> **APPROVED**：資源轉換及過期、同人每窗口一次、多人同窗口參與、先排後確認、失效跳過。**ENGINEERING PROPOSAL**：以下命名及函式切分僅為建議，不暗定仍屬TBD的結算順序。

```text
PlayerPhaseStart:
  # AP基線為共享6；手牌補至4；完整詠唱到期先後見舊文TBD
  initialize_turn_attack_mp_restore_flags_to_false()
PlayerPhase:
  while player_issues_legal_action:
    validate(actor_state, ap, mp, zone, mode, targets)
    spend_action_cost_once(); resolve_action(); log()
    if BasicAttack and actor.first_basic_attack_this_player_round:
      actor.attack_restored_mp_this_round = true
      restore_mp(config.basic_attack_mp_gain) # gain數字 PROVISIONAL
PlayerPhaseEnd:
  team_rp = min(team_remaining_ap, effective_rp_cap)   # 預設cap=6，M-D08；明文SP可改cap
  team_ap = 0
EnemyPhase:
  for each declared enemy action with a legal reaction opportunity:
    open_window(window_id, associated_enemy_action_id)
    player drafts zero or more distinct-actor reactions in explicit order
    player confirms once
    for each queued reaction in chosen order:
      revalidate against mutated state
      if invalid because trigger/target no longer exists:
        SKIP_WITHOUT_PAYMENT, card stays in hand, actor slot not consumed
      else:
        execute once, consume required RP/MP and card if SP
    resolve remaining enemy action if still valid
    close_window
  team_rp = 0  # 即使沒有敵方攻擊亦清除
RoundEnd:
  # 精確持續效果、勝敗/同步tick順序仍見14未定
```

**重要界線**：程式不得將「隊列編輯／預覽」等同於實際出牌；只有`ReactionExecuted`才支付並設定使用次數。`ReactionSkipped`不觸發被當作「已使用」的技能效果。玩家確認前移除隊列不等於戰鬥中的取消技能。

## 8. Reaction Window 生命週期與關閉事件

建議狀態：`NOT_ELIGIBLE → DRAFTING → CONFIRMED → RESOLVING → CLOSED`。領域提交前先驗證單一 ActionID 與窗口ID；確認後只接收已確認 queue 的 execution，不接受追加「隱藏反應」。同一敵方行動之單一窗口允許不同 actor 加入；同人編輯時可替換自己的意圖，但**不得提交兩份**。確認前 UI 可以重新排序，確認後由引擎照排定順序處理，不能交給速度或 UI Tween 競速。

敵方施法已中斷時：先標記該當次敵方攻擊後續攻擊效果失效；已安排的 Protect 失去原事件時跳過，對該次攻擊才合法的防護SP亦跳過；對其他來源獨立存在且仍合法的支援 SP 依原順序執行。哪種支援效果「不依賴該次攻擊」須資料定義清楚，未定卡不可臨時猜測。

## 9. Phase 1 回合不變量與裁決案例

- **R-TIME-01**：回合結束 AP=6/3/0 時，RP=6/3/0；無任何獨立 `min(2, ap)` 規則；轉換是一次性的，不重複發生。
- **R-TIME-02**：敵方階段多次攻擊會花用同一個 RP 池；其任何餘額必須在階段結束清空，即使玩家未按 Reaction 或敵人本回合無有效攻擊。
- **R-TIME-03**：不同窗口 actor 的「本窗口是否已反應」標記分別管理，不能把第一個窗口標記錯誤套到下一窗口。
- **R-TIME-04**：在同一窗口排 `反制→Protect`，前者取消了對應攻擊，Protect 應零耗跳過；已反制成功的前者照常扣資源。
- **R-TIME-05**：Actor進入Exhausted後，不得獲授一般Reaction權；其「可被當成保護目標」之判定另屬TBD。

## 8. 玩家逐次行動與 Reaction 佇列：規範性聲明（P1-D01，2026-10-14 明確化）

**APPROVED（僅釐清既有契約）**：Player Phase 不允許 UI 要求三名角色預先輸入全部指令，等三人都選完才一次開始統一執行。對每一個合法行動：`ChooseOneAction → Validate → CommitCosts → ExecuteImmediateEffectsOrStartCasting → SettleActionBoundary → NextChoice`。同一名角色可以連續執行多個合法行動，且不必三人輪流。對 Full Chant 只立即提交並開始詠唱，不得把延遲魔法效果當成當下完成。與此不同，敵方 Reaction Window 採**先排合法反應佇列、按一次確認、依序結算**；中途失效且尚未執行的反應依 P1-D16 跳過且不付費。最新 AP／RP／債務條款以 `18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md` 優先，不以本章早期的 6 AP 基線誤認為永遠無法額外取得 AP。

## Phase 2 延伸事件／勝敗規範（P2-D14～D16，APPROVED DIRECTION）

HP0 => `INCAPACITATED`，不能再安排一般主動行動；與 Concentration 解除、被動觸發、復活及 Exhausted 的交界 TBD。勝敗在**合法行動及隨行結算事件完成後**檢查，不能因 HP 在多段效果中途達零就無條件阻斷尚合法的同一 SP；同時死亡與特殊行動見19 OPEN。MP 中斷退款屬 `CastingInterrupted` 成立後即刻事件；不退 AP，也不抹除 Overload 債務。Player Phase 逐次選人即時結算、Reaction Window 先排確認後依序結算的既有差異不變。

## Phase 1–2 到期／失能／結果事件的新工程裁決（見20；DELEGATED_DEFAULT）

Player Phase start：先處理當點 Casting/Status 合法到期效果 → 完成其事件與勝敗檢查 → 計算新的 AP/債務及有行動資格者 → 各角色手牌不足4才補至4（cap8）；此流程不得以動畫事件決定。敵方 EnemyAction 開一個窗口，固定 ActionId，包含合法多段 hit；Reaction Queue 採逐筆 JIT 重驗，非法免耗跳過。HP0 當場 Incapacitated 並凍結手牌；一般未釋放 Full Chant 隨倒地取消、不依 M-D22 退 MP；已成功提交的 LastSpellInstance 是不可取消例外。合法當次行動及附屬事件結算後才檢查勝敗；雙方同時殲滅暫以 DRAW 進行測試，**CORE_CONFIRM**。詳細優先級、負例及仍保留的重大抉擇見20。

## 10. 終局優先級與 Last Spell 到期（2026-10-14 USER_APPROVED）
- 一次合法 Action（包括同一張卡的必要後續事件）完整結算後，**先查 `all_enemies_defeated`：若 true 則 `VICTORY`，即便 party 全員 HP0**。否則若所有可戰鬥角色都 Incapacitated，則 `DEFEAT`；其餘繼續。一般 Exhausted 不等於 HP0 或死亡，但不能執行新動作。此優先級取代 `DRAW` 模擬基線。
- 角色 HP0 引發 `Incapacitated` 時，若存在其尚未釋放的 `LastSpellInstance`，**立即強制 `INVALIDATED` 並取消已排程效果**，不等預定到期；一般 Full Chant 也按其既有失能規則停止。不可讓兩回合之後預定的 Last Spell 漏掉失效檢查。已合法釋放完成的傷害不因施法者同一行動後續 HP0 而追溯取消。
- `phase-start` 與 delayed casting event 按已定事件排序進行，但到期前**再次確認 caster HP>0、instance 尚 ACTIVE**。未獲確認的角色行動或 UI timer 不可執行事件。