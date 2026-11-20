extends RefCounted
class_name SlotLogic
# ตรรกะสล็อต 3 reel (ใช้ทั้งใน shop และหน้าเมนู) -- ไม่มี UI ในนี้
# RTP คำนวณด้วย python sim: ~92% ที่ luck 0, ~105% ที่ luck 1.0 (Luck crystal มีค่าจริง)

enum Sym { RUBY, SAPPHIRE, EMERALD, AMETHYST, STAR }

const NAMES : Array[String] = ["Ruby", "Sapphire", "Emerald", "Amethyst", "Star"]
const WEIGHTS : Array[float] = [30.0, 26.0, 22.0, 14.0, 8.0]
const TRIPLE : Array[float] = [5.0, 8.0, 12.0, 25.0, 60.0]   # x ราคาหมุน
const PAIR : Array[float] = [0.6, 0.7, 0.8, 1.2, 2.5]        # x ราคาหมุน (สองตัวเหมือน)

static func roll_symbol(luck : float) -> int:
	var w : Array = WEIGHTS.duplicate()
	w[3] = float(w[3]) * (1.0 + 0.5 * luck)   # Luck ดัน Amethyst / Star ให้ออกบ่อยขึ้น
	w[4] = float(w[4]) * (1.0 + 1.0 * luck)
	var total : float = 0.0
	for x in w:
		total += float(x)
	var r : float = randf() * total
	for i in w.size():
		r -= float(w[i])
		if r <= 0.0:
			return i
	return 0

# force_pair = pity: ถ้าแพ้ติดกันหลายรอบ รอบนี้การันตีอย่างน้อยคู่
static func roll(luck : float, force_pair : bool = false) -> Array[int]:
	var result : Array[int] = []
	for i in 3:
		result.append(roll_symbol(luck))
	if force_pair and evaluate(result)["kind"] == 0:
		result[1] = result[0]
	return result

# kind: 3 = สามตัวเหมือน, 2 = คู่, 0 = ไม่ตรง
static func evaluate(symbols : Array) -> Dictionary:
	var counts : Dictionary = {}
	for s in symbols:
		counts[s] = int(counts.get(s, 0)) + 1
	for s in counts:
		if counts[s] == 3:
			return {"kind": 3, "symbol": int(s), "mult": TRIPLE[int(s)]}
	for s in counts:
		if counts[s] == 2:
			return {"kind": 2, "symbol": int(s), "mult": PAIR[int(s)]}
	return {"kind": 0, "symbol": -1, "mult": 0.0}

# โบนัสเริ่มเกมจากสล็อตฟรีหน้าเมนู
static func start_bonus(symbols : Array) -> Dictionary:
	var ev : Dictionary = evaluate(symbols)
	match int(ev["kind"]):
		3:
			return {"gold": 300, "max_hp": 20, "free_crystal": true,
				"text": "TRIPLE!  +$300  +20 Max HP  + free crystal"}
		2:
			return {"gold": 150, "max_hp": 10, "free_crystal": false,
				"text": "PAIR!  +$150  +10 Max HP"}
	return {"gold": 60, "max_hp": 0, "free_crystal": false,
		"text": "No match  +$60"}
