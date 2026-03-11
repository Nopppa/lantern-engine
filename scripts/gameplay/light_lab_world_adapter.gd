extends RefCounted
class_name LightLabWorldAdapter

const LightWorldBuilder = preload("res://scripts/gameplay/light_world_builder.gd")

static func build(layout: Dictionary, arena_rect: Rect2, prism_node = null, prism_radius: float = 18.0, options: Dictionary = {}) -> Dictionary:
	var prism_stations: Array = Array(layout.get("prism_stations", [])).duplicate(true)
	var tree_trunks: Array = Array(layout.get("tree_trunks", [])).duplicate(true)
	var runtime_entities: Array = []
	if prism_node != null and is_instance_valid(prism_node):
		runtime_entities.append({
			"kind": "prism_node",
			"pos": prism_node.position,
			"radius": prism_radius,
			"material_id": "prism"
		})
	var builder_options := options.duplicate(true)
	builder_options["runtime_entities"] = runtime_entities
	var cache_key := String(builder_options.get("cache_key", builder_options.get("world_type", "light_lab")))
	var world := LightWorldBuilder.cached_from_layout(cache_key, layout, arena_rect, builder_options)
	return {
		"surface_segments": world.occluder_segments.duplicate(true),
		"surface_patches": world.material_patches.duplicate(true),
		"prism_stations": prism_stations,
		"tree_trunks": tree_trunks,
		"light_world": world
	}
