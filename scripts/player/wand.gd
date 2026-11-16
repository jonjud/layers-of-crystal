extends Node2D

@export var bullet_scene : PackedScene
var original_y : float

func _ready() -> void:
	SignalBus.fire_pressed.connect(_on_fire_pressed)
	original_y = position.y

func _on_fire_pressed() -> void:
	var tw : Tween = create_tween()
	
	tw.tween_property(self, "position:y", original_y - 5 , 0.2)
	tw.tween_property(self, "position:y", original_y , 0.3)
	
	
	var bullet : Bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	get_tree().current_scene.add_child(bullet)
