extends Control
const Encounter = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Adapter = preload("res://scripts/battle/presentation/battle_presentation_adapter.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
const Cost = preload("res://scripts/domain/m2/economy/cost_resolver.gd")
const Translations = preload("res://scripts/battle/presentation/battle_translations.gd")
const Controller = preload("res://scripts/battle/battle_controller.gd")
const Director = preload("res://scripts/battle/presentation/battle_animation_director.gd")
const Effects = preload("res://scripts/battle/presentation/battle_effects.gd")
const Bindings = preload("res://scripts/battle/ui/battle_input_bindings.gd")
var controller: Node
var director: Node
signal action_requested(command: Dictionary)
var snapshot: Dictionary = {}
var config: Dictionary = {}
var selected_actor: String = "A"
var pending_card: String = ""
var pending_kind: String = ""
var selected_target: String = ""
var legal_targets: Array = []
var pending_command: Dictionary = {}
var keyboard_index: int = 0
var view_model: Dictionary = {}
@onready var design: Control = $Design
@onready var hud: Control = $Design/HUD

func _enter_tree() -> void:
	Bindings.install()
	Translations.install()
	TranslationServer.set_locale("zh_TW")

func _ready() -> void:
	config = Encounter.config()
	hud.actor_requested.connect(select_actor)
	hud.card_requested.connect(select_card)
	hud.card_released.connect(_drop_card)
	hud.command_requested.connect(_command_requested)
	hud.target_requested.connect(select_target)
	hud.confirm_requested.connect(confirm_action)
	hud.cancel_requested.connect(cancel_action)
	hud.locale_requested.connect(set_locale)
	present(Encounter.initial())
	resized.connect(_fit_design)
	_fit_design()
	controller = Controller.new()
	add_child(controller)
	controller.begin(Encounter.initial(),config)
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
	var records: PackedStringArray = []
	for event: Dictionary in events:
		var key: String = "BATTLE_EVENT_GENERIC"
		if event["kind"] == "HPDamageApplied": key = "BATTLE_EVENT_DAMAGE"
		elif event["kind"] == "PlayerActionSettled": key = "BATTLE_EVENT_ACTION"
		records.append(tr("BATTLE_LOG_EVENT") % [event["event_seq"],tr(key)])
	hud.log_label.text = "\n".join(records.slice(maxi(0,records.size()-3)))
	director.enqueue(events,command)

func present(state: Dictionary) -> void:
	snapshot = state.duplicate(true)
	view_model = Adapter.project(snapshot)
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
			"legal":legal,"reason":_reason(str(price.get("error",""))) if not legal else ""})
	hud.render(view_model,selected_actor,cards,_reaction_choices())
	hud.confirm_button.disabled = true
	hud.set_targets([])
	if view_model["outcome"] != "ONGOING": hud.feedback.text = tr("BATTLE_"+str(view_model["outcome"]))

func _targets_for_card(instance: String) -> Array:
	var choices: Array = []
	for target: String in snapshot["core"]["battle"]["actors"]:
		var command: Dictionary = Factory.card(snapshot,selected_actor,instance,target)
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

func select_card(instance: String) -> void:
	var own: Dictionary = snapshot["core"]["cards"]["actors"][selected_actor]
	if not own["zones"]["hand"].has(instance): return
	pending_card = instance
	pending_kind = "CARD"
	selected_target = ""
	legal_targets = _targets_for_card(instance)
	var definition: String = str(own["instances"][instance]["definition_id"])
	var appearance: Resource = load("res://resources/ui/appearances/"+definition+".tres")
	hud.details.text = tr(appearance.name_key)+"\n"+tr(appearance.description_key)
	hud.mode.visible = definition == "regular"
	hud.mode.select(0)
	hud.combo.visible = definition == "finish" and not view_model["tactical"].get("combo",{}).is_empty()
	hud.combo.set_pressed_no_signal(false)
	hud.feedback.text = tr("BATTLE_TARGET") if not legal_targets.is_empty() else _reason("ACTOR_UNAVAILABLE" if view_model["actors"][selected_actor]["status"] != "ACTIVE" else "INSUFFICIENT_RESOURCES")
	hud.set_targets(legal_targets)
	hud.confirm_button.disabled = true

func select_target(target: String) -> void:
	if not legal_targets.has(target):
		hud.feedback.text = _reason("INVALID_TARGET")
		return
	selected_target = target
	_refresh_preview()

func _refresh_preview() -> void:
	if pending_kind == "CARD":
		pending_command = Factory.card(snapshot,selected_actor,pending_card,selected_target,
			"FULL" if hud.mode.selected == 1 else "CHANTLESS",hud.combo.button_pressed)
	else:
		var fields: Dictionary = {"actor_id":selected_actor,"target_actor_id":selected_target}
		if pending_kind == "FREE_SWAP": fields["card_instance_id"] = pending_card
		if pending_kind == "ACTIVATE_LAST_SPELL_M4":
			fields["casting_mode"] = "FULL"
			fields["confirmed"] = true
		pending_command = Factory.build(snapshot,pending_kind,fields)
	var result: Dictionary = Factory.preview(snapshot,pending_command,config)
	hud.confirm_button.disabled = not result["accepted"]
	hud.feedback.text = tr("BATTLE_CONFIRM_HINT") if result["accepted"] else _reason(str(result["error"]))
	if result["accepted"]: hud.confirm_button.grab_focus()

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
	hud.set_targets([])
	hud.details.text = tr("BATTLE_SELECT")
	hud.mode.hide()
	hud.combo.hide()
	hud.confirm_button.disabled = true
	hud.feedback.text = ""

func _drop_card(instance: String, pointer: Vector2) -> void:
	select_card(instance)
	for target: String in legal_targets:
		if hud.target_buttons[target].get_global_rect().has_point(pointer):
			select_target(target)
			return
	hud.feedback.text = tr("BATTLE_INVALID_DROP")

func _command_requested(kind: String, fields: Dictionary) -> void:
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
		controller.begin(Encounter.initial(),config)
		cancel_action()
		present(controller.snapshot())
		return
	if kind == "UNIMPLEMENTED":
		hud.feedback.text = tr("BATTLE_NOT_IMPLEMENTED")
		return
	if kind == "REFRESH_PREVIEW":
		if selected_target != "": _refresh_preview()
		return
	if kind == "FREE_SWAP":
		if pending_card.is_empty():
			hud.feedback.text = tr("BATTLE_SELECT")
			return
		pending_kind = kind
		selected_target = selected_actor
		_refresh_preview()
		return
	if kind in ["BASIC_ATTACK_RESOURCE_ONLY","ACTIVATE_LAST_SPELL_M4"]:
		cancel_action()
		pending_kind = kind
		legal_targets = ["Boss"]
		hud.set_targets(legal_targets)
		hud.details.text = tr("BATTLE_LAST_WARNING" if kind == "ACTIVATE_LAST_SPELL_M4" else "BATTLE_BASIC")
		hud.feedback.text = tr("BATTLE_TARGET")
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

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	# Modal buttons own Enter/Space/Tab; never turn a key into implicit Pass.
	if hud.reaction_panel.visible: return
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
