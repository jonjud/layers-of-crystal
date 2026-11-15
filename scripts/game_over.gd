extends CanvasLayer

@onready var _restart_button : Button = $Control/CenterContainer/VBoxContainer/RestartButton

func _ready() -> void:
	hide()
	SignalBus.player_died.connect(_on_player_died)
	_restart_button.pressed.connect(_on_restart_button_pressed)

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

func _on_player_died() -> void:
	show()
