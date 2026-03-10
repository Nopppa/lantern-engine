extends RefCounted
class_name LightSurfaceResolver

const BeamResolver = preload("res://scripts/gameplay/beam_resolver.gd")
const LightResponseModel = preload("res://scripts/gameplay/light_response_model.gd")

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
		"special": false
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
	for source in _environment_sources(lab):
		for sample in _surface_samples_for_source(lab, source):
			var response := LightResponseModel.response(String(sample["material_id"]), String(source["source_type"]), float(sample["intensity"]), Vector2(source["direction"]), Vector2(sample["normal"]))
			var hit_point: Vector2 = sample["point"]
			var material_id := String(sample["material_id"])
			if float(response["diffusion"]) * float(source["intensity"]) > float(response["branch_min"]):
				secondary_zones.append({
					"pos": hit_point,
					"radius": float(response["diffuse_radius"]),
					"strength": float(source["intensity"]) * float(response["diffusion"]),
					"material_id": material_id,
					"source_type": source["source_type"]
				})
			if float(response["reflectivity"]) * float(source["intensity"]) > float(response["branch_min"]):
				var reflect_dir: Vector2 = Vector2(response["reflect_dir"])
				var reflect_len := float(source["range"]) * float(response["branch_range_scale"]) * (0.75 + float(response["reflectivity"]) * 0.35)
				secondary_segments.append({
					"a": hit_point,
					"b": hit_point + reflect_dir * reflect_len,
					"intensity": float(source["intensity"]) * float(response["reflectivity"]),
					"material_id": material_id,
					"source_type": source["source_type"],
					"kind": "reflect"
				})
			if float(response["transmission"]) * float(source["intensity"]) > float(response["branch_min"]):
				var transmit_dir: Vector2 = Vector2(response["transmit_dir"])
				var transmit_len := float(source["range"]) * float(response["branch_range_scale"])
				secondary_segments.append({
					"a": hit_point,
					"b": hit_point + transmit_dir * transmit_len,
					"intensity": float(source["intensity"]) * float(response["transmission"]),
					"material_id": material_id,
					"source_type": source["source_type"],
					"kind": "transmit"
				})
			debug_points.append({
				"point": hit_point,
				"material_id": material_id,
				"source_type": source["source_type"],
				"intensity": sample["intensity"],
				"response": response
			})
	return {
		"segments": secondary_segments,
		"zones": secondary_zones,
		"debug_points": debug_points
	}

static func _environment_sources(lab) -> Array:
	var sources: Array = []
	if lab.flashlight_on:
		sources.append({
			"source_type": "flashlight",
			"origin": lab.player_pos,
			"direction": lab.facing,
			"range": lab.flashlight_range * 0.52,
			"half_angle": lab.flashlight_half_angle,
			"intensity": 0.72
		})
	for prism_station: Dictionary in lab.prism_stations:
		sources.append({
			"source_type": "prism",
			"origin": prism_station["pos"],
			"direction": Vector2.LEFT,
			"range": 82.0,
			"half_angle": 180.0,
			"intensity": 0.46
		})
	if lab.prism_node:
		sources.append({
			"source_type": "prism",
			"origin": lab.prism_node.position,
			"direction": lab.facing,
			"range": 96.0,
			"half_angle": 180.0,
			"intensity": 0.58
		})
	return sources

static func _surface_samples_for_source(lab, source: Dictionary) -> Array:
	var hits: Array = []
	for surface: Dictionary in lab.surface_segments:
		var sample := _sample_segment_from_source(lab, source, surface)
		if not sample.is_empty():
			hits.append(sample)
	for patch: Dictionary in lab.surface_patches:
		var patch_sample := _sample_patch_from_source(lab, source, patch)
		if not patch_sample.is_empty():
			hits.append(patch_sample)
	return hits

static func _sample_segment_from_source(lab, source: Dictionary, surface: Dictionary) -> Dictionary:
	var a: Vector2 = surface["a"]
	var b: Vector2 = surface["b"]
	var closest := BeamResolver.segment_circle_hit(a, b, Vector2(source["origin"]), float(source["range"]))
	if closest.is_empty():
		return {}
	var point: Vector2 = closest["point"]
	var intensity: float = lab._flashlight_intensity(Vector2(source["origin"]), Vector2(source["direction"]), point, float(source["range"]), float(source["half_angle"]), float(source["intensity"])) if String(source["source_type"]) == "flashlight" else lab._radial_intensity(Vector2(source["origin"]), point, float(source["range"]), float(source["intensity"]))
	if intensity <= 0.05:
		return {}
	return {
		"point": point,
		"normal": Vector2(surface["normal"]),
		"material_id": surface["material_id"],
		"intensity": intensity
	}

static func _sample_patch_from_source(lab, source: Dictionary, patch: Dictionary) -> Dictionary:
	var rect: Rect2 = patch["rect"]
	var point: Vector2 = rect.get_center().clamp(rect.position + Vector2(10, 10), rect.end - Vector2(10, 10))
	var intensity: float = lab._flashlight_intensity(Vector2(source["origin"]), Vector2(source["direction"]), point, float(source["range"]), float(source["half_angle"]), float(source["intensity"])) if String(source["source_type"]) == "flashlight" else lab._radial_intensity(Vector2(source["origin"]), point, float(source["range"]), float(source["intensity"]))
	if intensity <= 0.05:
		return {}
	var normal := (point - Vector2(source["origin"])).normalized()
	if normal == Vector2.ZERO:
		normal = Vector2.UP
	return {
		"point": point,
		"normal": normal,
		"material_id": patch["material_id"],
		"intensity": intensity
	}

