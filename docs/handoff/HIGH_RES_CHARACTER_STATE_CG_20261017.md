# 高解析角色狀態 CG：獨立驗收

## 角色分工

強模型已替換角色素材、完成聚焦 code review 與本地 Godot 驗證。請低成本模型只驗收，不修改實作、不放寬斷言；此環境無法替使用者切換模型。

## 範圍與提交

- 目標提交：`8594cd4a4c24484d548a4bc8c3b3439de21d5ce0`（`feat: replace character state CG with high-res sheets`）。
- 將 Ren、Akane、Tsumugi 狀態圖從 256×320 WebP 更換為使用者提供的 1024×1280 透明 PNG；registry 依角色素材識別切分狀態圖，不改戰鬥規則。
- 避免把驗收輸出或使用者其他工作區變更納入提交。

## 驗收方式

在此提交建立乾淨的暫存 checkout。Godot 4.7.2 Windows 若因 GitPlugin 外掛 DLL 不在 checkout 而無法載入，可只在暫存 checkout 的 `project.godot` 移除 `version_control/plugin_name`、`version_control/autoload_on_startup` 兩行；不可修改來源提交。

使用 Godot 4.7.2 執行：

```powershell
Godot_v4.7.2-stable_win64.exe --headless --path <checkout> --script res://tests/test_p4_character_state_cg.gd
Godot_v4.7.2-stable_win64.exe --path <checkout> --audio-driver Dummy --rendering-method gl_compatibility --script res://tests/capture_p4_v35_hud.gd -- --capture-prefix=lowcost-cg-hud
Godot_v4.7.2-stable_win64.exe --path <checkout> --audio-driver Dummy --rendering-method gl_compatibility --script res://tests/capture_p4_last_spell_retirement.gd -- --capture-prefix=lowcost-cg-retirement
```

預期結果：`STATE_CG_REPORT executed=39 passed=39 failed=0`、`V35_CAPTURE_REPORT executed=63 passed=63 failed=0`、`RETIREMENT_RENDER_REPORT executed=37 passed=37 failed=0`。目視確認 `outputs/p4_input_capture/lowcost-cg-hud/vis01_idle_1280_zh.png` 三名角色銳利且無切圖錯位，以及 `outputs/p4_input_capture/lowcost-cg-retirement/ret_ko_1280_zh.png` 的失能圖和肖像正確。記錄實際 commit、命令、報告、失敗與截圖觀察。

## 已知限制

- 本地強模型在目標提交已取得上述 39/39、63/63、37/37 結果，並目視檢查新素材待機和失能畫面；低成本 AI 仍需對乾淨 checkout 獨立重驗。
- 圖片由使用者提供；生成工具、模型、prompt 與授權來源資訊未知，已在素材來源記錄標示，Canonical 採用狀態仍為 provisional。
- 測試不得重跑既有已寫入的輸出 prefix；每次使用全新 prefix。驗收不得改圖、改 registry、改測試或清理既存使用者檔案。
