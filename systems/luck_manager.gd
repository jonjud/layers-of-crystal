extends Node
class_name LuckManager
# ระบบ Gambling ทั้งหมด (ถูกสร้างเป็นลูกของ GameManager -> เรียกผ่าน GameManager.luck)
#  1) Lucky Orb   : ซอมบี้ดรอปออร์บ เก็บแล้วสุ่มผลระหว่างต่อสู้ (ดี/ร้าย/เฉยๆ)
#  2) Wave Wager  : จบ wave แล้วเอาเงินที่หาได้มาพนัน Safe / Risky / YOLO
#  3) Slots       : สล็อตใน shop (ตรรกะอยู่ที่ SlotLogic)
# ทุกอย่างถูกถ่วงด้วย stat "luck" จาก crystal (Solar Lumen ฯลฯ)

const BASE_ORB_CHANCE : float = 0.06
const ORB_PITY_STEP : float = 0.012     # ยิ่งไม่ดรอปนาน โอกาสยิ่งเพิ่ม
const ORB_REVEAL_TIME : float = 1.1
const SLOT_PITY : int = 5               # แพ้ติด 5 รอบ -> รอบถัดไปการันตีคู่
const FRENZY_BONUS : float = 1.0        # +100% damage ทุกธาตุ
const MIDAS_MULT : float = 3.0
const CURSE_SPEED : float = 1.4

# kind: 1 = ดี, 0 = เฉยๆ, -1 = ร้าย
var outcomes : Array = [
	{"id": "jackpot", "name": "JACKPOT", "weight": 8.0,  "kind": 1},
	{"id": "coins",   "name": "COINS",   "weight": 22.0, "kind": 1},
	{"id": "frenzy",  "name": "FRENZY",  "weight": 14.0, "kind": 1},
	{"id": "midas",   "name": "MIDAS",   "weight": 12.0, "kind": 1},
	{"id": "heal",    "name": "HEAL",    "weight": 14.0, "kind": 1},
	{"id": "nova",    "name": "NOVA",    "weight": 8.0,  "kind": 1},
	{"id": "dud",     "name": "DUD",     "weight": 8.0,  "kind": 0},
	{"id": "curse",   "name": "CURSE",   "weight": 10.0, "kind": -1},
	{"id": "drain",   "name": "DRAIN",   "weight": 8.0,  "kind": -1},
	{"id": "robbed",  "name": "ROBBED",  "weight": 6.0,  "kind": -1},
]

# Wave Wager: เฉลี่ย EV ~0.95-0.98 ที่ luck 0 และเกิน 1.0 เมื่อมี luck
var tiers : Array = [
	{"name": "SAFE",  "mult": 1.4, "p": 0.70},
	{"name": "RISKY", "mult": 2.0, "p": 0.48},
	{"name": "YOLO",  "mult": 5.0, "p": 0.19},
]

var buffs : Dictionary = {}     # id -> {"left": วินาทีที่เหลือ, "total": วินาทีทั้งหมด}
var kills_since_orb : int = 0
var wager_used : bool = false
var slot_dry : int = 0          # จำนวนรอบสล็อตที่ไม่คืนทุนติดกัน

func luck() -> float:
	return CrystalManager.luck()

# ---------- รีเซ็ต ----------
func reset_wave() -> void:
	clear_buffs()
	kills_since_orb = 0
	wager_used = false

func reset_all() -> void:
	reset_wave()
	slot_dry = 0

# ---------- Buff ชั่วคราว ----------
func _process(delta : float) -> void:
	if buffs.is_empty():
		return
	var expired : Array = []
	for id in buffs:
		buffs[id]["left"] -= delta
		if buffs[id]["left"] <= 0.0:
			expired.append(id)
	for id in expired:
		_end_buff(id)
	if not expired.is_empty():
		SignalBus.buffs_changed.emit()

func start_buff(id : String, duration : float) -> void:
	if not buffs.has(id):
		_begin_effect(id)
	buffs[id] = {"left": duration, "total": duration}
	SignalBus.buffs_changed.emit()

func _begin_effect(id : String) -> void:
	if id == "frenzy":
		for type in GameManager.mods:
			GameManager.add_modifier(type, "luck_frenzy", FRENZY_BONUS)

func _end_buff(id : String) -> void:
	if id == "frenzy":
		for type in GameManager.mods:
			GameManager.remove_modifier(type, "luck_frenzy")
	buffs.erase(id)

func clear_buffs() -> void:
	for id in buffs.keys():
		_end_buff(id)
	SignalBus.buffs_changed.emit()

func buff_left(id : String) -> float:
	if buffs.has(id):
		return buffs[id]["left"]
	return 0.0

func gold_buff_multiplier() -> float:
	return MIDAS_MULT if buffs.has("midas") else 1.0

func zombie_speed_multiplier() -> float:
	return CURSE_SPEED if buffs.has("curse") else 1.0

# ---------- 1) Lucky Orb ----------
func roll_orb_drop() -> bool:
	var chance : float = BASE_ORB_CHANCE + kills_since_orb * ORB_PITY_STEP + luck() * 0.03
	kills_since_orb += 1
	if randf() < chance:
		kills_since_orb = 0
		return true
	return false

func outcome_names() -> Array:
	var names : Array = []
	for o in outcomes:
		names.append(o["name"])
	return names

