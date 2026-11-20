extends CharacterBody2D
class_name Zombie

var speed : float = 60.0
var wiz : Node2D   # player
var hp : float
var money : int = 30
var damage_amount : float = 60.0
var is_dead : bool = false   # กัน die() ถูกเรียกซ้ำ (กระสุนส่ง damage ทีละธาตุ)

@export var coin_scene : PackedScene
@export var zb_type : ZombieData

func _ready() -> void:
	zb_type = zb_type.duplicate(true)
	hp = zb_type.max_health
	speed = zb_type.speed
	damage_amount = zb_type.damage
	money = zb_type.money
	$ColorRect.color = zb_type.color
	add_to_group("zombie")
	wiz = get_tree().get_first_node_in_group("player")
	zb_type.random_type_of_resistance_and_assign_values()
	$HurtBox.body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity")
	if is_instance_valid(wiz):
		var dir : Vector2 = (wiz.global_position - global_position).normalized()
		velocity.x = dir.x * speed
	else:
		velocity.x = 0.0
	move_and_slide()

func damage(amount: float, type : String) -> void:
	if is_dead or amount < 0:
		return
	var final_damage : float = zb_type.calculate_recieved_damage(amount, type)
	hp = max(hp - final_damage, 0)
	if hp <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	var coin : Coins = coin_scene.instantiate()
	coin.value = roundi(money * CrystalManager.gold_multiplier())
	coin.position = global_position
	get_tree().current_scene.call_deferred("add_child", coin)
	SignalBus.zombie_died.emit()
	queue_free()

func _on_body_entered(body : Node2D) -> void:
	if is_dead:
		return
	if body.is_in_group("player"):
		if body.has_method("damage"):
			body.damage(damage_amount)
			queue_free()
