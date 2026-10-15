# 06 — Battle HUD Visual-Fidelity Refactor：聊天／Codex 職責與階段門檻

> 2026-10-15｜**PLANNING / CODE NOT MODIFIED / NO NEW GODOT TESTS EXECUTED**。
> 唯一工程庫：`KuroNekoLi/arbitrium-nexus-godot`。
> 本 UI 工作線：`ui/hud-visual-refactor-20261015`；建立自 `master@5103e40a4b95da82f2561b29c2604e9514fd398b`。
> **不可**以 `handoff/p4-lv40-chat-20261015` 覆蓋本分支的 UI 檔案；該 WIP 與此分支的 `battle_hud.gd` 不同，後續須做契約層整合。
> 此文件只分派 UI Presentation 工作，不新增、調整或批准任何 Gameplay Rule、Card Cost、Boss、Balance。

## 0. 已確認的 Source of Truth 與參考

1. 先讀根 `AGENTS.md`、`docs/ui/README.md`、`docs/ui/01_SCREEN_LAYOUT_AND_COMPONENTS.md`、`02_ARCHITECTURE_DATA_INTERACTION.md`、`05_EXECUTION_ROADMAP_ACCEPTANCE.md`，以及 `docs/combat/COMBAT_SPEC_INDEX.md`（若在工作樹存在）和已核准 Combat 規格。
2. UI UX／Architecture／QA 依既有 `.codex/skills/godot-card-rpg-{orchestrator,uiux-engineer}`、`godot-architecture-engineer`、`godot-qa-ci-engineer` 的 `SKILL.md` 與 references 分工；素材由 `godot-resource-library-manager` → `godot-game-asset-pipeline` 審查、選型、匯入。
3. 設計風格：深色奇幻 × 奧術科技、透明暗底與精緻邊框、中文主要＋英文 i18n；**概念圖不代表已核准的角色／技能／數字／資源消耗**。
4. 目標圖須以穩定 PNG（有版本與路徑）提供 Agent；若圖不在 Repo，Codex 需由使用者提供引用，不得假稱已比對。
5. 保留既有可執行架構 `BattleController → M5 Domain → PresentationAdapter → BattleHUD/AnimationDirector`；不可從 UI 自行扣 AP/MP/HP、決定 Reaction/Outcome 或新增限制。

## 1. 目前真實實作（master 基線）

- `scenes/battle/battle_screen.tscn`：`BattleScreen / Design(1280×720) / Background / Arena(A,B,C,Boss) / HUD`。
- `scripts/battle/ui/battle_hud.gd`：約 280 行，動態建立 TopBar、Conditions、三人 Party、Commands、EnemyStatus、Context、HandView、TargetButtons、ReactionQueue；含 `render()`、`set_targets()` 與扇形手牌排版。
- `scenes/ui/hero_roster_item.tscn` 與 `scripts/ui/hero_roster_item.gd`：已有可選角、Portrait、HP/MP 的共用元件，**重用不重造**。
- `scripts/battle/ui/battle_card_view.gd`：現有 SimpleCards 卡片大小約 164×218，有 Hover、Drag、Tween，外觀為 `PanelContainer`／`StyleBoxFlat`。
- `resources/ui/battle_theme.tres`：目前是 NotoSansTC、`StyleBoxFlat` 為主的簡易 Theme。
- `addons/simple_cards/shape/premade_shapes/arc_shape.gd`：已有手牌弧形佈局；保留既有可重播的 interaction，而不是重新實作卡牌排序。
- `project.godot`：1280×720 `canvas_items`、Compatibility Renderer；現有 `tests/test_p4_hud.gd`、`tests/test_p4_scene.gd`、`tests/test_p4_input_capture.gd` 與 `outputs/p4_3_*.png` 可作基線。
- 分支差異：`battle_hud.gd` 與 `P4_DELIVERY_STATUS.md` 在 Lv40 handoff WIP 和 master 間**不同**；不要無差別 cherry-pick。

## 2. 依任務性質分工

