extends RefCounted
class_name FlashlightVisuals

const LightApproximation = preload("res://scripts/gameplay/light_approximation.gd")
const LightResponseModel = preload("res://scripts/gameplay/light_response_model.gd")
const LightSurfaceResolver = preload("res://scripts/gameplay/light_surface_resolver.gd")
const LightStability = preload("res://scripts/gameplay/light_stability.gd")
const LightTypes = preload("res://scripts/gameplay/light_types.gd")

static func build_visual_trace(lab) -> Dictionary:
	if not lab.flashlight_on:
		return {"segments": [], "zones": [], "debug_points": [], "fills": [], "perf": {}}
	return _build_source_trace(lab, flashlight_source_options(lab))

static func flashlight_source_options(lab) -> Dictionary:
	return {
		"source_type": "flashlight",
		"origin": lab.player_pos,
		"direction": lab.facing,
		"range": lab.flashlight_range,
		"half_angle_deg": lab.flashlight_half_angle,
		"guide_rays": int(LightApproximation.config_for_source("flashlight").get("guide_rays", 9)),
		"center_intensity": 0.96,
		"edge_intensity": 0.42,
		"use_frontier_smoothing": true,
		"previous_frontier": lab.approx_flashlight_frontier,
		"source_anchor": lab.player_pos,
		"radial_emission": false
	}

static func build_prism_visual_trace(lab, source_origin: Vector2, source_direction: Vector2, previous_frontier: Dictionary = {}) -> Dictionary:
	return _build_source_trace(lab, prism_source_options(source_origin, source_direction, previous_frontier))

static func prism_source_options(source_origin: Vector2, source_direction: Vector2, previous_frontier: Dictionary = {}, range_override: float = 118.0, intensity_override: float = 0.78, guide_rays_override: int = -1) -> Dictionary:
	return {
		"source_type": "prism",
		"origin": source_origin,
		"direction": source_direction,
		"range": range_override,
		"guide_rays": guide_rays_override if guide_rays_override > 0 else int(LightApproximation.config_for_source("prism").get("guide_rays", 40)),
		"center_intensity": intensity_override,
		"edge_intensity": intensity_override,
		"use_frontier_smoothing": false,
		"previous_frontier": previous_frontier,
		"source_anchor": source_origin,
		"radial_emission": true
	}

static func build_render_packet(lab, options: Dictionary) -> Dictionary:
	var origin := Vector2(options.get("origin", Vector2.ZERO))
	var direction := Vector2(options.get("direction", Vector2.RIGHT))
	var source_type := String(options.get("source_type", "light"))
	if source_type == "flashlight" and not bool(lab.flashlight_on):
		return LightTypes.empty_render_packet("flashlight")
	var trace := _build_source_trace(lab, options)
	var source_spec := LightTypes.light_source_spec(source_type, origin, direction, 1.0, float(options.get("range", 0.0)), {
		"half_angle_deg": float(options.get("half_angle_deg", 0.0)),
		"guide_rays": int(options.get("guide_rays", 0)),
		"radial_emission": bool(options.get("radial_emission", false))
	})
	return LightTypes.light_render_packet(source_type, source_spec, trace.get("segments", []), [], trace.get("fills", []), trace.get("zones", []), {
		"frontier": trace.get("frontier", {}),
		"frontier_points": trace.get("frontier_points", []),
		"debug_points": trace.get("debug_points", []),
		"perf": trace.get("perf", {})
	})

