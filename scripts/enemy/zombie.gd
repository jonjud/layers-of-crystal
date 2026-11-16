extends CharacterBody2D

var speed : float = 60.0
var wiz : Node2D

var hp : float
var max_hp : float = 100.0

var damage_amount : float = 60.0


func _ready() -> void:
	hp = max_hp
	add_to_group("zombie")
	wiz = get_tree().get_first_node_in_group("player")
	$HurtBox.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity")
	if wiz:
		var dir : Vector2 = (wiz.global_position - global_position).normalized()
		velocity.x = dir.x * speed
	else:
		velocity.x = 0 * speed
	
	move_and_slide()

func damage(amount: float) -> void:
	if amount < 0:
		return
	hp = max(hp-amount,0)
	print("hp : ",hp," / ", max_hp)
	if hp  <= 0:
		die()

func die() -> void:
	SignalBus.zombie_died.emit()
	queue_free()

func _on_body_entered(body : Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("damage"):
			body.damage(damage_amount)
			self.queue_free()
