extends Resource
class_name CrystalData

# Each crystal sheet definition
@export var display_name : String = ""
@export_multiline var description : String = ""
@export var color : Color = Color.WHITE   # สีที่ใช้ใน UI ของ shop

#have to mach base damage keys (Active)
@export var active_type : String = "fire damage"
#have to match passive keys (Passive)
@export var passive_type : String = ""

# ค่าสูงสุด (ที่ level MAX และอยู่ตำแหน่งที่ weight = 1.0)
@export var max_active : float = 6.5
@export var max_passive : float = 2.0

#Pricing
@export var buy_price : int = 60

#Upgrade
# boost = start_boost + level * upgrade_step  (ไม่เกิน 1.0)
# [แก้บั๊ก] เดิม boost = level * step -> ซื้อมาแล้ว level 0 = ค่าเป็น 0 ใช้ไม่ได้จนกว่าจะอัป
@export_range(0.0, 1.0) var start_boost : float = 0.4
@export var upgrade_step : float = 0.06
@export var max_level : int = 10
@export var cost_base : int = 45
#Exponential increasing of price
@export var cost_growth : float = 1.3 #multiply with this numeber

func get_upgrade_cost(level : int) -> int:
	return roundi(cost_base * pow(cost_growth, level))
