extends RefCounted
class_name LightSurfaceResolver

const BeamResolver = preload("res://scripts/gameplay/beam_resolver.gd")
const LightApproximation = preload("res://scripts/gameplay/light_approximation.gd")
const LightResponseModel = preload("res://scripts/gameplay/light_response_model.gd")
const LightQuery = preload("res://scripts/gameplay/light_query.gd")
const LightLabCollision = preload("res://scripts/gameplay/light_lab_collision.gd")

static func cast_beam(lab, target: Vector2) -> void:
	if lab.beam_timer > 0.0:
		lab.last_event = "Beam on cooldown"
		return
	if lab.energy < lab.beam_cost:
		lab.last_event = "Low energy"
		return
	lab.energy -= lab.beam_cost
	lab.beam_timer = lab.beam_cooldown
	lab.beam_flash = 1.0
	lab.beam_pulse_timer = lab.BEAM_PULSE_DURATION
	lab.beam_segments.clear()
	lab.beam_debug_hits.clear()
	lab.hit_flashes.clear()
	var direction: Vector2 = (target - lab.player_pos).normalized()
	if direction == Vector2.ZERO:
		direction = lab.facing
	var queue: Array = [{
		"origin": lab.player_pos,
		"direction": direction,
		"intensity": 1.0,
		"remaining": lab.beam_range,
		"bounces": 0,
		"source_type": "laser",
		"special": false,
		"layer": 0,
		"parent_layer": -1
	}]
	var processed := 0
	while not queue.is_empty() and processed < 16:
		processed += 1
		_trace_ray(lab, queue.pop_front(), queue)
	if lab.beam_segments.is_empty():
		lab.last_event = "Beam fizzled"

static func build_secondary_light(lab) -> Dictionary:
	var secondary_segments: Array = []
	var secondary_zones: Array = []
	var debug_points: Array = []
	var source_index := 0
	var sampled_targets := 0
	for source in _environment_sources(lab):
		for sample in _surface_samples_for_source(lab, source):
			sampled_targets += 1
			var response := LightResponseModel.response(String(sample["material_id"]), String(source["source_type"]), float(sample["intensity"]), Vector2(source["direction"]), Vector2(sample["normal"]))
			var hit_point: Vector2 = sample["point"]
			var material_id := String(sample["material_id"])
			if float(response["diffusion"]) * float(sample["intensity"]) > float(response["branch_min"]):
				secondary_zones.append({
					"pos": hit_point,
					"radius": float(response["diffuse_radius"]),
					"strength": float(sample["intensity"]) * float(response["diffusion"]),
					"material_id": material_id,
					"source_type": source["source_type"],
					"kind": "diffuse",
					"source_index": source_index
				})
			if float(response["reflectivity"]) * float(sample["intensity"]) > float(response["branch_min"]):
				var reflect_dir: Vector2 = Vector2(response["reflect_dir"])
				var reflect_len := float(source["range"]) * float(response["branch_range_scale"]) * (0.62 + float(response["reflectivity"]) * 0.28)
				secondary_segments.append({
					"a": hit_point,
					"b": hit_point + reflect_dir * reflect_len,
					"intensity": float(sample["intensity"]) * float(response["reflectivity"]),
					"material_id": material_id,
					"source_type": source["source_type"],
					"kind": "reflect",
					"layer": 1,
					"source_index": source_index
				})
			if float(response["transmission"]) * float(sample["intensity"]) > float(response["branch_min"]):
				var transmit_dir: Vector2 = Vector2(response["transmit_dir"])
				var transmit_len := float(source["range"]) * float(response["branch_range_scale"])
				secondary_segments.append({
					"a": hit_point,
					"b": hit_point + transmit_dir * transmit_len,
					"intensity": float(sample["intensity"]) * float(response["transmission"]),
					"material_id": material_id,
					"source_type": source["source_type"],
					"kind": "transmit",
					"layer": 2,
					"source_index": source_index
				})
			debug_points.append({
				"point": hit_point,
				"material_id": material_id,
				"source_type": source["source_type"],
				"intensity": sample["intensity"],
				"response": response,
				"source_index": source_index
			})
		source_index += 1
	return {
		"segments": secondary_segments,
		"zones": secondary_zones,
		"debug_points": debug_points,
		"perf": {
			"sources": source_index,
			"samples": sampled_targets,
			"segments": secondary_segments.size(),
			"zones": secondary_zones.size()
		}
	}

static func _environment_sources(lab) -> Array:
	var sources: Array = []
	if lab.flashlight_on:
		sources.append({
			"source_type": "flashlight",
			"origin": lab.player_pos,
			"direction": lab.facing,
			"range": lab.flashlight_range * 0.46,
			"half_angle": lab.flashlight_half_angle,
			"intensity": 0.62
		})
	for prism_station: Dictionary in lab.prism_stations:
		sources.append({
			"source_type": "prism",
			"origin": prism_station["pos"],
			"direction": Vector2.LEFT,
			"range": 74.0,
			"half_angle": 180.0,
			"intensity": 0.40
		})
	if lab.prism_node:
		sources.append({
			"source_type": "prism",
			"origin": lab.prism_node.position,
			"direction": lab.facing,
			"range": 88.0,
			"half_angle": 180.0,
			"intensity": 0.50
		})
	return sources

