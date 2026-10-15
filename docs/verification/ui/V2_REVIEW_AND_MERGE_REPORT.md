# V2 Review, Missing UX Implementation and Merge Gate

日期：2026-10-15。狀態：VERIFIED — V2技術／版面整合範圍；已merge master。不是V3美術、原GUI或真人平衡驗收。

## 來源／權限
master基準 adb758206787aac62f1dd1109f5bbf1c67a3c095；V2來源 ui/v2-layout-fidelity-20261015@822b1ce6d573cad6634b11c161634d5360eda456。
隔離分支integration/v2-reviewed-20261015，工作樹C:/Users/user05/.codex/worktrees/v2-reviewed/referenced-chatgpt-conversation-this-is-an。
使用者授權審查V2、補缺及驗證後merge。沒有解除原P43/P44或V25第四次禁令；不改Domain/數值/資源/牌區/RNG/勝敗，不新增插件或素材Canon。

## 審查與修正
承接V2：分離AP/phase/tools islands、底緣手牌、contextual Conditions、獨立BattleLog、固定Confirm/Cancel、折疊偏好設定、8張可檢視扇形、instance選取高亮、水平空手牌。保留V1 facade、SimpleCards、scene profiles與雙語。

| 優先 | 缺陷／證據 | 修正 |
|---|---|---|
| P1 | Reaction原本只有鍵盤入口判斷，背景GUI/焦點未隔離 | HUD全畫面MouseStop shield、modal內Tab/ShiftTab閉環、關閉恢復合理focus；Outcome也擋背景快捷鍵 |
| P1 | V26首輪Pass被shield攔住 | z_index只控繪製，GUI依tree order；shield移到reaction/result之前 |
| P1 | V26次輪前7次Tab逃逸 | SimpleCards自行幾何hover並grab_focus；modal暫存背景Control focus_mode並設NONE、重繪處理新卡、關閉以WeakRef恢復存活節點，不改addon |
| Test | 1920drag持有但drop失敗 | warp_mouse用Viewport logical座標，push_input(false)維持window physical轉換；不改Production target或付款assertion |
| CI | 新master已改三層CI，V2只在舊branch workflow受測 | 保留canonical fast/integration/full；fast平行P4增layout18/context23/hand39，共12 suites/568 assertions+4Legacy；Full重用原1238/100seeds |

## 測試帳本與新範圍
新test_p4_v26_pending_ux只驗V25明列缺口：1920全8張、已選扇形drag/drop→固定footer真交易、實際wheel/偏好開關、Reaction隔離/Tab/明確Pass/Replay。不是改名複製或呼叫P43/P44/V25。

| 群組 | 實際結果 | 證據 |
|---|---|---|
| 新V26第1次 | 47執行/44PASS/3FAIL | 專案外../v26-attempt1.log；drag座標與Pass遮罩 |
| 新V26第2次 | 47執行/40PASS/7FAIL | ../v26-attempt2.log；drag/付款/Pass已成功，Tab逃逸 |
| 新V26第3次（最後） | 47/47 PASS | Actions38742124854，source d9e6e2a；master明確skipped，沒有第4次 |
| V2 headless | layout18/context23/hand39全PASS | ../v2-layout-contracts1/execution.json及logs |
| 舊接線 | Scene8/HUD36/P43integration31/Lv40positive32全PASS | ../v2-import1/execution.json及logs |
| 舊GUI／V25 | NOT_RERUN | 原P44第三次14/16及V25第三次31/31紀錄保留 |

本地Godot4.7.2.stable.official.ed1daf0bf、Compatibility/OpenGL3.3/GTX1650。檢查report及ERROR，不只exit0。失敗log保留專案外，未塞production。
CI第3次V26只在integration/v2-reviewed首次發布分支執行；master執行Fast/Full及9張V23靜態capture，避免GUI第4次。V3美術Gate不因此完成。

