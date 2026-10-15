# 專案唯讀稽核

研究日期：2026-10-15（Asia/Taipei）。Repo：[KuroNekoLi/arbitrium-nexus-godot](https://github.com/KuroNekoLi/arbitrium-nexus-godot)，branch `master`，commit `8a808cb0ef685fa48633740c6ae4a3f60f370c83`。此快照以唯讀clone研究，未修改遊戲、未push或建立PR。

`project.godot`：features 4.7、1280×720、canvas_items、gl_compatibility；main為scenes/main.tscn（Control），CG指向simple_cards addon。CI與工程Note記載Godot4.7.2.stable；本次未執行該Godot binary，不能宣稱本機或遊戲runtime已驗證。

本snapshot找不到 `AGENTS.md` 與指定單檔 `docs/combat/COMBAT_RULES_BASELINE_V0_8.md`。實際入口是 `00_README_COMBAT_RULES_BASELINE_V0_8.md`；整套00～24包含後續核准與實作契約。22中「docs-only repo」敘述指另一規格repo，不能誤套到已存在project.godot的本repo。

來源效力：21與20§7的CORE-01～04覆蓋舊DRAW／Last Spell死後續唱／走位／Reaction倒數提案；18/19更新早期手牌、魔法與AP/RP規則。依明示核准及supersession，不按檔名數字直接覆寫。使用者2026-10-15追加：衝突舊規則全部廢棄。

實作同時存在舊prototype與scripts/domain/m1～m4。combat_rng.gd為版本化Park-Miller，combat_model.gd有canonical hashing；不應重建RandomNumberGenerator或全新戰鬥框架。M4.2工程Note為 `IMPLEMENTED_AWAITING_ACTUAL_CI`，且明列M4.3/M4.4/M5與UI遷移未完成；只能報文件現況，不能升級為本輪PASS。

G0_CI_SETUP記載舊test_turn_flow仍驗證1.5秒Reaction timeout，與CORE-04衝突；依新指示其oracle廢棄，不作新版回歸標準。RTM列舊battle_state的兩次出牌、8卡deck、自然回滿等衝突；不得因legacy測試綠燈保留。需逐項以新版oracle遷移，未改動遊戲的本次Skill建立不代替該實作工作。

已讀樣本：project.godot、scenes/main.tscn、docs/combat/00、21、22、docs/verification/requirements_traceability.md、PH3_G0_CI_SETUP.md、PH3_M4_2_ENGINEERING_NOTE.md、scripts/domain/m1/combat_resolver.gd／combat_rng.gd／combat_model.gd、scripts/ui/card_view.gd、tests/test_m4_disruption.gd、.github/workflows/godot-m4-2-disruption.yml；並盤點docs、scripts、tests及workflows路徑。未宣稱全量程式審查。
