# 02 — UI 資料綁定、互動流程、i18n 與狀態一致性契約

> **DESIGN ONLY / NOT IMPLEMENTED**。本文件不是新的遊戲規則；屬可供後續 Godot UI Agent 落地的 presentation architecture。設計資料欄位只代表 *建議*，不得宣稱已存在於現有 API。

## 0. 真實程式現況與遷移限制（檢視日期：2026-10-15）

- Godot 專案：`project.godot` 使用 1280×720、`canvas_items` stretch、Compatibility renderer；`scenes/main.tscn` 指向 `scripts/main.gd`。
- `scenes/ui/hero_roster_item.tscn` 已有一個可點擊 Button 型元件；`scripts/ui/hero_roster_item.gd` 已提供 `configure(id, display_name, portrait_texture, accent_color)`、`update_status(hp,max_hp,mana,max_mana,hand_count)`、`set_selected(selected)`、`hero_selected(hero_id)`。**它已可重用，不要刪掉重建。**
- `scripts/ui/card_view.gd` 繼承 `addons/simple_cards/card/card.gd`，具 hover/drag／自行繪製卡面；美術引用 `assets/card_art_atlas.png`，藉由 `_card_art_index(card_id)` 決定圖集區域。目前不是 per-card Artwork Resource。
- `addons/simple_cards/plugin.cfg` 標示 `2.13`；進行版號與 upstream 授權／相容性盤點後再決定是否需升級，**不為了新規劃直接替換插件**。
- `scripts/main.gd` 仍含舊原型的 UI 組裝、遊戲回合／牌組綁定與 Reaction 機制；`scripts/ui/deck_builder.gd` 顯示舊 8 張配置，這與新核准 12 張不同。
- 有新的 `scripts/domain/` 與 `docs/verification/` Phase 3 工程文件；新的 HUD 實作必須經過工程實查，確定哪個 Domain 執行路徑才是權威。**不能一邊呈現新版 HUD，一邊暗中操縱舊版 BattleState。**
- 現有角色素材 `assets/kleya_atlas.png`、`nova_atlas.png`、`yora_atlas.png` 和 `assets/portraits/`；目前 UI 原型的角色名稱／Atlas 映射可能與最終 Canon 不一致，必須驗證 Asset Manifest。

## 1. 建議四層分離（重點）

```text
Authoritative Domain (headless, deterministic)
  BattleState, CardDefinition, CardInstance, Commands, DomainEvents
      ↓ snapshot/event (immutable contract; stable IDs)
BattlePresentationAdapter / ViewModel projector
  transforms State → PartyVM/HandVM/EnemyVM/ActionAvailability
  transforms Events → AnimationCue/LogVM
      ↓ passive read models / intents
Godot Reusable UI Scenes (Control + CanvasLayer)
  PartyStatusItem, HandView, CardView, Boss/Intent, Menus, Modals
      ↓ user intents (not mutation)
BattleController → Domain Command Validator → result/events
```

不可從 `CardView` 的被點擊狀態直接寫 `hp-=...`、`team_ap-=...`、`hand.erase(...)`；UI 不控制 domain RNG，也不決定勝敗。多場景切換時所有 UI Scene 是可銷毀／重建的 presentation；Stable IDs、戰鬥狀態不能是 Node reference。

## 2. 資料模型對應（方案草案）

| 類型 | 權威欄位 | UI 顯示／責任 |
| --- | --- | --- |
| Combatant | unit_id, character_id, variant_id, hp/max_hp, mp/max_mp, active_statuses, life_state | 繁中名稱與肖像由 Appearance lookup；HP/MP 依快照 |
| BattleState | round, phase, team_ap, team_rp, selected?（本地 UI）, active_intents | 階段標題、資源、可見意圖 |
| CardDefinition | card_id, tags, costs/profiles, reaction trigger, effects | 說明與合法預覽來源 |
| CardInstance | instance_id, owner_unit_id, card_id, zone, modifiers | 每張可拖的卡的唯一身份，手牌列表的 Key |
| CastingInstance | casting_id, caster_id, resolves_at, stability, focus_ward | 詠唱區小卡與施法狀態；視覺中不是第二份牌 |
| ComboOpportunity | id, source, eligible actors/tags, expires_at | Combo 情境式提示 |
| Domain Event | seq, action_id, type, actor, targets, deltas | Battle Log、VFX、傷害文字（只播一次） |
| EnemyIntent | intent id, enemy id, target visibility, commitment | UI 不能自行亂猜下一招 |