func roll_orb() -> Dictionary:
	var l : float = luck()
	var weights : Array[float] = []
	var total : float = 0.0
	for o in outcomes:
		var w : float = float(o["weight"])
		var kind : int = int(o["kind"])
		if kind > 0:
			w *= 1.0 + l
		elif kind < 0:
			w /= 1.0 + l
		weights.append(w)
		total += w
	var r : float = randf() * total
	for i in outcomes.size():
		r -= weights[i]
		if r <= 0.0:
			return outcomes[i]
	return outcomes[0]

# ผู้เล่นเก็บออร์บ: เลือกผลทันที -> HUD หมุนโชว์ -> ครบเวลาแล้วค่อยใช้ผลจริง
func open_orb() -> void:
	var outcome : Dictionary = roll_orb()
	SignalBus.orb_rolled.emit(outcome)
	await get_tree().create_timer(ORB_REVEAL_TIME).timeout
	var detail : String = apply_orb(outcome)
	SignalBus.orb_applied.emit(outcome, detail)

func apply_orb(outcome : Dictionary) -> String:
	var wave : int = int(GameManager.to_keep["current wave"])
	var player : Node = get_tree().get_first_node_in_group("player")
	match str(outcome["id"]):
		"jackpot":
			var jackpot_gold : int = 100 + 35 * wave
			SignalBus.money_added.emit(jackpot_gold)
			return "+$%d" % jackpot_gold
		"coins":
			var coin_gold : int = 40 + 12 * wave
			SignalBus.money_added.emit(coin_gold)
			return "+$%d" % coin_gold
		"frenzy":
			start_buff("frenzy", 8.0)
			return "All damage +100%  (8s)"
		"midas":
			start_buff("midas", 12.0)
			return "Gold x3  (12s)"
		"heal":
			if player != null and player.has_method("heal"):
				player.heal(float(GameManager.to_keep["max_hp"]) * 0.5)
				return "Restored 50% HP"
			return "Nothing to heal"
		"nova":
			var hit_count : int = 0
			for z in get_tree().get_nodes_in_group("zombie"):
				if is_instance_valid(z) and z.has_method("damage"):
					z.damage(float(z.max_hp) * 0.35, "light damage")
					hit_count += 1
			return "Blast hit %d zombies" % hit_count
		"curse":
			start_buff("curse", 10.0)
			return "Zombies +40% speed  (10s)"
		"drain":
			if player != null:
				player.hp = maxf(float(player.hp) * 0.75, 1.0)
			return "Lost 25% HP"
		"robbed":
			var money : float = float(GameManager.to_keep["money"])
			var lost : int = roundi(money * 0.08)
			GameManager.to_keep["money"] = maxf(money - lost, 0.0)
			return "-$%d" % lost
	return "Nothing happened"

# ---------- 2) Wave Wager ----------
func wager_chance(tier : int) -> float:
	return minf(float(tiers[tier]["p"]) * (1.0 + 0.25 * luck()), 0.92)

# เงินที่หาได้ใน wave นี้ (กันกรณีเงินหายระหว่าง wave)
func wager_stake() -> int:
	var money : float = float(GameManager.to_keep["money"])
	var start : float = float(GameManager.to_keep["wave start money"])
	return maxi(0, mini(roundi(money - start), roundi(money)))

func roll_wager(tier : int, stake : int) -> Dictionary:
	var won : bool = randf() < wager_chance(tier)
	var mult : float = float(tiers[tier]["mult"])
	var delta : int = roundi(stake * (mult - 1.0)) if won else -stake
	return {"won": won, "delta": delta}

func commit_wager(result : Dictionary) -> void:
	var money : float = float(GameManager.to_keep["money"])
	GameManager.to_keep["money"] = maxf(money + float(result["delta"]), 0.0)

# ---------- 3) Slots ----------
func slot_cost() -> int:
	return 40 + 20 * int(GameManager.to_keep["current wave"])

func can_spin() -> bool:
	return float(GameManager.to_keep["money"]) >= slot_cost()

# หักเงิน + สุ่มผล + จ่ายรางวัลทันที (UI ค่อยแสดงทีหลังตอน reel หยุด)
func spin_slot() -> Dictionary:
	var cost : int = slot_cost()
	if not can_spin():
		return {}
	GameManager.to_keep["money"] = float(GameManager.to_keep["money"]) - cost
	var force : bool = slot_dry >= SLOT_PITY
	var symbols : Array[int] = SlotLogic.roll(luck(), force)
	var ev : Dictionary = SlotLogic.evaluate(symbols)
	var payout : int = roundi(cost * float(ev["mult"]))
	if payout > 0:
		GameManager.to_keep["money"] = float(GameManager.to_keep["money"]) + payout
	if payout >= cost:
		slot_dry = 0
	else:
		slot_dry += 1
	var bonus : String = ""
	if int(ev["kind"]) == 3 and int(ev["symbol"]) >= SlotLogic.Sym.AMETHYST:
		var upgraded : String = CrystalManager.free_upgrade_random()
		if upgraded != "":
			bonus = "FREE UPGRADE: %s" % upgraded
	return {"symbols": symbols, "payout": payout, "cost": cost, "kind": int(ev["kind"]), "bonus": bonus}
