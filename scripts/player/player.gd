extends CharacterBody2D

var stats : Dictionary = {
	"max_hp" : 100.0,
	"mana" : 50,
	"money" : 0,
}

var base_damages : Dictionary = {
	"physical damage" : 10,
	"fire damage" : 5,
	"wind damage" : 5,
	"water damage" : 5,
	"earth damage" : 5,
	"light damage" : 5,
	"darkness damage" : 5,
}

var hp : float

func _ready() -> void:
	hp = stats["max_hp"]
	add_to_group("player")
	for i in stats:
		print(i ,stats[i])

func add_money(amount : int) -> void:
	if amount < 0:
		return
	stats["money"] += amount

func remove_money(amount : int) -> void:
	if amount < 0:
		return
	if stats["money"] < amount:
		return
	stats["money"] = max(stats["money"] - amount,0)

func damage(amount : int) -> void:
	if amount < 0:
		return
	hp = max(hp - amount,0)
	print("player hp : ",hp)
	if hp <= 0:
		die()

func die() -> void:
	SignalBus.player_died.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			SignalBus.fire_pressed.emit()


func _physics_process(delta: float) -> void:
	velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	move_and_slide()
