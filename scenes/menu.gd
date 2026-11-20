extends Control


const MAIN_SCENE : String = "res://scenes/main.tscn"
const GAME_TITLE : String = "LAYERS OF CRYSTAL"   # แก้เป็นชื่อเกม

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)

	var title := Label.new()
	title.text = GAME_TITLE
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var start := Button.new()
	start.text = "New Game"
	start.pressed.connect(_on_new_game_pressed)
	box.add_child(start)

func _on_new_game_pressed() -> void:
	GameManager.reset_all()   # ล้างเงิน, wave, modifier, กองคริสตัลของรอบเก่า
	get_tree().change_scene_to_file(MAIN_SCENE)
