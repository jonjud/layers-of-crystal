extends Node

# ข้อมูลที่ต้องรอดข้ามฉาก (main <-> shop)
var to_keep : Dictionary = {}

# ค่า Damage พื้นฐานของแต่ละประเภท ก่อนนำ Modifier มาคำนวณ
var base_damages : Dictionary = {
	"physical damage" : 10,
	"fire damage" : 5,
	"wind damage" : 5,
	"water damage" : 5,
	"earth damage" : 5,
	"light damage" : 5,
	"darkness damage" : 5,
}

# modifier ของ damage: type -> { source: percent }  (คูณกัน)
var mods : Dictionary = {
	"physical damage" : {},
	"fire damage" : {},
	"wind damage" : {},
	"water damage" : {},
	"earth damage" : {},
	"light damage" : {},
	"darkness damage" : {},
}

# damage จริงหลังคิด modifier (ถูกคำนวณใหม่ใน update_all_damage)
var true_damages : Dictionary = {}

# สร้าง Dictionary ของค่าตั้งต้นที่ต้องเก็บไว้ระหว่างเปลี่ยนฉากหรือเริ่มเกม
func _default_keep() -> Dictionary:
	return {
		"max_hp" : 100.0,
		"max_mana" : 50.0,
		"money" : 0.0,
		"kill count" : 0,
		"current wave" : 1,
	}

# ตั้งค่าเริ่มต้นและเชื่อม Signal ที่ GameManager ต้องรับรู้
func _ready() -> void:
	to_keep = _default_keep()
	SignalBus.zombie_died.connect(_on_zombie_died)
	SignalBus.money_added.connect(_on_money_added)
	SignalBus.wave_passed.connect(_on_wave_passed)
	# สำคัญ: ให้ true_damages มีค่าตั้งแต่ก่อนมี modifier ตัวแรก
	# (ไม่งั้นกระสุนจะได้ damage 0 จนกว่าจะมีใครเรียก add_modifier)
	update_all_damage()

# รีเซ็ตข้อมูลเกม, Modifier และ Crystal เมื่อเริ่มเกมใหม่
func reset_all() -> void:
	to_keep = _default_keep()
	for type in mods:
		mods[type].clear()
	update_all_damage()
	CrystalManager.reset()

# เพิ่มจำนวน Zombie ที่กำจัดได้
func _on_zombie_died() -> void:
	to_keep["kill count"] += 1

# เพิ่มเงินให้ผู้เล่นตามจำนวนที่ได้รับ
func _on_money_added(amount : int) -> void:
	to_keep["money"] += amount

# เพิ่มเลข Wave เมื่อผ่าน Wave ปัจจุบัน
func _on_wave_passed() -> void:
	to_keep["current wave"] += 1

# คำนวณ Damage ของประเภทที่ระบุ โดยนำ Modifier ของแต่ละแหล่งมาคูณต่อกัน
func calculate_damage(type : String) -> float:
	if not base_damages.has(type):
		return 0.0
	var result : float = base_damages[type]
	for source in mods[type]:
		result *= (1.0 + mods[type][source])
	return result

# คำนวณ Damage จริงใหม่ให้ครบทุกประเภท แล้วเก็บไว้ใน true_damages
func update_all_damage() -> void:
	for type in base_damages:
		true_damages[type] = calculate_damage(type)

# เพิ่มหรือแทนที่ Modifier ของ Damage ตามประเภทและแหล่งที่มา
func add_modifier(type : String, source : String, percent : float) -> void:
	if not mods.has(type):
		return
	mods[type][source] = percent
	update_all_damage()

# ลบ Modifier ของแหล่งที่มาที่ระบุ แล้วคำนวณ Damage ใหม่
func remove_modifier(type : String, source : String) -> void:
	if not mods.has(type):
		return
	mods[type].erase(source)
	update_all_damage()
