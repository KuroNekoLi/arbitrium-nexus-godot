# 05 — UI 與動畫實作路線、Agent 分工、驗收矩陣與交付條件

> **PLANNED / NO CODE OR ARTWORK IMPORTED**。本文件是**下一次使用者授權施工時**的交接計畫，不代表當前版本任何 UI Phase 已實施或通過 Godot 測試。具體成本、動畫資產與優先順序可經用戶確認後調整，但不修改已核准 Domain。

## 0. 與 Domain Phase 3 的關係

目前 Godot Repo 有既有的 MVP UI、`docs/verification/PH3_M1...` 到 M4 工程報告、`scripts/domain/` 和 UI 既有原型；未來開始時必須**重新查 master HEAD 和最新 CI**，不得僅依本計畫的編寫日期推測 M4/M5 狀態。

UI 專案是 **Presentation Track**，不是替代 Domain 的另一套戰鬥規則。若 M5 的特定技能效果／狀態還沒有 authoritative runtime，對應畫面只能用**已標示為 prototype fixture 的假資料**做 mock UI；不得把 mock 結果說成真實戰鬥功能，或為了讓 UI 可玩而自行填補尚未批准的算術。

既有本專案 `.codex/skills/` 分工：
- `godot-card-rpg-orchestrator`：協調依賴、里程碑、範圍和 evidence；
- `godot-card-rpg-uiux-engineer`：HUD/卡牌/使用者操作/i18n；
- `godot-game-asset-pipeline`：素材原稿、授權 manifest、匯入與壓縮；
- `godot-2-5d-rendering-engineer`：Actor、動畫、鏡頭與 VFX；
- `godot-architecture-engineer`：Presentation adapter／分層；
- `godot-qa-ci-engineer`：Godot CLI、Screenshot QA、CI、回歸與 Replay。

每個 Agent 都先讀自身 Skill `SKILL.md`、references、`docs/combat/` 和本目錄入口，不另生平行架構。

## 1. 未來的八個工作包（每包皆有退出 Gate）

| Package | 目標 | 必交工件 | Exit gate |
| --- | --- | --- | --- |
| **UI-G0 Current State & Reference Audit** | 最新 master、Godot 版本、Domain gate、現有 UI／資產、概念圖版號、環境 | 差異盤點、功能／素材矩陣、風險、實際測試命令 | G0 審查通過；未知物均標 BLOCKED |
| **UI-G1 Visual Foundation** | Color/Type/Theme、9-slice、Layout 與 safe-area | `Theme`、通用 Panel／Button styles、1280×720 mock | 同一 Theme 不必手調每個 Node；不裁字 |
| **UI-G2 Party & Cards Reuse** | 角色資訊、換角、卡牌圖文分離、手牌居底 | `HeroRosterItem`、`CardAppearance`、`HandView` 組件 | 以不同角色和多張不同圖片驗證可替換性 |
| **UI-G3 Core HUD & Authority Binding** | AP/RP、Boss HP/Break、Intent、Menu、Log、ActionDetail | Scene + Adapter + mock/real Domain 綁定證據 | 有效 action 和拒絕都與 Domain 事件一致 |
| **UI-G4 Advanced Context Overlays** | CastChoice、ReactionQueue、Combo、LastSpell；包含不同狀態 | 4 個情境 UI Scenes 和狀態矩陣 | 不擅自扣費、無 Reaction 倒數、不可逆確認正確 |
| **UI-G5 Art Integration** | 角色／Boss／卡圖／背景分離、優化與版權台帳 | Asset Manifest、Credits、Import 設定、可換美術截圖 | alpha／裁切／一致性／license 檢查通過 |
| **UI-G6 Actor/VFX Vertical Slice** | 玩家攻擊＋Boss 一個合法 Action／Reaction 流 | Actor Animation Resources、VFX、影片、事件對照 | 动畫 skip/60fps/低fps 不改 outcome |
| **UI-G7 Polish & Playtest** | 雙語、滑鼠/鍵盤/手把、響應式、無障礙、效能 | 兩語截图、操作紀錄、可玩 Demo、差異追蹤 | 不會誤判成本/目標、主戰鬥體驗可理解 |

**每次只執行使用者核准的一個工作包**。沒有 G0 不能直接進入 Asset 自動大量生成；不將 P2 的自由鏡頭與 3D Path 當成先決條件。

