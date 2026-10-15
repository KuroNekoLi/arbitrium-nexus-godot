# V2 branch-scoped CI execution

The existing P4 HUD reviewed headless workflow is extended **only on the V2 branch** to trigger for this branch and assert `V2_LAYOUT_REPORT executed=18 passed=18 failed=0` via the new layout runner. Existing assertions and tests are unchanged. GUI third attempt 14/16 remains unrerun. This does not promote V2 into master or assert screenshot/visual parity.
