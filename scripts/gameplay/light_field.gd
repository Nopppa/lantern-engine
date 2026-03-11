extends RefCounted
class_name LightField

var rect: Rect2
var cell_size := 24.0
var width_cells := 0
var height_cells := 0
var current_light: PackedFloat32Array = PackedFloat32Array()
var stored_light: PackedFloat32Array = PackedFloat32Array()
var display_light: PackedFloat32Array = PackedFloat32Array()
var decay_rate := 1.4

func _init(world_rect: Rect2 = Rect2(), grid_cell_size: float = 24.0, grid_decay_rate: float = 1.4) -> void:
	rect = world_rect
	cell_size = max(grid_cell_size, 1.0)
	decay_rate = max(grid_decay_rate, 0.01)
	width_cells = max(1, int(ceil(rect.size.x / cell_size)))
	height_cells = max(1, int(ceil(rect.size.y / cell_size)))
	var count := width_cells * height_cells
	current_light.resize(count)
	stored_light.resize(count)
	display_light.resize(count)
	_fill_zero(current_light)
	_fill_zero(stored_light)
	_fill_zero(display_light)

func clear_dynamic_light() -> void:
	_fill_zero(current_light)

func add_light_world(pos: Vector2, energy: float) -> void:
	var index := _index_for_world(pos)
	if index < 0:
		return
	current_light[index] = max(current_light[index], clampf(energy, 0.0, 1.0))

func add_splat_world(pos: Vector2, radius: float, energy: float) -> void:
	var clamped_energy := clampf(energy, 0.0, 1.0)
	if clamped_energy <= 0.0 or radius <= 0.0:
		return
	var min_cell := _cell_for_world(pos - Vector2.ONE * radius)
	var max_cell := _cell_for_world(pos + Vector2.ONE * radius)
	for cy in range(min_cell.y, max_cell.y + 1):
		if cy < 0 or cy >= height_cells:
			continue
		for cx in range(min_cell.x, max_cell.x + 1):
			if cx < 0 or cx >= width_cells:
				continue
			var sample_pos := _world_for_cell(cx, cy)
			var distance := sample_pos.distance_to(pos)
			if distance > radius:
				continue
			var falloff := pow(1.0 - distance / max(radius, 0.001), 1.15)
			var index := cy * width_cells + cx
			current_light[index] = max(current_light[index], clamped_energy * falloff)

func sample_world(pos: Vector2) -> float:
	var index := _index_for_world(pos)
	if index < 0:
		return 0.0
	return display_light[index]

func process_field(delta: float) -> void:
	for i in range(current_light.size()):
		var current := current_light[i]
		var stored := stored_light[i]
		if current >= stored:
			stored = lerpf(stored, current, min(1.0, delta * 10.0))
		else:
			stored = max(current, stored - delta * decay_rate)
		stored_light[i] = stored
		display_light[i] = lerpf(display_light[i], stored, min(1.0, delta * 12.0))

func _index_for_world(pos: Vector2) -> int:
	if not rect.has_point(pos):
		return -1
	var cell := _cell_for_world(pos)
	if cell.x < 0 or cell.x >= width_cells or cell.y < 0 or cell.y >= height_cells:
		return -1
	return cell.y * width_cells + cell.x

func _cell_for_world(pos: Vector2) -> Vector2i:
	var local := pos - rect.position
	return Vector2i(int(floor(local.x / cell_size)), int(floor(local.y / cell_size)))

func _world_for_cell(cx: int, cy: int) -> Vector2:
	return rect.position + Vector2((float(cx) + 0.5) * cell_size, (float(cy) + 0.5) * cell_size)

func _fill_zero(array: PackedFloat32Array) -> void:
	for i in range(array.size()):
		array[i] = 0.0
