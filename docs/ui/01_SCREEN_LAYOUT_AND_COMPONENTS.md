# 01 — 戰鬥 HUD 視覺規格與可重用元件契約

> **PLANNED / SPEC ONLY / NOT IMPLEMENTED**。本文件規劃如何將概念圖重建為可互動、可換素材的 Godot UI；非玩法 ADR，所有玩法、費用、事件與合法性均由 `docs/combat/` 裁決。視覺稿中的假角色、魔王、技能數值與名稱不能成為 Canon。

## 1. 設計意圖與既定需求

視覺方向：深色奇幻 × 奧術科技、2D 橫向／2.5D 空間感、三名我方角色在左、Boss 在右、以卡牌為行動媒介。Godot 專案現有基本畫布 **1280×720、16:9**，概念圖較大時應以比例還原，不能把概念圖像素當固定位置；畫面兼顧 1280×720 和更高解析度。視覺稿需要另由使用者交付、綁定版本、留下對照截圖。

**已確認的精簡 HUD 規則：**
1. 左上 3 個角色資訊框兼任選角按鈕；**不再顯示**左下另一排切換頭像／L1 R1 視覺元件（鍵盤／搖桿仍可有非重複的輔助操控）。
2. 手牌卡片**靠畫面下緣**，隨 hover 向上升，卡牌底緣不得被裁掉；**不放**獨立牌庫／棄牌堆／「手牌 4/8」計數條，但各角色的真實牌區狀態仍在 Domain 存在。
3. 玩家→敵人的固定階段流程不需常駐「行動順序」列表；Reaction 中只在情境面板列出**玩家手動排列的反應佇列**，不可誤當回合順序。
4. 保留隊伍 AP（敵方階段改重點 RP）、個人 HP／MP／狀態、Boss HP／Break／Intent、基本指令、技能詳情、戰鬥紀錄。
5. 「免費換牌」文案不可表示「切換隊員」：是**棄選定一張卡→合法抽一張**，並符合每角每 Player Phase 一次／替代牌預檢與觸發時序；角色切換是另一個純 UI 操作。
6. 不能把 Guard/Protect 誤畫為強制抽牌、把 Last Spell 畫為手牌，或把 Focus Ward 與 HP Barrier 混成同一條護盾。
7. 視覺參考圖若顯示舊版「普通行動數／秒數倒數／手牌數字」，以最新規格與已批准 UX 決策優先。

## 2. 資訊分層與 16:9 版面參考

以下只是**排版起點**，不是硬編碼或特定 Godot Rect，待實際截圖與使用者 review 確認。

| 層級 | 相對區域（1280×720） | 內容 | 規則 |
|---|---|---|---|
| L0 World | 全畫面 | 背景、場景深度、地面、角色和 Boss | 不包含任何 HUD 字或烘焙狀態 |
| L1 World Effects | 戰場區域 | 攻擊、法陣、命中、Break、地面指示 | 不遮住重要 HUD；結果取自事件 |
| L2 HUD top | 約 y=0–105 | 回合／玩家或敵方階段、AP/RP、可見 Boss HP／Break | 資源數字永遠與權威狀態一致 |
| L2 Party | 約 x=16–280；y=110–415 | 3 個角色可點資訊框 | 姓名、HP／MP、狀態，focus 明確 |
| L2 Boss & intent | 約 x=950–1264；y=100–360 | Boss HP／Break／Intent | 可讀但不預先暴露隱藏情報 |
| L2 Commands | 約 x=16–280；y=420–660 | 普通攻擊、解析、道具、免費換牌、Last Spell、結束階段 | 合法狀態／禁用理由可見；無重複切角列 |
| L2 Hand | 水平置中、底部 safe inset；建議底緣約 8–20px | 當前角色真正手牌（最多 8） | 蓋疊／橫向捲動依實際測試；不得露出多餘計數條 |
| L2 Context | 約 x=945–1264；y=375–660 | 技能詳情或戰鬥 Log；可切換／收合 | 避免大面積遮擋 Boss |
| L3 Modal | 視需求覆蓋中央 | Cast Choice、Reaction、Combo、Last Spell、Analyze 詳情、錯誤 | 非必要時不常駐 |

**Z-index 合約：** World < World VFX < HUD < Tooltip < Modal < 確認面板；Hover 卡片可以在手牌容器內浮出，但不能蓋住不可逆確認的主操作。Godot `CanvasLayer`／`Control`／`Container` 共存時要明確界定座標與鼠標事件穿透。

