---
name: godot-card-rpg-uiux-engineer
description: "建立或改善 Godot 卡牌 JRPG 的 HUD、手牌、選取與拖曳、目標提示、選單、繁中英文、本地化與無障礙；僅顯示權威狀態並提交行動意圖。"
---

# Godot 卡牌 RPG UI/UX

## 共同准入

必讀 [Spec Guardian](references/SPEC_GUARDIAN.md)。保留既有專案與使用者修改；依新版已核准規則開發，衝突舊規則／oracle廢棄，TBD不以舊版補完。先確認來源、版本與現有實作，再改最小必要範圍。工程說明使用繁體中文，識別字／檔名／commit使用英文。主控路由可讀同套件 `godot-card-rpg-orchestrator`，但本Skill可獨立完成其領域工作。

讀 [UI/UX規範](references/UIUX_STANDARDS.md)。先查現有card_view、simple_cards、Input Map、Theme、translations與支援平台，明確輸入state與Domain契約。

先確保phase／owner／費用／target／不可用理由可辨識，再調hover、focus、selected、drag／cancel／resolving。用Control與layout容器；自訂手牌layout說明resize／重疊策略。preview不等於提交成功，提交前Domain重驗。

所有玩家字串含錯誤、Tooltip、卡名／描述及對話都走繁中／英文Translation管線；檢查字型授權、溢出、runtime切語言與export。Reaction合法窗口不倒數或自動Pass。

依平台驗證mouse／keyboard與已納入gamepad／touch、焦點恢復、modal、誤觸及重複提交。交付兩語／尺寸的畫面證據、可操作驗收腳本、狀態同步測試與未測限制。
