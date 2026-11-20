extends Control


const MENU_SCENE : String = "res://scenes/menu.tscn"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color.WHITE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)

	var label := Label.new()
	label.text = "Thank you for playing"
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)

	var stats := Label.new()
	stats.text = "Kills: %d     Crystals owned: %d" % [GameManager.to_keep["kill count"], CrystalManager.owned.size()]
	stats.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(stats)

	var button := Button.new()
	button.text = "Main Menu"
	button.disabled = true
	button.pressed.connect(_on_menu_pressed)
	box.add_child(button)

	# ข้อความค่อยๆ ปรากฏบนพื้นขาว แล้วค่อยเปิดให้กดปุ่มได้
	box.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(box, "modulate:a", 1.0, 1.5)
	tween.tween_callback(func(): button.disabled = false)

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