## 2. G0：必須做的現況對照與 Blocker 註冊

1. `git rev-parse HEAD` + tree cleanliness + `project.godot` 真實引擎設定；
2. Godot binary 的絕對路徑與 `--version`，與目標 Godot 4.7.2.stable 是否一致；
3. Godot main scene；`scripts/main.gd` 現有 UI 的位置、狀態來源和已實作功能；
4. `scenes/ui/hero_roster_item.tscn`、`scripts/ui/card_view.gd`、`addons/simple_cards` version；
5. Domain `scripts/domain/` 與 M1～M5 交付是否能提供官方 UI adapter，仍未完成的功能獨立列 BLOCKED；
6. `assets/` 全量素材 Manifest、Godot 的 UID／license 存在性；
7. 使用者最新提供的 16:9 **視覺參考圖**：原檔、版本、需修改區域紀錄與是否屬最終批准 UI；
8. `docs/verification/` 最新報告、GitHub Action 真正綠燈／失敗及其主因；
9. 開新 UI 分支或 PR 的策略由使用者／專案工作流確定；不得不經請求對非本次任務的內容做 destructive rewrite。

## 3. Suggested File Architecture（只是假想目標樹）

```text
scenes/battle/
  battle_screen.tscn
  actors/battle_actor.tscn
  ui/
    party_status_panel.tscn
    hero_roster_item.tscn
    team_resource_bar.tscn
    enemy_status_panel.tscn
    enemy_intent_panel.tscn
    hand_view.tscn
    card_view.tscn
    action_menu.tscn
    action_detail_panel.tscn
    battle_log_panel.tscn
    overlays/
      casting_mode_choice.tscn
      reaction_queue.tscn
      combo_opportunity.tscn
      last_spell_confirmation.tscn
scripts/battle/presentation/
  battle_presenter.gd
  battle_ui_adapter.gd
  combat_animation_director.gd
resources/ui/
  battle_theme.tres
  appearances/{characters,cards,enemies}/
assets/battle/
  backgrounds/
  actor_portraits/
  actor_sprites/
  enemies/
  card_art/
  card_frames/
  effects/
  ui_icons/
  fonts/
docs/verification/ui/
  UI_G0_AUDIT.md
  UI_Gx_ENGINEERING_NOTE.md
  UI_Gx_ACCEPTANCE_REPORT.md
```

勿因本樹與現有檔名不一致便無條件重命名；遷移以最小 diff 與連續 CI 為原則。考慮既有 `scenes/ui/hero_roster_item.tscn` 是否直接保留原位置而非重複造一份。

## 4. Design Tokens（**Proposed, not approved final colors**）

| Token 類型 | 草案 | 用途 |
|---|---|---|
| Color — panel base | 深海軍藍／暗炭紫，中性高對比 | 卡片與 HUD 底板 |
| Color — interactive focus | 高亮青藍或金色輪廓 + icon | 選角、卡牌 Hover、焦點 |
| Color — danger | 紅／琥珀 + 警告圖示 | Boss Intent、非法指令 |
| Color — resources | HP 紅／綠系、MP 藍、AP 青金、RP 紫 | 需搭配文字和 icon，不能單靠顏色辨識 |
| Border family | Kenney Fantasy UI Borders／StyleBox/NinePatch | 同一邊框家族與九宮格比例 |
| Typography | 中文主字型 Noto TC 候選 + 清晰的數字字型 | 一律由 Theme 管理與授權紀錄 |
| Spacing | 4/8/12/16/24 設計單位為初期 token | 隨 viewport scale／實際 QA 調整 |
| Motion | fast hover / medium card / long cinematic | 全部可設定；不得變成 Domain 秒數 |

數值色碼、動畫 ms、關鍵字體大小、位置和素材風格仍由 UI-G1 實際截圖審核；未經用戶同意不固定為 Canon。

## 5. UI / UX Acceptance Matrix（測試規格，不是測試結果）

### Player phase / card / party

