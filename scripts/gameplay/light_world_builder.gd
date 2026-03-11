extends RefCounted
class_name LightWorldBuilder

const LightWorld = preload("res://scripts/gameplay/light_world.gd")
const LightTypes = preload("res://scripts/gameplay/light_types.gd")
const LightMaterials = preload("res://scripts/data/light_materials.gd")

static var _layout_cache := {}

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
	var layout := {
		"segments": lab.surface_segments,
		"patches": lab.surface_patches,
		"prism_stations": lab.prism_stations,
		"tree_trunks": lab.tree_trunks,
		"dead_alive_cells": lab._dead_alive_zone_defs()
	}
	return cached_from_layout("light_lab_scene", layout, lab.ARENA_RECT, {
		"world_type": "light_lab",
		"adapter": "light_world_builder.from_light_lab_scene",
		"runtime_entities": _runtime_entities_for_lab(lab)
	})

static func build_light_lab_smoke_test(arena_rect: Rect2) -> LightWorld:
	return cached_from_layout("generated_smoke_test", build_light_lab_smoke_test_layout(arena_rect), arena_rect, {
		"world_type": "generated_smoke_test",
		"ready_for_randomgen": true,
		"smoke_test": true,
		"adapter": "light_world_builder.build_light_lab_smoke_test"
	})

static func build_light_lab_smoke_test_layout(arena_rect: Rect2) -> Dictionary:
	return {
		"segments": _arena_boundary_segments(arena_rect) + [
			{"a": Vector2(300, 176), "b": Vector2(300, 488), "normal": Vector2.LEFT, "material_id": "brick"},
			{"a": Vector2(300, 488), "b": Vector2(560, 488), "normal": Vector2.UP, "material_id": "mirror"},
			{"a": Vector2(560, 488), "b": Vector2(560, 260), "normal": Vector2.RIGHT, "material_id": "glass"},
			{"a": Vector2(640, 220), "b": Vector2(860, 220), "normal": Vector2.DOWN, "material_id": "wood"}
		],
		"patches": [
			_normalized_patch(Rect2(arena_rect.position, arena_rect.size), "brick", "Generated floor"),
			_normalized_patch(Rect2(Vector2(340, 220), Vector2(180, 110)), "wet", "Generated wet strip"),
			_normalized_patch(Rect2(Vector2(618, 260), Vector2(170, 128)), "glass", "Generated glass lane")
		],
		"prism_stations": [
			{"pos": Vector2(704, 316), "radius": 18.0, "label": "Generated prism station"}
		],
		"tree_trunks": [
			{"pos": Vector2(430, 380), "radius": 28.0, "label": "Tree Trunk"},
			{"pos": Vector2(720, 420), "radius": 24.0, "label": "Tree Trunk"}
		],
		"dead_alive_cells": [
			{"rect": Rect2(Vector2(112, 112), Vector2(224, 128)), "value": 0.95},
			{"rect": Rect2(Vector2(612, 248), Vector2(240, 132)), "value": 0.72},
			{"rect": Rect2(Vector2(860, 448), Vector2(164, 112)), "value": 0.48}
		],
		"spawn_hint": Vector2(924, 516)
	}

static func cached_from_layout(cache_key: String, layout: Dictionary, arena_rect: Rect2, options: Dictionary = {}) -> LightWorld:
	var signature := _layout_signature(layout, arena_rect, options)
	var existing: Dictionary = _layout_cache.get(cache_key, {})
	var base_world: LightWorld = null
	var cache_hit := false
	if not existing.is_empty() and String(existing.get("signature", "")) == signature:
		base_world = existing.get("world", null)
		cache_hit = base_world != null
	if base_world == null:
		base_world = build_from_layout(layout, arena_rect, options)
		_layout_cache[cache_key] = {"signature": signature, "world": base_world}
	var runtime_entities: Array = Array(options.get("runtime_entities", []))
	var runtime_meta := {
		"cache_key": cache_key,
		"cache_hit": cache_hit,
		"static_signature": signature,
		"runtime_entity_count": runtime_entities.size()
	}
	return base_world.clone_with_entities(base_world.light_entities + runtime_entities, runtime_meta)

