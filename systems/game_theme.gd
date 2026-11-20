extends RefCounted
class_name GameTheme
# ธีม "Crystal Casino" สร้างด้วยโค้ดล้วน (ไม่ต้องใช้ asset / ไม่ต้องแก้ project.godot)
# ถูก inject ที่ root window ตอน GameManager._ready() -> ทุก Control ในเกมรับธีมนี้อัตโนมัติ
# ออกแบบสำหรับจอ 640x360 : ฟอนต์เล็ก 11px, padding แน่น

const BG := Color(0.075, 0.063, 0.122)
const PANEL := Color(0.122, 0.094, 0.196)
const PANEL_LIGHT := Color(0.173, 0.137, 0.278)
const BORDER := Color(0.357, 0.247, 0.627)
const TEXT := Color(0.914, 0.894, 1.0)
const MUTED := Color(0.604, 0.565, 0.741)
const GOLD := Color(1.0, 0.83, 0.35)
const GOOD := Color(0.43, 0.94, 0.63)
const BAD := Color(1.0, 0.36, 0.42)
const ACCENT := Color(0.56, 0.42, 1.0)

const FONT_SIZE : int = 11

static func element_color(type : String) -> Color:
	match type:
		"physical damage": return Color(0.85, 0.85, 0.90)
		"fire damage": return Color(1.0, 0.42, 0.24)
		"wind damage": return Color(0.43, 0.94, 0.76)
		"water damage": return Color(0.30, 0.65, 1.0)
		"earth damage": return Color(0.69, 0.545, 0.33)
		"light damage": return Color(1.0, 0.89, 0.37)
		"darkness damage": return Color(0.54, 0.30, 1.0)
	return MUTED

# "fire damage" -> "Fire Dmg" , "crit rate" -> "Crit Rate"
static func nice(type : String) -> String:
	if type.ends_with(" damage"):
		return type.replace(" damage", "").capitalize() + " Dmg"
	return type.capitalize()

static func _box(bg : Color, border : Color, radius : int = 3, border_w : int = 1, pad_x : int = 8, pad_y : int = 3) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	return sb

static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_SIZE

	# ---------- Label ----------
	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Label", FONT_SIZE)

	# ---------- Button ----------
	t.set_stylebox("normal", "Button", _box(PANEL_LIGHT, BORDER))
	t.set_stylebox("hover", "Button", _box(PANEL_LIGHT.lightened(0.15), ACCENT))
	t.set_stylebox("pressed", "Button", _box(ACCENT.darkened(0.35), GOLD))
	t.set_stylebox("disabled", "Button", _box(PANEL.darkened(0.2), PANEL_LIGHT))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_hover_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", MUTED.darkened(0.35))
	t.set_font_size("font_size", "Button", FONT_SIZE)

	# ---------- Panels ----------
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, BORDER, 4, 1, 8, 6))
	t.set_stylebox("panel", "Panel", _box(PANEL, BORDER, 4, 1, 4, 4))

	# ---------- ProgressBar (HP bar) ----------
	t.set_stylebox("background", "ProgressBar", _box(Color(0.05, 0.04, 0.08), BORDER, 3, 1, 0, 0))
	t.set_stylebox("fill", "ProgressBar", _box(BAD, BAD.lightened(0.3), 3, 0, 0, 0))
	t.set_color("font_color", "ProgressBar", TEXT)

	# ---------- ScrollBar (บางๆ เพราะจอเล็ก) ----------
	for bar in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", bar, _box(Color(0.05, 0.04, 0.08), Color(0, 0, 0, 0), 2, 0, 2, 2))
		t.set_stylebox("scroll_focus", bar, _box(Color(0.05, 0.04, 0.08), Color(0, 0, 0, 0), 2, 0, 2, 2))
		t.set_stylebox("grabber", bar, _box(BORDER, BORDER, 2, 0, 2, 2))
		t.set_stylebox("grabber_highlight", bar, _box(ACCENT, ACCENT, 2, 0, 2, 2))
		t.set_stylebox("grabber_pressed", bar, _box(GOLD, GOLD, 2, 0, 2, 2))
	return t
