---
name: godot-architecture-engineer
description: "維護或審查既有 Godot 4 卡牌 JRPG 的場景組合、Node 生命週期、Typed GDScript、Resource、signals、存檔與輸入邊界；玩法與視覺需求交由相應專業 Skill。"
---

# Godot 架構工程

## 共同准入

必讀 [Spec Guardian](references/SPEC_GUARDIAN.md)。保留既有專案與使用者修改；依新版已核准規則開發，衝突舊規則／oracle廢棄，TBD不以舊版補完。先確認來源、版本與現有實作，再改最小必要範圍。工程說明使用繁體中文，識別字／檔名／commit使用英文。主控路由可讀同套件 `godot-card-rpg-orchestrator`，但本Skill可獨立完成其領域工作。

讀 [GDScript規範](references/GDSCRIPT_STANDARDS.md) 與 [架構規範](references/GAME_ARCHITECTURE.md)。先追真實入口、依存與目前測試；建立現有component責任圖與最小改動方案，優先重用M1～M4、simple_cards及CG的既有邊界。

為場景／Resource／save/load／input改動列owner、schema、生命週期與失敗契約。對公開API與存檔格式變更提供兼容性／遷移／rollback；不強迫企業架構或候選類別全套落地。UI與動畫不得持有權威規則。

實作型別／空值檢查、共享Resource隔離、signal重複連線與離場cleanup。驗證fresh import、相關runner、重入／場景切換、save-load與輸入重複提交；測試按repo契約選擇，已有新版衝突oracle先廢棄再替換。

審查交付列具體檔案位置、重現條件、影響、規則來源及可驗證修正；沒有實際問題不為湊數提出重寫。交付架構取捨、相容性、實測／未測與工程Note。
