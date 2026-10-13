# 仲裁核心

Godot 4.x 單人 2D 橫向回合制卡牌 JRPG 原型，採 1280×720（16:9）畫面。

## 執行

以 Godot 4.x 開啟本資料夾並執行主場景。

## 操作

- 點擊角色面板，切換至該角色獨立的牌組與手牌。
- 我方階段將普通卡牌拖曳至戰場出牌；全隊每階段最多普通出牌兩次。
- 點擊「結束回合」揭露首領意圖。
- 敵方階段若持有「中斷反制」且能量足夠，可拖曳至戰場取消意圖；否則點擊「承受敵方行動」。
- 點擊「牌組編輯」可從 12 種卡牌 Resource 為每位角色挑選 8 張牌，儲存／載入牌組、匯出 JSON，或套用設定並重新開始戰鬥。
- 卡牌拖曳、追蹤與放開判定使用開源 Simple Cards `Card` 元件；卡面與戰鬥規則由本專案實作。
- 卡牌懸停會抬起，無效放置會彈回；有效出牌時卡牌飛入戰場、角色移動並播放專屬動作，命中後才結算傷害。

## 驗證

```text
godot --headless --path . --script res://tests/test_battle_state.gd
godot --headless --path . --script res://tests/test_combat_ui.gd
godot --headless --path . --script res://tests/test_deck_builder.gd
```

重新擷取執行畫面（需圖形環境）：

```text
godot --path . --script res://tests/capture_combat_screenshots.gd
godot --path . --script res://tests/capture_deck_builder.gd
```

畫面證據：[主戰鬥介面](outputs/combat_ui_mvp.png)、[牌組編輯器](outputs/deck_builder.png)、[角色突進／卡牌飛行](outputs/card_attack_midflight.png)、[命中結果](outputs/card_attack_impact.png)。

戰鬥規格 source of truth：[docs/COMBAT_RULES_V1.md](docs/COMBAT_RULES_V1.md)。

## 範圍

M0–M5 MVP 已完成：包含可執行專案、純戰鬥引擎與固定種子測試、獨立牌組與抽牌、能量保留、每階段出牌上限、反應中斷、首領生命／穩定度／弱點節點、分析與敵方意圖、可玩的 16:9 戰鬥介面，以及可編輯、儲存、載入與匯出 JSON 的牌組編輯器。克蕾雅、諾瓦、尤拉各有待機／奔跑／出招逐格圖集；不同卡牌類型有各自配色、圖樣與施放特效。這是功能完整的 MVP 原型，尚未達商業發行產品的最終內容與打磨標準。
