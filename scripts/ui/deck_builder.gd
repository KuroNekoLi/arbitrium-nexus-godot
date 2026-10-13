extends Control

signal close_requested
signal apply_requested

const CardCatalogClass = preload("res://scripts/domain/card_catalog.gd")
const DeckProfileStoreClass = preload("res://scripts/domain/deck_profile_store.gd")

var profile: Dictionary = {}
var hero_id := "kleya"
var deck_list: VBoxContainer
var catalog_list: VBoxContainer
var deck_title: Label
var status_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	profile = DeckProfileStoreClass.load_profile()
	_build()
	_refresh()

func _build() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color("#06101b")
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1040, 650)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0b1725")
	panel_style.border_color = Color("#4a91a8")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 22
	panel_style.content_margin_right = 22
	panel_style.content_margin_top = 18
	panel_style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var heading := Label.new()
	heading.text = "牌組編輯器  /  每位角色 8 張牌"
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", Color("#d9f5ff"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close_button := _button("返回戰鬥")
	close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close_button)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	layout.add_child(tabs)
	for hero: String in CardCatalogClass.PLAYER_IDS:
		var tab := _button(_hero_name(hero))
		tab.pressed.connect(_select_hero.bind(hero))
		tabs.add_child(tab)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	layout.add_child(columns)
	var deck_column := _column("目前牌組", true)
	columns.add_child(deck_column)
	deck_title = deck_column.get_child(0) as Label
	var card_pool_column := _column("可用卡牌目錄", false)
	columns.add_child(card_pool_column)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	layout.add_child(footer)
	status_label = Label.new()
	status_label.text = "修改需儲存；套用會以新牌組重新開始戰鬥。"
	status_label.add_theme_color_override("font_color", Color("#91b6c4"))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(status_label)
	var restore_button := _button("恢復預設")
	restore_button.pressed.connect(_restore_defaults)
	footer.add_child(restore_button)
	var load_button := _button("載入存檔")
	load_button.pressed.connect(_load_profile)
	footer.add_child(load_button)
	var save_button := _button("儲存設定")
	save_button.pressed.connect(_save_profile)
	footer.add_child(save_button)
	var export_button := _button("匯出 JSON")
	export_button.pressed.connect(_export_profile)
	footer.add_child(export_button)
	var apply_button := _button("套用並重新開始")
	apply_button.pressed.connect(_apply_profile)
	footer.add_child(apply_button)

func _column(title: String, is_deck: bool) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 15)
	heading.add_theme_color_override("font_color", Color("#75dced"))
	column.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	column.add_child(scroll)
	if is_deck:
		deck_list = list
	else:
		catalog_list = list
	return column

func _refresh() -> void:
	if deck_list == null or catalog_list == null:
		return
	for child: Node in deck_list.get_children():
		child.queue_free()
	for child: Node in catalog_list.get_children():
		child.queue_free()
	var chosen: Array = profile["decks"][hero_id]
	deck_title.text = "目前牌組（%d / 8 張）" % chosen.size()
	for card_id: String in chosen:
		_add_card_row(deck_list, card_id, false)
	for card_id: String in CardCatalogClass.card_ids():
		_add_card_row(catalog_list, card_id, true)
	status_label.text = "%s｜修改需儲存；套用會以新牌組重新開始戰鬥。" % _hero_name(hero_id)

func _add_card_row(parent: VBoxContainer, card_id: String, is_catalog: bool) -> void:
	var card: CardData = CardCatalogClass.get_definition(card_id)
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 54
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	var name := Label.new()
	name.text = "%s   ·   %s   ·   %d 能量" % [card.title, _kind_name(card.kind), card.cost]
	name.add_theme_color_override("font_color", _kind_color(card.kind))
	info.add_child(name)
	var description := Label.new()
	description.text = card.description
	description.add_theme_font_size_override("font_size", 10)
	description.add_theme_color_override("font_color", Color("#a7bbc8"))
	info.add_child(description)
	row.add_child(info)
	var action := _button("加入" if is_catalog else "移除")
	action.custom_minimum_size.x = 82
	if is_catalog:
		var chosen: Array = profile["decks"][hero_id]
		action.disabled = chosen.size() >= 8 or chosen.has(card_id)
		action.pressed.connect(_add_card.bind(card_id))
	else:
		action.pressed.connect(_remove_card.bind(card_id))
	row.add_child(action)
	parent.add_child(row)
	var separator := HSeparator.new()
	parent.add_child(separator)

func _select_hero(next_hero: String) -> void:
	hero_id = next_hero
	_refresh()

func _add_card(card_id: String) -> void:
	var chosen: Array = profile["decks"][hero_id]
	if chosen.size() < 8 and not chosen.has(card_id):
		chosen.append(card_id)
		_refresh()

func _remove_card(card_id: String) -> void:
	profile["decks"][hero_id].erase(card_id)
	_refresh()

func _restore_defaults() -> void:
	profile = DeckProfileStoreClass.default_profile()
	_refresh()
	status_label.text = "已恢復三位角色的預設牌組；按「儲存設定」保存變更。"

func _load_profile() -> void:
	profile = DeckProfileStoreClass.load_profile()
	_refresh()
	status_label.text = "已載入 user://deck_profile.json（若沒有存檔則載入預設牌組）。"

func _save_profile() -> void:
	if not DeckProfileStoreClass.save_profile(profile):
		status_label.text = "儲存失敗：每位角色都必須有 8 張不重複的有效卡牌。"
		return
	status_label.text = "牌組設定已儲存至 user://deck_profile.json。"

func _export_profile() -> void:
	if not DeckProfileStoreClass.export_profile(profile):
		status_label.text = "匯出失敗：請確認每位角色的牌組均為 8 張有效卡牌。"
		return
	status_label.text = "已匯出至 user://exports/arbitrium_decks.json。"

func _apply_profile() -> void:
	if not DeckProfileStoreClass.save_profile(profile):
		status_label.text = "套用失敗：每位角色都必須有 8 張不重複的有效卡牌。"
		return
	apply_requested.emit()

func _hero_name(id: String) -> String:
	return {"kleya": "克蕾雅", "nova": "諾瓦", "yora": "尤拉"}.get(id, id)

func _kind_name(kind: int) -> String:
	return ["攻擊", "防禦", "支援", "反應"][kind]

func _kind_color(kind: int) -> Color:
	return [Color("#ff765f"), Color("#53d8c2"), Color("#c29aff"), Color("#ff5cba")][kind]

func _button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(92, 36)
	return button
