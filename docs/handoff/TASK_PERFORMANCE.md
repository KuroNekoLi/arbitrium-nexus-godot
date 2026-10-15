# PERFORMANCE — Godot performance profiler / visual acceptance harness

本分支入口就是此檔；繼承的 P4_CHAT_HANDOFF.md 是其他AI的Domain任務，不是本包指令。
Repo: https://github.com/KuroNekoLi/arbitrium-nexus-godot
Branch: `handoff/p4-performance-qa-chat-20261015`
Common base: `977a289654e1470bcda83c6c25c14d4cda4c86ab`。記錄開工實際HEAD；不覆蓋master或其他分支。

## 共通工程契約
先讀AGENTS、orchestrator Skill與Spec Guardian，再按本包閱讀 QA、rendering（只讀現有場景） Skill及其必要references。正式Combat Spec Index／核准補充優先；UI契約不能另定玩法。工程說明與教學繁中，識別字／檔名／commit英文。
P4.4 GUI第三輪14/16、額外重跑仍待批；換分支／Agent不重設配額。共享檔只由owner寫入，不直接merge其他施工分支。僅白名單可寫；無工具則patch + NOT_EXECUTED，不虛構測試、截圖或push。新測試保存失敗log、每群組最多三次，不弱化oracle。

## 實作目標
提供可在本機實跑的效能／視覺驗收工具，讓Codex用真硬體與畫面驗收。聊天端可以寫工具，不能在沒有GPU/Godot時虛構數據。

## 可寫範圍（僅新檔）
- `tests/profile_p4.gd`、`tests/test_p4_profile_metrics.gd`、`tools/qa/p4_profile_metrics.gd`。
- `docs/verification/ui/P4_PERFORMANCE_ENGINEERING_NOTE.md`、`docs/verification/ui/P4_VISUAL_ACCEPTANCE_CHECKLIST.md`。
- 回填 `docs/handoff/CODEX_RETURN_PERFORMANCE.md`；輸出只在 `outputs/p4_performance/`。
- 其他既有程式／素材／Domain／CI／project settings全唯讀；不要新增高權限plugin或改renderer。

## 具體要求
1. SceneTree profiler載入既有battle_screen.tscn，1280x720與1920x1080分開固定warmup與有限採樣；不headless當GPU profile。支援顯式場景參數給未來Lv40使用，但不存在就fail-closed。
2. 記錄Godot完整version、OS/CPU/GPU、renderer、resolution、scene/profile、debug/release資訊、VSync／FPS cap、sample數／warmup；未知資訊明確unknown。
3. 用官方RenderingServer viewport measure API與Performance monitors：frame delta分佈、process時間、render CPU/GPU時間、draw calls、video/texture memory；平均/p50/p95/峰值。單位明確。render CPU不包含腳本CPU，frame時間可能包含VSync，不混為同一指標。API不可用或0不能自動說GPU零成本。
4. 測量不直接修改Domain，不自動推進真人Reaction。可有清楚標為synthetic visual stress的VFX負載，但不混成真戰鬥benchmark；idle、stress、實戰tape應分報，沒有replay就標未測。
5. 新截圖用唯一runID/新資料夾，確保資料夾存在、寫入結果/Error正確回報，避免覆寫舊P4.3證據。保存圖尺寸、場景／語言／狀態metadata；不改舊test_p4_input_capture重置配額。
6. 純metrics helper測空sample、NaN/invalid、單筆、percentile排序與單位、缺GPU資料、檔案失敗；有限time/sample cap、異常必定exit非0，不留下Godot掛住。
7. 驗收checklist具體列三人緊湊斜向層次、Boss不裁切、0/4/8手牌安全區、hover/drag/release/confirm、真攻擊前衝與VFX、兩語、HP/AP/MP/Intent、Reaction不auto-pass、Barrier/Guard/Casting/Break/Exposed、減少動態／靜音、重入。將「自動檢查／需人工觀察」分開。
8. 不宣稱達到60FPS或商售品質，除非同硬體/scene實測並列baseline；沒有實跑則交程式與exact commands + NOT_EXECUTED。不執行需要尚未批准的GUI第四輪。

## 來源
UI01/04/05、現有P4_4_ENGINEERING_NOTE／P4_FEEDBACK_EDGE_AUDIT、Godot官方Performance/RenderingServer文件。若查API只用官方來源，回填精確版本依據。不用新框架替換現有SimpleCards／渲染系統。

## 回填格式（建立本包指定的 CODEX_RETURN_PERFORMANCE.md）
1. Input full SHA、output SHA或patch檔名、環境、PROPOSED_PATCH / IMPLEMENTED_NOT_VERIFIED / VERIFIED / BLOCKED。
2. 逐檔NEW/MODIFY、責任／來源、unified diff及完整新檔；是否超出白名單。
3. 公開API精確簽名、schema／版本／caller changes，依存未完成列BLOCKED_CONTRACT而非猜測。
4. 實際commands／Godotversion／suite／attempt／PASS/FAIL/exit／log／seed/tape/hash；未執行明寫NOT_EXECUTED。保留歷史失敗及配額。
5. Engineering Note涵蓋目標／來源、Godot概念、責任、架構理由／替代、Android/Kotlin對照、測試方法／真結果、面試追問／延伸。
6. Codex下一步最多五項、已知問題、rollback範圍；不reset使用者資料。
有Git工具只commit/push本分支，不force、不合併master、不開PR；否則回傳patch與回填檔。工作包完成不等於P4全部驗收；Codex保留最終整合／回歸／GUI／CI責任。
