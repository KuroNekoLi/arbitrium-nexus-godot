# P4.1 Battle Scene Foundation — 工程與驗收

來源基準：7163aeff0de1f93b2c1a05e20bf7a3c3899333b7。需求：Combat Phase4 Handoff P4.1、UI01/04、CORE-03、CORE-04、Implementation Contract §2。內容仍FIXTURE_ONLY／BALANCE_PROVISIONAL。

## 目標與責任

`battle_screen.tscn`為可獨立啟動的Control組合根：Design設計畫布、背景TextureRect、Arena/Y-sort、3個BattleActor及Boss、被動HUD插槽。`battle_actor.gd`只管腳底anchor、SpriteFrames和局部Tween；`battle_presentation_adapter.gd`把M5快照投影成深複製VM。舊main保留，不動其規則或測試。

與Android對照：SceneTree類似View/Compose樹；PackedScene像可重用UI元件工廠；SpriteFrames為獨立美術定義；Adapter像ViewModel的UI state projector。角色slot只是演出座標，不是遊戲移動格。

## 選型ADR／資源

A Node2D＋Y-sort實際載入三組3×3動畫、compact diagonal腳底位置(438,458)/(497,421)/(549,388)，近大遠小；Boss高度325不碰上下邊界。B相同資產／1280×720正交Sprite3D spike成功渲染，5 draw calls，圖片見outputs；靜態構圖可等效，但不帶來本輪所需額外能力，且需3D input／alpha／動畫維護。C Hybrid增加render target，不實作；沒有假報C性能。採A作本輪可逆預設，不切renderer。GPU跨平台／手機p95尚未測。

背景、actor、boss、atlas沿用已有資產，沒有新下載／外部Vault（Documents未找到catalog）；重用優先避免無目的取得pack。原資產來源證明不足，manifest標PROVENANCE_PENDING＋REUSED_PLACEHOLDER，不能稱已清權可商售。Boss舊atlas含鄰近紫色片段是已知美術缺口，不以裁去Boss武器掩蓋。Kenney框包內CC0已核對。SimpleCards本地未附LICENSE，upstream MIT可讀，後續補notice，不升級插件。

## 真實測試與證據

Godot `4.7.2.stable.official.ed1daf0bf`，Windows、NVIDIA GTX1650 OpenGL3.3 Compatibility。命令：`Godot --headless --path . --editor --import --quit`；`Godot --headless --path . --script res://tests/test_p4_scene.gd`。首次8/8 PASS、exit0，無SCRIPT ERROR。檢查四slot、真Domain三人/AP、逐格動畫、兩解析度、free與fresh reentry。

真渲染：`Godot --path . --script res://tests/capture_p4.gd`及`capture_p4_depth_spike.gd`，exit0。`outputs/p4_1_1280.png`、`p4_1_1920.png`、`p4_1_sprite3d_spike.png`已實看1280與B；完整logs在outputs/p4_logs。Headless不當畫質證據。原本work/simple-cards-v-2嵌套專案被Godot忽略warning保留，與本場景無關。

完整回歸由`tools/run_p4_regression.ps1`首次執行31個runner全數exit0，1238/1238 Domain assertions、100/100 seeds及4legacy PASS，原始log在p41_regression。GitHub CI待本commit推送後核對，未完成前不將遠端Gate標VERIFIED。

## 學習與追問

為何用Control包Node2D？可讓UI與世界共享設計畫布但各管責任；Y-sort按腳底而非貼圖中心排序。為何深複製VM？避免可變Dictionary別名讓UI寫穿權威狀態。為何Tween不扣HP？播放、skip、銷毀與FPS不能影響已提交交易。

面試追問：Resource共享和runtime實例差異？如何驗證離場Tween釋放？如何處理異比率letterbox？答案可由Scene重入測試、VM別名測試與尺寸Gate重現。

官方延伸：[Scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html)、[2D animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html)、[Sprite3D](https://docs.godotengine.org/en/stable/classes/class_sprite3d.html)。本輪閱讀官方Scene organization後沿用組合根注入，避免子場景耦合其他場景路徑。
