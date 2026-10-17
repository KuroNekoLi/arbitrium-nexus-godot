@tool
class_name BattleCharacterAppearance
extends Resource
## Reversible presentation-only candidate. No combat data or card ownership.

@export var atlas: Texture2D:
	set(value):
		atlas = value
		emit_changed()
@export var cg: Texture2D:
	set(value):
		cg = value
		emit_changed()
@export var cg_states: Texture2D:
	set(value):
		cg_states = value
		emit_changed()
@export var cg_state_split_y: int = 0:
	set(value):
		cg_state_split_y = maxi(0, value)
		emit_changed()
@export var columns: PackedInt32Array = PackedInt32Array([0, 418, 836, 1254]):
	set(value):
		columns = value
		emit_changed()
@export var rows: PackedInt32Array = PackedInt32Array([0, 418, 800, 1254]):
	set(value):
		rows = value
		emit_changed()
@export var portrait_rect: Rect2 = Rect2(80, 130, 864, 940):
	set(value):
		portrait_rect = value
		emit_changed()
@export var foot_offset: Vector2 = Vector2.ZERO:
	set(value):
		foot_offset = value
		emit_changed()
@export var frame_baselines: PackedFloat32Array = PackedFloat32Array():
	set(value):
		frame_baselines = value
		emit_changed()
@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		emit_changed()

func region_for(animation_row: int, frame_column: int) -> Rect2:
	if atlas == null or rows.size() != 4 or columns.size() != 4:
		return Rect2()
	if animation_row < 0 or animation_row > 2 or frame_column < 0 or frame_column > 2:
		return Rect2()
	var left: int = columns[frame_column]
	var top: int = rows[animation_row]
	var right: int = columns[frame_column+1]
	var bottom: int = rows[animation_row+1]
	if left < 0 or top < 0 or right > atlas.get_width() or bottom > atlas.get_height():
		return Rect2()
	if left >= right or top >= bottom:
		return Rect2()
	return Rect2(left, top, right-left, bottom-top)

func sprite_texture(row: int, column: int) -> Texture2D:
	var region: Rect2 = region_for(row, column)
	if region.size.x <= 0 or region.size.y <= 0:
		return null
	var frame := AtlasTexture.new()
	frame.atlas = atlas
	frame.region = region
	return frame

func baseline_for(row: int, column: int) -> float:
	var region: Rect2 = region_for(row, column)
	var index: int = row * 3 + column
	if index >= 0 and index < frame_baselines.size():
		return clampf(frame_baselines[index], 0.0, region.size.y)
	return region.size.y

func portrait_texture() -> Texture2D:
	if cg == null:
		return sprite_texture(0, 0)
	var bounds := Rect2(Vector2.ZERO, cg.get_size())
	if not bounds.encloses(portrait_rect) or portrait_rect.size.x <= 0 or portrait_rect.size.y <= 0:
		return cg
	var cropped := AtlasTexture.new()
	cropped.atlas = cg
	cropped.region = portrait_rect
	return cropped

## Returns the portrait or field CG from this character's own state sheet.
## Exhausted characters have no field CG; callers must keep field visibility
## governed by the battle state, not this presentation helper.
func state_texture(status: String, on_field: bool) -> Texture2D:
	if status == "EXHAUSTED" and on_field:
		return null
	if cg_states == null or cg_states.get_size() != Vector2(1024, 1280):
		return null
	if cg_state_split_y <= 0 or cg_state_split_y >= 1280:
		return null
	var column: int = 1 if status == "INCAPACITATED" else 0
	var top: int = cg_state_split_y if on_field else 0
	var height: int = 1280 - cg_state_split_y if on_field else cg_state_split_y
	var region := AtlasTexture.new()
	region.atlas = cg_states
	region.region = Rect2(column * 512, top, 512, height)
	return region

func portrait_texture_for_status(status: String) -> Texture2D:
	var state_portrait: Texture2D = state_texture(status, false)
	return state_portrait if state_portrait != null else portrait_texture()

func field_cg_for_status(status: String) -> Texture2D:
	return state_texture(status, true)
