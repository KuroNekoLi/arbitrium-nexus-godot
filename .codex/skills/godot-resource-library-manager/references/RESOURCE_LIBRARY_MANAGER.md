# Resource Library Manager — 可執行工作契約（Asset Vault / Acquisition / Selection）

> Workflow specification · 2026-10-15 · no downloader implementation or asset import promised by the existence of this file. 本 Skill 受現有 Godot Repo 規格、GitHub 授權與工具權限限制。

## 1. 啟動語意與責任邊界

用户提出**交付成果**而非搜尋請求時也須主動啟動：
- 「製作森林／學院／戰鬥 XX 場景」→ 背景、舞台物件、角色、天氣／光影、UI overlay、音效／SFX 的 Dependency Graph。
- 「生成 XX 卡牌圖片」→ CardDefinition 映射、art-only 提示、畫框／i18n／Texture 格式、資產生成、卡牌預覽。
- 「替 Boss 做攻擊動畫」→ canonical Boss 身份、idle／prepare／impact／recover、VFX 與 SFX、受擊座標、Godot AnimationCue。
- 「美化 HUD」→ 既有 Theme/九宮格／圖示／字體的優先重用、候選 UI pack、前後截圖。

Resource Manager 只負責搜尋／取得／索引／建議，Asset Pipeline 負責加工／匯入／license 帳本，UI/Rendering Agent 產出真 Godot Scene/Animation，QA 產出 runtime 證據；一個有工具權限的 Agent 可以串行扮演，但不可聲稱未完成的步驟已完成。

## 2. Vault：專案外共用來源庫

不要把數 GB 原始下載檔直接塞進 Godot `res://` 或 Git。路徑透過 `ASSET_VAULT_ROOT` 或使用者允許的工作目錄配置；沒有檔案寫入權限先產計畫，**不猜測可寫磁碟路徑**。

```text
<ASSET_VAULT_ROOT>/
  sources/<provider>/<pack_slug>/<version>/source.zip  # untouched original
  extracted/<provider>/<pack_slug>/<version>/           # unpacked, immutable after audit
  index/catalog.jsonl                                   # per-file searchable metadata
  index/packs.jsonl                                     # source/pack-level license+version
  index/thumbnails/                                      # preview jpg/webp
  reports/<task_id>/candidate_report.md
  reports/<task_id>/decision_report.md
  licenses/<provider>/<pack_slug>/<version>/
  quarantine/<task_id>/                                  # untrusted/unlicensed assets
  tmp/<task_id>/                                         # disposable, cleanup after success
```

- 原始來源唯讀，衍生／裁切圖另外 versioning；Repo `assets/` 僅承載**當前正式使用**且授權通過的最小素材集。
- Vault 可位於共享資料夾或經授權的外部儲存，但**本 Skill 不憑空提供雲端倉庫或自動跨裝置同步**；若環境是短暫 cloud worker，必須先確定長期保存目標與權限，否則保存 manifest 和需要重新下載的 URL，並誠實標 `CACHE_EPHEMERAL`。
- Pack 同源去重用 source URL + release/tag + SHA256；File 同內容用 SHA256；不能只靠檔名判斷重複。
- 不使用外部隱式搜尋結果做索引真相：catalog 指向已存在檔案；檔案失去存取權需降級 `MISSING`，下一個 Agent 重新取得。

## 3. 素材生命周期

```text
DISCOVERED → LICENSE_REVIEWED → ELIGIBLE → DOWNLOADED → INDEXED
                                           ↘ QUARANTINED
INDEXED → PROPOSED → SELECTED_FOR_TASK → INTEGRATED → VERIFIED
               ↘ REJECTED / SUPERSEDED / BLOCKED
```

`SELECTED_FOR_TASK` 代表 Agent 推薦，不是重大 Canon 正式核准；`APPROVED_FOR_CANON` 只能由使用者確認時記錄 approval reference。沒有真正下載只能 `DISCOVERED/ELIGIBLE`，沒有 Godot 截圖只能 `INTEGRATED_NOT_VISUALLY_VERIFIED`。

### Pack catalog 最低欄位

