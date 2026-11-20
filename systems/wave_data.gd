extends Resource
class_name WaveData

@export var type : Array[ZombieAndAmount] # the type that will get random in this wave

@export_group("Balance")
@export var spawn_interval : float = 1.5      # วินาทีระหว่างซอมบี้แต่ละตัว
@export var hp_multiplier : float = 1.0       # คูณ HP ซอมบี้ทุกตัวใน wave นี้
@export var speed_multiplier : float = 1.0
@export var money_multiplier : float = 1.0
