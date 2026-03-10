extends RefCounted
class_name EnemyController

const BossController = preload("res://scripts/gameplay/boss_controller.gd")
const RunSummary = preload("res://scripts/gameplay/run_summary.gd")
const LightLabCollision = preload("res://scripts/gameplay/light_lab_collision.gd")
const LightLabNavigation = preload("res://scripts/gameplay/light_lab_navigation.gd")

static func update_enemies(run: RunScene, delta: float) -> void:
	BossController.update_projectiles(run, delta)
	for enemy: Dictionary in run.enemies:
		if not enemy["alive"]:
			_tick_dead_enemy(enemy, delta)
			continue
		enemy["flash"] = max(enemy["flash"] - delta, 0.0)
		enemy["special_lock_timer"] = max(float(enemy.get("special_lock_timer", 0.0)) - delta, 0.0)
		_tick_light_burn(run, enemy, delta)
		if not enemy["alive"]:
			continue
		var to_player: Vector2 = run.player_pos - enemy["node"].position
		var dir := _safe_direction_from_player(to_player)
		if enemy["type"] == "moth":
			_update_moth(run, enemy, dir, delta)
		elif enemy["type"] == "hollow":
			_update_hollow(run, enemy, dir, delta)
		elif enemy["type"] == "boss_hollow_matriarch":
			BossController.update_boss(run, enemy, dir, delta)

static func _tick_dead_enemy(enemy: Dictionary, delta: float) -> void:
	enemy["death_timer"] -= delta
	enemy["flash"] = max(enemy["flash"] - delta, 0.0)
	enemy["node"].scale = Vector2.ONE * max(enemy["death_timer"] * 2.0, 0.1)
	if enemy["death_timer"] <= 0.0 and is_instance_valid(enemy["node"]):
		enemy["node"].queue_free()

static func _tick_light_burn(run: RunScene, enemy: Dictionary, delta: float) -> void:
	var burn_timer: float = float(enemy.get("light_burn_timer", 0.0))
	if burn_timer <= 0.0:
		enemy["light_burn_timer"] = 0.0
		enemy["light_burn_tick_timer"] = 0.0
		enemy["light_burn_pulse"] = max(float(enemy.get("light_burn_pulse", 0.0)) - delta * 1.8, 0.0)
		return
	burn_timer = max(burn_timer - delta, 0.0)
	enemy["light_burn_timer"] = burn_timer
	var burn_tick_timer: float = float(enemy.get("light_burn_tick_timer", run.prism_surge_light_burn_tick)) - delta
	while burn_tick_timer <= 0.0 and burn_timer > 0.0 and enemy["alive"]:
		enemy["hp"] -= run.prism_surge_light_burn_damage
		RunSummary.note_damage_dealt(run, run.prism_surge_light_burn_damage)
		enemy["flash"] = max(float(enemy.get("flash", 0.0)), 0.16)
		enemy["light_burn_pulse"] = 0.38
		run._add_hit_flash(enemy["node"].position, enemy["radius"] + 12.0, Color(1.0, 0.94, 0.62, 0.7), 0.12)
		if enemy["hp"] <= 0.0:
			enemy["alive"] = false
			enemy["death_timer"] = 0.35
			RunSummary.note_kill(run, String(enemy["type"]))
			run._add_hit_flash(enemy["node"].position, enemy["radius"] + 22.0, Color(1.0, 0.97, 0.78, 0.95), 0.22)
			run.last_event = "Light Burn consumed a %s" % String(enemy["type"])
			break
		burn_tick_timer += run.prism_surge_light_burn_tick
	enemy["light_burn_tick_timer"] = max(burn_tick_timer, 0.0)
	enemy["light_burn_pulse"] = max(float(enemy.get("light_burn_pulse", 0.0)) - delta * 1.6, 0.0)

static func _safe_direction_from_player(to_player: Vector2) -> Vector2:
	if to_player.length_squared() < 4.0:
		var dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		return dir if dir != Vector2.ZERO else Vector2.RIGHT
	return to_player.normalized()

