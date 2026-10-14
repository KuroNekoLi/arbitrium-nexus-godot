# G0.1 — Godot Headless CI 建置與舊版基線測試

> STATUS: **WORKFLOW ADDED; CI RUN RESULT PENDING VERIFICATION**。本文件描述本 repo 的真實流程；任何 CI PASS 必須以本 repo 的實際 workflow run / logs / exit code 證明。G0 原始稽核見 [PH3_G0_AUDIT.md](PH3_G0_AUDIT.md)。

## 目的

1. 以 `godotengine/godot-builds` 正式 release `4.7.2-stable` 的 **Linux x86_64** zip 取得 Godot。下載官方 SHA512-SUMS.txt 並對所選二進位檔驗證。
2. `--version` 必須以 `4.7.2.` 開頭，`--headless --editor --import --quit` 成功。
3. 明確以 `tests/ci_failure_probe.gd` 確認 Godot Script 程序故意 `quit(17)` 可讓 runner 辨識；若因崩潰取得 17 仍須看 `G0_PROBE_EXPECTED_FAILURE` marker，避免假陽性。
4. 現有原型四個 smoke tests 個別跑：`test_battle_state`、`test_deck_builder`、`test_combat_ui`、`test_turn_flow`；**保留原本 assertions，不為了 CI 綠燈改成新規格**。將 exit、stdout/stderr 存檔並上傳 artifact。
5. 使用 GitHub Actions push/PR/workflow_dispatch 啟動，成功時僅代表 `LEGACY_BASELINE_GREEN`，**不是** Phase1/2 `SPEC_PASS`，不代表新版 M1–M5 已完成。

## 重要限制與歷史規格衝突

- 舊 `test_battle_state.gd` 承認8張牌、兩次出牌上限，**不是**最新核准玩法。
- 舊 `test_turn_flow.gd` 驗證1.5秒 Reaction 自動結束，與 `CORE-04` 「無強制倒數」**直接衝突**。舊測試跑 PASS 只表示舊功能仍在，將來必須反轉測試契約。
- 尚未引入 Domain Command/RNG event hash/replay 的新 M1 驗收；不可將 legacy script 名稱中的 `M1 TESTS PASS` 當成新版 M1 驗收。

## 後續驗證紀錄必填

| 欄位 | 值 |
|---|---|
| Repo | `KuroNekoLi/arbitrium-nexus-godot` |
| Branch | `master` |
| CI Run URL | PENDING |
| Commit SHA | 依實際 run 綁定 |
| Godot bin / --version | PENDING actual stdout |
| SHA512 verification | PENDING actual stdout |
| Import exit | PENDING actual exit |
| Negative probe code / marker | PENDING actual exit / marker |
| Legacy tests 4 scripts / exit codes | PENDING actual logs |
| G0 Gate | 只有上述實際 PASS 後才可標 VERIFIED；其他條件仍依 G0 稽核 |
