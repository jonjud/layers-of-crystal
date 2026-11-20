extends CharacterBody2D
class_name Zombie

var speed : float = 60.0
var wiz : Node2D   # player
var hp : float
var max_hp : float = 1.0
var money : int = 30
var damage_amount : float = 60.0
var is_dead : bool = false   # กัน die() ถูกเรียกซ้ำ (กระสุนส่ง damage ทีละธาตุ)
var body_size : float = 32.0

# ตัวคูณจาก WaveData -- SpawnManager ตั้งก่อน add_child
var hp_mult : float = 1.0
var speed_mult : float = 1.0
var money_mult : float = 1.0

@export var coin_scene : PackedScene
@export var orb_scene : PackedScene       # Lucky Orb (ระบบ Gambling)
@export var zb_type : ZombieData

func _ready() -> void:
	zb_type = zb_type.duplicate(true)
	# [แก้บั๊ก] duplicate ไม่การันตีว่า Dictionary ถูกแยกสำเนา -> ซอมบี้จาก .tres เดียวกันจะใช้ resistances ร่วมกัน
	zb_type.resistances = zb_type.resistances.duplicate()
	max_hp = zb_type.max_health * hp_mult
	hp = max_hp
	speed = zb_type.speed * speed_mult
	damage_amount = zb_type.damage
	money = roundi(zb_type.money * money_mult)
	body_size = zb_type.size
	_apply_size()
	$ColorRect.color = zb_type.color
	add_to_group("zombie")
	wiz = get_tree().get_first_node_in_group("player")
	zb_type.random_type_of_resistance_and_assign_values()
	$HurtBox.body_entered.connect(_on_body_entered)
	queue_redraw()

# [แก้บั๊ก] เดิม field "size" ใน ZombieData ไม่เคยถูกใช้ ทุกตัวเลยตัวเท่ากัน 32px
func _apply_size() -> void:
	var half : float = body_size * 0.5
	var rect : ColorRect = $ColorRect
	rect.offset_left = -half
	rect.offset_top = -half
	rect.offset_right = half
	rect.offset_bottom = half
	# shape ใน .tscn เป็น sub-resource ที่ใช้ร่วมกันทุก instance -> ต้องสร้างใหม่
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(body_size, body_size)
	$CollisionShape2D.shape = body_shape
	var hurt_shape := RectangleShape2D.new()
	hurt_shape.size = Vector2(body_size + 1.0, body_size + 1.0)
	$HurtBox/CollisionShape2D.shape = hurt_shape

func _physics_process(delta: float) -> void:
	# [แก้บั๊ก] เดิมบวกแรงโน้มถ่วงโดยไม่คูณ delta (แรงกว่าจริง ~60 เท่า)
	velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	if is_instance_valid(wiz):
		var dir : Vector2 = (wiz.global_position - global_position).normalized()
		velocity.x = dir.x * speed * GameManager.luck.zombie_speed_multiplier()
	else:
		velocity.x = 0.0
	move_and_slide()

# แถบเลือด + จุดสีธาตุที่ต้านทาน (ต้าน >= 30%) -> ให้ผู้เล่นเลือก crystal ได้ถูกธาตุ
func _draw() -> void:
	if zb_type == null:
		return
	var half : float = body_size * 0.5
	var w : float = maxf(body_size, 24.0)
	var y : float = -half - 9.0
	draw_rect(Rect2(-w * 0.5, y, w, 4.0), Color(0, 0, 0, 0.65))
	draw_rect(Rect2(-w * 0.5, y, w * clampf(hp / max_hp, 0.0, 1.0), 4.0), GameTheme.BAD)
	var x : float = -w * 0.5
	for type in zb_type.resistances:
		var r : float = zb_type.resistances[type]
		if r >= 0.3:
			draw_rect(Rect2(x, y + 6.0, 5.0, 3.0), GameTheme.element_color(type))
			x += 7.0

# รับ damage ทีละธาตุ (เก็บไว้ให้โค้ดเก่า/Nova ใช้)
func damage(amount: float, type : String) -> void:
	if is_dead or amount < 0:
		return
	var final_damage : float = zb_type.calculate_recieved_damage(amount, type)
	hp = max(hp - final_damage, 0)
	queue_redraw()
	if hp <= 0:
		die()

# กระสุนโดน: รวมทุกธาตุเป็นหนึ่งครั้ง -> ตัวเลข damage ลอยเลขเดียว + lifesteal + flash
func hit(damages : Dictionary, crit : float) -> void:
	if is_dead:
		return
	var total : float = 0.0
	for type in damages:
		total += zb_type.calculate_recieved_damage(float(damages[type]) * crit, type)
	hp = maxf(hp - total, 0.0)
	queue_redraw()
	_flash()
	_popup(total, crit > 1.0)
	var steal : float = CrystalManager.lifesteal_rate()
	if steal > 0.0 and is_instance_valid(wiz) and wiz.has_method("heal"):
		wiz.heal(total * steal)
	if hp <= 0.0:
		die()

func _flash() -> void:
	modulate = Color(1.7, 1.7, 1.7)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.12)

func _popup(amount : float, is_crit : bool) -> void:
	var label := Label.new()
	label.text = str(roundi(amount)) + ("!" if is_crit else "")
	label.add_theme_font_size_override("font_size", 14 if is_crit else 10)
	label.add_theme_color_override("font_color", GameTheme.GOLD if is_crit else Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 50
	label.position = global_position + Vector2(randf_range(-10.0, 4.0), -body_size * 0.5 - 26.0)
	get_tree().current_scene.add_child(label)
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 22.0, 0.6)
	tw.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.2)
	tw.chain().tween_callback(label.queue_free)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	var total_gold : int = roundi(money * GameManager.total_gold_multiplier())
	# Piggybank / Boss = jackpot: ระเบิดเหรียญเป็นกอง
	var burst : int = 1
	if zb_type.zombie_type == ZombieData.ZombieTypes.PIGGYBANK or zb_type.zombie_type == ZombieData.ZombieTypes.BOSS:
		burst = 8
	var left : int = total_gold
	for i in burst:
		var coin : Coins = coin_scene.instantiate()
		coin.value = left if i == burst - 1 else total_gold / burst
		left -= coin.value
		coin.position = global_position + Vector2(randf_range(-14.0, 14.0), randf_range(-10.0, 4.0)) * (1.0 if burst > 1 else 0.0)
		get_tree().current_scene.call_deferred("add_child", coin)
	# Lucky Orb: โอกาสดรอป (Piggybank การันตี)
	if orb_scene != null:
		var guaranteed : bool = zb_type.zombie_type == ZombieData.ZombieTypes.PIGGYBANK
		if GameManager.luck.roll_orb_drop() or guaranteed:
			var orb : Node2D = orb_scene.instantiate()
			orb.position = global_position + Vector2(0.0, -12.0)
			get_tree().current_scene.call_deferred("add_child", orb)
	SignalBus.zombie_died.emit()
	queue_free()

func _on_body_entered(body : Node2D) -> void:
	if is_dead:
		return
	if body.is_in_group("player"):
		if body.has_method("damage"):
			body.damage(damage_amount)
			queue_free()
