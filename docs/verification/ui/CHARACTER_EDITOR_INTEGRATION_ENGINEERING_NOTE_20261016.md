# Character Appearance / Editor Preview — Engineering Note (2026-10-16)

## 設計任務與結果

來源：[2026-10-16 Character Atlas Checkpoint](../../handoff/CHARACTER_ATLAS_EDITOR_PREVIEW_CHECKPOINT_20261016.md)。將六張已取得透明角色圖整合到獨立 Actor Slot、原 HUD 人物頭像與 Last Spell 大型 CG，並建置可在 Godot Scene Editor 即時呈現的非遊戲執行預覽。**不變更 Lv40 攻防/卡牌/Seed/Replay/Target/ContentConfig。**

### 分層

- **BattleCharacterAppearance @tool Resource**：包含 Atlas/CG、可調列界/欄界、Portrait Region、腳底 Offset/Tint；不含 HP/AP/MP。每位角色單獨 `.tres`，美術可替換。 Atlas 1254×1254，但列界為 `0/418/800/1254`，避免 418×418 等分切斷第三列動作。
- **CharacterAppearanceRegistry**：唯一 A/B/C 映射，僅回傳 Texture2D/Resource，不猜角色陣營與卡牌法術作用範圍。Boss 沿用 Placeholder。
- **BattleActor**：四個獨立 Node2D 共用腳底 Sprite 動態構建；`_ready`/Resource.changed 更新視覺子節點，保留 `play_attack/play_hit/project_conditions/reset_motion` 舊 API。 Editor 模式禁止 Battle Tween/Resource Payment；`SpriteFrames` 由各 Actor 持有，不修改共享 Resource。
- **EditorPreviewData**：以預設資料直接更新**同一套** HUD 控件、使用 `BattleCardFrame.build` 建立暫時牌面，避免 Editor 下安裝 SimpleCards runtime action handlers。不執行 M5 Resolver、不啟動 Controller、不實際選牌扣資源；`MOCK_ONLY` 會顯示在畫面。Inspector `editor_preview_mode` 在 Battle / Last Spell 三人間選擇，CG 使用同一 Registry。
- **Run-time Last Spell**：原 `LastSpellReadModel` 的 legality / Single/All/Team / Command 明確提交全部保持；單體敵對、敵全朱音及我全紬的唯一權威仍是 Domain config。本輪只替換獨立 CG / Portrait 來源，不修改 Damage/Heal/Replay。
- **Legacy lifecycle**：原資源移 `assets/legacy/` 並更新舊 `scripts/main.gd`。Source manifests 紀錄 AI-generation 候選與原 SHA，不能誤稱 CC0 或最終 Canon Art。

### Android / Kotlin 對照

`@tool Resource` 類似把 Design-time asset properties 放進可編輯資料模型； `Engine.is_editor_hint()` + MockProjection 類似 **Compose @Preview** 的 Fake UiState。但只替換 rendering input，不讓 Preview 呼叫 ViewModel／Repository／Reducer； Signal.changed 類似參數更新導致 UI invalidation。實際戰鬥仍用 Controller → Domain Command → M5 → Events → Adapter，不能從 Tween 改 HP。

### Alternatives / Risks

選擇 `AtlasTexture` 明確 Rect，因實際 Atlas row boundaries 非等高。另可批次裁成 9 張獨立 PNG，但會增加重複資產與管理負擔。暫不導入新 3D Renderer/插件、也不自行重繪候選圖。 Editor 預覽為方便構圖的 mock state，不是實際戰鬥 screenshot；`@tool` 必須小心 editor lifecycle、信號解訂和底層編輯器與遊戲 TranslationServer 不同（% 字串格式化不能套在未解析 key 上）。

### QA 原始證據與限制

- 三次「新角色 Editor Group」： [run1](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38836200204), [run2](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38836444604), [run3](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38836688296)。**第 3 次 strict Editor Import 成功**，新 Group 31 項連續 PASS，後因 `SceneTree._init` 在 `_ready` 前檢查 Actor Body 造成一項 FAIL 與 Nil error；已移到 `_initialize` deferred run。**新組測試 35/35 並未通過，不得重跑第四次。**
- 原 Last Spell Scope 經使用者額外授權第 4 次已 29/29 PASS；本輪不重跑受限的 Last Spell / P4.4 GUI。
- 真正 Editor Scene GUI／F6／1280×720／1920×1080 截圖 **NOT EXECUTED**。Native GPU Renderer、動作骨架、角色比例、美術定稿 **NOT VERIFIED**。不能由 editor import 或 31 項單元檢查推導出使用者眼前的美觀結果。
- QA 原因與修復以 GitHub CI logs 為準，未用修改測試預期降低失敗率。

### 接下來的驗收決策

需要由擁有者在 Godot Scene Editor 開啟 `scenes/battle/lv40_playable_battle.tscn`，切換 Inspector Editor Preview Mode 觀察 Ren/Akane/Tsumugi 位置、3×3 frame crops、CG 對齊及手牌元件。正式角色美術屬重大採用，需要另行核准；如果要求重新執行受限群組，必須先取得新的明確授權。本任務不擅自 Merge master。

面試追問：為何 Godot @tool 需要隔離 Domain 初始化？Resource.changed 的信號生命周期如何管理？何時要用 AtlasTexture vs 裁切輸出檔？Editor Preview 的 Mock Data 如何防止錯當遊戲驗收？
