# P4.3 Combat Vertical Slice — 實作／未驗證交接

Status: **NOT VERIFIED / QA_EXECUTION_LIMIT**。本輪已實作，但沒有提交或 push P4.3。不是工具不足，沒有 BLOCKED_BY_TOOLING，也不能引用 P4.2 的綠 CI 為這些修改背書。

## 使用者續作後的驗收（2026-10-15）

使用者明確要求「繼續往下直到完成P4」，恢復本里程碑；原三次紀錄保留，沒有改名／刪除失敗。續作同名 test_p4_integration.gd 首次31/31 PASS，logs/p43_resume_attempt1.log；Scene8/8、HUD36/36、實際Godot視窗輸入16/16 PASS，logs/p43_resume_*。以下QA_EXECUTION_LIMIT為上一輪停止時歷史狀態；修正已由本次實跑驗證。遠端CI待本次獨立提交後核對。

本次完整31 suite回歸亦全部exit0，1238/1238、100/100 seeds及4Legacy PASS，原始log為p43_resume_regression；沒有修改Domain程式。使用者最新授權接續P4.4～6，取代上一輪「停在P4.3」的範圍限制；玩法／美術重大決策約束保留。

## 1. 功能目標與需求來源

Combat Phase4 Handoff P4.3、Implementation Contract §2、UI02/04/05、CORE-01/02/03：玩家選角→持有的CardInstance→合法目標→確認→M5支付／結算→快照與事件→演出。內容使用既有 m5_full_battle_fixture，仍 FIXTURE_ONLY / BALANCE_PROVISIONAL，不宣稱正式角色內容或完整Boss encounter通過。

## 2. Godot 概念與責任

- `battle_controller.gd` Node 是 session owner。begin 深複製初始狀態與 config，submit 唯一呼叫 M5.apply；接受後保存 Command Tape 並 emit detached state/events；拒絕不提交。snapshot()/tape() 不回傳可寫穿內部的 Dictionary 別名。
- `battle_screen.gd` 是組合根與輸入協調，連接 Controller／HUD／Director，選角只改 UI state。預覽保留 expected_event_seq，確認仍重驗。
- `battle_presentation_adapter.gd` 投影 HP/AP/MP、牌區、Boss tactical、Barrier及Casting。HUD只讀，不能計算傷害。
- `battle_animation_director.gd` 將接受事件排隊；讀 DamageTrace 的 recipient、hit、hp_damage 畫數字，播放既有 run／strike／hit。離手 artwork ghost 沒有 CardInstance，也不改牌區。畫面掉幀、Tween取消不會回呼 reducer。
- SimpleCards 的 ArcShape 與 tween_position／rotation／scale 沿用，不另造扇形公式。手牌重排依相同 instance 的前後視覺位置，所有旋轉角的 bounds 按安全區縮放。addon釋放handler會還原未歸屬容器卡片的rotation，因此 presentation deferred還原fan pose，未修改上游腳本。

## 3. 架構及方案取捨

Input→BattleScreen→BattleController→M5.apply→existing state/events→Adapter→HUD/Director。Controller自動提交排程指令，只推進既有 Intent；DRAFTING 停下來等使用者 Confirm／Pass，沒有 timer auto-pass。演出排隊與 Domain 交易解耦，非動畫完成才扣血；因此HUD可能已顯示最新結算值而演出尚在進行，P4.4可改善節奏，不改結果。

另一方案是 UI 直接持有可變 BattleState 或由 AnimationPlayer call method 扣血，會讓 duplicate input、場景離開和 replay 失去一致性，不採用。CGF整套原始碼含Godot3 API與AGPL授權，本輪只研究互動，未導入其規則／ScriptingEngine；詳細比較見 P4_RESOURCE_SELECTION。

## 4. Android / Kotlin 對照

Controller像擁有狀態的ViewModel/use-case owner；M5.apply像純reducer，Command像Action；signal像callback／Flow通知；Adapter像UiState mapper；Director像消費一次性effect的動畫層。Node的生命週期近似UI component owner，但不是Android Activity。Coroutine await timer在Node離場後須檢查is_inside_tree，不能假定await自動取消所有後續邏輯。UI不應直接改StateFlow內的可變物件，同樣不應改寫Domain Dictionary。

