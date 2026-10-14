extends SceneTree

# G0.1 CI failure-signal probe. It MUST fail with exit code 17.
# This is not a gameplay test. Do not include it in the normal pass suite.
func _init() -> void:
	printerr("G0_PROBE_EXPECTED_FAILURE: intentional nonzero process exit (17)")
	quit(17)
