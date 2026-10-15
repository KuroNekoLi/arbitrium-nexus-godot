# ADR：2.5D Presentation 選型

Status：ENGINEERING_PROPOSAL（尚未作正式選型）
Context：現有renderer、scene、平台、畫面目標與規格限制。
Options：A 2D＋Parallax／Fake Depth；B 3D＋2D sprites；C Hybrid Viewport。
Experiment：相同資產／相機構圖／解析度，記錄硬體與build。
Evidence：視覺對照、alpha／depth、CPU/GPU frame time／顯存／draw calls。
Decision：依真實結果填選型、原因、未採方案與成本。
Consequences：Domain不變、輸入映射、依存、風險與rollback。
Acceptance：實機畫面／相同Domain replay／scene重入與演出skip。
