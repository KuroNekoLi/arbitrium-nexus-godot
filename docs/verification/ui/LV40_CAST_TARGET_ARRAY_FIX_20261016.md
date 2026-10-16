# Lv40 Casting Target Array Fix — Engineering Note

## Reproduction and source

使用者在本機 Godot 戰鬥執行時回報 `lv40_cast_effect.gd:21 @ settle()`：一般 `Array` 不能直接指定給 `Array[String]`。本機主工作樹當時在 `aaa62a8d516f7aff5e731c93470b3325a68ea0fb`，第 21 行正是 `LastTargets.recipients(...)` 的整批指定；遠端 master `b2496dd1aeae7742eddd94872d3661ebdfcad628` 仍有同樣語法，位置已移至第 23 行。本機主工作樹另有未提交修改，本次只在其未修改過的 cast script 套用同一修正，沒有 pull 或清除其他檔案。

## Change and architecture

`lv40_cast_effect.gd` 的兩個目標清單都先建立 `Array[String]`，再逐一 append `LastTargets.recipients` 回傳的角色 ID。這避免跨 GDScript typed-array 邊界進行整批指定；既有的目標候選、公開意圖、費用、效果次序、退場時機、Domain 事件及 Replay 規則均未修改。Domain 仍決定合法目標與結算，UI 不補算目標。對照 Kotlin：這相當於由動態來源逐個驗證元素後放入 `MutableList<String>`，而非把平台型別的整個集合強轉。

## Evidence and limits

Godot `4.7.2.stable.official.ed1daf0bf`，Compatibility renderer。修正後本機 headless import exit 0、log gate 0 errors；`test_lv40_domain.gd` 83/83 PASS、exit 0、log gate 0 errors，包含 `DEMO-12-FULL-DELAYED`、`DEMO-12-LAST-TWO-ROUNDS` 與 `DEMO-12-LAST-HEAL-EXHAUSTED`。原始日誌在 `evidence/v3_retirement/logs/cast_target_import_20261016.log` 與 `cast_target_lv40_domain_20261016.log`。原始真人 GUI 報錯是使用者提供的堆疊；本次未執行真人 GUI 回歸，也未重跑先前受限的 RET26／原生截圖群組。舊測試曾在另一版本通過，故這次的 83/83 只能證明目前 headless 路徑，不能取代使用者本機重新操作確認。

保留主工作樹的其他未提交修改；正式修正提交到 GitHub master 後，該工作樹仍須在安全處理本機修改後同步其他新版內容。回退可普通 revert 此小改動，不涉及狀態遷移。
