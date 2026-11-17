extends Resource
class_name ZombieData


enum ZombieTypes { #Type of ZWAMBEH (haha it's weird)
	NORMAL, #AVERAGE HEALTH
	TANK, #HIGH HEALTH , 
	RUNNER, #SUPAFAST
	PIGGYBANK,
	BOSS #SPECIAL GRADE CURSE
}

@export_group("Identity")
@export var display_name : String = "ZWAMBEH"
@export var zombie_type : ZombieTypes = ZombieTypes.NORMAL

@export_group("Stats")
@export var max_health : float = 500.0
@export var speed : float = 30.0
@export var damage : float = 30.0
@export var money : int = 30

@export_group("Appearance")
@export var color : Color = Color.CRIMSON
@export var size : float = 32.0

@export_group("Damage Resistance")
# Key = Damage Type
# Value = Damage Reduction (0.0 - 1.0)
@export var resistances : Dictionary = {
	"physical": 0.0,
	"fire": 0.0,
	"wind damage" : 0.0,
	"water damage" : 0.0,
	"earth damage" : 0.0,
	"light damage" : 0.0,
	"darkness damage" : 0.0,
}

func random_type_of_resistance_and_assign_values() -> void:
	if zombie_type != ZombieTypes.NORMAL:
		return
	#duplicate and erase to prevent the same key
	var avail_keys = resistances.keys()
	for i in range(3):
		var rand_key : String = avail_keys.pick_random()
		resistances[rand_key] = randf_range(0.1,0.8)
		avail_keys.erase(rand_key)
	for i in resistances:
		print(i,resistances[i])

func calculate_recieved_damage(amount : float, type : String) -> float:
	var reduction : float = resistances.get(type,0.0) #หาไม่เจอให้ใส่ 0.0
	return amount * (1.0 - reduction)
