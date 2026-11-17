extends Node2D

@export var zombie_scene : PackedScene
var spawn_point : Vector2
var screen_size : Vector2 

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	print(screen_size)
	spawn_point = Vector2(screen_size.x + 10 , 180.0)
	$Timer.timeout.connect(spawn_zwambeh)

func spawn_zwambeh() -> void:
	var zwambeh : Zombie = zombie_scene.instantiate()
	zwambeh.global_position = spawn_point
	get_tree().current_scene.add_child(zwambeh)


func _on_go_shop_button_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/shop.tscn")
