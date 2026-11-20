extends Node2D
# หน้า Shop 640x360 : 3 แท็บ  LAYERS (จัดกอง) / CRYSTALS (ซื้อ-อัป) / LUCKY (สล็อต)

const MAIN_SCENE : String = "res://scenes/main.tscn"

var catalog : Array[CrystalData] = []

var header_money : Label
var header_wave : Label
var layers_scroll : ScrollContainer
var layers_box : VBoxContainer
var catalog_scroll : ScrollContainer
var catalog_box : VBoxContainer
var lucky_page : HBoxContainer
var tab_buttons : Array[Button] = []

# Lucky page
var machine : SlotMachine
var spin_button : Button
var spin_result : Label
var spin_info : Label
var _last_spin : Dictionary = {}
var _saved_scroll : Array = [0, 0]

func _ready() -> void:
	catalog = CrystalCatalog.all()   # แหล่งเดียวกับสล็อตหน้าเมนู
	_build_layout()
	CrystalManager.layers_changed.connect(_refresh)
	_refresh()
	_show_tab(0)

# ---------- โครงหน้าจอ ----------
func _build_layout() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var bg := ColorRect.new()
	bg.color = GameTheme.BG
	layer.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	layer.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)

	# Header
	var head := HBoxContainer.new()
	root.add_child(head)
	header_money = Label.new()
	header_money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_money.add_theme_color_override("font_color", GameTheme.GOLD)
	header_money.add_theme_font_size_override("font_size", 14)
	head.add_child(header_money)
	header_wave = Label.new()
	head.add_child(header_wave)

	# Tabs
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	root.add_child(tabs)
	var group := ButtonGroup.new()
	var tab_names : Array[String] = ["LAYERS", "CRYSTALS", "LUCKY"]
	for i in tab_names.size():
		var b := Button.new()
		b.text = tab_names[i]
		b.toggle_mode = true
		b.button_group = group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_show_tab.bind(i))
		tabs.add_child(b)
		tab_buttons.append(b)

	# Pages
	var pages := Control.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(pages)

	layers_scroll = _make_scroll(pages)
	layers_box = _make_scroll_box(layers_scroll)
	catalog_scroll = _make_scroll(pages)
	catalog_box = _make_scroll_box(catalog_scroll)

	lucky_page = HBoxContainer.new()
	lucky_page.add_theme_constant_override("separation", 14)
	pages.add_child(lucky_page)
	lucky_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_lucky(lucky_page)

	# Bottom button
	var next := Button.new()
	next.text = "NEXT WAVE  >"
	next.custom_minimum_size.y = 30
	next.add_theme_color_override("font_color", GameTheme.GOLD)
	next.pressed.connect(_on_next_wave_pressed)
	root.add_child(next)

