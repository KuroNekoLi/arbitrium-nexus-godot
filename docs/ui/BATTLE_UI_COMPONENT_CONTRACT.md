# Battle UI Component Contract — V0 / API-first decomposition

> **STATUS: DESIGN CONTRACT / NOT IMPLEMENTED / NOT TESTED**（2026-10-15）。
> Source: `ui/hud-visual-refactor-20261015` from `master@5103e40a4b95da82f2561b29c2604e9514fd398b`；Godot 4.7.2；1280×720 Design。
> 與 `docs/ui/01_SCREEN_LAYOUT_AND_COMPONENTS.md` 的目標樹並行：該文件是視覺功能規格，**本文是以現有程式實查後制定的分階段拆分契約**。不調整任何 `docs/combat/` 玩法。

## 1. 現有現實架構（請先查 Git HEAD 再動工）

**現行可執行樹**：`scenes/battle/battle_screen.tscn` > `BattleScreen/Design/{Background,Arena(A,B,C,Boss),HUD}`。`HUD` 是 `Control`，掛 `scripts/battle/ui/battle_hud.gd`，在 `_build()` **動態建立**下列子節點，非 Editor 中已保存 Scene：

`TopBar`、`Conditions`、`party VBoxContainer (未命名)` 內 3 個 `HeroRosterItem`、`Commands`、`EnemyStatus`、`Context`、`HandView`、`TargetBoss / TargetA / TargetB / TargetC`、`ReactionQueue`。晚期 branch 的 P4.4 可能還有 `Result` / ScrollContainer，不能假定 master 版本已有。

- `battle_hud.gd` 實際公開 signals：`actor_requested(actor: String)`、`card_requested(instance: String)`、`card_released(instance: String, pointer: Vector2)`、`command_requested(kind: String, fields: Dictionary)`、`target_requested(actor: String)`、`confirm_requested()`、`cancel_requested()`、`locale_requested(locale: String)`。
- 對外方法：`render(projection: Dictionary, actor: String, cards: Array, reaction_choices: Array)` 和 `set_targets(ids: Array)`。
- **實際 UI Client 非常依賴 HUD public fields**：`scripts/battle/battle_screen.gd` 直接存取 `hud.card_views`、`hud.details.text`、`hud.mode`、`hud.combo`、`hud.feedback.text`、`hud.log_label.text`、`hud.confirm_button.disabled`、`hud.target_buttons`、`hud.reaction_panel.visible`、`hud.theme`。
- **既有測試也依賴節點／欄位**：`tests/test_p4_hud.gd` 會 `get_node("TopBar")`、驗證 `hand.size`、`card_views`、`end_button.text`、Reaction 無自動 Pass；`tests/test_p4_input_capture.gd` 目前還用 `reaction_column.get_child(-1).get_child(-1)` 找 Pass 按鈕。不得在 V1 搬樹後讓它們直接失效。
- 現在資料鏈：`BattleController → M5.apply → BattlePresentationAdapter.project(state) → BattleScreen.present(...) → BattleHUD.render(...)`；AnimationDirector 消費接受後 Events，均不得讓 View 直接修改 Domain。

## 2. 拆分原則

1. **先接口後 Scene**：每個 Control 只擁有自己創建／顯示的子節點；`BattleHUD` 專職 compose／bind／re-emit signal／layout roots，禁止重新擁有個別按鈕的呈現細節。
2. **Domain-authoritative**：卡片所屬、Cost、可行動與 target legality、Reaction draft/order、Boss Intent、Casting／Outcome 均只讀 Presenter/現有 Validator 的投影；Component 可以保存 selection/hover/scroll/focus，但不能扣費/改 state。
3. **先保留 public facades**：V1 以兼容 accessor/field 轉發 `battle_screen.gd` 和測試；新 `BattleHUD` 對外 signals/methods 完全不變。等後續獨立小提交＋完整回歸，才有條件把呼叫者改成明確 view API，**不得同一 commit 大量改 runtime + 重寫 oracles**。
4. **不增原生玩法**：`Analyze`、`Item` 等未有有效實作時保留 existing command/disabled 表現，不可新增假的 accepted Command。`Last Spell` 必須是獨立入口，不是手牌卡。
5. **重用**：`scenes/ui/hero_roster_item.tscn`、`scripts/ui/hero_roster_item.gd`、`scripts/battle/ui/battle_card_view.gd`、`addons/simple_cards/`、`resources/ui/appearances/`、`resources/ui/battle_theme.tres`；禁建 duplicate 狀態模型／卡牌 registry。
6. **Scene 命名與路徑是建議**：新場景以 `res://scenes/battle/ui/`、腳本以 `res://scripts/battle/ui/components/`（或一致等價位置）規劃；未建立的檔案不可寫成已存在。