```json
{
  "pack_id": "kenney/fantasy-ui-borders@SOURCE_VERSION",
  "provider": "Kenney",
  "author": "Kenney",
  "source_page": "https://kenney.nl/assets/fantasy-ui-borders",
  "download_url": "OFFICIAL_URL_FROM_FETCHED_PAGE",
  "source_version": "TO_BE_VERIFIED",
  "fetched_at": "ISO-8601",
  "license_spdx": "CC0-1.0",
  "license_evidence": "URL_AND_BUNDLED_LICENSE",
  "commercial_ok": true,
  "modification_ok": true,
  "redistribution_ok": true,
  "attribution_text": "",
  "source_sha256": "REAL_SHA256_IF_DOWNLOADED",
  "archive_bytes": null,
  "status": "DISCOVERED"
}
```

上述是 schema **示例**，不能把占位字串寫成已核實來源或 hash；若欄位未知用 null 並標 `PENDING`。檔案級 index 應額外有 `asset_id`, `relative_path`, `sha256`, `type`, `width`, `height`, `duration`, `alpha`, `tags`, `palette`, `style`, `preview_path`, `license_ref`, `usage_history`, `risk_flags`。

## 4. 來源可靠性、下載規範與安全

1. 優先本 Repo 既有 `addons/` 與 Asset Manifest；其次官方作者頁、Godot Asset Library／官方 GitHub release；OpenGameArt 必須**逐作品**審核，不能一概認定 CC0。
2. 先讀資源**個別** license、包內 LICENSE、下載條款與 GitHub release/tag（適用時）；針對商用、改作、再散布與署名建立正反證據。未知授權**不可**默許下載後整合，最多先保存不會造成授權爭議的頁面 metadata。
3. 只使用經允許的 HTTPS 官方來源，防止 HTTP redirect 至無關主機；禁止猜下載網址、繞過會員登入／付款／防爬、註冊帳號、抓付費合集。Kenney All-in-1 可能是付費商品，不能因 Kenney 個別素材頁 CC0 就自動免費下載付費合輯。
4. 批次下載優先**相關 pack**，不鏡像全站。先向工作報告記錄 `expected_pack_count`、`estimated_bytes`、磁碟可用量、下載上限；建議首批採受限配額（例如每次 5 包、總量不超過 500 MiB，為**建議預設而非不可修改上限**），如超出需交給使用者確認或依既定 workspace 配額調整。API Token／付費服務單獨取得同意。
5. URL、安全下載與 archive 解壓必須防 ZIP Slip/path traversal、symlink escape、絕對路徑、zip bomb、超量解壓與危險檔型。限制可處理副檔名白名單；來源不可信時**不得執行**其中的 `.gd` 工具腳本、二進位檔、安裝程式、Godot Editor plugin、shell script 或 shader include 的不明導入流程。
6. Godot 內新增 `addons/` 可執行插件是**程式碼相依**，不是普通圖片素材；必須走 Major Decision Gate/安全審查；在授權與 code review 前不得 enable。
7. 素材包不可隨手 commit 到 Repository；只有挑出的已審美術素材與必要 license 進 `res://assets/`，保持 CREDITS 與 import metadata。Godot 的 `.godot/imported/` 為 cache，勿提交。

## 5. 動態評分與自動選型

### Hard gates（先過才比較分數）
- `license_allowed`、`source_verified`、`cost=0`（除非使用者已批准付費）、`content_suitable`、`file_safe`、`tool_compatibility`、`canon_not_violated`。
- 不符 hard gate 即 `REJECTED / BLOCKED`，不得以畫質很漂亮覆蓋法律／安全結果。

### Soft scoring（供報告比較）
```text
Visual style / canon match      30%
Functional fit / required states 25%
Quality / resolution / alpha    15%
Godot integration/performance   15%
Maintainability & reusability   10%
Download size / ongoing cost     5%
```
建議示例權重可依任務記錄後調整；**未看 preview 不得虛構視覺評分**。分數低的候選仍可列備選，須寫明 tradeoff；如果所有候選不合適，推薦從乾淨參考圖進行新資產生成（在可用的模型與授權下），而不是硬塞不一致的免費素材。

## 6. 重大採用判定與報告

以下至少需**先出報告，再等使用者核准正式採用**：
- 主角、Boss、重要 NPC 的永久外觀、主線主要舞台、大場景定調、風格 Bible 修改、長期共用 UI 框架／Theme；
- 更換整套卡牌框／字型體系、大量改寫現有素材、跨 2D/2.5D/3D renderer 升級；
- 附署名之外重大授權義務的素材、需額外付費／登入或授權不明內容；
- 下載／安裝可執行插件或需要新高權限整合；
- 大型 pack 超過已核准的下載／容量／算力預算。

