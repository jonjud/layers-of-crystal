extends CharacterBody2D
class_name Zombie

var speed : float = 60.0
var wiz : Node2D #player

var hp : float
var max_hp : float = 600.0
var money : int = 30

var damage_amount : float = 60.0
@export var coin_scene : PackedScene

@export var zb_type : ZombieData

func _ready() -> void:
	zb_type = zb_type.duplicate(true)
	hp = zb_type.max_health
	add_to_group("zombie")
	wiz = get_tree().get_first_node_in_group("player")
	zb_type.random_type_of_resistance_and_assign_values()
	$HurtBox.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity")
	if wiz:
		var dir : Vector2 = (wiz.global_position - global_position).normalized()
		velocity.x = dir.x * speed
	else:
		velocity.x = 0 * speed
	
	move_and_slide()

func damage(amount: float , type : String) -> void:
	if amount < 0:
		return
	var final_damage : float = zb_type.calculate_recieved_damage(amount ,type)
	hp = max(hp- final_damage,0)
	print("hp : ",hp," / ", max_hp)
	if hp  <= 0:
		die()

func die() -> void:
	var coin : Coins = coin_scene.instantiate()
	coin.value = money
	coin.position = global_position
	get_tree().current_scene.call_deferred("add_child",coin)
	SignalBus.zombie_died.emit()
	queue_free()

func _on_body_entered(body : Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("damage"):
			body.damage(damage_amount)
			self.queue_free()
