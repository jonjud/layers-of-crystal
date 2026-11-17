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
	zombie = get_tree().get_first_node_in_group("zombie")

func _physics_process(delta: float) -> void:
	if zombie:
		dir = (zombie.global_position - global_position).normalized()
		position += dir * speed * delta
	position += Vector2.RIGHT * speed * delta

func _on_body_entered(body : Node2D) -> void:
	if body.is_in_group("zombie"):
		if body.has_method("damage"):
			for i in GameManager.true_damages:
				body.damage(GameManager.true_damages[i],i)
			queue_free()
