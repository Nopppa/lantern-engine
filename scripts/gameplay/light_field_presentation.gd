extends Node2D
class_name LightFieldPresentation

const FLASHLIGHT_COLOR := Color(1.0, 0.95, 0.72, 1.0)
const PRISM_COLOR := Color(0.54, 0.93, 1.0, 1.0)

var flashlight_polygon: Polygon2D
var flashlight_feather: Polygon2D
var prism_polygon: Polygon2D
var prism_feather: Polygon2D
var prism_light: PointLight2D

func _ready() -> void:
	flashlight_polygon = _make_polygon()
	flashlight_feather = _make_polygon()
	prism_polygon = _make_polygon()
	prism_feather = _make_polygon()
	add_child(flashlight_feather)
	add_child(flashlight_polygon)
	add_child(prism_feather)
	add_child(prism_polygon)
	prism_light = PointLight2D.new()
	prism_light.texture = _build_radial_texture(256, Color(0.58, 0.96, 1.0, 1.0), 0.42)
	prism_light.color = Color(0.58, 0.96, 1.0, 1.0)
	prism_light.energy = 0.65
	prism_light.texture_scale = 0.95
	prism_light.blend_mode = Light2D.BLEND_MODE_ADD
	prism_light.enabled = false
	add_child(prism_light)
	clear_flashlight()
	clear_prism()

func _make_polygon() -> Polygon2D:
	var poly := Polygon2D.new()
	poly.antialiased = true
	poly.visible = false
	return poly

func clear_flashlight() -> void:
	flashlight_polygon.visible = false
	flashlight_polygon.polygon = PackedVector2Array()
	flashlight_polygon.vertex_colors = PackedColorArray()
	flashlight_feather.visible = false
	flashlight_feather.polygon = PackedVector2Array()
	flashlight_feather.vertex_colors = PackedColorArray()

func clear_prism() -> void:
	prism_polygon.visible = false
	prism_polygon.polygon = PackedVector2Array()
	prism_polygon.vertex_colors = PackedColorArray()
	prism_feather.visible = false
	prism_feather.polygon = PackedVector2Array()
	prism_feather.vertex_colors = PackedColorArray()
	if prism_light:
		prism_light.enabled = false


func _frontier_array_from_packet(packet: Dictionary) -> Array:
	var frontier_points: Array = packet.get("frontier_points", [])
	if not frontier_points.is_empty():
		return frontier_points
	var legacy_frontier = packet.get("frontier", [])
	if legacy_frontier is Array:
		return legacy_frontier
	if legacy_frontier is Dictionary:
		return Dictionary(legacy_frontier).values()
	return []

func update_flashlight_packet(packet: Dictionary) -> void:
	update_flashlight(
		Vector2(packet.get("source", {}).get("origin", Vector2.ZERO)),
		_frontier_array_from_packet(packet),
		float(packet.get("source", {}).get("range", 0.0)),
		Vector2(packet.get("source", {}).get("direction", Vector2.RIGHT)),
		float(packet.get("source", {}).get("half_angle_deg", 0.0))
	)

func update_prism_packet(packet: Dictionary) -> void:
	update_prism(
		Vector2(packet.get("source", {}).get("origin", Vector2.ZERO)),
		_frontier_array_from_packet(packet),
		float(packet.get("source", {}).get("range", 0.0))
	)

