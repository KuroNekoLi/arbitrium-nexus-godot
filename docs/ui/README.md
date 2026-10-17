# Arbitrium Nexus — Battle UI、Visual Assets 與 Animation 規劃入口

> **設計規劃版本：2026-10-15；2026-10-16 Combat文件入口已更新**  
> 本目錄是未來 Godot Agent 的正式 **UI／美術／動畫研究與交接入口**。本次只補充文件及免費／開源資源調查；**此份UI規劃編寫當時**沒有新實作；但後續已新增Lv40 playable Scene、限定正向接線測試與靜態截圖，詳細進度需核對 `docs/verification/ui/` 的最新證據。這些仍不等於全部真人操作驗收。  
> 目前已有 Lv40 BattleScreen、P4 HUD、真渲染截圖路線；以下 01～05 是設計研究與歷史執行計畫，**不是當前實作差距清單**。請讀取最新 Scenes、測試與 [現行工程對照](../combat/engineering/規則與程式對照表.md)。

## 快速導覽（未來 Agent 請依序閱讀）

| 順序 | 文件 | 內容 | 輸出用途 |
| --- | --- | --- | --- |
| 0 | **本 README** | 權威規則、現況、已確認的 UI 取捨、工作入口 | 確保 Agent 不重新開始、不動玩法 |
| 1 | [01_SCREEN_LAYOUT_AND_COMPONENTS.md](01_SCREEN_LAYOUT_AND_COMPONENTS.md) | 16:9 戰場排版、HUD 區域、Scene Tree、元件 I/O 契約、五種主要戰鬥畫面 | HUD／Design System Agent |
| 2 | [02_ARCHITECTURE_DATA_INTERACTION.md](02_ARCHITECTURE_DATA_INTERACTION.md) | 目前程式碼現況、ViewModel/Adapter、CardAppearance、合法性預覽、互動狀態、i18n | Godot Architecture/UI Agent |
| 3 | [03_FREE_OPEN_SOURCE_RESOURCE_SCOUT.md](03_FREE_OPEN_SOURCE_RESOURCE_SCOUT.md) | 現有 Kenney／SimpleCards 資產、免費／開源候選、授權差異、Asset Manifest、導入分級 | Resource Scout/Asset Pipeline Agent |
| 4 | [04_BATTLE_ANIMATION_PRESENTATION.md](04_BATTLE_ANIMATION_PRESENTATION.md) | 普通攻擊、Boss、詠唱、反應、連攜與 LastSpell 動畫，2D vs 2.5D 架構 | Animation/Rendering Agent |
| 5 | [05_EXECUTION_ROADMAP_ACCEPTANCE.md](05_EXECUTION_ROADMAP_ACCEPTANCE.md) | G0～G7 工作包、真 Godot 截圖、測試、UX 與授權驗收、GitHub 交付格式 | Orchestrator/QA Agent |

以上是五份**分工文件，不是五個已執行 Milestone**。需要進入實作時，先由使用者**明確指定**本次授權的工作包，並提供最新參考圖或其穩定檔案位置。不能只因 Agent 讀了文件就自動實作全部。

## Repository 與 Spec Source of Truth

- 唯一 Repository：`KuroNekoLi/arbitrium-nexus-godot`，`master`；**每次開工重新讀 HEAD**。
- 目標 Godot：`4.7.2.stable`；是否有可執行 binary 要現場確認；`project.godot` 現設 1280×720、Compatibility renderer。
- **Gameplay authority**：[`docs/combat/README.md`](../combat/README.md) 及其繁體中文主題規格；工程入口是[`docs/combat/engineering/戰鬥引擎實作契約.md`](../combat/engineering/戰鬥引擎實作契約.md)。舊編號文件已列為歷史並歸檔，不再並列判斷權威。
- 工程合約：[`docs/combat/engineering/戰鬥引擎實作契約.md`](../combat/engineering/戰鬥引擎實作契約.md)、[規則程式對照表](../combat/engineering/規則與程式對照表.md)、`docs/verification/` 最新 Engineering Notes + CI 證據。舊規格檔原來曾寫過其他 Repo／docs-only 前提；**以這個使用者指定的真實 Godot Repo 為工作目標**，不要回頭處理舊 Repo。
- 規格優先級：最新明示 `USER_APPROVED` > 原已核准 P1/P2/M > 合法 `DELEGATED_DEFAULT` > `BALANCE_PROVISIONAL` > `HISTORICAL/SUPERSEDED`。文件不能擅自把 TBD 變正式規則。
- 根目錄 `README.md` 已以現行 12 SP + M1～M5 引擎重寫；舊版 8 卡／兩次出牌／Reaction 倒數只存在封存歷史，不可重新導入。

## 已決定的界面行為（優先實作；不屬玩法重設）

1. **畫面左上點角色頭像就可以切角**，不做左下角重複切角列；人物與 Boss 圖、角色 UI 模板皆需獨立且可換。
2. 下方手牌**靠底緣排**、保留 Hover／選中放大、但不常駐牌庫、棄牌堆、手牌 4/8 數字工具列；後台仍須維護所有牌區。
3. 玩家階段後接敵方階段，主 HUD 無需常駐固定行動順序面板；Reaction Queue 是另一個情境式排序視窗。
4. 卡片分成 Artwork + reusable Frame + Labels/icons + CardDefinition/Instance；更換插畫不用重新畫框或寫卡牌規則。角色 HUD、Boss HUD 同樣 template 化。
5. **免費換牌不是換角色**：該詞代表每角色每合法玩家階段一次的棄一抽一，受 Domain precheck 與事件時序控制。
6. UI 繁體中文為主要設計語言，支援英文；所有玩家文字皆走 i18n。Guard/Protect 不需要手牌、Last Spell 獨立槽；React 不得有強制倒數／自動 Pass。
7. 高保真概念圖只是 **視覺參考**。圖中可能存在假名字／假 Boss、錯誤花費或自動生成文字；要以正式 Spec、既有 Asset 和使用者核准的角色／Boss 設計為準。

