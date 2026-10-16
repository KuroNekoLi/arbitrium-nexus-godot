# PNG Capture 寫入靜態修正工程說明

## 主控整合收據（覆蓋下方委派施工時的NOT_EXECUTED快照）
正式Master38726127041已completed/success，受測f16227c，writer46/46；下方pending為當時快照。原GUI仍未重跑。

受測source f16227c1e67457de53b3547a73462416c32349ef。主控file-only首輪46執行/45PASS/1FAIL，SW-16發現Windows recursive mkdir在namespace為普通檔案時可能回OK；新增conversion前的檔案存在檢查，未改oracle。
staged Actions38722977144 completed/success，writer46/46嚴格Gate通過；Master38726127041待核對。原GUI runner完全未重跑，原14/16維持GUI_NOT_VERIFIED。
獨立Lv40靜態capture兩尺寸已解碼驗證並目視；不是原輸入測試、真人或GPU benchmark。此分支合併收據已清除；下方「本輪沒有run」限定委派Agent階段，不能誤讀為主控沒做這些驗證。

日期：2026-10-15。狀態：`IMPLEMENTED_NOT_VERIFIED`；helper 測試為 `TEST_WRITTEN / NOT_EXECUTED`。本輪沒有執行 Godot（包含 `--version`、import、parse、headless helper 與 GUI runner），沒有新截圖、runtime log、CI run、commit 或 push。

## 來源與差異

指定 worktree：`C:/Users/user05/.codex/worktrees/p4-final-integration/referenced-chatgpt-conversation-this-is-an`。讀取時 HEAD：`5349950e929546515f0669ae433beaf3c4281d63`；分支：`integration/p4-final-playable-20261015`。本機 master：`5103e40a4b95da82f2561b29c2604e9514fd398b`。使用者簡稱 `origin/integration/p4-reviewed` 不存在；實際來源為 `origin/integration/p4-reviewed-20261015`，SHA `2cdcd01d65f59e21f2d50490176dd0f11dc9209a`，唯讀 `git ls-remote` 亦得到同一 SHA；沒有 fetch 或更新 refs。

已讀根目錄 AGENTS、QA 與 architecture SKILL.md，以及各自 Spec Guardian、QA_CI_STANDARDS、GDSCRIPT_STANDARDS、GAME_ARCHITECTURE 與文件22工程契約。`project.godot` 宣告 Godot 4.7、Compatibility renderer；這不證明本機完整引擎版本。歷史第三輪 log 的引擎為 `4.7.2.stable.official.ed1daf0bf`，不當成本輪環境證據。既有 SceneTree runner 與 `.github/workflows/godot-p4-hud-headless.yml` 已靜態檢視；後者未納入本 helper suite，不宣稱 CI 已覆蓋。

| 同名 runner 比較 | master／本輪修改前 | reviewed 來源 | 本輪處理 |
|---|---|---|---|
| PNG 路徑 | 固定 `res://outputs/<capture>.png`，直接 save_png | 以 `path.replace("p4_3", capture_prefix)` 改名 | 固定安全 scope 下的 namespace；不搬移或更名舊 PNG |
| prefix | 無 | `--capture-prefix=` 後 validate_filename | 嚴格拒絕非法值／重複參數，沒有靜默清洗 |
| capture assertion ID | 原始 capture 名稱 | 隨 prefix 改 ID | 保留原始 ID，prefix 只影響輸出目錄 |
| 鍵盤 | physical_keycode | 另加 keycode | 本輪不採入，超出 PNG 寫入修正 |
| Reaction panel 不可見 | 繼續既有流程 | 提早報告並 quit | 本輪不採入，不變更原流程或 assertions |

本輪以 `git show origin/integration/p4-reviewed-20261015:outputs/p4_logs/p44_input_attempt3.log` 讀到：`P4_INPUT_REPORT executed=16 passed=14 failed=2`。失敗恰為 `P43-CAPTURE-p4_3_drag_1280` 與 `P43-CAPTURE-p4_3_eight_1920`，兩者都有原始 `Can't save PNG` 路徑／backtrace；其餘14項通過。此證據只證明兩次 PNG save 失敗，無法分辨鎖檔、權限、磁碟或其他 I/O 原因。master 上較早的16/16 log不能取代此第三輪結果。

## 寫入契約與所有權

僅修改 `tests/test_p4_input_capture.gd`；新增 `scripts/qa/screenshot_writer.gd`、`tests/test_screenshot_writer.gd` 與本 note。主控其他檔案變更不屬本包；不編輯 battle_screen、場景、Domain、RTM、CI、project.godot 或既有證據。四檔所有權與主控互斥；交接後由主控統一執行與提交。本包透過 apply_patch 編輯。

helper 是 RefCounted，僅接收 Image，沒有 scene、viewport、input、計時等待或 Domain 依賴。GUI runner 仍自行等待 frame_post_draw、取得真正 viewport Image；helper 測試的小圖不構成 GUI 證據。

輸出限定 `res://outputs/p4_input_capture/<namespace>/<original_capture_name>.png`。未給 prefix 使用 `default`；明示 `--capture-prefix=<value>` 使用該 namespace。名稱限1至80個 ASCII 英數字、底線與連字號，拒絕 Windows device names、路徑分隔、冒號、點號、空白、空值及 traversal；不接受任意 output-root。prefix 不自動生成：未來取得 GUI 重跑授權時，由主控指定獨特 run prefix；重用同一 prefix／capture 名即明確失敗，不自動後綴、重試或覆寫。改輸出目錄的目的是工程隔離，並非取得第四次執行許可。

