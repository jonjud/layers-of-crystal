extends Control


# เส้นทางฉากเมนูหลักที่ใช้กลับไปหลังจบเกม
const MENU_SCENE : String = "res://scenes/menu.tscn"

# สร้างฉากจบด้วยพื้นหลังสีขาว ข้อความขอบคุณ และปุ่มกลับเมนู
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# สร้างพื้นหลังสีขาวให้เต็มพื้นที่ของหน้าจอ
	var bg := ColorRect.new()
	bg.color = Color.WHITE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# วางกลุ่ม UI ไว้กึ่งกลางหน้าจอ
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)

	# แสดงข้อความขอบคุณผู้เล่นด้วยตัวอักษรสีดำ
	var label := Label.new()
	label.text = "Thank you for playing"
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)

	# สร้างปุ่มกลับเมนู โดยปิดการใช้งานไว้จนกว่า Animation จะจบ
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

# เปลี่ยนจากฉากจบกลับไปยังหน้าเมนูหลักเมื่อกดปุ่ม
func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
