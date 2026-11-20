extends Node2D

# เส้นทางฉากเกมหลักที่ใช้กลับไปเล่น Wave ถัดไป
const MAIN_SCENE : String = "res://scenes/main.tscn"

# รายการ CrystalData ที่กำหนดให้แสดงในร้าน
@export var catalog : Array[CrystalData]

# Label แสดงเงินและ Wave ปัจจุบัน
var header : Label
# Container สำหรับรายการ Crystal ที่ติดตั้งอยู่ในแต่ละช่อง
var slots_box : VBoxContainer
# Container สำหรับรายการ Crystal ที่อยู่ใน Catalog
var catalog_box : VBoxContainer

# ปุ่มสลับระหว่างหน้ารายการ Layers และ Crystals
var layers_tab : Button
var crystals_tab : Button

# สร้างหน้าร้าน เชื่อมการเปลี่ยนแปลง Layers และแสดงข้อมูลครั้งแรก
func _ready() -> void:
	_build_layout()
	CrystalManager.layers_changed.connect(_refresh)
	_refresh()

# ---------- โครงหน้าจอ ----------
# สร้าง UI ของร้านด้วย Control nodes และเชื่อมปุ่มต่าง ๆ เข้ากับฟังก์ชัน
func _build_layout() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var margin := MarginContainer.new()
	layer.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 5)
	margin.add_child(root)

	# Header
	header = Label.new()
	root.add_child(header)

	# Tabs
	var tabs := HBoxContainer.new()
	root.add_child(tabs)

	layers_tab = Button.new()
	layers_tab.text = "LAYERS"
	layers_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layers_tab.pressed.connect(_show_layers)
	tabs.add_child(layers_tab)

	crystals_tab = Button.new()
	crystals_tab.text = "CRYSTALS"
	crystals_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crystals_tab.pressed.connect(_show_crystals)
	tabs.add_child(crystals_tab)

	# Content
	var content := Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(scroll)

	var content_box := VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_box)

	slots_box = content_box

	# Catalog container
	catalog_box = VBoxContainer.new()
	catalog_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(catalog_box)

	# Bottom button
	var next := Button.new()
	next.text = "NEXT WAVE"
	next.custom_minimum_size.y = 32
	next.pressed.connect(_on_next_wave_pressed)
	root.add_child(next)

	_show_layers()

# สร้างคอลัมน์แนวตั้งที่มีหัวข้อและพื้นที่เนื้อหาภายใน แล้วคืน Container เนื้อหา
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
# อัปเดต Header และสร้างแถวรายการ Layers/Catalog ใหม่ตามข้อมูลล่าสุด
func _refresh() -> void:
	header.text = "Money: %d  |  Wave: %d" % [
		roundi(GameManager.to_keep["money"]),
		GameManager.to_keep["current wave"],
	]
	_clear(slots_box)
	_clear(catalog_box)
	for slot in CrystalManager.SLOTS:
		slots_box.add_child(_make_slot_row(slot))
	if catalog.is_empty():
		var warn := Label.new()
		warn.text = "(Catalog empty)"
		catalog_box.add_child(warn)
	for crystal in catalog:
		catalog_box.add_child(_make_catalog_row(crystal))

# ลบลูกทั้งหมดออกจาก Container และสั่งให้แต่ละ Node ถูกทำลายภายหลัง
func _clear(box : Node) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()

# ---------- แถวของแต่ละช่องในกอง ----------
# สร้างแถวแสดง Crystal ในช่องที่ระบุ พร้อมปุ่มเลื่อนตำแหน่งและถอดออก
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
	row.add_theme_constant_override("separation", 3)
	return row

# ---------- แถวของแต่ละแผ่นที่ขาย ----------
# สร้างแถวข้อมูล Crystal ใน Catalog พร้อมปุ่มซื้อ อัปเกรด หรือติดตั้งตามสถานะ
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
			row.add_theme_constant_override("separation", 3)
	return row

# ---------- ตัวช่วย ----------
# แปลงประเภทเอฟเฟกต์และค่าเป็นข้อความเปอร์เซ็นต์สำหรับแสดงผล
func _fmt(type : String, value : float) -> String:
	return "+%d%% %s" % [roundi(value * 100.0), type]

# สร้างปุ่ม กำหนดข้อความ สถานะ disabled ขนาด และ Callable ที่จะทำงานเมื่อกด
func _make_button(text : String, action : Callable, disabled : bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.pressed.connect(action)
	button.custom_minimum_size = Vector2(32, 28)
	button.add_theme_font_size_override("font_size", 11)
	return button

# กลับไปยังฉากเกมหลักเพื่อเริ่ม Wave ถัดไป
func _on_next_wave_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)

# แสดงรายการ Layers และตั้งสถานะปุ่ม Tab ให้ตรงกับหน้าที่เลือก
func _show_layers() -> void:
	slots_box.get_parent().visible = true
	catalog_box.visible = false

	layers_tab.disabled = true
	crystals_tab.disabled = false


# แสดง Catalog ของ Crystals และตั้งสถานะปุ่ม Tab ให้ตรงกับหน้าที่เลือก
func _show_crystals() -> void:
	slots_box.get_parent().visible = false
	catalog_box.visible = true

	layers_tab.disabled = false
	crystals_tab.disabled = true
