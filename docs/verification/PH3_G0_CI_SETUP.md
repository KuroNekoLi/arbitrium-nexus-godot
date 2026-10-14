# G0.1 — Godot Headless CI 建置與舊版基線測試

> STATUS: **G0.1 CI VERIFIED — LEGACY_BASELINE_GREEN; NEW RULES NOT VERIFIED**。本文件描述本 repo 的真實流程；任何 CI PASS 必須以本 repo 的實際 workflow run / logs / exit code 證明。G0 原始稽核見 [PH3_G0_AUDIT.md](PH3_G0_AUDIT.md)。

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
| CI Run URL | [Run 38563701908](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38563701908) — completed / success |
| Commit SHA | `bcc7bdcb5df3e1cb63d64581ae094410a8e04115` |
| Godot bin / --version | `4.7.2.stable.official.ed1daf0bf` |
| SHA512 verification | `Godot_v4.7.2-stable_linux.x86_64.zip: OK` |
| Import exit | `0`; CI job step success |
| Negative probe code / marker | exit `17`；`G0_PROBE_EXPECTED_FAILURE` marker found |
| Legacy tests 4 scripts / exit codes | `test_battle_state=0`; `test_deck_builder=0`; `test_combat_ui=0`; `test_turn_flow=0` |
| G0 Gate | **G0.1 ENVIRONMENT VERIFIED**；整體 G0 尚需完成全量 RTM 對應與新版規格驗收；M1～M5 仍 NOT VERIFIED |

## 實際 CI 證據（2026-10-14）

- Workflow run [#38563701908](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38563701908)；`event=push`；`head_sha=bcc7bdcb5df3e1cb63d64581ae094410a8e04115`；`status=completed`，`conclusion=success`。
- GitHub job ID `115850918437`；下載/校驗、版本與專案匯入、負例探針、四組舊版測試、artifact 上傳等步驟均 `success`。
- `SHA512-SUMS.txt` 驗證：`Godot_v4.7.2-stable_linux.x86_64.zip: OK`；執行引擎 `4.7.2.stable.official.ed1daf0bf`。
- 故意失敗 Probe：console 有 `G0_PROBE_EXPECTED_FAILURE`，實際進程 Exit Code **17**，CI 以反向斷言判為測試成功。這證明 runner 不會把退出碼17誤當成功。
- Legacy tests：`test_battle_state.gd` Exit0（內含 `M1 TESTS PASS // 6 suites` 字樣，但**非新版 M1**）；`test_deck_builder.gd` Exit0（內含 `M5 TESTS PASS` 字樣，但**非新版 M5**）；`test_combat_ui.gd` Exit0；`test_turn_flow.gd` Exit0（此測試仍驗證舊1.5秒超時，**不合 CORE-04**）。
- Artifact：`godot-g0-legacy-headless-logs`，ID `11893533402`，保存14天至 2026-10-28，包含版本檢查與四組測試／探針紀錄。
- **品質警告需追蹤**：`test_combat_ui` 結束時 log 顯示 `WARNING: 4 ObjectDB instances were leaked at exit` 和 `ERROR: 2 resources still in use at exit`；測試 exit0，但這不是乾淨無警告的證據。另 GitHub runner 提示 `actions/checkout@v4`、`actions/upload-artifact@v4` Node 20 deprecation，後續獨立升級。
- 此次只驗證舊版可執行基線；Phase1/2 的新玩法測試尚未執行，禁止以此結果解除規格遷移的 CONFLICT 狀態。
