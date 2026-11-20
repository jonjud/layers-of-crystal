extends Node

# แจ้งระบบ UI หรือระบบอื่นเมื่อการจัดวาง Crystal เปลี่ยนแปลง
signal layers_changed

# จำนวนช่อง Crystal และน้ำหนักโบนัสของชั้นบนสุดกับล่างสุด
const SLOTS : int = 5
const TOP_WEIGHT : float = 1.0 #multiplier of top level
const BOTTOM_WEIGHT : float = 0.2 #multiplier of bottom level

# ค่าสถานะพื้นฐานก่อนนำโบนัสจาก Crystal มาคำนวณ
const BASE_CRIT_RATE : float = 0.12     # 12%
const BASE_CRIT_DAMAGE : float = 2.0    # damage if hit crit
const BASE_REGEN : float = 1.0          # HP regen per sec

# รายการ Crystal ที่ติดตั้ง, เป็นเจ้าของ, ระดับอัปเกรด และ Modifier ของค่าสถานะอื่น
var layers : Array[CrystalData] = [] #index 0 = TOP , SLOTS - 1 = BOTTOM (HEHE)
var owned : Array[CrystalData] = []
var levels : Dictionary = {} # Key = display name , Value = level
var stat_mods : Dictionary = {} # value that is not damage

# เตรียม Array สำหรับเก็บ Crystal ตามจำนวนช่องที่กำหนด
func _ready() -> void:
	layers.resize(SLOTS)

# คำนวณน้ำหนักโบนัส Active ของช่อง โดยช่องบนสุดมีน้ำหนักมากกว่าช่องล่าง
func active_weight(slot : int) -> float:
	var t : float = float(slot) / float(SLOTS - 1)
	return lerpf(TOP_WEIGHT,BOTTOM_WEIGHT,t)

# คำนวณน้ำหนักโบนัส Passive โดยใช้น้ำหนักกลับด้านกับ Active
func passive_weight(slot : int) -> float:
	return TOP_WEIGHT + BOTTOM_WEIGHT - active_weight(slot) #1.2-weight of active

# คำนวณค่าโบนัส Active ของ Crystal ในช่องที่ระบุ
func active_value(slot : int) -> float:
	var crystal : CrystalData = layers[slot]
	if crystal == null:
		return 0.0
	return crystal.max_active * _boost(crystal) * active_weight(slot)

# คำนวณค่าโบนัส Passive ของ Crystal ในช่องที่ระบุ
func passive_value(slot : int) -> float:
	var crystal : CrystalData = layers[slot]
	if crystal == null or crystal.passive_type == "":
		return 0.0
	return crystal.max_passive * _boost(crystal) * passive_weight(slot)

# คำนวณตัวคูณจากระดับอัปเกรดและค่า upgrade_step ของ Crystal
func _boost(crystal : CrystalData) -> float:
	return 1.0 * get_level(crystal) * crystal.upgrade_step

# ตรวจสอบว่า Crystal อยู่ในรายการที่ผู้เล่นเป็นเจ้าของหรือไม่
func is_owned(crystal : CrystalData) -> bool:
	return owned.has(crystal)

# ตรวจสอบว่า Crystal ถูกติดตั้งอยู่ในช่องใดช่องหนึ่งหรือไม่
func is_equipped(crystal : CrystalData) -> bool:
	return layers.has(crystal)

# ค้นหาช่องว่างช่องแรก หากไม่มีช่องว่างจะคืนค่า -1
func first_empty_slot() -> int:
	return layers.find(null)   # -1 = เต็มหมด

# ตรวจสอบว่าเงินปัจจุบันเพียงพอกับราคาที่ต้องจ่ายหรือไม่
func _can_afford(cost : int) -> bool:
	return GameManager.to_keep["money"] >= cost

# ซื้อ Crystal หากยังไม่เคยเป็นเจ้าของและมีเงินเพียงพอ พร้อมติดตั้งถ้ามีช่องว่าง
func try_buy(crystal : CrystalData) -> bool:
	if is_owned(crystal) or not _can_afford(crystal.buy_price):
		return false
	GameManager.to_keep["money"] -= crystal.buy_price
	owned.append(crystal)
	var slot : int = first_empty_slot()
	if slot != -1:
		layers[slot] = crystal
	rebuild_mods()
	return true

# ติดตั้ง Crystal ที่เป็นเจ้าของแล้วลงในช่องว่าง
func equip(crystal : CrystalData) -> bool:
	if not is_owned(crystal) or is_equipped(crystal):
		return false
	var slot : int = first_empty_slot()
	if slot == -1:
		return false
	layers[slot] = crystal
	rebuild_mods()
	return true

# ถอด Crystal ออกจากช่องที่ระบุ
func unequip(slot : int) -> void:
	if slot < 0 or slot >= SLOTS:
		return
	layers[slot] = null
	rebuild_mods()

