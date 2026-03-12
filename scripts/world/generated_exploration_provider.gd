## GeneratedExplorationProvider
##
## Produces procedurally-generated layouts for the exploration world.
## RandomGEN Layout v2 moves away from loose arena scatter toward a deterministic
## graph of playable zones connected by corridors, with deliberate material
## themes, prism placement, and route blockers that still compile into the
## shared LightWorld pipeline.
##
class_name GeneratedExplorationProvider
extends WorldLayoutProvider

const LightWorldBuilder = preload("res://scripts/gameplay/light_world_builder.gd")

const CONNECTOR_HALF_WIDTH := 46.0
const MIN_ZONE_COUNT := 3
const MAX_ZONE_COUNT := 7
const ZONE_ARCHETYPES := ["mirror", "glass", "wet", "wood", "wet"]

var _seed: int
var _arena_rect: Rect2
var _last_layout: Dictionary = {}

func _init(seed_value: int, arena_rect: Rect2) -> void:
	_seed = seed_value
	_arena_rect = arena_rect

# --- WorldLayoutProvider interface ---

func build_static_layout(options: Dictionary = {}) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	_last_layout = _build_graph_layout(rng)
	return _last_layout

func build_light_world(layout: Dictionary, arena_rect: Rect2, options: Dictionary = {}) -> LightWorld:
	var merged := _base_options().merged(options)
	merged["layout_nodes"] = Array(layout.get("layout_nodes", [])).duplicate(true)
	merged["layout_links"] = Array(layout.get("layout_links", [])).duplicate(true)
	merged["zone_summaries"] = Array(layout.get("zone_summaries", [])).duplicate(true)
	merged["graph_depth"] = int(layout.get("graph_depth", 0))
	merged["progression_node_id"] = String(layout.get("progression_node_id", ""))
	merged["spawn_node_id"] = String(layout.get("spawn_node_id", "spawn"))
	merged["generated_seed"] = _seed
	return super.build_light_world(layout, arena_rect, merged)

func spawn_hint() -> Vector2:
	if _last_layout.is_empty():
		build_static_layout()
	var hint = _last_layout.get("spawn_hint", Vector2.INF)
	if hint is Vector2:
		return hint
	return Vector2.INF

func metadata() -> Dictionary:
	return {
		"world_type": "generated_exploration",
		"provider": "GeneratedExplorationProvider",
		"generator_version": "layout_v2",
		"seed": _seed,
		"arena_rect": _arena_rect,
		"ready_for_randomgen": true
	}

func _base_options() -> Dictionary:
	return {
		"world_type": "generated_exploration",
		"cache_key": "generated_exploration_%d" % _seed,
		"ready_for_randomgen": true,
		"adapter": "generated_exploration_provider",
		"generated_seed": _seed,
		"generator_version": "layout_v2"
	}

# --- Convenience API ---

func reseed(new_seed: int) -> void:
	_seed = new_seed
	_last_layout = {}

func build_world() -> LightWorld:
	var layout := build_static_layout()
	return build_light_world(layout, _arena_rect)

func current_seed() -> int:
	return _seed

# --- Layout v2 implementation ---

