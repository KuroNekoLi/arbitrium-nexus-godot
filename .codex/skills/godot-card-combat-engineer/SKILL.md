---
name: godot-card-combat-engineer
description: "實作、除錯或審查 Godot 卡牌 JRPG 的回合、個人牌組、AP/MP/RP、Reaction、施法、Last Spell、狀態、敵方 AI 與確定性重播；依最新核准戰鬥規格，不自行平衡改規則。"
---

# Godot 卡牌戰鬥工程

## 共同准入

必讀 [Spec Guardian](references/SPEC_GUARDIAN.md)。保留既有專案與使用者修改；依新版已核准規則開發，衝突舊規則／oracle廢棄，TBD不以舊版補完。先確認來源、版本與現有實作，再改最小必要範圍。工程說明使用繁體中文，識別字／檔名／commit使用英文。主控路由可讀同套件 `godot-card-rpg-orchestrator`，但本Skill可獨立完成其領域工作。

讀 [戰鬥規範](references/CARD_COMBAT_STANDARDS.md)，再按任務讀實際00/01及相關module、18～22。先抽取本次有效requirement、approved／provisional狀態與oracle，與現有resolver及test對照。

以新版規則修正舊prototype衝突；不得把legacy regression當驗收標準。先寫可失敗的正例、負例與邊界，再實作最小Domain transaction。時序任務加event-order，隨機／卡區／傷害任務加replay與不變量；不合法action不得改動資源、RNG或排程。

沿用command／instance／state revision、版本化RNG、M2資源帳本及M3/M4整合接口，避免UI計算或複製成本規則。Enemy AI從合法候選與既定Intent產生決策，記錄tie-break，不增即時走位或反應倒數。

交付 requirement→source→resolver→test→log／seed 的對照、精確scope與未完成項目。fixture-only功能不宣稱可玩內容完成；Last Spell／退款／死亡邊界不得由候選值推論。
