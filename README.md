# Arbitrium Nexus — Godot 卡牌 JRPG

> **現行戰鬥引擎只有一套：M1～M5 Domain + Lv40 Battle。** 先讀 [繁體中文戰鬥規則](docs/combat/README.md)，不要使用已退役的八張牌原型或歷史測試。

## 執行入口與資料流

- Godot `project.godot` 預設場景：`res://scenes/battle/lv40_playable_battle.tscn`。
- 戰鬥 UI：`scenes/battle/battle_screen.tscn`、`scripts/battle/battle_screen.gd`、`scripts/battle/ui/`。
- 命令提交／重播：`scripts/battle/battle_controller.gd` → `scripts/domain/m5/integration/m5_domain_resolver.gd` → M1～M5。
- Lv40 初始隊伍及 Boss 內容：`resources/combat/rosters/lv40_party_v0_3.json`；解析：`scripts/domain/m5/lv40/lv40_party_catalog.gd`；試玩／初始牌組：`lv40_encounter.gd`；候選卡牌、敵方效果及平衡參數：`lv40_content.gd` 和同目錄 resolver。
- 角色 **A/B/C 是場內位置 ID**，不是固定人物。當前三人（朝霧蓮、九條朱音、白石紬）只是候選內容。角色美術、雙語名稱、牌組、技能和終式需一併配置，不能僅改顯示姓名就宣稱完成角色替換。

## 不可退回的戰鬥規則

每人 **12 張 SP**、開局手牌 4、玩家階段不足 4 補至 4、上限 8、每人每階段一次免費換牌；全隊共用 **Base AP 6**，MP 不自然逐回合補滿，未用 AP 依規則轉換 RP。沒有舊原型「每人 8 張／每階段最多出兩張／限時 Reaction 自動 Pass」。終式不進普通牌組，每人每戰一次完整詠唱；成功後耗竭，釋放前 HP 歸零則失效。詳細規則及例外以中文主題文件為準。

## 工程文件

- [戰鬥主題規則與角色／卡牌／Boss 圖鑑](docs/combat/README.md)
- [Agent 實作契約](docs/combat/engineering/戰鬥引擎實作契約.md)
- [規則與程式對照](docs/combat/engineering/規則與程式對照表.md)
- [已知差距／待驗證清單](docs/combat/engineering/待實作與待驗證功能.md)
- [舊系統退役紀錄](docs/combat/engineering/舊系統退役與驗收紀錄.md)
- [Battle UI／素材開發規範](docs/ui/README.md)

## 執行與驗證

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_lv40_roster.gd
godot --headless --path . --script res://tests/test_lv40_content.gd
godot --headless --path . --script res://tests/test_p4_lv40_playable.gd
python3 -m unittest discover -s tests/ci -p 'test_*.py' -v
```

GitHub Actions：`CI Fast`、`CI Integration`、`CI P4 UI Contracts`、`CI Visual`；每日／手動 `CI Full` 執行目前 Domain 的 100 場固定種子對局。CI 成功需以**實際 commit 與該次 run** 為準，不可拿舊版紀錄充當新提交驗收。

**退役範圍**：八張牌原型的 main 場景、舊 Domain／DeckBuilder 已從程式移除；舊測試相容殼與呼叫它們的 workflow 步驟也已從清理分支刪除。M1～M5 目錄是新引擎，不能因編號較早而刪掉。仍被新 HUD 使用的 `scenes/ui/hero_roster_item.tscn` 是**現役可重用元件**。

美術和第三方授權見 [CREDITS](CREDITS.md)；保留歷史核准與驗證紀錄在 `docs/combat/archive/` 與 `docs/verification/`，它們不是現行規則。
