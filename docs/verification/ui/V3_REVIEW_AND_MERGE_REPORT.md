# V3.1–V3.3 Review and Master Integration

日期：2026-10-15。狀態：IMPLEMENTED_NOT_VERIFIED — 等待整合與Master CI；不是V3最終美術核准。

## Source / Permission

- 使用者授權Review V3，通過後merge；途中明確加入V3.3審查。
- master基準：a355d0b97374295fe731cd48f148eb4f2c8e3014。
- 初始V3來源：97816644e（完整SHA見merge parent）；V3.3來源：ui/v3-visual-foundation-20261015@85d5c64b396145beca43153d66c644ab2497a269。
- 隔離分支integration/v3-reviewed-20261015；先正常merge V3.1/2保留V2修復，再merge V3.3；不force push、不刪來源分支、不清使用者修改。
- 不變量：保留V2 modal隔離、SimpleCards及既有API；Domain/ContentConfig/project.godot/1238 assertions/100-seed driver無修改。

## Review / Fixes

| ID | 優先 | 問題與證據 | 修復 |
|---|---|---|---|
| V3-R01 | P1 | V3仍基於審查前V2，CardView與已驗證wrap寬144衝突 | 採V3 Frame並移入V2穩定wrap寬；不可用卡摘要1行，保留原因空間 |
| V3-R02 | P1 | 本機真PNG發現成本徽章幾乎空白；字串相等測試仍PASS | ellipsis Label minimum width為0，HBox spacer吃掉空間；以真字型量測成本，限寬130，tooltip保留全文，不自算成本 |
| V3-R03 | P2 | 取消hover/selected後退回V2 accent，遺失V3 idle金屬邊/陰影 | 每卡獨立idle StyleBox快照；不改root尺寸、hit rect、drag或command |
| V3-R04 | P1 | Locked+Exposed同列在實際PNG截斷 | read-only狀態改三行；保留V3.3完整tooltip，不改Break語意 |
| V3-R05 | QA | 來源分支再次執行舊V25 GUI，不能當作本輪授權或最終SHA證據 | 禁用歷史V3.2 GUI workflow job；原P43/P44、V25、V26全不重跑 |
| V3-R06 | CI | V3 branch-only workflows不保護master | canonical Fast加入V31/32/33/merge；Render加3張Boss fixture；Full沿用原1238/100Seeds |

V3.3實讀新增BossTitlePlate、HP/Break sections、PublishedIntentPanel、tokens及47條測試。它只讀projection：沒有Break或公開Intent則整區隱藏，不猜目標/威脅數值。保留V1/V3.1 aliases、既有first-published-intent行為；沒有第二套Boss AI。

## Requirements / Test Ledger

| Requirement | Source / authority | Code / test | Evidence |
|---|---|---|---|
| Theme、HP/Break分離與公開Intent | UI DesignSystem §3/5、UI02 §5；presentation PROVISIONAL | battle_theme、visual_tokens、enemy_status_panel；V31 31、V33 47 | 本機V31首輪31/31；最終CI待回填 |
| 真成本/Artwork/雙語/選取/不可用原因 | UI02 §2/3/6，Domain唯一權威 | CardView/Frame；V32 73、merge90 | 本機V32 73/73；merge第一版80/80，新增成本幾何10條待CI |
| V2修復與卡面安全 | V2 master d1a971a／DesignSystem §6 | V27 8、merge長字/Exhausted×2locale×2resolution | 本機V27首輪8/8，最終CI待回填 |
| 真實Godot畫面 | QA與視覺驗收契約 | V23九PNG30、V31三PNG20 | 本機各首輪30/30及20/20，目視抓到R02/R04，最終CI待回填 |
| Domain/Replay保持 | CombatImplementationContract §2/3 | canonical Full1238+100Seeds+4Legacy | 待整合及正式Master CI |

本機Godot4.7.2.stable.official.ed1daf0bf，Compatibility OpenGL3.3／GTX1650。
G0在專案外../v3-g0-inventory.json；首輪import、故意exit17 probe與四組logs在../v3-headless-attempt1/。
首輪12張原生圖在outputs/p4_input_capture/v3_review_local_20261015及v3_review_boss_20261015，logs在../v3-render-layout-attempt1.log、../v3-render-boss-attempt1.log。
主控實際查看1280繁中idle、Locked+Exposed及1920英文8卡原圖；不以PASS摘要代替目視。V3.3接入與成本/狀態修正後須再查CI最終原圖。
同群組最多三次：本機first→staged second→Master third；V33沒有本機執行，從staged first起計。原GUI不參與、不改名複製規避上限。
GUI_NOT_VERIFIED：來源38744445451及38748033243只保留歷史，不作本輪GUI授權或最終SHA驗收。來源V32初次71/73與修正locale期待後73/73記錄保留，不弱化既有assertion。

## Engineering Note

1. 目標／需求：在已核准V2布局上接入可逆V3.1–3.3視覺候選，依UI02與DesignSystem；不是正式美術Canon。
2. Godot概念：Theme提供共用StyleBox/字型；Frame builder組合Control；Container按minimum size排版，Label.text正確不保證文字可見。
3. 程式責任：CardView仍繼承SimpleCards.Card管理hover/selection/drag signals；Frame只組裝；EnemyStatus只讀projection；BattleController→M5仍獨佔玩法。
4. 架構理由：共用Frame保留既有API、可回退；獨立StyleBox避免選中一張污染其他卡；wrap寬/行數限制避免初始窄排版膨脹。
5. 替代方案：固定整行成本較簡單但留白過多；量測字型且限寬保留compact徽章。重寫手牌引擎或全面改Popup與本次無關，不採。
6. Android/Kotlin對照：Theme像MaterialTheme；Frame像可重用Compose Card；minimum size與Row.weight/ellipsize互動相似；projection像StateFlow的UI映射，不能自行改Reducer。
7. 如何測：兩語×兩尺寸×可用/Exhausted，檢查真成本寬、長文字、卡面、idle還原、state hash；12張原圖及1238/100Seeds回歸。
8. 結果與證據：見帳本與最終收據；第一次圖缺陷如實保留，不冒充GUI/真人/效能驗收。
9. 面試追問：Label文字正確為何看不見？為何測face不只hit rect？共享Resource如何污染？衝突為何不能整檔選ours/theirs？如何證UI重繪不改Domain？
10. 延伸：[Containers](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_containers.html)、[Resources](https://docs.godotengine.org/en/4.7/tutorials/scripting/resources.html)、[Theme](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_theme_type_variations.html)。
11. 實際Skills：orchestrator+SpecGuardian盤點/來源/權限；architecture責任與資源隔離；UIUX文字/成本/雙語；rendering既有Compatibility畫面目視；QA原runner/CI/oracle/限制保存。

## Assets / Limits / Rollback

沒有下載/生成新素材或安裝plugin；沿用NotoSansTC、CardAppearance artwork、SimpleCards、背景/角色及既有manifest/credits，未推定新授權。
這是既有Theme可逆候選擴充，不是重大美術換包；不宣稱像素參考一致、商用品質或最終V3核准。Boss鄰角碎片、角色映射/來源、8卡需選取閱讀、真人/GPU效能仍待處理。
Rollback可在專用分支revert此次merge保留V2；Domain不需遷移，不刪分支或force push。

## Final Receipts

待整合與Master CI成功後追加完整merge/tested SHA、Run URL及結果；此前不聲稱已merge或VERIFIED。
