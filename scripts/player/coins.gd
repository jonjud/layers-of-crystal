extends Area2D
class_name Coins

# อ้างอิงผู้เล่นที่เหรียญจะเคลื่อนที่เข้าหา
var wiz : Node2D
# จำนวนเงินที่เหรียญนี้จะมอบให้ผู้เล่นเมื่อเก็บได้
var value : int
# ความเร็วในการเคลื่อนที่เข้าหาผู้เล่น
var speed : float = 300.0

# ค้นหาผู้เล่นจากกลุ่ม player และเชื่อมสัญญาณเมื่อมีวัตถุเข้ามาสัมผัส
func _ready() -> void:
	wiz = get_tree().get_first_node_in_group("player")
	body_entered.connect(_on_body_entered)

# เคลื่อนเหรียญเข้าหาผู้เล่นทุกเฟรม หากพบผู้เล่นแล้ว
func _process(delta: float) -> void:
	if wiz:
		var dir : Vector2 = (wiz.global_position - global_position).normalized()
		position += dir * speed * delta

# เมื่อมีวัตถุเข้ามาสัมผัส จะให้เงินเฉพาะกรณีที่เป็นผู้เล่นที่อ้างอิงไว้
func _on_body_entered(body : Node2D) -> void:
	if body == wiz:
		if body.has_method("add_money"):
			body.add_money(value)
			call_deferred("queue_free")
