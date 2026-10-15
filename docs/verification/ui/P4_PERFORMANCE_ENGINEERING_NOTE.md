# Phase 4 — Performance / Capture Harness Engineering Note

**Status: IMPLEMENTED_NOT_VERIFIED / NOT_EXECUTED.** 2026-10-15。Owner: Performance QA。此分支只新增工具、runner、測試、Note、Checklist及本包回填，不改Domain、UI、渲染設定、project.godot或原P4.4 GUI測試。原P4.4第三輪14/16（兩PNG寫入失敗），第四輪未獲批准；這個全新profile runner**不是原Gate的重跑或通過證據**。

## API / implementation

- `tools/qa/p4_profile_metrics.gd`：`summarize(values,units)`、`aggregate(samples,units)`、`percentile(sorted,fraction)`、`scoped_run_id(value)`、`write_new(path,payload)`。空樣本與全部缺失回傳null，NaN／INF／負數／非numeric拒絕；mean、p50、p95線性插值、peak，保留missing count。寫入限定 `res://outputs/p4_performance/` 且拒絕相對路徑跳脫或覆蓋。
- `tests/profile_p4.gd`：GUI-only SceneTree sampler，繼承既有 `battle_screen.tscn` 但不改Controller/Reaction，預設 `IDLE_SCENE_NOT_GAMEPLAY_REPLAY`。可選 `--scene=res://scenes/battle/...tscn`（檔案不存在拒絕）、`--profile=...`、`--run-id=...`、`--warmup=...`、`--samples=...`。固定1280x720/1920x1080，warmup至少3最多600、samples5..1000，有限 wall time。每尺寸另記 viewport frame interval、Performance.TIME_PROCESS、CPU/GPU viewport時間、canvas draw calls、GPU memory；讀不到或0依測量限制記null，不標「沒有成本」。PNG要有真正Image、正確尺寸、檢查save_png回傳Error，不覆寫其他run。
- Metadata：Godot完整version、作業系統/CPU/GPU名稱、rendering method/driver、profile/scene/resolution、debug、VSync與Engine.max_fps、warmup/sample數。Frame interval可能含VSync；Render CPU不包含GDScript；GPU時間在Compatibility renderer可能無法提供，當缺值。
- `tests/test_p4_profile_metrics.gd`：空／單筆／錯型別／NaN/INF／null缺值／p95／路徑安全與不合格式的負向oracles。

## Official Godot API sources

- RenderingServer `viewport_set_measure_render_time`, `viewport_get_measured_render_time_cpu/gpu`, `viewport_get_render_info`, `get_video_adapter_name`: https://docs.godotengine.org/en/stable/classes/class_renderingserver.html
- Performance `get_monitor`, `TIME_PROCESS`, `RENDER_VIDEO_MEM_USED`: https://docs.godotengine.org/en/stable/classes/class_performance.html
- `DisplayServer.window_get_vsync_mode`: https://docs.godotengine.org/en/stable/classes/class_displayserver.html

## Execution gates (not run)

1. 真實Godot 4.7.2（GUI/OpenGL Compatibility）先執行 `godot --headless --path . --editor --import --quit` 匯入及 `godot --headless --path . --script res://tests/test_p4_profile_metrics.gd` 純統計測試。
2. 在有視窗和GPU的機器：`godot --path . --script res://tests/profile_p4.gd -- --run-id=p4_gui_001`，截圖與報告只生成於新runID資料夾；若 Godot headless，工具必須非0退出。兩組解析度單獨檢查capture與數據。
3. 等正式Lv40 UI整合通過後以 `--scene=res://scenes/battle/lv40_battle.tscn --profile=lv40` 在相同硬體新runID重新測量，另錄真實Tape和stress，**不可用idle分數代表戰鬥性能**。
4. 沒有執行環境，本回填為 NOT_EXECUTED：沒有FPS/P95/GPU結果、沒有PNG或人工畫面評審，不能聲稱60FPS或商售品質。

## Android / Kotlin learning & interviews

像Android Macrobenchmark + FrameMetrics：把量測時間、暖機、環境、渲染版本與場景一起版本化，避免在debug/Release或不同設備直接比較FPS；缺GPU讀值必須null而不是0。為何不能用headless當GPU benchmark？headless renderer根本不是目標硬體的render path。如何區分CPU主緒腳本時間與render thread CPU？各自取樣不同監測器，不直接相加當Frame Time。為何要保存原始failed sample？避免只統計快幀造成selection bias。替代方案是外部GPU profiler，但本階段以Godot內建可攜API提供最小可重現證據。
