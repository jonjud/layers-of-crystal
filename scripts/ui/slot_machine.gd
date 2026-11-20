extends HBoxContainer
class_name SlotMachine
# เครื่องสล็อต 3 reel (UI ล้วน) -- ผลลัพธ์ถูกสุ่มไว้แล้วจากข้างนอก ที่นี่แค่ "หมุนโชว์แล้วหยุดที่ผลนั้น"
# ใช้: machine.spin([a,b,c]) แล้วรอ signal finished

signal finished

const STOP_TIMES : Array[float] = [0.7, 1.15, 1.6]   # reel หยุดทีละอัน (สร้างความลุ้น)

var icons : Array[SymbolIcon] = []
var target : Array = [0, 0, 0]
var stopped : Array = [true, true, true]
var spinning : bool = false
var _elapsed : float = 0.0
var _tick : float = 0.0

func _init(icon_size : int = 44) -> void:
	add_theme_constant_override("separation", 6)
	for i in 3:
		var panel := PanelContainer.new()
		var icon := SymbolIcon.new(icon_size)
		icon.symbol = randi() % 5
		panel.add_child(icon)
		add_child(panel)
		icons.append(icon)

func show_symbols(result : Array) -> void:
	for i in 3:
		icons[i].symbol = int(result[i])

func spin(result : Array) -> void:
	if spinning:
		return
	target = result.duplicate()
	stopped = [false, false, false]
	_elapsed = 0.0
	_tick = 0.0
	spinning = true

func _process(delta : float) -> void:
	if not spinning:
		return
	_elapsed += delta
	_tick += delta
	var cycle : bool = _tick >= 0.06
	if cycle:
		_tick = 0.0
	var all_done : bool = true
	for i in 3:
		if stopped[i]:
			continue
		if _elapsed >= STOP_TIMES[i]:
			stopped[i] = true
			icons[i].symbol = int(target[i])
			_bounce(icons[i])
		else:
			all_done = false
			if cycle:
				icons[i].symbol = randi() % 5
	if all_done:
		spinning = false
		finished.emit()

func _bounce(icon : SymbolIcon) -> void:
	icon.pivot_offset = icon.size * 0.5
	var tw := create_tween()
	tw.tween_property(icon, "scale", Vector2(1.25, 1.25), 0.06)
	tw.tween_property(icon, "scale", Vector2.ONE, 0.12)
