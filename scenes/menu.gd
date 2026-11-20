extends Control
# เมนูหลัก 640x360 : ชื่อเกม + "Free Lucky Spin" 1 ครั้ง (โบนัสเริ่มเกม) + New Game

const MAIN_SCENE : String = "res://scenes/main.tscn"
const GAME_TITLE : String = "LAYERS OF CRYSTAL"

var machine : SlotMachine
var spin_button : Button
var new_button : Button
var prize_label : Label
var _spun : bool = false
var _pending : Array = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = GameTheme.BG
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_add_floating_gems()

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	center.add_child(box)

	var title := Label.new()
	title.text = GAME_TITLE
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", GameTheme.GOLD)
	title.add_theme_color_override("font_outline_color", GameTheme.ACCENT.darkened(0.4))
	title.add_theme_constant_override("outline_size", 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var sub := Label.new()
	sub.text = "stack crystals  -  spin the reels  -  survive the horde"
	sub.add_theme_color_override("font_color", GameTheme.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	# กล่อง Free Lucky Spin
	var panel := PanelContainer.new()
	box.add_child(panel)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)

	var spin_title := Label.new()
	spin_title.text = "FREE LUCKY SPIN  -  win a starting bonus"
	spin_title.add_theme_color_override("font_color", GameTheme.ACCENT.lightened(0.4))
	spin_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(spin_title)

	machine = SlotMachine.new(46)
	machine.alignment = BoxContainer.ALIGNMENT_CENTER
	machine.finished.connect(_on_spin_finished)
	inner.add_child(machine)

	prize_label = Label.new()
	prize_label.text = "Pair = +$150   Triple = +$300 and a free crystal"
	prize_label.add_theme_color_override("font_color", GameTheme.MUTED)
	prize_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(prize_label)

	spin_button = Button.new()
	spin_button.text = "SPIN"
	spin_button.custom_minimum_size = Vector2(0, 28)
	spin_button.pressed.connect(_on_spin_pressed)
	inner.add_child(spin_button)

	new_button = Button.new()
	new_button.text = "NEW GAME"
	new_button.custom_minimum_size = Vector2(0, 34)
	new_button.add_theme_font_size_override("font_size", 14)
	new_button.add_theme_color_override("font_color", GameTheme.GOLD)
	new_button.pressed.connect(_on_new_game_pressed)
	box.add_child(new_button)

# อัญมณีลอยเบาๆ เป็นพื้นหลัง
func _add_floating_gems() -> void:
	for i in 12:
		var gem := SymbolIcon.new(randi_range(18, 34))
		gem.symbol = randi() % 5
		gem.modulate.a = 0.18
		gem.position = Vector2(randf_range(10.0, 600.0), randf_range(10.0, 320.0))
		add_child(gem)
		var base_y : float = gem.position.y
		var tw := gem.create_tween().set_loops()
		var d : float = randf_range(1.8, 3.2)
		tw.tween_property(gem, "position:y", base_y - 10.0, d).set_trans(Tween.TRANS_SINE)
		tw.tween_property(gem, "position:y", base_y + 10.0, d).set_trans(Tween.TRANS_SINE)

func _on_spin_pressed() -> void:
	if _spun:
		return
	_spun = true
	spin_button.disabled = true
	new_button.disabled = true   # กันกดเริ่มเกมก่อนผลออก (โบนัสจะหาย)
	prize_label.text = "..."
	_pending = SlotLogic.roll(0.0)
	machine.spin(_pending)

func _on_spin_finished() -> void:
	var bonus : Dictionary = SlotLogic.start_bonus(_pending)
	GameManager.pending_bonus = bonus
	prize_label.text = str(bonus["text"])
	prize_label.add_theme_color_override("font_color", GameTheme.GOOD)
	spin_button.text = "USED"
	new_button.disabled = false

func _on_new_game_pressed() -> void:
	GameManager.reset_all()   # ล้างเงิน, wave, modifier, กองคริสตัลของรอบเก่า + ใส่โบนัสจากสล็อต
	get_tree().change_scene_to_file(MAIN_SCENE)