func _build_graph_layout(rng: RandomNumberGenerator) -> Dictionary:
	var segments: Array = LightWorldBuilder._arena_boundary_segments(_arena_rect)
	var patches: Array = [
		LightWorldBuilder._normalized_patch(Rect2(_arena_rect.position, _arena_rect.size), "brick", "Generated world floor")
	]
	var prism_stations: Array = []
	var tree_trunks: Array = []
	var dead_alive_cells: Array = []
	var layout_nodes: Array = []
	var layout_links: Array = []
	var zone_summaries: Array = []
	var used_rects: Array = []

	var spawn_size := Vector2(176, 148)
	var spawn_rect := Rect2(
		Vector2(_arena_rect.position.x + 86.0, _arena_rect.position.y + _arena_rect.size.y * 0.5 - spawn_size.y * 0.5),
		spawn_size
	)
	var spawn_node := {
		"id": "spawn",
		"kind": "spawn",
		"depth": 0,
		"theme": "calm",
		"rect": spawn_rect,
		"center": spawn_rect.get_center()
	}
	layout_nodes.append(spawn_node)
	used_rects.append(spawn_rect)
	patches.append(LightWorldBuilder._normalized_patch(spawn_rect.grow(18.0), "wood", "Calm spawn grove"))
	dead_alive_cells.append(_zone_energy(spawn_rect.grow(12.0), 0.92, "wood", "spawn"))

	var zone_count := rng.randi_range(MIN_ZONE_COUNT, MAX_ZONE_COUNT)
	var progression_index := zone_count - 1
	var lane_count := max(2, mini(3, zone_count))
	var lane_y := [0.28, 0.54, 0.76]
	var previous_zone_centers := {}
	var node_id_order: Array = ["spawn"]
	var last_zone_center := spawn_rect.get_center()

	for i in range(zone_count):
		var lane_index := i % lane_count
		var depth := i + 1
		var theme := _zone_theme_for_index(i)
		var zone_size := _zone_size_for_theme(theme, rng)
		var progress := float(i + 1) / float(zone_count + 1)
		var zone_rect := _place_zone_rect(rng, zone_size, progress, lane_y[lane_index], used_rects)
		used_rects.append(zone_rect)
		var node_kind := "progression" if i == progression_index else "zone"
		var node_id := ("exit" if node_kind == "progression" else "zone_%d" % (i + 1))
		var node := {
			"id": node_id,
			"kind": node_kind,
			"depth": depth,
			"theme": theme,
			"rect": zone_rect,
			"center": zone_rect.get_center(),
			"lane": lane_index
		}
		layout_nodes.append(node)
		node_id_order.append(node_id)
		var previous_center := spawn_rect.get_center() if i == 0 else last_zone_center
		layout_links.append(_build_link(segments, previous_center, zone_rect.get_center(), i == progression_index, "main"))
		if previous_zone_centers.has(lane_index):
			layout_links.append(_build_link(segments, previous_zone_centers[lane_index], zone_rect.get_center(), false, "branch"))
		previous_zone_centers[lane_index] = zone_rect.get_center()
		last_zone_center = zone_rect.get_center()

		var zone_result := _decorate_zone(theme, node, depth, i == progression_index, rng)
		patches.append_array(zone_result.get("patches", []))
		segments.append_array(zone_result.get("segments", []))
		prism_stations.append_array(zone_result.get("prism_stations", []))
		tree_trunks.append_array(zone_result.get("tree_trunks", []))
		dead_alive_cells.append_array(zone_result.get("dead_alive_cells", []))
		zone_summaries.append(zone_result.get("summary", {}))

	segments.append_array(_build_spawn_soft_cover(spawn_rect))
	prism_stations.append({
		"pos": spawn_rect.get_center() + Vector2(34.0, -10.0),
		"radius": 18.0,
		"label": "Spawn guide prism"
	})
	dead_alive_cells.append(_zone_energy(spawn_rect.grow(-10.0), 1.0, "wood", "spawn_core"))

	return {
		"segments": segments,
		"patches": patches,
		"prism_stations": prism_stations,
		"tree_trunks": tree_trunks,
		"dead_alive_cells": dead_alive_cells,
		"spawn_hint": spawn_rect.get_center() + Vector2(-36.0, 0.0),
		"generated_seed": _seed,
		"graph_depth": zone_count + 1,
		"spawn_node_id": "spawn",
		"progression_node_id": "exit",
		"layout_nodes": layout_nodes,
		"layout_links": layout_links,
		"zone_summaries": zone_summaries
	}

func _zone_theme_for_index(index: int) -> String:
	if index < ZONE_ARCHETYPES.size():
		return ZONE_ARCHETYPES[index]
	return "wood" if index % 2 == 0 else "wet"

func _zone_size_for_theme(theme: String, rng: RandomNumberGenerator) -> Vector2:
	match theme:
		"mirror":
			return Vector2(rng.randi_range(184, 228), rng.randi_range(152, 196))
		"glass":
			return Vector2(rng.randi_range(204, 250), rng.randi_range(148, 184))
		"wet":
			return Vector2(rng.randi_range(196, 238), rng.randi_range(168, 214))
		_:
			return Vector2(rng.randi_range(172, 214), rng.randi_range(144, 182))

