# CI evidence gate — 工程驗證
日期2026-10-15；基底master `5103e40a4b95da82f2561b29c2604e9514fd398b`，branch `engineering/ci-evidence-gate-20261015`。

## 目標／來源
使用者要求繼續未委派Agent的工作，並選擇維持P4.4 GUI三次上限、不額外重跑。依docs/combat/22 §5.2/5.4/5.5與QA Skill，補強CI失敗傳遞及依存觸發，不修改Domain／Agent施工範圍。

## 概念／程式責任
- tools/ci/assert_godot_logs.py：stdlib gate，疊加在process exit及exact oracle grep之後。偵測SCRIPT ERROR／ERROR／FAIL／Parse／Compile／assertion與矛盾／重複摘要；剝ANSI，支援UTF8/UTF16 BOM，缺檔／壞編碼fail closed，warnings仍明列。
- tests/ci/test_godot_log_gate.py：19個正／負／邊界／CLI自測；含錯誤+PASS仍非零。
- 原M5.5 workflow：擴充scripts/scenes/resources/assets/addons/tests觸發範圍，加import gate、exit17 probe與總log gate；原1238測試、固定seeds、legacy、exact greps、SHA512、timeout、always artifacts保留。
- tests/test_combat_ui.gd：只修historical prototype smoke的成功退出清理。stop、解除stream、queue_free、等待音訊清理再deferred quit。原assertions保留；舊動畫決定damage預期只是歷史smoke，不是新M5 oracle。

## 缺陷／三次紀錄
只讀稽核master的p43_resume_regression歷史log（未重跑Domain）找到legacy UI exit0/PASS但4 ObjectDB leaks／2 resources in use；新gate正確exit1，保存historical-log-audit.log，沒有重寫歷史證據。

本輪同名legacy UI runner三次，完整verbose log在outputs/p4_logs/ci_evidence：
1. 原碼重現exit0但ERROR；定位knifeSlice.ogg的OggPacketSequence／AudioStreamOggVorbis／playback refs。
2. stop／queue_free／frame／deferred quit仍洩漏，gate exit1。
3. 解除stream及0.15秒teardown等待後，原smoke PASS、process exit0，gate errors0/warnings0。等待只在測試退出，不決定傷害或Reaction。
三次配額用完，沒有本機第四次。後續雲端是另一平台回歸，不冒稱第四輪修復。

## 實際測試／環境
Godot實測4.7.2.stable.official.ed1daf0bf（本機WinGet binary），Windows/headless。Python為C:/Users/user05/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe。
- python -m unittest discover -s tests/ci -p 'test_*.py' -v：attempt1，19/19，exit0，attempt1.log。
- Godot --headless --path . --script res://tests/ci_failure_probe.gd：真實預期exit17／marker確認，failure-probe.log；不是遊戲PASS suite。
- Godot --headless --verbose --path . --script res://tests/test_combat_ui.gd：上述三輪。
- python tools/ci/assert_godot_logs.py outputs/p4_logs/ci_evidence/legacy-ui-attempt3.log：errors0/warnings0、exit0。
本機無PyYAML，未宣稱YAML parser通過，不額外安裝依賴。Bash syntax／遠端Actions另補。

24個workflow run script已逐一交給本機Git Bash `bash -n`，全部語法通過；這不等於完整YAML／Actions執行。額外hash查詢第一次因PowerShell多路徑未用陣列而失敗，已改成明確Path陣列；不影響前述24段檢查結果。

## 架構理由／替代／Android對照
quit(0)只表達回碼，退出清理可能另印ERROR。只grep PASS會漏錯；額外gate較重寫所有runner更小且保留原oracle。Warnings明列不一律fatal，真正ERROR仍fatal。
類似Android instrumentation成功仍需檢查logcat例外／resource leak；SceneTree lifecycle清理類似stop MediaPlayer後release。UI返回不是跨thread音訊釋放的fence。短teardown等待是本次測試取捨，不保證全部音訊後端語意相同。

## 面試追問／延伸
如何證明gate不是永遠綠？負例含錯誤+PASS、缺檔、壞encoding與真exit17，並抓到歷史漏錯。為何不改Domain？缺陷是CI／測試退出，不是玩法。為何stop不足？verbose顯示Ogg playback refs尚在，需釋放stream及清理時間，沒有靠吞掉ERROR過關。
[AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html)、[Node](https://docs.godotengine.org/en/stable/classes/class_node.html)、[unittest](https://docs.python.org/3/library/unittest.html)。

## 限制／交付
IMPLEMENTED_NOT_VERIFIED（遠端CI待查）。P4.4 GUI仍未驗收，未重跑。export_presets.cfg不存在，APPDATA/Godot/export_templates無已安裝版本；僅盤點，未匯出／下載templates。原dirty截圖／使用者memory不納入commit，不merge其他AI分支。Rollback僅本commit CI／test清理，不reset使用者檔。
