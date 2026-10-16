# Arbitrium Nexus｜Godot 三人卡牌 RPG

目前唯一的預設遊戲入口：`project.godot` → `res://scenes/battle/lv40_playable_battle.tscn`。

## 已確認的玩法
每名戰鬥角色**各自持有12張技能卡**，開局各抽4張，每個玩家階段不足4才補至4，手牌上限8。全隊共享基準6AP，MP各人獨立且不會每回合自然回滿；沒有「每人最多出兩張」的舊版限制。敵方反應窗口不計時自動Pass；終式獨立、成功後耗竭。

## 角色與牌組：資料驅動
`resources/combat/rosters/lv40_party_v0_3.json` 定義目前示範戰的3個戰鬥槽位、角色身分、形態、name_key、立繪資源、能力及每人12張起始牌。新增或替換角色應修改內容檔與對應翻譯／美術／技能內容，不應在 BattleScreen、CardCatalog 或牌組儲存器寫死人物名字。

原8張卡原型已從正式遊戲入口撤下；本專案的 M1～M5 Domain 與 Lv40 正向場景為唯一開發路線。**內容數值仍為候選**，尚需依真實 Godot 對局與CI確認；不能由 README 或舊原型覆寫正式戰鬥規格。

## 文件與實作
- [現行戰鬥規則（唯一入口）](docs/combat/README.md)
- [角色圖鑑](docs/combat/角色圖鑑.md)
- [卡牌圖鑑與起始牌組](docs/combat/卡牌圖鑑.md)
- [工程實作契約](docs/combat/engineering/戰鬥引擎實作契約.md)
- [規則與程式對照](docs/combat/engineering/規則與程式對照表.md)
- [UI規格](docs/ui/README.md)

## 目前有效的驗證
```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_lv40_roster.gd
godot --headless --path . --script res://tests/test_lv40_content.gd
godot --headless --path . --script res://tests/test_p4_lv40_playable.gd
```
完整自動化以 `.github/workflows/ci-fast.yml`、`ci-integration.yml` 與 M5 regression workflow 的最新證據為準。**提交程式碼不等於這些測試已通過**。翻譯以 `resources/ui/lv40_strings.csv` 和戰鬥既有翻譯資源為準。

原型視覺素材與第三方資源保留其授權記錄，詳見 [CREDITS](CREDITS.md)。切換新的角色資產前須確認影像與授權，不要因清除舊程式直接刪除仍被場景引用的素材。
