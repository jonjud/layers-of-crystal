extends RefCounted
class_name CrystalCatalog
# รายการ crystal ทั้งหมดที่เกมรู้จัก (แหล่งเดียว: shop / สล็อตหน้าเมนู ใช้ร่วมกัน)
# เพิ่ม crystal ใหม่: สร้าง .tres แล้วเติม path ตรงนี้

const PATHS : Array[String] = [
	"res://resources/crystals/ember_core.tres",
	"res://resources/crystals/crimson_edge.tres",
	"res://resources/crystals/tidal_shard.tres",
	"res://resources/crystals/gaia_plate.tres",
	"res://resources/crystals/zephyr_prism.tres",
	"res://resources/crystals/solar_lumen.tres",
	"res://resources/crystals/umbral_void.tres",
	"res://resources/crystals/gale_rune.tres",
]

static var _cache : Array[CrystalData] = []

static func all() -> Array[CrystalData]:
	if _cache.is_empty():
		for path in PATHS:
			var res : Resource = load(path)
			if res is CrystalData:
				_cache.append(res)
	return _cache
