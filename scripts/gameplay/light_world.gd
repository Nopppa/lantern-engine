extends RefCounted
class_name LightWorld

var occluder_segments: Array = []
var material_patches: Array = []
var light_entities: Array = []
var metadata: Dictionary = {}

func _init(segments: Array = [], patches: Array = [], entities: Array = [], meta: Dictionary = {}) -> void:
	occluder_segments = segments.duplicate(true)
	material_patches = patches.duplicate(true)
	light_entities = entities.duplicate(true)
	metadata = meta.duplicate(true)

func entity_list(kind: String = "") -> Array:
	if kind.is_empty():
		return light_entities.duplicate(true)
	var matches: Array = []
	for entity: Dictionary in light_entities:
		if String(entity.get("kind", "")) == kind:
			matches.append(entity.duplicate(true))
	return matches

func find_patch_at(pos: Vector2) -> Dictionary:
	for patch: Dictionary in material_patches:
		if Rect2(patch.get("rect", Rect2())).has_point(pos):
			return patch.duplicate(true)
	return {}

func all_blockers() -> Array:
	var blockers: Array = occluder_segments.duplicate(true)
	for entity: Dictionary in light_entities:
		match String(entity.get("kind", "")):
			"tree_trunk":
				blockers.append({
					"kind": "circle",
					"pos": entity.get("pos", Vector2.ZERO),
					"radius": float(entity.get("radius", 0.0)),
					"material_id": entity.get("material_id", "tree")
				})
	return blockers
