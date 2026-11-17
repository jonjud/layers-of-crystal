extends Node

var to_keep : Dictionary = {
	"max_hp" : 100.0,
	"max_mana" : 50.0,
	"money" : 0.0,
	"kill count" : 0,
}

var base_damages : Dictionary = {
	"physical damage" : 10,
	"fire damage" : 5,
	"wind damage" : 5,
	"water damage" : 5,
	"earth damage" : 5,
	"light damage" : 5,
	"darkness damage" : 5,
}

var layers : Array = []

var phys_dmg : float
var fir_dmg : float
var wnd_dmg : float
var wtr_dmg : float
var erth_dmg : float
var lght_dmg : float
var drknss_dmg : float

var test_percent : float = 0.8


var mods : Dictionary = {
	"physical damage" : {},
	"fire damage" : {},
	"wind damage" :{},
	"water damage" : {},
	"earth damage" : {},
	"light damage" : {},
	"darkness damage" : {},
}

var true_damages : Dictionary = {
	"physical damage" : phys_dmg,
	"fire damage" : fir_dmg,
	"wind damage" : wnd_dmg,
	"water damage" : wtr_dmg,
	"earth damage" : erth_dmg,
	"light damage" : lght_dmg,
	"darkness damage" : drknss_dmg,
}

func _ready() -> void:
	SignalBus.zombie_died.connect(_on_zombie_died)
	SignalBus.money_added.connect(_on_money_added)
	for i in base_damages:
		add_modifier(i,"tester",test_percent)
		print(true_damages,true_damages[i])

func _on_zombie_died() -> void:
	to_keep["kill count"] += 1


func _on_money_added(amount : int) -> void:
	to_keep["money"] = amount

func calculate_damage(type : String) -> float:
	if not base_damages.has(type):
		return 0.0
	var result : float = base_damages[type]
	
	for source in mods[type]:
		result *= (1.0+ mods[type][source])
	return result

func update_all_damage() -> void:
	for type in base_damages:
		true_damages[type] = calculate_damage(type)

func add_modifier(type : String ,source : String, percent : float) -> void:
	if not mods.has(type):
		return
	mods[type][source] = percent
	update_all_damage()

func remove_modifier(type : String , source : String) -> void:
	if not mods.has(type):
		return
	mods[type].erase(source)
	update_all_damage()