func _place_zone_rect(rng: RandomNumberGenerator, size: Vector2, progress: float, lane_ratio: float, used_rects: Array) -> Rect2:
	var min_x := _arena_rect.position.x + 240.0
	var max_x := _arena_rect.end.x - size.x - 64.0
	var base_x := lerpf(min_x, max_x, clampf(progress, 0.0, 1.0))
	var min_y := _arena_rect.position.y + 58.0
	var max_y := _arena_rect.end.y - size.y - 58.0
	var base_y := lerpf(min_y, max_y, clampf(lane_ratio, 0.0, 1.0))
	for _attempt in range(20):
		var rect := Rect2(
			Vector2(
				clampf(base_x + rng.randf_range(-56.0, 56.0), min_x, max_x),
				clampf(base_y + rng.randf_range(-42.0, 42.0), min_y, max_y)
			),
			size
		)
		var overlaps := false
		for existing: Rect2 in used_rects:
			if rect.grow(34.0).intersects(existing):
				overlaps = true
				break
		if not overlaps:
			return rect
	return Rect2(Vector2(clampf(base_x, min_x, max_x), clampf(base_y, min_y, max_y)), size)

func _build_link(segments: Array, from_center: Vector2, to_center: Vector2, progression_link: bool, route_kind: String) -> Dictionary:
	var horizontal_first := absf(to_center.x - from_center.x) >= absf(to_center.y - from_center.y)
	var corridor_points := [from_center]
	if horizontal_first:
		corridor_points.append(Vector2(to_center.x, from_center.y))
	else:
		corridor_points.append(Vector2(from_center.x, to_center.y))
	corridor_points.append(to_center)
	for i in range(corridor_points.size() - 1):
		_add_corridor_segment(segments, corridor_points[i], corridor_points[i + 1], progression_link and i == corridor_points.size() - 2)
	return {
		"from": from_center,
		"to": to_center,
		"route_kind": route_kind,
		"progression": progression_link,
		"corridor_points": corridor_points
	}

func _add_corridor_segment(segments: Array, a: Vector2, b: Vector2, add_gate: bool) -> void:
	if a.distance_to(b) < 8.0:
		return
	var horizontal := absf(a.x - b.x) > absf(a.y - b.y)
	var min_x := minf(a.x, b.x)
	var max_x := maxf(a.x, b.x)
	var min_y := minf(a.y, b.y)
	var max_y := maxf(a.y, b.y)
	if horizontal:
		segments.append(_segment(Vector2(min_x, a.y - CONNECTOR_HALF_WIDTH), Vector2(max_x, a.y - CONNECTOR_HALF_WIDTH), Vector2.DOWN, "wood"))
		segments.append(_segment(Vector2(min_x, a.y + CONNECTOR_HALF_WIDTH), Vector2(max_x, a.y + CONNECTOR_HALF_WIDTH), Vector2.UP, "wood"))
		if add_gate:
			var gate_x := lerpf(min_x, max_x, 0.72)
			segments.append(_segment(Vector2(gate_x, a.y - CONNECTOR_HALF_WIDTH + 6.0), Vector2(gate_x, a.y + CONNECTOR_HALF_WIDTH - 6.0), Vector2.LEFT, "glass"))
	else:
		segments.append(_segment(Vector2(a.x - CONNECTOR_HALF_WIDTH, min_y), Vector2(a.x - CONNECTOR_HALF_WIDTH, max_y), Vector2.RIGHT, "wood"))
		segments.append(_segment(Vector2(a.x + CONNECTOR_HALF_WIDTH, min_y), Vector2(a.x + CONNECTOR_HALF_WIDTH, max_y), Vector2.LEFT, "wood"))
		if add_gate:
			var gate_y := lerpf(min_y, max_y, 0.68)
			segments.append(_segment(Vector2(a.x - CONNECTOR_HALF_WIDTH + 6.0, gate_y), Vector2(a.x + CONNECTOR_HALF_WIDTH - 6.0, gate_y), Vector2.DOWN, "glass"))