# กำหนด Crystal ลงช่องโดยตรง (ใช้สำหรับทดสอบ)
func set_crystal(slot : int, crystal : CrystalData) -> void:   # ไว้ทดสอบ
	if slot < 0 or slot >= SLOTS:
		return
	layers[slot] = crystal
	rebuild_mods()

# สลับตำแหน่ง Crystal ระหว่างสองช่อง
func swap_slots(a : int, b : int) -> void:
	if a < 0 or b < 0 or a >= SLOTS or b >= SLOTS:
		return
	var tmp : CrystalData = layers[a]
	layers[a] = layers[b]
	layers[b] = tmp
	rebuild_mods()

# เลื่อน Crystal ขึ้นหนึ่งช่อง
func move_up(slot : int) -> void:
	swap_slots(slot, slot - 1)

# เลื่อน Crystal ลงหนึ่งช่อง
func move_down(slot : int) -> void:
	swap_slots(slot, slot + 1)

# อ่านระดับอัปเกรดของ Crystal จากชื่อที่ใช้เป็น Key
func get_level(crystal : CrystalData) -> int:
	return levels.get(crystal.display_name, 0)

# คำนวณราคาอัปเกรด Crystal ตามระดับปัจจุบัน
func get_upgrade_cost(crystal : CrystalData) -> int:
	return crystal.get_upgrade_cost(get_level(crystal))

# อัปเกรด Crystal เมื่อเป็นเจ้าของและมีเงินเพียงพอ
func try_upgrade(crystal : CrystalData) -> bool:
	if not is_owned(crystal):
		return false
	var cost : int = get_upgrade_cost(crystal)
	if not _can_afford(cost):
		return false
	GameManager.to_keep["money"] -= cost
	levels[crystal.display_name] = get_level(crystal) + 1
	rebuild_mods()
	return true

# รวมโบนัสของค่าสถานะที่ไม่ใช่ Damage จากทุกแหล่ง
func get_stat(stat : String) -> float:
	var total : float = 0.0
	var sources : Dictionary = stat_mods.get(stat, {})
	for source in sources:
		total += sources[source]
	return total

# สร้าง Modifier ใหม่ทั้งหมดจาก Crystal ที่ติดตั้งอยู่ในแต่ละช่อง
func rebuild_mods() -> void:
	_clear_all()
	for slot in SLOTS:
		var crystal : CrystalData = layers[slot]
		if crystal == null:
			continue
		var source : String = _source(slot)
		_apply(crystal.active_type, source, active_value(slot))
		if crystal.passive_type != "":
			_apply(crystal.passive_type, source, passive_value(slot))
	layers_changed.emit()

# สร้างชื่อแหล่งที่มาของ Modifier โดยผูกกับหมายเลขช่อง
func _source(slot : int) -> String:
	return "crystal_%d" % slot

# ลบ Modifier เดิมของทุกช่อง ก่อนคำนวณและใส่ค่าใหม่
func _clear_all() -> void:
	for slot in SLOTS:
		var source : String = _source(slot)
		for type in GameManager.mods:
			GameManager.remove_modifier(type, source)
		for stat in stat_mods:
			stat_mods[stat].erase(source)

# ส่งโบนัสไปยัง GameManager หากเป็น Damage หรือเก็บใน stat_mods หากเป็นค่าสถานะอื่น
func _apply(type : String, source : String, value : float) -> void:
	if GameManager.mods.has(type):
		GameManager.add_modifier(type, source, value)
	else:
		if not stat_mods.has(type):
			stat_mods[type] = {}
		stat_mods[type][source] = value

# คำนวณโอกาส Critical จากค่าพื้นฐานและโบนัสที่ได้รับ
func get_crit_chance() -> float:
	return clampf(BASE_CRIT_RATE * (1.0 + get_stat("crit rate")), 0.0, 1.0)

# สุ่มผล Critical Hit และคืนค่าตัวคูณ Damage ที่ควรใช้
func roll_crit_multiplier() -> float:
	if randf() < get_crit_chance():
		return BASE_CRIT_DAMAGE * (1.0 + get_stat("crit damage"))
	return 1.0

# คำนวณตัวคูณเงินจากโบนัส gold
func gold_multiplier() -> float:
	return 1.0 + get_stat("gold")

# ลด Damage ที่ได้รับตามค่า defense
func reduce_damage(amount : float) -> float:
	return amount / (1.0 + get_stat("defense"))

# คำนวณอัตราฟื้นฟู HP ต่อวินาทีจากโบนัส hp regen
func regen_per_second() -> float:
	return BASE_REGEN * (1.0 + get_stat("hp regen"))

# รีเซ็ตช่อง Crystal, รายการที่เป็นเจ้าของ, ระดับอัปเกรด และโบนัสค่าสถานะ
func reset() -> void:
	layers.fill(null)
	owned.clear()
	levels.clear()
	stat_mods.clear()
	rebuild_mods()