static func _resolve_motion(run: RunScene, enemy: Dictionary, motion: Vector2) -> void:
	var radius := float(enemy.get("radius", 16.0)) + 4.0
	var segments: Array = run.get("surface_segments") if run.get("surface_segments") != null else []
	var circles: Array = run.get("tree_trunks") if run.get("tree_trunks") != null else []
	var next_pos := LightLabCollision.resolve_circle_motion(enemy["node"].position, radius, motion, segments, circles)
	next_pos = next_pos.clamp(run.ARENA_RECT.position + Vector2(radius, radius), run.ARENA_RECT.end - Vector2(radius, radius))
	enemy["node"].position = next_pos

static func _find_clear_position(run: RunScene, desired: Vector2, radius: float) -> Vector2:
	var clamped := desired.clamp(run.ARENA_RECT.position + Vector2(radius, radius), run.ARENA_RECT.end - Vector2(radius, radius))
	var segments: Array = run.get("surface_segments") if run.get("surface_segments") != null else []
	var circles: Array = run.get("tree_trunks") if run.get("tree_trunks") != null else []
	if segments.is_empty() or not LightLabCollision.is_circle_blocked(clamped, radius + 4.0, segments, circles):
		return clamped
	for ring in range(1, 5):
		for step in range(12):
			var probe := clamped + Vector2.RIGHT.rotated(TAU * float(step) / 12.0) * 18.0 * float(ring)
			probe = probe.clamp(run.ARENA_RECT.position + Vector2(radius, radius), run.ARENA_RECT.end - Vector2(radius, radius))
			if not LightLabCollision.is_circle_blocked(probe, radius + 4.0, segments, circles):
				return probe
	return clamped

static func _update_moth(run: RunScene, enemy: Dictionary, dir: Vector2, delta: float) -> void:
	var steer: Vector2 = _steer_toward_player(run, enemy, dir)
	_resolve_motion(run, enemy, steer * enemy["speed"] * delta)

static func _update_hollow(run: RunScene, enemy: Dictionary, dir: Vector2, delta: float) -> void:
	var light_state := run._light_state_for_position(enemy["node"].position)
	var in_light := bool(light_state.get("flashlight", false)) or bool(light_state.get("prism", false))
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
		var target_pos := _find_clear_position(run, run.player_pos + dir.rotated(PI) * blink_dist + flank, float(enemy.get("radius", 16.0)) + 6.0)
		enemy["blink_transiting"] = true
		enemy["blink_transit_start"] = enemy["node"].position
		enemy["blink_transit_end"] = target_pos
		enemy["blink_transit_duration"] = 0.28
		enemy["blink_transit_timer"] = 0.28
		run.last_event = "Hollow disrupted transit..."
	else:
		var jitter := Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		enemy["node"].position += jitter

static func _steer_toward_player(run: RunScene, enemy: Dictionary, fallback_dir: Vector2) -> Vector2:
	var radius: float = float(enemy.get("radius", 16.0)) + 6.0
	var waypoint: Vector2 = LightLabNavigation.next_waypoint(run, enemy["node"].position, run.player_pos, radius)
	var steer: Vector2 = (waypoint - enemy["node"].position).normalized()
	if steer == Vector2.ZERO:
		steer = fallback_dir
	enemy["nav_target"] = waypoint
	return steer

static func _update_hollow_active(run: RunScene, enemy: Dictionary, dir: Vector2, in_light: bool, delta: float) -> void:
	enemy["attack_timer"] -= delta
	var special_lock_timer: float = float(enemy.get("special_lock_timer", 0.0))
	if enemy["attack_timer"] <= 0.0:
		if special_lock_timer > 0.0:
			enemy["attack_timer"] = min(0.2, special_lock_timer)
			run.last_event = "Hollow blink jammed by Prism Surge"
		elif in_light:
			enemy["blink_winding_up"] = true
			enemy["blink_windup"] = 0.4
			run.last_event = "Hollow struggling to blink..."
		else:
			enemy["attack_timer"] = 2.4
			var flank: Vector2 = Vector2(randf_range(-80, 80), randf_range(-80, 80))
			enemy["node"].position = _find_clear_position(run, run.player_pos + dir.rotated(PI) * 140.0 + flank, float(enemy.get("radius", 16.0)) + 6.0)
			run.last_event = "Hollow ambush blink"
	else:
		var steer: Vector2 = _steer_toward_player(run, enemy, dir)
		_resolve_motion(run, enemy, steer * enemy["speed"] * 0.55 * delta)
