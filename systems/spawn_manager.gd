extends Node
class_name SpawnManager

const GROUND_TOP : float = 212.0   # ขอบบนของพื้นใน main.tscn (StaticBody2D y=285 - 72.5)

@export var zombie_scene : PackedScene
@export var waves : Array[WaveData]
@export var shuffle_queue : bool = true   # true = สลับลำดับซอมบี้ในคิวแบบสุ่ม

var alive_count : int = 0
var spawn_x : float = 650.0
var waves_index : int = 0
var zwambeh_queue : Array[ZombieData] = []
var wave_done : bool = false   # กัน emit ซ้ำ และกัน emit หลังผู้เล่นตาย
var closing : bool = false     # ฉากกำลังถูกปิด (ซอมบี้หายพร้อมกัน ไม่ใช่ถูกฆ่า)
var current_wave : WaveData

func _ready() -> void:
	tree_exiting.connect(_on_tree_exiting)
	SignalBus.player_died.connect(_on_player_died)

	var screen_size : Vector2 = get_viewport().get_visible_rect().size
	spawn_x = screen_size.x + 10.0
	GameManager.total_waves = waves.size()

	waves_index = GameManager.to_keep["current wave"] - 1
	if waves_index < 0 or waves_index >= waves.size():
		push_warning("SpawnManager: ไม่มี wave ที่ index %d" % waves_index)
		$Timer.stop()
		return

	current_wave = waves[waves_index]
	zwambeh_queue = queue_the_zwambeh(waves_index)
	$Timer.timeout.connect(spawn_zwambeh)
	if zwambeh_queue.is_empty():
		$Timer.stop()
		call_deferred("_check_wave_clear")
	else:
		$Timer.start(maxf(current_wave.spawn_interval, 0.2))

# แปลง WaveData เป็นคิวแบนๆ เช่น [NORMAL, NORMAL, TANK, ...]
func queue_the_zwambeh(index : int) -> Array[ZombieData]:
	var result : Array[ZombieData] = []
	for entry in waves[index].type:
		for _n in entry.count:
			result.append(entry.type)
	if shuffle_queue:
		result.shuffle()
	return result

func spawn_zwambeh() -> void:
	if zwambeh_queue.is_empty():
		$Timer.stop()
		return
	var zwambeh : Zombie = zombie_scene.instantiate()
	var data : ZombieData = zwambeh_queue.pop_front()
	zwambeh.zb_type = data   # ต้องตั้งก่อน add_child (_ready ของซอมบี้อ่านค่านี้)
	zwambeh.hp_mult = current_wave.hp_multiplier
	zwambeh.speed_mult = current_wave.speed_multiplier
	zwambeh.money_mult = current_wave.money_multiplier
	add_child(zwambeh)
	# วางให้ "เท้า" แตะพื้นพอดี ไม่ว่าตัวจะใหญ่แค่ไหน (เดิม y คงที่ ตัวใหญ่จะจมพื้น)
	zwambeh.global_position = Vector2(spawn_x, GROUND_TOP - data.size * 0.5 - 1.0)
	alive_count += 1
	zwambeh.tree_exited.connect(_on_zombie_exited)
	if zwambeh_queue.is_empty():
		$Timer.stop()

func _on_zombie_exited() -> void:
	if closing:
		return
	alive_count -= 1
	_check_wave_clear()

# wave จบเมื่อ "คิวหมด" และ "ไม่เหลือซอมบี้" พร้อมกัน
func _check_wave_clear() -> void:
	if wave_done or closing:
		return
	if not zwambeh_queue.is_empty() or alive_count > 0:
		return
	wave_done = true
	if waves_index >= waves.size() - 1:
		SignalBus.level_passed.emit()
	else:
		SignalBus.wave_passed.emit()

func _on_tree_exiting() -> void:
	closing = true

func _on_player_died() -> void:
	wave_done = true
	$Timer.stop()
