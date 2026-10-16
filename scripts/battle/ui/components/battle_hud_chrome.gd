@tool
extends RefCounted
## Input-transparent, unmeasured ornament layer. Container layout and focus
## remain owned by the existing component, never by the source texture size.
const FRAME: Texture2D = preload("res://assets/ui/v35/arcane_panel.svg")

static func install(panel: Control, tint: Color = Color.WHITE) -> void:
	if panel.has_node("ArcaneChrome"):
		return
	var overlay := Control.new()
	overlay.name = "ArcaneChrome"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(overlay)
	var frame := NinePatchRect.new()
	frame.texture = FRAME
	frame.modulate = tint
	frame.patch_margin_left = 30
	frame.patch_margin_right = 30
	frame.patch_margin_top = 30
	frame.patch_margin_bottom = 30
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if panel is PanelContainer:
		var surface: StyleBox = panel.get_theme_stylebox("panel")
		frame.offset_left = -surface.get_margin(SIDE_LEFT)
		frame.offset_right = surface.get_margin(SIDE_RIGHT)
		frame.offset_top = -surface.get_margin(SIDE_TOP)
		frame.offset_bottom = surface.get_margin(SIDE_BOTTOM)
	overlay.add_child(frame)
