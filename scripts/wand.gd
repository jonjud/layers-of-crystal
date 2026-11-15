extends Node2D


func _ready() -> void:
	SignalBus.fire_pressed.connect(_on_fire_pressed)

func _on_fire_pressed() -> void:
	print("fire pressed")
