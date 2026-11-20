extends CharacterBody2D

var hp : float
var mana : float

func _ready() -> void:
	# HP ไม่ข้าม wave: เริ่มทุก wave ด้วยเลือดเต็ม
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
	GameManager.to_keep["money"] = max(GameManager.to_keep["money"] - amount, 0)

func damage(amount : float) -> void:
	if amount < 0 or hp <= 0:
		return
	amount = CrystalManager.reduce_damage(amount)   # Defense
	hp = max(hp - amount, 0)
	if hp <= 0:
		die()

func die() -> void:
	SignalBus.player_died.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			SignalBus.fire_pressed.emit()

func _process(delta: float) -> void:
	# HP Regen
	var max_hp : float = GameManager.to_keep["max_hp"]
	if hp > 0 and hp < max_hp:
		hp = min(hp + CrystalManager.regen_per_second() * delta, max_hp)

func _physics_process(delta: float) -> void:
	velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	move_and_slide()
