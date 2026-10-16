# Character Atlas / Editor Preview — Quota Checkpoint

## 狀態與權限

2026-10-16：五小時額度剩 21%，依使用者「低於 30% 保存、Push、交接」要求停止擴大施工。
工作分支：`ui/last-spell-target-scope-20261016`。
前一功能 Commit：`6e3830fcea9bac382901d3fc923e84e0c025e474`。
本批為 **ASSETS_CREATED / RUNTIME_INTEGRATION_NOT_IMPLEMENTED**，不是視覺驗收通過。
使用者授權繪製必要素材、改用其設計的 Lv40 三人與 SP、舊頭像移到 Legacy、獨立角色 CG 與編輯器即時預覽；未授權改動戰鬥數值。

## 已完成

- 內建 ImageGen 實際產生六張透明 PNG：Ren、Akane、Tsumugi 各自一張 3×3 動作 Atlas（1254×1254）及獨立 CG（1024×1536）。不是三人合圖。
- 已保存於 `assets/characters/{ren,akane,tsumugi}/{atlas,cg}.png`。
- 已檢視生成圖與 alpha；外觀為可替換 v1 候選，尚待使用者視覺核准，不宣稱最終 Canon。
- 舊素材曾準備搬移，但接線尚未完成，因此已回復原路徑，避免破壞 preload。沒有刪除舊素材。
- SimpleCards 兩個檔案只有換行格式變動，經 `git add --renormalize` 消除，沒有修改其邏輯。

## 素材來源與製作紀錄

來源：本輪內建 ImageGen，使用者明確授權生成；未取得外部素材或使用付費服務。模型名稱未由工具揭露。不得將 AI 生成來源誤記成 Kenney / CC0。
Atlas 共用製作要求：透明背景、3×3 九格、完整人物、略俯視 3/4 朝右、統一比例與腳底基準；第一列 idle，第二列 run，第三列 anticipation / action / follow-through；無文字、UI 或預繪陰影。

- Ren：黑短髮成年男性、藍眼、深藍學院長外套、銀金飾邊、青色刃光長劍，劍擊。
- Akane：紅髮成年女性、琥珀眼、紅黑金法袍、紅寶石法杖，火焰施法。
- Tsumugi：銀髮成年女性、藍眼、象牙白／薄荷綠金飾長裙、月牙法杖、青綠水晶，治療施法。

CG 以各自 Atlas 為參考，要求保留身份、單一人物、直式透明背景與武器。
生成原圖保留在執行主機 `.codex/generated_images/01a135fe-b5b9-7660-9169-df6f7ae31bb6/`；專案 PNG 即可獨立交接，無須該私有路徑。

| 路徑（assets/characters/ 下） | SHA-256 |
|---|---|
| ren/atlas.png | 35f9020220fc6672ec34c964aa13f1947d654ea9eda5c86a9e76841f0cf3ce8a |
| ren/cg.png | 9764407b53a85a89bf2b11af734d07503c8beed4f3a1e91d779830b7db31d1a3 |
| akane/atlas.png | 15a009e6b963d42569c4ebab8fd970610a2d5c14a9b0bfcb66ae09a33fee5529 |
| akane/cg.png | bb1c5e1f7d930f03b1124b13788aa449e7f39f7258bf9c64867e2a7c8d8bef0d |
| tsumugi/atlas.png | 7e7bb9144e7484edda834b76d139d9f323526a60521033967cceabf9dabca349 |
| tsumugi/cg.png | 16534492f60aa116cab5a72ecd3b234b364453cd3fda1cbd2e67c853ae28aa5a |

## 下一位 Agent 實作清單（非已完成）

先讀 AGENTS、orchestrator / Spec Guardian，以及 architecture、rendering、asset、resource、UI、QA Skills 的必要 references。

