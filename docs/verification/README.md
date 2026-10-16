# 驗證文件索引

## 現行入口

- 規則與程式歸屬：[戰鬥引擎實作契約](../combat/engineering/戰鬥引擎實作契約.md)及[規則與程式對照表](../combat/engineering/規則與程式對照表.md)
- 未完成項目：[待實作與待驗證功能](../combat/engineering/待實作與待驗證功能.md)
- 測試入口、workflow 與觸發：[CI 測試矩陣](../ci/CI_TEST_MATRIX.md)

## 本目錄內容

測試 AI 依當次 handoff 的提交 SHA、核准範圍與測試命令執行；只有目前受測提交的真實輸出可標註通過。保留必要的原始 logs／CI artifacts、測試程式、資產來源及授權紀錄與簡潔的永久狀態摘要。任務 handoff 在驗收通過後移除，驗收證據不隨 handoff 刪除。

- `PH3_PHASE12_TEST_INVENTORY.md`、`requirements_traceability.md` 和 `PH3_M*_ENGINEERING_NOTE.md` 是歷史測試／實作紀錄；標頭中的狀態只代表當時 SHA，不是目前狀態。
- UI review、visual acceptance、Editor Preview 與功能工程紀錄若標示 `NOT VERIFIED`、`NEEDS_REVISION` 或 `USER_APPROVAL_PENDING`，仍保留作為尚未完成工作的依據。
- M2.5、M3.5、M4.5、M5.5 已完成的 acceptance receipts，以及 M4/M5 已完成的 handoff receipts 已移除。詳細舊紀錄可從 Git 歷史與原 GitHub Actions artifacts 追溯；目前測試由現行 workflow 執行並保存新證據。
- 完成的分支整合、merge、cleanup 和交接收據不再放在 `docs/handoff/`；仍未結案的 checkpoint 由 [`docs/handoff/README.md`](../handoff/README.md) 索引。
