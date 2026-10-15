# QA、CI與發行證據

先讀 Spec Guardian與repo22契約。沿用已存在的SceneTree test runners，不強制安裝GUT／gdUnit4。主張驗證成功必須有本輪版本、commit、command、exit、實際assertion報告與logs。舊規格衝突案例廢棄，不保留為新版必過Gate。

## 分層 Gate

| 層 | 驗證內容 | 不能推論 |
|---|---|---|
| Spec | 有效批准、來源／oracle與RTM | runtime已完成 |
| Parse／Import | GDScript解析、資源依存、UID及載入 | gameplay或無runtime錯誤 |
| Unit／Integration | 正／負／邊界、真實resolver串接 | 全部角色／內容均完成 |
| Replay／Properties | RNG、順序、hash、原子拒絕、卡守恆 | 遊戲已平衡 |
| Scene／UX | 真實場景載入、輸入、焦點、兩語UI | headless可證畫質／GPU性能 |
| Performance | 指定硬體／renderer／場景的profile | 所有裝置同效能 |
| Export／Release | templates、preset、資源、執行、license、存檔 | export成功就可發布 |

既有流程可由 `scripts/check_godot.py` 逐一呼叫明確選定的runner並保留JSON及log；不自動挑選所有legacy tests。用同repo `ci_failure_probe.gd` 的expected exit17及marker確認失敗傳遞；故意失敗不能被當成正常通過。

## 命令契約

先找binary，再確認 `--version`。官方4.7 CLI：匯入 `--headless --path PROJECT --editor --import --quit`；解析 `--headless --path PROJECT --check-only --script res://PATH.gd`；執行 `--headless --path PROJECT --script res://tests/ACTUAL_TEST.gd`。所有路徑均須真實存在。helper不提供專案未存在的run_all.gd。

fresh clone的class cache／import需要先建立；在可丟棄checkout驗證可避免污染使用者環境。command有timeout、保存stdout/stderr、code與失敗marker。exit0不保證沒有SCRIPT ERROR或測試內吞錯，交叉檢查runner assertion計數、failed=0、必需案例與error log。warning／ObjectDB leak另行記錄，不用過度寬鬆的grep忽略。

## 測試及除錯

測試資料標明ruleset/content/provisional版本；每個requirement依13對應正／負／邊界及必要event-order／replay。非法action狀態／RNG／events不變、同CardInstance只屬一區、資源不負／合法債務例外、每窗口實際Reaction次數、失效LastSpell不結算、同seed重播一致。

bug report含最小fixture、seed／command tape、expected／actual、source rule、受影響commit、event／state hash、相關logs。先隔離Domain、adapter、scene、asset、renderer／export；只修根因與必要scope。repo同一測試群組最多三次執行；第三次仍失敗交付blocker與三次差異，不改測試名重置計數。

## GitHub Actions

先讀 `.github/workflows/`。已有官方Godot4.7.2下載、SHA512、版本／import、故意失敗probe、M1～M4.2及legacy流程；只增改所需job／path filter，不另建重複pipeline。引擎與templates固定版本；第三方actions按repo供應鏈政策固定可信ref。最小contents:read、明確timeout，failure也保存logs/artifact；secret不進檔案或logs。

CI綠燈須核對run URL、head SHA、job／實際步驟與suite scope；不能直接把舊Engineering Note的PASS套到新HEAD。cache key包含引擎、平台及import／addon依存；fresh import檢查避免cache掩蓋缺檔。修改path filters需驗證跨module依存也會觸發；外部發布不是本Skill預設行為。

## 效能、平衡與發行

profile記硬體、OS、renderer、build、解析度、場景、CPU/GPU frame time、p95與峰值、draw calls、texture memory，與同條件baseline比較。平衡驗收依repo22要求固定多seed至少100場，報勝率／回合／卡手／資源瓶頸／施法中斷及LastSpell參與；不把provisional數值升格Canon。

Export前查實際preset、同版本templates、平台SDK／簽章與資源filter；使用 `--export-release` 或既有debug流程後啟動實際產物，核對中文font／translations、asset notices、save migration、輸入與渲染。未做為NOT_EXECUTED，缺環境為BLOCKED，不能泛稱ALL PASS。

交付套用 `assets/engineering_note.md` 與 `assets/requirements_traceability.csv`；每個里程碑保留已跑／未跑清單、風險、rollback與下一步，不自動跳過未過Gate。

官方依據：[CLI](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)、[Export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html)、[Optimization](https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html)。