1. 新增 `scripts/battle/presentation/character_appearance.gd`：`@tool Resource`，包含 Atlas、CG、肖像裁切、frame regions、腳底 offset、角色色調。新增 `resources/ui/characters/{ren,akane,tsumugi}.tres` 與只讀外觀 Registry，映射 A→Ren、B→Akane、C→Tsumugi。
2. 修改 `scripts/battle/presentation/battle_actor.gd`：共用編輯器／執行時的純視覺建立流程；保留既有 play_attack / play_hit / project_conditions / reset_motion API。Inspector 可獨立調整位置、高度、陰影與色調；Resource.changed 正確連接與清理。禁止在 editor 初始化 Domain、提交 Command 或播放戰鬥 Tween。
3. Atlas 生成列界並非完美等分：不可盲目 418×418 切九格。先檢查約 y=418、800 的列界，以 AtlasTexture 自訂 region / 腳底 offset 修正；必要時重新 ImageGen，不假稱動畫已流暢。
4. 修改 `scenes/battle/battle_screen.tscn` 三個既有獨立 Actor Slot。現有位置 A(438,458)、B(497,421)、C(549,388)，為接近的左下→右上排列；保留 y_sort 與逐角色可編輯位置。現有三人本來就是獨立 Node，只是視覺與素材未達需求；不要誤報為拆分了一張三人圖。
5. 修改 `party_status_panel.gd`、`enemy_status_panel.gd`、Last Spell preview 的頭像／CG來源到 Registry。不要用合圖裁切當新人物 CG。
6. 引用更新完成後才 git mv 舊 atlas 到 `assets/legacy/characters/`、舊 party_portraits 到 `assets/legacy/portraits/`。同步 `scripts/main.gd` 舊 Prototype preload 與現有 manifest，保留可執行性。
7. Battle Editor Live Preview：`battle_screen.gd` 的 `_enter_tree` / `_ready` 必須在 `Engine.is_editor_hint()` 時避開 Controller、M5 與 runtime 初始化。新增明確 MOCK_ONLY PreviewData；共用實際 HUD 元件，不能另畫假戰鬥截圖。HUD/子元件按必要範圍 tool 化。動態節點不設 owner，避免污染保存場景。手牌可共用 BattleCardFrame 外觀，避免 SimpleCards runtime autoload 在 editor 觸發輸入副作用。
8. 新增獨立 editor/appearance 測試：三人材質不同、位置可調、frame 不越界、預覽不提交 Domain、re-entry/Signal cleanup、F6 接線與新素材匯入；新增原生 Godot editor / runtime 截圖證據。這是新需求群組，不可用它規避既有測試次數限制。
9. 更新 CREDITS / Asset Manifest、Engineering Note（對照 Compose @Preview）、RTM。只提交有關檔案，最後 clean 並 Push。

## 測試限制與既有證據

- Last Spell scope 新群組最後一次經明確額外授權：29/29 PASS。證據 `docs/verification/ui/evidence/last_spell_scope/batch4-authorized.log`。該組授權次數已用完，不能再跑。
- 舊 P4.4 GUI 14/16、V3.5、Last preview25 等受限群組不可重跑或改名規避。
- 本批六張圖未做 Godot runtime 匯入／視覺驗收；不得聲稱 EDITOR_PREVIEW_VERIFIED。
- 1238 Domain Regression / 100 seeds / 全部 CI 未在本批重跑，不能引用過往 PASS 作本輪證據。
- Commit 使用 `[skip ci]`，避免 Push 自動觸發已達次數上限的歷史群組；CI 必須如實標示 SKIPPED，不是綠燈驗收。

## 工程說明

獨立 Actor Node 如 Compose 中三個帶各自 state 的 View：美術 Resource 提供外觀，Presentation Adapter 提供已結算狀態。編輯器 PreviewData 相當於 @Preview 的 fake UI state，但不進入正式 reducer。陰影、Tween、光效只能呈現事件，不能決定傷害。保持這個邊界才可安全調整構圖且不改 Replay。