## 3. 拆分目標 Component Tree

`BattleScreen/Design/HUD` 在 V1 仍由 `battle_hud.gd` 為 Composition Root：

```text
HUD (Control; existing battle_hud.gd)
├── TeamPhaseHeader (Control scene; legacy node alias TopBar)
├── PartyStatusPanel (Control scene; 3 × existing HeroRosterItem)
├── ConditionsStrip (Control; optional, collapse when empty)
├── CommandMenu (Control scene; legacy node alias Commands)
├── HandView (Control scene; 0..8 existing BattleCardView, SimpleCards ArcShape)
├── BossStatusPanel (Control scene; hp / break / public statuses)
├── EnemyIntentPanel (Control scene; announced intent / target / timing)
├── ActionDetailsPanel (Control scene; cost, mode, combo, confirm/cancel, feedback)
├── BattleLogPanel (Control scene; event_seq-tied text)
├── TargetHitRegions (existing target buttons, transparent outside legal target selection)
└── OverlayRoot (Control / focus boundary)
    ├── CastingChoice (only when required)
    ├── ReactionQueue (manual drafting)
    ├── ComboChoice (opportunity-only)
    ├── LastSpellConfirm (irreversible-commit warning)
    └── ResultOverlay
```

**V1 API 相容優先於完全達成上圖**：例如 `TopBar` 與原 `Context` 可先保留 alias；`ActionDetailsPanel` / `BattleLogPanel` 可從既有 Context 徐徐拆分，不能一次換掉 Controller 的欄位引用。

## 4. Component I/O 契約表（API proposal，非現存宣告）

| Component | Input（UI-only detached data） | Child emits | 主要 owner / invariant |
|---|---|---|---|
| `TeamPhaseHeader` | `{phase,round,resources,current_locale}` | `locale_requested(locale)`、`utility_requested(kind)` | AP/RP 回合資源；只顯示現有計價；TopBar alias |
| `PartyStatusPanel` | `{actors_by_id,selected_id,barriers,casts}` | `actor_requested(actor_id)` | 3 個真 HeroRosterItem；HP/MP/狀態／選中；不顯示獨立 HandCount |
| `CommandMenu` | `{phase,outcome,command_availability}` | `command_requested(kind, fields)` | Basic/Analyze/Item/Swap/Last/End，明確 disabled/reason，不產生命令語義 |
| `HandView` | `{owner_id,items:Array[CardViewVM],selection_id,interaction_mode}` | `card_requested(instance_id)`、`card_released(instance_id,pointer)` | 卡片 reorder/hit bounds 和 ArcShape，獨立 CardInstanceID、owner；0..8 |
| `BossStatusPanel` | `{boss_actor,tactical,barriers}` | `detail_requested(target_id)`（可選） | HP != Break，Exposed 必須真值，Boss 名稱不是生成圖猜測 |
| `EnemyIntentPanel` | `{published_intents}` | `inspect_intent_requested(id)`（可選） | 顯示已公開資訊、合法目標/時程；不可虛構隱藏 Intent |
| `ActionDetailsPanel` | `{card_preview,selected_target,casting_profiles,combo,feedback}` | `confirm_requested()`、`cancel_requested()`、`preview_changed(mode,combo)` | Preview 只讀；操作 Submit 由既有 Screen 執行；保留 existing OptionButton/CheckButton |
| `BattleLogPanel` | `{entries:[{event_seq,localization_key,args}]}` | `expand_requested()`（可選） | 不自行合成 Gameplay Event；原 `log_label.text` transition |
| `TargetHitRegions` | `{legal_target_ids}` | `target_requested(target_id)` | 無合法目標時鼠標穿透；Input 坐標與 Design scale 一致 |
| `ReactionQueue` | `{window,draft,choices,remaining_rp}` | `command_requested(QUEUE/REMOVE/REORDER/CONFIRM/PASS,fields)` | 只在 `DRAFTING` 可見；未 Confirm 不扣 RP；不加 timer |
| `CastingChoice` / `ComboChoice` / `LastSpellConfirm` | genuine validator previews | explicit confirm/cancel / chosen mode | 只有真實合法 UI 事件；不能錯誤變成免費追加卡、瞬發 Last Spell |
| `ResultOverlay` | `{outcome,summary}` | `command_requested(RESTART_BATTLE,...)` | 勝敗完全取自 Domain |

