extends RefCounted
class_name LightSurfaceResolver

const BeamResolver = preload("res://scripts/gameplay/beam_resolver.gd")
const LightMaterials = preload("res://scripts/data/light_materials.gd")

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
		"special": false
	}]
	var processed: int = 0
	while not queue.is_empty() and processed < 12:
		processed += 1
		var ray: Dictionary = queue.pop_front()
		_trace_ray(lab, ray, queue)
	if lab.beam_segments.is_empty():
		lab.last_event = "Beam fizzled"

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
		var end: Vector2 = origin + direction * remaining
		_append_segment(lab, origin, end, intensity, "open", false)
		return
	var hit_point: Vector2 = best["point"]
	var travel: float = origin.distance_to(hit_point)
	_append_segment(lab, origin, hit_point, intensity, String(best.get("material_id", "open")), bool(best.get("special", false)))
	var material_id := String(best.get("material_id", "brick"))
	var material: Dictionary = LightMaterials.get_definition(material_id)
	lab.beam_debug_hits.append({
		"point": hit_point,
		"material_id": material_id,
		"label": material.get("label", material_id),
		"intensity": intensity
	})
	if bool(best.get("special", false)):
		var redirected: Vector2 = direction.rotated(deg_to_rad(60.0 if direction.y >= 0.0 else -60.0)).normalized()
		queue.append({"origin": hit_point + redirected * lab.BEAM_OFFSET, "direction": redirected, "intensity": intensity * 0.95, "remaining": remaining - travel, "bounces": bounces + 1, "special": true})
		lab.last_event = "Beam redirected through prism station"
		return
	var normal: Vector2 = best["normal"]
	var remaining_after: float = remaining - travel
	var reflectivity: float = float(material.get("reflectivity", 0.0))
	var transmission: float = float(material.get("transmission", 0.0))
	var diffusion: float = float(material.get("diffusion", 0.0))
	if diffusion > 0.0:
		lab.diffuse_zones.append({"pos": hit_point, "radius": 44.0 + diffusion * 46.0, "strength": intensity * diffusion, "material_id": material_id})
	if material_id == "mirror" or material_id == "wet":
		var reflected: Vector2 = direction.bounce(normal).normalized()
		if material_id == "wet":
			reflected = reflected.rotated(deg_to_rad(8.0 * signf(sin(hit_point.x + hit_point.y))))
		if remaining_after > 8.0 and reflectivity * intensity > 0.08:
			queue.append({"origin": hit_point + reflected * lab.BEAM_OFFSET, "direction": reflected, "intensity": intensity * reflectivity, "remaining": remaining_after, "bounces": bounces + 1, "special": false})
		lab.last_event = "%s reflected the beam" % material.get("label", material_id)
		return
	if material_id == "glass":
		if remaining_after > 8.0 and transmission * intensity > 0.08:
			queue.append({"origin": hit_point + direction * lab.BEAM_OFFSET, "direction": direction, "intensity": intensity * transmission, "remaining": remaining_after, "bounces": bounces, "special": false})
		if remaining_after > 8.0 and reflectivity * intensity > 0.08:
			var glass_reflect: Vector2 = direction.bounce(normal).normalized()
			queue.append({"origin": hit_point + glass_reflect * lab.BEAM_OFFSET, "direction": glass_reflect, "intensity": intensity * reflectivity, "remaining": remaining_after * 0.7, "bounces": bounces + 1, "special": false})
		lab.last_event = "Glass transmitted the beam"
		return
	if material_id == "wood":
		lab.last_event = "Wood softly diffused the beam"
	else:
		lab.last_event = "%s absorbed most of the beam" % material.get("label", material_id)

static func _append_segment(lab, a: Vector2, b: Vector2, intensity: float, material_id: String, special: bool) -> void:
	lab.beam_segments.append({
		"a": a,
		"b": b,
		"intensity": intensity,
		"material_id": material_id,
		"special": special
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
		best = {
			"point": hit["point"],
			"normal": surface["normal"],
			"material_id": surface["material_id"],
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
		best = {"point": point, "normal": Vector2.UP, "material_id": "prism", "special": true}
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
