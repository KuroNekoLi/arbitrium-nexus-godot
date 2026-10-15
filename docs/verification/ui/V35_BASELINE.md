# V3.5.0 — Pinned References and Engineering Baseline

2026-10-15。V3.5整體狀態NEEDS_REVISION；不是已完成的高保真驗收。

## Source / ownership
遠端V3=f73e31cdf2ca5f235594ab4936191df36115958c；master=50e2eafc1112906e6a05bd8af813a3a937250d9b，已包含V2及V3.1–3.4審查修復。提示中的「V2仍Review」是歷史；不回退已修正的modal/成本/翻譯。
safe branch ui/v35-hud-convergence-20261015以50e2eaf起始（是f73e31c後代），無force merge/rebase，沒有修改master/V2分支。完成小階段後正常fast-forward推V3；並行變更時保留safe branch，不覆寫他人。
單一owner負責Theme、翻譯、HUD與測試；不改Domain/ContentConfig/command/replay。所有技能已按主控→UI/architecture→resource/pipeline→QA閱讀；只在實際有美術缺口才下載。

## Pinned originals
兩圖已實際view_image讀像素，Copy-Item保留原件；不是重新繪製。
位置docs/ui/references/v35/（.gdignore排除Godot import/export），來源是使用者本輪兩張照片附件。
| Reference | Actual format / size | SHA256 |
|---|---|---|
| reference_a_current.jpg | JPEG 1280×720 | 8505de0b9b37f0bb6c2fb7dcb1d6ab508858b8ec522d23c6543e500a32769c12 |
| reference_b_target.jpg | JPEG 1280×720 | 0d22c6bb6c245adeb3a18b3f3bd64a107cdb9017cf485141aa4bfd2d11e1ad33 |
B實際不是1536×864；等比原尺寸比較，不捏造原始PNG。不擷取其中角色/圖示作production素材，圖中資料非玩法權威。參考圖僅供本專案視覺審查，商業再散布權利未推定。

## Four-corner mapping / Top 5 mismatches
| Priority / node | Before vs target | Owner files / planned stage |
|---|---|---|
| 1 HUD/TopBar/ResourcePanel | 純AP文字，缺核心與水晶；target有大數字與發光核心 | team_phase_header、new party_resource_panel，V3.5.1 |
| 2 HUD/PartyStatusPanel | 一般list、細bar、選中身份弱；target角色卡與狀態徽記 | hero_roster_item、party_status_panel，V3.5.1 |
| 3 HUD/Commands | 通用button缺icon/副說明，Last/End權重不足 | command_menu及可換icon assets，V3.5.2 |
| 4 HUD/EnemyStatus | 純字Intent，大片空白；target技能縮圖/target badge | enemy_status_panel，純展示readmodel擴充，V3.5.3 |
| 5 HUD/Context + BattleLogPanel | idle大空框/無事件empty；target詳細技能與事件列表 | action_context_panel、battle_log_panel及Screen presentation，V3.5.4 |
頂部Phase後續與四角材質收斂V3.5.5。中央角色/背景/卡牌不在主範圍。六維及四角尚未評至3/4，不宣布20/24或READY_FOR_USER_REVIEW。

## Asset decision / actual inventory
Repo已有Kenney panel-border-000.png，包內LICENSE.txt明示CC0，可再用九宮格；保留NotoSansTC及SimpleCards2.13 MIT。外部Vault實際只有Noto字型來源，未假裝有別的框庫。
選用A：既有Kenney九宮格+原創獨立SVG核心/水晶/焦點角飾（沒有烘焙文字）；可逆且零下載，符合既有Style Bible。B：只用原StyleBox可維護但達不到材質；C：候選外部Fantasy整包本輪不下載/不採用，未作視覺評分。
這是既有Theme增量，不是更換UI framework/renderer/正式角色，無重大採用。字型與框授權沿用CREDITS；新SVG須記manifest與原創來源。素材重用是resource skill選擇、pipeline正式匯入，不停在Scout。

## Executed baseline
Godot4.7.2.stable.official.ed1daf0bf、Compatibility OpenGL3.3／GTX1650。隔離worktree .codex/worktrees/v35-hud/...。
唯讀scan ../v35-inventory.json；fresh import ../v35-baseline-import.log；9張真基準PNG outputs/p4_input_capture/v35_baseline_20261015/，../v35-baseline-render.log：V23 30/30（此為靜態渲染，不是GUI input）。
本輪尚未執行任何舊GUI，P4.4歷史14/16保持。V3.5新任務要求GUI驗證，但不自動抹除舊三次失敗紀錄；需明確scope帳本。

## Engineering note / continuation
Theme提供共用底板/字體；NinePatch縮放邊角不拉伸；SVG獨立裝飾；Control顯示projection、Signal發意圖，類似Compose UI讀StateFlow。不可從動畫或Label改State。
測試必須涵蓋AP>6、三角色切換、資源bar與快照一致、兩語、0/1/4/8、modal隔離及Hash。UI操作的幾何、字串、stderr和真PNG分開驗證。
每小階段記commit/CI/實測；quota低於30%時按使用者既定要求push並交接，不把未完成V3.5.2–.5當完成。
