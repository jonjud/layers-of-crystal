extends CharacterBody2D

# สถานะปัจจุบันของผู้เล่น
var hp : float
var mana : float


# ทำงานครั้งเดียวเมื่อ Player ถูกสร้างและเข้าสู่ Scene Tree
func _ready() -> void:
	# HP ไม่ข้าม wave: เริ่มทุก wave ด้วยเลือดเต็ม
	hp = GameManager.to_keep["max_hp"]
	mana = GameManager.to_keep["max_mana"]
	# เพิ่ม Player เข้า Group เพื่อให้ระบบอื่นค้นหา Player ได้ด้วยชื่อ Group
	add_to_group("player")


# เพิ่มเงินให้ผู้เล่น โดยส่ง Signal ไปให้ระบบที่รับผิดชอบอัปเดตเงินจริง
# amount: จำนวนเงินที่ต้องการเพิ่ม
func add_money(amount : int) -> void:
	# ไม่รับจำนวนเงินติดลบ
	if amount < 0:
		return
	SignalBus.money_added.emit(amount)


# หักเงินจากผู้เล่น
# amount: จำนวนเงินที่ต้องการหัก
func remove_money(amount : int) -> void:
	# ไม่อนุญาตให้หักจำนวนเงินติดลบ
	if amount < 0:
		return
	# ถ้าเงินที่มีไม่พอ จะไม่ทำรายการ
	if GameManager.to_keep["money"] < amount:
		return
	# หักเงินและป้องกันไม่ให้ยอดเงินต่ำกว่า 0
	GameManager.to_keep["money"] = max(GameManager.to_keep["money"] - amount, 0)


# ทำให้ Player ได้รับ Damage
# amount: จำนวน Damage ก่อนนำโบนัส Defense มาคำนวณ
func damage(amount : float) -> void:
	# ไม่รับ Damage ติดลบ และไม่ทำอะไรถ้า Player ตายแล้ว
	if amount < 0 or hp <= 0:
		return
	# ให้ CrystalManager ลด Damage ตามค่า Defense ของ Crystal ที่สวมใส่
	amount = CrystalManager.reduce_damage(amount)   # Defense
	# ลด HP และป้องกันไม่ให้ HP ต่ำกว่า 0
	hp = max(hp - amount, 0)
	# ถ้า HP หมด ให้เรียกขั้นตอนการตาย
	if hp <= 0:
		die()


# จัดการเมื่อ Player ตาย
func die() -> void:
	# แจ้งระบบอื่นว่า Player ตายแล้ว เช่น ระบบที่แสดงหน้า Game Over
	SignalBus.player_died.emit()
	# ลบ Node ของ Player ออกจาก Scene
	queue_free()


# รับ Input ที่ยังไม่มี Control Node อื่นจัดการ
func _unhandled_input(event: InputEvent) -> void:
	# สนใจเฉพาะ Event ประเภทการกดปุ่มเมาส์
	if event is InputEventMouseButton:
		# เมื่อกดปุ่มเมาส์ซ้าย ให้ส่ง Signal เพื่อให้ระบบอาวุธเริ่มยิง
		if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			SignalBus.fire_pressed.emit()


# ทำงานทุก Frame ใช้จัดการการฟื้นฟู HP
func _process(delta: float) -> void:
	# HP Regen: อ่านค่า HP สูงสุดที่กำหนดไว้ใน GameManager
	var max_hp : float = GameManager.to_keep["max_hp"]
	# ฟื้นฟูเฉพาะตอนที่ Player ยังมีชีวิตและ HP ยังไม่เต็ม
	if hp > 0 and hp < max_hp:
		# เพิ่ม HP ตามอัตราฟื้นฟูต่อวินาทีคูณเวลาที่ผ่านไป
		# min() ช่วยจำกัดไม่ให้ HP เกินค่า max_hp
		hp = min(hp + CrystalManager.regen_per_second() * delta, max_hp)


# ทำงานในรอบ Physics ของ Godot
func _physics_process(delta : float) -> void:
	# เพิ่มความเร็วแนวดิ่งจากแรงโน้มถ่วงของโปรเจกต์
	velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	# เคลื่อนที่ตาม velocity และจัดการการชนตามระบบ CharacterBody2D
	move_and_slide()