`CharacterAppearance` 和 `CardAppearance` 是**新增的 presentation-only Resource 提案**：

```text
CharacterAppearance (.tres; proposal)
  character_id, variant_id, name_i18n_key,
  portrait: Texture2D, battle_art/sprite_frames, tint, animation_profile
CardAppearance (.tres; proposal)
  card_id, name_i18n_key, description_i18n_key,
  art: Texture2D, frame_style_key, icon: Texture2D
EnemyAppearance (.tres; proposal)
  enemy_id, name_i18n_key, battle_art, portrait, animation_profile
```

名字是 i18n key，不是 Image 裡的字；圖片 Resource 不能決定 AP／MP／傷害。Variant 改變外觀或卡牌資格時，正式角色與牌組限制仍由 Domain 重新檢驗。

### 動態換角的正確流程

1. 點左上 `HeroRosterItem(unit_id)` → 發出 `selection_requested(unit_id)`。
2. UI adapter 判定該角色是否存在、目前可否選取，更新 `selected_unit_id`（純視覺焦點）。
3. 取得**該角色** `hand[owner_unit_id]` 的 CardInstance 列表，不複製其他角色牌。
4. `HandView` 以 instance_id 做 diff，載入 Appearance、成本與合法 preview；當前耗竭或詠唱中，依正式規則顯示不可主動行動理由。
5. 只有玩家真正選擇合法指令時才交給 Domain；切換頭像本身不消耗回合資源或擲骰。

### 動態換卡圖片的正確流程

1. Designer 在 Assets Manifest 登記已核准圖片與來源；
2. CardAppearance 的 `art` 指到獨立圖片，`card_id` 與既有 CardDefinition 對應；
3. `CardView` 將圖顯示在 `TextureRect`，卡框、成本、文字另由 Theme/Labels/Definition 組合；
4. 牌區流轉仍使用 `instance_id`，同名不同實例不可因替換圖片而合併；
5. 缺圖片時顯示統一 Placeholder 與可診斷警告，不能因資產缺漏阻擋 Domain Replay。

## 3. UI Command / Preview 契約

**只讀預覽**應由與正式命令相同的 validator/resolver 提供，至少回：
- `legal`、`reason_code`、`actor_id`、`card_instance_id`（如有）；
- `target_candidates`、`cost_preview(AP/MP/RP)`；
- `visible_effect_summary`、`casting_mode_profiles`；
- `state_version / battle_version`（用於確認前重新檢查）。
- 不可從顏色判定合法性；不合法 hover 仍可顯示 tooltip，但不能 Submit。

例子（**僅示意，不是現有序列化格式**）：

```json
{
  "request": "PreviewAction",
  "actor_id": "unit_003",
  "card_instance_id": "card_instance_073",
  "target_ids": ["enemy_001"],
  "mode": "CHANTLESS",
  "expected_state_version": 52
}
```

提交採用唯一 `command_id`。收到成功／拒絕事件後才更新資源；UI loading 狀態可鎖重複 Submit，但不得把 loading 看成已成功。Rejected 不得暗扣資源／抽卡／偽造 log。從領域返回事件完成後播放動畫，動畫 callback 不應重新提交原命令。

## 4. 各操作的最小狀態機

**手牌選擇：**
`Idle → Hover/Focus → Selected → Targeting → Preview → Confirm → Submitted → Resolving → Idle`。
中途可以 Cancel 返回上一狀態；失敗從 `Targeting/Confirm` 回到可操作狀態，並顯示原因。拖曳放下到非法位置不會改變牌區。解析／道具／LastSpell 各用獨立流程，不可偽造 hand card。

**雙模式詠唱：**
`CardSelected → Choose(Chantless | Full Chant) → PreviewCostsAndResolution → Submit → DomainResult`。
即時版可當回合完成；Full Chant 提交後由 Domain 管理 CastingInstance 與何時 due，UI只顯示專注／Focus Ward／Stability；預設同 MP cost，不能因畫面效果擅自變更。

