extends CanvasLayer

var player : Node2D
@onready var root : Control = $Control
@onready var hp_bar : ProgressBar = $Control/HealthBar

var hp_label : Label
var money_label : Label
var wave_label : Label
var buff_box : VBoxContainer
var buff_labels : Dictionary = {}

var orb_panel : PanelContainer
var orb_title : Label
var orb_detail : Label
var _orb_tween : Tween

var wager : WagerPanel
var layers_box : VBoxContainer

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player:
		hp_bar.max_value = GameManager.to_keep["max_hp"]
		hp_bar.value = player.hp
	_build_info_labels()
	_build_orb_banner()
	_build_wager()
	_build_layers_box()
	CrystalManager.layers_changed.connect(_refresh_layers)
	_refresh_layers()
	_show_wave_banner()
	SignalBus.buffs_changed.connect(_rebuild_buffs)
	SignalBus.orb_rolled.connect(_on_orb_rolled)
	SignalBus.orb_applied.connect(_on_orb_applied)
	SignalBus.wave_passed.connect(_on_wave_passed)
	_rebuild_buffs()

# ---------- โครง HUD (ออกแบบสำหรับ 640x360) ----------
func _build_info_labels() -> void:
	var vp_w : float = get_viewport().get_visible_rect().size.x

	hp_label = Label.new()
	hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 10)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.add_child(hp_label)

	money_label = Label.new()
	money_label.position = Vector2(12, 34)
	money_label.add_theme_color_override("font_color", GameTheme.GOLD)
	money_label.add_theme_font_size_override("font_size", 13)
	root.add_child(money_label)

	wave_label = Label.new()
	wave_label.custom_minimum_size = Vector2(170, 0)
	wave_label.position = Vector2(vp_w - 170.0 - 12.0, 12)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(wave_label)

	buff_box = VBoxContainer.new()
	buff_box.custom_minimum_size = Vector2(170, 0)
	buff_box.position = Vector2(vp_w - 170.0 - 12.0, 30)
	buff_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(buff_box)

func _build_orb_banner() -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	holder.offset_top = 44
	holder.offset_bottom = 104
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(holder)

	orb_panel = PanelContainer.new()
	orb_panel.visible = false
	orb_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(orb_panel)
	var box := VBoxContainer.new()
	orb_panel.add_child(box)
	orb_title = Label.new()
	orb_title.custom_minimum_size.x = 170
	orb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	orb_title.add_theme_font_size_override("font_size", 16)
	box.add_child(orb_title)
	orb_detail = Label.new()
	orb_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(orb_detail)

func _build_wager() -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(holder)
	wager = WagerPanel.new()
	holder.add_child(wager)

func _show_wave_banner() -> void:
	var label := Label.new()
	label.text = "WAVE %d / %d" % [GameManager.to_keep["current wave"], GameManager.total_waves]
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", GameTheme.GOLD)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	label.offset_top = 110
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(label, "modulate:a", 0.0, 0.8)
	tw.tween_callback(label.queue_free)

# ---------- อัปเดตทุกเฟรม ----------
func _process(_delta: float) -> void:
	if is_instance_valid(player):
		hp_bar.value = player.hp
		hp_label.text = "%d / %d" % [ceili(player.hp), roundi(GameManager.to_keep["max_hp"])]
	else:
		hp_bar.value = 0
		hp_label.text = "0"
	money_label.text = "$ %d" % roundi(GameManager.to_keep["money"])
	wave_label.text = "WAVE %d/%d    KILLS %d" % [GameManager.to_keep["current wave"], GameManager.total_waves, GameManager.to_keep["kill count"]]
	for id in buff_labels:
		var left : float = GameManager.luck.buff_left(id)
		buff_labels[id].text = "%s  %.1fs" % [str(id).to_upper(), left]

# ---------- Buff chips ----------
func _rebuild_buffs() -> void:
	for child in buff_box.get_children():
		child.queue_free()
	buff_labels.clear()
	for id in GameManager.luck.buffs:
		var l := Label.new()
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var bad : bool = (id == "curse")
		l.add_theme_color_override("font_color", GameTheme.BAD if bad else GameTheme.GOOD)
		buff_box.add_child(l)
		buff_labels[id] = l

# ---------- Lucky Orb ----------
func _on_orb_rolled(_outcome : Dictionary) -> void:
	if _orb_tween:
		_orb_tween.kill()
	orb_panel.visible = true
	orb_panel.modulate.a = 1.0
	orb_detail.text = ""
	orb_title.add_theme_color_override("font_color", GameTheme.ACCENT)
	var names : Array = GameManager.luck.outcome_names()
	_orb_tween = create_tween()
	for i in 10:
		_orb_tween.tween_callback(_spin_name.bind(names))
		_orb_tween.tween_interval(0.05 + i * 0.012)

func _spin_name(names : Array) -> void:
	orb_title.text = str(names.pick_random())

func _on_orb_applied(outcome : Dictionary, detail : String) -> void:
	if _orb_tween:
		_orb_tween.kill()
	var kind : int = int(outcome["kind"])
	var col : Color = GameTheme.MUTED
	if kind > 0:
		col = GameTheme.GOOD
	elif kind < 0:
		col = GameTheme.BAD
	orb_title.text = str(outcome["name"])
	orb_title.add_theme_color_override("font_color", col)
	orb_detail.text = detail
	_orb_tween = create_tween()
	_orb_tween.tween_interval(1.6)
	_orb_tween.tween_property(orb_panel, "modulate:a", 0.0, 0.4)
	_orb_tween.tween_callback(orb_panel.hide)

# ---------- Wave Wager ----------
func _on_wave_passed() -> void:
	# รอให้เหรียญสุดท้ายลอยเข้าตัวก่อน (connect กับ method ของ self -> ปลอดภัยถ้าฉากถูกปิดก่อน)
	get_tree().create_timer(1.4).timeout.connect(wager.open)

func _build_layers_box() -> void:
	layers_box = VBoxContainer.new()
	layers_box.position = Vector2(12, 56)   # ใต้เงิน ซ้ายมือ
	layers_box.add_theme_constant_override("separation", 0)
	layers_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(layers_box)

func _refresh_layers() -> void:
	for child in layers_box.get_children():
		child.queue_free()
	for slot in CrystalManager.SLOTS:
		var crystal : CrystalData = CrystalManager.layers[slot]
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 10)
		if crystal == null:
			l.text = "%d  -" % (slot + 1)
			l.add_theme_color_override("font_color", GameTheme.MUTED)
		else:
			l.text = "%d  %s +%d%%" % [slot + 1, GameTheme.nice(crystal.active_type), roundi(CrystalManager.active_value(slot) * 100.0)]
			l.add_theme_color_override("font_color", GameTheme.element_color(crystal.active_type))
		layers_box.add_child(l)
