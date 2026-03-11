extends RefCounted
class_name LightLabNavigation

const LightLabCollision = preload("res://scripts/gameplay/light_lab_collision.gd")

static func next_waypoint(run, start: Vector2, goal: Vector2, radius: float) -> Vector2:
	var collision_space: Dictionary = run._collision_space() if run.has_method("_collision_space") else {"segments": run.get("surface_segments") if run.get("surface_segments") != null else [], "circles": run.get("tree_trunks") if run.get("tree_trunks") != null else []}
	if _line_walkable(start, goal, radius, collision_space):
		return goal
	var cell_size := 48.0
	var start_cell := _to_cell(start, run.ARENA_RECT, cell_size)
	var goal_cell := _to_cell(goal, run.ARENA_RECT, cell_size)
	var open: Array = [start_cell]
	var came_from := {}
	var g_score := {}
	var f_score := {}
	g_score[_key(start_cell)] = 0.0
	f_score[_key(start_cell)] = _heuristic(start_cell, goal_cell)
	var best := start_cell
	while not open.is_empty():
		var current_index := 0
		var current = open[0]
		var current_f: float = float(f_score.get(_key(current), 999999.0))
		for i in range(1, open.size()):
			var candidate = open[i]
			var candidate_f: float = float(f_score.get(_key(candidate), 999999.0))
			if candidate_f < current_f:
				current = candidate
				current_f = candidate_f
				current_index = i
		open.remove_at(current_index)
		if _heuristic(current, goal_cell) < _heuristic(best, goal_cell):
			best = current
		if current == goal_cell:
			best = current
			break
		for neighbor in _neighbors(current):
			if not _cell_walkable(run, neighbor, radius, cell_size, collision_space):
				continue
			var tentative_g: float = float(g_score.get(_key(current), 999999.0)) + current.distance_to(neighbor)
			if tentative_g >= float(g_score.get(_key(neighbor), 999999.0)):
				continue
			came_from[_key(neighbor)] = current
			g_score[_key(neighbor)] = tentative_g
			f_score[_key(neighbor)] = tentative_g + _heuristic(neighbor, goal_cell)
			if not open.has(neighbor):
				open.append(neighbor)
	var path: Array = []
	var cursor = best
	path.append(cursor)
	while came_from.has(_key(cursor)):
		cursor = came_from[_key(cursor)]
		path.push_front(cursor)
	if path.size() <= 1:
		return goal
	var next_cell: Vector2i = path[1]
	var next_point: Vector2 = _cell_center(next_cell, run.ARENA_RECT, cell_size)
	return next_point.clamp(run.ARENA_RECT.position + Vector2(radius, radius), run.ARENA_RECT.end - Vector2(radius, radius))

static func _line_walkable(a: Vector2, b: Vector2, radius: float, collision_space: Dictionary) -> bool:
	var distance: float = a.distance_to(b)
	var steps: int = max(2, int(distance / 18.0))
	for i in range(steps + 1):
		var point: Vector2 = a.lerp(b, float(i) / float(steps))
		if LightLabCollision.is_circle_blocked_in_space(point, radius, collision_space):
			return false
	return true

static func _cell_walkable(run, cell: Vector2i, radius: float, cell_size: float, collision_space: Dictionary) -> bool:
	var cols := int(ceil(run.ARENA_RECT.size.x / cell_size))
	var rows := int(ceil(run.ARENA_RECT.size.y / cell_size))
	if cell.x < 0 or cell.y < 0 or cell.x >= cols or cell.y >= rows:
		return false
	var center := _cell_center(cell, run.ARENA_RECT, cell_size)
	return not LightLabCollision.is_circle_blocked_in_space(center, radius, collision_space)

static func _neighbors(cell: Vector2i) -> Array:
	return [
		Vector2i(cell.x + 1, cell.y), Vector2i(cell.x - 1, cell.y),
		Vector2i(cell.x, cell.y + 1), Vector2i(cell.x, cell.y - 1),
		Vector2i(cell.x + 1, cell.y + 1), Vector2i(cell.x - 1, cell.y - 1),
		Vector2i(cell.x + 1, cell.y - 1), Vector2i(cell.x - 1, cell.y + 1)
	]

static func _heuristic(a: Vector2i, b: Vector2i) -> float:
	return absf(float(a.x - b.x)) + absf(float(a.y - b.y))

static func _to_cell(pos: Vector2, rect: Rect2, cell_size: float) -> Vector2i:
	var local := pos - rect.position
	return Vector2i(int(floor(local.x / cell_size)), int(floor(local.y / cell_size)))

static func _cell_center(cell: Vector2i, rect: Rect2, cell_size: float) -> Vector2:
	return rect.position + Vector2((float(cell.x) + 0.5) * cell_size, (float(cell.y) + 0.5) * cell_size)

static func _key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
