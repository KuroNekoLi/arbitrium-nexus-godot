# P4 Localization — Engineering Note

**Status: IMPLEMENTED_NOT_VERIFIED / NOT_EXECUTED** (2026-10-15). 來源：`docs/handoff/P4_CARD_LOCALIZATION_HANDOFF.md`、`docs/ui/02_ARCHITECTURE_DATA_INTERACTION.md`、Lv40 卡牌定義；以 `docs/combat/COMBAT_SPEC_INDEX.md` 決定規格權威。本包沒有改 Domain、其他 Battle UI、CI、RTM、主設定、圖片或原 `battle_strings.csv`。

## Godot / architecture

`battle_translations.gd` 保留 `install() -> void`，新增 `validate_catalogues(paths)`、`install_checked(paths)`、`uninstall_owned()` 與 `owned_count()`。用 `FileAccess.get_csv_line()` 處理逗號／引號／Unicode，先將兩份CSV驗證成 locale→key→value，再以每個 locale **一個** `Translation` 註冊到 `TranslationServer`。安裝不更動目前 locale。失敗時不留下本模組半套翻譯；僅移除自身註冊的翻譯，不呼叫 `TranslationServer.clear()`。

欄位必須為 `keys,en,zh_TW`；缺檔、錯欄、空值、空key、非白名單重複Key皆拒絕且回傳機器可辨的 `error`。原 `battle_strings.csv` 已存在 `BATTLE_SAVED`、`BATTLE_SAVE_FAILED` 的歷史重複列；此包無權修改該檔，僅允許此兩key在原檔**後列覆蓋前列**、透過 `warnings: LEGACY_LAST_WINS:...` 揭示。其他（含跨檔）重複皆 fail-closed。將來應由原檔 owner 另案去除歷史重複，屆時可移除特例。

Lv40 CSV 補 4 個角色／Boss名稱、11 個Boss意圖與3個Last Spell顯示Key（最後3個僅候選，不宣稱已接 caller），沿用原有26份 CardAppearance 的完整ID與 name/description key；修正兩個原描述過度承諾的 A02（目前多目標未接線）、R06（目前無登錄Combo配方）。不更動暫定平衡值或素材；新增Boss意圖與Last Spell譯名是 **UI候選文案，需正式內容文字核對／用戶核准**，不是新Gameplay Canon。

## Source → code → test（待執行）

- `scripts/battle/presentation/battle_translations.gd`: atomic/冪等雙CSV載入、錯誤契約、owned cleanup。
- `resources/ui/lv40_strings.csv`: 26 card name/desc、角色與Boss意圖 metadata keys。
- `tests/test_p4_localization.gd`: SceneTree named assertions，包括解析、兩語lookup、26 appearance一致、legacy相容、quoted CSV、失敗不註冊、冪等、locale不變及cleanup。

建議 Godot 4.7.2 檢查：`godot --headless --path . --editor --import --quit`；`godot --headless --path . --script res://tests/test_p4_localization.gd`。需要保留attempt、exit code、full log及版本；本對話**沒有執行Godot**，所以沒有PASS數字、截圖、runtime CI或GUI overflow結論。P4.4既有GUI 14/16 / attempt3不在本包重跑。

## Android / Kotlin comparison

`TranslationServer` 對應 Android `Resources.getString(id)` / 多語 `strings.xml`；`install_checked` 的先驗證後一次提交類似 Repository 在 Room transaction 前驗證資料完整性，防止部分locale載入。UI只有key、Domain擁有實際數值；即使UI文案翻譯失敗也不能偷偷改Cost、MP。

面試追問：為何不能 `split(",")`？（quoted欄位）。為何不每檔直接 `add_translation`？（同locale註冊順序不保證、部分失敗污染全域）。為何 cleanup 不用 clear？（只應移除自己的資源）。替代方案是Godot匯入 .translation資源或編譯JSON；本輪保留現有CSV/public API以避免侵入式遷移。

## Known gaps

實際Godot parse/runtime與locale輸出、UI長文overflow、Last Spell caller、Boss Intent正式文案驗收尚待整合。不可宣稱P4.5 VERIFIED。
