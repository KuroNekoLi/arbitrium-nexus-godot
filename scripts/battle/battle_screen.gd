@tool
extends Control
## Reversible scene-specific profile; Lv40 stays fail-closed until merged contracts.
@export_enum("fixture", "lv40", "lv40_playable") var encounter_profile: String = "fixture"
const Encounter = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Lv40Encounter = preload("res://scripts/domain/m5/lv40/lv40_encounter.gd")
const Adapter = preload("res://scripts/battle/presentation/battle_presentation_adapter.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
const Cost = preload("res://scripts/domain/m2/economy/cost_resolver.gd")
const Translations = preload("res://scripts/battle/presentation/battle_translations.gd")
const Controller = preload("res://scripts/battle/battle_controller.gd")
const Director = preload("res://scripts/battle/presentation/battle_animation_director.gd")
const Effects = preload("res://scripts/battle/presentation/battle_effects.gd")
const Bindings = preload("res://scripts/battle/ui/battle_input_bindings.gd")
const LogFormatter = preload("res://scripts/battle/presentation/battle_log_formatter.gd")
const LastView = preload("res://scripts/battle/presentation/last_spell_read_model.gd")
const Appearances = preload("res://scripts/battle/presentation/character_appearance_registry.gd")
const EditorPreview = preload("res://scripts/battle/presentation/battle_editor_preview_data.gd")
@export_enum("Battle", "Last Spell Ren", "Last Spell Akane", "Last Spell Tsumugi") var editor_preview_mode: String = "Battle":
	set(value):
		editor_preview_mode = value
		if Engine.is_editor_hint() and is_node_ready():
			EditorPreview.show(hud,editor_preview_mode)
const LOG_EVENT_LIMIT: int = 64
var log_events: Array = []
var controller: Node
var director: Node
signal action_requested(command: Dictionary)
var snapshot: Dictionary = {}
var config: Dictionary = {}
var selected_actor: String = "A"
var pending_card: String = ""
var pending_kind: String = ""
var selected_target: String = ""
var remembered_attack_target: String = ""
var remembered_last_ally_target: String = ""
var _hand_before_last: bool = true
var legal_targets: Array = []
var pending_command: Dictionary = {}
var keyboard_index: int = 0
var view_model: Dictionary = {}
var _last_actor_visibility: Dictionary = {}
@onready var design: Control = $Design
@onready var hud: Control = $Design/HUD

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		# Never register gameplay input or reset the editor locale.
		return
	Bindings.install()
	Translations.install()
	TranslationServer.set_locale("zh_TW")

func _ready() -> void:
	if Engine.is_editor_hint():
		# The actual battle scene/actors/HUD render from editor-safe mock data.
		# No Controller, M5 initial state, signals, combat tweens or tape.
		resized.connect(_fit_design)
		_fit_design()
		EditorPreview.show(hud,editor_preview_mode)
		return
	# The inherited Lv40 scene must never silently start a legacy fixture.
	# Formal activation requires a reviewed Domain+ReadModel+Localization merge.
	if encounter_profile == "lv40":
		set_process_input(false)
		set_process_unhandled_input(false)
		resized.connect(_fit_design)
		_fit_design()
		hud.feedback.text = tr("BATTLE_NOT_IMPLEMENTED")
		hud.end_button.disabled = true
		push_warning("BLOCKED_CONTRACT: Lv40 playable BattleScreen/Controller wiring remains staging-only")
		return
	config = Lv40Encounter.config() if encounter_profile == "lv40_playable" else Encounter.config()
	hud.actor_requested.connect(select_actor)
	hud.card_requested.connect(select_card)
	hud.card_released.connect(_drop_card)
	hud.command_requested.connect(_command_requested)
	hud.target_requested.connect(select_target)
	hud.confirm_requested.connect(confirm_action)
	hud.cancel_requested.connect(cancel_action)
	hud.locale_requested.connect(set_locale)
	present(_initial_state())
	resized.connect(_fit_design)
	_fit_design()
	controller = Controller.new()
	add_child(controller)
	controller.begin(_initial_state(),config)
	controller.resolved.connect(_on_resolved)
	controller.rejected.connect(func(error: String) -> void: hud.feedback.text = _reason(error))
	director = Director.new()
	director.arena = $Design/Arena
	var effects: Control = Effects.new()
	effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects.theme = hud.theme
	design.add_child(effects)
	director.overlay = effects
	add_child(director)
	director.cue_presented.connect(_on_cue)
	action_requested.connect(_submit)

func _initial_state() -> Dictionary:
	return Lv40Encounter.initial() if encounter_profile == "lv40_playable" else Encounter.initial()

func _on_cue(cue: Dictionary) -> void:
	if cue["kind"] != "DAMAGE": hud.feedback.text = tr("BATTLE_CUE_"+str(cue["kind"]))

func _submit(command: Dictionary) -> void:
	if command["type"] == "SAVE_REPLAY":
		var error: Error = controller.save_tape("user://p4_battle.tape")
		hud.feedback.text = tr("BATTLE_SAVED" if error == OK else "BATTLE_SAVE_FAILED")
		return
	controller.submit(command)

func _on_resolved(state: Dictionary, events: Array, command: Dictionary) -> void:
	for card: Control in hud.card_views:
		if card.instance_id == command.get("card_instance_id",""):
			var origin: Vector2 = design.get_global_transform().affine_inverse()*card.global_position
			var target: Node2D = $Design/Arena.get_node(str(command.get("target_actor_id","Boss")))
			director.play_card(card.appearance.artwork,origin,target.position+Vector2(0,-100))
			break
	cancel_action()
	present(state)
	# V3.5.4: log rows are derived only from real DomainEvents (raw events are
	# kept so a locale rebuild re-translates instead of replaying stale text).
	log_events.append_array(events.duplicate(true))
	hud.get_node("BattleLogPanel").append_rows(_log_rows(events))
	director.enqueue(events,command)

## Same name fallbacks as the visible panels: EnemyStatus titles the Boss with
## BATTLE_TITLE and the party roster uses BATTLE_HERO_<id>.
func log_actor_name(id: String) -> String:
	var fallback: String = "BATTLE_TITLE" if id == "Boss" else "BATTLE_HERO_" + id if id in ["A", "B", "C"] else id
	return tr(str(view_model.get("actor_name_keys", {}).get(id, fallback)))

func _log_rows(events: Array) -> Array:
	return LogFormatter.rows_for(events,
		func(key: String) -> String: return tr(key),
		log_actor_name,
		func(skill_id: String) -> String: return tr(str(config.get("intent_name_keys", {}).get(
			skill_id, "BATTLE_" + skill_id.to_upper()))))

func present(state: Dictionary) -> void:
	snapshot = state.duplicate(true)
	view_model = Adapter.project(snapshot,config)
	for actor: Node2D in $Design/Arena.get_children():
		var casting: bool = false
		for cast: Dictionary in view_model["casts"].values():
			if cast["caster_id"] == actor.actor_id: casting = true
		actor.project_conditions(str(view_model["actors"][actor.actor_id]["status"]),casting,float(view_model["barriers"].get(actor.actor_id,0)) > 0)
	var cards: Array = []
	var own: Dictionary = snapshot["core"]["cards"]["actors"][selected_actor]
	for instance: String in own["zones"]["hand"]:
		var definition: String = str(own["instances"][instance]["definition_id"])
		var appearance: Resource = load("res://resources/ui/appearances/"+definition+".tres")
		var targets: Array = _targets_for_card(instance)
		var price: Dictionary = Cost.quote(snapshot["core"]["battle"],{
			"actor_id":selected_actor,"card":config["definitions"][definition],"casting_mode":"CHANTLESS"},config["costs"])
		var legal: bool = not targets.is_empty()
		var cost_text: String = tr("BATTLE_COST") % [price.get("ap_cost",config["definitions"][definition]["ap_cost"]),price.get("mp_cost",config["definitions"][definition]["mp_cost"])]
		cards.append({"instance_id":instance,"appearance":appearance,"cost":cost_text,
			"can_full_chant": definition == "regular" or config.get("lv40_cards", {}).get(definition, {}).get("mode", "") == "DUAL",
			"legal":legal,"reason":_reason(str(price.get("error",""))) if not legal else ""})
	hud.render(view_model,selected_actor,cards,_reaction_choices())
	hud.confirm_button.disabled = true
	hud.set_targets([])
	if view_model["outcome"] != "ONGOING": hud.feedback.text = tr("BATTLE_"+str(view_model["outcome"]))

func _targets_for_card(instance: String, casting_mode: String = "CHANTLESS") -> Array:
	var choices: Array = []
	for target: String in snapshot["core"]["battle"]["actors"]:
		var command: Dictionary = Factory.card(snapshot,selected_actor,instance,target,casting_mode,false,config)
		if Factory.preview(snapshot,command,config)["accepted"]: choices.append(target)
	return choices

func _reaction_choices() -> Array:
	var options: Array = []
	var window: Dictionary = snapshot["reaction_window"]
	if window.get("status","") != "DRAFTING": return options
	for actor: String in ["A","B","C"]:
		for kind: String in ["BASIC_GUARD","BASIC_PROTECT"]:
			var target: String = actor if kind == "BASIC_GUARD" else str(snapshot["published_intents"][0]["target_ids"][0])
			var entry: Dictionary = {"kind":kind,"actor_id":actor,"target_actor_id":target}
			var command: Dictionary = Factory.build(snapshot,"QUEUE_REACTION",{"window_id":window["window_id"],"entry":entry})
			if Factory.preview(snapshot,command,config)["accepted"]:
				options.append({"entry":entry,"label":"BATTLE_GUARD" if kind == "BASIC_GUARD" else "BATTLE_PROTECT"})
		var own: Dictionary = snapshot["core"]["cards"]["actors"][actor]
		for instance: String in own["zones"]["hand"]:
			var definition: String = str(own["instances"][instance]["definition_id"])
			if not config["reaction_definitions"].has(definition): continue
			for target: String in snapshot["core"]["battle"]["allies"]:
				var entry: Dictionary = {"kind":"REACTION_SP_FIXTURE","actor_id":actor,"target_actor_id":target,"card_instance_id":instance}
				var command: Dictionary = Factory.build(snapshot,"QUEUE_REACTION",{"window_id":window["window_id"],"entry":entry})
				if Factory.preview(snapshot,command,config)["accepted"]:
					var effect: String = str(config["reaction_definitions"][definition]["fixture_effect"])
					var definition_data: Dictionary = config["reaction_definitions"][definition]
					options.append({"entry":entry,"label":"BATTLE_CUE_INTERRUPT" if effect == "CANCEL_ACTION_FIXTURE" else "BATTLE_REACTION_FOCUS_WARD" if effect == "FOCUS_WARD_FIXTURE" else "BATTLE_SPECIAL_REACTION",
						"tooltip":tr("BATTLE_REACTION_COST") % [definition_data["rp_cost"],definition_data["mp_cost"]]})
	return options

func select_actor(actor: String) -> void:
	if not snapshot["core"]["battle"]["allies"].has(actor): return
	selected_actor = actor
	cancel_action()
	present(snapshot)

func select_card(instance: String, inspect_details: bool = true) -> void:
	var own: Dictionary = snapshot["core"]["cards"]["actors"][selected_actor]
	if not own["zones"]["hand"].has(instance): return
	hud.clear_command_confirmation()
	hud.get_node("Context").visible = inspect_details
	pending_card = instance
	hud.set_selected_card(instance)
	pending_kind = "CARD"
	selected_target = ""
	legal_targets = _targets_for_card(instance)
	var definition: String = str(own["instances"][instance]["definition_id"])
	var appearance: Resource = load("res://resources/ui/appearances/"+definition+".tres")
	hud.details.text = tr(appearance.description_key)
	hud.mode.visible = definition == "regular" or config.get("lv40_cards",{}).get(definition,{}).get("mode","") == "DUAL"
	hud.mode.select(0)
	hud.combo.visible = (definition in ["finish","A06","T04"]) and not view_model["tactical"].get("combo",{}).is_empty()
	hud.combo.set_pressed_no_signal(false)
	hud.feedback.text = tr("BATTLE_TARGET") if not legal_targets.is_empty() else _reason("ACTOR_UNAVAILABLE" if view_model["actors"][selected_actor]["status"] != "ACTIVE" else "INSUFFICIENT_RESOURCES")
	hud.set_targets(legal_targets)
	hud.confirm_button.disabled = true
	_update_action_summary()

func _update_action_summary() -> void:
	var context: Control = hud.get_node("Context")
	var target: String = log_actor_name(selected_target) if not selected_target.is_empty() else tr("BATTLE_TARGET")
	if pending_kind == "CARD":
		var own: Dictionary = snapshot["core"]["cards"]["actors"][selected_actor]
		var definition: String = str(own["instances"][pending_card]["definition_id"])
		var appearance: Resource = load("res://resources/ui/appearances/" + definition + ".tres")
		var quote: Dictionary = Cost.quote(snapshot["core"]["battle"], {
			"actor_id": selected_actor, "card": config["definitions"][definition],
			"casting_mode": "FULL" if hud.mode.selected == 1 else "CHANTLESS"}, config["costs"])
		# Unavailable quotes have no trustworthy payable cost; omit rather than infer.
		var cost: String = tr("BATTLE_COST") % [quote["ap_cost"], quote["mp_cost"]] if quote.get("ok", false) else ""
		context.render_summary(tr(appearance.name_key), appearance.artwork, cost, target)
	elif pending_kind in ["BASIC_ATTACK_RESOURCE_ONLY", "ACTIVATE_LAST_SPELL_M4", "FREE_SWAP"]:
		var key: String = "BATTLE_BASIC" if pending_kind == "BASIC_ATTACK_RESOURCE_ONLY" else "BATTLE_LAST" if pending_kind == "ACTIVATE_LAST_SPELL_M4" else "BATTLE_SWAP"
		var cost: String = ""
		if pending_kind == "BASIC_ATTACK_RESOURCE_ONLY" and config.get("resources", {}).has("basic_attack_ap_cost"):
			cost = "%d AP" % int(config["resources"]["basic_attack_ap_cost"])
		elif pending_kind == "ACTIVATE_LAST_SPELL_M4":
			var inspected: Dictionary = preload("res://scripts/domain/m4/last_spell/last_spell_resolver.gd").inspect(snapshot["core"], selected_actor, config)
			if inspected.get("ok", false):
				cost = tr("BATTLE_COST") % [inspected["quote"]["ap_cost"], inspected["quote"]["mp_cost"]]
		context.render_summary(tr(key), preload("res://scripts/battle/ui/components/battle_command_visual.gd").icon_for(key), cost, target)

func select_target(target: String) -> void:
	if not legal_targets.has(target):
		hud.feedback.text = _reason("INVALID_TARGET")
		return
	if pending_kind == "BASIC_ATTACK_RESOURCE_ONLY":
		if selected_target == target:
			_refresh_preview()
			confirm_action()
			return
		selected_target = target
		remembered_attack_target = target
		_refresh_preview()
		return
	selected_target = target
	if pending_kind == "ACTIVATE_LAST_SPELL_M4":
		if hud.last_preview.targeting.get("team", "") == "ALLY":
			remembered_last_ally_target = target
		else:
			remembered_attack_target = target
	_refresh_preview()

func _refresh_preview() -> void:
	if pending_kind == "CARD":
		pending_command = Factory.card(snapshot,selected_actor,pending_card,selected_target,
			"FULL" if hud.mode.selected == 1 else "CHANTLESS",hud.combo.button_pressed,config)
	else:
		var fields: Dictionary = {"actor_id":selected_actor,"target_actor_id":selected_target}
		if pending_kind == "FREE_SWAP": fields["card_instance_id"] = pending_card
		if pending_kind == "ACTIVATE_LAST_SPELL_M4":
			fields["casting_mode"] = "FULL"
			fields["confirmed"] = true
		pending_command = Factory.build(snapshot,pending_kind,fields)
	var result: Dictionary = Factory.preview(snapshot,pending_command,config)
	_update_action_summary()
	hud.confirm_button.disabled = not result["accepted"]
	hud.feedback.text = tr("BATTLE_CONFIRM_HINT") if result["accepted"] else _reason(str(result["error"]))
	if pending_kind == "ACTIVATE_LAST_SPELL_M4" and hud.last_preview.visible:
		# Keep the public targeting/confirm facade for non-GUI clients, while the
		# player sees only the dedicated cut-in's activation/cancel controls.
		hud.last_preview.select_target(selected_target, false)
		hud.last_preview.error_label.text = "" if result["accepted"] else _reason(str(result["error"]))
	elif pending_kind == "BASIC_ATTACK_RESOURCE_ONLY":
		hud.set_basic_target_choices(legal_targets, selected_target, _basic_target_labels())
		hud.feedback.text = tr("BATTLE_BASIC_SELECTED") % log_actor_name(selected_target) if result["accepted"] else _reason(str(result["error"]))
	elif pending_kind != "CARD":
		var key: String = "BATTLE_BASIC" if pending_kind == "BASIC_ATTACK_RESOURCE_ONLY" else "BATTLE_LAST" if pending_kind == "ACTIVATE_LAST_SPELL_M4" else "BATTLE_SWAP"
		hud.show_command_confirmation(tr(key), hud.details.text)
	if result["accepted"] and hud.confirm_button.is_visible_in_tree(): hud.confirm_button.grab_focus()

func confirm_action() -> void:
	if pending_command.is_empty() or hud.confirm_button.disabled: return
	# Snapshot revision is retained until reducer acceptance. No UI payment.
	action_requested.emit(pending_command.duplicate(true))

func cancel_action() -> void:
	pending_card = ""
	pending_kind = ""
	selected_target = ""
	pending_command = {}
	legal_targets = []
	if not is_node_ready(): return
	if hud.last_preview.visible:
		hud.hand.visible = _hand_before_last
		hud.feedback.show()
	hud.last_preview.hide()
	for actor: String in _last_actor_visibility:
		$Design/Arena.get_node(actor).visible = _last_actor_visibility[actor]
	_last_actor_visibility.clear()
	hud.set_targets([])
	hud.set_basic_target_choices([], "", {})
	hud.set_selected_card("")
	hud.details.text = tr("BATTLE_SELECT")
	hud.get_node("Context").clear_summary()
	hud.get_node("Context").hide()
	hud.clear_command_confirmation()
	hud.mode.hide()
	hud.combo.hide()
	hud.confirm_button.disabled = true
	hud.feedback.text = ""

func _drop_card(instance: String, pointer: Vector2) -> void:
	if hud.reaction_panel.visible or hud.result_panel.visible or hud.command_prompt.visible or hud.last_preview.visible:
		return
	var full: bool = false
	for card: Control in hud.card_views:
		if card.instance_id == instance:
			full = card.can_full_chant and card.full_chant_held
			break
	select_card(instance, false)
	if pending_card != instance:
		return
	if full and hud.mode.visible:
		hud.mode.select(1)
		legal_targets = _targets_for_card(instance, "FULL")
		hud.set_targets(legal_targets)
	for target: String in legal_targets:
		if hud.target_buttons[target].get_global_rect().has_point(pointer):
			select_target(target)
			confirm_action()
			hud.mode.select(0)
			return
	hud.mode.select(0)
	legal_targets = _targets_for_card(instance)
	hud.set_targets(legal_targets)
	_update_action_summary()
	hud.feedback.text = tr("BATTLE_INVALID_DROP")

func _open_last_preview() -> void:
	if hud.reaction_panel.visible or hud.result_panel.visible:
		return
	cancel_action()
	var presentation: Dictionary = LastView.project(snapshot, selected_actor, config)
	var inspected: Dictionary = presentation["inspection"]
	var targets: Array = presentation["targets"]
	legal_targets = []
	for target: Dictionary in targets:
		var id: String = str(target["id"])
		target["name"] = log_actor_name(id)
		target["portrait"] = _last_target_portrait(id)
		if hud.target_buttons.has(id):
			target["rect"] = Rect2(hud.target_buttons[id].position, hud.target_buttons[id].size)
		if target["legal"]: legal_targets.append(id)
	var team: String = str(presentation["targeting"].get("team", "UNKNOWN"))
	var remembered: String = remembered_last_ally_target if team == "ALLY" else remembered_attack_target
	selected_target = remembered if legal_targets.has(remembered) else selected_actor if team == "ALLY" and legal_targets.has(selected_actor) else str(legal_targets[0]) if not legal_targets.is_empty() else ""
	presentation["selected_id"] = selected_target
	var appearance_id: String = str(presentation["targeting"].get("appearance_id", ""))
	if not appearance_id.is_empty():
		presentation["appearance"] = load("res://resources/ui/appearances/" + appearance_id + ".tres")
	var artwork_path: String = str(presentation["targeting"].get("artwork_path", ""))
	if not artwork_path.is_empty(): presentation["spell_art"] = load(artwork_path)
	presentation["actor_id"] = selected_actor
	var texture: Texture2D = Appearances.cg_for(selected_actor)
	if texture == null: texture = hud.roster[selected_actor].portrait.texture
	var character: String = str(Lv40Encounter.CHARACTERS.get(selected_actor, "")) if config.get("m5_lv40_enabled", false) else ""
	var title: String = tr("last_spell." + character + ".name") if not character.is_empty() else tr("BATTLE_LAST")
	_hand_before_last = hud.hand.visible
	hud.hand.hide()
	hud.last_preview.present(title, inspected, texture, targets, _reason(str(inspected.get("error", ""))), presentation)
	pending_kind = "ACTIVATE_LAST_SPELL_M4"
	if not selected_target.is_empty(): _refresh_preview()
	hud.feedback.hide()
	hud._sync_modal_focus()

func _last_target_portrait(id: String) -> Texture2D:
	var candidate: Texture2D = Appearances.portrait_for(id)
	if candidate != null: return candidate
	if hud.roster.has(id): return hud.roster[id].portrait.texture
	var visual: Node2D = $Design/Arena.get_node_or_null(id)
	if visual != null: return visual.body.sprite_frames.get_frame_texture("idle", 0)
	return preload("res://assets/ui/v35/intent_skill.svg")

func _command_requested(kind: String, fields: Dictionary) -> void:
	if kind == "ACTIVATE_LAST_PREVIEW":
		var command: Dictionary = Factory.build(snapshot, "ACTIVATE_LAST_SPELL_M4", {
			"actor_id": selected_actor, "target_actor_id": str(fields.get("target_id", "")),
			"confirmed": true, "casting_mode": "FULL"})
		var preview: Dictionary = Factory.preview(snapshot, command, config)
		if preview["accepted"]:
			action_requested.emit(command)
		else:
			hud.last_preview.error_label.text = _reason(str(preview["error"]))
		return
	if kind == "ACTIVATE_LAST_SPELL_M4":
		_open_last_preview()
		return
	if kind == "HOLD_CHANT":
		if hud.reaction_panel.visible or hud.result_panel.visible:
			return
		var instance: String = str(fields.get("instance_id", ""))
		if fields.get("full", false):
			select_card(instance, false)
			if pending_card == instance and hud.mode.visible:
				hud.mode.select(1)
				legal_targets = _targets_for_card(instance, "FULL")
				hud.set_targets(legal_targets)
				_update_action_summary()
		elif pending_card == instance:
			hud.mode.select(0)
			legal_targets = _targets_for_card(instance)
			hud.set_targets(legal_targets)
			_update_action_summary()
		return
	if kind == "SKIP_ANIMATION":
		director.skip_all()
		return
	if kind == "REDUCED_MOTION":
		director.reduced_motion = bool(fields["enabled"])
		director.overlay.reduced_motion = director.reduced_motion
		if director.reduced_motion: director.skip_all()
		return
	if kind == "MUTE_AUDIO":
		director.overlay.audio_enabled = not bool(fields["enabled"])
		return
	if kind == "RESTART_BATTLE":
		director.reset_session()
		log_events.clear()
		hud.get_node("BattleLogPanel").clear_rows()
		controller.begin(_initial_state(),config)
		remembered_attack_target = ""
		cancel_action()
		present(controller.snapshot())
		return
	if kind == "UNIMPLEMENTED":
		hud.feedback.text = tr("BATTLE_NOT_IMPLEMENTED")
		return
	if kind == "REFRESH_PREVIEW":
		if pending_kind == "CARD":
			legal_targets = _targets_for_card(pending_card,"FULL" if hud.mode.selected == 1 else "CHANTLESS")
			hud.set_targets(legal_targets)
		if selected_target != "": _refresh_preview()
		else: _update_action_summary()
		return
	if kind == "FREE_SWAP":
		if pending_card.is_empty():
			hud.feedback.text = tr("BATTLE_SELECT")
			return
		pending_kind = kind
		selected_target = selected_actor
		_refresh_preview()
		return
	if kind == "BASIC_ATTACK_RESOURCE_ONLY":
		cancel_action()
		pending_kind = kind
		for target: String in snapshot["core"]["battle"]["enemies"]:
			var command: Dictionary = Factory.build(snapshot, kind,
				{"actor_id":selected_actor,"target_actor_id":target})
			if Factory.preview(snapshot,command,config)["accepted"]:
				legal_targets.append(target)
		if legal_targets.is_empty():
			cancel_action()
			hud.feedback.text = _reason("ACTOR_UNAVAILABLE" if view_model["actors"][selected_actor]["status"] != "ACTIVE" else "INSUFFICIENT_RESOURCES")
			return
		hud.set_targets(legal_targets)
		selected_target = remembered_attack_target if legal_targets.has(remembered_attack_target) else legal_targets[0]
		remembered_attack_target = selected_target
		_refresh_preview()
		if legal_targets.size() == 1:
			confirm_action()
		return
	var args: Dictionary = fields.duplicate(true)
	if kind in ["QUEUE_REACTION","REMOVE_REACTION","REORDER_REACTIONS","CONFIRM_REACTIONS","PASS_REACTION"]:
		args["window_id"] = snapshot["reaction_window"].get("window_id","")
	action_requested.emit(Factory.build(snapshot,kind,args))

func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
	cancel_action()
	# Recreate labels through the same HUD component, without touching Domain.
	var parent: Node = hud.get_parent()
	parent.remove_child(hud)
	hud.queue_free()
	hud = preload("res://scripts/battle/ui/battle_hud.gd").new()
	hud.name = "HUD"
	hud.size = Vector2(1280,720)
	parent.add_child(hud)
	_connect_hud()
	present(snapshot)
	if not log_events.is_empty():
		hud.get_node("BattleLogPanel").append_rows(_log_rows(log_events))
	hud.reduced_toggle.set_pressed_no_signal(director.reduced_motion)
	hud.mute_toggle.set_pressed_no_signal(not director.overlay.audio_enabled)

func _connect_hud() -> void:
	hud.actor_requested.connect(select_actor)
	hud.card_requested.connect(select_card)
	hud.card_released.connect(_drop_card)
	hud.command_requested.connect(_command_requested)
	hud.target_requested.connect(select_target)
	hud.confirm_requested.connect(confirm_action)
	hud.cancel_requested.connect(cancel_action)
	hud.locale_requested.connect(set_locale)

func _reason(code: String) -> String:
	if "INSUFFICIENT" in code: return tr("BATTLE_ERROR_RESOURCE")
	if "ACTOR" in code or "CONCENTRAT" in code: return tr("BATTLE_ERROR_ACTOR")
	if "TARGET" in code: return tr("BATTLE_ERROR_TARGET")
	if "STALE" in code: return tr("BATTLE_ERROR_STALE")
	return tr("BATTLE_ERROR_GENERIC")

func _basic_target_labels() -> Dictionary:
	var labels: Dictionary = {}
	for target: String in legal_targets:
		labels[target] = log_actor_name(target)
	return labels

func _input(event: InputEvent) -> void:
	if snapshot.is_empty(): return
	if not event is InputEventKey or not event.pressed or event.echo: return
	# Modal buttons own Enter/Space/Tab; never turn a key into implicit Pass.
	if hud.reaction_panel.visible or hud.result_panel.visible or hud.command_prompt.visible or hud.last_preview.visible: return
	if event.is_action_pressed("end_turn"):
		_command_requested("END_PLAYER_PHASE",{})
		get_viewport().set_input_as_handled()
		return
	var party_index: int = -1
	for i: int in 3:
		if event.is_action_pressed("battle_party_"+str(i+1)): party_index = i
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused is Button and not focused is Card and event.is_action_pressed("ui_accept"): return
	if party_index >= 0:
		select_actor(["A","B","C"][party_index])
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		if hud.card_views.is_empty(): return
		keyboard_index = wrapi(keyboard_index + (1 if event.is_action_pressed("ui_right") else -1),0,hud.card_views.size())
		select_card(hud.card_views[keyboard_index].instance_id)
		hud.card_views[keyboard_index].grab_focus()
	elif event.is_action_pressed("end_turn"): _command_requested("END_PLAYER_PHASE",{})
	elif event.is_action_pressed("ui_accept"):
		if pending_kind.is_empty() and not hud.card_views.is_empty(): select_card(hud.card_views[0].instance_id)
		elif selected_target.is_empty() and not legal_targets.is_empty(): select_target(legal_targets[0])
		else: confirm_action()
	elif event.is_action_pressed("ui_cancel"): cancel_action()
	else: return
	get_viewport().set_input_as_handled()

func _fit_design() -> void:
	var factor: float = minf(size.x / 1280.0, size.y / 720.0)
	design.scale = Vector2.ONE * factor
	design.position = (size - Vector2(1280, 720) * factor) * 0.5