func _make_scroll(parent : Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return scroll

func _make_scroll_box(scroll : ScrollContainer) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	scroll.add_child(box)
	return box

func _show_tab(index : int) -> void:
	layers_scroll.visible = index == 0
	catalog_scroll.visible = index == 1
	lucky_page.visible = index == 2
	tab_buttons[index].button_pressed = true

# ---------- วาดใหม่ทุกครั้งที่กองเปลี่ยน ----------
func _refresh() -> void:
	if machine != null and machine.spinning:
		return   # ระหว่าง reel หมุนไม่รีเฟรช (กันสปอยล์) -- จบแล้วเรียกเอง
	var v1 : int = layers_scroll.scroll_vertical
	var v2 : int = catalog_scroll.scroll_vertical
	_set_header(float(GameManager.to_keep["money"]))
	_clear(layers_box)
	_clear(catalog_box)

	var hint := Label.new()
	hint.text = "Top layer = strong element damage.  Bottom layer = strong passive.  Use ^ v to reorder."
	hint.add_theme_color_override("font_color", GameTheme.MUTED)
	hint.add_theme_font_size_override("font_size", 10)
	layers_box.add_child(hint)
	for slot in CrystalManager.SLOTS:
		layers_box.add_child(_make_slot_row(slot))

	if catalog.is_empty():
		var warn := Label.new()
		warn.text = "(Catalog empty)"
		catalog_box.add_child(warn)
	for crystal in catalog:
		catalog_box.add_child(_make_catalog_row(crystal))

	_refresh_lucky()
	# คืนตำแหน่ง scroll หลัง layout คำนวณเสร็จ
	_saved_scroll = [v1, v2]
	get_tree().process_frame.connect(_restore_scroll, CONNECT_ONE_SHOT)

func _restore_scroll() -> void:
	layers_scroll.scroll_vertical = int(_saved_scroll[0])
	catalog_scroll.scroll_vertical = int(_saved_scroll[1])

func _set_header(money : float) -> void:
	header_money.text = "$ %d" % roundi(money)
	header_wave.text = "Next: Wave %d / %d" % [GameManager.to_keep["current wave"], GameManager.total_waves]

func _clear(box : Node) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()

# ---------- Row helpers ----------
func _make_row(accent : Color) -> HBoxContainer:
	# คืน HBox ที่อยู่ใน PanelContainer (ผู้เรียกต้องดึง .get_parent() ไปใส่ box)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	panel.add_child(h)
	var swatch := ColorRect.new()
	swatch.color = accent
	swatch.custom_minimum_size = Vector2(4, 30)
	h.add_child(swatch)
	return h

# ---------- แถวของแต่ละช่องในกอง ----------
func _make_slot_row(slot : int) -> Control:
	var crystal : CrystalData = CrystalManager.layers[slot]
	var h : HBoxContainer = _make_row(crystal.color if crystal != null else GameTheme.PANEL_LIGHT)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var role : String = "TOP" if slot == 0 else ("BTM" if slot == CrystalManager.SLOTS - 1 else "")
	if crystal == null:
		label.text = "%d. (empty)  %s" % [slot + 1, role]
		label.add_theme_color_override("font_color", GameTheme.MUTED)
	else:
		var text : String = "%d. %s  Lv%d/%d  %s\n    %s" % [
			slot + 1, crystal.display_name, CrystalManager.get_level(crystal), crystal.max_level, role,
			_fmt(crystal.active_type, CrystalManager.active_value(slot)),
		]
		if crystal.passive_type != "":
			text += "   " + _fmt(crystal.passive_type, CrystalManager.passive_value(slot))
		label.text = text
	h.add_child(label)
	var empty : bool = crystal == null
	h.add_child(_make_button("^", func(): CrystalManager.move_up(slot), empty or slot == 0))
	h.add_child(_make_button("v", func(): CrystalManager.move_down(slot), empty or slot == CrystalManager.SLOTS - 1))
	h.add_child(_make_button("x", func(): CrystalManager.unequip(slot), empty))
	return h.get_parent() as Control

# ---------- แถวของแต่ละแผ่นที่ขาย ----------
func _make_catalog_row(crystal : CrystalData) -> Control:
	var h : HBoxContainer = _make_row(crystal.color)
	var money : float = float(GameManager.to_keep["money"])

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var passive : String = GameTheme.nice(crystal.passive_type) if crystal.passive_type != "" else "-"
	var title : String = crystal.display_name
	if CrystalManager.is_owned(crystal):
		title += "  Lv%d/%d" % [CrystalManager.get_level(crystal), crystal.max_level]
		if CrystalManager.is_equipped(crystal):
			title += "  [equipped]"
	label.text = "%s\n    top: %s   bottom: %s" % [title, GameTheme.nice(crystal.active_type), passive]
	h.add_child(label)

	if not CrystalManager.is_owned(crystal):
		h.add_child(_make_button("Buy $%d" % crystal.buy_price, func(): CrystalManager.try_buy(crystal), money < crystal.buy_price))
	else:
		if CrystalManager.is_maxed(crystal):
			h.add_child(_make_button("MAX", func(): pass, true))
		else:
			var cost : int = CrystalManager.get_upgrade_cost(crystal)
			h.add_child(_make_button("Upgrade $%d" % cost, func(): CrystalManager.try_upgrade(crystal), money < cost))
		if not CrystalManager.is_equipped(crystal):
			h.add_child(_make_button("Equip", func(): CrystalManager.equip(crystal), CrystalManager.first_empty_slot() == -1))
	return h.get_parent() as Control

# ---------- LUCKY (สล็อต) ----------
func _build_lucky(page : HBoxContainer) -> void:
	# ซ้าย: เครื่อง
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 8)
	page.add_child(left)

	var title := Label.new()
	title.text = "LUCKY SLOTS"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", GameTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(title)

	machine = SlotMachine.new(54)
	machine.alignment = BoxContainer.ALIGNMENT_CENTER
	machine.finished.connect(_on_spin_finished)
	left.add_child(machine)

	spin_result = Label.new()
	spin_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spin_result.add_theme_font_size_override("font_size", 13)
	spin_result.custom_minimum_size.y = 34
	left.add_child(spin_result)

	spin_button = Button.new()
	spin_button.custom_minimum_size = Vector2(180, 34)
	spin_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	spin_button.pressed.connect(_on_spin_pressed)
	left.add_child(spin_button)

	spin_info = Label.new()
	spin_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spin_info.add_theme_color_override("font_color", GameTheme.MUTED)
	spin_info.add_theme_font_size_override("font_size", 10)
	left.add_child(spin_info)

	# ขวา: ตารางรางวัล
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 210
	right.add_theme_constant_override("separation", 3)
	page.add_child(right)
	var pt := Label.new()
	pt.text = "PAYTABLE  (x spin cost)"
	pt.add_theme_color_override("font_color", GameTheme.GOLD)
	right.add_child(pt)
	for i in range(SlotLogic.Sym.size() - 1, -1, -1):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		for k in 3:
			var icon := SymbolIcon.new(16)
			icon.symbol = i
			row.add_child(icon)
		var l := Label.new()
		l.text = "  x%s   (pair x%s)" % [_num(SlotLogic.TRIPLE[i]), _num(SlotLogic.PAIR[i])]
		row.add_child(l)
		right.add_child(row)
	var note := Label.new()
	note.text = "Triple Amethyst / Star also gives\na FREE crystal upgrade.\nLose 5 in a row -> next spin is\nguaranteed a pair.\nLuck crystals improve the odds."
	note.add_theme_color_override("font_color", GameTheme.MUTED)
	note.add_theme_font_size_override("font_size", 10)
	right.add_child(note)

	machine.show_symbols([SlotLogic.Sym.RUBY, SlotLogic.Sym.STAR, SlotLogic.Sym.RUBY])

