extends Node2D

@export var bullet_scene : PackedScene

const BASE_COOLDOWN : float = 0.40   # วินาที/นัด (Gale Rune / "fire rate" ลดค่านี้)

var original_y : float
var holding : bool = false
var cooldown_left : float = 0.0

func _ready() -> void:
	SignalBus.fire_pressed.connect(_on_fire_pressed)
	original_y = position.y

# กดค้างเพื่อยิงต่อเนื่อง (เดิมต้องรัวคลิก = DPS ขึ้นกับความเร็วนิ้ว balance ไม่ได้)
func _on_fire_pressed() -> void:
	holding = true

func _process(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	# เช็คปุ่มจริงทุกเฟรม -> ปล่อยเมาส์ตรงไหน (แม้บนปุ่ม UI) ก็หยุดยิงแน่นอน
	if holding and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		holding = false
	if holding and cooldown_left <= 0.0:
		_fire()

func _fire() -> void:
	cooldown_left = BASE_COOLDOWN / CrystalManager.fire_rate_multiplier()
	var tw : Tween = create_tween()
	tw.tween_property(self, "position:y", original_y - 5 , minf(0.2, cooldown_left * 0.4))
	tw.tween_property(self, "position:y", original_y , minf(0.3, cooldown_left * 0.6))

	var bullet : Bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	get_tree().current_scene.add_child(bullet)
