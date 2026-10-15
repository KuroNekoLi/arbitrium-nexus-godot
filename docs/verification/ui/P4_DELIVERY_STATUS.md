# Phase 4 本輪交接

## G0

已pull指定repo master，起點 `7163aeff0de1f93b2c1a05e20bf7a3c3899333b7`。AGENTS、現行Combat／UI、Skills及Guardian已核對。詳見 P4_G0_AUDIT.md。沒有使用歷史Flutter／Astraea-Academy。

## P4.1 — VERIFIED

Commit `66a8b3faf776ca2d4f8371718e89ea3c89aef4fe`。

正式CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38681239677 completed/success。

三角／Boss slots、腳底anchor、動畫atlas、設計畫布與Adapter；Scene8/8，1238 Domain／100 seeds／4Legacy PASS。實際1280／1920截圖與Sprite3D小比較在outputs/p4_1_*。檔案與教學見 P4_1_ENGINEERING_NOTE.md。

## P4.2 — VERIFIED

Commit `961c05061665be1c518d041ce05508c225fdb8ae`。

正式CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38682762145 completed/success；Legacy failure-probe CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38682762150 completed/success。

獨立真手牌、選角、hover／拖曳、合法性dry-run、AP/MP/HP／Boss Intent、兩語、明確Reaction UI。HUD36/36，Scene8/8，1238／100 seeds／4Legacy PASS。輸出outputs/p4_2_*；重要檔案 scripts/battle/ui、resources/ui、battle_command_factory.gd、battle_translations.gd、hero_roster_item.gd。教學見 P4_2_ENGINEERING_NOTE.md。

## P4.3 — NOT VERIFIED / QA_EXECUTION_LIMIT

未commit、未push、沒有本輪P4.3遠端CI。不要用P4.2 SHA／CI替其背書。

工作樹已接 BattleController→M5→Adapter→HUD/Director，主場景切換到 scenes/battle/battle_screen.tscn；真交易與事件演出、手動Reaction後Boss自動續行、typed CommandTape、save/replay、沿用SimpleCards扇形／Tween。沒有修改scripts/domain。

本機：Scene8/8、HUD36/36、GUI輸入16/16、完整Domain1238／100 seeds／4Legacy PASS。P4.3 runner三次27/27、27/27、30/31；第三次新增順序oracle用錯事件名，已修正但未第四次重跑。詳見 P4_3_ENGINEERING_NOTE.md，完整保留失敗log。

截圖：outputs/p4_3_hit_1280.png 是Boss259/290、AP5、A MP9且角色前衝；reaction顯示DRAFTING等待；eight兩尺寸顯示真正旋轉邊界。截圖與GUI PASS不抵銷未過的順序Gate。操作者是Godot測試輸入，不是人工playtest。

## Skills / Assets

主控與Spec Guardian；Architecture負責owner／signals／tape，Combat檢查M5 API／scheduler，UIUX負責真手牌／i18n／互動，Rendering負責compact diagonal／事件演出，Resource Manager＋Pipeline盤點重用／字型／授權，QA負責runner／CI／原始證據及三次上限。所有實際工作為單Agent依序執行，沒有假稱另啟subagents。

Kenney frame CC0、既有SimpleCards2.13 MIT，完整notice已補回；NotoSansTC OFL1.1，Vault／manifest記錄。角色／Boss／背景既有PNG是來源待清權placeholder。CGF查核main SHA、API／授權／互動，未匯入其原始碼，未替換M5。研究見 P4_RESOURCE_SELECTION.md；各素材專案路徑在assets/asset_manifest.csv。

## Git／限制

遠端master停在P4.2 SHA；P4.3保留在工作樹供續作，不能標成clean。原有 .codex/COMBAT_SPEC_MEMORY.md 保留未提交；另有本機Godot產生.uid／CSV .translation及未提交本輪證據，不把它們混入無關commit。不reset、不force push。

下一輪先跑修正後 test_p4_integration.gd，核對Scene／HUD／GUI及完整回歸，再review diff、獨立commit／push P4.3、核對其GitHub Actions。通過後停在P4.3，不擴大至P4.4～6。沒有商售美術、完整Boss遊玩、balance或export完成主張。
