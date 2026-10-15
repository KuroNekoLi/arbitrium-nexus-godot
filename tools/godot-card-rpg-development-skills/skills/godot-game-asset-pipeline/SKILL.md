---
name: godot-game-asset-pipeline
description: "接到製作 Godot 場景、卡牌圖片、角色、Boss、VFX、音效等成果任務時，與資源庫管理員協作，從既有/免費素材或可用生成工具取得合規素材，完成轉檔、Godot 匯入、Theme/Scene 綁定、測試、來源記錄與可回退交付；重大資源採用先出候選比較報告。"
---

# Godot Game Asset Pipeline — 從任務到 Godot 可用資源

## 自動啟動與安全邊界

使用者說「製作 XX 場景」「生產 XX 圖片」「新增角色」「讓 Boss 有 XX 動畫」「美化卡牌」等結果導向指令時，**不要停在提供網址或生成單張合成示意圖**。在該任務授權的範圍內主動規劃、復用、選取／取得合規素材、匯入 Godot 並交給 UI/Rendering Agent 組裝，最後以真實場景／截圖／測試驗收。任務明確說「只規劃、不要實作」時只產出文件，不得下載、匯入或生成大量實物。

此 Skill 負責正式**入庫與遊戲內整合**；外部探索、Vault 批次下載／Catalog 索引請用 `godot-resource-library-manager`。一個 Agent 可依序扮演兩者，但 Skill 本身不提供網路、磁碟、繪圖模型或 Godot 執行權限；缺權限則列 `BLOCKED_BY_TOOLING`，不可假稱已完成。

## 正式必讀

1. [Spec Guardian](references/SPEC_GUARDIAN.md)、[Asset Pipeline 工程規範](references/ASSET_PIPELINE.md)。
2. `docs/ui/README.md` → `03_FREE_OPEN_SOURCE_RESOURCE_SCOUT.md`；Resource Manager 的 `references/RESOURCE_LIBRARY_MANAGER.md`。
3. 根 `CREDITS.md`、已存在的 `assets/`、`addons/`、角色 Canon 與對應 Combat Rules；先查 Godot 版本／renderer／可用工具。
4. 先盤點 `kenney_fantasy_ui_borders`、`kenney_particle_pack`、`kenney_ui_audio`、`kenney_rpg_audio`、`simple_cards`、現有角色 atlas／卡牌圖集，避免重複下載或重做已經存在的工作。

## 任務自動閉環（不是每一步都問使用者）

`User deliverable → Asset Brief → Inventory/Vault Search → Resource Scout & License → Reuse/Acquire/Generate → Normalize → Godot Resource/Scene Binding → Runtime QA → Manifest/Credits & Report`

1. **Brief**：將使用者描述拆成可交付的獨立素材、動畫／角色狀態、風格 Bible、解析度、方向、透明背景、Atlas/SpriteFrames 與語系；不得擅改核心劇情／職能／玩法。
2. **Find**：先搜尋已有 Repo 素材，再找外部 Vault；缺才呼叫 Resource Manager 做包級下載、索引、評分、提出推薦。從可信官方來源取得素材，外部插件需重大決策審核。
3. **Select**：低風險、來源合法且可替換素材可自動採用；主角／Boss 最終造型、整體 UI Theme、標誌性背景／動畫、renderer/插件大替換、特殊授權／付費等需 **Major Asset Decision Report + user approval before final adoption**，可先用 placeholder 進行不會鎖定美術的工作。
4. **Generate**：若素材庫沒有合適候選且有圖像／音效生成工具，可在任務授權下以 **one isolated component per file** 產圖／音；不自動開通付費 API、不把合成 UI 照片直接當作可編輯 Scene。記 prompt/reference、服務和模型可得資訊、生成日期、原件 hash。
5. **Transform**：保留來源原始檔於 Vault，按用途製作 PNG/WebP/SVG/Shader/SpriteFrames/音效等；角色頭像、角色戰鬥圖、卡牌 artwork、UI 九宮格、背景、Boss 與 VFX 相互分離，並檢查 alpha、pivot、filter、texture/atlas padding、尺寸與色系。
6. **Import**：只將選定素材及必要授權檔拷至 `res://assets/`，登記具穩定 ID 的 `CardAppearance/CharacterAppearance/EnemyAppearance`（具體名稱依真實專案契約調整），配合現有 `HeroRosterItem`、`CardView`、SimpleCards 與必要 UI/Rendering Scene。**不變更 Domain 成本／傷害／RNG／牌區。**
7. **Verify**：執行該版本 Godot 的 fresh import、Scene 開啟與可操作視覺測試；提供符合目標解析度/語言的**真正 Godot 截圖**或影片。headless domain PASS 不能代替畫面驗收，AI 概念圖也不是 runtime 證據。
8. **Record**：更新 `assets/asset_manifest.csv` 的真正選用資產條目、`CREDITS.md` 授權資料、Vault 使用歷史、來源 hash、Godot 導入設定、QA 結果及 rollback；更新後下次先復用。

## 與 Godot UI / Animation 分層

- 背景 ≠ 一張含角色、Boss、卡牌、文字的合成大圖。角色/Boss 有獨立 Sprite/Frames/Actor appearance；HUD 由 Control／Theme／Labels／NinePatchRect 動態渲染，卡牌 artwork 只佔卡片內的美術區。
- AnimationPlayer/AnimatedSprite2D/Tween/Particles 的效果由 Domain Event 鏈驅動，不在動畫事件／Tween callback 決定 AP/HP／攻擊命中；受擊角色與傷害數字來自權威事件。
- 卡牌換 artwork 不能改 `card_id`／`instance_id` 的語義；資源缺失使用可見 placeholder，標示導入不完整。
- 本 Repo 的兩語規範：繁體中文與英文所有玩家可見文案經 i18n，禁止畫死在圖上。

## 素材使用決策權

**AUTO：** 本地已審資產、來源與 license 清楚的免費圖示／卡牌特效／一般面板片段／短音效，符合下載配額與已核准美術方向，且能撤銷。

**REPORT + APPROVAL：** 大型 Boss／主角或重要 NPC 定稿、主要戰場背景／美術 Style Bible、UI 系統整體替換、需改專案技術架構或安裝可執行第三方插件、需要付費、無法確認授權、會影響大量已製作素材的不可逆大規模採用。先提供**推薦 1 案 + 2–4 個真實備選**（候選不足則明示），比較畫風、license、相容性、性能、費用、風險與回退路徑，不得無聲定案。

**BLOCK：** 未清權資源或素材庫不足而沒有可用生成／下載工具；清楚告知缺什麼，提供替代方案／待授權的處理步驟。

## 每個成果的最小交付

`task_id`、original brief、reused/downloaded/generated asset IDs、來源與 license proof、實際 `res://` 路徑、hash、相容性／匯入設定、改動檔案、Scene Preview/真正 Godot screenshot、實跑測試指令／exit code、未完成或待批准的決策。任何未實際執行的工作標 `NOT_EXECUTED`，不虛報已匯入／已生成。
