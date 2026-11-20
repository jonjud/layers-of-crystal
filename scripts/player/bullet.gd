extends Area2D
class_name Bullet

var speed : float = 300.0
var damage : float
var player : Node2D
var zombie : Node2D
var dir : Vector2

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player")
	zombie = _pick_target()
	get_tree().create_timer(6.0).timeout.connect(queue_free)

# ซอมบี้ที่อยู่ใกล้กระสุนที่สุด (เดิมเลือก "ตัวแรกในกลุ่ม" และไม่เปลี่ยนเป้าแม้ตัวนั้นตายแล้ว)
func _pick_target() -> Node2D:
	var best : Node2D = null
	var best_dist : float = INF
	for z in get_tree().get_nodes_in_group("zombie"):
		if not is_instance_valid(z):
			continue
		var d : float = global_position.distance_squared_to(z.global_position)
		if d < best_dist:
			best_dist = d
			best = z
	return best

func _physics_process(delta: float) -> void:
	if not is_instance_valid(zombie):
		zombie = _pick_target()   # เป้าตาย -> หาเป้าใหม่
	if is_instance_valid(zombie):
		dir = (zombie.global_position - global_position).normalized()
		position += dir * speed * delta
	position += Vector2.RIGHT * speed * delta

func _on_body_entered(body : Node2D) -> void:
	if body.is_in_group("zombie"):
		var crit : float = CrystalManager.roll_crit_multiplier()
		if body.has_method("hit"):
			body.hit(GameManager.true_damages, crit)
		elif body.has_method("damage"):
			for type in GameManager.true_damages:
				body.damage(GameManager.true_damages[type] * crit, type)
		queue_free()