| ID | Setup / 操作 | Expected |
|---|---|---|
| UI-P01 | 三名角色各有不同手牌→點頭像切換 | 只更新 selected UI／對應 hand，無 RP/AP/MP 命令 |
| UI-P02 | 手牌4張→hover 任一卡 | 卡片上浮、可讀、可取消；底部完整可見 |
| UI-P03 | 手牌8張→滑鼠/鍵盤逐張選取 | 8 張皆可被選取，沒有重複 instance 或幽靈卡 |
| UI-P04 | 指定一張卡 artwork 換新圖 | 同模板改畫面，不改 card_id、費用、效果 |
| UI-P05 | 顯示 0、3、4、8 張手牌 | 無多餘計數條；操作與空狀態清晰 |
| UI-P06 | 卡牌非法目標／AP不足 | 不可提交＋具體原因；抽牌與牌區原狀 |
| UI-P07 | 合法免費換牌，存在替代牌 | 選卡→預檢→Confirm→Domain events 後 UI 正確更新 |
| UI-P08 | 免費換牌沒有合法替代牌 | 顯示 disabled reason；不棄不抽不扣使用次數 |
| UI-P09 | 角色狀態為 Concentrating/Exhausted/Incapacitated | 顯示不同 icon/禁用規則；不能假裝死亡等於耗竭 |
| UI-P10 | 玩家 AP 多於6（合法 buff） | 正確顯示 current AP，不以固定長條裁掉數值 |
| UI-P11 | 點 Last Spell 而非卡牌 | 獨立操作，手牌不出現虛構 Last Spell 卡 |
| UI-P12 | 切換角色再切回 | card_instance_id/選取/tooltip 不與他角混淆 |

### Casting / Reaction / Combo / Boss / End

| ID | Setup / 操作 | Expected |
|---|---|---|
| UI-C01 | 同卡兩種詠唱模式 | 唯一 CardInstance 的模式切換，MP 預設一致，Full 延後 |
| UI-C02 | Full Chant 開始 | Concentrating、Casting Zone、Stability、Ward 分開顯示 |
| UI-C03 | Casting Interrupted | 即時依事件更新退款／狀態，UI 不自主猜 50% |
| UI-R01 | 敵方有合法 Reaction Window | 可以排隊／刪除／重排、Confirm/Pass，沒有秒數倒數 |
| UI-R02 | Guard/Protect | 不需要手牌有「防禦」卡 |
| UI-R03 | 特殊反應需 CardInstance | 只顯示合法的本角色反應卡，不跨角色使用 |
| UI-R04 | 多筆 Draft→尚未確認 | AP/RP/MP 與牌區不變 |
| UI-R05 | 已排隊反應 JIT 失效 | 依 Domain `SKIPPED` 展示，未非法扣費 |
| UI-CMB01 | Combo 機會有效 | 顯示可選 partner／目標／附加效果、不得自動改 action |
| UI-CMB02 | Combo 已過期 | 不可確認，提示 expired，Domain 狀態不變 |
| UI-L01 | Last Spell 預提交確認 | 顯示不可逆風險，取消只在提交前 |
| UI-L02 | Last Spell 中 HP0 | 強制失效並移除待釋放 cue，無成功傷害演出 |
| UI-L03 | Last Spell 成功 | Exhausted 獨立圖示、行動禁用，非死亡 |
| UI-B01 | Boss Break + Casting Stability 同時顯示 | 清楚分開，沒有混用進度條 |
| UI-B02 | Boss Intent target 變化／Protect 轉向 | 意圖及實際結果與 event 一致 |
| UI-B03 | 全隊失能/勝利結算 | 依 Domain `BattleOutcome` 彈窗，不以 UI 自判 |

### Localization / inputs / presentation

| ID | Setup / 操作 | Expected |
|---|---|---|
| UI-I01 | 遊戲中切換 zh_TW→en→zh_TW | HUD、卡名／描述／錯誤即時改語，無硬編碼字 |
| UI-I02 | 1280×720、1920×1080 | 沒有被裁掉的卡牌與按鈕；無常駐 turn-order/count |
| UI-I03 | 只用鍵盤/手把 | 可選角色、選卡、預覽、確認、返回；焦點明顯 |
| UI-I04 | 無 Hover 的 touch 模擬 | 點卡→點目標→確認可完成相同行動 |
| UI-I05 | 連按 Confirm 或重複拖卡 | Domain 至多一次合法接受，不重扣費 |
| UI-I06 | VFX skip / low FPS | 同 seed 同 CommandTape 的 Domain events/outcome hashes 一致 |
| UI-I07 | 離開戰鬥再重進 | Signals 無重複訂閱、卡牌場景不殘留 |
| UI-I08 | 所需美術缺圖 | Placeholder 降級可用，必要文字可讀，有診斷記錄 |
| UI-I09 | 已修改素材（逐筆授權清單） | CREDITS/Manifest 正確，沒有 L3 未授權資產 |
| UI-I10 | 色彩與高對比設定 | 目標／禁用／結果不僅靠顏色理解 |

