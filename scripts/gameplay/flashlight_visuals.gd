extends RefCounted
class_name FlashlightVisuals

const LightResponseModel = preload("res://scripts/gameplay/light_response_model.gd")
const LightSurfaceResolver = preload("res://scripts/gameplay/light_surface_resolver.gd")

static func build_visual_trace(lab) -> Dictionary:
	if not lab.flashlight_on:
		return {"segments": [], "zones": [], "debug_points": []}
	var segments: Array = []
	var zones: Array = []
	var debug_points: Array = []
	var ray_count: int = 17
	var max_bounces: int = 2
	var base_angle: float = lab.facing.angle()
	var cone_angle: float = deg_to_rad(lab.flashlight_half_angle)
	for i in range(ray_count):
		var t: float = 0.0 if ray_count <= 1 else float(i) / float(ray_count - 1)
		var angle: float = lerpf(base_angle - cone_angle, base_angle + cone_angle, t)
		var edge_ratio: float = absf(t * 2.0 - 1.0)
		var origin: Vector2 = lab.player_pos
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var intensity: float = lerpf(0.34, 0.92, pow(1.0 - edge_ratio, 1.45))
		var remaining: float = lab.flashlight_range
		var bounce_index: int = 0
		while remaining > 12.0 and intensity > 0.045 and bounce_index <= max_bounces:
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
				if _crosses_material_patch(lab, origin, end_point, "wood"):
					var wood_mid: Vector2 = origin.lerp(end_point, 0.52)
					zones.append({
						"pos": wood_mid,
						"radius": 28.0 + 24.0 * intensity,
						"strength": 0.10 + intensity * 0.12,
						"material_id": "wood",
						"kind": "wood_floor_glow"
					})
				break
			var hit_point: Vector2 = hit["point"]
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
					"radius": 18.0 + 14.0 * intensity,
					"strength": 0.05 + intensity * 0.08,
					"material_id": material_id,
					"kind": "block"
				})
				break
			var response: Dictionary = LightResponseModel.response(material_id, "flashlight", intensity, direction, Vector2(hit["normal"]))
			if float(response["diffusion"]) * intensity > 0.035:
				zones.append({
					"pos": hit_point,
					"radius": float(response["diffuse_radius"]),
					"strength": float(response["diffusion"]) * intensity,
					"material_id": material_id,
					"kind": "diffuse"
				})
			if material_id == "wood":
				var scatter_dir: Vector2 = Vector2(response["reflect_dir"]).lerp(direction, 0.55).normalized()
				segments.append({
					"a": hit_point,
					"b": hit_point + scatter_dir.rotated(0.13) * remaining * 0.22,
					"intensity": intensity * 0.18,
					"kind": "scatter",
					"material_id": material_id,
					"bounce_index": bounce_index + 1,
					"sample": t
				})
				segments.append({
					"a": hit_point,
					"b": hit_point + scatter_dir.rotated(-0.16) * remaining * 0.18,
					"intensity": intensity * 0.14,
					"kind": "scatter",
					"material_id": material_id,
					"bounce_index": bounce_index + 1,
					"sample": t
				})
			if material_id == "wet":
				segments.append({
					"a": hit_point,
					"b": hit_point + Vector2(response["reflect_dir"]).rotated(0.08 if int(i) % 2 == 0 else -0.08) * remaining * 0.24,
					"intensity": intensity * 0.16,
					"kind": "disturb",
					"material_id": material_id,
					"bounce_index": bounce_index + 1,
					"sample": t
				})
			var continued: bool = false
			if float(response["transmission"]) * intensity > float(response["branch_min"]):
				segments.append({
					"a": hit_point,
					"b": hit_point + Vector2(response["transmit_dir"]) * remaining * float(response["branch_range_scale"]),
					"intensity": intensity * float(response["transmission"]),
					"kind": "transmit",
					"material_id": material_id,
					"bounce_index": bounce_index,
					"sample": t
				})
				direction = Vector2(response["transmit_dir"]).normalized()
				origin = hit_point + direction * lab.BEAM_OFFSET
				intensity *= float(response["transmission"])
				remaining *= float(response["branch_range_scale"])
				continued = true
			if not continued and float(response["reflectivity"]) * intensity > float(response["branch_min"]):
				segments.append({
					"a": hit_point,
					"b": hit_point + Vector2(response["reflect_dir"]) * remaining * float(response["branch_range_scale"]),
					"intensity": intensity * float(response["reflectivity"]),
					"kind": "reflect",
					"material_id": material_id,
					"bounce_index": bounce_index + 1,
					"sample": t
				})
				direction = Vector2(response["reflect_dir"]).normalized()
				origin = hit_point + direction * lab.BEAM_OFFSET
				intensity *= float(response["reflectivity"])
				remaining *= float(response["branch_range_scale"])
				bounce_index += 1
				continued = true
			if not continued:
				break
	return {"segments": segments, "zones": zones, "debug_points": debug_points}

static func _crosses_material_patch(lab, a: Vector2, b: Vector2, material_id: String) -> bool:
	for patch: Dictionary in lab.surface_patches:
		if String(patch.get("material_id", "")) != material_id:
			continue
		var rect: Rect2 = patch["rect"]
		for step in range(8):
			var t := float(step) / 7.0
			if rect.has_point(a.lerp(b, t)):
				return true
	return false