**正常低風險 AUTO 素材不需要詢問**：可直接選、加工和匯入，必要時在最終成果摘要列出用過的包與 license。

### Major Asset Decision Report 模板

```markdown
# Major Asset Decision — <Task>/<Decision ID>
User goal / Canon constraints / Reference artwork / Target platforms:
Decision scope / Why this is MAJOR:
Recommendation: <candidate_id>; Status: PROPOSED_AWAITING_APPROVAL
Rationale: art/style, technical, cost/size, legal/license, reusability, known gaps.
| Candidate | Source + direct preview | License / rights | Visual | Godot / performance | Cost/size | Risk | Why not first |
| A (recommended) | ... | ... | ... | ... | ... | ... | ... |
| B | ... | ... | ... | ... | ... | ... | ... |
| C | ... | ... | ... | ... | ... | ... | ... |
Decision needed: Approve A / choose B or C / generate custom / postpone.
Meanwhile completed without approval: <reversible preview or placeholder task>
Cannot proceed without approval: <finalized canon / destructive migration>
Evidence: source URLs, LICENSE text, source checksums(if downloaded), preview screenshot, measured import tests(if executed).
```

若只有一個候選可用，報告可以少於 3 項但必須寫出搜尋策略與排除原因；不能編造備選。報告應簡潔可決策：**先推薦 A、再列可用 B/C**，附圖片或可點的 preview 來源，禁只貼無說明 URL。

## 7. 任務型產線與回退

- 收到「製作XX圖片」：判定 isolated component（背景不含角色/UI字；卡牌圖只畫插畫）；先檢索 Vault／現有 asset，若不足且具圖像工具則生產，記 prompt/reference/provenance，然後交下游產出材質並預覽；不因沒有圖像工具而偽造圖檔。
- 收到「製作XX場景」：拆成 `Background + Props + Actor Art + VFX + HUD + Audio`，生成依賴表；Asset Manager 逐類找素材，Integrator 在 Scene 組裝，QA 需提供真 Godot 截圖；此 Skill 本身不做場景實作。
- 收到「攻擊動畫」：先找已有合法 actor sprite sheet，否則用部件圖／sprite generation + Tween/AnimationPlayer；絕不可只從單張合成概念圖切出帶背景的 GIF 當正式動畫。
- 所有採用保留 `source_asset_id`、`transform_recipe`、原圖 hash、目標 path、受影響 Scene/Resource 清單與 rollback 操作，便於替換及版本升級；不能直接刪原資源破壞歷史。
- Vault 選型準備就緒而沒有整合工具時輸出 `READY_FOR_INTEGRATION`、下一 Agent 所需參數；不要假稱 Scene 已可執行。

## 8. QA 與故障處理

| Check | Required |
|---|---|
| Vault 檔案可讀與 hash match | selected source 必須存在且完整；cache miss 自動提示或依許可重下載 |
| 授權與 credits | CC BY 原作者署名、MIT/ISC/OFL 所需聲明、包級與檔級差異 |
| 影像 | alpha、輸出格式、像素尺寸、裁切、CardArtwork 無烘焙文字 |
| 動畫 | frame count、大小、pivot、朝向、人物一致性、VFX 與 Domain events 一致 |
| 性能 | Godot Compatibility Renderer、資源匯入、VRAM、FPS／卡頓視目標硬體 |
| 版本／成本 | release pin、pack sha256、同包重下載零重複、限額無超支 |
| 大採用 | DecisionReport + 類別 + ApprovalReference；未核准仍是 proposed |
| 實際交付 | Screenshot/Video/CLI exit/log；沒有則標 NOT_EXECUTED |

## 9. 官方參考／資源清單

- `docs/ui/03_FREE_OPEN_SOURCE_RESOURCE_SCOUT.md`（候選網站與優先級）
- `docs/ui/04_BATTLE_ANIMATION_PRESENTATION.md`（動畫與頭像／Boss 分層）
- `docs/ui/05_EXECUTION_ROADMAP_ACCEPTANCE.md`（GitHub/Godot 驗收）
- Godot import: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/import_process.html
- Godot plugins: https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html
- Kenney FAQ: https://kenney.nl/support
- OpenGameArt FAQ: https://opengameart.org/node/5571

所有資訊均以官方來源和下載當下的 license 文件為準；本 reference 不是 legal opinion。
