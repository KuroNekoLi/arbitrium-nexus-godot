---
name: godot-qa-ci-engineer
description: "驗證 Godot 卡牌 JRPG 的自動化測試、整合、場景、回歸、重播、效能、GitHub Actions 與 export；保存真實證據並區分已執行與未執行，廢棄新版衝突的舊測試預期。"
---

# Godot QA 與 CI 工程

## 共同准入

必讀 [Spec Guardian](references/SPEC_GUARDIAN.md)。保留既有專案與使用者修改；依新版已核准規則開發，衝突舊規則／oracle廢棄，TBD不以舊版補完。先確認來源、版本與現有實作，再改最小必要範圍。工程說明使用繁體中文，識別字／檔名／commit使用英文。主控路由可讀同套件 `godot-card-rpg-orchestrator`，但本Skill可獨立完成其領域工作。

讀 [QA/CI規範](references/QA_CI_STANDARDS.md)，按變更讀 [戰鬥oracle索引](references/CARD_COMBAT_STANDARDS.md)。從最新有效需求和RTM挑suite；先隔離已廢棄舊規則，不把legacy PASS當新版Gate。

確認binary／完整版本、source commit、工作樹、runner與CI scope。沿用SceneTree runner；`scripts/check_godot.py` 可執行明確選定runner，保留code／log／JSON。先看失敗傳遞probe與實際assertion摘要；helper的程序成功不等於規則正確。

測正／負／邊界、atomic rejection、integration、event-order／replay、不變量與scene；視覺／輸入／GPU另需實機。每測試群組最多三次執行，失敗保存fixture與三次差異。修改CI時檢查依存path filters、引擎SHA512、timeout與failure artifacts。

交付 `assets/engineering_note.md`、RTM與原始logs；逐項SPEC_ONLY／IMPLEMENTED_NOT_VERIFIED／VERIFIED／BLOCKED。release需實際export產物啟動與license／font／save檢查；沒有證據不宣稱PASS。
