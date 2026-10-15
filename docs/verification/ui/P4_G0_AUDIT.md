# Phase 4 G0 唯讀盤點與施工契約

日期：2026-10-15。基準 `7163aeff0de1f93b2c1a05e20bf7a3c3899333b7`，正確倉庫 arbitrium-nexus-godot/master。已 fast-forward pull。唯一既有未追蹤檔案 `.codex/COMBAT_SPEC_MEMORY.md` 保留且排除提交。

實際 binary：`C:/Users/user05/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe`。實測版本 `4.7.2.stable.official.ed1daf0bf`。現有 Renderer = gl_compatibility，canvas_items，1280×720。

## 現況／依存

- 已完整讀取根 AGENTS、主控／所有本輪專業 Skills、Spec Guardian（八份 hash 相同）、所需 references、現行 Combat Index/Contract/Open/Handoff、M5.5報告、docs/ui 00～05。既有00～24於上一輪完整讀取；本輪按新索引核對增量／取代關係。
- 官方 CI `38678649741` 經 GitHub connector讀回 job `116237914387`：completed/success，全部步驟成功，包含100 seeds及四組legacy。這是9c8b14b8的歷史基準，不代替本輪驗證。
- 舊main是獨立舊prototype，不用其BattleState。新場景以既有M5.apply/replay為唯一權威；M2/M3/M4照原API委派，UI不接受damage payload。
- `m5_full_battle_fixture.gd`是可重播3×12獨立牌組的已驗證配置。本輪P4.1～3明示使用此FIXTURE_ONLY內容，不聲稱Lv40 parity或P4.5完成；driver僅測試參考，不接管玩家輸入。
- HeroRosterItem可重用；SimpleCards 2.13保留，新增presentation subclass；卡片Artwork取既有atlas，各語言用獨立Label。
- 角色圖集三組各3×3、idle/run/strike；背景與Boss透明圖已實看。角色identity映射沿用原main（A/nova_atlas，B/kleya_atlas，C/yora_atlas），僅外觀別名，不更改fixture身份／職能。
- 概念圖在對話可見，但本repo無穩定原檔。以docs/ui尺寸／層級為依據，視覺對照仍待原圖；不宣稱像素還原。

## 範圍與選型

P4.1 scene/slots/adapter/smoke；P4.2 HUD/手牌/兩語/輸入/Reaction；P4.3 controller/真支付傷害/event演出/tape/replay。P4.4～6不擴充。

採可逆Node2D＋Y-sort，沿用Compatibility與既有atlas；小型Sprite3D比較另附證據。Hybrid需要額外render target／座標映射，本輪無此需求，不導入。角色腳底anchors、前大後小、左下到右上緊密排列，Boss全身縮入戰場。無新自由走位命令。

## 缺口與處理

Analyze/Counter未交付內容→顯示未實作理由，不偽造。全Exhausted正HP→保留Domain pending，不擅判敗。未核准正式美術→重用既有placeholder，不作Canon定稿；無新付費服務／插件。手機GPU／實體觸控／手把未測，不能宣稱驗證。

單一agent整合，Scene/controller/adapter/Theme/translation/RTM各由本agent持有。每Gate由QA技能選runner驗證、保存raw logs；最多三次失敗執行，若三次失敗即停止該里程碑。自動化輸入和截圖不冒充真人playtest。