## Engineering Learning
1. 目標／來源：UI02及UIUX modal/focus安全契約，保留snapshot→意圖→M5單向流。
2. Godot概念：CanvasItem Z是視覺序；Control tree/mouse_filter是命中；focus_next/previous是鍵盤圖，與Domain時序不同。
3. 責任：HUD擁有modal生命周期；Screen擋背景快捷鍵；Card仍由SimpleCards拖曳；付款只由Domain。
4. 架構選擇：局部shield/focus保持既有Reaction facade。替代PopupPanel需要重構；只改Z無效，recursive focus也不能保證Addon不主動grab。
5. Kotlin/Android對照：Dialog觸控攔截/focus trap；WeakRef類似只對仍有效View binding操作；選取高亮類似remember UI狀態，不是Reducer transaction。
6. 如何測：真mouse/wheel/Tab與兩種坐標、唯一instance、State hash/Tape Replay；Headless geometry不證picking。
7. 測試結果：見帳本，失敗亦保存，不修改期待掩蓋。
8. 面試追問：為何看得見按鈕卻點不到？如何防addon偷焦點？何時修測試座標而非Production layout？怎樣避免scene重入時恢復已釋放Control？
9. 延伸官方依據：[Viewport.warp_mouse/push_input](https://docs.godotengine.org/en/4.7/classes/class_viewport.html#class-viewport-method-warp-mouse)、[Control輸入與z_index限制](https://docs.godotengine.org/en/4.7/classes/class_control.html#signals)。
10. Skills：orchestrator/SpecGuardian統籌；architecture生命週期/WeakRef；UIUX focus/手牌；QA保留oracles/三次帳本/CI。

## 限制／回退

### 真實畫面目視後追加修正
主控目視V23九張原生截圖發現4-card底部裁切；原V24只量Card hit rect而非內層face。新增test_p4_v27_face_bounds量實際face旋轉四角（0/1/4/8張、繁中/英文），首輪8執行/2PASS/6FAIL，face高度可達510/1062，Card hit rect仍218。
修正CardView摘要已知wrap寬144及最多3行（不可用卡2行），超出以ellipsis並保留tooltip/右側完整詳情。不修改Card根節點尺寸/slot/hit算法/拖曳引擎。V27修正後staged與Master均8/8；V26第三次47/47在d9e6e2a成功，後續不第4次重跑；此追加僅卡內文字/face minimum size，該GUI收據限定其原SHA，不冒充新SHA再驗證。
V26 staged第三次：[38742124854](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38742124854)，同時V23 30/30；fast38742124852、integration38742124634及Full38742124849均success。追加V27納入fast平行P4：13 suites/576 assertions。

## 正式合併／最終收據
- 合併commit：d9e6e2ab8acf95c231180577a829a31836070c96（兩個parents包含最新master基準與V2來源822b1ce）；保留原V2歷史，無force push、無PR、未刪分支。
- 卡面修復／Master受測程式：d1a971a9c4800e04196ba648416f900148ea122d；已fast-forward推送master。
- staged最終 [Fast38743195904](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38743195904)、[Render38743196007](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38743196007)：completed/success；V27 8/8、V23 30/30。
- 正式 [Master Fast38743758109](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38743758109)：completed/success；13組P4契約576、4Legacy、V2 geometry及既有接線通過。
- 正式 [Master Render38743758086](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38743758086)：completed/success；九張PNG／30assertions，V26步驟明確skipped，不冒充Master重跑GUI。
- 正式 [Master Full38743758255](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38743758255)：completed/success；維持1238 Domain／100固定Seeds完整戰鬥與Replay／4Legacy。scripts/domain與canonical Full runner相對master基準完全無差異。
- 主控另於GTX1650原生補拍九張並目視：outputs/p4_input_capture/v2_review_fixed_20261015/（v23_idle_1280_zh.png、v23_hand8_1920_en.png等），../v2-render-local2.log為30/30。已確認4張實際卡面底部不裁切，0張水平空狀態與8張扇形維持；不是只看Control hit rect或exit0。
- 後續僅文件收據commit不改受測程式，不宣稱該docs SHA重跑CI。原本地使用者8張未提交PNG未改動；新工作樹的兩個SimpleCards自動cache修改不納入提交。
- 遠端並行ui/v3-visual-foundation-20261015不在本次範圍，未合併或覆寫。

V2不是V3正式Art/Theme。原概念PNG尚未穩定pin在repo；既有Boss鄰角碎片/角色映射仍placeholder及provenance pending。無像素級/商用品質/真人平衡完成聲明。
第三次V26若失敗，不merge此未過Gate。同步master先fetch，不force push不刪branch；回退本merge可恢復原V1 UI而不動Domain。
