# Godot 卡牌 RPG Skills — 使用入口

目前 **8 個可發現的 Skill** 位於 `.codex/skills/`，對應可攜式套件 `tools/godot-card-rpg-development-skills/skills/`；共同規範主本位於 `tools/godot-card-rpg-development-skills/references/`，每個 Skill 自帶必要 references、agents/openai.yaml，可獨立啟動。既有遊戲的玩法與 M1～M5 驗收以 `docs/combat/`／`docs/verification/` 為準；Skills 不替代已核准的 Domain Rules。

## 直接用自然語言啟動任務

- 「**製作魔法學院訓練場場景**」→ `godot-card-rpg-orchestrator` → `godot-resource-library-manager`（自動索材）→ `godot-game-asset-pipeline`（加工／匯入）→ UI/Rendering/Architecture（實作）→ QA（真實驗收）。
- 「**生成火系卡牌插畫**」→ Asset Manager 先查倉庫、有工具才 clean-room 生成，Asset Pipeline 做獨立圖文分離、卡牌外框和 Preview。
- 「**Boss 攻擊動畫**」→ Asset Manager 查既有 SpriteFrames/效果素材，Pipeline/Rendering Agent 完成獨立 Actor／VFX 動畫，再由 QA 比對 Domain Events。

使用者不必自行指定素材網站。低風險素材 Agent 可在範圍及授權預算內自選自用；重大主角／Boss／正式背景／Style Bible／插件等選型需提供 **Major Asset Decision Report：推薦項 + 真實候選、授權、品質、效能、成本、回退**，正式定案前由使用者確認。未知授權、付費或工具不可用時應停下或給替代提案，不能假稱已下載或已完成。

## 八個角色

1. `godot-card-rpg-orchestrator`：整合與路由。
2. `godot-resource-library-manager`：免費／開源素材搜尋、外部 Vault 下載、索引、選材和重大採用報告。
3. `godot-game-asset-pipeline`：生成素材後製、正式 Godot 匯入、Asset Manifest/Credits。
4. `godot-architecture-engineer`：Scene、Signal、Domain adapter。
5. `godot-card-combat-engineer`：權威戰鬥 Domain，只有已批准玩法可調整。
6. `godot-2-5d-rendering-engineer`：渲染／VFX／角色與 Boss 動畫。
7. `godot-card-rpg-uiux-engineer`：HUD、卡牌、繁中英文、使用者互動。
8. `godot-qa-ci-engineer`：實際 Godot、CI、畫面與 Replay 驗證。

## 維護與驗證

更新 Skill 時須同步 `.codex/skills/` 和 `tools/godot-card-rpg-development-skills/skills/`，共享 reference 同步 `tools/.../references/` 主本；執行套件 `scripts/validate_bundle.py` 和 `evals/test_skill_tools.py`（**必須真實執行才可宣稱 PASS**），並更新 `bundle_sha256.json` 以保存對應校驗資料。測試僅是 Skill 工具結構，不代表遊戲已完成。

詳細 Resource Scout: `docs/ui/03_FREE_OPEN_SOURCE_RESOURCE_SCOUT.md`。本次變更只增補 Skill 規範與文件，不下載素材、不啟用付費 API、不修改 Gameplay。過去的 `docs/skills/VALIDATION_REPORT.md` 為歷史報告，不可用其七項舊版驗收代表此八 Skill 新版已通過。
