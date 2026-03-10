extends RefCounted
class_name EnemyController

static func update_enemies(run: RunScene, delta: float) -> void:
	for enemy: Dictionary in run.enemies:
		if not enemy["alive"]:
			_tick_dead_enemy(enemy, delta)
			continue
		enemy["flash"] = max(enemy["flash"] - delta, 0.0)
		var to_player: Vector2 = run.player_pos - enemy["node"].position
		var dir := _safe_direction_from_player(to_player)
		if enemy["type"] == "moth":
			_update_moth(enemy, dir, delta)
		elif enemy["type"] == "hollow":
			_update_hollow(run, enemy, dir, delta)
		if enemy["node"].position.distance_to(run.player_pos) < run.ENEMY_CONTACT_RADIUS + enemy["radius"]:
			run._apply_contact_damage(enemy["contact_damage"] * delta)

static func _tick_dead_enemy(enemy: Dictionary, delta: float) -> void:
	enemy["death_timer"] -= delta
	enemy["flash"] = max(enemy["flash"] - delta, 0.0)
	enemy["node"].scale = Vector2.ONE * max(enemy["death_timer"] * 2.0, 0.1)
	if enemy["death_timer"] <= 0.0 and is_instance_valid(enemy["node"]):
		enemy["node"].queue_free()

static func _safe_direction_from_player(to_player: Vector2) -> Vector2:
	if to_player.length_squared() < 4.0:
		var dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		return dir if dir != Vector2.ZERO else Vector2.RIGHT
	return to_player.normalized()

static func _update_moth(enemy: Dictionary, dir: Vector2, delta: float) -> void:
	enemy["node"].position += dir * enemy["speed"] * delta

static func _update_hollow(run: RunScene, enemy: Dictionary, dir: Vector2, delta: float) -> void:
	var in_light := run._is_in_flashlight_cone(enemy["node"].position)
	enemy["revealed_by_light"] = in_light
	if enemy["blink_transiting"]:
		_update_hollow_transit(run, enemy, delta)
	elif enemy["blink_winding_up"]:
		_update_hollow_windup(run, enemy, dir, delta)
	else:
		_update_hollow_active(run, enemy, dir, in_light, delta)
	if enemy.get("shimmer_timer", 0.0) > 0.0:
		enemy["shimmer_timer"] -= delta

static func _update_hollow_transit(run: RunScene, enemy: Dictionary, delta: float) -> void:
	enemy["blink_transit_timer"] -= delta
	var t_progress: float = 1.0 - clampf(float(enemy["blink_transit_timer"]) / float(enemy["blink_transit_duration"]), 0.0, 1.0)
	enemy["node"].position = Vector2(enemy["blink_transit_start"]).lerp(Vector2(enemy["blink_transit_end"]), t_progress)
	if enemy["blink_transit_timer"] <= 0.0:
		enemy["blink_transiting"] = false
		enemy["node"].position = Vector2(enemy["blink_transit_end"])
		enemy["attack_timer"] = 2.6
		enemy["shimmer_timer"] = 0.5
		run.last_event = "Hollow blink DISRUPTED by flashlight"

static func _update_hollow_windup(run: RunScene, enemy: Dictionary, dir: Vector2, delta: float) -> void:
	enemy["blink_windup"] -= delta
	if enemy["blink_windup"] <= 0.0:
		enemy["blink_winding_up"] = false
		var blink_dist := 140.0 * 0.4
		var flank := Vector2(randf_range(-50, 50), randf_range(-50, 50))
		var target_pos := (run.player_pos + dir.rotated(PI) * blink_dist + flank).clamp(run.ARENA_RECT.position + Vector2(32, 32), run.ARENA_RECT.end - Vector2(32, 32))
		enemy["blink_transiting"] = true
		enemy["blink_transit_start"] = enemy["node"].position
		enemy["blink_transit_end"] = target_pos
		enemy["blink_transit_duration"] = 0.28
		enemy["blink_transit_timer"] = 0.28
		run.last_event = "Hollow disrupted transit..."
	else:
		var jitter := Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		enemy["node"].position += jitter

static func _update_hollow_active(run: RunScene, enemy: Dictionary, dir: Vector2, in_light: bool, delta: float) -> void:
	enemy["attack_timer"] -= delta
	if enemy["attack_timer"] <= 0.0:
		if in_light:
			enemy["blink_winding_up"] = true
			enemy["blink_windup"] = 0.4
			run.last_event = "Hollow struggling to blink..."
		else:
			enemy["attack_timer"] = 2.4
			var flank := Vector2(randf_range(-80, 80), randf_range(-80, 80))
			enemy["node"].position = (run.player_pos + dir.rotated(PI) * 140.0 + flank).clamp(run.ARENA_RECT.position + Vector2(32, 32), run.ARENA_RECT.end - Vector2(32, 32))
			run.last_event = "Hollow ambush blink"
	else:
		enemy["node"].position += dir * enemy["speed"] * 0.55 * delta
