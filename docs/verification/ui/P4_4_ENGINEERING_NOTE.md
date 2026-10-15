# P4.4 Combat Animation & Feedback — 工程／驗收紀錄

來源 `5103e40a4b95da82f2561b29c2604e9514fd398b`。P4.3正式CI [38685051780](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38685051780) completed/success，31垂直切片／8Scene／36HUD與全Domain步驟成功。使用者本輪授權繼續P4.4～6，並明確批准同M5內擴充Lv40；不變更已核准玩法，數值維持Provisional。

## 目標／需求來源

Handoff P4.4、UI04 §4/5/8/9、UI05 UI-C/R/L/B/I：普通攻擊／魔法／詠唱、干擾、Guard/Protect、破綻／失衡／Combo、LastSpell、勝敗與跳過動畫。禁止動畫回呼扣血、Reaction倒數或假釋放。

## 主要程式與 Godot 概念

- `battle_cue_mapper.gd` 是純Dictionary projector，只映射已有事件，cue有command+seq去重ID，unknown不亂播。
- `battle_animation_director.gd` 維護視覺佇列、seen、generation；snapshot已由Domain接受，caption/VFX/傷害數字只是呈現。普通物理攻擊前衝、魔法用不同burst；Guard／Protect等收到真事件才顯示。數字hit/recipient/hp_damage來自DamageTrace，不從卡面算。
- `battle_actor.gd` 用既有SpriteFrames及Tween，顯示持續Casting與HP Barrier的不同圖形；Exhausted與Incapacitated不同tint／HUD文案，不混成死亡。
- `battle_effects.gd` 重用已審Kenney magic/slash紋理及click2/knifeSlice音效，四個AudioStreamPlayer輪用，-20dB，靜音／減少動態可切。沒有新增外部plugin／渲染器。
- `battle_hud.gd` 顯示手動Reaction/特殊持卡Reaction，Result overlay與新戰鬥入口；詳情區ScrollContainer防長文撐出畫面；draft的HBox label設定expand，避免擠成逐字直排。
- `battle_input_bindings.gd` 只安裝缺少的選角InputMap action，不覆蓋使用者重綁；其餘沿用ui_*與end_turn。確認合法target後focus到ConfirmButton。Reaction modal鍵由GUI處理，不變成隱含Pass。

## 為何採用此架構／替代方案

接受Domain交易→即更新HUD→非權威cue排隊，讓FPS、Skip或離場無法改傷害。單一大AnimationPlayer可以編排鏡頭，但若method track扣費就破壞Replay；本輪短Tween適合重用既有atlas，未新增骨架或自製框架。ArcShape／還原／重排Tween沿用SimpleCards，CGF只研究交互設計，未混入AGPL原始碼。

### Signal重入為何要generation？

Godot signal可以同步呼叫訂閱者。訂閱者若在cue_presented中按Skip，函式仍會回到舊_play_next繼續執行。僅在await後檢查不夠；必須在emit返回後立刻比對generation，timer返回後再比對。Skip清佇列、復位actor、清effects，不動BattleController／M5。新戰鬥才清seen，否則同事件會重播兩次。

## Android / Kotlin 對照

cue projector類似把Domain Event映射到UI effect；signal像可能同步觸發的callback，不能一律當異步Flow。generation像Coroutine Job cancellation token，但Node的timer await不自動保證語意取消。角色／VFX ownership類似View lifecycle owner；InputMap類似可重綁的KeyEvent→Action router，業務Command不含平台按鍵。

## 真正測試與證據

Godot4.7.2.stable.official.ed1daf0bf；Windows／GTX1650／Compatibility。

- `test_p4_feedback.gd` 首輪45/45：mapper單元案例明示synthetic；其他使用真M5 Full Chant、Guard A+Protect B、實際recipient B、due release、dedupe、skip後hash、完整Golden事件與LastSpell HP0失效。Golden仍49commands，final `c510227726170562d623b3737226439f3dffa0e4cea1ee9dfc4150117671acdd`。
- QA獨立 `test_p4_feedback_edges.gd`：三輪從locale／signal重入缺陷到80/80 PASS，原assertions保留，詳見P4_FEEDBACK_EDGE_AUDIT與p44_edges_attempt1/2/3.log。包含10FPS／縮短演出／reentry／invalid command無成功cue／Guard和Protect真實傷害收據。
- Scene8/8、HUD36/36、vertical31/31 PASS。完整31suite回歸1238/1238、100/100 seeds、4Legacy PASS，p44_regression原始log。
- 真視窗 `capture_p4_feedback.gd` 兩輪exit0，p4_4_full_chant_1280、protect_draft/hit、last_confirmation/chant、victory_1280、victory_en_1920；已實看雙模式、援護佇列、長LastSpell確認及勝利。第一次draft逐字直排缺陷已修，第二次畫面可讀。

### GUI input failures 必須保留

同名 `test_p4_input_capture.gd`：attempt1確認鍵FAIL（舊synthetic只給physical鍵，InputMap ui_accept需logical事件）；加入如真OS的logical+physical事件並把焦點交給ConfirmButton，沒有減少功能assertion。attempt2確認鍵PASS，但focused Button吃掉Space使END失敗，接續test空reaction child引發SCRIPT ERROR並掛住；只終止已核對CommandLine的本次測試程序，完整log保留。修成非modal時end_turn優先、modal仍不隱含Pass，test加fail-fast避免後續null錯誤。

attempt3所有互動及兩尺寸8張旋轉四角PASS，但兩PNG save_png寫入失敗，整組14/16、exit1；不能稱整組PASS。已加入outputs/.gdignore排除證據資料夾的Godot匯入、可選capture-prefix避免覆寫前階段圖片；實際根因尚未證明，檔案非唯讀，當時無殘留Godot程序。已向使用者請求一次額外驗證；未獲明確批准前不第四次執行。這是本輪目前未通過Gate，不隱藏FAIL或重命名測試重設配額。

## 素材選型與可回退

Asset Manager／Pipeline已盤點既有Repo／Vault、讀包內CC0 license、hash後重用4檔，manifest逐條記錄，零下載。Kenney適合短VFX／SFX，與新整套框架相比整合低且可撤回；不把新效果定為最終角色／Boss造型。原PNG角色／Boss仍placeholder待清權。音效有runtime載入／播放呼叫證據，沒有冒稱人工完成聽感混音審核。

## 面試追問／延伸

如何證明Skip不改勝敗？同seed/tape下比較Domain final/eventhash，加上pending await／重入測試。為何dedupe不能只用FPS？事件ID是權威順序，Frame可能掉或重播。Guard與Protect怎麼區別？前者coverage、後者recipient redirect，都讀事件，不依畫面站位判斷。為何Context用Scroll？長翻譯不能反過來撐大固定安全區。

官方延伸：[Signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)、[Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html)、[ScrollContainer](https://docs.godotengine.org/en/stable/classes/class_scrollcontainer.html)。

## 限制／下一步

P4.4只呈現既有事件，未把Interrupt的mapper單元測試冒充Lv40 Boss Casting已完成。後者正由P4.5同M5擴充。此報告尚未宣告P4.4遠端VERIFIED；需GUI剩餘Gate、獨立commit／push／CI。真人遊玩、完整Lv40 parity、正式平衡核准、手把／touch／export與商售美術仍不能由上述headless推論。