## 5. Tape / Replay

`user://p4_battle.tape` 是 p4-tape-v1，包含 initial state、ContentConfig、typed commands、final hash。FileAccess Variant編碼保留整數，get_var(false)不允許反序列化任意Object；暫存後rename，失敗回報。verify_saved_tape呼叫原 M5.replay。這不是通用外部存檔匯入UI，也未宣稱跨引擎版本相容。

## 6. 實際測試／三次差異

本機Godot4.7.2、Windows／GTX1650 Compatibility。

| 執行 | 結果 | 內容與差異 |
|---|---|---|
| p43_attempt1.log | 27/27 PASS | 真HP/AP/MP/棄牌、duplicate/stale/invalid atomic、snapshot隔離、seq、save/load replay、動畫不變狀態、手動Reaction、reentry／cleanup |
| p43_attempt2.log | 27/27 PASS | 加入fan pose／狀態呈現、原子tape寫入後重新驗證 |
| p43_attempt3.log | **30/31，1 FAIL** | 新增資源不足三條PASS；新增具體付款→卡區→傷害→完成順序測試 FAIL |

失敗根因：新增測試錯用 resource ledger 的 `APSpent`，實際 SP 路徑是 Cost.apply 的 `SPCostReservedOnly`（cost_resolver.gd末段），再由 M2包裝及M5轉發。不可讓Domain發出額外假事件配合測試。已改成真正事件名，並強化所有index必須存在且依序，但**修正後 NOT EXECUTED**。依 QA Skill 同組最多三次規範，不改名換runner重置次數；本輪不再執行第四次。這項測試錯誤不是已證明的戰鬥扣費缺陷，也不能省略其Gate。

其他實測：Scene8/8、HUD36/36；完整31 suite 1238/1238、100/100固定seed、4Legacy PASS，logs `outputs/p4_logs/p43_regression/`。Domain程式未改，Golden final仍 `c510227726170562d623b3737226439f3dffa0e4cea1ee9dfc4150117671acdd`。

真視窗輸入測試 `tests/test_p4_input_capture.gd`：首次12/12、加入兩解析度八張旋轉四角後16/16 PASS；使用Godot viewport真mouse press／drag／release、實際addon holding、鍵盤選角／Enter確認／Space結束、實際Pass Button。不是直接emit signal替代輸入，也不是人工playtest。證據 `outputs/p4_3_idle_1280.png`、drag、hit、reaction、round2_1920、en_1920、eight_1280、eight_1920；已實看命中／Reaction／雙語／八張邊界。Boss290→259、AP6→5、A MP10→9，數字16+15來自DamageTrace。字重用唯一OpenType tag修正，避免名字映射未生效；依官方FontVariation API。

## 7. 面試追問與延伸

為什麼 preview成功仍可能commit拒絕？快照過期或duplicate，expected_event_seq必須守門。如何防動畫二次扣血？Director只有事件資料、沒有 reducer引用。如何確保UI與replay一致？對照snapshot hash、Domain費用／牌區、接受的CommandTape及重播hash，不能只看截圖。為何不用JSON直接保存typed commands？JSON number可變float而失去既有int schema，本輪Variant encoding且禁Object；未來對外格式應明確DTO及數值驗證。

延伸：[Signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)、[FontVariation](https://docs.godotengine.org/en/stable/classes/class_fontvariation.html)、[FileAccess](https://docs.godotengine.org/en/stable/classes/class_fileaccess.html)。

## 8. 已知限制與下一步

P4.3 Gate待下一輪重新驗證修正後的同名runner與CI；未推送master。P4.4全類型施法／反應／LastSpell動畫、音效、完整視覺質感、P4.5真人完整Boss、P4.6性能／平衡均未執行。Analyze／道具沒有本輪可用Domainaction，明示未實作。角色圖身份及Boss舊圖紫色鄰片仍placeholder／來源待清權，非商售美術。無export preset，未驗證export內CSV／font packaging。輸入驗證為mouse／keyboard，不含gamepad、touch或真人可用性。
