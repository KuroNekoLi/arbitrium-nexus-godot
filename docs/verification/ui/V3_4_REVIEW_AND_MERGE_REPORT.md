# V3.4 Review and Master Integration

2026-10-15。狀態：VERIFIED — 技術／headless／靜態畫面整合已merge並通過Master CI；GUI_NOT_VERIFIED，不是最終美術或真人可玩性核准。

## Source / Scope

使用者在V3.1–3.3審查中明示V3.4已好，納入獨立批次。
基準：已推master的2ce71a2f2d88b425ccfc9e99d5e65a15363b35b8；Production來源53fdbdfec6f5fcdbfb9ae66087cd8c81ea84ac7f，途中補審tests/CI/docs-only來源f73e31cdf2ca5f235594ab4936191df36115958c。
分支integration/v34-reviewed-20261015；只merge以上明確V3.4 source，不自動跟進後續未知功能。
內容：保留三個HeroRosterItem／真肖像／Kenney邊框，HP與MP獨立named bars、可見焦點；CommandMenu六項指令保留signal及fields，只加skin與input-transparent accent rail。Analyze/Item仍UNIMPLEMENTED，不假稱可玩。

## Review Finding / Fix

**V34-R01 / P1：共享元件的翻譯初始化依賴。**
來源V3.4把legacy update_status改用BATTLE_HP/MP翻譯key，但舊main從未安裝BattleScreen catalogues。全新程序載入舊場景可重現String formatting error；test_combat_ui雖印UI TEST PASS，stderr仍有12個ERROR。嚴格helper正確判FAILED_PROCESS_GATE，不能以exit0忽略。
修正：HeroRosterItem._ready呼叫既有BattleTranslations.install()。該入口先驗證所有catalogues再原子註冊，且冪等、不改locale；所有元件共用同一份已擁有的Translation，不自行創另一套翻譯。沒有更動舊玩法或任何Domain。
新增test_p4_v34_legacy_roster：全新程序、不建立BattleScreen，兩語update_status、真bar數值、零最大值僅render clamp、無手牌計數、離場重入與兩份Translation不重複，共18條。

**V34-R02 / QA：來源補交GUI與workflow限制衝突。**
f73e31c新增V34 GUI28與收據，但同job再次包含已耗盡的V25。正常三方merge在push觸發設定衝突；保留master的manual-only+job if:false，完整保留新增測試與歷史收據，不自動再跑。
靜態檢查新GUI helper還把window physical座標傳給Viewport.warp_mouse；改用原logical point，push_input仍維持window座標。這只是測試helper修正，不改Production；source第三輪28/28不冒充修正後或本輪SHA驗證，GUI_NOT_VERIFIED且需要新授權才可再驗證。
原GUI28 assertions保留不弱化；source無效YAML、錯誤minimum30而實際28等歷史報告原樣留存。

## Requirements / Evidence

| Requirement | Source | Implementation / oracle | Status |
|---|---|---|---|
| 三角色切換／獨立HP/MP／可見focus | UI02 §2/6、DesignSystem，視覺PROVISIONAL | HeroRosterItem/visual_tokens；V34 102 | 本機first102/102，最終CI待回填 |
| 六個Command名稱與fields保留 | M5 Command契約、UI02 §3 | CommandMenu；原V34 signal測試不改 | 本機firstPASS，最終CI待回填 |
| Legacy API獨立可用 | Architecture skill／preserve existing scenes | 共用catalogue installer；legacy18及原4Legacy | first舊UI error被抓出，修正後待CI |
| 全解析度／雙語真圖 | QA／既有Render gate | V23九PNG30+V31三PNG20 | 本機與CI帳本見最終收據 |
| Domain Single Source of Truth | CombatImplementationContract | Domain/ContentConfig/seed driver無diff；原1238/100Seeds | 沿用Full，不弱化oracle |

Godot4.7.2.stable.official.ed1daf0bf、Compatibility/OpenGL3.3/GTX1650；只在隔離managed worktree施工，保留原使用者8張PNG。首輪logs與execution.json保存在專案外../v34-headless-attempt1/，含正確exit17 probe與失敗stderr。helper在legacy error處停止，原排定test_turn_flow未執行，不能記PASS。
本輪最多三次：V34/legacy原群組本機first→stagedsecond→Masterthird；新增legacy18由stagedfirst→Mastersecond。視覺capture本機first→stagedsecond→Masterthird。舊P43/P44、V25、V26 GUI完全不重跑。
canonical Fast補V34 102+legacy18，P4平行19組937assertions+4Legacy；不用來源workflow的dynamic>=70當正式oracle。Full1238/100Seeds不改；Render保持12圖並補shared hero script path filter。

## Engineering Learning

