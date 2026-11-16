extends Area2D
class_name Coins

var wiz : Node2D
var value : int
var speed : float = 300.0

func _ready() -> void:
	wiz = get_tree().get_first_node_in_group("player")
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if wiz:
		var dir : Vector2 = (wiz.global_position - global_position).normalized()
		position += dir * speed * delta

func _on_body_entered(body : Node2D) -> void:
	if body == wiz:
		if body.has_method("add_money"):
			body.add_money(value)
			call_deferred("queue_free")
