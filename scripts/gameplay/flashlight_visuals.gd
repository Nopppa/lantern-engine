extends RefCounted
class_name FlashlightVisuals

const LightApproximation = preload("res://scripts/gameplay/light_approximation.gd")
const LightResponseModel = preload("res://scripts/gameplay/light_response_model.gd")
const LightSurfaceResolver = preload("res://scripts/gameplay/light_surface_resolver.gd")
const LightStability = preload("res://scripts/gameplay/light_stability.gd")

static func build_visual_trace(lab) -> Dictionary:
	if not lab.flashlight_on:
		return {"segments": [], "zones": [], "debug_points": [], "fills": [], "perf": {}}
	var config := LightApproximation.config_for_source("flashlight")
	var ray_count: int = int(config.get("guide_rays", 9))
	var previous_frontier: Dictionary = lab.approx_flashlight_frontier
	var max_bounces: int = 1
	var segments: Array = []
	var zones: Array = []
	var fills: Array = []
	var debug_points: Array = []
	var primary_frontier: Array = []
	var trace_count := 0
	var base_angle: float = lab.facing.angle()
	var cone_angle: float = deg_to_rad(lab.flashlight_half_angle)
	for i in range(ray_count):
		var t: float = 0.0 if ray_count <= 1 else float(i) / float(ray_count - 1)
		var angle: float = lerpf(base_angle - cone_angle, base_angle + cone_angle, t)
		var edge_ratio: float = absf(t * 2.0 - 1.0)
		var origin: Vector2 = lab.player_pos
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var intensity: float = lerpf(0.42, 0.96, pow(1.0 - edge_ratio, 1.18))
		var remaining: float = lab.flashlight_range
		var bounce_index: int = 0
		var frontier_point: Vector2 = origin + direction * min(remaining, 48.0)
		while remaining > 14.0 and intensity > 0.055 and bounce_index <= max_bounces:
			trace_count += 1
			var hit := LightSurfaceResolver._closest_hit(lab, origin, direction, remaining)
			if hit.is_empty():
				var end_point: Vector2 = origin + direction * remaining
				segments.append({
					"a": origin,
					"b": end_point,
					"intensity": intensity,
					"kind": "primary",
					"material_id": "open",
					"bounce_index": bounce_index,
					"sample": t
				})
				frontier_point = end_point
				if _crosses_material_patch(lab, origin, end_point, "wood"):
					var wood_mid: Vector2 = origin.lerp(end_point, 0.52)
					zones.append({
						"pos": wood_mid,
						"radius": 34.0 + 28.0 * intensity,
						"strength": 0.08 + intensity * 0.10,
						"material_id": "wood",
						"kind": "wood_floor_glow"
					})
				break
			var hit_point: Vector2 = hit["point"]
			frontier_point = hit_point
			var travel: float = origin.distance_to(hit_point)
			segments.append({
				"a": origin,
				"b": hit_point,
				"intensity": intensity,
				"kind": "primary",
				"material_id": String(hit.get("material_id", "brick")),
				"bounce_index": bounce_index,
				"sample": t
			})
			debug_points.append({
				"point": hit_point,
				"material_id": String(hit.get("material_id", "brick")),
				"intensity": intensity,
				"bounce_index": bounce_index
			})
			remaining -= travel
			if remaining <= 10.0:
				break
			var material_id: String = String(hit.get("material_id", "brick"))
			if material_id == "tree" or material_id == "brick":
				zones.append({
					"pos": hit_point,
					"radius": 18.0 + 16.0 * intensity,
					"strength": 0.04 + intensity * 0.07,
					"material_id": material_id,
					"kind": "block"
				})
				break
			var response: Dictionary = LightResponseModel.response(material_id, "flashlight", intensity, direction, Vector2(hit["normal"]))
			if float(response["diffusion"]) * intensity > 0.03:
				zones.append({
					"pos": hit_point,
					"radius": float(response["diffuse_radius"]),
					"strength": float(response["diffusion"]) * intensity,
					"material_id": material_id,
					"kind": "diffuse"
				})
			if material_id == "wood":
				var scatter_dir: Vector2 = Vector2(response["reflect_dir"]).lerp(direction, 0.68).normalized()
				var scatter_segment := LightSurfaceResolver._clip_secondary_branch(lab, hit_point, scatter_dir, remaining * 0.18, material_id, false)
				if not scatter_segment.is_empty():
					segments.append({
						"a": scatter_segment["a"],
						"b": scatter_segment["b"],
						"intensity": intensity * 0.12,
						"kind": "scatter",
						"material_id": material_id,
						"bounce_index": bounce_index + 1,
						"sample": t
					})
			elif material_id == "wet":
				var wet_segment := LightSurfaceResolver._clip_secondary_branch(lab, hit_point, Vector2(response["reflect_dir"]), remaining * 0.20, material_id, false)
				if not wet_segment.is_empty():
					segments.append({
						"a": wet_segment["a"],
						"b": wet_segment["b"],
						"intensity": intensity * 0.11,
						"kind": "disturb",
						"material_id": material_id,
						"bounce_index": bounce_index + 1,
						"sample": t
					})
			elif material_id == "mirror":
				var mirror_segment := LightSurfaceResolver._clip_secondary_branch(lab, hit_point, Vector2(response["reflect_dir"]), remaining * 0.26, material_id, false)
				if not mirror_segment.is_empty():
					segments.append({
						"a": mirror_segment["a"],
						"b": mirror_segment["b"],
						"intensity": intensity * 0.18,
						"kind": "reflect",
						"material_id": material_id,
						"bounce_index": bounce_index + 1,
						"sample": t
					})
			var continued: bool = false
			if float(response["transmission"]) * intensity > float(response["branch_min"]):
				var transmit_segment := LightSurfaceResolver._clip_secondary_branch(lab, hit_point, Vector2(response["transmit_dir"]), remaining * float(response["branch_range_scale"]), material_id, true)
				if not transmit_segment.is_empty():
					segments.append({
						"a": transmit_segment["a"],
						"b": transmit_segment["b"],
						"intensity": intensity * float(response["transmission"]),
						"kind": "transmit",
						"material_id": material_id,
						"bounce_index": bounce_index,
						"sample": t,
						"blocked": transmit_segment.get("blocked", false)
					})
				direction = Vector2(response["transmit_dir"]).normalized()
				origin = hit_point + direction * lab.BEAM_OFFSET
				intensity *= float(response["transmission"])
				remaining *= float(response["branch_range_scale"])
				continued = true
			if not continued and float(response["reflectivity"]) * intensity > float(response["branch_min"]):
				direction = Vector2(response["reflect_dir"]).normalized()
				origin = hit_point + direction * lab.BEAM_OFFSET
				intensity *= float(response["reflectivity"])
				remaining *= float(response["branch_range_scale"])
				bounce_index += 1
				continued = true
			if not continued:
				break
		primary_frontier.append(frontier_point)
	primary_frontier = LightStability.smooth_frontier(lab.player_pos, primary_frontier, previous_frontier, float(config.get("envelope_smoothing", 0.35)))
	fills = _build_beam_fills(lab.player_pos, primary_frontier, config)
	var new_frontier: Dictionary = {}
	for i in range(primary_frontier.size()):
		new_frontier[LightStability.stable_frontier_key(Vector2(primary_frontier[i]), i)] = primary_frontier[i]
	return {
		"segments": segments,
		"zones": zones,
		"debug_points": debug_points,
		"fills": fills,
		"perf": {
			"guide_rays": ray_count,
			"traces": trace_count,
			"fills": fills.size()
		},
		"frontier": new_frontier
	}

