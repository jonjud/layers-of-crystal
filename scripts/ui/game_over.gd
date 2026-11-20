extends CanvasLayer

# ปุ่มสำหรับเริ่มเกมใหม่จากฉากปัจจุบัน
@onready var _restart_button : Button = $Control/CenterContainer/VBoxContainer/RestartButton

# ซ่อนหน้าจอ Game Over ไว้ก่อน และเชื่อมสัญญาณการตายกับปุ่มเริ่มใหม่
func _ready() -> void:
	hide()
	SignalBus.player_died.connect(_on_player_died)
	_restart_button.pressed.connect(_on_restart_button_pressed)

# โหลดฉากปัจจุบันใหม่เมื่อผู้เล่นกดปุ่ม Restart
func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

# แสดงหน้าจอ Game Over เมื่อได้รับสัญญาณว่าผู้เล่นตาย
func _on_player_died() -> void:
	show()