| ID | 工作 | 聊天（ChatGPT）可直接交付 | Codex Agent 實作／驗證 | 主要檔案與輸出 |
|---|---|---|---|---|
| A01 | Visual Target / Pixel Space / Layout Contract | 16:9 參考圖校稿、方位/安全區/優先級/狀態矩陣、UI 規格文件 | 用真 Godot 截圖對照尺寸、檢測 Control Rect 與裁切 | `docs/ui/`；`outputs/` |
| A02 | Design Tokens / Theme 規劃 | 色彩、字體階層、間距、Panel/Button/Card States、NinePatch 使用規範及 Theme 檔草案 | Theme 實際接線，雙語及多尺寸渲染；重大視覺系統採用先提決策報告 | `resources/ui/battle_theme.tres`、UI assets |
| A03 | UI Component Ownership Contract | 各元件輸入 ViewModel／輸出 Signal、拆分依賴圖、公開 API 不變量；可在 GitHub 提供程式碼草案 | 拆 `.tscn`／`.gd`、連接、編譯、交互驗證與 screenshot | `scripts/battle/ui/`、`scenes/battle/ui/` |
| A04 | Party/Boss/Intent 外觀 | 資訊層級、精簡形狀、圖框/HP/Break/Intent 視覺稿 | 元件化角色、Boss 和 Intent，對真投影資料刷新 | roster scene/script、Boss/Intent scenes |
| A05 | Commands / Details / Log | 面板尺寸、互動焦點、情境式資訊優先序、i18n key 審查 | 拆分 Context，保留既有確認／取消／詳細資訊／紀錄與 Focus | `battle_hud.gd` 與新 reusable controls |
| A06 | Card UI Design | 卡框、卡成本/插畫/文字/可用性/Selected/Hover/Drag 的視覺與 motion spec | `BattleCardView` + `HandView` 整合；0/1/4/8 張碰撞與旋轉邊界測試 | `battle_card_view.gd`、HandView |
| A07 | Casting / Reaction / Combo / Last Spell | 情境面板 storyboard、已核准規格比對、可操作狀態矩陣 | Modal node、鍵盤／滑鼠 input、Reaction 手動確認、無倒數、結算 UI 同步 | context overlays |
| A08 | Visual Asset Production | 指定單張圖片、Icon/Frame 風格參考及重要候選決策報告 | 素材審權、切圖/九宮格/尺寸/import/manifest、真實渲染驗收 | assets、manifest、resources |
| A09 | Quality & Regression | 截圖差異審查、code review、缺陷優先級與 QA Case Spec | Godot4.7.2 headless / GUI、CI 原始 log、Action 回歸、真場景截圖和錯誤修正 | existing `tests/test_p4_*.gd`、verification |
| A10 | GitHub Documentation | 可直接更新設計文件、設計決策、Agent 任務契約（GitHub Connector 有權限時） | 以實際驗證後輸出的版本、狀態、證據更新 Engineering Notes | `docs/ui/`、`docs/verification/ui/` |

**聊天可直接寫 GitHub 文件／檢查程式／撰寫隔離的 GDScript 草案，但無本地 Godot 執行證據時不得宣告 scene/GUI 已驗證。**

## 3. 建議的可重用 Scene Component（目標，不是現存檔案）

```text
BattleScreen/Design/HUD (BattleHUD: composition, rendering routing, public signals)
├── TeamPhaseHeader
├── PartyStatusPanel (reuse 3 HeroRosterItem)
├── CommandMenu
├── HandView (0..8 BattleCardView via SimpleCards ArcShape)
├── BossStatusPanel
├── EnemyIntentPanel
├── ActionDetailsPanel
├── BattleLogPanel
├── TargetHitRegion
└── OverlayRoot
    ├── CastingModeChoice
    ├── ReactionQueue
    ├── ComboOpportunity
    ├── LastSpellConfirmation
    └── BattleResult
```

每個 Component 須只接受 Presentation/ViewModel 的資料並發出意圖 Signal；`BattleHUD` 保留對外相容：

- Signals：`actor_requested`、`card_requested`、`card_released`、`command_requested`、`target_requested`、`confirm_requested`、`cancel_requested`、`locale_requested`。
- 方法：`render(projection, actor, cards, reaction_choices)`、`set_targets(ids)`。
- 抽離階段不可丟失：selected actor、CardInstanceID、Pointer drop、合法性 preview、Reaction draft/reorder/confirm/pass、Modal focus、Keyboard、Localization、Save Replay。
- 使用已有 `HeroRosterItem`、`BattleCardView`、SimpleCards 弧形排版、Adapter，不直接讓 Components 依賴 M5 Domain。

