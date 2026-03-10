extends RefCounted
class_name BossDefs

const BOSS_FILES := {
	"hollow_matriarch": "res://scripts/data/bosses/hollow_matriarch.json"
}

static var _cache := {}

static func get_boss(id: String) -> Dictionary:
	if _cache.has(id):
		return Dictionary(_cache[id]).duplicate(true)
	var path := String(BOSS_FILES.get(id, ""))
	if path.is_empty():
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("BossDefs could not open %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("BossDefs expected dictionary in %s" % path)
		return {}
	_cache[id] = parsed
	return Dictionary(parsed).duplicate(true)
