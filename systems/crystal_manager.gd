extends Node

signal layers_changed

const SLOTS : int = 5
const TOP_WEIGHT : float = 1.0 #multiplier of top level
const BOTTOM_WEIGHT : float = 0.2 #multiplier of bottom level

const BASE_CRIT_RATE : float = 0.12     # 12%
const BASE_CRIT_DAMAGE : float = 2.0    # damage if hit crit
const BASE_REGEN : float = 1.0          # HP regen per sec

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

func _boost(crystal : CrystalData) -> float:
	return 1.0 * get_level(crystal) * crystal.upgrade_step

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

func get_upgrade_cost(crystal : CrystalData) -> int:
	return crystal.get_upgrade_cost(get_level(crystal))

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

#NEW GGAME 
func reset() -> void:
	layers.fill(null)
	owned.clear()
	levels.clear()
	stat_mods.clear()
	rebuild_mods()