`CardViewVM` 建議逐卡欄位：`{instance_id:String,owner_actor_id:String,appearance:Resource,cost:String,legal:bool,reason:String}`；現有 `BattleScreen.present` 僅傳 `{instance_id,appearance,cost,legal,reason}`，**若補 owner_id 必須由 Present 層保證正確，不得在卡片中猜值**。

`BattleProjection` 現有 keys（來自 `battle_presentation_adapter.gd`）：
`actors`、`resources`、`hands`、`phase`、`round`、`outcome`、`event_seq`、`intent`、`reaction`、`barriers`、`casts`、`tactical`。任何新的 VM key 都是 Presenter schema change，必須先定 migration + case；不得把 proposal 當現有實作。

## 5. BattleHUD public API 與兼容性矩陣

V1 預設**保留**以下函式簽名及來源狀態：

```gdscript
signal actor_requested(actor: String)
signal card_requested(instance: String)
signal card_released(instance: String, pointer: Vector2)
signal command_requested(kind: String, fields: Dictionary)
signal target_requested(actor: String)
signal confirm_requested()
signal cancel_requested()
signal locale_requested(locale: String)

func render(projection: Dictionary, actor: String, cards: Array, reaction_choices: Array) -> void
func set_targets(ids: Array) -> void
```

**既有 caller／tests 的 member access 不能隨意刪**：

| 必留 access | 現有 caller / test 用途 | V1 compatible 方案 |
|---|---|---|
| `card_views`、`hand` | 動畫抽取 card art/position；8張 bounds | alias 真 `HandView` 的 card instances/list，觸發前後一致 |
| `details`、`mode`、`combo`、`confirm_button`、`feedback` | Preview、Mode、Combo、Confirm、Error | legacy refs 指向 `ActionDetailsPanel` 內真 Control；不另外造一份 UI |
| `log_label` | `_on_resolved` 顯示 Event log | alias 真 `BattleLogPanel` 內 Label，保留既有更新時序 |
| `target_buttons` | 拖卡座標判定合法目標 | 仍為有效 `Dictionary[String,Button]`；調整 overlay 時同步更新 global hit rect |
| `reaction_panel`、`reaction_column` | phase input guard + 現有 GUI Pass 測試 | 可保留舊 alias；QA 後續改成 explicit `pass_button` semantic getter，不弱化 click test |
| `end_button`、`TopBar` | i18n smoke、height test | ref/button alias 保留；`get_node("TopBar")` 不可意外失敗 |
| `theme` | 目前 Animation Effects 接 UI Theme | 使用同一資源或兼容 Theme getter |
| `set_locale()` scene reconstruction | `BattleScreen` 會新建 `BattleHUD` | 保證信號重連/手牌重繪/Focus 與語言一致 |

**不相容改動必須在獨立提交明確更新 caller+test（保留原 oracle）、新增 deprecation 說明與證據；V1 不要執行這步。**

## 6. Interaction 時序與資料流（原子性不可被 UI 破壞）

**選角**：Party Button `hero_selected(id)` → BattleHUD `actor_requested(id)` → `BattleScreen.select_actor` → Presenter 重讀**該角色**真 Hand → HandView diff/render。僅 UI selection；Domain hash 不變。

**出牌**：`BattleCardView.card_clicked` → `card_requested(instance_id)` → Screen 檢驗合法目標／成本 preview（保留 `expected_event_seq`）→ 點 target → 選擇模式及 Combo → Confirm → Controller → M5 Domain。Rejected 不產生支付、Zone 移動或成功 cue；UI 僅顯示 reason。

**拖卡**：`drag_started` 顯示 elevated overlay；`card_released(instance_id,global_pointer)` → Screen 與 `target_buttons[target].get_global_rect()` 比對 → 真合法目標 → 明確 confirm → Controller。Drag cancel / invalid drop 回 arc pose；換解析度後 hit rect 仍與 World 對齊。

**敵方 Reaction**：公開 EnemyAction → Window=DRAFTING → UI Queue／Remove／Reorder；draft 可變但權威 state 尚未付費 → Confirm/Pass → Domain JIT；不設強制秒數、不自動 Pass，不把 ReactionQueue 當固定回合列表。

**語系**：`set_locale("en"/"zh_TW")` 既有會重建 HUD；所有新的组件 theme/labels 與 signal 必須能 clean rebind。以 stable ID 而非翻譯文字決定操作。避免多個 signal connection / stale Node refs。

**動畫**：Domain accepted → snapshot/VM 即更新 → Director queue/cue。Skip/降低 FPS/重繪 UI 不得二次結算。`focus` 和 modal click 不能穿透觸發卡片或 Boss action。

