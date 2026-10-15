---
name: godot-game-asset-pipeline
description: "管理 Godot 卡牌 JRPG 的 sprite、紋理、動畫、音訊、VFX 與 3D 模型匯入、品質及來源授權；建立 Asset Manifest，支援合法開源與 AI 資產，不代替渲染架構選型。"
---

# Godot 遊戲資產管線

## 共同准入

必讀 [Spec Guardian](references/SPEC_GUARDIAN.md)。保留既有專案與使用者修改；依新版已核准規則開發，衝突舊規則／oracle廢棄，TBD不以舊版補完。先確認來源、版本與現有實作，再改最小必要範圍。工程說明使用繁體中文，識別字／檔名／commit使用英文。主控路由可讀同套件 `godot-card-rpg-orchestrator`，但本Skill可獨立完成其領域工作。

讀 [資產規範](references/ASSET_PIPELINE.md)。先做符合既有美術方向的brief與需求表，不新增玩法。來源／授權先查核；未知授權隔離，不進正式資產。

為每項資產填 `assets/asset_manifest.csv` 的所有適用欄位及license證據，記source hash與import settings。保留原始來源、版本、pivot／尺寸／format／音訊或模型metadata；AI生成記provider與reference來源。

按pixel／UI／world／3D用途選filter、compression、mipmaps、atlas與animation resource，測fresh import／reimport、實際scene與export依存。保留UID，不手改.godot cache。

交付manifest、credit／license紀錄、import差異、品質／顯存或音訊驗證及未知項目。不得使用未確認授權的第三方遊戲素材，也不自動啟用付費生成服務。
