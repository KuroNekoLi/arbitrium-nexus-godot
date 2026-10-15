# 遊戲資產管線與授權

先讀 Spec Guardian。只在已授權需求內製作／匯入；素材、字型、音樂、音效、模型、VFX及AI資產皆有manifest。未知授權素材不進正式遊戲，保留隔離狀態與缺失欄位，不把「免費下載」當成商用許可。

## Asset Manifest

使用 `assets/asset_manifest.csv` 空白schema。每筆正式資產記錄Asset ID、name、purpose、type、source URL／原始來源、author/provider、license／版本與證據、dimensions、format、version、import settings；補充source hash、import path、attribution text、commercial／redistribution／modification狀態與review status。音訊／3D不適用dimensions時填N/A並於metadata記duration／sample rate／channels／polycount／units／skeleton。

原始素材、可編輯來源與Godot匯入設定分開；`.godot`是cache，不手改或提交。保留需要追蹤的`.import`設定及`.uid` sidecar；重命名透過編輯器／受控工具更新依存，不自造UID。Asset ID穩定，替換版本要能回退。

## Art brief與匯入

先定palette、像素密度／比例、角色腳底anchor、朝向、光源方向、outline、動畫節奏與UI可讀性。參考Octopath的景深層次／JRPG鏡頭和Slay the Spire資訊回饋，只轉化視覺原則，不擷取其卡圖、角色、音樂、商標或介面素材。

- Sprite／spritesheet：記尺寸、grid、frame rect、padding/extrusion、pivot、FPS、loop／事件、alpha與filter；以實際renderer看邊緣bleed。pixel art是否nearest、mipmaps依縮放需求測試，不全球盲設。
- Texture／VFX：分類UI／world／3D材質、compression、color space與alpha；評估atlas、顯存、overdraw及shader兼容。優化前後保留相同鏡頭比較。
- Animation：SpriteFrames／Animation resource的命名、framerate與來源可追溯；依2D／3D選適合節點，動畫事件不處理遊戲傷害。
- Audio：loop seam、peak／音量一致性、格式、mono/stereo、bus routing、串流與壓縮按用途；一次載入的大音訊要測記憶體與卡頓。
- 3D：記單位、axis、scale、pivot、material slots、skeleton／動畫命名、模型格式與import選項，檢查重匯入不破壞場景覆寫。

## 授權與AI來源

保存license原文／版本、來源頁及取得日期、必要署名和是否可修改／商用／再散布；CC-BY、CC0、OFL、MIT等逐件核對，不能用單一repo license推論內含全部第三方資產。不確定者標LICENSE_UNVERIFIED並提出替代或查核工作。發行時credits／third-party notices要含遊戲資產與Godot依存所需資訊。

AI生成資產記provider、model/version（可取得時）、生成日期、prompt或安全摘要、reference素材來源及授權、輸出hash、後製與服務條款證據。AI生成不自動等於已清權或獨占；人工檢查相似性、品質、破圖／透明邊緣。不得因本Skill就自動啟用付費服務。

## 完成條件

Manifest對得上實際檔案／hash與正式用途；license已確認，credits已覆蓋；fresh import、重新匯入、場景載入、export包含與目標裝置視覺／音訊檢查均按scope執行。只有靜態檢查時不宣稱正式可發行。

官方依據：[License compliance](https://docs.godotengine.org/en/4.7/about/complying_with_licenses.html)、[Project organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/project_organization.html)。

## Task-driven Asset Vault and Role Handoff（2026-10-15 補充）

用戶提出「製作 X 場景／生產 X 圖片／Boss 動畫」時，由 `godot-resource-library-manager` 自動取得或選出候選素材、在專案外 Vault 建索引；本 Asset Pipeline 只接入有 license proof 的 `SELECTED_FOR_TASK` 素材並依重大性門檻判斷是否需正式核准。外部素材倉庫**不是**新的 Godot `res://` 全量鏡像，只有被選中的合規素材移入正式工程。動態搜尋、下載、分類、hash 比較、配額與安全解壓規範見新 Skill `references/RESOURCE_LIBRARY_MANAGER.md`。

### 完整成果的自動化閉環

`Brief → existing assets → indexed vault → license-safe discovery/acquisition → ranked choice → isolated source processing/generation → Appearance Resource → scene binding → real Godot screenshot/QA → asset manifest and credits`。

- **圖像任務**：生成 card-art-only／background-only／actor-only／boss-only 等獨立檔，絕不把複合概念圖視為可換文字、換角色的背景。UI Frames、圖示、卡名／費用／描述由獨立 Texture／Control／Theme 和繁中／英文 i18n 渲染。
- **場景任務**：場景拆為背景、道具、Actor Slots、HUD、VFX、Audio，逐一來源查核；真的把 UI／場景組裝、運行、拍照才算完成，單有素材包或概念圖不算。
- **動畫任務**：檢查現有角色 Sprite Sheet 和動畫，合適時重用；缺材質再建 SpriteFrames、Skeleton Cutout 或 Tween 方案；Animation Cue 只呈現 Domain Events，絕不依動畫 callback 扣傷害。
- **未清權 / 工具不足**：輸出候選報告、待核准方案和 `BLOCKED`，不要拿來源不明圖當成成品或宣稱已完成。

### 採用決策與權限

| 採用類別 | 執行模式 |
| --- | --- |
| 已審並已存在素材、免費低風險 icon/VFX/UI 音效/一般佔位，符合風格和配額 | AUTO 可自行取用、整合與交付；最終摘要記用途與授權 |
| 重要角色／Boss 正式外觀、核心場景定調、主 UI Style Bible、重要音樂、renderer/第三方可執行插件替換、會改變大量現有設計的採用 | **先出 Major Asset Decision Report，再等核准正式採用**；報告附推薦、2–4 個真實備選、授權／效能／風格與回退 |
| 授權未知、付費/帳號權限要求、不明來源、受明顯限制的不可商用檔 | BLOCK 或 REVIEW；不得逾越權限，不能啟用付費工具 |

**Record requirements**：新來源要完整資產 ID／vendor／release／licensing evidence／來源 sha256／轉檔 sha256／import settings／viewport 和 runtime QA。Vault 路徑可由 `ASSET_VAULT_ROOT` 配置，不能假設 ephemeral worker 上下載的檔案已持久化。安裝 Godot 插件等同引進可執行程式碼，須與單純圖片 zip 區別處理。

### 參考

- `docs/ui/03_FREE_OPEN_SOURCE_RESOURCE_SCOUT.md`
- `.codex/skills/godot-resource-library-manager/SKILL.md`
- `tools/godot-card-rpg-development-skills/references/RESOURCE_LIBRARY_MANAGER.md`
- Godot 官方匯入流程：https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/import_process.html
