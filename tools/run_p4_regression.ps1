param([string]$GodotBin, [string]$OutputDir = 'outputs/p4_logs/regression')
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $OutputDir | Out-Null
$suites = @('test_combat_m1','test_m2_resources','test_m2_costs','test_m2_cards','test_m2_free_swap','test_m2_invariants','test_m2_replay','test_m2_integration','test_m3_phase','test_m3_reaction_window','test_m3_guard_protect','test_m3_ui_modes','test_m3_integration','test_m3_replay','test_m4_dual_cast','test_m4_disruption','test_m4_last_spell','test_m4_incapacitation','test_m4_integration','test_m4_replay','test_m5_damage','test_m5_status','test_m5_boss_combo','test_m5_outcome','test_m5_integration','test_m5_replay','test_m5_100_seeds','test_battle_state','test_deck_builder','test_combat_ui','test_turn_flow')
foreach ($suite in $suites) {
    $log = Join-Path $OutputDir "$suite.log"
    & $GodotBin --headless --path . --script "res://tests/$suite.gd" 2>&1 | Tee-Object -FilePath $log | Out-Null
    $code = $LASTEXITCODE
    $raw = Get-Content -Raw $log
    if ($code -ne 0 -or $raw -match 'SCRIPT ERROR|^FAIL |failed=[1-9]') { throw "FAILED $suite exit=$code; see $log" }
    Write-Output "PASS $suite exit=$code"
}
Write-Output "P4_REGRESSION suites=$($suites.Count) failed=0"
