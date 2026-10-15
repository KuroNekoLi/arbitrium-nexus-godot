---
name: godot-resource-library-manager
description: "在 Godot/JRPG 接到製作場景、圖片、角色、卡牌、UI、動畫或音效要求時，自動搜尋可用免費／開源素材、審核授權、限額批次下載到專案外 Asset Vault、索引評分並交付可選用候選；重大美術選型產出比較與建議報告，不擅自定 Canon 或安裝高風險插件。"
---

# Godot Resource Library Manager — 任務導向素材搜尋／下載／索引／選型

## 何時啟動

使用者只需提出「製作 XX 場景」「生產 XX 圖片」「替 Boss 做 XX 動畫」「新增卡牌美術」「美化 UI」「找免費音效」等**成果導向指令**，無需自行列出網站。當任務需要圖片、紋理、Sprite、聲音、字型、Icon、模型、動畫、Shader 或 UI framework 時，先使用本 Skill 檢查既有資源與 Vault；找不到合適資源時再搜尋、下載、生成或申請授權。

此 Skill 專責**發現／取得／管理／評選**，不是獨立的遊戲場景實作者。當任務要求最終 Godot 成品，必須交接至 `godot-game-asset-pipeline` 匯入，以及 `godot-card-rpg-uiux-engineer`／`godot-2-5d-rendering-engineer`／`godot-architecture-engineer` 建構，最後 `godot-qa-ci-engineer` 驗證。單一 Agent 可逐段扮演上述角色，沒有工具權限就明示 blocker，不可假稱下載或完成。

## 必讀

先讀 [Spec Guardian](references/SPEC_GUARDIAN.md) 與 [Resource Library 管理契約](references/RESOURCE_LIBRARY_MANAGER.md)，再看 `docs/ui/03_FREE_OPEN_SOURCE_RESOURCE_SCOUT.md`、`docs/ui/README.md`、`CREDITS.md`、現有 `assets/`／`addons/`。決策、角色身份、戰鬥效果與先前已核准的美術 Canon 不能因素材可用而更改。

## 一句話到可用資源的完整閉環

1. **Interpret**：從成果指令提取 scene/character/card/VFX/audio 需求、分層、用途、風格、透明度、朝向、動畫狀態、解析度、語系、正式或 placeholder、權限／預算。
2. **Inventory first**：檢索已匯入資產＋Vault catalog，核對 hash、license、tag、preview；已有合適素材直接重用，禁止盲目重新下載。
3. **Discover**：不足時搜尋官方/可信上游（Kenney、Godot Asset Library、作者 GitHub、逐件審查的 OpenGameArt 等），記錄不少於合理數量的候選；不抓搜尋縮圖／第三方轉載站充當來源。
4. **License & safety gate**：先審核每個「具體資源包或檔案」的權利／商用／修改／再散布／署名、網址、版本、下載條款與雜湊；L2 review 僅隔離，L3 拒用。沒有明確授權不得當正式素材。
5. **Acquire**：在受權限、大小／件數配額限制下，對核可的相關 pack 下載**整包到專案外 Vault**；不批量抓全站、不付費、不默默安裝可執行工具；原檔唯讀歸檔並計算 SHA256。
6. **Index**：安全解壓後建 metadata、縮圖、尺寸、格式、alpha、色系、subject、用途 tag、license 索引、來源版本，必要時依相似度去重；可查詢的 catalog 必須能定位具體檔案。
7. **Rank**：先硬性篩掉 license/安全不合格，再比較視覺一致、用途相符、品質／解析度、性能、維護成本、既有重用度；推薦 1 個與至多 2–4 個替代方案及原因。
8. **Decision gate**：一般低風險可自動選；重大採用輸出比較報告與明確推薦，**未取得使用者正式核准前不得將重大選項固定為正式 Canon 或進行難以回復的架構替換**。其餘可逆工作可用暫時 placeholder 繼續。
9. **Hand off**：將選中 asset ID、確切來源路徑、授權／credits、規格、transform／import 建議交給 `godot-game-asset-pipeline`；由整合/QA Agent 完成場景與真正 runtime 檢查。
10. **Learn & reuse**：正式使用後更新 catalog 的 `selected_by`、asset manifest、用途與回退路徑；下次「製作XX」先重用此成果。

## 自主權限與重大採用

- **AUTO**：本專案已確認的素材、授權明確且可免費下載的相關 pack、同視覺系的普通 icon／微型 VFX／UI 音效、低風險可撤回的匯入素材。符合範圍與安全預算時不用逐檔詢問。
- **REPORT + APPROVAL BEFORE FINAL ADOPTION**：主角／Boss／重要 NPC 的最終設計、美術 Style Bible 全局替換、整個戰場主要背景、重要音樂主題、重要品牌／商標、會重置既有大量素材的 pack、切換渲染技術、引入新的高權限 Godot 插件或可執行工具、可能的付費/雲端承諾、授權權利不明／帶署名以外重大義務。報告包含：目標、推薦項、備選 2–4 項、實際預覽連結、授權/價格、品質／性能、整合成本、可逆性、風險與明確待決問題。
- **BLOCK**：缺明確再利用許可、NC/ND 不符用途、來源不可追、需繞過登入/付費牆、下載量無界、要執行不可信腳本／擴充、素材疑似未授權的遊戲擷取／第三方重上傳。
- **工具不足**：可先做研究、候選報告和 manifest 草案，但不能聲稱下載、索引、匯入或已完成；請求所需能力或交接給可操作的 Agent。**Skill 不會自動授予網路或本機檔案權限**。

## 交付

每個成果型任務回報 `REUSED / ACQUIRED / GENERATED / PROPOSED / BLOCKED`，列出素材 ID、來源、license proof、Vault/專案路徑、大小、hash（如果實際下載）、所選原因／替代選項、授權與相容性風險。重大選型請套用 reference 中 `Major Asset Decision Report` 模板。

**永遠不**自行變更 Combat Domain，或把使用者提供的合成 UI 截圖裁切後當作正式獨立角色／卡牌。素材可用不等於 Godot 功能／動畫驗收成功。
