# Editor-authored battle layout：程式審查與修復

## 基準與範圍

- Master：`bae066ae0dccacc9d058e703e039c82798e13ca2`。
- 待審分支：`refactor/editor-authored-battle-layout`；輸入 HEAD `2def368edf149e994af0107f89091958a521d5b2`，包含三筆尚未推送的本地提交，全部保留。
- 修復提交：`842b294820530fcf8e00fa7ca8de8bb2753a4988`。
- Godot：`4.7.2.stable.official.ed1daf0bf`，Windows，Compatibility。
- 範圍為場景化 HUD、Inspector Skin、角色視覺、輸入命中區與必要 CI 修復。`scripts/domain/`、戰鬥內容與 Replay 規則沒有變更。
- 實際使用 Orchestrator／Spec Guardian、Architecture、UI/UX、QA Skills。未新增素材或外部依賴。

## 審查發現與修復

| 嚴重度 | 問題與重現 | 修復與驗證 |
|---|---|---|
| P1 | Lv40 四個 TargetRegion 的局部原點被保存為 `(0,0)`，命中區在腳下右方；拖到人物身上不一定能選取 | 改回覆蓋立繪的範圍；新增 production scene 幾何測試，檢查可見 CG 中心、目標按鈕與命中區在兩種尺寸的一致性 |
| P1 | Boss hit 的 X 軌道仍是 `0,-4,4,-2,0`，受擊時跳離編輯器設定的偏移 | 以 `_body_base_position.x` 產生軌道；保留原 BA-08 並增加起末點斷言 |
| P2 | Boss 沒有 `base_tint`，既有 feedback-edge 測試中斷一段函式，程序卻 exit 0 | 補共用呈現介面與實際場景色；原 80 項重新完整執行成功，保留 72 項與 SCRIPT ERROR 的失敗 log |
| P2 | Lv40 場景保存了 Editor Preview 的 MOCK_ONLY 提示，遊戲開局仍顯示 | HUD runtime 初始化清空 feedback；新測試斷言初始提示為空，最終 production 截圖確認 |
| P2 | Boss reset 覆寫法陣的旋轉、色調；無 ShaderMaterial 時也會解參考 null | 動畫以保存的色調為基準，reset 保留旋轉；shader 存取加型別檢查。BA-12 用非零旋轉與自訂色調驗證 |
| P2 | 自訂 Skin 只有 ELIGIBLE 圖示、沒有 UNAVAILABLE 時，失能狀態會存取不存在的 key | 缺少 fallback 圖示則隱藏；新增 RS-21。測試第二次因測試本身的 untyped Dictionary 指派中止，已改 typed Dictionary，最終重驗仍待執行 |
| P2 | Visual CI 仍要求 SP gesture 27 項，但現行測試已增加 drag-first 斷言為 28 項 | 更新精確 report 至 28，保留所有原 assertions；本機真視窗 28/28 |

## 實際驗證及限制

原始輸出保存在 [evidence/editor-layout-review-20261018](evidence/editor-layout-review-20261018/)。`-1`、`-2` 是本輪執行序號；失敗檔沒有覆寫或刪除。下表不是所有項目已在最後修復提交重跑的聲明；個別測試是在相同工作樹的修復過程執行。

| 項目 | 實際結果 |
|---|---|
| M1～M5 canonical integration 清單 | 26 suites，1128/1128 |
| 固定 100 seeds 完整戰鬥／Replay | 110/110；100 battles；100 victories；5244 commands；0 rejected |
| 合計 Domain | 1238/1238；保留原 Golden／Replay，未修改期待值 |
| Lv40 playable／P4 integration | 32/32、31/31 |
| Component／command／legacy roster | 24/24、30/30、18/18 |
| Character editor preview | 39/39 |
| Boss scene 最後定向驗證 | 14/14（第二次） |
| HeroRosterSkin | 第一次原版 20/20；第二次新增案例時在 RS-12 後出現 typed Dictionary 錯誤並停止程序；修正後尚未驗收，下一次是第三次 |
| Feedback edges | 第一次程序 exit 0 但有 SCRIPT ERROR、僅 72 項，判定失敗；第二次 80/80、無 SCRIPT ERROR |
| Target geometry | 首次真渲染 20/20；追加 runtime 提示斷言後 headless 19/19；CI headless 期待 19 |
| 其他定向 P4 UI contracts | feedback 45、staging 10、localization 198、readmodel 29、V2 layout 18、context 23、hand 39、face bounds 8、V3 visual 31、card 73、Boss 47、integration 90、roster command 102、resources 32、party 57、intent 35、log 33、convergence 25，全部 failed=0 |
| 真視窗 SP 手勢 | 28/28；使用 Godot 視窗的 pointer input，非真人完成整場戰鬥 |
| Python CI policy tests | 42/42 |
| Editor import | 無 SCRIPT ERROR；有被忽略的本地 `work/simple-cards-v-2` 巢狀專案警告 |
| Editor-authored layout／P4 HUD | 本輪未執行。原交接列為已達三次上限；追加一次的授權詢問待回覆 |

## 真實畫面

- [1280×720 production Lv40](evidence/editor-layout-review-20261018/lv40_1280.png)
- [1920×1080 production Lv40](evidence/editor-layout-review-20261018/lv40_1920.png)

SHA-256：1280 `e916bd826c33742b86f9f107490fce9bde54e17300255454d46eef312d785b7a`；1920 `7cd9cf340da17a5125a4bbf22c50f76d55cdb244baf796240682a59873b6b51b`。

兩張均由修復提交 `842b294` 的正式 main scene，透過 Godot Movie Maker PNG 輸出取得，使用真實 Lv40 開局資料。不是 AI 圖、mock fixture 或額外測試群組重跑。英文與完整真人 Boss 勝利未在此畫面批次驗收。

## CI 與合併 Gate

輸入 Master 原有兩項失敗已查閱實際 job logs：

- [P4 contracts 39070454694](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/39070454694)：Boss 缺少 base_tint。
- [Visual 39009470489](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/39009470489)：SP gesture report 數量仍要求 27。
- [Master Full 39064172049](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/39064172049)：輸入基準 success，僅作歷史證據。

**REVIEWED — MERGE_PENDING_TEST_AUTHORIZATION**。尚未 merge 或 push；尚無本次遠端成功 CI，不可引用上列 runs 代替本次驗收。Push 現有 refactor 分支或 Master 會自動觸發已達上限的兩組測試，故等待授權後只發起一次適用 CI，避免分支與 Master 重複執行。

## 工程學習與回退

Scene 保存幾何與 Resource，腳本負責資料投影與短暫演出；如同 Compose 的可調整視覺元件接收 immutable UI state。`AnimationPlayer` 的關鍵影格是絕對值，因此應先記錄場景基準，再加上受擊偏移。只斷言動畫名稱存在，抓不到角色水平跳動。

Skin 是共享 Resource：呈現時複製需染色的 StyleBox，不能改共用模板。顯示圖示缺省應安全隱藏；Dictionary 輸入仍須符合 Godot typed collection 的型別契約。

零 exit code 不代表驗收成功：SCRIPT ERROR 可中止 coroutine 而讓後續 runner 繼續，必須同時檢查 report 精確計數與 raw log。此次 72/72 的假綠燈即為實例。

獨立差異複查涵蓋 serialized Node 引用、signal forwarding、locale 原地更新、Skin 訂閱清理及 Domain 差異；未發現需另建戰鬥規則的理由。回退修復可 revert `842b294`；原分支與全部使用者場景調整仍在歷史中，無資料格式遷移。
