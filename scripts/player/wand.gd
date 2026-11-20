extends Node2D

# Scene ของกระสุนที่จะสร้างเมื่อผู้เล่นโจมตี
@export var bullet_scene : PackedScene
# เก็บตำแหน่งแกน Y เดิมของไม้กายสิทธิ์ไว้ใช้ตอนเล่นแอนิเมชัน
var original_y : float

# เชื่อม Signal สำหรับการยิง และจำตำแหน่งเริ่มต้นของไม้กายสิทธิ์
func _ready() -> void:
	SignalBus.fire_pressed.connect(_on_fire_pressed)
	original_y = position.y

# ทำให้ไม้กายสิทธิ์ขยับขึ้นลง แล้วสร้างกระสุนออกมา
func _on_fire_pressed() -> void:
	# สร้าง Tween เพื่อขยับไม้กายสิทธิ์ขึ้นเล็กน้อย แล้วกลับตำแหน่งเดิม
	var tw : Tween = create_tween()
	
	tw.tween_property(self, "position:y", original_y - 5 , 0.2)
	tw.tween_property(self, "position:y", original_y , 0.3)
	
	
	# สร้างกระสุนจาก PackedScene และวางไว้ตรงตำแหน่งของไม้กายสิทธิ์
	var bullet : Bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	get_tree().current_scene.add_child(bullet)
