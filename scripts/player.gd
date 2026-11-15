extends CharacterBody2D

var stats : Dictionary = {
	"hp" : 10,
	"mana" : 50,
	"physical damage" : 10,
	"fire damage" : 5,
	"wind damage" : 5,
	"water damage" : 5,
	"earth damage" : 5,
	"light damage" : 5,
	"darkness damage" : 5,
}

func _ready() -> void:
	add_to_group("player")
	for i in stats:
		print(i ,stats[i])

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			SignalBus.fire_pressed.emit()


func _physics_process(delta: float) -> void:
	velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	move_and_slide()