## 7. Godot 組件工程守則

- `BattleHUD` 只持有組件引用與 routing，不硬寫全部 title、cost、card description；優先為各组件建立 `render(vm)` 或 `set_data(vm)`，只輸入 deep-copy 或 read-only usage data。
- 可用 `Control`、`PanelContainer`、`VBoxContainer` 與 `NinePatchRect`，同一 owner 一組組件內部局部布局；不要在 `Container` 直接手動改受其控制的子節點 position（除非封裝自訂 HandView）。
- 新组件信號 typed、命名一致，Mouse Filter / Z-index 符合 modal/focus safety，Control node owner 與 PackedScene instancing 正確。
- 外觀資料為可配置 Appearance，不能把卡牌名稱、AP/MP、target logic 寫入 Theme、Texture 或特定 Node。
- 改 Theme/Shared translation table/`project.godot`/`battle_hud.gd` 只能由單一 integration owner 寫，避免多個 Codex workers 覆蓋。
- 仍可沿用既有 Programmatic `_build` 過渡；只在各元件穩定後逐個轉 PackedScene，**不需要把一整個 UI 一次從動態改成靜態**。

## 8. V1 拆分順序與每個 Gate

| Commit group | 實作 | 驗收 / 邊界 |
|---|---|---|
| V1.0 baseline | 只讀 `git status`、HEAD、original scene captures、tests | 所有未提交改動分類；不跑尚未獲追加授權之 P4.4 重試 |
| V1.1 | `TeamPhaseHeader`、`PartyStatusPanel`、`CommandMenu` | 原 `TopBar`/選角/EndPhase/locale API 仍可用 |
| V1.2 | `BossStatusPanel`、`EnemyIntentPanel`、`BattleLogPanel` | Boss intent 讀真 projection；`hud.log_label` 正常 |
| V1.3 | `ActionDetailsPanel` + Condition Strip | Mode/Combo/Confirm/Cancel/Feedback & 焦點仍正確 |
| V1.4 | `HandView` 包裝既有 `BattleCardView` + ArcShape | 卡片數量/instance ID/rotation/drag/bounds；無額外 Card Zone |
| V1.5 | `OverlayRoot` + ReactionQueue 包裝 | DRAFTING 等待、Queue/Pass、沒有倒數、Modal focus 仍正確 |
| V1.6 | 全部 integration regression + Visual Snapshot | 戰鬥 Domain hash、GUI screenshots 與原版本視覺不應有無意義大幅變動（V2 才改佈局） |

所有拆分單元做到 **source-to-target mapping + emitted signals unchanged + UI regression tests** 才可提交。新 Component 沒有獨立 fixture 時新增 typed render/intent tests；不弱化既有 P42/P43 判斷。

## 9. 與同時進行的 Lv40 工作的契約

- 本 branch 取自 P4.3 `master`；`handoff/p4-lv40-chat-20261015` 是 WIP，可能包含 P4.4 的 `Context ScrollContainer`、`Result Overlay`、新的 `HUD` member fields。**先比對並由整合者逐一合併 API**。
- 新 `BattleHUD` 須容納 Lv40 的新 VM 字段／反應模式的合理擴充，但**不可先憑 WIP 代碼自行創造 Domain payload 或改 M5 public entry**。
- P4.4 GUI 三次以舊跑次計算；轉 UI 新分支並不重置重試額度。若整合後需要額外重跑，請取得新授權並記錄對應 run/case。
- 最終合併只在各 branch 所屬 Gate 通過，且 source HEAD/CI 一致時進行；不直接複製整段 `battle_hud.gd`。

## 10. 審核 checklist

- [ ] 依 Git HEAD 最新版確認 API 與 WIP 差異
- [ ] 畫出 diff 的 before/after node ownership
- [ ] V1 所有 public signals/methods/fields 或 facade 均可用
- [ ] P42 tests + P43 input/capture 仍可跑原 oracle
- [ ] 角色切換不影響 Domain；CardInstance + zone 守恆
- [ ] 跨語言、1280/1920、0/1/4/8 卡仍可操作
- [ ] Reaction 佇列 Confirm/Pass 明示，無 Timer
- [ ] 每個元件可獨立更換 Theme/Appearance，無嵌入玩法成本
- [ ] 截圖／實際 Godot4.7.2 logs 已保存才可標 VERIFIED

延伸：`BATTLE_UI_DESIGN_SYSTEM.md`（token、layout）、`BATTLE_UI_VISUAL_ACCEPTANCE.md`（測試/截圖），以及 Godot 官方 `Control`、`Containers`、`Signals`、`Theme` 文件。
