extends Resource
class_name CrystalData

# ชื่อ Crystal ที่ใช้แสดงผลในเกม
@export var display_name : String = ""
#have to mach base damage keys (Active)
# ประเภท Damage ที่ Crystal นี้เพิ่มให้ (ต้องตรงกับ key ใน GameManager.base_damages)
@export var active_type : String = "fire damage"
#have to match passive keys (Passive
# ประเภทค่าสถานะเสริมที่ Crystal นี้เพิ่มให้
@export var passive_type : String = ""

# ค่าสูงสุดของโบนัส Active และ Passive ก่อนคำนวณน้ำหนักชั้นและระดับอัปเกรด
@export var max_active : float = 2.5
@export var max_passive : float = 2.0

# ราคาที่ต้องจ่ายเพื่อซื้อ Crystal
@export var buy_price : int = 100

# ค่าที่ใช้กำหนดการเติบโตของโบนัสและราคาอัปเกรด
#0.1 = +10% per upgrade level
@export var upgrade_step : float = 0.1
@export var cost_base : int = 100
#Exponential increasing of price
@export var cost_growth : float = 1.5 #multiply with this numeber

# คำนวณราคาอัปเกรดจากราคาเริ่มต้นยกกำลังตามระดับปัจจุบัน
func get_upgrade_cost(level : int) -> int:
	return roundi(cost_base * pow(cost_growth,level))
