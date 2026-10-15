# V3.5 Quota Checkpoint — Continue Implementation, Do Not Claim Completion

2026-10-15。使用者規則：Codex剩餘低於30%先保存、push與交接。本次檢查used71%／remaining29%，停止新功能，僅完成保存交接。
Status: **NEEDS_REVISION / V3.5 PARTIAL**。不是High-Fidelity VERIFIED，不是完整V3.5.1驗收。master不修改。

## Checkout / source

Repo KuroNekoLi/arbitrium-nexus-godot。V3工作線ui/v3-visual-foundation-20261015；safe branch ui/v35-hud-convergence-20261015。先fetch比較兩者HEAD，禁止force push。基準50e2eaf（完整SHA在V35_BASELINE），包含已Review的V2/V3.1–3.4；不要退回f73e31c遺失modal/費用/翻譯修復。
工作樹C:/Users/user05/.codex/worktrees/v35-hud/referenced-chatgpt-conversation-this-is-an；原cwd使用者8張PNG完全保留。Godot binary：C:/Users/user05/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe。

## Already done — no duplicate planning

1. 必讀Skills／UI文件已檢視；新agent仍依本次適用Skill自行閱讀。V3.5.0基準commit1d64ccd已push V3及safe branch。
2. 使用者兩JPEG已pin在docs/ui/references/v35，實際皆1280×720（不是B1536×864）。Hash及四角mapping見docs/verification/ui/V35_BASELINE.md。不可拿參考圖切素材。
3. 真基準9PNG30/30：outputs/p4_input_capture/v35_baseline_20261015；logs專案外../v35-baseline-render.log與import.log。
4. AP部分真正實作在team_phase_header.gd：原API resources Label維持但不重複顯示；新core SVG+APValue+RPValue+gem row；只讀projection.resources，base_ap取真資料，不硬寫6上限。數字不截斷；最多12顆只是視覺budget，完整數字/tooltip保留。
5. 實際整合Kenney CC0 NinePatch及兩個原創獨立SVG；沒有新插件/框架，manifest/CREDITS已更新。
6. 首輪畫面發現NinePatch直接放PanelContainer造成min size膨脹/遮擋（雖headless PASS）。已加零minsize overlay wrapper並限制caption/RP不wrap；不是用縮圖或PASS掩蓋。

## Executed / retry ledger

| Group | Attempt / actual result | Evidence |
|---|---|---|
| Baseline V23 static render | baseline first30/30 | ../v35-baseline-render.log |
| AP HUD/Layout/Integration | first36/36 +18/18 +31/31 | ../v35-ap-attempt1/execution.json + runner_1..3.log，fresh import無error |
| New V35 resources | first32/32 | ../v35-resource-contract1.log；2locale×AP0/6/9/16，frame bounds+Domain hash |
| AP static render | first30/30但目視有缺陷；second修正後30/30 | ../v35-ap-render.log、../v35-ap-render2.log |
| Original GUI | NOT_RUN | 歷史P4.4 14/16不清除，不複製/改名規避；其他耗盡GUI見V3 reports |
| Full1238/100Seeds | NOT_RERUN_THIS_CHECKPOINT | 基準master89871c9 CI成功僅歷史；本批Domain無diff，不冒充新SHA執行 |

AP修正後真9PNG：outputs/p4_input_capture/v35_ap_fixed_20261015；主控已看1280繁中原圖。原生Godot4.7.2.stable.official.ed1daf0bf／Compatibility OpenGL3.3／GTX1650。32test的AP9/16是明確MOCK_ONLY readmodel邊界，不是真對局AP加成驗收。
本批AP static capture已用2次，最多剩1次（不能新prefix當重置）。新32test用1次最多剩2；HUD/Layout/Integration用1次最多剩2。不同未開始stage群組另建scope，不得覆蓋此帳本。
本次CI推送後如無法在quota內確認，必須標CI_PENDING，後續先讀最新runs，不直接再跑suite。新32test尚未掛入canonical CI，屬必要待辦。

