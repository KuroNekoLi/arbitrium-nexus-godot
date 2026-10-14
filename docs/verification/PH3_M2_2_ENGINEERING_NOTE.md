# Phase 3 M2.2 — Cost Engine and Overload

Status: **M2.2 COST_DOMAIN_VERIFIED** — Godot 4.7.2 headless CI passed 43/43; playable SP execution remains deferred.

## Sources

- docs/combat/18: M-D01–17, AP investment, discount, Overload, debt, refund.
- docs/combat/19: M-D18 uncapped CurrentAP and M-D21 same MP in two casting modes.
- docs/combat/20: PRE3-R10 SetCost before numeric discounts and deterministic consumption order.
- docs/combat/22 and 23: test-first, atomic state transitions, reproducible replay.

## Components

- scripts/domain/m2/economy/cost_resolver.gd: internal quote/apply for combined AP+MP payment, SetCost, discounts, minimum AP, Overload shortfall, atomic state and event recording.
- scripts/domain/m2/economy/overload_debt.gd: per-card borrow limit, party debt cap, next-phase AP pool and repayment.
- scripts/domain/m2/economy/cost_effect_resolver.gd: paid-source fixture effects for current AP refund, direct debt reduction and future bonus. Effects may fire once per instance.
- scripts/domain/m1/combat_model.gd: resource and cost modifier state invariants.
- scripts/domain/m2/economy/resource_ledger.gd: player resource opening accounts for prior debt and future AP bonus.
- resources/combat/rulesets/m2_2_provisional_costs.json: BALANCE_PROVISIONAL fixture only.
- tests/test_m2_costs.gd: positive, negative, boundary and deterministic replay cases.
- .github/workflows/godot-m2-resources.yml: M1, M2.1 and M2.2 CI.

## Boundaries

M2.2 does not implement real playable SP, cards in hand, hit, spell effects, casting, Boss AI or UI. PAY_SP_COST_ONLY is internal only; the public PLAY_SP command stays FEATURE_NOT_IMPLEMENTED. The receipt SPCostReservedOnly is not proof of a card played. Existing scenes and original prototype are unchanged.

M-D04 debt carry is PROVISIONAL. MaxAPDebt 8 is a candidate fixture, not Canon. SetCost conflict with multiple eligible SetCost sources is explicitly rejected as MULTIPLE_SET_COST_TBD. Finite discount priority order is ascending priority, grant sequence then effect ID as an implementation fixture.

Do not mark VERIFIED until the actual Godot CI has run and the output, tested SHA and replay hashes have been inspected. Full M2 awaits M2.3–M2.5.

## Verified run — 2026-10-14

- Correct repo/branch: `KuroNekoLi/arbitrium-nexus-godot` / `master`.
- Tested code commit: [`907d406d13dc1fb841e0a52e4364121f5f819fcd`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/907d406d13dc1fb841e0a52e4364121f5f819fcd).
- Actual GitHub Actions: [Run #38571553461](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38571553461), `completed/success`. Official binary `4.7.2.stable.official.ed1daf0bf`, SHA512 `OK`, import success.
- Output: `M1_TEST_REPORT executed=30 passed=30 failed=0 skipped=0`; `M2_1_TEST_REPORT executed=38 passed=38 failed=0 skipped=0`; `M2_2_TEST_REPORT executed=43 passed=43 failed=0 skipped=0`.
- Seed `20261014`; cost fixture schema `m2.2-cost-fixture-v1` (BALANCE_PROVISIONAL); ruleset `arbitrium-phase3-m2.1-v1`; content `m2.1-placeholder-content-v1`.
- `M2_2_REPLAY_PROOF` initial SHA256: `4a2aa915c24d2e1490e91cbce68d0ea8fe5db46db0370959b3e57ce015db882f`.
- `M2_2_REPLAY_PROOF` events SHA256: `ca6b7064391bf43da53b7b916a5ec092344ced2da9ff54ae1955ceffbfb4d648`.
- `M2_2_REPLAY_PROOF` final SHA256: `251b01b42229d2f8beb4e10e3c964f19637bc0e1cfd0e06598545d7368e54bbe`.
- Deterministic command tape: two `PAY_SP_COST_ONLY` fixture transactions (CHANTLESS AP2/MP1, then FULL AP3/MP2). Public `PLAY_SP` is NOT implemented.
- G0 legacy smoke [Run #38571553541](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38571553541) and independent M1 [Run #38571553345](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38571553345) also show `success` for same tested commit.
- Status: **M2.2 INTERNAL COST DOMAIN VERIFIED**; **M2 overall NOT VERIFIED** pending M2.3–M2.5.

### Non-gameplay design constraints

- M-D04 multi-round debt is PROVISIONAL; `max_ap_debt=8` only candidate. Never present these as final balance.
- Multiple simultaneous eligible SetCost effects fail with `MULTIPLE_SET_COST_TBD`; this is a deliberate unresolved gameplay precedence, not an engine crash.
- Current implementation accepts a paid-source receipt for subsequent fixture effects; in M2.3/M3 attach these to actual card/effect definitions before allowing gameplay callers. This is a boundary, not proof of true card/effect ownership.
- The policy remains independent from UI frame/animation and the legacy `battle_state.gd`.
