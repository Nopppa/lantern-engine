extends RefCounted
class_name LightQuery

static func flashlight_intensity(source_pos: Vector2, source_facing: Vector2, target: Vector2, max_range: float, half_angle_deg: float, base_intensity: float) -> float:
	var to_target := target - source_pos
	var distance := to_target.length()
	if distance <= 0.001 or distance > max_range:
		return 0.0
	var dir := to_target / distance
	var angle_ratio: float = absf(rad_to_deg(source_facing.angle_to(dir))) / max(half_angle_deg, 0.001)
	if angle_ratio > 1.0:
		return 0.0
	var center_weight: float = pow(max(0.0, 1.0 - angle_ratio), 1.65)
	var distance_weight: float = pow(max(0.0, 1.0 - distance / max_range), 1.35)
	return clampf(base_intensity * center_weight * distance_weight, 0.0, 1.0)

static func segment_intensity(a: Vector2, b: Vector2, point: Vector2, radius: float, strength: float) -> float:
	var ab := b - a
	var t := clampf((point - a).dot(ab) / max(ab.length_squared(), 0.001), 0.0, 1.0)
	var closest := a + ab * t
	var distance := closest.distance_to(point)
	if distance > radius:
		return 0.0
	var dist_weight: float = 1.0 - distance / max(radius, 0.001)
	var along_weight: float = 0.78 + 0.22 * (1.0 - absf(t - 0.5) * 2.0)
	return clampf(strength * dist_weight * along_weight, 0.0, 1.0)

static func radial_intensity(origin: Vector2, point: Vector2, radius: float, strength: float) -> float:
	var distance := origin.distance_to(point)
	if distance > radius:
		return 0.0
	return clampf(strength * pow(1.0 - distance / max(radius, 0.001), 1.25), 0.0, 1.0)
