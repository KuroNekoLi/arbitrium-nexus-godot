# 04 — 每角 12 卡牌組、抽牌、洗牌、施法卡的區域

> **Documentation status · 2026-10-15 — APPROVED_DETAIL + HISTORICAL_TBD**：每角12張 SP、開局4張、Player Phase 補至4／手牌上限8／每人免費換牌1次已核准。不得把歷史「僅提案／TBD」當成目前狀態。 現行導航：[Combat Spec Index](COMBAT_SPEC_INDEX.md)；缺口：[Open Issues](COMBAT_OPEN_ISSUES.md)。**Godot Domain M1～M5.5：1,238/1,238 通過；100 場固定 Seed 的完整戰鬥與 Replay 已驗證（[Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741)）。Scene／真人可玩／正式平衡仍未驗證。** 以下舊段落保留歷史脈絡，不是新測試或新核准。



## 1. 基礎（APPROVED）

每一位上陣角色**各自配置12張技能卡**，其內容可混搭通用、符合職能/標籤、同一故事角色專屬和特定戰鬥 Variant 專屬。不是全隊共用36張手牌；每角各有 draw/hand/discard/casting。Last Spell 是獨立槽，不佔12張、也不進抽牌。

開戰時每角色將其12張卡洗牌，抽4；每玩家回合開始時，手牌**不足4才補至4**；不用的牌保留，不是全部重抽。打出即時技能完成後進 discard；完整詠唱放入 Casting Zone，成功結算／中斷後再依法律移區（具體中斷去向TBD）。若 draw pile 不足以補足，先抽完剩餘，再將可洗回的 discard 洗牌繼續抽；禁止 duplicate card instances。

## 2. 精確抽牌演算法（符合已批准高階規則）

```text
DrawToFour(character):
  missing = max(0, 4 - hand.count)
  repeat missing:
    if draw.empty:
      if discard.empty: break
      draw = Shuffle(discard, seeded_rng)
      discard.clear()
    hand.add(draw.pop())
```

若當前手牌超過4，**不要自行棄至4**；**M-D25 已核准每人手牌上限8**。容量不足的多餘抽牌不執行，且不從牌庫移出額外的卡牌。若不夠牌可洗，則保持不足4，絕不能無限重抽。

## 3. 實體卡與定義區別

`CardDefinition` 是模板（ID、tags、cost、effects/rarity/eligibility），`CardInstance` 在戰鬥內有穩定唯一ID和區域。配置多張相同模板時生成不同 instance_id。任何效果引用卡需指向instance_id，避免「打出同名卡把另一張移區」。

## 4. 牌組驗證

- 必須恰好12張才可正式開戰（prototype；未滿能否用填充基本牌？TBD）。
- 確保角色 Variant 資格以及卡牌收藏數量；不能使用不合法的專屬卡。
- **同名重複數量、UR上限、職能/專屬卡比例尚未批准**。不要自動設2張上限或SR/UR限制；可先驗證所有條件已配置。
- `Reaction` 是特殊技能卡類型，若未使用仍佔用手牌；Reaction窗口內能否使用它由TriggerWindow校驗。
- 部分卡牌可具破棄與完整兩個施法 profile；選擇方式在05。

## 5. 卡手與換牌

使用者已確認「保留未使用手牌、補至4」；若保留4張就不抽任何新卡，這是可能的卡手風險。**M-D26 APPROVED**：「每人每個 Player Phase 免費棄1抽1」已成基本指令，0 AP／0 MP，不需手牌中的 SP。設計選擇列在14/LEGACY-Q11。若確定棄牌、重洗順序應用 deterministic event 定義。

## 6. 角色不可行動時

`CONCENTRATING` 是否仍抽牌（目前高階流程傾向是，可持有但不可主動出牌）；`EXHAUSTED / INCAPACITATED` 是否停止補牌，皆需要明文定案。最低安全限制：這些角色不得因抽牌造成新主動行動權；所有移區必須可重播。

## 7. 邊界案例

