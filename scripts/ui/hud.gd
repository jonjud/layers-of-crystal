extends CanvasLayer

# อ้างอิง Node ของผู้เล่นเพื่ออ่านค่าพลังชีวิต
var player : Node2D
# แถบแสดงพลังชีวิตบน HUD
@onready var hp_bar : ProgressBar = $Control/HealthBar

# ค้นหาผู้เล่นและกำหนดค่าสูงสุด/ค่าเริ่มต้นของแถบพลังชีวิต
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player:
		hp_bar.max_value = GameManager.to_keep["max_hp"]
		hp_bar.value = player.hp
		

# อัปเดตค่าบนแถบพลังชีวิตให้ตรงกับ HP ปัจจุบันของผู้เล่น
func _process(delta: float) -> void:
	if player:
		hp_bar.value = player.hp
