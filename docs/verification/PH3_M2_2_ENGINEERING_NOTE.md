# Phase 3 M2.2 — Cost Engine and Overload

Status: IMPLEMENTED_NOT_VERIFIED until actual GitHub Actions runs pass.

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
