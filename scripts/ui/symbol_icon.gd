extends Control
class_name SymbolIcon
# วาดสัญลักษณ์อัญมณีของสล็อตด้วยโค้ด (ไม่ต้องมีรูป): Ruby / Sapphire / Emerald / Amethyst / Star

const COLORS : Array[Color] = [
	Color(1.0, 0.30, 0.43),   # Ruby
	Color(0.30, 0.65, 1.0),   # Sapphire
	Color(0.30, 1.0, 0.65),   # Emerald
	Color(0.70, 0.40, 1.0),   # Amethyst
	Color(1.0, 0.83, 0.35),   # Star (jackpot)
]

var symbol : int = 0 :
	set(value):
		symbol = value
		queue_redraw()

func _init(icon_size : int = 40) -> void:
	custom_minimum_size = Vector2(icon_size, icon_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var c : Vector2 = size * 0.5
	var r : float = minf(size.x, size.y) * 0.42
	var col : Color = COLORS[clampi(symbol, 0, COLORS.size() - 1)]
	var pts : PackedVector2Array
	match symbol:
		0: pts = _ngon(c, r, 4, -PI / 2.0)    # ทรงข้าวหลามตัด
		1: pts = _ngon(c, r, 24, 0.0)         # วงกลม
		2: pts = _ngon(c, r, 6, 0.0)          # หกเหลี่ยม
		3: pts = _ngon(c, r, 5, -PI / 2.0)    # ห้าเหลี่ยม
		_: pts = _star(c, r * 1.1, r * 0.5)   # ดาว
	draw_colored_polygon(pts, col.darkened(0.5))
	draw_colored_polygon(_scaled(pts, c, 0.82, Vector2.ZERO), col)
	draw_colored_polygon(_scaled(pts, c, 0.32, Vector2(-r * 0.22, -r * 0.24)), col.lightened(0.55))
	var closed : PackedVector2Array = pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, col.lightened(0.35), 1.0)

func _ngon(center : Vector2, radius : float, sides : int, rot : float) -> PackedVector2Array:
	var out : PackedVector2Array = []
	for i in sides:
		var a : float = rot + TAU * float(i) / float(sides)
		out.append(center + Vector2(cos(a), sin(a)) * radius)
	return out

func _star(center : Vector2, outer : float, inner : float) -> PackedVector2Array:
	var out : PackedVector2Array = []
	for i in 10:
		var a : float = -PI / 2.0 + TAU * float(i) / 10.0
		var rad : float = outer if i % 2 == 0 else inner
		out.append(center + Vector2(cos(a), sin(a)) * rad)
	return out

func _scaled(pts : PackedVector2Array, center : Vector2, factor : float, offset : Vector2) -> PackedVector2Array:
	var out : PackedVector2Array = []
	for p in pts:
		out.append(center + (p - center) * factor + offset)
	return out
