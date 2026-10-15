# 03 — 免費／開源 UI、美術、動畫與音效資源調查（Resource Scout）

> **2026-10-15 research snapshot · RESEARCH ONLY / NO IMPORT / NO LICENSE APPROVAL FOR SPECIFIC UNDOWNLOADED ASSETS**。以下來源以官方頁面／上游 Repository 為準；列入候選不表示已下載、整合、相容性測試或可不附授權聲明地再散布。使用前需重新檢查每個下載檔的 license、版本、來源、權利和是否已由本專案引入。

## 0. 選用優先順序

1. **先用 Repo 已存在的東西**：`addons/kenney_fantasy_ui_borders`、`kenney_particle_pack`、`kenney_ui_audio`、`kenney_rpg_audio`、`simple_cards`、現有 `assets/` 角色圖集／肖像／卡圖集。先讀根目錄 `CREDITS.md`、包內授權檔和 `plugin.cfg`。
2. 使用 Godot 內建 `Control/Container/Theme/NinePatchRect/TextureRect/AnimationPlayer/AnimatedSprite2D/GPUParticles2D`，除非有明確功能缺口，不多裝 UI framework。
3. 優先 CC0 美術素材；若採 ISC/MIT/OFL/CC BY，須履行通知或署名。盡量**不**導入要求整個程式分發特別義務的 GPL/AGPL 遊戲插件（不代表所有 GPL 禁用；需法律與散布型態評估）。
4. 資產是否適合最終奇幻 JRPG 風格，和授權可用性**分開**評估；像素風／低多邊形資產可用於早期樣機，不得自動當正式角色造型。

## 1. 已在專案內的可再利用資源（優先）

| 現有路徑 | 用途 | 授權/狀態來源 | Agent 指示 |
|---|---|---|---|
| `addons/kenney_fantasy_ui_borders/` | 角色框、Boss 框、卡牌／彈窗框 | Kenney Fantasy UI Borders，CC0；見 `CREDITS.md` | 優先以 `NinePatchRect` 試排，不為 1 個框重建 100 張 PNG |
| `addons/kenney_particle_pack/` | 命中、魔法、火花 VFX | Kenney Particle Pack，CC0；`CREDITS.md` | 先盤點現成 Godot-compatible 特效，避免重做 |
| `addons/kenney_ui_audio/` | Hover、拖牌、確認、取消音效 | Kenney UI Audio，CC0；`CREDITS.md` | 試播音量與響度，避免 UI 過度干擾 |
| `addons/kenney_rpg_audio/` | 武器揮動／命中音效 | Kenney RPG Audio，CC0；`CREDITS.md` | 按 AttackCue 而非 Domain hit calculation 觸發 |
| `addons/simple_cards/` | Card、Hover、Drag 與資源機制 | 現有 plugin.cfg `2.13`；上游 v2 標 MIT，但要核對**本地** LICENSE 與版本 | 重用既有 plugin；升級需另立變更與回歸 |
| `assets/card_art_atlas.png` | 目前卡牌插畫 | 本專案既有美術，來源需逐一盤點 | 短期兼容；長期改 `CardAppearance.art` |
| `assets/kleya_atlas.png`／`nova_atlas.png`／`yora_atlas.png` | 玩家角色逐格 | 本專案現有素材；來源與映射待審 | 動畫第一版優先盤點這些 Atlas |
| `assets/portraits/` | 角色頭像 | 本專案現有素材；來源待審 | 經角色 identity mapping 驗證後可先用 |
| `assets/battlefield_bg.png` | 既有戰場背景 | 現有素材；與概念圖美術不同 | 可先支援 UI spike，不必直接切概念圖 |

**注意：** 上游 SimpleCards v2 官方專案： https://github.com/twdoor/simple-cards-v-2 ，其 README 描述 Godot 4.5.1+、MIT、hand／layout／drag。舊 `https://github.com/twdoor/simplecards` 已歸檔，**不要**當新主線來源。專案雖已有 `2.13` 插件，仍須核對本地檔案與上游 release/commit 才能宣稱已完全相容 Godot 4.7.2。

## 2. 外部美術素材候選（優先排序）

