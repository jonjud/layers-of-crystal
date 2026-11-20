extends CharacterBody2D
class_name Zombie

# ความเร็วในการเคลื่อนที่ของ Zombie
var speed : float = 60.0
# เก็บ reference ของผู้เล่นที่ Zombie จะเดินเข้าหา
var wiz : Node2D   # player
# พลังชีวิตปัจจุบันของ Zombie
var hp : float
# เงินพื้นฐานที่จะดรอปเมื่อตาย
var money : int = 30
# ความเสียหายที่ Zombie สร้างให้ Player เมื่อสัมผัสกัน
var damage_amount : float = 60.0
# ป้องกันไม่ให้ die() ทำงานซ้ำ เมื่อได้รับ Damage หลายประเภท
var is_dead : bool = false   # กัน die() ถูกเรียกซ้ำ (กระสุนส่ง damage ทีละธาตุ)

# Scene ของเหรียญที่จะสร้างเมื่อ Zombie ตาย
@export var coin_scene : PackedScene
# Resource ที่เก็บค่าต่าง ๆ ของ Zombie ประเภทนี้
@export var zb_type : ZombieData

# เตรียมค่าสถานะจาก ZombieData และเชื่อมการตรวจจับการชน
func _ready() -> void:
	# ทำสำเนา Resource เพื่อให้ Zombie ตัวนี้มีข้อมูลของตัวเอง
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

# เคลื่อนที่เข้าหาผู้เล่น โดยใช้แรงโน้มถ่วงในแนวแกน Y
func _physics_process(_delta: float) -> void:
	velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity")
	if is_instance_valid(wiz):
		var dir : Vector2 = (wiz.global_position - global_position).normalized()
		velocity.x = dir.x * speed
	else:
		velocity.x = 0.0
	move_and_slide()

# รับความเสียหาย โดยคำนวณค่าที่เหลือหลังหักผลจาก Resistance
func damage(amount: float, type : String) -> void:
	if is_dead or amount < 0:
		return
	var final_damage : float = zb_type.calculate_recieved_damage(amount, type)
	hp = max(hp - final_damage, 0)
	if hp <= 0:
		die()

# จัดการการตาย สร้างเหรียญตามตัวคูณเงิน และแจ้งระบบว่า Zombie ตายแล้ว
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

# เมื่อ HurtBox ชน Player จะสร้างความเสียหายให้ Player แล้วลบ Zombie
func _on_body_entered(body : Node2D) -> void:
	if is_dead:
		return
	if body.is_in_group("player"):
		if body.has_method("damage"):
			body.damage(damage_amount)
			queue_free()
