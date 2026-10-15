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
