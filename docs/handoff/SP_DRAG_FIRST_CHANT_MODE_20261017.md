# SP drag-first 詠唱模式驗收交接

狀態：ACCEPTANCE_PENDING。請由較省 token 的 AI 對指定提交做一次獨立驗收；通過後刪除此文件及 README 對應項目。

## 目標與範圍

只有在卡片按住至少 450ms、且尚未開始拖曳時，才切換完整詠唱。若先開始拖曳，該次手勢固定為瞬發詠唱，即使瞄準耗時超過 450ms。已先長按再拖曳的操作仍應使用完整詠唱。

## 實作與 review

- 實作提交：`2a0fc02075d0a13243c18aeed087e60119964bc7` (`fix: keep chantless mode for drag-first card gestures`)
- 變更：`scripts/battle/ui/battle_card_view.gd`、`tests/test_p4_sp_drag_gesture.gd`、`docs/ui/V35_SP_GESTURE_DECISION_20261016.md`
- 獨立 code review：未發現阻斷問題；確認 SimpleCards 在子類該幀的計時邏輯前設定 `holding`，因此拖曳開始後計時停止。
- 強 AI 本機 GUI 執行結果：Godot `4.7.2.stable.official.ed1daf0bf`，`SP_GESTURE_REPORT executed=28 passed=28 failed=0`。本機原始輸出位於 `%TEMP%\arbitrium-sp-gesture-gui-out.log` 和 `%TEMP%\arbitrium-sp-gesture-gui-err.log`。

## 獨立驗收步驟

1. 確認 `git rev-parse HEAD` 是 `2a0fc02075d0a13243c18aeed087e60119964bc7`，工作樹中包含且沒有覆寫後續 handoff 文件變更。
2. 使用 Godot `4.7.2.stable.official.ed1daf0bf` 在 Windows 視窗模式執行唯一必要案例 `tests/test_p4_sp_drag_gesture.gd`：

   ```powershell
   $godot = 'C:\Users\user05\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe'
   $stdout = Join-Path $env:TEMP 'arbitrium-sp-gesture-acceptance-out.log'
   $stderr = Join-Path $env:TEMP 'arbitrium-sp-gesture-acceptance-err.log'
   $p = Start-Process -FilePath $godot -ArgumentList @('--path', (Get-Location).Path, '--script', 'tests/test_p4_sp_drag_gesture.gd') -PassThru -Wait -NoNewWindow -RedirectStandardOutput $stdout -RedirectStandardError $stderr
   Get-Content $stdout
   Get-Content $stderr
   if ($p.ExitCode -ne 0) { exit $p.ExitCode }
   ```

3. 記錄實際 Godot 版本、case 輸出、exit code。預期 `SPG-DRAG-DOES-NOT-BECOME-FULL`、`SPG-RELEASE-MODE-false`、`SPG-RELEASE-MODE-true` 通過，總結為 `executed=28 passed=28 failed=0`。
4. 不改 runtime、assertions 或規格。若失敗，保留此 handoff，交回較強 AI 修正和 review。

## 範圍外／清理

- 不執行完整 CI、headless 版此 GUI-only 測試或 export；本機 GUI 測試已覆蓋要求的手勢。GitHub Actions 目前因帳戶付款／支出限制不能啟動 runner。
- 獨立驗收通過後刪除此 handoff 及 `docs/handoff/README.md` 的本項索引，再提交清理；保留規格、測試與執行證據。