func _decorate_zone(theme: String, node: Dictionary, depth: int, is_progression: bool, rng: RandomNumberGenerator) -> Dictionary:
	var rect: Rect2 = node.get("rect", Rect2())
	var patches: Array = []
	var segments: Array = []
	var prism_stations: Array = []
	var tree_trunks: Array = []
	var dead_alive_cells: Array = []
	var label_prefix := ("Exit " if is_progression else "") + theme.capitalize()
	match theme:
		"mirror":
			patches.append(LightWorldBuilder._normalized_patch(rect.grow(14.0), "mirror", "%s gallery" % label_prefix))
			var x_left := rect.position.x + 28.0
			var x_right := rect.end.x - 28.0
			var mid_y := rect.get_center().y
			segments.append(_segment(Vector2(x_left, mid_y - 18.0), Vector2(x_right, mid_y - 18.0), Vector2.DOWN, "mirror"))
			segments.append(_segment(Vector2(x_left + 20.0, mid_y + 30.0), Vector2(x_right - 34.0, mid_y + 30.0), Vector2.UP, "mirror"))
			segments.append(_segment(Vector2(rect.end.x - 44.0, rect.position.y + 30.0), Vector2(rect.end.x - 44.0, rect.end.y - 30.0), Vector2.LEFT, "mirror"))
			prism_stations.append({
				"pos": Vector2(rect.position.x + rect.size.x * 0.34, rect.position.y + rect.size.y * 0.38),
				"radius": 22.0,
				"label": "%s redirect prism" % label_prefix
			})
			dead_alive_cells.append(_zone_energy(rect.grow(-12.0), 0.64 + minf(float(depth) * 0.03, 0.16), "mirror", "mirror_core"))
		"glass":
			patches.append(LightWorldBuilder._normalized_patch(rect.grow(16.0), "glass", "%s conservatory" % label_prefix))
			patches.append(LightWorldBuilder._normalized_patch(Rect2(rect.position + Vector2(14.0, 16.0), Vector2(rect.size.x - 28.0, rect.size.y * 0.28)), "wet", "%s dew strip" % label_prefix))
			var lane_x := rect.get_center().x
			segments.append(_segment(Vector2(lane_x, rect.position.y + 20.0), Vector2(lane_x, rect.end.y - 20.0), Vector2.LEFT, "glass"))
			segments.append(_segment(Vector2(rect.position.x + 26.0, rect.get_center().y + 18.0), Vector2(rect.end.x - 42.0, rect.get_center().y + 18.0), Vector2.UP, "glass"))
			segments.append(_segment(Vector2(rect.position.x + 34.0, rect.position.y + 42.0), Vector2(rect.position.x + 34.0, rect.end.y - 42.0), Vector2.RIGHT, "wood"))
			prism_stations.append({
				"pos": Vector2(rect.end.x - 46.0, rect.position.y + rect.size.y * 0.36),
				"radius": 22.0,
				"label": "%s transmission prism" % label_prefix
			})
			dead_alive_cells.append(_zone_energy(rect.grow(-8.0), 0.58 + minf(float(depth) * 0.04, 0.18), "glass", "glass_lane"))
		"wet":
			patches.append(LightWorldBuilder._normalized_patch(rect.grow(14.0), "wet", "%s basin" % label_prefix))
			patches.append(LightWorldBuilder._normalized_patch(Rect2(rect.position + Vector2(18.0, 22.0), Vector2(rect.size.x - 36.0, rect.size.y * 0.36)), "wood", "%s boardwalk" % label_prefix))
			var y1 := rect.position.y + rect.size.y * 0.34
			var y2 := rect.position.y + rect.size.y * 0.67
			segments.append(_segment(Vector2(rect.position.x + 18.0, y1), Vector2(rect.end.x - 18.0, y1), Vector2.DOWN, "wet"))
			segments.append(_segment(Vector2(rect.position.x + 34.0, y2), Vector2(rect.end.x - 34.0, y2), Vector2.UP, "wood"))
			segments.append(_segment(Vector2(rect.position.x + rect.size.x * 0.72, rect.position.y + 24.0), Vector2(rect.position.x + rect.size.x * 0.72, rect.end.y - 24.0), Vector2.LEFT, "mirror" if is_progression else "wet"))
			prism_stations.append({
				"pos": Vector2(rect.position.x + rect.size.x * 0.24, rect.end.y - 42.0),
				"radius": 20.0,
				"label": "%s pool prism" % label_prefix
			})
			if rng.randf() < 0.55:
				tree_trunks.append({
					"pos": Vector2(rect.position.x + rect.size.x * 0.54, rect.position.y + rect.size.y * 0.56),
					"radius": 22.0,
					"label": "%s trunk" % label_prefix
				})
			dead_alive_cells.append(_zone_energy(rect.grow(-10.0), 0.52 + minf(float(depth) * 0.05, 0.22), "wet", "wet_pool"))
		_:
			patches.append(LightWorldBuilder._normalized_patch(rect.grow(12.0), "wood", "%s hall" % label_prefix))
			patches.append(LightWorldBuilder._normalized_patch(Rect2(rect.position + Vector2(12.0, 14.0), Vector2(rect.size.x - 24.0, rect.size.y * 0.24)), "brick", "%s footing" % label_prefix))
			segments.append(_segment(Vector2(rect.position.x + 24.0, rect.get_center().y), Vector2(rect.end.x - 24.0, rect.get_center().y), Vector2.UP, "wood"))
			segments.append(_segment(Vector2(rect.position.x + rect.size.x * 0.36, rect.position.y + 20.0), Vector2(rect.position.x + rect.size.x * 0.36, rect.end.y - 26.0), Vector2.RIGHT, "brick"))
			prism_stations.append({
				"pos": Vector2(rect.end.x - 42.0, rect.end.y - 38.0),
				"radius": 20.0,
				"label": "%s routing prism" % label_prefix
			})
			if rng.randf() < 0.85:
				tree_trunks.append({
					"pos": Vector2(rect.position.x + rect.size.x * 0.68, rect.position.y + rect.size.y * 0.34),
					"radius": 24.0,
					"label": "%s rooted blocker" % label_prefix
				})
			dead_alive_cells.append(_zone_energy(rect.grow(-12.0), 0.46 + minf(float(depth) * 0.05, 0.25), "wood", "wood_hall"))

	if is_progression:
		patches.append(LightWorldBuilder._normalized_patch(Rect2(rect.position + Vector2(rect.size.x * 0.58, 18.0), Vector2(rect.size.x * 0.28, rect.size.y - 36.0)), "glass", "%s gate channel" % label_prefix))
		segments.append(_segment(Vector2(rect.end.x - 26.0, rect.position.y + 20.0), Vector2(rect.end.x - 26.0, rect.end.y - 20.0), Vector2.LEFT, "mirror"))
		segments.append(_segment(Vector2(rect.position.x + 18.0, rect.position.y + 24.0), Vector2(rect.position.x + 18.0, rect.end.y - 24.0), Vector2.RIGHT, "glass"))
		prism_stations.append({
			"pos": rect.get_center() + Vector2(rect.size.x * 0.18, 0.0),
			"radius": 24.0,
			"label": "Exit gate prism"
		})
		dead_alive_cells.append(_zone_energy(Rect2(rect.position + Vector2(18.0, 18.0), rect.size - Vector2(36.0, 36.0)), 0.78, "glass", "exit_gate"))

	return {
		"patches": patches,
		"segments": segments,
		"prism_stations": prism_stations,
		"tree_trunks": tree_trunks,
		"dead_alive_cells": dead_alive_cells,
		"summary": {
			"id": String(node.get("id", "")),
			"kind": String(node.get("kind", "zone")),
			"theme": theme,
			"depth": depth,
			"prism_count": prism_stations.size(),
			"blocker_count": segments.size() + tree_trunks.size(),
			"progression": is_progression
		}
	}

func _build_spawn_soft_cover(spawn_rect: Rect2) -> Array:
	return [
		_segment(
			Vector2(spawn_rect.position.x + 18.0, spawn_rect.position.y + 26.0),
			Vector2(spawn_rect.position.x + 18.0, spawn_rect.end.y - 26.0),
			Vector2.RIGHT,
			"wood"
		),
		_segment(
			Vector2(spawn_rect.position.x + 18.0, spawn_rect.position.y + 26.0),
			Vector2(spawn_rect.end.x - 36.0, spawn_rect.position.y + 26.0),
			Vector2.DOWN,
			"wood"
		)
	]

func _zone_energy(rect: Rect2, value: float, material_id: String, tag: String) -> Dictionary:
	return {
		"rect": rect,
		"value": clampf(value, 0.18, 1.0),
		"material_id": material_id,
		"tag": tag
	}

func _segment(a: Vector2, b: Vector2, normal: Vector2, material_id: String) -> Dictionary:
	return {
		"a": a,
		"b": b,
		"normal": normal,
		"material_id": material_id,
		"blocks_flashlight": material_id != "wet" and material_id != "glass"
	}
