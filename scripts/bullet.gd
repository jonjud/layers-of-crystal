extends Node2D
class_name Bullet

var speed : float = 300.0

func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT * speed * delta