## 自動素材產線（2026-10-15 更新；僅規劃）

在未來獲得正式製作授權的工作階段，使用者只需輸入「製作 XX 場景」「生產 XX 圖片」「製作 XX Boss 動畫」；由 `godot-card-rpg-orchestrator` 自動判斷需求並啟動：

**`godot-resource-library-manager`（Repo/Vault 重用→合法資源搜尋→安全限額下載→索引→選型） → `godot-game-asset-pipeline`（圖片／音效／動畫素材處理與 Godot 匯入） → UI/2.5D/Architecture（場景實作） → QA（真正 Godot 截圖與驗收）**。

一般素材自選、可逆可替換；對於主角／Boss 正式設計、整體美術風格、主要場景及大規模新插件等重大採用，先提交 **Major Asset Decision Report**，有推薦方案、真實備選、授權、成本、風格、效能、回退方式，使用者核准後再正式定案。素材倉庫規劃放在 Repo 外，避免整包素材塞進 Godot 或 Git；沒有下載／圖像生成／持久化權限時應說明工具缺口，不可宣稱已完成。

詳細 SOP 與可用免費資源：[03 Resource Scout / Vault](03_FREE_OPEN_SOURCE_RESOURCE_SCOUT.md)。兩個 Skills：`.codex/skills/godot-resource-library-manager/SKILL.md`、`.codex/skills/godot-game-asset-pipeline/SKILL.md`。**本次未執行下載或真正場景生成。**

## 最值得優先重用的程式與素材

- `scenes/ui/hero_roster_item.tscn` + `scripts/ui/hero_roster_item.gd`：**仍為現役共用元件**，由 `scripts/battle/ui/components/party_status_panel.gd` preload；不能因建立時間或測試名稱帶 legacy 而刪除。
- `scripts/battle/ui/battle_card_view.gd`、`scripts/battle/ui/components/hand_view.gd` + `addons/simple_cards/`：現行手牌與卡片 presentation；更換插畫先查 CardAppearance 對應及現有測試。
- `scripts/battle/battle_screen.gd` 與 `scripts/battle/battle_controller.gd`：目前戰鬥畫面與命令提交；舊 `scripts/main.gd` 已退役，不得恢復第二套 UI→Domain 路徑。
- `assets/characters/ren/`、`akane/`、`tsumugi/`：目前候選角色立繪；`CharacterDefinition` 提供 `appearance_path`，由 CharacterAppearance 統一讀取動畫圖集、肖像與狀態立繪。`assets/legacy/` 僅留歷史素材與授權，非現行人物清單。
- `addons/kenney_fantasy_ui_borders/`、`kenney_particle_pack/`、`kenney_ui_audio/`、`kenney_rpg_audio/`，授權清單見 `CREDITS.md`。
- `.codex/skills/` 內已有專業 `godot-card-rpg-uiux-engineer`、`godot-game-asset-pipeline`、`godot-2-5d-rendering-engineer`、`godot-qa-ci-engineer` 等；未來由 orchestrator 協調而非新造一套平行技能。

## 首選免費／開源資源摘要

- **P0 已在 Repo**：Kenney Fantasy UI Borders、Particle Pack、UI/RPG Audio（包頁為 CC0）；SimpleCards（請確認本地版本和 MIT license）。
- **P1 候選**：Kenney UI Pack Adventure（CC0）、Lucide（ISC／部分 MIT）、Game-icons.net（CC BY 3.0，須署名）、Noto TC（SIL OFL，應附字型授權）。
- **P2/選型才看**：Poly Haven CC0 材質、Quaternius 指定 CC0 角色包做 3D spike；OpenGameArt／itch.io 的免費素材**逐作品確認**授權，禁止一概當商用免費。

詳細來源 URL、權利、清單和導入規則以 `03_FREE_OPEN_SOURCE_RESOURCE_SCOUT.md` 為準；**此次未下載/新增任何外部美術素材**。

## 未來 Agent 交接指令（可直接貼）

> 請接續 `KuroNekoLi/arbitrium-nexus-godot` 的 Battle UI / Visual Assets / Animation 規劃。先確認最新 `master` HEAD，完整閱讀 `docs/ui/README.md` → `docs/ui/01`～`05`、`docs/combat/` 最新核准文件、`docs/verification/` 與相關 `.codex/skills/`。請不要重新設計已核准戰鬥系統，不能把概念圖當作最終背景貼圖。請先做**UI-G0 現況／素材／Domain 接口盤點**及差異與阻擋清單；在我指定要實作哪個工作包之前，先不要修改程式或生成美術。未來交付時需真實 Godot 截圖、測試和授權紀錄，不可用 AI 概念圖當 runtime 證據。

## 修改履歷

- **2026-10-15**：由簡要 Agent Handoff 擴充為五章詳細計畫與 Resource Scout；文件-only，沒有任何 UI/Animation 實作。
