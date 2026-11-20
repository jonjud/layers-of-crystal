extends Node2D


const MAIN_SCENE : String = "res://scenes/main.tscn"

@export var catalog : Array[CrystalData]

var header : Label
var slots_box : VBoxContainer
var catalog_box : VBoxContainer

func _ready() -> void:
	_build_layout()
	CrystalManager.layers_changed.connect(_refresh)
	_refresh()

# ---------- โครงหน้าจอ ----------
func _build_layout() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var margin := MarginContainer.new()
	layer.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	header = Label.new()
	root.add_child(header)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	root.add_child(columns)

	slots_box = _make_column(columns, "LAYERS  (top = strong active / bottom = strong passive)")
	catalog_box = _make_column(columns, "CRYSTALS")

	var next := Button.new()
	next.text = "Next Wave"
	next.pressed.connect(_on_next_wave_pressed)
	root.add_child(next)

func _make_column(parent : Node, title : String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	parent.add_child(col)

	var label := Label.new()
	label.text = title
	col.add_child(label)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	col.add_child(content)
	return content

# ---------- วาดใหม่ทุกครั้งที่กองเปลี่ยน (ซื้อ/อัปเกรด/สลับ ล้วนทำให้ layers_changed ยิง) ----------
func _refresh() -> void:
	header.text = "Money: %d     Next: Wave %d" % [
		roundi(GameManager.to_keep["money"]),
		GameManager.to_keep["current wave"],
	]
	_clear(slots_box)
	_clear(catalog_box)

	for slot in CrystalManager.SLOTS:
		slots_box.add_child(_make_slot_row(slot))

	if catalog.is_empty():
		var warn := Label.new()
		warn.text = "(Catalog ว่าง: ลาก CrystalData ใส่ใน Inspector)"
		catalog_box.add_child(warn)
	for crystal in catalog:
		catalog_box.add_child(_make_catalog_row(crystal))

func _clear(box : Node) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()

# ---------- แถวของแต่ละช่องในกอง ----------
func _make_slot_row(slot : int) -> Control:
	var row := HBoxContainer.new()
	var crystal : CrystalData = CrystalManager.layers[slot]

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if crystal == null:
		label.text = "%d. (empty)" % (slot + 1)
	else:
		var text : String = "%d. %s  Lv%d\n    %s" % [
			slot + 1, crystal.display_name, CrystalManager.get_level(crystal),
			_fmt(crystal.active_type, CrystalManager.active_value(slot)),
		]
		if crystal.passive_type != "":
			text += "\n    " + _fmt(crystal.passive_type, CrystalManager.passive_value(slot))
		label.text = text
	row.add_child(label)

	var empty : bool = crystal == null
	row.add_child(_make_button("^", func(): CrystalManager.move_up(slot), empty or slot == 0))
	row.add_child(_make_button("v", func(): CrystalManager.move_down(slot), empty or slot == CrystalManager.SLOTS - 1))
	row.add_child(_make_button("x", func(): CrystalManager.unequip(slot), empty))
	return row

# ---------- แถวของแต่ละแผ่นที่ขาย ----------
func _make_catalog_row(crystal : CrystalData) -> Control:
	var row := HBoxContainer.new()
	var money : float = GameManager.to_keep["money"]

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var passive : String = crystal.passive_type if crystal.passive_type != "" else "-"
	var title : String = crystal.display_name
	if CrystalManager.is_owned(crystal):
		title += "  Lv%d" % CrystalManager.get_level(crystal)
		if CrystalManager.is_equipped(crystal):
			title += "  [equipped]"
	label.text = "%s\n    top: %s   bottom: %s" % [title, crystal.active_type, passive]
	row.add_child(label)

	if not CrystalManager.is_owned(crystal):
		row.add_child(_make_button("Buy %d" % crystal.buy_price, func(): CrystalManager.try_buy(crystal), money < crystal.buy_price))
	else:
		var cost : int = CrystalManager.get_upgrade_cost(crystal)
		row.add_child(_make_button("Upgrade %d" % cost, func(): CrystalManager.try_upgrade(crystal), money < cost))
		if not CrystalManager.is_equipped(crystal):
			row.add_child(_make_button("Equip", func(): CrystalManager.equip(crystal), CrystalManager.first_empty_slot() == -1))
	return row

# ---------- ตัวช่วย ----------
func _fmt(type : String, value : float) -> String:
	return "+%d%% %s" % [roundi(value * 100.0), type]

func _make_button(text : String, action : Callable, disabled : bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.pressed.connect(action)
	return button

func _on_next_wave_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)
