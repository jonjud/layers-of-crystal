extends Node

# ข้อมูลที่ต้องรอดข้ามฉาก (main <-> shop)
var to_keep : Dictionary = {}

# ระบบ Gambling (สร้างเป็นลูกของ autoload นี้ ไม่ต้องแก้ project.godot)
var luck : LuckManager
# โบนัสเริ่มเกมจากสล็อตฟรีหน้าเมนู (ถูกใช้ตอน reset_all)
var pending_bonus : Dictionary = {}
# จำนวน wave ทั้งหมด (SpawnManager ตั้งให้ตอนเริ่มฉาก)
var total_waves : int = 8

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

func _default_keep() -> Dictionary:
	return {
		"max_hp" : 100.0,
		"max_mana" : 50.0,
		"money" : 0.0,
		"kill count" : 0,
		"current wave" : 1,
		"wave start money" : 0.0,   # ไว้คำนวณกำไรของ wave สำหรับ Wager
	}

func _ready() -> void:
	to_keep = _default_keep()
	luck = LuckManager.new()
	luck.name = "LuckManager"
	add_child(luck)
	SignalBus.zombie_died.connect(_on_zombie_died)
	SignalBus.money_added.connect(_on_money_added)
	SignalBus.wave_passed.connect(_on_wave_passed)
	# สำคัญ: ให้ true_damages มีค่าตั้งแต่ก่อนมี modifier ตัวแรก
	# (ไม่งั้นกระสุนจะได้ damage 0 จนกว่าจะมีใครเรียก add_modifier)
	update_all_damage()
	# INJECT THEME: ตั้งที่ root window -> ทุก Control ในเกม (menu/shop/hud/...) ใช้ธีมนี้
	get_tree().root.theme = GameTheme.build()

# เรียกตอนเริ่มทุก wave (main._ready) -- รวมถึงตอน Restart หลังตาย
func begin_wave() -> void:
	to_keep["wave start money"] = to_keep["money"]
	luck.reset_wave()

# ปุ่ม New Game เรียกอันนี้ (Autoload ไม่ถูกรีเซ็ตเองตอนเปลี่ยนฉาก)
func reset_all() -> void:
	to_keep = _default_keep()
	for type in mods:
		mods[type].clear()
	update_all_damage()
	CrystalManager.reset()
	luck.reset_all()
	_apply_start_bonus()

func _apply_start_bonus() -> void:
	if pending_bonus.is_empty():
		return
	to_keep["money"] += float(pending_bonus.get("gold", 0))
	to_keep["max_hp"] += float(pending_bonus.get("max_hp", 0))
	if pending_bonus.get("free_crystal", false):
		var list : Array[CrystalData] = CrystalCatalog.all()
		if not list.is_empty():
			CrystalManager.grant(list.pick_random(), 2)
	pending_bonus = {}

func _on_zombie_died() -> void:
	to_keep["kill count"] += 1

func _on_money_added(amount : int) -> void:
	to_keep["money"] += amount

func _on_wave_passed() -> void:
	to_keep["current wave"] += 1

# ตัวคูณเงินรวม: crystal (Gold) x buff Midas
func total_gold_multiplier() -> float:
	return CrystalManager.gold_multiplier() * luck.gold_buff_multiplier()

func calculate_damage(type : String) -> float:
	if not base_damages.has(type):
		return 0.0
	var result : float = base_damages[type]
	for source in mods[type]:
		result *= (1.0 + mods[type][source])
	return result

func update_all_damage() -> void:
	for type in base_damages:
		true_damages[type] = calculate_damage(type)

func add_modifier(type : String, source : String, percent : float) -> void:
	if not mods.has(type):
		return
	mods[type][source] = percent
	update_all_damage()

func remove_modifier(type : String, source : String) -> void:
	if not mods.has(type):
		return
	mods[type].erase(source)
	update_all_damage()