**Reaction：**
`EnemyActionCommitted → WindowOpen → DraftQueue/Modify/Reorder → Confirm or Pass → JIT Results → WindowClosed`。
Draft 排隊不扣 RP/MP／不移手牌；同一角色同 Window 最多成功一次；Guard/Protect 無需 CardInstance；被早一筆反應取消的後續反應依正式規則 SKIPPED 而不扣費／移卡。**無倒數與無隱形自動 Pass**。

**免費換牌：**
`SelectActor → FreeSwapButton → ChooseOneHandInstance → DomainPreflight → Confirm → Result`。
不顯示「切換角色」，不以 UI 本地邏輯直接改 Hand。Preflight 缺替代卡→顯示原因且不耗次數；成功或觸發改變替代牌池等情況依真實事件刷新。

**Combo：** Domain 建立有效 Opportunity 後 UI 才顯示，並以角色／卡／目標對應；比較正常模式與 combo preview，但不自動把出牌改為 combo。

**Last Spell：** 獨立入口→合法預覽→不可逆確認→提交；提交後不提供 Cancel；玩家看到「成功釋放後 Exhausted、HP0 在釋放前強制失效」，干擾／延後提示不等於立即死亡。

## 5. 狀態呈現規則（避免誤解）

- 角色同時擁有多狀態時要有**主要狀態**與**附加 icon**（例如 Concentrating + Barrier），不以一個 enum 清空其他獨立狀態。
- Incapacitated ≠ Exhausted；前者 HP0 不可正常行動，後者是 Last Spell 成功後特殊耗竭。圖示不同、tooltip 不同；不可用 `dead` 通用字眼掩蓋。
- Boss Break 是 Boss 專屬累積／破綻線索，不是施法穩定度；Focus Ward 保護 Casting Stability，Barrier 處理 HP 傷害。
- 不允許將世界 VFX 特效進度直接轉成 Domain Time。若 CombatLog 事件大量產生，視覺可合併播放，但日誌仍保留全部正式序列號。

## 6. Translation & Accessibility

- UI 所有使用者可見文字皆用 i18n key，至少 `zh_TW` 和 `en`；包括數字單位、狀態、暫停、Tooltip、錯誤、卡牌效果描述、指令確認。
- 名稱由 Resource 的 key 查詢翻譯；輸出不能預先把中英文字烘焙在美術圖片。翻譯後文字伸縮測試須涵蓋英文較長字串。
- 顏色標示同時搭配 icon、文字與 tooltip；焦點輪廓不被 glow 取代；可見焦點（keyboard/gamepad）、Esc/取消、雙擊防重、screen edge safe-area 都要驗證。
- 1280×720 / 1920×1080 的最低文字大小與截斷策略以清晰閱讀為目標；建議正文不小於 16 **設計像素**、成本關鍵資訊 18–24，實際透過整體 viewport scaling 與人工測試校準，不是已批准的硬性美術數值。
- 選取卡牌與禁用原因應能用鍵盤獨立操作；不要求玩家辨認只有紅／綠的差異；按鍵提示依輸入來源決定，不常駐重複切角列。

## 7. Integration / 風險

1. Godot `Container` 會控制子 Control 的 positioning；如果做 hover 上移或底部靠齊，需設置可動畫的獨立包裹節點或正確的佈局計算，避免 `Container` 下一幀覆寫位置。
2. CardView 既有 `_draw()` 直接 `draw_string` 與 atlas index，國際化／長字可讀性較弱；可以逐步抽為 `TextureRect`、`Label` 和 Theme，而非一次重寫操作系統。
3. `addons/simple_cards` 是已集成依賴；分層時保留拖曳與 Hover 行為且確認版本差異，不自動引進重複卡牌 framework。
4. `scripts/main.gd` 的舊原型與 Phase3 Domain 工程平行存在；正式施工前須先追出 active authoritative code path，避免把 HUD 直接連到錯誤的引擎。

## 8. 參考

- `docs/combat/04_DECK_DRAW_CARD_RULES.md`、`07_REACTIONS_PROTECTION.md`、`12_ENGINE_ARCHITECTURE_EVENTS.md`、`20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md`
- https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html
- https://docs.godotengine.org/en/stable/tutorials/ui/gui_theme_type_variations.html
- https://docs.godotengine.org/en/stable/tutorials/animation/introduction.html
