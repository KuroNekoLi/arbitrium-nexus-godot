# Master 整合交付紀錄

使用者授權：審查所有未合併分支，最後合併至 master；Combo Domain／GUI 維持暫緩。

- Base：`50bf7b19b2f9c3d66c1a8cd267bd20ef7f56b4cd`。
- 審查 branch：`codex/review-all-unmerged-20261016`。
- 程式修正：`a5e007e`；history-only merge：`b81702b`；workflow 修正：`15d5f3c`。
- 新功能分支：Combo V2、箭頭 PoC、法術投射物、角色 state CG；來源及 SHA 見 `BRANCH_INVENTORY.json`。
- 較舊 P4／M5 分支：保存 Git parents；不恢復退役八卡、硬編碼角色、舊勝敗規則或過時 CI。
- 本機 Godot presentation：126/126；CI 工具 unit tests：41/41；43份 YAML：0 parse／duplicate errors。
- [審查分支遠端 CI #38897092900](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38897092900)：**未啟動**，GitHub 回報付款失敗或 spending limit。這不是 Godot 測試結果；不標 PASS。
- [原角色 CG workflow #38897091696](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38897091696)：原始 workflow 無效；已修正，43份 strict YAML 檢查通過，原始 YAML 保存在 historical-source。
- Combo Domain136/142、GUI258/260：保留三輪紀錄，修正後未重驗，使用者明確維持暫緩。
- 新視覺皆為可替換 placeholder；三份既有 state atlas 為來源待確認候選，不宣稱正式美術採用。未生成／下載新圖。

Master 最終合併 SHA、遠端推送及 ancestry 檢查將附於下方；未 force push、未刪除來源分支。