static func _build_source_trace(lab, options: Dictionary) -> Dictionary:
	var source_type := String(options.get("source_type", "flashlight"))
	var config := LightApproximation.config_for_source(source_type)
	var ray_count: int = max(1, int(options.get("guide_rays", int(config.get("guide_rays", 9)))))
	var previous_frontier: Dictionary = options.get("previous_frontier", {})
	var max_bounces: int = 1
	var radial_emission: bool = bool(options.get("radial_emission", false))
	var segments: Array = []
	var zones: Array = []
	var fills: Array = []
	var debug_points: Array = []
	var primary_frontier: Array = []
	var trace_count := 0
	var base_angle: float = Vector2(options.get("direction", Vector2.RIGHT)).angle()
	var cone_angle: float = deg_to_rad(float(options.get("half_angle_deg", 32.0)))
	var trace_origin: Vector2 = Vector2(options.get("origin", lab.player_pos))
	var source_anchor: Vector2 = Vector2(options.get("source_anchor", trace_origin))
	var center_intensity: float = float(options.get("center_intensity", 0.96))
	var edge_intensity: float = float(options.get("edge_intensity", 0.42))
	for i in range(ray_count):
		var t: float = 0.0 if radial_emission and ray_count <= 0 else (0.5 if ray_count <= 1 else float(i) / float(ray_count - 1))
		var angle: float = 0.0
		var edge_ratio: float = 0.0
		if radial_emission:
			angle = base_angle + TAU * float(i) / float(ray_count)
		else:
			angle = lerpf(base_angle - cone_angle, base_angle + cone_angle, t)
			edge_ratio = absf(t * 2.0 - 1.0)
		var origin: Vector2 = trace_origin
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var intensity: float = center_intensity if radial_emission else lerpf(edge_intensity, center_intensity, pow(1.0 - edge_ratio, 1.18))
		var remaining: float = float(options.get("range", lab.flashlight_range))
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
					"sample": t,
					"source_type": source_type,
					"visible": false
				})
				frontier_point = end_point
				if _crosses_material_patch(lab, origin, end_point, "wood"):
					var wood_mid: Vector2 = origin.lerp(end_point, 0.52)
					zones.append({
						"pos": wood_mid,
						"radius": 34.0 + 28.0 * intensity,
						"strength": 0.08 + intensity * 0.10,
						"material_id": "wood",
						"kind": "wood_floor_glow",
						"source_type": source_type
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
				"sample": t,
				"source_type": source_type,
				"visible": false
			})
			debug_points.append({
				"point": hit_point,
				"material_id": String(hit.get("material_id", "brick")),
				"intensity": intensity,
				"bounce_index": bounce_index,
				"source_type": source_type
			})
			remaining -= travel
			if remaining <= 10.0:
				break
			var material_id: String = String(hit.get("material_id", "brick"))
			if material_id == "tree" or material_id == "brick":
				if source_type != "flashlight" and source_type != "prism":
					zones.append({
						"pos": hit_point,
						"radius": 18.0 + 16.0 * intensity,
						"strength": 0.04 + intensity * 0.07,
						"material_id": material_id,
						"kind": "block",
						"source_type": source_type,
						"normal": Vector2(hit["normal"]),
						"incoming_dir": direction
					})
				break
			var response: Dictionary = LightResponseModel.response(material_id, source_type, intensity, direction, Vector2(hit["normal"]))
			if float(response["diffusion"]) * intensity > 0.03:
				zones.append({
					"pos": hit_point,
					"radius": float(response["diffuse_radius"]),
					"strength": float(response["diffusion"]) * intensity,
					"material_id": material_id,
					"kind": "diffuse",
					"source_type": source_type,
					"normal": Vector2(hit["normal"]),
					"incoming_dir": direction
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
						"sample": t,
						"source_type": source_type,
						"visible": true
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
						"sample": t,
						"source_type": source_type,
						"visible": true
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
						"sample": t,
						"source_type": source_type,
						"visible": true
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
						"blocked": transmit_segment.get("blocked", false),
						"source_type": source_type,
						"visible": true
					})
				direction = Vector2(response["transmit_dir"]).normalized()
				origin = hit_point + direction * lab.BEAM_OFFSET
				intensity *= float(response["transmission"])
				remaining *= float(response["branch_range_scale"])
				continued = true
				# Lock the cone-envelope frontier at the material boundary.
				# Post-material light is shown through the transmit segment above.
				# Allowing the frontier to follow the refracted ray scatters it in
				# different directions per ray, causing polygon self-intersection.
				frontier_point = hit_point
				break
			if not continued and float(response["reflectivity"]) * intensity > float(response["branch_min"]):
				direction = Vector2(response["reflect_dir"]).normalized()
				origin = hit_point + direction * lab.BEAM_OFFSET
				intensity *= float(response["reflectivity"])
				remaining *= float(response["branch_range_scale"])
				bounce_index += 1
				continued = true
				# Same: lock envelope frontier at mirror surface to prevent broken polygon.
				frontier_point = hit_point
				break
			if not continued:
				break
		primary_frontier.append(frontier_point)
	if bool(options.get("use_frontier_smoothing", true)) and not radial_emission:
		primary_frontier = LightStability.smooth_frontier(source_anchor, primary_frontier, previous_frontier, float(config.get("envelope_smoothing", 0.35)))
	fills = _build_light_fills(source_anchor, primary_frontier, config, radial_emission)
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
		"frontier": new_frontier,
		"frontier_points": primary_frontier.duplicate()
	}

static func _build_light_fills(origin: Vector2, frontier: Array, config: Dictionary, radial_emission: bool) -> Array:
	if radial_emission:
		return _build_radial_fills(origin, frontier, config)
	return _build_beam_fills(origin, frontier, config)

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

static func _build_radial_fills(origin: Vector2, frontier: Array, config: Dictionary) -> Array:
	if frontier.size() < 3:
		return []
	var fills: Array = []
	for i in range(frontier.size()):
		var a: Vector2 = frontier[i]
		var b: Vector2 = frontier[(i + 1) % frontier.size()]
		var span_strength := clampf(1.0 - absf(a.distance_to(origin) - b.distance_to(origin)) / 120.0, 0.58, 1.0)
		fills.append({
			"points": PackedVector2Array([origin, a, b]),
			"strength": span_strength
		})
	return fills

static func _crosses_material_patch(lab, a: Vector2, b: Vector2, material_id: String) -> bool:
	for patch: Dictionary in LightSurfaceResolver._world_patches(lab):
		if String(patch.get("material_id", "")) != material_id:
			continue
		var rect: Rect2 = patch["rect"]
		for step in range(6):
			var t := float(step) / 5.0
			if rect.has_point(a.lerp(b, t)):
				return true
	return false
