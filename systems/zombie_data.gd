extends Resource
class_name ZombieData

# ประเภทของ Zombie ที่ใช้แยกพฤติกรรมหรือค่าสถานะ
enum ZombieTypes { # Type of ZWAMBEH (haha it's weird)
	NORMAL,    # AVERAGE HEALTH
	TANK,      # HIGH HEALTH
	RUNNER,    # SUPAFAST
	PIGGYBANK,
	BOSS       # SPECIAL GRADE CURSE
}

@export_group("Identity")
# ชื่อที่ใช้แสดง และประเภทของ Zombie
@export var display_name : String = "ZWAMBEH"
@export var zombie_type : ZombieTypes = ZombieTypes.NORMAL

@export_group("Stats")
# ค่าสถานะพื้นฐานของ Zombie
@export var max_health : float = 500.0
@export var speed : float = 30.0
@export var damage : float = 30.0
@export var money : int = 30

@export_group("Appearance")
# สีและขนาดที่ใช้กำหนดรูปลักษณ์ของ Zombie
@export var color : Color = Color.CRIMSON
@export var size : float = 32.0

@export_group("Damage Resistance")
# Key = ชนิด damage (ต้องตรงกับ key ใน GameManager.base_damages เป๊ะ)
# Value = Damage Reduction (0.0 - 1.0)
# เก็บค่าการลดความเสียหายแยกตามประเภท Damage
@export var resistances : Dictionary = {
	"physical damage" : 0.0,
	"fire damage" : 0.0,
	"wind damage" : 0.0,
	"water damage" : 0.0,
	"earth damage" : 0.0,
	"light damage" : 0.0,
	"darkness damage" : 0.0,
}

# สุ่ม Resistance 3 ประเภทให้ Zombie ที่เป็น NORMAL โดยไม่สุ่มประเภทเดิมซ้ำ
func random_type_of_resistance_and_assign_values() -> void:
	if zombie_type != ZombieTypes.NORMAL:
		return
	# เก็บ Key ที่ยังมีสิทธิ์ถูกสุ่ม และลบ Key ที่สุ่มแล้วออก
	var avail_keys : Array = resistances.keys()
	for i in range(3):
		var rand_key : String = avail_keys.pick_random()
		resistances[rand_key] = randf_range(0.1, 0.8)
		avail_keys.erase(rand_key)

# คำนวณ Damage หลังหัก Resistance ของประเภทนั้น
func calculate_recieved_damage(amount : float, type : String) -> float:
	var reduction : float = resistances.get(type, 0.0)   # หาไม่เจอให้ใช้ 0.0
	return amount * (1.0 - reduction)
