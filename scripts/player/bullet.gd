extends Area2D
class_name Bullet

# ความเร็วในการเคลื่อนที่ของกระสุน
var speed : float = 300.0
# ตัวแปรเก็บค่าความเสียหาย (ในไฟล์นี้ยังไม่ได้ถูกนำไปใช้)
var damage : float
# เก็บ reference ของ Player ที่อยู่ใน group "player"
var player : Node2D
# เก็บ reference ของ Zombie ที่อยู่ใน group "zombie"
var zombie : Node2D
# เก็บทิศทางจากกระสุนไปยัง Zombie
var dir : Vector2

# เชื่อมสัญญาณชน ค้นหา Player/Zombie และตั้งเวลาให้กระสุนหายไป
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player")
	zombie = get_tree().get_first_node_in_group("zombie")
	get_tree().create_timer(6.0).timeout.connect(queue_free)

# เคลื่อนที่ไปทาง Zombie ถ้ายังมีอยู่ และเคลื่อนที่ไปทางขวาด้วยทุกครั้ง
func _physics_process(delta: float) -> void:
	if is_instance_valid(zombie):
		dir = (zombie.global_position - global_position).normalized()
		position += dir * speed * delta
	position += Vector2.RIGHT * speed * delta

# เมื่อชนวัตถุ ถ้าเป็น Zombie จะคำนวณคริติคอลและส่งค่าความเสียหายให้
func _on_body_entered(body : Node2D) -> void:
	if body.is_in_group("zombie"):
		if body.has_method("damage"):
			# สุ่มตัวคูณความเสียหายคริติคอล
			var crit : float = CrystalManager.roll_crit_multiplier()
			# วนส่งความเสียหายแต่ละประเภทที่ GameManager เก็บไว้
			for type in GameManager.true_damages:
				body.damage(GameManager.true_damages[type] * crit, type)
			queue_free()
