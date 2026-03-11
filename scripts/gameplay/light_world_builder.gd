extends RefCounted
class_name LightWorldBuilder

const LightWorld = preload("res://scripts/gameplay/light_world.gd")
const LightTypes = preload("res://scripts/gameplay/light_types.gd")
const LightMaterials = preload("res://scripts/data/light_materials.gd")

static func from_run_scene(run) -> LightWorld:
	var segments: Array = _arena_boundary_segments(run.ARENA_RECT)
	var patches: Array = [{
		"rect": run.ARENA_RECT,
		"material_id": "brick",
		"label": "Arena floor",
		"material_spec": LightTypes.light_material_spec("brick", {"label": "Arena floor"})
	}]
	var entities: Array = [{
		"kind": "player_anchor",
		"pos": run.player_pos,
		"material_id": "open"
	}]
	if run.prism_node and is_instance_valid(run.prism_node):
		entities.append({
			"kind": "prism_node",
			"pos": run.prism_node.position,
			"radius": run.current_prism_radius(),
			"material_id": "prism"
		})
	return LightWorld.new(segments, patches, entities, {
		"world_type": "arena_runtime",
		"arena_rect": run.ARENA_RECT,
		"shared_boundary_ready": true,
		"note": "Arena runtime now emits a concrete LightWorld boundary for shared solver/presentation flow."
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
			"material_id": "tree",
			"material_spec": LightTypes.light_material_spec("tree", {"label": "Tree Trunk"})
		})
	var patches: Array = []
	for patch: Dictionary in lab.surface_patches:
		var normalized_patch := patch.duplicate(true)
		var material_id := String(normalized_patch.get("material_id", "brick"))
		normalized_patch["material_spec"] = LightTypes.light_material_spec(material_id, LightMaterials.get_definition(material_id))
		patches.append(normalized_patch)
	return LightWorld.new(lab.surface_segments, patches, entities, {
		"world_type": "light_lab",
		"arena_rect": lab.ARENA_RECT,
		"ready_for_randomgen": true,
		"note": "Procedural maps should emit the same occluder/material/entity boundary."
	})

static func build_light_lab_smoke_test(arena_rect: Rect2) -> LightWorld:
	var segments: Array = _arena_boundary_segments(arena_rect)
	segments.append_array([
		{"a": Vector2(300, 176), "b": Vector2(300, 488), "normal": Vector2.LEFT, "material_id": "brick"},
		{"a": Vector2(300, 488), "b": Vector2(560, 488), "normal": Vector2.UP, "material_id": "mirror"},
		{"a": Vector2(560, 488), "b": Vector2(560, 260), "normal": Vector2.RIGHT, "material_id": "glass"},
		{"a": Vector2(640, 220), "b": Vector2(860, 220), "normal": Vector2.DOWN, "material_id": "wood"}
	])
	var patches: Array = [
		_normalized_patch(Rect2(arena_rect.position, arena_rect.size), "brick", "Generated floor"),
		_normalized_patch(Rect2(Vector2(340, 220), Vector2(180, 110)), "wet", "Generated wet strip"),
		_normalized_patch(Rect2(Vector2(618, 260), Vector2(170, 128)), "glass", "Generated glass lane")
	]
	var entities: Array = [
		{"kind": "tree_trunk", "pos": Vector2(430, 380), "radius": 28.0, "material_id": "tree", "material_spec": LightTypes.light_material_spec("tree", {"label": "Tree Trunk"})},
		{"kind": "tree_trunk", "pos": Vector2(720, 420), "radius": 24.0, "material_id": "tree", "material_spec": LightTypes.light_material_spec("tree", {"label": "Tree Trunk"})},
		{"kind": "prism_station", "pos": Vector2(704, 316), "radius": 18.0, "material_id": "prism"}
	]
	return LightWorld.new(segments, patches, entities, {
		"world_type": "generated_smoke_test",
		"arena_rect": arena_rect,
		"ready_for_randomgen": true,
		"smoke_test": true,
		"adapter": "light_world_builder.build_light_lab_smoke_test",
		"dead_alive_zones": [
			{"rect": Rect2(Vector2(112, 112), Vector2(224, 128)), "value": 0.95},
			{"rect": Rect2(Vector2(612, 248), Vector2(240, 132)), "value": 0.72},
			{"rect": Rect2(Vector2(860, 448), Vector2(164, 112)), "value": 0.48}
		],
		"spawn_hint": Vector2(924, 516)
	})

static func _normalized_patch(rect: Rect2, material_id: String, label: String) -> Dictionary:
	return {
		"rect": rect,
		"material_id": material_id,
		"label": label,
		"title": label,
		"material_spec": LightTypes.light_material_spec(material_id, LightMaterials.get_definition(material_id))
	}

static func _arena_boundary_segments(rect: Rect2) -> Array:
	return [
		{"a": rect.position, "b": Vector2(rect.end.x, rect.position.y), "normal": Vector2.DOWN, "material_id": "brick"},
		{"a": Vector2(rect.end.x, rect.position.y), "b": rect.end, "normal": Vector2.LEFT, "material_id": "brick"},
		{"a": rect.end, "b": Vector2(rect.position.x, rect.end.y), "normal": Vector2.UP, "material_id": "brick"},
		{"a": Vector2(rect.position.x, rect.end.y), "b": rect.position, "normal": Vector2.RIGHT, "material_id": "brick"}
	]
