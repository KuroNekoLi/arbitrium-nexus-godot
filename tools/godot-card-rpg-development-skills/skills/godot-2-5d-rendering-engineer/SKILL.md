---
name: godot-2-5d-rendering-engineer
description: "改善既有 Godot 卡牌 JRPG 的 2.5D 場景層次、鏡頭、Sprite3D、光影、shader、VFX 與動畫效能；比較 2D、3D sprites 與 Hybrid Viewport，維持戰鬥規則。"
---

# Godot 2.5D 渲染工程

## 共同准入

必讀 [Spec Guardian](references/SPEC_GUARDIAN.md)。保留既有專案與使用者修改；依新版已核准規則開發，衝突舊規則／oracle廢棄，TBD不以舊版補完。先確認來源、版本與現有實作，再改最小必要範圍。工程說明使用繁體中文，識別字／檔名／commit使用英文。主控路由可讀同套件 `godot-card-rpg-orchestrator`，但本Skill可獨立完成其領域工作。

讀 [2.5D規範](references/RENDERING_2_5D.md)。先查renderer、現有scene與目標平台；用相同資產／鏡頭與明列裝置比較A/B/C，提出ADR與最小presentation spike，保留既有工程。

定視覺slot、depth、framing、zoom／shake、技能與boss演出契約；依需求選AnimationPlayer／Tween／Shader／粒子，只有確有混合需求才用AnimationTree。Sprite3D與AnimatedSprite3D依逐格需求區分。

事件只驅動視覺，不透過動畫回呼決定傷害。skip、掉幀、離場清理不改Domain outcome。確認alpha／depth／filter／shader與實際Compatibility支援，不憑社群Skill升級API。

交付場景／shader／動畫diff、A/B/C取捨、同條件畫面證據與CPU/GPU／顯存profile。未實機看畫面標NOT_EXECUTED；不能以headless通過代替視覺驗收。
