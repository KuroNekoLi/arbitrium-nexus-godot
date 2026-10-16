@tool
class_name BattleCharacterAppearance
extends Resource
## Reversible presentation-only candidate. No combat data or card ownership.

@export var atlas: Texture2D
@export var cg: Texture2D
@export var columns: PackedInt32Array = PackedInt32Array([0, 418, 836, 1254]):
	set(value):
		columns = value
		emit_changed()
@export var rows: PackedInt32Array = PackedInt32Array([0, 418, 800, 1254]):
	set(value):
		rows = value
		emit_changed()
@export var portrait_rect: Rect2 = Rect2(80, 130, 864, 940)
@export var foot_offset: Vector2 = Vector2.ZERO:
	set(value):
		foot_offset = value
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
