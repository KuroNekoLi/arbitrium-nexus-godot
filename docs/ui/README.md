# Battle UI / Visual Assets / Animation — Agent Handoff

> **Status: PLANNED / NOT IMPLEMENTED.** 本文件僅為未來 Agent 的工作入口，不授權立即修改遊戲、戰鬥規則、程式碼、場景或美術。概念圖是視覺參考，不是已核准的角色／Boss Canon，也不是功能驗收證據。

## 0. 開工前必讀（依序）

1. 確認唯一 Repository 為 `KuroNekoLi/arbitrium-nexus-godot`，分支為 `master`，每次工作前重新取得 GitHub HEAD。目標 Godot `4.7.2.stable`；勿操作其他舊 Repository。
2. 閱讀 `docs/combat/00_README_COMBAT_RULES_BASELINE_V0_8.md`，再閱讀 `docs/combat/18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md`、`19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md`、`20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md`、`22_PHASE12_AGENT_IMPLEMENTATION_CONTRACT.md`、`23_PHASE3_EXECUTION_PLAN.md`，並查看 `docs/verification/` 的最新證據。
3. 以最新核准決策與相關 ADR 為規則權威；舊版 `README.md`、`docs/COMBAT_RULES_V1.md` 或舊原型程式可能包含歷史機制，**不得**據此覆蓋最新核准規則。若文件衝突，先列出衝突再詢問，不私自決議。
4. 參考圖須由使用者於後續實作任務提供／指定，不能假定概念圖已放進 Repository。

## 1. 已討論的 UI 方向（視覺需求，不改 Domain）

- 橫向 16:9，2.5D/2D 橫向角色與 Boss 戰場，繁體中文優先且預留英文 i18n；字串不可寫死在圖片中。
- 左上方三個可點擊角色頭像：資訊框由單一 reusable scene 實例化，動態呈現角色頭像、名稱、HP／MP／狀態；點選頭像切換目前操控角色。
- **不要**再做畫面左下重複的角色切換列。
- 底部中央只保留可操作的手牌卡片列，位置往下、靠近底緣且留足安全邊距；Hover/選取可上浮。**不要**固定顯示牌庫、棄牌堆、手牌 4/8 計數條。
- 固定玩家階段→敵方階段的流程，主 HUD **不要**常駐「行動順序」清單；複雜行動／Reaction 的先後如需呈現，應使用情境式預覽／佇列，且遵從 Domain Events。
- 保留共享 AP、角色獨立 MP、Boss HP／Break、可見敵方意圖、技能詳情、戰鬥紀錄和必要狀態指示。Casting Stability、Focus Ward、Barrier、Break 各有不同語義，不能共用一條假進度值。
- **「免費換牌」= 某角色每合法 Player Phase 一次，選擇一張手牌棄一抽一（含已核准預檢與事件順序）；不是切換角色。** 切換角色靠頭像選取。
- Last Spell 是獨立特殊槽，不能當一般手牌。Reaction Window 先排隊／確認再依 Domain 規則支付與結算；不設強制秒數倒數。

## 2. 擬採用的可替換 Scene 及資料結構

以下屬可調整的 UI 工程規劃；進入實作階段須先盤點現有 Scene 和 Domain API，優先重用已存在的元件。

| 分區 | 擬定共用元件 | 輸入資料 |
| --- | --- | --- |
| 戰場 | BattleBackground / BattleActor | 場景資源、Actor 外觀資源、狀態／事件 |
| 隊伍 | PartyStatusPanel + HeroRosterItem | actor_id、頭像、HP、MP、狀態、selected |
| 資源列 | TeamResourceBar | team_ap／team_rp、phase |
| 手牌 | HandView + CardView | 該角色當前 hand 的 card_instance_id 與 CardDefinition |
| 敵方 HUD | EnemyStatusPanel / EnemyIntentPanel | enemy_id、HP、Break、可見 intent |
| 指令 | ActionMenu / ActionDetailPanel | 合法 Command 預覽、消耗、目標 |
| 回饋 | BattleLogPanel / CombatFeedback | Domain Events |
| 情境層 | CastingChoice / ReactionQueue / ComboOpportunity / LastSpellConfirm | 只讀預覽與可提交指令 |

