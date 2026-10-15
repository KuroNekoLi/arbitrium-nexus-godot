# P4.2 Battle HUD & Card Interaction — 工程筆記與 Gate

## 目標及來源

以 docs/ui/01、02、05、Combat Phase4 Handoff P4.2 接上真實個人手牌，雙語、合法性預覽、選角、拖曳／鍵盤及明確 Reaction 確認。延續 P4.1 `66a8b3faf776ca2d4f8371718e89ea3c89aef4fe`，其正式 CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38681239677 已成功。

## 責任與 Godot 概念

BattleHUD 組合 Control／Container，HeroRosterItem 重用既有角色框與 Kenney frame。BattleCardView 繼承既有 SimpleCardsCardBase，不改上游，沿用點擊／拖曳／焦點，卡面使用 CardAppearance Resource 及 AtlasTexture，不把文字畫入圖。BattleScreen 只提交意圖，BattleCommandFactory 用 M5.apply 的 detached dry-run 顯示合法性，不自行算費用／傷害。角色切換不產生 Domain Command。

TranslationServer 在 _enter_tree 安裝 catalog：父 _ready 晚於子 _ready，因此若在 _ready 才安裝，子 Labels 會拿到 key。CSV 只存雙語，CardAppearance 不含遊戲數值。容器中的單行頂列關閉 wrap，避免 minimum size 被長字串撐高。

## Android / Kotlin 對照及取捨

signal 類似 callback／Flow；snapshot→VM→render 類似 StateFlow 收集 UI state；Resource 像唯讀 presentation model；command dry-run 類似同一 use-case validator，避免 ViewModel 重寫 business rule。選角是 UI state 而非 domain action。採繼承 addon 而非修改 addon，便於更新；整體引入 CGF 需 Godot4 port／授權評估，見 P4_RESOURCE_SELECTION。動態組合元件比巨型 tscn 易做兩語重建，但 Inspector 編輯便利性較低，後續可抽 PackedScene，不能用這點當作第二套規則理由。

## 驗證與失敗修復

首次 HUD 34/34 PASS，但實際畫面發現頂列高度與首次翻譯錯誤；修正生命週期與 wrap，新增兩條回歸，第二次36/36 PASS。真渲染截圖在 outputs/p4_2_1280_zh.png、1920_zh.png、1280_en.png、eight_cards.png；1280繁中已實看，Boss全身未裁、三人 compact diagonal、四張安全邊界，八張可重疊且選取看詳細。測試0／4／8、實例唯一／歸屬、EXHAUSTED／INCAPACITATED、兩語、雙解析度、Reaction 等待不 auto-pass。

完整31 suite 回歸 exit0：1238/1238、100/100固定seed、4 Legacy PASS。原始 logs outputs/p4_logs/p42_regression/。P4.2 尚未接上實際提交；那是 P4.3 Gate，不能把預覽 PASS 當傷害整合 PASS。遠端 CI 推送後另核對。

## 面試追問與測試方法

為何不要 clone 假手牌？CardInstance 歸屬和 zones 必須來自 reducer。preview 與 commit 有何競態？保留 expected_event_seq，提交時仍需再次驗證；不能相信先前預覽。為何圖片 PASS 不夠？須驗證命中區域／鍵盤／resize，以及 mutation safety。命令 `Godot --headless --path . --script tests/test_p4_hud.gd`；`Godot --path . --script tests/capture_p4.gd`。

延伸：https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html 、https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html 。已知：fixture-only；Analyze／道具未有核准 Domain action，明示不可用；舊Boss圖含鄰近紫色碎片，角色身份圖待正式定稿。未做真人 playtest，不宣稱零障礙或商售美術完成。