- 牌庫0，棄牌0，手牌2 → 保持2，不產生空白／複製卡。
- 牌庫1，棄牌10，手牌1 → 抽3：抽舊庫1、重洗後2。
- 完整詠唱中的卡不能被洗入；完整詠唱完成後才進discard。
- 兩次連續出牌不得復用同一卡 instance；計算區域守恆：`deck_size = draw + hand + discard + casting + other_explicit_zones`。
- 解散隊伍／替換 Variant 時所裝卡合法性要重審。


---

## 8. Phase 1 Reaction SP 與基礎指令的卡區域契約

**APPROVED P1-D03/D04/D16**：`Guard` / `Protect` 是 Action/Reaction definitions 而非抽牌中的 `CardInstance`；不可在12張卡中憑空插入 Guard/Protect、也不得要求玩家先抽到對應防禦卡。特殊反應是具有 `reaction_trigger` 的真實手牌 `CardInstance`，只有持在該角色手上才可加入計畫；別人的牌不能作為同角色Reaction。

**先規劃、後提交**：拖入 Reaction queue 時**不**立刻從hand移卡，也不扣 RP/MP；先檢查計畫是否可能合法，實際執行時再檢查手牌實例是否仍在hand。已執行的SP需移到它原本定義的目標區域（即時效果通常進discard；特殊鑄造另依05）；**被 D16 略過的反應卡必須保留在原 hand**，不能因 UI曾選取就進棄牌，更不能觸發棄牌增益或抽卡。

**一人一窗口一次**判定角色身份不是牌 instance：同角色同窗口排兩張不同 Reaction SP 依然不合法；可以在按確認前更換選項。其他角色使用另一張牌完全不受前一角色已反應限制，只受 RP池及自身成本限制。基本 Guard/Protect 不列入抽牌守恆分母。

**TBD**：若 Reaction SP 瞬發成功與完整詠唱狀態互動、Reaction SP 帶抽牌或換牌、已排隊SP被中途偷走、特殊反應在結算時留場的移區規則，必須依卡牌明確定義與獨立測試；不可由UI猜測。

## 8. M-D25～M-D30：手牌8／基本補4／免費換牌（APPROVED）

基本抽牌 `missing=max(0,4-hand.count)`；手牌至少4時不補，超額不棄；每角色手牌最多8，額外抽牌只在尚有容量時真正 Draw，未抽出的牌仍在 draw/discard 正常位置，不製造 `CardDrawn`。

免費換牌：每名角色在合法 Player Phase 最多1次，零 AP／MP，選擇 **一張 hand SP 實例**；先驗證 draw pile 或其他**排除該卡實例**的可重洗 discard 存在合法替代牌（M-D29），否則不執行、不耗次數、也不發事件。驗證成功才將原實例**暫時隔離**，發出正式棄牌事件並先結算其合法觸發效果，之後抽合法替代卡（不足時遵守原 seeded 洗牌規則，但不能抽回本次原實例），成功後發 `CardDrawn` 與其合法觸發，最後將原實例加入棄牌堆（M-D27/28/30）。同名不同實例允許；須守住卡牌實例不重複和反無限循環（M-D12）。棄牌觸發改變牌庫時的回滾／失敗政策為工程細則，不能讓原實例在本次換牌立刻抽回。

## 免費換牌牌池在事件中變動（PRE3-R11；DELEGATED_DEFAULT）

在免費換牌 PRECHECK 時若沒有合法替代卡，沿用 M-D29：禁止換牌、不消耗、不發事件。**若 PRECHECK 已通過**，但 `CardDiscarded` 觸發效果在抽替代卡之前移走最後一張合法牌，則不回滾已合法結算事件；發 `CardDrawFailed(POOL_CHANGED)`、消耗本次換牌額度、暫隔離原卡於操作末正常進棄牌堆；始終不得本次抽回同一個 CardInstance。未抽到則不發 `CardDrawn`。詳見20，該例外不可被誤讀為 M-D29 規則遭取消。載入12張牌不齊直接 LoadoutInvalid，不自動填卡；同名上限逐 DeckRules 配置，不能擅設通用2張。