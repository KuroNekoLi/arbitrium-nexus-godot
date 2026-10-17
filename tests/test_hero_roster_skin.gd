extends SceneTree
const RosterScene = preload("res://scenes/ui/hero_roster_item.tscn")
const RosterSkin = preload("res://scripts/ui/hero_roster_skin.gd")
var executed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, case_id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ") + case_id)

func run() -> void:
	var first: Button = RosterScene.instantiate()
	var second: Button = RosterScene.instantiate()
	root.add_child(first)
	root.add_child(second)
	var default_skin: Resource = first.skin
	var original_border: Color = default_skin.selected.border_color
	first.configure("A", "Hero", null, Color.RED)
	second.configure("B", "Hero", null, Color.BLUE)
	first.set_selected(true)
	second.set_selected(true)
	check(first.skin == second.skin, "RS-01-SHARED-DEFAULT-DEFINITION")
	check(default_skin.selected.border_color == original_border, "RS-02-DEFAULT-TEMPLATE-NOT-MUTATED")
	check(first.get_theme_stylebox("normal").border_color != second.get_theme_stylebox("normal").border_color, "RS-03-INDEPENDENT-ACTOR-TINTS")

	var custom: Resource = default_skin.duplicate(true)
	custom.use_actor_name_color = false
	custom.name_color = Color.GREEN
	var texture := GradientTexture2D.new()
	texture.gradient = Gradient.new()
	texture.width = 16
	texture.height = 16
	var image_style := StyleBoxTexture.new()
	image_style.texture = texture
	image_style.texture_margin_left = 3
	image_style.texture_margin_right = 3
	custom.normal = image_style
	custom.selected = image_style
	custom.portrait_selected = image_style
	custom.status_surfaces["ACTIVE"] = image_style
	custom.status_colors["ACTIVE"] = Color.CYAN
	custom.downed_portrait_tint = Color(0.4, 0.6, 0.7)
	custom.combo_icons["ELIGIBLE"] = texture
	first.skin = custom
	var border: NinePatchRect = first.get_node("FantasyBorder")
	border.texture = texture
	border.modulate = Color(0.7, 0.8, 0.9)
	first.configure("A", "Hero", null, Color.RED)
	check(first.name_label.get_theme_color("font_color") == Color.GREEN, "RS-04-GUI-NAME-COLOR")
	first.set_selected(false)
	check(first.get_theme_stylebox("normal") == image_style, "RS-05-GUI-NORMAL-TEXTURE")
	first.set_selected(true)
	check(first.get_theme_stylebox("normal") == image_style, "RS-06-GUI-SELECTED-TEXTURE")
	check(first.get_node("Layout/PortraitFrame").get_theme_stylebox("panel") == image_style, "RS-07-GUI-PORTRAIT-SURFACE")
	first.set_status_kind("ACTIVE")
	var subtitle: Label = first.get_node("Layout/Stats/Subtitle")
	check(subtitle.get_theme_stylebox("normal") == image_style, "RS-08-GUI-STATUS-SURFACE")
	check(subtitle.get_theme_color("font_color") == Color.CYAN, "RS-09-GUI-STATUS-COLOR")
	first.set_status_kind("INCAPACITATED")
	check(first.portrait.modulate == custom.downed_portrait_tint, "RS-10-GUI-DOWNED-TINT")
	first.set_status_kind("ACTIVE")
	first.set_combo_state("ELIGIBLE")
	check(first.combo_mark.texture == texture, "RS-11-GUI-COMBO-ART")
	check(border.texture == texture and border.modulate == Color(0.7, 0.8, 0.9), "RS-12-FRAME-ART-AND-TINT-NOT-OVERWRITTEN")
	first.set_combo_state("")
	var partial_icons: Dictionary[String, Texture2D] = {"ELIGIBLE": texture}
	custom.combo_icons = partial_icons
	first.update_projection({"status": "INCAPACITATED", "hp": 0, "max_hp": 100, "mp": 10, "max_mp": 10}, "Downed")
	first.set_combo_state("ELIGIBLE")
	check(first.combo_state.is_empty() and not first.combo_mark.visible, "RS-21-PARTIAL-SKIN-DOWNED-FALLBACK")
	custom.tint_flat_surfaces_with_actor = false
	var flat := StyleBoxFlat.new()
	flat.border_color = Color.MAGENTA
	custom.selected = flat
	check(first.get_theme_stylebox("normal") == flat, "RS-13-INSPECTOR-RESOURCE-REPLACEMENT-LIVE")
	flat.border_color = Color.YELLOW
	check(first.get_theme_stylebox("normal").border_color == Color.YELLOW, "RS-14-NESTED-STYLE-EDIT-LIVE")
	custom.use_actor_name_color = true
	check(first.name_label.get_theme_color("font_color") == Color.RED, "RS-15-INSPECTOR-IDENTITY-COLOR-TOGGLE")
	check(second.skin == default_skin and second.get_theme_stylebox("normal") != flat, "RS-16-OTHER-INSTANCE-UNCHANGED")

	var path: String = "user://hero_roster_skin_test.tres"
	check(ResourceSaver.save(custom, path) == OK, "RS-17-SAVE-GUI-SKIN")
	var loaded: Resource = ResourceLoader.load(path, "Resource", ResourceLoader.CACHE_MODE_IGNORE)
	check(loaded.normal is StyleBoxTexture and loaded.normal.texture != null and loaded.selected.border_color == Color.YELLOW, "RS-18-RELOAD-GUI-SKIN")
	first.skin = loaded
	check(not custom.changed.is_connected(Callable(first, "_on_skin_changed")), "RS-19-REPLACED-SKIN-DISCONNECTED")
	first.queue_free()
	second.queue_free()
	await process_frame
	check(not loaded.changed.has_connections(), "RS-20-FREED-ITEM-DISCONNECTED")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("HERO_ROSTER_SKIN_REPORT executed=%d passed=%d failed=%d" % [executed, executed-failed, failed])
	quit(0 if failed == 0 else 1)
