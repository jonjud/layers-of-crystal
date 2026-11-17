extends Node

@export var max_spawn : int = 10

var spawned_count : int = 0
var alive_count : int = 0

func _ready() -> void:
	SignalBus.zombie_died.connect(_on_zombie_died)

func spawn_zwambeh() -> void:
	spawned_count += 1
	alive_count += 1
	if spawned_count >= max_spawn:
		

func _on_zombie_died() -> void:
	alive_count -= 1
