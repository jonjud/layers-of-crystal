extends Resource
class_name ZombieData

enum ZombieTypes { # Type of ZWAMBEH (haha it's weird)
	NORMAL,    # AVERAGE HEALTH
	TANK,      # HIGH HEALTH
	RUNNER,    # SUPAFAST
	PIGGYBANK,
	BOSS       # SPECIAL GRADE CURSE
}

@export_group("Identity")
@export var display_name : String = "ZWAMBEH"
@export var zombie_type : ZombieTypes = ZombieTypes.NORMAL

@export_group("Stats")
# ค่า default = "Walker" ที่ balance แล้ว (ดู BALANCE_REPORT.md)
@export var max_health : float = 160.0
@export var speed : float = 32.0
@export var damage : float = 20.0
@export var money : int = 20

@export_group("Appearance")
@export var color : Color = Color.CRIMSON
@export var size : float = 32.0     # ตอนนี้ถูกใช้จริงแล้ว (ขนาดตัว + hitbox)

@export_group("Damage Resistance")
# Key = ชนิด damage (ต้องตรงกับ key ใน GameManager.base_damages เป๊ะ)
# Value = Damage Reduction (0.0 - 1.0)
@export var resistances : Dictionary = {
	"physical damage" : 0.0,
	"fire damage" : 0.0,
	"wind damage" : 0.0,
	"water damage" : 0.0,
	"earth damage" : 0.0,
	"light damage" : 0.0,
	"darkness damage" : 0.0,
}

func random_type_of_resistance_and_assign_values() -> void:
	if zombie_type != ZombieTypes.NORMAL:
		return
	# [แก้บั๊ก] ล้างค่าเก่าก่อน เพื่อให้ได้ "3 ธาตุ" จริงๆ ทุกตัว
	for key in resistances:
		resistances[key] = 0.0
	# erase key ที่สุ่มได้แล้ว เพื่อไม่ให้สุ่มซ้ำ
	var avail_keys : Array = resistances.keys()
	for i in range(3):
		var rand_key : String = avail_keys.pick_random()
		resistances[rand_key] = randf_range(0.1, 0.8)
		avail_keys.erase(rand_key)

func calculate_recieved_damage(amount : float, type : String) -> float:
	var reduction : float = resistances.get(type, 0.0)   # หาไม่เจอให้ใช้ 0.0
	return amount * (1.0 - reduction)