## 4. 已確認的視覺需求（避免因重構倒退）

1. 左側三位角色資訊框本身可點選切角；**不要**第二排切角頭像。
2. 角色下方只有真正的可視手牌；**不顯示**獨立「手牌 4/8」、牌庫、棄牌、常駐卡區狀態工具列。
3. 手牌在畫面**下緣附近**呈弧形，保留卡片完整底緣，Selected/Hover 抬高＋輕放大＋外光，不擠壓戰場。
4. 不顯示固定玩家／敵人的常駐「行動順序」；但 **Reaction Queue 的排序不可刪除**。
5. 左上明確 AP/RP，右上 Boss HP/Break/公開 Intent，右側情境詳情與精簡 Log；重要 action 不被漂亮背景蓋過。
6. 免費換牌是棄選定的一張手牌再合法抽牌；不是「切換其他隊伍成員」。
7. 支援繁中與英文，不硬編碼 player-facing 文案；真正 Actor/Skill/Boss ID 與 Cost 由 Domain/資源映射，非概念圖虛構。
8. 不使用 AI 生成的整張 mockup 當作不可互動的 HUD 底圖。

## 5. 推進次序與誰負責

- **V0 — ChatGPT / SPEC ONLY**：確定 visual target version、layout、元件切分與 I/O 契約、可重用資產候選、QA matrix；此文件屬第一步。
- **V1 — Codex / STRUCTURAL SPLIT**：只拆 `BattleHUD` 的 compositional responsibility，不引入新視覺或玩法；須讓原 `tests/test_p4_hud.gd`、`test_p4_scene.gd`、`test_p4_input_capture.gd` 有可比對回歸，並保持 Signal/Method API。
- **V2 — Codex / LAYOUT**：按最終 PNG 調整 1280×720 語義座標與 1920×1080，先保證手牌、角色/指令與 Boss/詳細資料無重疊；可使用正常的 `Control` anchor、Container、Scene 可維護元件。
- **V3 — ChatGPT DESIGN + Codex INTEGRATION**：Theme、卡框、選中/禁用態、控件素材及視覺動效。對重大外觀選型先看決策報告；不擅自覆蓋作者未核准內容。
- **V4 — Codex / ADVANCED MODALS**：Casting、Reaction、Combo、Last Spell 可操作介面，按核准 Domain 投影分別測試。
- **V5 — QA + ChatGPT REVIEW**：真實遊戲 1280×720／1920×1080；0／1／4／8 Cards；中英、AP/RP、Concentration/Exhausted、Reaction 佇列、Boss Intent、Combo、Last Spell、Win/Lose；對比圖＋缺陷表＋原始測試／CI 連結。

**每個 V 應單獨交付與審查，未驗證不得標 VERIFIED。所有 V 的已確認 UI 重大風格變更需先讓使用者核准。**

## 6. Worktree、交接與合併保護

- 此分支唯一基準為 master P4.3；Lv40 `handoff/p4-lv40-chat-20261015` 是 WIP，**禁止直接合併／整檔搬移以繞過 P4.4 gate**。
- 若開發 Agent 同時工作，按 Component file ownership 併行；`battle_hud.gd`、`battle_theme.tres`、`battle_screen.tscn`、translations、project.godot 採單一整合者。
- 現有 P4.4 GUI 測試第三輪 14/16（兩筆 PNG save 失敗）；不能將切新分支當成新的測試額度或取得 VERIFICATION。須遵循根／QA Skill 的限制及使用者追加授權。
- 合併前比較 master/工作分支/最新 Lv40 改動的 HUD public contract 與動態 Scene；以逐項可回滾 patch 為主，保留 Domain hash／Replay 與現有已核准測試結果。
- 此 UI 工作線從不修改 `scripts/domain/`、戰鬥規格已核准規則、平衡配置、Lv40 模組；不能用動畫完成時刻控制 Domain 付款／傷害。
