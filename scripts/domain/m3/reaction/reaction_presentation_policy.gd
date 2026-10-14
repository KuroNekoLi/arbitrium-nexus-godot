extends RefCounted
## M3.4 presentation-only policy (P1-D05, CORE-04).
## No timer, Node, UI input, mutations, or authority to Confirm/Pass.
## Reads the M3.2/M3.3 phase/window snapshot; never alters it.
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")

const SMART: String = "SMART"
const ALWAYS_ASK: String = "ALWAYS_ASK"
const QUICK: String = "QUICK"
const VALID_MODES: Array[String] = [SMART, ALWAYS_ASK, QUICK]
const EDIT_COMMANDS: Array[String] = ["QUEUE_REACTION", "REMOVE_REACTION", "REORDER_REACTIONS"]
const DECISION_COMMANDS: Array[String] = ["CONFIRM_REACTIONS", "PASS_REACTION"]

## significance is ONLY a presentation hint supplied by a future encounter
## presenter: MAJOR / MINOR / UNKNOWN. Threat thresholds are not approved;
## UNKNOWN uses the safe, prominent Smart prompt. Other hint fields such as
## time_elapsed, fps, input_device, countdown, auto_pass are ignored.
static func describe(state: Dictionary, mode: String = SMART,
		presentation_hints: Dictionary = {}) -> Dictionary:
	if not VALID_MODES.has(mode):
		return {"ok": false, "error": "UNKNOWN_REACTION_UI_MODE"}
	if not Phase.validate_state(state):
		return {"ok": false, "error": "INVALID_PHASE_STATE"}
	var window: Dictionary = state["reaction_window"]
	var enemy_phase: bool = str(state["phase"]) == "ENEMY_PHASE"
	var declared: bool = enemy_phase and not str(state["active_enemy_action_id"]).is_empty()
	var is_pending: bool = declared and not window.is_empty() and str(window["status"]) == "DRAFTING"
	var is_closed: bool = declared and not window.is_empty() and str(window["status"]) == "CLOSED"
	var empty_window: bool = is_closed and str(window.get("closure_reason", "")) == "NO_LEGAL_REACTION"
	var significance: String = str(presentation_hints.get("significance", "UNKNOWN"))
	if not ["MAJOR", "MINOR"].has(significance):
		significance = "UNKNOWN"
	# UI prominence is not authorization to execute. For low-threat Smart
	# actions, the persistent quieter affordance STILL blocks Domain advance.
	var modal_prompt: bool = is_pending and (mode == ALWAYS_ASK
		or (mode == SMART and significance != "MINOR"))
	var interaction_style: String = "SMART_CONTEXTUAL"
	if mode == ALWAYS_ASK:
		interaction_style = "FULL_PROMPT"
	elif mode == QUICK:
		interaction_style = "COMPACT_PROMPT"
	var presentation_key: String = "reaction.mode.smart"
	if mode == ALWAYS_ASK:
		presentation_key = "reaction.mode.always_ask"
	elif mode == QUICK:
		presentation_key = "reaction.mode.quick"
	var window_id: String = ""
	if not window.is_empty():
		window_id = str(window.get("window_id", ""))
	return {"ok": true, "error": "",
		"mode": mode,
		"window_id": window_id,
		"enemy_action_id": str(state["active_enemy_action_id"]),
		"interaction_style": interaction_style,
		"presentation_i18n_key": presentation_key,
		"prompt_visible": is_pending,
		"should_block_prompt": modal_prompt,
		"show_persistent_affordance": is_pending,
		"has_legal_reaction_window": is_pending,
		"reaction_pending": is_pending,
		"requires_explicit_player_decision": is_pending,
		"blocks_enemy_resolution": is_pending,
		"may_complete_enemy_action": is_closed,
		"empty_window_skipped": empty_window,
		"decision_commands": DECISION_COMMANDS.duplicate() if is_pending else [],
		"edit_commands": EDIT_COMMANDS.duplicate() if is_pending else [],
		"auto_pass": false, "auto_confirm": false,
		"auto_spend_rp": false,
		"deadline_seconds": null,
		"timeout_seconds": null,
		"waiting_policy": "UNTIL_EXPLICIT_CONFIRM_OR_PASS" if is_pending else "NO_WAIT",
		"core_resources_changed": false,
		"change_reason": "PRESENTATION_ONLY"}