static func _build_beam_fills(origin: Vector2, frontier: Array, config: Dictionary) -> Array:
	if frontier.size() < 2:
		return []
	var smoothing := float(config.get("envelope_smoothing", 0.35))
	var points: PackedVector2Array = []
	points.append(origin)
	for i in range(frontier.size()):
		var p: Vector2 = frontier[i]
		if i > 0 and i < frontier.size() - 1 and smoothing > 0.0:
			var prev: Vector2 = frontier[i - 1]
			var nxt: Vector2 = frontier[i + 1]
			p = p.lerp((prev + p + nxt) / 3.0, smoothing)
		points.append(p)
	var fills: Array = []
	for i in range(1, points.size() - 1):
		fills.append({
			"points": PackedVector2Array([points[0], points[i], points[i + 1]]),
			"strength": 1.0 - (float(i - 1) / max(1.0, float(points.size() - 3))) * 0.22
		})
	return fills

static func _crosses_material_patch(lab, a: Vector2, b: Vector2, material_id: String) -> bool:
	for patch: Dictionary in lab.surface_patches:
		if String(patch.get("material_id", "")) != material_id:
			continue
		var rect: Rect2 = patch["rect"]
		for step in range(6):
			var t := float(step) / 5.0
			if rect.has_point(a.lerp(b, t)):
				return true
	return false