static func _surface_samples_for_source(lab, source: Dictionary) -> Array:
	var candidates: Array = []
	for surface: Dictionary in lab.surface_segments:
		var sample := _sample_segment_from_source(lab, source, surface)
		if not sample.is_empty():
			candidates.append(sample)
	for patch: Dictionary in lab.surface_patches:
		var patch_sample := _sample_patch_from_source(lab, source, patch)
		if not patch_sample.is_empty():
			candidates.append(patch_sample)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	var budget := int(LightApproximation.config_for_source(String(source.get("source_type", "prism"))).get("sample_budget", 6))
	if budget <= 0 or candidates.size() <= budget:
		return candidates
	return candidates.slice(0, budget)

static func _sample_segment_from_source(lab, source: Dictionary, surface: Dictionary) -> Dictionary:
	var a: Vector2 = surface["a"]
	var b: Vector2 = surface["b"]
	var closest := BeamResolver.segment_circle_hit(a, b, Vector2(source["origin"]), float(source["range"]))
	if closest.is_empty():
		return {}
	var point: Vector2 = closest["point"]
	var visibility: float = lab._visibility_between(Vector2(source["origin"]), point)
	if visibility <= 0.0:
		return {}
	var intensity: float = LightQuery.flashlight_intensity(Vector2(source["origin"]), Vector2(source["direction"]), point, float(source["range"]), float(source["half_angle"]), float(source["intensity"])) if String(source["source_type"]) == "flashlight" else LightQuery.radial_intensity(Vector2(source["origin"]), point, float(source["range"]), float(source["intensity"]))
	intensity *= visibility
	if intensity <= 0.06:
		return {}
	return {
		"point": point,
		"normal": Vector2(surface["normal"]),
		"material_id": surface["material_id"],
		"intensity": intensity,
		"score": intensity / max(8.0, Vector2(source["origin"]).distance_to(point))
	}

static func _sample_patch_from_source(lab, source: Dictionary, patch: Dictionary) -> Dictionary:
	var rect: Rect2 = patch["rect"]
	var point: Vector2 = rect.get_center().clamp(rect.position + Vector2(12, 12), rect.end - Vector2(12, 12))
	var visibility: float = lab._visibility_between(Vector2(source["origin"]), point)
	if visibility <= 0.0:
		return {}
	var intensity: float = LightQuery.flashlight_intensity(Vector2(source["origin"]), Vector2(source["direction"]), point, float(source["range"]), float(source["half_angle"]), float(source["intensity"])) if String(source["source_type"]) == "flashlight" else LightQuery.radial_intensity(Vector2(source["origin"]), point, float(source["range"]), float(source["intensity"]))
	intensity *= visibility
	if intensity <= 0.06:
		return {}
	var normal := (point - Vector2(source["origin"])).normalized()
	if normal == Vector2.ZERO:
		normal = Vector2.UP
	return {
		"point": point,
		"normal": normal,
		"material_id": patch["material_id"],
		"intensity": intensity,
		"score": intensity / max(8.0, Vector2(source["origin"]).distance_to(point))
	}

static func _trace_ray(lab, ray: Dictionary, queue: Array) -> void:
	var origin: Vector2 = ray["origin"]
	var direction: Vector2 = Vector2(ray["direction"]).normalized()
	var intensity: float = float(ray["intensity"])
	var remaining: float = float(ray["remaining"])
	var bounces: int = int(ray["bounces"])
	var layer: int = int(ray.get("layer", 0))
	if intensity < 0.08 or remaining <= 8.0:
		return
	var best: Dictionary = _closest_hit(lab, origin, direction, remaining)
	if best.is_empty():
		_append_segment(lab, origin, origin + direction * remaining, intensity, "open", false, layer, bounces, "primary")
		return
	var hit_point: Vector2 = best["point"]
	var travel: float = origin.distance_to(hit_point)
	_append_segment(lab, origin, hit_point, intensity, String(best.get("material_id", "open")), bool(best.get("special", false)), layer, bounces, String(best.get("hit_kind", "primary")))
	var material_id := String(best.get("material_id", "brick"))
	lab.beam_debug_hits.append({
		"point": hit_point,
		"material_id": material_id,
		"label": String(best.get("material_label", material_id)),
		"intensity": intensity,
		"source_type": "laser",
		"layer": layer,
		"kind": String(best.get("hit_kind", "primary")),
		"bounce_index": bounces
	})
	if bool(best.get("special", false)):
		var redirected: Vector2 = direction.rotated(deg_to_rad(60.0 if direction.y >= 0.0 else -60.0)).normalized()
		queue.append({"origin": hit_point + redirected * lab.BEAM_OFFSET, "direction": redirected, "intensity": intensity * 0.95, "remaining": remaining - travel, "bounces": bounces + 1, "source_type": "laser", "special": true, "layer": layer + 1, "parent_layer": layer})
		lab.last_event = "Beam redirected through prism station"
		return
	var response := LightResponseModel.response(material_id, "laser", intensity, direction, Vector2(best["normal"]))
	var remaining_after := remaining - travel
	if float(response["diffusion"]) > 0.0:
		lab.diffuse_zones.append({"pos": hit_point, "radius": response["diffuse_radius"], "strength": intensity * float(response["diffusion"]), "material_id": material_id, "source_type": "laser", "layer": layer + 1, "kind": "diffuse"})
	if remaining_after <= 8.0:
		return
	if material_id == "tree":
		lab.last_event = "Tree trunk blocked the beam"
		return
	if float(response["reflectivity"]) * intensity > float(response["branch_min"]):
		queue.append({"origin": hit_point + Vector2(response["reflect_dir"]) * lab.BEAM_OFFSET, "direction": response["reflect_dir"], "intensity": intensity * float(response["reflectivity"]), "remaining": remaining_after, "bounces": bounces + 1, "source_type": "laser", "special": false, "layer": layer + 1, "parent_layer": layer})
	if float(response["transmission"]) * intensity > float(response["branch_min"]):
		queue.append({"origin": hit_point + direction * lab.BEAM_OFFSET, "direction": direction, "intensity": intensity * float(response["transmission"]), "remaining": remaining_after * 0.9, "bounces": bounces, "source_type": "laser", "special": false, "layer": layer + 1, "parent_layer": layer})
	var label := String(Dictionary(response["material"]).get("label", material_id))
	if material_id == "glass":
		lab.last_event = "%s split the beam" % label
	elif material_id == "mirror" or material_id == "wet":
		lab.last_event = "%s reflected the beam" % label
	elif material_id == "wood":
		lab.last_event = "%s diffused the beam" % label
	else:
		lab.last_event = "%s absorbed most of the beam" % label

