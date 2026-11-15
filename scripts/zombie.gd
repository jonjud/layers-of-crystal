extends CharacterBody2D

var speed : float = 60.0
var wiz : Node2D

var hp : float = 5.0

func _ready() -> void:
	add_to_group("zombie")
	wiz = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity")
	var dir : Vector2 = (wiz.global_position - global_position).normalized()
	velocity.x = dir.x * speed
	move_and_slide()

func damage(amount: float) -> void:
	if amount < 0:
		return
	hp = max(hp-amount,0)
	print("hp : ",hp," / 5")
	if hp  <= 0:
		die()

func die() -> void:
	queue_free()
	