| 資源與官方連結 | 內容／擬用途 | 網站列示授權 | 建議級別 | 注意事項 |
| --- | --- | --- | --- | --- |
| [Kenney Fantasy UI Borders](https://kenney.nl/assets/fantasy-ui-borders) | 奇幻風面板、邊框、按鈕，與現有視覺接近 | **CC0** | **P0：已內建** | 140 個檔案；視覺一致性優於跨站混搭 |
| [Kenney UI Pack — Adventure](https://kenney.nl/assets/ui-pack-adventure) | 彈窗、按鈕、狀態框、提示 | **CC0** | P1 | 素材畫風需與 Fantasy UI 混搭測試 |
| [Kenney UI Pack](https://kenney.nl/assets/ui-pack) | UI 元件與一般按鈕 | **CC0** | P1 | 適合功能性按鈕，不必全部啟用 |
| [Kenney UI Pack — RPG Expansion](https://kenney.nl/assets/ui-pack-rpg-expansion) | RPG 血條、資訊面板 | **CC0** | P1 | 風格偏原型，最終圖框需設計審核 |
| [Kenney Particle Pack](https://kenney.nl/assets/particle-pack) | 火花、魔法、爆炸的 2D 粒子素材 | **CC0** | **P0：已內建** | 不是完整角色攻擊動畫，只是 VFX |
| [Kenney Monster Builder Pack](https://kenney.nl/assets/monster-builder-pack) | 拼裝 2D 敵人原型與佔位 | **CC0** | P2 Prototype | 不等同正式 Boss Canon；和高保真美術風格不同 |
| [Kenney UI Audio](https://kenney.nl/assets/ui-audio) | 按鈕／交換／選取音效 | **CC0** | **P0：已內建** | 注意觸控 Hover 不存在 |
| [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio) | 武器、腳步、命中音效 | **CC0** | **P0：已內建** | 最終混音與授權包另做清單 |
| [Lucide](https://lucide.dev/license) | 一般界面圖示（關閉、資訊、查詢、箭頭） | **ISC；部分 Feather 衍生 icon 為 MIT** | P1 | 要保留對應版權與授權通知；戰鬥元素圖示風格可能太簡約 |
| [Game-icons.net](https://game-icons.net/about.html) | RPG 元素、狀態、武器、卡片 tag 圖示 | **CC BY 3.0** | P1 | **必須依原作者個別署名**；不要因免費就省略 credits |
| [Noto CJK Fonts](https://github.com/notofonts/noto-cjk) | 繁中主要字型與英文字 fallback | **SIL OFL 1.1（詳見實際包版）** | P1 | 檢查實際字型檔的 OFL、Reserved Font Name、體積及遊戲發行附錄；不將文字烘焙於圖 |
| [Poly Haven](https://polyhaven.com/license) | HDRI／背景質感／石材和金屬材質 | **CC0** | P2：偏 2.5D | 多為 3D/貼圖/HDRI，對純 2D HUD 幫助有限，僅於渲染 spike 評估 |
| [Quaternius Universal Base Characters](https://quaternius.com/packs/universalbasecharacters.html) | 可 Rig 的 3D 角色/動作試驗 | 該包頁面列 **CC0** | P2：僅比較 3D 路徑 | 網站有免費與會員內容，實際選用檔案要確保是可免費下載版本；其 Godot 工程示例較舊 |
| [OpenGameArt](https://opengameart.org/) | 多樣 sprite、魔法 VFX、敵人等 | **每個作品獨立**（可能 CC0、CC BY、CC BY-SA、GPL...） | 僅候選 | 不能把網站當成統一授權；需逐條作品頁、檔案內 license 審核 |

以上 **CC0/ISC/MIT/OFL/CC BY** 均非「無著作權疑慮、可直接轉賣所有內容」的保證；另有商標／人物肖像／第三方再上傳權利、修改與散布義務。必要時諮詢法律專業人士。

## 3. 免費／開源製作工具（可輔助 Agent）

| 工具 | 免費／開源狀況 | 適合工作 | 限制 |
| --- | --- | --- | --- |
| [Godot](https://godotengine.org/) | MIT | Scene、HUD、VFX、輸入、動畫、實際截圖 | 需用**本專案指定版本**執行驗證 |
| [Krita](https://krita.org/en/about/license/) | GPLv3 程式；作者創作的圖片不因使用該工具而變 GPL | 人物／卡牌／戰場圖、透明去背、逐格繪圖 | 手動美術品質仍取決於素材 |
| [Inkscape](https://inkscape.org/en/about/license/) | 開源 GPL 程式；作品由創作者／衍生來源權利決定 | SVG UI、圖示、卡框原稿 | 匯入 SVG 需用 Godot 實測材質及顯示 |
| [LibreSprite](https://libresprite.github.io/) | 免費開源（需查看實際版本 license） | Sprite Sheet、像素動畫、簡單逐格調整 | 視覺風格偏 pixel；不等於手繪 2.5D 畫風 |
| [Godot Asset Library](https://docs.godotengine.org/en/stable/community/asset_library/what_is_assetlib.html) | 官方資產庫免費，但**各項有不同 OSS license** | 查找兼容引擎的輔助工具 | 必須查個別 Repo／版本／license，禁無審核安裝 |

工具開源授權與工具產生**輸出作品的權利**不同：Krita 官方明確區分其 GPL 程式與使用者作品；Inkscape 也有同樣說明。不能反向推論用了 GPL 工具就必須把整款遊戲改為 GPL。

## 4. 授權風險分級

- **L0 Ready-to-evaluate**：來源官方可追、CC0 明示、檔案版權確認、無第三方素材異常、與遊戲風格相容；仍待 Asset QA。
- **L1 Notice/Attribution**：ISC/MIT/OFL/CC BY 等允許預期用途，但需保留 license 文本、作者與必要聲明；若未完成 credits 不得發行。
- **L2 Manual review**：CC BY-SA、GPL/AGPL、未知 custom terms、AI 生成含第三方輸入來源、人物肖像／品牌標記；先僅記錄研究，不直接進專案。
- **L3 Reject for now**：來源不明、僅寫「free」但未提供允許條款、明確 NC 或 ND 限制、需要登入後不明授權、禁止重散布或與預期商用不相容；未經許可不得提交正式 Asset。

切記：不要把 `OpenGameArt`／`itch.io` 搜尋結果的「免費下載」理解為可商業使用或可再發布；也不要拿其他遊戲的截圖裁出角色當成素材。

## 5. 建議 Asset Manifest（未來實作時建立）

```text
asset_id,category,role,source_url,author,source_pack,
license_id,license_url,license_file,attribution_required,
source_version,download_date,source_sha256,original_filename,
source_format,output_path,output_format,pixel_dimensions,
transparent_background,frame_count,pivot,import_settings,
content_id,variant_id,reviewer,status,notes
```

必要守則：
- 資產 ID 不綁定本地檔名；角色 variant、卡牌 card_id 對上 Appearance 映射。
- 原始檔與轉檔後 WebP/PNG 分別記 SHA／目的；發行包中必需的 NOTICE/credit 應同步 `CREDITS.md`。
- 刪除 Atlas 片段後還要檢查任何 Scene 的 `AtlasTexture.region` 是否仍指到原區域。
- 每次重繪／AI 圖像生成都要建立素材來源記錄、用途和參考素材是否被授權。
- 若使用圖片模型重新生成：按 **background-only、portrait-only、actor-only、boss-only、card-art-only、UI-frame-only、VFX-only** 的 isolated brief 執行，禁止一次生成帶有所有 UI 字的整張合成圖作為最終可換的檔案。

## 6. 推薦搜尋與導入策略（不立刻安裝）

**近程 P0：** Repo 現有 Kenney Frames／Particles／UI Audio／RPG Audio + SimpleCards，先做清單，能滿足暫時的功能與交互。

**中程 P1：** Kenney UI Pack Adventure（補缺面板）、Lucide（一般 icon）、Game-icons.net（魔法／屬性 icon，記作者）、Noto TC 字型，選一套一致色系及線條粗細後再導入。

**遠程 P2：** 若真正要上 2.5D，再比較 Poly Haven／Quaternius 的需求，不因「可免費」增加不必要的 3D 負擔；高保真 anime 戰鬥角色需另外建立美術規範與產線。

## 7. 已核實官方／上游來源

- Kenney Fantasy UI Borders: https://kenney.nl/assets/fantasy-ui-borders
- Kenney Particle Pack: https://kenney.nl/assets/particle-pack
- Kenney UI Pack Adventure: https://kenney.nl/assets/ui-pack-adventure
- Kenney UI Pack RPG Expansion: https://kenney.nl/assets/ui-pack-rpg-expansion
- Kenney RPG Audio: https://kenney.nl/assets/rpg-audio
- Kenney UI Audio: https://kenney.nl/assets/ui-audio
- Simple Cards v2: https://github.com/twdoor/simple-cards-v-2
- Game-icons.net license: https://game-icons.net/about.html
- Lucide license: https://lucide.dev/license
- Noto CJK: https://github.com/notofonts/noto-cjk
- Poly Haven license: https://polyhaven.com/license
- Quaternius specified pack: https://quaternius.com/packs/universalbasecharacters.html
- Godot Asset Library license variations: https://docs.godotengine.org/en/stable/community/asset_library/what_is_assetlib.html
- Krita output-art license clarification: https://krita.org/en/about/license/
- Inkscape files-made license clarification: https://inkscape.org/en/about/license/

所有資料為 2026-10-15 閱讀頁面所得之候選清單。新增前 Agent 必須再次開官方來源確認條款與檔案版本。