建立目錄的結果會檢查；拒絕既有輸出目錄 link。目標存在（檔案、目錄或 link）即碰撞失敗。用 `<target>.lock` 目錄建立作為同 helper 間的原子 reservation，持有後再次檢查目標，寫入後釋放；既有 lock 不自動清除。寫入錯誤會回報 `stage/path/error/error_name/detail`，cleanup 錯誤另帶 `cleanup_error` 並使 ok=false。失敗留下的部分 PNG保留診斷，下次視為碰撞，禁止自動覆寫。

成功條件為 save_png 回傳 OK，且目標存在、可讀、非空、PNG signature 正確、可解碼且尺寸等於來源 Image。capture check 每次仍只計一個既有 assertion；不改原16項的 IDs、遊戲 expected conditions、輸入、等待、解析度、fixture 或報告／exit 規則。新增 JSON diagnostics 不額外印 PASS、不吞掉 failure。

## 需求與測試追溯

下列需求來源均為本次使用者明示授權（`USER_APPROVED`），不改任何戰鬥規則。四檔範圍不包含 RTM，故在此記錄局部追溯供主控整合。

| 需求 | helper／runner 實作 | 案例／oracle | 證據狀態 |
|---|---|---|---|
| SW-SCOPE 安全路徑 | OUTPUT_SCOPE、valid_token、scope link 檢查 | SW-03、06～08：合法邊界／非法路徑拒絕 | IMPLEMENTED_NOT_VERIFIED |
| SW-PREFIX 可選獨特 namespace | prefix_from_args、write_png namespace | SW-09～11、21：預設／合法／重複／隔離 | TEST_WRITTEN |
| SW-COLLISION 不覆寫 | exists、reservation、再次檢查 | SW-04～05、14～15：舊 bytes 不變、目錄／held lock 拒絕 | TEST_WRITTEN |
| SW-ERROR 詳細失敗 | mkdir/save/verify/cleanup result | SW-12～13、16～18：空圖、目錄 blocker、注入寫入錯誤及釋放 | TEST_WRITTEN |
| SW-PNG 實檔驗證 | existence/signature/decode/size | SW-02～03、19～20、22：小圖、假OK無檔、壞PNG、錯尺寸 | TEST_WRITTEN |
| SW-ORACLE 保留原assertions | shot 的單一 check、原 capture ID | 靜態 diff；原 GUI suite 未執行 | IMPLEMENTED_NOT_VERIFIED |

純檔案 suite 使用2×2 CPU Image，先保留獨特測試 namespace，清理由本次 fixture 建立的明確檔案與空目錄，沒有遞迴清除。另以 subclass 注入 save error／假OK／損壞內容／錯尺寸，不用真 GUI、不呼叫原 GUI runner。測試失敗回傳非零，輸出 `SCREENSHOT_WRITER_REPORT executed=... passed=... failed=...`；fixture cleanup 亦有 assertions，數量不硬編為已通過數。

待主控安排（本輪均未執行）：確認其 Godot binary／完整版本、必要 import、三個 GDScript 的 check-only，以及單獨 `--headless --path <project> --script res://tests/test_screenshot_writer.gd`。保存命令、exit、原始 stdout/stderr、實際 summary 及 SCRIPT ERROR 檢查；失敗／重跑次數由主控統一記帳。純 helper 結果不提升 GUI 14/16，也不等於 PNG 問題已在原 GPU 環境重現或修復。不要執行原 GUI runner、複製改名 runner、以 prefix 重設配額。

本輪已執行的靜態檢查：指定 runner 的 `git diff --check` exit=0；四個 owner 檔逐行檢查無行尾空白。PowerShell 將 HEAD 與修改後 runner 自 `func mouse(` 至 EOF 作逐字比較，結果 `STATIC_CAPTURE_FLOW_UNCHANGED_FROM_MOUSE_TO_EOF`；原輸入、run 主體與其 assertions 均一致。runner diff 為8行新增／1行替換，僅新增 helper 宣告、options、shot diagnostics 與寫入條件。共享 worktree 後續出現主控修改及 import sidecars，本包未建立、修改或清除那些檔案；其存在不構成本包曾執行 Godot 的證據。

## 限制與回退

- Godot parse、執行、CI 與實機 I/O 都是 NOT_EXECUTED。沒有本輪 Godot 版本或 PNG 成果，不能標 PASS／VERIFIED。
- Godot FileAccess／Image.save_png 未提供本 helper 可用的 OS 層 exclusive-create 寫入契約。reservation 防護涵蓋遵守本 helper 的 writers；不保證對忽略 lock 的外部程序具備不可覆寫的原子性。主控必須維持四檔互斥與輸出目錄受控，不讓其他 writer 同時寫同一路徑。
- scope 檢查以可信的 project root 為前提，拒絕已存在的 outputs／scope／namespace symlink；無法防惡意程序於檢查後替換 junction/link 的 TOCTOU。不是任意不可信 filesystem 的沙箱。
- 程序被終止可能留下 reservation 或部分 PNG；由主控查明 owner／狀態後手動處理，本 helper不自動刪除。測試未覆蓋真實磁碟滿、ACL、Windows sharing violation、link race、多程序壓力與 cleanup 失敗；注入錯誤不等同實機重現。
- 輸出路徑由舊 outputs 根目錄移至上述 scope，舊 screenshot consumers 若寫死路徑須由主控另行評估。此包不搬移、複製、重命名或刪除歷史 PNG。
- 回退只撤銷本包 runner shot／新增宣告，移除三個新增檔；不回退主控工作、不更動歷史14/16證據或 GUI 執行上限。