static func _append_segment(lab, a: Vector2, b: Vector2, intensity: float, material_id: String, special: bool, layer: int, bounce_index: int, hit_kind: String) -> void:
	lab.beam_segments.append({
		"a": a,
		"b": b,
		"intensity": intensity,
		"material_id": material_id,
		"special": special,
		"source_type": "laser",
		"layer": layer,
		"bounce_index": bounce_index,
		"kind": hit_kind
	})
	BeamResolver.damage_enemies_along_segment(lab, a, b, lab.beam_damage * (0.55 + intensity * 0.45))

static func _closest_hit(lab, origin: Vector2, direction: Vector2, max_distance: float) -> Dictionary:
	var best_t: float = max_distance
	var best: Dictionary = {}
	for surface: Dictionary in lab.surface_segments:
		var hit := _ray_segment_intersection(origin, direction, Vector2(surface["a"]), Vector2(surface["b"]))
		if hit.is_empty():
			continue
		var t: float = float(hit["t"])
		if t < 0.001 or t > best_t:
			continue
		best_t = t
		var mat_resp := LightResponseModel.response(String(surface["material_id"]), "laser", 1.0, direction, Vector2(surface["normal"]))
		best = {
			"point": hit["point"],
			"normal": surface["normal"],
			"material_id": surface["material_id"],
			"material_label": String(Dictionary(mat_resp["material"]).get("label", surface["material_id"])),
			"special": false,
			"hit_kind": "bounce"
		}
	for trunk: Dictionary in lab.tree_trunks:
		var trunk_hit := LightLabCollision.segment_intersects_circle(origin, origin + direction * max_distance, Vector2(trunk["pos"]), float(trunk["radius"]))
		if trunk_hit.is_empty():
			continue
		var point: Vector2 = trunk_hit["point"]
		var t_tree := origin.distance_to(point)
		if t_tree > best_t:
			continue
		best_t = t_tree
		best = {"point": point, "normal": (point - Vector2(trunk["pos"])).normalized(), "material_id": "tree", "material_label": "Tree Trunk", "special": false, "hit_kind": "block"}
	for prism_station: Dictionary in lab.prism_stations:
		var prism_hit := BeamResolver.segment_circle_hit(origin, origin + direction * max_distance, prism_station["pos"], prism_station["radius"])
		if prism_hit.is_empty():
			continue
		var point2: Vector2 = prism_hit["point"]
		var t_prism := origin.distance_to(point2)
		if t_prism > best_t:
			continue
		best_t = t_prism
		best = {"point": point2, "normal": Vector2.UP, "material_id": "prism", "material_label": "Prism", "special": true, "hit_kind": "redirect"}
	return best

static func _ray_segment_intersection(origin: Vector2, direction: Vector2, a: Vector2, b: Vector2) -> Dictionary:
	var v1: Vector2 = origin - a
	var v2: Vector2 = b - a
	var v3: Vector2 = Vector2(-direction.y, direction.x)
	var dot: float = v2.dot(v3)
	if absf(dot) < 0.00001:
		return {}
	var t1: float = v2.cross(v1) / dot
	var t2: float = v1.dot(v3) / dot
	if t1 >= 0.0 and t2 >= 0.0 and t2 <= 1.0:
		return {"point": origin + direction * t1, "t": t1}
	return {}
