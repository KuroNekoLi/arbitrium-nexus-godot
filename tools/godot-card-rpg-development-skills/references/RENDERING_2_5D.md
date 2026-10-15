# 2.5D 場景、鏡頭與渲染

先讀 Spec Guardian。現有入口是 Control main，Compatibility renderer，1280×720、canvas_items；這是已檢查快照，不是永久限制。Phase3無自由走位。美術參考只借鑑場景層次與資訊節奏，不能複製商業遊戲素材。

## 選型比較與 ADR

| 方案 | 適合情況 | 成本／風險 | 最小驗證 |
|---|---|---|---|
| A：2D＋Parallax／Fake Depth | 既有2D HUD與固定戰場、前中後景層次 | 光影與鏡頭自由度較有限；z/Y排序需明確 | 一個戰場、前景遮擋、角色聚焦、最小整合diff |
| B：3D＋2D sprites | 需要幾何透視、真實遮擋與3D鏡頭 | Sprite3D透明排序、billboard、光照一致性、更多工具成本 | 同資產場景驗證正交／透視、陰影與最低目標裝置 |
| C：Hybrid SubViewport | 需獨立3D世界及2D UI／像素解析度 | 額外render target、解析度／輸入座標、重複渲染成本 | viewport縮放、目標選取映射、GPU／顯存實測 |

現況優先以A作低成本比較基準；B/C是候選，不是已核准正式選型。ADR列現有約束、畫面目標、A/B/C結果、CPU/GPU/frame time／draw calls／texture memory、工時與維護、選擇原因與rollback。不能只因2.5D就重建Node3D專案或擅自切renderer。

## 場景與鏡頭

以視覺slot定位角色／敵人，世界背景、前景、中景、戰場zones及range_tag各有明確責任；視覺slot不能改變合法目標或射程。定義depth排序、腳底anchor、sprite尺度、影子與可選取輪廓。3D評估Sprite3D billboard與alpha cut／透明、深度寫入、近遠裁切、texture filtering和像素密度；不可把Sprite3D當SpriteFrames播放器，逐格3D可評估AnimatedSprite3D。

Camera2D適合A；Camera3D的orthographic／perspective適合B/C。鏡頭有framing／zoom／shake、人物與技能focus、boss entrance及cinematic transitions契約；所有位移完成／取消／場景離開後復位。shake影響相機或視覺root，不動Domain位置；減少動態設定可關閉。鏡頭不遮HUD、目標提示及Reaction選擇。

## 演出工具

| 工具 | 用途 | 邊界 |
|---|---|---|
| AnimationPlayer | 作者編排技能、鏡頭、特效track | method track只觸發表現，不扣費傷害 |
| AnimationTree | 多狀態動畫混合確有需要時 | 不用於權威回合狀態機 |
| Tween | hover、位移、淡入與短互動 | 新效果取代同屬性舊tween，離場kill／綁node |
| AnimatedSprite2D／AnimatedSprite3D | 逐格sprite | 與Sprite3D texture/frame用途區分 |
| Shader | 閃白、溶解、局部材質效果 | 依renderer支援確認uniform與shader API |
| GPUParticles2D/3D | 爆發、環境粒子 | 數量、overdraw及裝置成本有budget |

Card Selected → Domain Validated → Effect Resolved → Presentation Event → Animation。結果揭露、是否可skip與何時能再提交依正式規格／UX契約；演出缺失、掉幀、skip或切場景不能改變Domain outcome。hit-stop避免全域time_scale干擾其他系統，先界定局部表現範圍。

## 品質驗收

在明列硬體／OS／renderer／解析度／場景的條件下測alpha sorting、depth artifacts、camera clipping、foreground occlusion、縮放鋸齒、texture filtering、陰影、shader兼容、長寬比及UI清晰度。記錄draw calls、GPU／CPU frame time、p95／峰值及texture memory；budget由平台目標設定，不能假設所有手機60fps。headless僅驗證載入／邏輯，畫質與GPU效能需有畫面實機證據。

官方依據：[Viewports](https://docs.godotengine.org/en/4.7/tutorials/rendering/viewports.html)、[Renderers](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html)、[Animation](https://docs.godotengine.org/en/4.7/tutorials/animation/introduction.html)、[Sprite3D](https://docs.godotengine.org/en/4.7/classes/class_sprite3d.html)、[Tween](https://docs.godotengine.org/en/4.7/classes/class_tween.html)。