**1280×720 安全區驗證：** 最低 HUD 字體可讀、手牌被選取上浮後完整顯示、左選角不遮住指令、右 Boss 意圖不與 Log 重疊。1920×1080 應等比及容器佈局而非拉伸出模糊框線；21:9 如非正式支援，至少以留邊方案不裁必需資訊。

## 3. Scene Tree（目標，不等於現況）

```text
BattleScreen.tscn (Control root)
├─ WorldViewport (Control / optional SubViewportContainer after ADR)
│  ├─ Background (TextureRect or Sprite2D)
│  ├─ Arena (Node2D)
│  │  ├─ PartyActorSlots (3 × reusable BattleActor)
│  │  ├─ EnemyActorSlots (reusable BattleActor)
│  │  └─ WorldVFX (Node2D)
├─ HUD (CanvasLayer)
│  └─ HUDRoot (Control)
│     ├─ PhaseAndTeamResourceBar
│     ├─ PartyStatusPanel (3 × HeroRosterItem.tscn)
│     ├─ EnemyStatusPanel
│     ├─ EnemyIntentPanel
│     ├─ ActionMenu
│     ├─ HandView (0..8 × CardView)
│     ├─ ActionDetailPanel
│     ├─ BattleLogPanel
│     ├─ TooltipLayer
│     └─ ModalLayer
│         ├─ CastingModeChoice
│         ├─ ReactionQueue
│         ├─ ComboOpportunity
│         └─ LastSpellConfirmation
└─ BattlePresentationAdapter (binds authoritative state/events)
```

不要一開始就替換 `scenes/main.tscn`：現有 `scripts/main.gd` 是大整合式原型，必須先逐步抽離、提供 regression，再決定 Scene 搬遷。Node 名稱與資料結構可因現況調整，必須寫 ADR／Diff 說明。

## 4. 元件規格表

| Component | 公開輸入（建議） | 輸出 Signal（建議） | 顯示狀態／注意事項 |
|---|---|---|---|
| HeroRosterItem | unit_id, display_name_key, portrait, hp/max_hp, mp/max_mp, status_icons, selected, eligible | `hero_selected(unit_id)` | 選取／Hover／Disabled／Concentrating／Exhausted／Incapacitated；不能由顏色單獨表示 |
| PartyStatusPanel | party unit IDs + selected ID | `selection_requested(unit_id)` | 新增角色素材不必改模板；恰 3 上陣不是固定特定三個名字 |
| TeamResourceBar | phase, current AP/RP, AP debt preview if public | none | AP 可因合法效果高於 base6，不應把 6 當硬 cap；RP enemy-only |
| EnemyStatusPanel | enemy_id, name, hp/max_hp, break, public statuses | `enemy_detail_requested(id)` | HP ≠ Break，unknown 數值用合適保密表示 |
| EnemyIntentPanel | public EnemyIntentSnapshot, target visibility | `intent_detail_requested(id)` | 未承諾的行動不要寫成已確定，重抽遵從 Domain |
| HandView | actor_id, ordered CardInstance IDs, legal selection, current phase | `card_selected(instance_id)` / `play_requested(...)` | 0–8 張；在切角後不共享手牌；無底部計數條 |
| CardView | CardInstance + CardDefinition + CardAppearance + preview | hover/drag/select/cancel | card_id≠instance_id；圖、標題、成本、描述都是獨立來源 |
| ActionMenu | ActionAvailability projection + phase | `command_requested(kind)` | 免費換牌需指定手牌 instance；Last Spell 獨立入口 |
| ActionDetailPanel | preview cost/effect/target/reason | confirm/cancel | Preview 不代表已付費；禁用時明確提示原因 |
| ReactionQueue | enemy_action_id, Window ID, queued intents, RP preview | queue/reorder/remove/confirm/pass | 只在合法 Window 出現；Draft 未扣費，Confirm 後 JIT 驗證 |
| BattleLogPanel | translated event view models | filter/expand | 必須能對應 event_seq，不用本地 FPS 決定順序 |

## 5. 卡牌手感（Card UX）

