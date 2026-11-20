extends Node

signal layers_changed

const SLOTS : int = 5
const TOP_WEIGHT : float = 1.0 #multiplier of top level
const BOTTOM_WEIGHT : float = 0.2 #multiplier of bottom level

const BASE_CRIT_RATE : float = 0.12     # 12%
const BASE_CRIT_DAMAGE : float = 2.0    # damage if hit crit
const BASE_REGEN : float = 1.0          # HP regen per sec
const LIFESTEAL_RATE : float = 0.03     # lifesteal stat 1.0 = ฟื้น 3% ของ damage ที่ตีโดน

var layers : Array[CrystalData] = [] #index 0 = TOP , SLOTS - 1 = BOTTOM (HEHE)
var owned : Array[CrystalData] = []
var levels : Dictionary = {} # Key = display name , Value = level
var stat_mods : Dictionary = {} # value that is not damage

func _ready() -> void:
	layers.resize(SLOTS)

# WEIGHT per layer (1.0 > 0.2)
func active_weight(slot : int) -> float:
	var t : float = float(slot) / float(SLOTS - 1)
	return lerpf(TOP_WEIGHT,BOTTOM_WEIGHT,t)

func passive_weight(slot : int) -> float:
	return TOP_WEIGHT + BOTTOM_WEIGHT - active_weight(slot) #1.2-weight of active

func active_value(slot : int) -> float:
	var crystal : CrystalData = layers[slot]
	if crystal == null:
		return 0.0
	return crystal.max_active * _boost(crystal) * active_weight(slot)

func passive_value(slot : int) -> float:
	var crystal : CrystalData = layers[slot]
	if crystal == null or crystal.passive_type == "":
		return 0.0
	return crystal.max_passive * _boost(crystal) * passive_weight(slot)

# [แก้บั๊ก] เดิม = level * step (level 0 => 0) ตอนนี้เริ่มที่ start_boost และตัดที่ 1.0
func _boost(crystal : CrystalData) -> float:
	return minf(crystal.start_boost + get_level(crystal) * crystal.upgrade_step, 1.0)

#OWNASHEEP
func is_owned(crystal : CrystalData) -> bool:
	return owned.has(crystal)

func is_equipped(crystal : CrystalData) -> bool:
	return layers.has(crystal)

func first_empty_slot() -> int:
	return layers.find(null)   # -1 = เต็มหมด

func _can_afford(cost : int) -> bool:
	return GameManager.to_keep["money"] >= cost

#buy new one if there's a room , replace the first empty room
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

func equip(crystal : CrystalData) -> bool:
	if not is_owned(crystal) or is_equipped(crystal):
		return false
	var slot : int = first_empty_slot()
	if slot == -1:
		return false
	layers[slot] = crystal
	rebuild_mods()
	return true

func unequip(slot : int) -> void:
	if slot < 0 or slot >= SLOTS:
		return
	layers[slot] = null
	rebuild_mods()

func set_crystal(slot : int, crystal : CrystalData) -> void:   # ไว้ทดสอบ
	if slot < 0 or slot >= SLOTS:
		return
	layers[slot] = crystal
	rebuild_mods()

func swap_slots(a : int, b : int) -> void:
	if a < 0 or b < 0 or a >= SLOTS or b >= SLOTS:
		return
	var tmp : CrystalData = layers[a]
	layers[a] = layers[b]
	layers[b] = tmp
	rebuild_mods()

func move_up(slot : int) -> void:
	swap_slots(slot, slot - 1)

func move_down(slot : int) -> void:
	swap_slots(slot, slot + 1)

#Upgrade the one that already have
func get_level(crystal : CrystalData) -> int:
	return levels.get(crystal.display_name, 0)

func is_maxed(crystal : CrystalData) -> bool:
	return get_level(crystal) >= crystal.max_level

func get_upgrade_cost(crystal : CrystalData) -> int:
	return crystal.get_upgrade_cost(get_level(crystal))

func try_upgrade(crystal : CrystalData) -> bool:
	if not is_owned(crystal) or is_maxed(crystal):
		return false
	var cost : int = get_upgrade_cost(crystal)
	if not _can_afford(cost):
		return false
	GameManager.to_keep["money"] -= cost
	levels[crystal.display_name] = get_level(crystal) + 1
	rebuild_mods()
	return true

# ---- ช่องทางที่ระบบ Gambling / start bonus ใช้ (ไม่หักเงิน) ----
func free_upgrade_random() -> String:
	var pool : Array[CrystalData] = []
	for c in owned:
		if not is_maxed(c):
			pool.append(c)
	if pool.is_empty():
		return ""
	var pick : CrystalData = pool.pick_random()
	levels[pick.display_name] = get_level(pick) + 1
	rebuild_mods()
	return pick.display_name

func grant(crystal : CrystalData, level : int = 0) -> void:
	if crystal == null:
		return
	if not owned.has(crystal):
		owned.append(crystal)
	levels[crystal.display_name] = clampi(level, 0, crystal.max_level)
	var slot : int = first_empty_slot()
	if slot != -1 and not is_equipped(crystal):
		layers[slot] = crystal
	rebuild_mods()

#read the bonus summation that are not the damage bonus
func get_stat(stat : String) -> float:
	var total : float = 0.0
	var sources : Dictionary = stat_mods.get(stat, {})
	for source in sources:
		total += sources[source]
	return total

# HEART OF MANAGA
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

func _source(slot : int) -> String:
	return "crystal_%d" % slot

func _clear_all() -> void:
	for slot in SLOTS:
		var source : String = _source(slot)
		for type in GameManager.mods:
			GameManager.remove_modifier(type, source)
		for stat in stat_mods:
			stat_mods[stat].erase(source)

# damage ไปที่ GameManager.mods (คูณ) / ค่าอื่นไปที่ stat_mods (บวก)
func _apply(type : String, source : String, value : float) -> void:
	if GameManager.mods.has(type):
		GameManager.add_modifier(type, source, value)
	else:
		if not stat_mods.has(type):
			stat_mods[type] = {}
		stat_mods[type][source] = value

# helper for other file
func get_crit_chance() -> float:
	return clampf(BASE_CRIT_RATE * (1.0 + get_stat("crit rate")), 0.0, 1.0)

func roll_crit_multiplier() -> float:
	if randf() < get_crit_chance():
		return BASE_CRIT_DAMAGE * (1.0 + get_stat("crit damage"))
	return 1.0

func gold_multiplier() -> float:
	return 1.0 + get_stat("gold")

# defense +200% = หารความเสียหายด้วย 3 (ไม่มีวันติดลบ)
func reduce_damage(amount : float) -> float:
	return amount / (1.0 + get_stat("defense"))

func regen_per_second() -> float:
	return BASE_REGEN * (1.0 + get_stat("hp regen"))

# ---- stat ใหม่ ----
func fire_rate_multiplier() -> float:   # +100% = ยิงเร็วขึ้น 2 เท่า
	return 1.0 + get_stat("fire rate")

func lifesteal_rate() -> float:
	return LIFESTEAL_RATE * maxf(get_stat("lifesteal"), 0.0)

func luck() -> float:                   # ใช้กับ Lucky Orb / Wager / Slot
	return maxf(get_stat("luck"), 0.0)

#NEW GGAME
func reset() -> void:
	layers.fill(null)
	owned.clear()
	levels.clear()
	stat_mods.clear()
	rebuild_mods()