static func _trace_ray(lab, ray: Dictionary, queue: Array) -> void:
	var origin: Vector2 = ray["origin"]
	var direction: Vector2 = Vector2(ray["direction"]).normalized()
	var intensity: float = float(ray["intensity"])
	var remaining: float = float(ray["remaining"])
	var bounces: int = int(ray["bounces"])
	if intensity < 0.08 or remaining <= 8.0:
		return
	var best: Dictionary = _closest_hit(lab, origin, direction, remaining)
	if best.is_empty():
		_append_segment(lab, origin, origin + direction * remaining, intensity, "open", false)
		return
	var hit_point: Vector2 = best["point"]
	var travel: float = origin.distance_to(hit_point)
	_append_segment(lab, origin, hit_point, intensity, String(best.get("material_id", "open")), bool(best.get("special", false)))
	var material_id := String(best.get("material_id", "brick"))
	lab.beam_debug_hits.append({
		"point": hit_point,
		"material_id": material_id,
		"label": String(best.get("material_label", material_id)),
		"intensity": intensity,
		"source_type": "laser"
	})
	if bool(best.get("special", false)):
		var redirected: Vector2 = direction.rotated(deg_to_rad(60.0 if direction.y >= 0.0 else -60.0)).normalized()
		queue.append({"origin": hit_point + redirected * lab.BEAM_OFFSET, "direction": redirected, "intensity": intensity * 0.95, "remaining": remaining - travel, "bounces": bounces + 1, "source_type": "laser", "special": true})
		lab.last_event = "Beam redirected through prism station"
		return
	var response := LightResponseModel.response(material_id, "laser", intensity, direction, Vector2(best["normal"]))
	var remaining_after := remaining - travel
	if float(response["diffusion"]) > 0.0:
		lab.diffuse_zones.append({"pos": hit_point, "radius": response["diffuse_radius"], "strength": intensity * float(response["diffusion"]), "material_id": material_id, "source_type": "laser"})
	if remaining_after <= 8.0:
		return
	if float(response["reflectivity"]) * intensity > float(response["branch_min"]):
		queue.append({"origin": hit_point + Vector2(response["reflect_dir"]) * lab.BEAM_OFFSET, "direction": response["reflect_dir"], "intensity": intensity * float(response["reflectivity"]), "remaining": remaining_after, "bounces": bounces + 1, "source_type": "laser", "special": false})
	if float(response["transmission"]) * intensity > float(response["branch_min"]):
		queue.append({"origin": hit_point + direction * lab.BEAM_OFFSET, "direction": direction, "intensity": intensity * float(response["transmission"]), "remaining": remaining_after * 0.9, "bounces": bounces, "source_type": "laser", "special": false})
	var label := String(Dictionary(response["material"]).get("label", material_id))
	if material_id == "glass":
		lab.last_event = "%s split the beam" % label
	elif material_id == "mirror" or material_id == "wet":
		lab.last_event = "%s reflected the beam" % label
	elif material_id == "wood":
		lab.last_event = "%s diffused the beam" % label
	else:
		lab.last_event = "%s absorbed most of the beam" % label

static func _append_segment(lab, a: Vector2, b: Vector2, intensity: float, material_id: String, special: bool) -> void:
	lab.beam_segments.append({
		"a": a,
		"b": b,
		"intensity": intensity,
		"material_id": material_id,
		"special": special,
		"source_type": "laser"
	})
	BeamResolver.damage_enemies_along_segment(lab, a, b, lab.beam_damage * (0.55 + intensity * 0.45))

static func _closest_hit(lab, origin: Vector2, direction: Vector2, max_distance: float) -> Dictionary:
	var best_t: float = max_distance
	var best: Dictionary = {}
	for surface: Dictionary in lab.surface_segments:
		var hit := _ray_segment_intersection(origin, direction, Vector2(surface["a"]), Vector2(surface["b"]))
		if hit.is_empty():
			continue
		var t := float(hit["t"])
		if t < 0.001 or t > best_t:
			continue
		best_t = t
		var mat_resp := LightResponseModel.response(String(surface["material_id"]), "laser", 1.0, direction, Vector2(surface["normal"]))
		best = {
			"point": hit["point"],
			"normal": surface["normal"],
			"material_id": surface["material_id"],
			"material_label": String(Dictionary(mat_resp["material"]).get("label", surface["material_id"])),
			"special": false
		}
	for prism_station: Dictionary in lab.prism_stations:
		var prism_hit := BeamResolver.segment_circle_hit(origin, origin + direction * max_distance, prism_station["pos"], prism_station["radius"])
		if prism_hit.is_empty():
			continue
		var point: Vector2 = prism_hit["point"]
		var t_prism := origin.distance_to(point)
		if t_prism > best_t:
			continue
		best_t = t_prism
		best = {"point": point, "normal": Vector2.UP, "material_id": "prism", "material_label": "Prism", "special": true}
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
