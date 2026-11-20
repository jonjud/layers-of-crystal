extends Resource
class_name CrystalData

# Each crystal sheet definition 
@export var display_name : String = ""
#have to mach base damage keys (Active)
@export var active_type : String = "fire damage"
#have to match passive keys (Passive
@export var passive_type : String = ""

@export var max_active : float = 2.5
@export var max_passive : float = 2.0

#Pricing
@export var buy_price : int = 100

#Upgrade
#0.1 = +10% per upgrade level
@export var upgrade_step : float = 0.1
@export var cost_base : int = 100
#Exponential increasing of price
@export var cost_growth : float = 1.5 #multiply with this numeber 

func get_upgrade_cost(level : int) -> int:
	return roundi(cost_base * pow(cost_growth,level))
