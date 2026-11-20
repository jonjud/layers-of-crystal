extends Area2D
class_name LuckOrb
# Lucky Orb: ดรอปจากซอมบี้ ลอยเข้าหาผู้เล่น เก็บแล้วสุ่มผลทันที (ดู LuckManager)

var wiz : Node2D
var speed : float = 110.0
var _age : float = 0.0
const LIFETIME : float = 9.0

func _ready() -> void:
	add_to_group("coin")   # ให้ main.gd ดูดเก็บตอนจบ wave เหมือนเหรียญ
	wiz = get_tree().get_first_node_in_group("player")
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	if is_instance_valid(wiz):
		var dir : Vector2 = (wiz.global_position - global_position).normalized()
		position += dir * speed * delta
	queue_redraw()

func _draw() -> void:
	# กะพริบเร็วขึ้นเมื่อใกล้หมดเวลา
	var blink : float = 1.0
	if _age > LIFETIME - 2.5:
		blink = 0.5 + 0.5 * sin(_age * 18.0)
	var pulse : float = 1.0 + 0.12 * sin(_age * 6.0)
	var a : float = blink
	draw_circle(Vector2.ZERO, 11.0 * pulse, Color(0.56, 0.42, 1.0, 0.25 * a))
	draw_circle(Vector2.ZERO, 7.5 * pulse, Color(0.56, 0.42, 1.0, a))
	draw_circle(Vector2.ZERO, 5.0 * pulse, Color(0.85, 0.75, 1.0, a))
	draw_string(ThemeDB.fallback_font, Vector2(-3.0, 4.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.2, 0.1, 0.4, a))

func _on_body_entered(body : Node2D) -> void:
	if body == wiz:
		GameManager.luck.open_orb()
		call_deferred("queue_free")
