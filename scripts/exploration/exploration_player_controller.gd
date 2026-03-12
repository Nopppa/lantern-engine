extends RefCounted
class_name ExplorationPlayerController

const LightLabCollision = preload("res://scripts/gameplay/light_lab_collision.gd")

var arena_rect: Rect2 = Rect2()
var player_radius := 14.0
var player_speed := 240.0
var light_world: LightWorld = null

func configure(config: Dictionary) -> void:
	arena_rect = Rect2(config.get("arena_rect", Rect2()))
	player_radius = float(config.get("player_radius", player_radius))
	player_speed = float(config.get("player_speed", player_speed))

func reset(world: LightWorld) -> void:
	light_world = world

func resolve_spawn(target: Vector2) -> Vector2:
	var candidate := _clamp_to_arena(target)
	var collision_space := _collision_space()
	if not LightLabCollision.is_circle_blocked_in_space(candidate, player_radius, collision_space):
		return candidate
	for ring in range(1, 7):
		for step in range(16):
			var angle := TAU * float(step) / 16.0
			var probe := candidate + Vector2.RIGHT.rotated(angle) * float(ring) * 20.0
			probe = _clamp_to_arena(probe)
			if not LightLabCollision.is_circle_blocked_in_space(probe, player_radius, collision_space):
				return probe
	return _clamp_to_arena(arena_rect.get_center())

func step(player_pos: Vector2, facing: Vector2, mouse_world: Vector2, delta: float) -> Dictionary:
	var next_pos := player_pos
	var next_facing := facing
	var input_dir := _input_vector()
	if mouse_world.distance_to(player_pos) > 8.0:
		next_facing = (mouse_world - player_pos).normalized()
	if input_dir.length() > 0.0:
		input_dir = input_dir.normalized()
		var target_pos := LightLabCollision.resolve_circle_motion_in_space(
			player_pos,
			player_radius,
			input_dir * player_speed * delta,
			_collision_space()
		)
		next_pos = _clamp_to_arena(target_pos)
	return {
		"position": next_pos,
		"facing": next_facing,
		"moved": next_pos != player_pos,
		"input_dir": input_dir
	}

func _input_vector() -> Vector2:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
	return input_dir

func _collision_space() -> Dictionary:
	if light_world == null:
		return {"segments": [], "circles": []}
	return light_world.collision_space()

func _clamp_to_arena(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, arena_rect.position.x + player_radius, arena_rect.end.x - player_radius),
		clampf(pos.y, arena_rect.position.y + player_radius, arena_rect.end.y - player_radius)
	)