1. 目標與來源：共享Godot元件不能只在某個大型scene初始化後才正確運作；依architecture與UI翻譯契約補足邊界。
2. 原理：Godot tr找不到key就回傳key本身；若key字串沒有%d，繼續以%傳兩個數字就產生格式錯誤。呼叫者印PASS或exit0不等於沒有runtime error。
3. 概念：Scene._ready是元件已入tree的初始化點；Translation是共享Resource，由既有installer管理ownership及冪等。
4. 主要責任：HeroRosterItem只顯示數字與發選角signal；BattleTranslations只管catalogue；CommandMenu發既有意圖；M5才擁有資源/傷害/勝敗。
5. 取捨：只在legacy main加install可修這個入口，卻仍使獨立元件依賴外部隱藏前置；元件明確確保既有installer更穩健。沒有到處新增Translation或手寫中英fallback。
6. Kotlin/Android對照：像共用View不應假設只被某Activity建立；DI/應用資源初始化要可重入。idempotent install類似共享repository initialize-once；狀態Flow仍唯讀。
7. 測法：不同runner各自啟動Godot，先確認catalogue未安裝，再獨立建立元件；兩語/零值/queue_free重入；嚴格檢查stderr與摘要；原legacy照跑。
8. 證據：首輪102 PASS不掩蓋legacyERROR，修正待staged/Master收據。GUI/真人不冒充headless驗收。
9. 面試追問：為何某scene正常、另scene錯？為何exit0仍紅燈？共享Translation怎麼防重複？誰負責cleanup？renderer為何只能clamp顯示不能修State？
10. 延伸：[Internationalization](https://docs.godotengine.org/en/4.7/tutorials/i18n/internationalizing_games.html)、[Scene organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html)。
11. Skills：延續本輪已讀orchestrator/SpecGuardian、architecture、UIUX、rendering、QA；循序review共享API、翻譯生命週期、真圖、CI與保留oracle。

## Assets / Limits / Rollback

無新增/下載素材，沿用Kenney既有CC0框、肖像、NotoSansTC及原manifest/credits；沒有換Theme系統、插件或角色Canon。
原GUI限制不解除，V3.4真滑鼠/鍵盤playtest未執行；本次限技術/headless/靜態畫面整合，不宣告V3.5或商用品質核准。
原Boss碎片/角色映射與8卡重疊限制延續V3報告。本次merge可revert回2ce71a2，不需Domain或存檔遷移，不刪來源分支。

## Final Receipts

施工時「待CI」保留；最終狀態以下列收據為準。

- Production merge／staged受測SHA：e1f506159fd90f14a1872a248d96e33493c7f894，parents包括master2ce71a2與V3.4來源53fdbdf。
- 後續正常merge GUI handoff/tests/docs：89871c97ec774c2ab0b0db1032785ca6b50eee9c，parent包括f73e31c；已fast-forward推master。相對staged e1f5061，scripts/ui、scripts/battle、scripts/domain、resources、scenes及project.godot完全沒有差異。
- staged全部completed/success：[Fast38750705109](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38750705109)、[Integration38750705120](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38750705120)、[Full38750705220](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38750705220)、[Render38750705205](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38750705205)。raw job116476039555已讀：19組937、V34 102/102、legacy18/18、原4Legacy通過。原本ERROR已修復，不改測試期待。
- 正式Master受測89871c97ec774c2ab0b0db1032785ca6b50eee9c：[Fast38751653887](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38751653887)、[Full38751653715](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38751653715)、[Render38751653611](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38751653611)全部completed/success。
- 已讀正式raw jobs116479318876／116479318153／116479317746：V34 102/102、legacy18/18、V3merge90/90、P4共19組937+4Legacy；原1238 Domain基線與100固定Seed完整戰鬥Replay保持全綠；12張真PNG（V23 30/30、V31Render20/20）。V26步驟明確skipped，歷史V25/V34 GUI job沒有啟動。
- 主控原生12PNG與logs在outputs/p4_input_capture/v34_review_local_20261015/、v34_review_boss_20261015/與專案外../v34-render-*-attempt1.log。實際目視1280繁中idle及1920英文idle原圖：三角色資訊、HP/MP各自獨立bar、全部command按鈕、卡牌成本可見；30/30及20/20。不以640縮圖或headless當完整視覺驗收。
- 保留來源GUI28與歷史收據，不重跑任何耗盡群組，不把helper靜態修正冒稱驗證成功。最後文件收據commit僅文件，不冒充另有程式/GUI測試。
- 遠端integration/v34-reviewed保留e1f5061 staged Gate；local後續tests/docs merge直接推master而不再次觸發integration重跑，避免超出本批三次帳本。來源分支未刪除，未force push。兩個工作樹生成的SimpleCards cache變更全部排除提交。
