# P4.4–6 並行工作契約

來源master 5103e40a4b95da82f2561b29c2604e9514fd398b；使用者明確授權完成P4，並另確認「授權擴充既有M5」。所有數值Provisional，Canon／重大美術不能自行定案。

| Owner | Write scope | Read dependencies | Output / tests |
|---|---|---|---|
| Main / presentation integrator | scripts/battle、scenes/battle、resources/ui、project.godot、CI、RTM、總交接、P4.4 tests/capture | Domain唯讀至子Agent交接 | P4.4呈現、雙語、真實截圖、整合CI；唯一commit/push者 |
| Lv40 Domain engineer | scripts/domain、resources/combat/lv40、tests/test_lv40_*、docs/verification/PH4_LV40_DOMAIN_NOTE.md | docs/combat25/26/27/29、現有M1–M5 | 同M5入口，lv40_encounter.gd static config()/initial(seed)，PLAY_LV40_CARD真卡交易；Boss/反應/被動，atomic/replay tests |
| QA sidecar | tests/test_p4_feedback_edges.gd、docs/verification/ui/P4_FEEDBACK_EDGE_AUDIT.md | scripts/battle唯讀 | skip/dedupe/reentry/invalid cue/frame與locale邊界，發現缺陷附重現，不改presentation |

共享project.godot／translations／CI／RTM只有Main寫入。Lv40 Agent不得修改scripts/battle或CI，不得commit/push。QA不得修改Domain。跨scope需求先交接。

Domain state唯一權威；所有effects使用既有M2支付、M3window、M4casting、M5Damage／Status流水線，新Lv40模組只能擴充同引擎，不增加第二State／UI扣HP。接受事件保持command_id/event_seq；rejection整筆原子。測試專用fixture不能冒充正式Lv40parity；未做到逐項列出。

交接API：res://scripts/domain/m5/lv40/lv40_encounter.gd，config()為版本化Dictionary，initial(seed)為M5 envelope，角色穩定A/B/C對應ren/akane/tsumugi，Boss穩定Boss；definitions使用U/R/A/T標準ID，presentation另查display key。M5.apply仍唯一入口；PLAY_LV40_CARD含actor_id/card_instance_id/target_actor_id/casting_mode/command_id/expected_event_seq，費用效果不得由UI輸入。

Main在P4.4驗證期間，Lv40 Agent可做獨立領域施工；不代表P4.5已放行。Main review子Agentdiff、逐項正式驗收後才獨立commit/push。原使用者未提交檔與Godot產物保留。P4.6真人playtest必須使用者操作，不可由Agent冒稱。
