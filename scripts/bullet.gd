extends Area2D
class_name Bullet

var speed : float = 300.0
var damage : float = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT * speed * delta

func _on_body_entered(body : Node2D) -> void:
	if body.is_in_group("zombie"):
		if body.has_method("damage"):
			body.damage(damage)