static func build_from_layout(layout: Dictionary, arena_rect: Rect2, options: Dictionary = {}) -> LightWorld:
	var segments: Array = []
	for segment: Dictionary in Array(layout.get("segments", [])):
		segments.append(segment.duplicate(true))
	var patches: Array = []
	for patch: Dictionary in Array(layout.get("patches", [])):
		var normalized_patch := patch.duplicate(true)
		var material_id := String(normalized_patch.get("material_id", "brick"))
		normalized_patch["material_spec"] = LightTypes.light_material_spec(material_id, LightMaterials.get_definition(material_id))
		patches.append(normalized_patch)
	var entities: Array = []
	for prism_station: Dictionary in Array(layout.get("prism_stations", [])):
		entities.append({
			"kind": "prism_station",
			"pos": prism_station.get("pos", Vector2.ZERO),
			"radius": prism_station.get("radius", 18.0),
			"material_id": "prism"
		})
	for trunk: Dictionary in Array(layout.get("tree_trunks", [])):
		entities.append({
			"kind": "tree_trunk",
			"pos": trunk.get("pos", Vector2.ZERO),
			"radius": trunk.get("radius", 0.0),
			"material_id": "tree",
			"material_spec": LightTypes.light_material_spec("tree", {"label": "Tree Trunk"})
		})
	var metadata := {
		"world_type": String(options.get("world_type", "generated_layout")),
		"arena_rect": arena_rect,
		"ready_for_randomgen": bool(options.get("ready_for_randomgen", true)),
		"adapter": String(options.get("adapter", "light_world_builder.build_from_layout")),
		"dead_alive_zones": Array(layout.get("dead_alive_cells", [])).duplicate(true),
		"spawn_hint": layout.get("spawn_hint", Vector2.INF),
		"layout_signature": _layout_signature(layout, arena_rect, options)
	}
	for key in options.keys():
		if metadata.has(key):
			continue
		if key == "runtime_entities":
			continue
		metadata[key] = options[key]
	return LightWorld.new(segments, patches, entities, metadata)

static func _runtime_entities_for_lab(lab) -> Array:
	var runtime_entities: Array = []
	if lab.prism_node and is_instance_valid(lab.prism_node):
		runtime_entities.append({
			"kind": "prism_node",
			"pos": lab.prism_node.position,
			"radius": lab.current_prism_radius(),
			"material_id": "prism"
		})
	return runtime_entities

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

static func _layout_signature(layout: Dictionary, arena_rect: Rect2, options: Dictionary = {}) -> String:
	var bits: PackedStringArray = []
	bits.append("rect:%d:%d:%d:%d" % [int(arena_rect.position.x), int(arena_rect.position.y), int(arena_rect.size.x), int(arena_rect.size.y)])
	for segment: Dictionary in Array(layout.get("segments", [])):
		bits.append("seg:%d:%d:%d:%d:%s" % [int(round(Vector2(segment.get("a", Vector2.ZERO)).x)), int(round(Vector2(segment.get("a", Vector2.ZERO)).y)), int(round(Vector2(segment.get("b", Vector2.ZERO)).x)), int(round(Vector2(segment.get("b", Vector2.ZERO)).y)), String(segment.get("material_id", ""))])
	for patch: Dictionary in Array(layout.get("patches", [])):
		var rect: Rect2 = patch.get("rect", Rect2())
		bits.append("patch:%d:%d:%d:%d:%s:%s" % [int(round(rect.position.x)), int(round(rect.position.y)), int(round(rect.size.x)), int(round(rect.size.y)), String(patch.get("material_id", "")), String(patch.get("title", patch.get("label", "")))])
	for station: Dictionary in Array(layout.get("prism_stations", [])):
		var pos: Vector2 = station.get("pos", Vector2.ZERO)
		bits.append("station:%d:%d:%d" % [int(round(pos.x)), int(round(pos.y)), int(round(float(station.get("radius", 0.0))))])
	for trunk: Dictionary in Array(layout.get("tree_trunks", [])):
		var tree_pos: Vector2 = trunk.get("pos", Vector2.ZERO)
		bits.append("tree:%d:%d:%d" % [int(round(tree_pos.x)), int(round(tree_pos.y)), int(round(float(trunk.get("radius", 0.0))))])
	for zone: Dictionary in Array(layout.get("dead_alive_cells", [])):
		var zone_rect: Rect2 = zone.get("rect", Rect2())
		bits.append("zone:%d:%d:%d:%d:%d" % [int(round(zone_rect.position.x)), int(round(zone_rect.position.y)), int(round(zone_rect.size.x)), int(round(zone_rect.size.y)), int(round(float(zone.get("value", 0.0)) * 100.0))])
	bits.append("world:%s" % String(options.get("world_type", "generated_layout")))
	return "|".join(bits)
