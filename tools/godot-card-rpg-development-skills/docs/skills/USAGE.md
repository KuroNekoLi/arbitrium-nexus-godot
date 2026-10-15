# Godot 卡牌 RPG Skills

七個可發現的Skill位於 `.codex/skills/`。完整可攜式套件、規範主本、模板、輔助工具及評估案例位於 `tools/godot-card-rpg-development-skills/`，專業Skill各自攜帶必要references，可獨立使用。

使用 `$godot-card-rpg-orchestrator` 協調跨系統任務，或直接指定專業Skill。所有工作以新版核准規則為準，衝突舊規則及測試oracle廢棄；未決項目不能用舊版補完。

維護套件references後同步套件內及 `.codex/skills/` 對應副本，執行套件scripts/validate_bundle.py與evals/test_skill_tools.py；另比對兩套skill檔案一致。範例評估僅含自我審閱，trigger案例未執行模型benchmark。

研究報告記錄建立時master快照 `8a808cb0ef685fa48633740c6ae4a3f60f370c83`。推送前已快轉至 `b8fae6ae3af3310b2be0b386910dab5b8dc870ae`，其M4.2驗證文件已有後續更新；歷史研究觀察不取代當前工程Note。沒有修改遊戲、戰鬥規格或CI流程。
