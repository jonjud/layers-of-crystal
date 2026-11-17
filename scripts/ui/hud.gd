extends CanvasLayer

var player : Node2D
@onready var hp_bar : ProgressBar = $Control/HealthBar

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player:
		hp_bar.max_value = GameManager.to_keep["max_hp"]
		hp_bar.value = player.hp
		

func _process(delta: float) -> void:
	if player:
		hp_bar.value = player.hp