上述 test case 必須記錄 Screenshot + log + source commit + binary version + test result；規格本身不證明驗收通過。

## 6. 截圖與視覺品質審核

每個 UI-G 的執行必須提供：
- **Reference**：使用者認可概念圖或局部標記（包括底部手牌下移、刪除冗餘列）；
- **Actual**：*真正 Godot 運行*同解析度、相同 UI 狀態的 screenshot，標註 Godot version、render mode、commit SHA；
- **Diff**：位置、尺寸、可讀性、素材一致性、動畫剪裁、圖層遮擋、負載；
- **Test**：實際 CLI/GUI 指令、退出碼、完整測試紀錄，CI run URL（若有）。
不能用 AI 重新生成的一張「看似遊戲畫面」當成實際運行證據；不可宣稱所有 UI 都 100% 相似。可用 0–5 的主觀五項評分（Visual fidelity、Readability、Interactivity、Rule correctness、Asset compliance），但評分者、尺度與改善點需保留，不能拿評分代替已跑測試。

## 7. 視覺交付 Gate 的判定

- `SPEC_ONLY`：只有文檔與設計。
- `ASSET_PENDING`：缺合法素材／角色動作；UI 可做 placeholder。
- `IMPLEMENTED_NOT_VERIFIED`：有 Scene/GDScript，但沒實際 run/screenshot/test。
- `PARTIALLY_VERIFIED`：驗證部分流程，尚有 block 證據。
- `VERIFIED`：所有本 Gate 的 code、resource、screen state、回歸測試和實際畫面都有證據。
- `BLOCKED_BY_DOMAIN`：依賴尚未交付／未核准的 Domain Action/Event／Balance。
- `BLOCKED_BY_LICENSE`：尚未確認可用的美術來源。
- `NOT_APPLICABLE`：本次明確不涉及的功能。

**放行條件**：所有本階段必要案例都有真實測試證據、沒有阻止玩家使用主功能的缺陷。小量視覺偏差可以列 backlog，但不能把缺失的核心操作當完成。

## 8. 工程交接報告模板

```md
# UI-Gx Engineering / Visual Acceptance
- Repo / master base SHA / implementation branch SHA:
- Godot binary/version / renderer / OS:
- Source of Truth commit / Requirement IDs:
- Concept image reference ID / approved date / version:
- In scope / Out of scope / Planned:
- Changed paths (Scene, script, Resource, asset, test, doc):
- Third-party assets/license proof/credits:
- Tests executed (ID, command, exit, seed/replay hashes):
- Screenshots (path, resolution, locale, UI state):
- Visual diff and usability findings:
- Open items (BLOCKED/PROVISIONAL)/Reason:
- Final status: [SPEC_ONLY|IMPLEMENTED_NOT_VERIFIED|VERIFIED|...]
```

## 9. 執行限制與禁止事項

- **這次需求就是文檔研究與 GitHub 推送**；不可新增／修改 `.gd`、`.tscn`、`.tres`、圖片、Shader、音訊、`project.godot` 或 CI。
- 未來不允許為 UI 速度而繞過 command validation；不得在動畫末端再結算傷害。
- 不擅自引入付費模型 API、不擅自把搜尋到的美術素材下載合併；未經授權不新增正式 Canon 角色或 Boss。
- 有 license 不明、Domain event 不足、概念圖來源不清時，列 blocker 而非填補虛構值。
- 已核准的 `12 cards/character`、`start/refill 4`、`hand max8`、`shared 6 base AP`、`RP from remaining AP`、`Reaction manual confirm` 等不變量不可因視覺層而更動。

## 10. 未來 Agent 開工提示詞

> 只在我指定的下一個工作包內施工。確認 `KuroNekoLi/arbitrium-nexus-godot` 最新 master HEAD，閱讀 `docs/ui/README.md` → 01～05、`docs/combat/` 最新批准規格和 `docs/verification/`，同時盤點既有 Scene、SimpleCards、Kenney、Assets。先交 G0 Diff／規格映射與計劃，確認 Blockers 再依我授權實作。每次提供真正的 Godot 畫面、完整測試證據與授權紀錄，不能把概念圖當可玩的遊戲。