func update_flashlight(origin: Vector2, frontier: Array, max_range: float, facing: Vector2, half_angle_deg: float) -> void:
	if frontier.size() < 2:
		clear_flashlight()
		return
	var base_points := PackedVector2Array()
	base_points.append(origin)
	for point in frontier:
		base_points.append(Vector2(point))
	var base_colors := PackedColorArray()
	base_colors.append(Color(FLASHLIGHT_COLOR.r, FLASHLIGHT_COLOR.g, FLASHLIGHT_COLOR.b, 0.26))
	for i in range(frontier.size()):
		var dist_ratio := clampf(origin.distance_to(Vector2(frontier[i])) / max(max_range, 1.0), 0.0, 1.0)
		var edge_ratio := 0.0 if frontier.size() <= 1 else absf((float(i) / float(frontier.size() - 1)) * 2.0 - 1.0)
		var alpha: float = lerpf(0.07, 0.15, pow(1.0 - dist_ratio, 1.15)) * lerpf(0.72, 1.0, pow(1.0 - edge_ratio, 1.35))
		base_colors.append(Color(FLASHLIGHT_COLOR.r, FLASHLIGHT_COLOR.g, FLASHLIGHT_COLOR.b, alpha))
	flashlight_polygon.polygon = base_points
	flashlight_polygon.vertex_colors = base_colors
	flashlight_polygon.visible = true
	flashlight_feather.visible = true
	var feather_distance: float = max(36.0, max_range * 0.16)
	var feather: Dictionary = _build_feather_polygon(origin, frontier, feather_distance, false)
	flashlight_feather.polygon = feather["points"]
	flashlight_feather.vertex_colors = feather["colors"]

func update_prism(origin: Vector2, frontier: Array, radius_hint: float) -> void:
	if frontier.size() < 3:
		clear_prism()
		return
	var base_points := PackedVector2Array()
	base_points.append(origin)
	for point in frontier:
		base_points.append(Vector2(point))
	var base_colors := PackedColorArray()
	base_colors.append(Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.22))
	for point in frontier:
		var dist_ratio := clampf(origin.distance_to(Vector2(point)) / max(radius_hint, 1.0), 0.0, 1.5)
		var alpha: float = lerpf(0.05, 0.14, pow(1.0 - min(dist_ratio, 1.0), 0.75))
		base_colors.append(Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, alpha))
	prism_polygon.polygon = base_points
	prism_polygon.vertex_colors = base_colors
	prism_polygon.visible = true
	prism_feather.visible = true
	var feather: Dictionary = _build_feather_polygon(origin, frontier, max(28.0, radius_hint * 0.22), true)
	prism_feather.polygon = feather["points"]
	prism_feather.vertex_colors = feather["colors"]
	prism_light.enabled = true
	prism_light.position = origin
	prism_light.texture_scale = max(0.65, radius_hint / 128.0)
	prism_light.energy = 0.52

func _build_feather_polygon(origin: Vector2, frontier: Array, feather_distance: float, wrap: bool) -> Dictionary:
	var points: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	var count: int = frontier.size()
	if count < (3 if wrap else 2):
		return {"points": points, "colors": colors}
	for i in range(count):
		var current: Vector2 = Vector2(frontier[i])
		var next_index: int = (i + 1) % count if wrap else min(i + 1, count - 1)
		if not wrap and i >= count - 1:
			break
		var next: Vector2 = Vector2(frontier[next_index])
		var outer_a: Vector2 = current + (current - origin).normalized() * feather_distance
		var outer_b: Vector2 = next + (next - origin).normalized() * feather_distance
		points.append(current)
		points.append(next)
		points.append(outer_b)
		points.append(current)
		points.append(outer_b)
		points.append(outer_a)
		var inner_color: Color = Color(FLASHLIGHT_COLOR.r, FLASHLIGHT_COLOR.g, FLASHLIGHT_COLOR.b, 0.05)
		var outer_color: Color = Color(FLASHLIGHT_COLOR.r, FLASHLIGHT_COLOR.g, FLASHLIGHT_COLOR.b, 0.0)
		if wrap:
			inner_color = Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.055)
			outer_color = Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.0)
		colors.append_array(PackedColorArray([inner_color, inner_color, outer_color, inner_color, outer_color, outer_color]))
	return {"points": points, "colors": colors}

func _build_radial_texture(size: int, color: Color, alpha_scale: float) -> Texture2D:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size, size) * 0.5
	var max_radius: float = size * 0.5
	for y in range(size):
		for x in range(size):
			var dist: float = center.distance_to(Vector2(x, y)) / max_radius
			var falloff: float = clampf(1.0 - dist, 0.0, 1.0)
			var alpha: float = pow(falloff, 1.9) * alpha_scale
			image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	return ImageTexture.create_from_image(image)