func _num(v : float) -> String:
	return str(int(v)) if is_equal_approx(v, floorf(v)) else "%.1f" % v

func _refresh_lucky() -> void:
	var cost : int = GameManager.luck.slot_cost()
	spin_button.text = "SPIN   $%d" % cost
	spin_button.disabled = machine.spinning or not GameManager.luck.can_spin()
	spin_info.text = "Luck +%d%%    Dry streak %d/%d" % [
		roundi(GameManager.luck.luck() * 100.0), GameManager.luck.slot_dry, LuckManager.SLOT_PITY]

func _on_spin_pressed() -> void:
	var res : Dictionary = GameManager.luck.spin_slot()
	if res.is_empty():
		return
	_last_spin = res
	spin_button.disabled = true
	spin_result.text = ""
	# เงินในหัวข้อ: แสดงยอดหลังหักค่าหมุน แต่ยังไม่รวมรางวัล (กันสปอยล์)
	_set_header(float(GameManager.to_keep["money"]) - float(res["payout"]))
	machine.spin(res["symbols"])

func _on_spin_finished() -> void:
	var payout : int = int(_last_spin["payout"])
	var cost : int = int(_last_spin["cost"])
	var text : String
	if payout > 0:
		spin_result.add_theme_color_override("font_color", GameTheme.GOOD if payout >= cost else GameTheme.MUTED)
		text = "WIN  +$%d" % payout
		if int(_last_spin["kind"]) == 3:
			text = "TRIPLE!  +$%d" % payout
	else:
		spin_result.add_theme_color_override("font_color", GameTheme.BAD)
		text = "No match"
	if _last_spin["bonus"] != "":
		text += "\n" + str(_last_spin["bonus"])
	spin_result.text = text
	_refresh()

# ---------- ตัวช่วย ----------
func _fmt(type : String, value : float) -> String:
	return "+%d%% %s" % [roundi(value * 100.0), GameTheme.nice(type)]

func _make_button(text : String, action : Callable, disabled : bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.pressed.connect(action)
	button.custom_minimum_size = Vector2(32, 28)
	return button

func _on_next_wave_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)