使用 `Control`、Containers、Anchors、Theme、`NinePatchRect`／StyleBox 實作介面；背景、角色、Boss 及 VFX 由 `Node2D` 相關元件呈現。視覺層讀取權威 `BattleState`／事件，將玩家操作轉為 Commands，**不能**在 UI、Tween、動畫 callback 內直接修改 HP／AP／MP／牌區或 RNG。

角色模板只寫一次，換角用穩定 ID＋資料更新；卡牌框、成本、文字與美術插畫分離。以 `CardDefinition` 與 `CardInstance` 管理正式規則與牌區；額外的 `CardAppearance`（名稱／圖示／插畫參照）只供視覺渲染，同 ID 的多個實例仍有不同 instance_id。不可依顯示名稱當作戰鬥 ID。

## 3. 美術素材工作流（非直接裁圖實作）

1. 以完整概念圖分析區域與尺寸；列出 Asset Inventory、可再利用素材與缺漏素材。
2. 不以整張概念圖當戰場圖片。背景須與人物、Boss、文字、HUD 分離；角色頭像、戰鬥角色、Boss、SP 插畫、卡框、UI 邊框、圖示、VFX 應各自管理。
3. 可安全使用的區塊才從參考圖萃取；無法乾淨分離時，另製獨立透明素材或重繪，不保留殘留 UI／文字；不要把概念圖的虛構數值／角色名稱視為 Canon。
4. 技能卡只需替換 Artwork Texture 和對應 Resource，卡牌框、名稱、費用、描述、Hover、拖曳交由共用元件渲染。檢查素材權利／授權、解析度、裁切及效能。

## 4. 戰鬥動畫工作流（規劃中）

- 預期共用 `BattleActor` 呈現層，依 Actor 外觀與動畫 Resource 換角色／Boss；視實際素材選用 `AnimationPlayer`、`AnimatedSprite2D`、`Skeleton2D`、Tween、Shader、Particles。
- 支援 idle、attack、cast_start、casting_loop、cast_release、hit、guard、break、incapacitated，以及必要的 Reaction／Last Spell 視覺狀態。動畫清單不是新的 Domain 規則。
- 第一個 Vertical Slice：一名角色的合法普通攻擊演出（前搖→前衝→揮擊→命中回饋→歸位）與一個 Boss 的意圖→Reaction Window→攻擊／中斷→回饋。角色／Boss 動作影格若缺，先盤點再產圖並檢查前後一致性。
- 領域狀態先決定結果，VFX 只能消費事件；動畫播放速度、FPS、特效／倒數都不得影響命中、結算、反應時機或可重播性。

## 5. 未來的執行門檻與驗收

**目前只建立計畫，不執行下列事項。** 後續使用者正式授權實作時，分階段完成，每階段提交真實 Godot 截圖／錄影和測試證據：

1. 盤點現有 `scenes/ui/hero_roster_item.tscn`、`scripts/ui/card_view.gd`、`scripts/main.gd`、`addons/simple_cards`、素材與原型差距；列出最小變更方案。
2. 共用 Theme、UI Scenes、角色／卡牌 Appearance Resource；以多個角色和兩張不同技能圖測試替換，不能沿用卡牌 ID 到 atlas 位置的硬編碼。
3. 視覺素材生產／接入及 HUD 綁定權威狀態；不把舊原型中每角 8 張牌、普通出牌兩次、Reaction 秒數倒數當作新規則。
4. 動畫 Vertical Slice，然後依需求擴充；驗證牌區守恆、AP／MP／RP、Reaction、Replay 與既有 regression。
5. 以 Godot **4.7.2.stable** 實際啟動畫面，截圖比對參考圖，測試中／英文、16:9 安全區、Hover、可用性、效能和 CI；沒執行不宣告 PASS。

## 6. 給未來 Agent 的入口指令

> 在 `KuroNekoLi/arbitrium-nexus-godot` 確認最新 `master` HEAD，先讀 `docs/ui/README.md` 與本文第 0 節列出的現行 Combat SoT、`docs/verification/`，再盤點現有 UI 元件。請把使用者附上的戰鬥概念圖當成視覺參考，不是單張遊戲貼圖。此文件為 PLANNED，未經新指令不做實作；不得重構或改寫核准戰鬥規則。