## Files to modify / create — separate staged commits

### V3.5.1 finish Top Left (first next task)
- 修改scripts/ui/hero_roster_item.gd與scripts/battle/ui/components/party_status_panel.gd：更強selected/hover/focus框、較厚且帶紋章的HP/MP、真狀態icons。保留HeroRosterItem signal/update_status與Subtitle/Stats兼容路徑；incapacitated視覺不可阻止純UI切角查看。
- 只有projection.barriers、reaction.guard_actor_ids、casts及actor.status真存在才生狀態；不要捏造圖示。必要新增純展示set_status_badges API，不改Domain。
- 微調team_phase_header.gd：目前APcaption/RP偏小、白Kenney框需向B的暗金/冷cyan收斂；不要再長高遮角色。AP>6/16保持，RP不得遺失。
- 新增tests/test_p4_v35_party.gd與new scoped mouse/key cases，覆蓋三角切換/hash、真disabled/casting、兩尺寸兩語；保留舊cases，不稱舊GUI清除。
- .github/workflows/ci-fast.yml沿用P4 job，加入32resource及party明確oracle；不要重建CI。資源/圖片CI需要safe/V3分支path/trigger，避免無意再觸發耗盡GUI。

### V3.5.2 Bottom Left
- 修改components/command_menu.gd，新增可換command icon resources/副說明/i18n，LastSpell與End兩種強視覺；原6 command IDs/fields不變。
- 預計新增components/battle_command_visual.gd、assets/ui/v35/icons/*.svg或已查授權素材。Analyze/Item仍UNIMPLEMENTED，不能加圖示就說玩法完成。
- 普通圖示可自選；付費/不明授權/整套theme替換需決策報告。更新manifest/CREDITS與真操作測試。

### V3.5.3 Top Right
- 修改components/enemy_status_panel.gd與必要presentation純讀欄位：技能圖/公開target badge/可用portrait；真值HP/Break/Exposed分開；無資料省略、不猜威力或下一招。
- 新增tests/test_p4_v35_intent.gd，保留V31/V33 31/47；不得重寫Boss AI。

### V3.5.4 Bottom Right
- 修改components/action_context_panel.gd、battle_log_panel.gd、必要battle_screen.gd presentation glue。保留details/mode/combo/confirm_button/feedback/log_label facade與HUD signals。
- 可新增components/action_summary_card.gd、combat_log_entry.gd；真selected card成本/Artwork/目標/validator狀態；Confirm/Cancel固定scroll外。
- 日誌需真DomainEvents seq、有順序、保留底層Tape；只在展示fixture清楚MOCK_ONLY，正式不塞假記錄。

### V3.5.5 final comparison / QA
- 新增tools/qa/compare_v35_references.gd（或明確可重現的deterministic比較工具），輸出B/Actual並排、50%overlay、四角標註。不可拿ImageGen假裝runtime；原B1280等比、不比較人物/背景。
- 新增tests/capture_p4_v35_hud.gd，按使用者VIS01–10：雙語雙尺寸、selected detail、真events、狀態、0/1/4/8、focus/disabled；MOCK_ONLY分開。
- 每輪Top5 mismatch含NodePath/實際bounds/commit/新PNG；六維及四角各≥3、總≥20才READY_FOR_USER_REVIEW，不能代替使用者核准。
- 更新docs/verification/ui/V35_FINAL_REVIEW.md、requirements_traceability.md與asset manifest；逐stage工程Note含Compose對照、實測、回退。

## Backfill contract / authority

下一agent完成後建立docs/handoff/V35_AGENT_BACKFILL.md，按同名模板回填實際files/commit/CI/log/PNG/hash/失敗與跑次；不可只回貼散文。若在GPT「對話」無repo工具，可提供逐檔完整patch與測試檔案，標NOT_EXECUTED，讓Codex接手驗證。
最終停在V3工作線，**不merge master，不修改V2分支**。每次push先fetch檢查並行source HEAD；不能force push。只有使用者明確解除quota門檻或額度恢復才讓本Codex擴大施工。
