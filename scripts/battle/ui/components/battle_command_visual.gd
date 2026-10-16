@tool
extends RefCounted
## V3.5.2 replaceable command presentation table. Visual identity ONLY:
## it never adds commands, changes command IDs/fields or implies a rule.
## Analyze/Item keep their UNIMPLEMENTED event; an icon is not a feature.
const ICONS: Dictionary = {
	"BATTLE_BASIC": preload("res://assets/ui/v35/cmd_basic.svg"),
	"BATTLE_ANALYZE": preload("res://assets/ui/v35/cmd_analyze.svg"),
	"BATTLE_ITEM": preload("res://assets/ui/v35/cmd_item.svg"),
	"BATTLE_SWAP": preload("res://assets/ui/v35/cmd_swap.svg"),
	"BATTLE_LAST": preload("res://assets/ui/v35/cmd_last.svg"),
	"BATTLE_END": preload("res://assets/ui/v35/cmd_end.svg"),
}
const SUBTITLES: Dictionary = {
	"BATTLE_BASIC": "BATTLE_BASIC_SUB",
	"BATTLE_ANALYZE": "BATTLE_UNIMPLEMENTED_SUB",
	"BATTLE_ITEM": "BATTLE_UNIMPLEMENTED_SUB",
	"BATTLE_SWAP": "BATTLE_SWAP_SUB",
	"BATTLE_LAST": "BATTLE_LAST_SUB",
	"BATTLE_END": "BATTLE_END_SUB",
}
## Strong treatments are reserved for the irreversible and phase-ending commands.
const EMPHASIS: Array[String] = ["BATTLE_LAST", "BATTLE_END"]

static func icon_for(key: String) -> Texture2D:
	return ICONS.get(key, null)

static func subtitle_key(key: String) -> String:
	return str(SUBTITLES.get(key, ""))

static func is_emphasis(key: String) -> bool:
	return EMPHASIS.has(key)

## Emphasis surface: deeper tinted fill + 2px accent border + glow.
static func emphasis_surface(accent: Color, state: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var base: Color = accent.darkened(0.72)
	style.bg_color = base.lightened(0.12) if state == "hover" else base.lightened(0.2) if state == "pressed" else base
	style.border_color = accent.lightened(0.15) if state != "normal" else accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.35 if state == "normal" else 0.5)
	style.shadow_size = 5
	if state == "disabled":
		style.bg_color = Color("#141C25")
		style.border_color = Color("#3A4652")
		style.shadow_size = 0
	return style

static func disabled_surface() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0A1520")
	style.border_color = Color("#2C3C4A")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style
