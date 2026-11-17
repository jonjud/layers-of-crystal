extends CharacterBody2D

var hp : float
var mana : float

func _ready() -> void:
	hp = GameManager.to_keep["max_hp"]
	mana = GameManager.to_keep["max_mana"]
	add_to_group("player")
	

func add_money(amount : int) -> void:
	if amount < 0:
		return
	SignalBus.money_added.emit(amount)

func remove_money(amount : int) -> void:
	if amount < 0:
		return
	if GameManager.to_keep["money"] < amount:
		return
	GameManager.to_keep["money"] = max(GameManager.to_keep["money"] - amount,0)

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
