extends PanelContainer
class_name WagerPanel
# "DOUBLE OR NOTHING" : หลังจบ wave เอาเงินที่หาได้ใน wave นั้นมาพนัน 1 ครั้ง
# (ถูกสร้างและควบคุมโดย hud.gd)

var stake_label : Label
var result_label : Label
var tier_buttons : Array[Button] = []
var skip_button : Button
var _busy : bool = false

func _ready() -> void:
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)

	var title := Label.new()
	title.text = "DOUBLE OR NOTHING"
	title.add_theme_color_override("font_color", GameTheme.GOLD)
	title.add_theme_font_size_override("font_size", 13)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	stake_label = Label.new()
	stake_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(stake_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	for i in GameManager.luck.tiers.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(92, 42)
		b.pressed.connect(_pick.bind(i))
		row.add_child(b)
		tier_buttons.append(b)

	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 14)
	result_label.custom_minimum_size.y = 20
	box.add_child(result_label)

	skip_button = Button.new()
	skip_button.text = "SKIP"
	skip_button.pressed.connect(close)
	box.add_child(skip_button)

func open() -> void:
	if GameManager.luck.wager_used or GameManager.luck.wager_stake() < 20:
		return
	_busy = false
	result_label.text = ""
	skip_button.text = "SKIP"
	skip_button.disabled = false
	visible = true
	_update()

func close() -> void:
	visible = false

func _process(_delta : float) -> void:
	if visible and not _busy:
		_update()   # เหรียญสุดท้ายยังลอยมาเก็บอยู่ -> stake เพิ่มขึ้นเรื่อยๆ

func _update() -> void:
	var stake : int = GameManager.luck.wager_stake()
	stake_label.text = "Stake: $%d  (earned this wave)" % stake
	for i in tier_buttons.size():
		var t : Dictionary = GameManager.luck.tiers[i]
		tier_buttons[i].text = "%s\nx%.1f  %d%%" % [t["name"], float(t["mult"]), roundi(GameManager.luck.wager_chance(i) * 100.0)]
		tier_buttons[i].disabled = stake <= 0

func _pick(tier : int) -> void:
	if _busy:
		return
	var stake : int = GameManager.luck.wager_stake()
	if stake <= 0:
		return
	_busy = true
	GameManager.luck.wager_used = true
	for b in tier_buttons:
		b.disabled = true
	skip_button.disabled = true
	var res : Dictionary = GameManager.luck.roll_wager(tier, stake)
	# ตัวเลขสุ่มวิ่งเร็วๆ แล้วค่อยช้าลง ก่อนเฉลย
	var tw := create_tween()
	for k in 9:
		tw.tween_callback(_flicker.bind(stake))
		tw.tween_interval(0.07 + 0.02 * k)
	tw.tween_callback(_reveal.bind(res))

func _flicker(stake : int) -> void:
	result_label.add_theme_color_override("font_color", GameTheme.MUTED)
	result_label.text = "%+d" % roundi(randf_range(-1.0, 4.0) * stake)

func _reveal(res : Dictionary) -> void:
	GameManager.luck.commit_wager(res)
	if res["won"]:
		result_label.add_theme_color_override("font_color", GameTheme.GOOD)
		result_label.text = "WIN  +$%d" % int(res["delta"])
	else:
		result_label.add_theme_color_override("font_color", GameTheme.BAD)
		result_label.text = "LOST  -$%d" % absi(int(res["delta"]))
	skip_button.text = "CONTINUE"
	skip_button.disabled = false
