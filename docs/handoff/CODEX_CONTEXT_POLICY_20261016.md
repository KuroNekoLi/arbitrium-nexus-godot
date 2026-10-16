# Codex Context Policy

本機與本工作樹原本沒有 `.codexignore`。2026-10-16 查核本機 `codex --help` 與官方 Configuration Reference，未找到其自動套用契約。因此本檔作為 **ripgrep 明確載入的規則**，由 AGENTS.md 指定使用方式；不宣稱 Codex 自動忽略，也不是秘密保護或權限設定。

一般探索排除生成物、raw logs、outputs、archive、Legacy 素材及 SimpleCards 第三方實作。現行程式、測試、正式規格、Skills、驗收報告及交接仍可探索。需要除錯時明確讀取被排除的檔案；不刪除或取消 Git 追蹤。

不修改全域模型、reasoning、Skills、權限或 AGENTS 載入上限。過往對話不會因此縮短，大型輸出仍需由 Agent 控制。

官方 GPT-6.1 Sol 模型頁列出 Standard 短上下文每百萬 token：輸入 $2、快取讀取 $0.10、快取寫入 $2.50、輸出 $10。API 價格不是 Codex 訂閱額度公式，也不保證命中；本次未量測節省百分比。

來源：
- https://developers.openai.com/api/docs/models/gpt-6.1-sol
- https://developers.openai.com/codex/config-reference

驗證方式：比較 `rg --hidden --files -g !.git/` 與 `rg --hidden --ignore-file .codexignore --files`。首次驗證發現 ripgrep 預設跳過隱藏的 `.codex/skills`，已在指令加上 `--hidden` 修正，不刪除必要 Skills。確認必要檔案可見、排除項不可見。沒有重跑受限 Godot 測試。本批不是遊戲視覺驗收。

角色圖與法術／失能 CG 的現役 runtime 狀態，改依 `docs/ui/BATTLE_UI_VISUAL_ACCEPTANCE.md` 查核；Editor-only Atlas Preview checkpoint 已結案並移除。
