extends RefCounted
class_name DeadAliveGrid

static func build(rect: Rect2, cell_size: float, alive_zones: Array = []) -> Array:
	var cells: Array = []
	var cols := int(floor(rect.size.x / cell_size))
	var rows := int(floor(rect.size.y / cell_size))
	for y in range(rows):
		for x in range(cols):
			var cell_rect := Rect2(rect.position + Vector2(x * cell_size, y * cell_size), Vector2(cell_size, cell_size))
			var center := cell_rect.get_center()
			var base_alive := 0.0
			for zone: Dictionary in alive_zones:
				var zrect: Rect2 = zone.get("rect", Rect2())
				if zrect.has_point(center):
					base_alive = max(base_alive, float(zone.get("value", 1.0)))
			cells.append({
				"rect": cell_rect,
				"center": center,
				"base_alive": base_alive,
				"exposure": 0.0,
				"display": base_alive
			})
	return cells

static func update(cells: Array, delta: float, query: Callable) -> void:
	for cell: Dictionary in cells:
		var light := clampf(float(query.call(cell["center"])), 0.0, 1.0)
		if light > cell["exposure"]:
			cell["exposure"] = lerpf(float(cell["exposure"]), light, min(1.0, delta * 7.0))
		else:
			cell["exposure"] = max(light, float(cell["exposure"]) - delta * 0.32)
		cell["display"] = clampf(max(float(cell["base_alive"]), float(cell["exposure"])), 0.0, 1.0)
