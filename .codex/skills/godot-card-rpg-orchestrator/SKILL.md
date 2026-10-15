---
name: godot-card-rpg-orchestrator
description: "協調既有 Godot 2.5D 卡牌 JRPG 的跨系統開發、除錯、審查與里程碑驗收；先查核正式規格並路由專業技能。單一明確領域工作直接使用該領域 Skill。"
---

# Godot 卡牌 RPG 主控

## 共同准入

必讀 [Spec Guardian](references/SPEC_GUARDIAN.md)。保留既有專案與使用者修改；依新版已核准規則開發，衝突舊規則／oracle廢棄，TBD不以舊版補完。先確認來源、版本與現有實作，再改最小必要範圍。工程說明使用繁體中文，識別字／檔名／commit使用英文。主控路由可讀同套件 `godot-card-rpg-orchestrator`，但本Skill可獨立完成其領域工作。

## 主控流程

讀 [Spec Guardian](references/SPEC_GUARDIAN.md)，先建立需求／來源／權限／版本／scope表。以 `scripts/scan_project.py PROJECT` 輸出唯讀盤點；它只能找來源，不判斷哪份規格已核准。

確認該階段入口Gate後選最少必要專業Skill；不要預載全部references。單一領域直接執行，跨領域依下表定責任。沒有額外agent可在同一agent內循序切換Skill，Skill選用不等於自動獲得多agent或外部寫入權限。

| 任務 | 專業Skill | 先讀reference |
|---|---|---|
| 場景／型別／signals／save／input／重構／審查 | godot-architecture-engineer | GAME_ARCHITECTURE、GDSCRIPT_STANDARDS |
| 卡牌／回合／資源／Reaction／AI／狀態 | godot-card-combat-engineer | CARD_COMBAT_STANDARDS |
| 景深／鏡頭／光影／shader／演出 | godot-2-5d-rendering-engineer | RENDERING_2_5D |
| HUD／手牌／互動／兩語／無障礙 | godot-card-rpg-uiux-engineer | UIUX_STANDARDS |
| 免費／開源素材搜尋、Vault 批次下載／索引／比較、重大採用報告 | godot-resource-library-manager | RESOURCE_LIBRARY_MANAGER |\n| 美術加工／音訊／正式匯入／授權／Godot Asset QA | godot-game-asset-pipeline | ASSET_PIPELINE |
| 測試／回歸／CI／效能／export | godot-qa-ci-engineer | QA_CI_STANDARDS |

## 成果型指令自動路由\n\n接到「製作 XX 場景」「生產 XX 圖片」「為 XX Boss 製作攻擊動畫」等直接成果要求，不需要使用者逐一指出素材網站。先查現有 assets／可共享的 Asset Vault，由 `godot-resource-library-manager` 自動安全選材、按授權／大小限制取得與索引，再由 `godot-game-asset-pipeline` 完成資產加工和 Godot 匯入，最後由 architecture／UIUX／rendering Agent 完成真場景、由 QA Agent 驗證。用戶明說「只做規劃」則僅寫文件，不能趁機下載素材或實作。\n\n普通低風險素材可自動採用；重大角色／Boss／Style Bible、主要場景、難以復原的替換、可執行插件、授權或付費爭議，先產生帶**推薦方案+其他候選**的 `Major Asset Decision Report`，獲用戶核准後再正式採用。沒有下載／圖像工具或不能持久化 Vault，要明確回報而非宣稱完成。\n\n## 工作契約與整合

若多Skills／多agent同時工作，先用 `assets/task_contract.md` 定每位owner可寫檔案、只讀依存、command/event/schema／reason codes、互斥檔案、test ownership及整合順序。共用 `project.godot`、integration resolver、Theme／translation table、RTM各只指定一位寫入者；修改他人範圍先交接，不能整檔覆蓋。

順序通常：有效規格／oracle → Domain契約 → adapter → UI／render／assets → 整合／回歸／實玩。可獨立的素材調研或UI mock並行，但沒有已定Domain契約不得自行補玩法。整合者檢查每個diff、來源與測試scope，保存使用者未提交改動。

## 交付

每階段記錄source commit／decision IDs、changed files、實際測試／未執行原因、seed／replay、規格影響與限制；使用 `assets/engineering_note.md`。與新版衝突的舊規則／oracle廢棄，缺決策列blocker，不由主控決定新玩法。達到該階段全部必要Gate才驗收，不擅自發布或重建工程。
