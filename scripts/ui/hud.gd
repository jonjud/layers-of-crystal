extends CanvasLayer

# อ้างอิง Node ของผู้เล่นเพื่ออ่านค่าพลังชีวิต
var player : Node2D
var info : Label
# แถบแสดงพลังชีวิตบน HUD
@onready var hp_bar : ProgressBar = $Control/HealthBar

# ค้นหาผู้เล่นและกำหนดค่าสูงสุด/ค่าเริ่มต้นของแถบพลังชีวิต
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player:
		hp_bar.max_value = GameManager.to_keep["max_hp"]
		hp_bar.value = player.hp
	info = Label.new()                                 # ป้ายข้อความ
	info.position = Vector2(12, 34)                    # ใต้หลอด HP
	info.add_theme_font_size_override("font_size", 11)
	$Control.add_child(info)
	SignalBus.money_added.connect(_update_info)        # เก็บเหรียญแล้วอัปเดต
	_update_info()

# อัปเดตค่าบนแถบพลังชีวิตให้ตรงกับ HP ปัจจุบันของผู้เล่น
func _process(delta: float) -> void:
	if player:
		hp_bar.value = player.hp

func _update_info(_amount : int = 0) -> void:
	info.text = "Wave %d   $%d" % [GameManager.to_keep["current wave"], roundi(GameManager.to_keep["money"])]
