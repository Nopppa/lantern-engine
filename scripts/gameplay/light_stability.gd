extends RefCounted
class_name LightStability

static func stable_surface_key(sample: Dictionary) -> String:
	var point: Vector2 = Vector2(sample.get("point", Vector2.ZERO))
	var normal: Vector2 = Vector2(sample.get("normal", Vector2.ZERO))
	return "%s|%d|%d|%d|%d" % [
		String(sample.get("material_id", "")),
		int(round(point.x * 10.0)),
		int(round(point.y * 10.0)),
		int(round(normal.x * 100.0)),
		int(round(normal.y * 100.0))
	]

static func stable_frontier_key(point: Vector2, index: int) -> String:
	return "%02d|%d|%d" % [index, int(round(point.x * 10.0)), int(round(point.y * 10.0))]

static func sort_samples(candidates: Array, previous_keys := {}) -> void:
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_score := float(a.get("score", 0.0))
		var b_score := float(b.get("score", 0.0))
		var a_key := stable_surface_key(a)
		var b_key := stable_surface_key(b)
		var a_prev := int(previous_keys.get(a_key, 1_000_000))
		var b_prev := int(previous_keys.get(b_key, 1_000_000))
		if absf(a_score - b_score) > 0.0005:
			return a_score > b_score
		if a_prev != b_prev:
			return a_prev < b_prev
		return a_key < b_key
	)

static func smooth_frontier(origin: Vector2, frontier: Array, previous_frontier: Dictionary, smoothing: float) -> Array:
	if frontier.is_empty() or smoothing <= 0.0:
		return frontier.duplicate()
	var result: Array = []
	for i in range(frontier.size()):
		var point: Vector2 = frontier[i]
		var key := stable_frontier_key(point, i)
		var previous: Vector2 = Vector2(previous_frontier.get(key, point))
		var blended := previous.lerp(point, clampf(1.0 - smoothing, 0.15, 1.0))
		if blended.distance_to(origin) < 4.0:
			blended = origin + (point - origin).normalized() * min(origin.distance_to(point), 4.0)
		result.append(blended)
	return result