- 卡片的 Normal／Hovered／Selected／Dragging／InvalidDrop／Disabled／Committed／Resolving 狀態要分開。
- Hover 可以上移 12–28 設計單位並略放大，但**實際數值以視覺驗收為準**；不改變卡牌邏輯順序。
- 拖曳到合法目標時提示合法目標與預估成本；不合法時標示具體原因並可退回原位。觸控至少提供「點卡→點目標→確認」替代，不得只依賴 Hover。
- 4 張卡有舒適間距；到 8 張時採精算重疊／適當橫向伸縮／水平捲動，任何卡仍可選、可看完整詳情；不得永遠固定4個 UI Slot。
- 必須支援鼠標、鍵盤與搖桿的焦點切換及取消；焦點移動不能誤提交 Domain 命令。
- 卡牌圖片只是一塊 `TextureRect` artwork，卡框可用 9-slice、費用是 Label／Icon、描述是本地化文字、稀有度／反應標誌由外觀配置。

## 6. 五個視覺情境（與先前概念稿對齊）

**S01 玩家階段主畫面：** 左上角色 A 選取，左下 ActionMenu，底部 A 的 hand，右上 Boss 意圖與 HP/Break；換點角色 B 就顯示 B 的 hand；玩家可同一角色連續合法行動；按 End Phase 後換敵方階段。

**S02 雙模式詠唱：** 持有具 Chantless／Full Chant profile 的 SP → 選模式、預覽兩種差異、成本及時間 → 確認提交。Full Chant 的 Casting Zone 及 Casting Stability／Focus Ward 以情境 HUD 顯示；不能捏造固定多回合或固定 MP 倍數，預設雙模式相同 MP 依 M-D21。

**S03 Enemy Reaction Window：** 畫面進入敵方階段、Boss 宣告可見 EnemyAction，清晰切換共享 RP 與合法反應清單；Guard／Protect 為基本反應，不需抽卡；特殊 SP 需要對應手牌實例；先 Draft 排隊再 Confirm，無秒數倒數，無隱含 auto-pass。佇列不是常駐行動順序面板。

**S04 Combo Opportunity：** 若 Domain 已產生有效機會，主 HUD 提示來源角色、目標及有效合作者，正常出牌 vs 加成效果 preview；Combo 不替代原卡、不自行發明免成本條款；UI 僅根據機會狀態顯示可選確認。

**S05 Last Spell：** 獨立入口開確認視窗，說明 Full Chant、不可玩家取消、合法費用、未釋放 HP 歸0強制失效、正常成功後 Exhausted。確認前可返回；啟動後不可玩家主動 Cancel。分辨「干擾後 Destabilized」與「HP0 導致立即失效」。

**另外必備的非主視覺狀態：** 解析資訊、消耗道具、可被 Protect 的攻擊、Boss Break／Exposed、目標失效、卡牌不能出、牌組不足、無替代卡不可免費換牌、資源不足、詠唱被 Interrupt 退款、勝敗 overlay。每個要有資訊優先級但不將未決算術寫死。

## 7. UI 文字與狀態字典

| 概念 | 繁中建議 | 英文 key / label |
| --- | --- | --- |
| 階段 | 玩家階段／敵方階段 | Player Phase / Enemy Phase |
| 免費換牌 | 免費換牌；請選擇要替換的 1 張卡 | Free Swap |
| 詠唱中 | 詠唱中 | Concentrating |
| 穩定度 | 詠唱穩定度 | Casting Stability |
| 施法守護 | 專注護盾（或核准術語） | Focus Ward |
| HP 盾 | 屏障 | Barrier |
| 最後術式 | 終極法術 | Last Spell |
| 耗竭 | 力竭 | Exhausted |
| 不能行動 | 失能 | Incapacitated |
| 敵方意圖 | 下一意圖 | Next Intent |
| 反應 | 排入／確認反應／略過 | Queue / Confirm / Pass |

詞彙表僅限 UI 翻譯建議；具體功能依正式 `docs/combat/`。請勿在類似「已行動」文案暗示角色每階段只能行動一次。

## 8. 本文件對應來源

- 官方容器／layout: https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html
- 九宮格： https://docs.godotengine.org/en/stable/classes/class_ninepatchrect.html
- Theme type variations：https://docs.godotengine.org/en/stable/tutorials/ui/gui_theme_type_variations.html
- 本專案現有：`scenes/ui/hero_roster_item.tscn`、`scripts/ui/hero_roster_item.gd`、`scripts/ui/card_view.gd`、`scripts/main.gd`

以上為設計計畫，不是執行或畫面驗收證據。
