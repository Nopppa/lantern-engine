extends RefCounted
class_name LightWorldBuilder

const LightWorld = preload("res://scripts/gameplay/light_world.gd")

static func from_run_scene(run) -> LightWorld:
	var entities: Array = []
	if run.prism_node and is_instance_valid(run.prism_node):
		entities.append({
			"kind": "prism_node",
			"pos": run.prism_node.position,
			"radius": run.current_prism_radius(),
			"material_id": "prism"
		})
	return LightWorld.new([], [], entities, {
		"world_type": "arena_runtime",
		"arena_rect": run.ARENA_RECT,
		"note": "Phase-1 scaffold: explicit light-world boundary for authored and future generated maps."
	})

static func from_light_lab_scene(lab) -> LightWorld:
	var entities: Array = []
	for prism_station: Dictionary in lab.prism_stations:
		entities.append({
			"kind": "prism_station",
			"pos": prism_station.get("pos", Vector2.ZERO),
			"radius": prism_station.get("radius", 18.0),
			"material_id": "prism"
		})
	if lab.prism_node and is_instance_valid(lab.prism_node):
		entities.append({
			"kind": "prism_node",
			"pos": lab.prism_node.position,
			"radius": lab.current_prism_radius(),
			"material_id": "prism"
		})
	for trunk: Dictionary in lab.tree_trunks:
		entities.append({
			"kind": "tree_trunk",
			"pos": trunk.get("pos", Vector2.ZERO),
			"radius": trunk.get("radius", 0.0),
			"material_id": "tree"
		})
	return LightWorld.new(lab.surface_segments, lab.surface_patches, entities, {
		"world_type": "light_lab",
		"arena_rect": lab.ARENA_RECT,
		"ready_for_randomgen": true,
		"note": "Procedural maps should emit the same occluder/material/entity boundary."
	})
