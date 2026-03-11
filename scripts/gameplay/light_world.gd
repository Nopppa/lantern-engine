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

func collision_space() -> Dictionary:
	return {
		"segments": occluder_segments.duplicate(true),
		"circles": entity_list("tree_trunk")
	}

func prism_emitters() -> Array:
	var emitters: Array = []
	emitters.append_array(entity_list("prism_station"))
	emitters.append_array(entity_list("prism_node"))
	return emitters

func metadata_array(key: String) -> Array:
	var value = metadata.get(key, [])
	return Array(value).duplicate(true)

func clone_with_entities(entities: Array, metadata_patch: Dictionary = {}):
	var merged_meta := metadata.duplicate(true)
	for key in metadata_patch.keys():
		merged_meta[key] = metadata_patch[key]
	return get_script().new(occluder_segments, material_patches, entities, merged_meta)
