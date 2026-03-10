extends RefCounted
class_name LightLabCollision

static func resolve_circle_motion(position: Vector2, radius: float, motion: Vector2, segments: Array, iterations: int = 4) -> Vector2:
	var new_pos := position
	new_pos += motion
	for _i in range(iterations):
		var pushed := false
		for segment: Dictionary in segments:
			var closest := _closest_point_on_segment(new_pos, Vector2(segment["a"]), Vector2(segment["b"]))
			var delta := new_pos - closest
			var dist := delta.length()
			if dist >= radius or dist <= 0.0001:
				continue
			var push_dir := delta / dist
			new_pos = closest + push_dir * radius
			pushed = true
		if not pushed:
			break
	return new_pos

static func is_circle_blocked(position: Vector2, radius: float, segments: Array) -> bool:
	for segment: Dictionary in segments:
		var closest := _closest_point_on_segment(position, Vector2(segment["a"]), Vector2(segment["b"]))
		if closest.distance_to(position) < radius:
			return true
	return false

static func _closest_point_on_segment(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var t := clampf((point - a).dot(ab) / max(ab.length_squared(), 0.001), 0.0, 1.0)
	return a + ab * t
