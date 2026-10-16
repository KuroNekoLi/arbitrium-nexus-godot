extends SceneTree
## New CHARACTER_APPEARANCE_AND_EDITOR_PREVIEW test group.
## It does not rerun any exhausted Last Spell or P4.4 GUI attempt.
const Registry = preload("res://scripts/battle/presentation/character_appearance_registry.gd")
const Mock = preload("res://scripts/battle/presentation/battle_editor_preview_data.gd")
const Screen = preload("res://scenes/battle/battle_screen.tscn")
const ActorScene = preload("res://scenes/battle/actors/battle_actor.tscn")

var passed: int = 0
var failed: int = 0
const EXPECTED: int = 35

func check(id: String, good: bool) -> void:
	if good:
		passed += 1
		print("PASS ",id)
	else:
		failed += 1
		printerr("FAIL ",id)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for id: String in ["A","B","C"]:
		var item: BattleCharacterAppearance = Registry.appearance_for(id)
		check("EDITOR-APPEAR-"+id,item != null)
		if item == null:
			quit(1)
			return
		check("EDITOR-ATLAS-"+id,item.atlas != null and item.atlas.get_size() == Vector2(1254,1254))
		check("EDITOR-CG-"+id,item.cg != null and item.cg.get_size() == Vector2(1024,1536))
		check("EDITOR-IDLE-"+id,item.region_for(0,0).size == Vector2(418,418))
		check("EDITOR-RUN-"+id,item.region_for(1,0).position.y == 418)
		check("EDITOR-STRIKE-"+id,item.region_for(2,0).position.y == 800)
		check("EDITOR-PORTRAIT-"+id,item.portrait_texture() != null)
		check("EDITOR-FRAME-"+id,item.sprite_texture(1,2) != null)
	check("EDITOR-BOUNDS-EMPTY",Registry.appearance_for("Boss") == null)
	check("EDITOR-CG-UNIQUE",Registry.cg_for("A") != Registry.cg_for("B") and Registry.cg_for("B") != Registry.cg_for("C"))
	var screen: Control = Screen.instantiate()
	for id: String in ["A","B","C"]:
		var node: Node2D = screen.get_node("Design/Arena/"+id)
		check("EDITOR-INDEPENDENT-SLOT-"+id,node != null and node.get("appearance") == Registry.appearance_for(id))
	check("EDITOR-MOCK-PROJECTION",Mock.projection().get("resources",{}).get("current_ap",-1) == 6)
	check("EDITOR-MOCK-NO-DOMAIN",not Mock.projection().has("core") and not Mock.projection().has("events"))
	screen.free()
	var actor: Node2D = ActorScene.instantiate()
	actor.set("actor_id","A")
	actor.set("appearance",Registry.appearance_for("A"))
	root.add_child(actor)
	check("EDITOR-ACTOR-SPRITE",actor.get("body") != null and (actor.get("body") as AnimatedSprite2D).sprite_frames.get_frame_count("idle") == 3)
	check("EDITOR-NO-SAVED-CHILDREN",(actor.get("body") as AnimatedSprite2D).owner == null if actor.get("body") != null else false)
	var original: AnimatedSprite2D = actor.get("body")
	(actor.get("appearance") as Resource).emit_changed()
	check("EDITOR-RESOURCE-CHANGE-LIVE",actor.get("body") == original and original != null and original.sprite_frames.get_frame_count("run") == 3)
	root.remove_child(actor)
	check("EDITOR-SIGNAL-CLEANUP",not (actor.get("appearance") as Resource).changed.is_connected(Callable(actor,"_on_art_changed")))
	actor.free()
	print("CHARACTER_EDITOR_PREVIEW_REPORT executed=%d passed=%d failed=%d" % [passed+failed,passed,failed])
	quit(0 if failed == 0 and passed == EXPECTED else 1)
