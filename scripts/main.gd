extends Node2D

# เส้นทางฉากร้านค้าและฉากจบของเกม
const SHOP_SCENE : String = "res://scenes/shop.tscn"
const ENDING_SCENE : String = "res://scenes/ending.tscn"

# ซ่อนปุ่มเข้าร้านและเชื่อมสัญญาณเมื่อผ่าน Wave หรือผ่าน Level
func _ready() -> void:
	$GoShopButton.hide()
	SignalBus.wave_passed.connect(_on_wave_passed)
	SignalBus.level_passed.connect(_on_level_passed)

# แสดงปุ่มเข้าร้านเมื่อผ่าน Wave
func _on_wave_passed() -> void:
	$GoShopButton.show()

# wave สุดท้าย: fade จอเป็นสีขาว แล้วไปฉากจบ (ฉากจบเริ่มด้วยพื้นขาวต่อกันพอดี)
# สร้าง CanvasLayer และ ColorRect สำหรับทำภาพ Fade จากโปร่งใสเป็นสีขาว ก่อนเปลี่ยนฉาก
func _on_level_passed() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var white := ColorRect.new()
	white.color = Color(1, 1, 1, 0)
	layer.add_child(white)
	white.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(white, "color:a", 1.0, 2.0)
	await tween.finished
	get_tree().change_scene_to_file(ENDING_SCENE)

# เปลี่ยนจากฉากเกมหลักไปยังฉากร้านค้าเมื่อกดปุ่ม Go Shop
func _on_go_shop_button_button_down() -> void:
	get_tree().change_scene_to_file(SHOP_SCENE)
