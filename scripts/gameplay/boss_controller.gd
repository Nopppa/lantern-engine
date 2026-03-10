extends RefCounted
class_name BossController

const BossDefs = preload("res://scripts/data/boss_defs.gd")
const RunSummary = preload("res://scripts/gameplay/run_summary.gd")

static func spawn_boss(run: RunScene, boss_id: String, pos: Vector2) -> void:
	if boss_id != "hollow_matriarch":
		return
	var boss_def := BossDefs.get_boss(boss_id)
	if boss_def.is_empty():
		return
	var core_rules: Dictionary = boss_def.get("core_rules", {})
	var dark_regen: Dictionary = core_rules.get("dark_regen", {})
	var skills := _skill_map(Array(boss_def.get("skills", [])))
	var shadow_bolt: Dictionary = skills.get("shadow_bolt", {})
	var veil_pounce: Dictionary = skills.get("veil_pounce", {})
	var node := Node2D.new()
	node.name = "Enemy_hollow_matriarch_%d" % (randi() % 9999)
	node.position = pos
	run.world_layer.add_child(node)
	run.enemies.append({
		"node": node,
		"type": "boss_hollow_matriarch",
		"boss_id": boss_id,
		"display_name": String(boss_def.get("display_name", "Hollow Matriarch")),
		"hp": float(core_rules.get("hp", 420.0)),
		"max_hp": float(core_rules.get("hp", 420.0)),
		"speed": float(core_rules.get("base_move_speed", 72.0)),
		"radius": 28.0,
		"contact_damage": float(core_rules.get("contact_damage_per_second", 18.0)),
		"alive": true,
		"flash": 0.0,
		"death_timer": 0.0,
		"special_lock_timer": 0.0,
		"light_burn_timer": 0.0,
		"light_burn_tick_timer": 0.0,
		"light_burn_pulse": 0.0,
		"attack_timer": 0.0,
		"projectile_cooldown": randf_range(0.6, 1.1),
		"projectile_profile": shadow_bolt.duplicate(true),
		"special_cooldown": randf_range(2.2, 3.2),
		"special_profile": veil_pounce.duplicate(true),
		"special_state": "idle",
		"special_timer": 0.0,
		"special_target": pos,
		"regen_rate": float(dark_regen.get("hp_per_second", 7.0)),
		"regen_delay": float(dark_regen.get("delay_out_of_light", 1.35)),
		"regen_delay_timer": float(dark_regen.get("delay_out_of_light", 1.35)),
		"regen_active": false,
		"phase": 1,
		"phase_threshold": float(Array(core_rules.get("phase_thresholds", [0.5]))[0]),
		"revealed_by_light": false,
		"boss_def": boss_def.duplicate(true)
	})
	run.last_event = "%s entered the arena" % String(boss_def.get("display_name", "Hollow Matriarch"))

static func update_boss(run: RunScene, enemy: Dictionary, dir: Vector2, delta: float) -> void:
	var light_state := run._light_state_for_position(enemy["node"].position)
	var in_honest_light: bool = bool(light_state.get("honest", false))
	var in_prism_light: bool = bool(light_state.get("prism", false))
	var in_flashlight: bool = bool(light_state.get("flashlight", false))
	enemy["revealed_by_light"] = in_honest_light
	_update_phase(run, enemy)
	_tick_regen(run, enemy, in_honest_light, delta)
	var special_lock_timer: float = float(enemy.get("special_lock_timer", 0.0))
	if String(enemy.get("special_state", "idle")) == "windup":
		_update_pounce_windup(run, enemy, in_honest_light, delta)
	elif String(enemy.get("special_state", "idle")) == "pouncing":
		_update_pounce(run, enemy, delta)
	else:
		enemy["node"].position += dir * float(enemy["speed"]) * (0.62 if in_honest_light else 1.0) * delta
		var projectile_cooldown: float = float(enemy.get("projectile_cooldown", 0.0)) - delta
		var special_cooldown: float = float(enemy.get("special_cooldown", 0.0)) - delta
		if special_lock_timer <= 0.0 and special_cooldown <= 0.0:
			_start_pounce(run, enemy)
			special_cooldown = _special_interval(enemy)
		elif projectile_cooldown <= 0.0:
			_fire_shadow_bolt(run, enemy)
			projectile_cooldown = _projectile_interval(enemy)
		enemy["projectile_cooldown"] = projectile_cooldown
		enemy["special_cooldown"] = special_cooldown
	if enemy["node"].position.distance_to(run.player_pos) < run.ENEMY_CONTACT_RADIUS + enemy["radius"]:
		run._apply_contact_damage(enemy["contact_damage"] * delta)

static func update_projectiles(run: RunScene, delta: float) -> void:
	for i in range(run.boss_projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = run.boss_projectiles[i]
		projectile["lifetime"] = float(projectile.get("lifetime", 0.0)) - delta
		if float(projectile.get("lifetime", 0.0)) <= 0.0:
			run.boss_projectiles.remove_at(i)
			continue
		var pos: Vector2 = projectile["pos"]
		pos += Vector2(projectile["velocity"]) * delta
		projectile["pos"] = pos
		var light_state := run._light_state_for_position(pos)
		var light_dps := 0.0
		if bool(light_state.get("flashlight", false)):
			light_dps += float(projectile.get("flashlight_dps", 0.0))
		if bool(light_state.get("prism", false)):
			light_dps += float(projectile.get("prism_light_dps", 0.0))
		if light_dps > 0.0:
			projectile["hp"] = float(projectile.get("hp", 0.0)) - light_dps * delta
			projectile["light_decay"] = min(float(projectile.get("light_decay", 0.0)) + delta * 2.6, 1.0)
			if int(Time.get_ticks_msec()) % 90 < 18:
				run._add_hit_flash(pos, float(projectile.get("radius", 18.0)) + 6.0, Color(1.0, 0.95, 0.72, 0.35), 0.08)
		else:
			projectile["light_decay"] = max(float(projectile.get("light_decay", 0.0)) - delta * 1.5, 0.0)
		if float(projectile.get("hp", 0.0)) <= 0.0:
			run._add_hit_flash(pos, float(projectile.get("radius", 18.0)) + 12.0, Color(1.0, 0.96, 0.8, 0.82), 0.16)
			run.last_event = "Shadow bolt dissolved in honest light"
			run.boss_projectiles.remove_at(i)
			continue
		if not run.ARENA_RECT.has_point(pos):
			run.boss_projectiles.remove_at(i)
			continue
		if pos.distance_to(run.player_pos) <= float(projectile.get("radius", 18.0)) + run.PLAYER_RADIUS:
			run._apply_contact_damage(float(projectile.get("contact_damage", 22.0)))
			run._add_hit_flash(pos, float(projectile.get("radius", 18.0)) + 18.0, Color(0.3, 0.0, 0.0, 0.75), 0.18)
			run.last_event = "Shadow bolt impact"
			run.boss_projectiles.remove_at(i)

static func _update_phase(run: RunScene, enemy: Dictionary) -> void:
	var hp_ratio: float = float(enemy.get("hp", 1.0)) / max(float(enemy.get("max_hp", 1.0)), 0.001)
	if hp_ratio <= float(enemy.get("phase_threshold", 0.5)) and int(enemy.get("phase", 1)) == 1:
		enemy["phase"] = 2
		enemy["projectile_cooldown"] = min(float(enemy.get("projectile_cooldown", 0.0)), 0.45)
		enemy["special_cooldown"] = min(float(enemy.get("special_cooldown", 0.0)), 1.0)
		run.last_event = "Hollow Matriarch enrages at half health"

static func _tick_regen(run: RunScene, enemy: Dictionary, in_honest_light: bool, delta: float) -> void:
	if in_honest_light:
		enemy["regen_delay_timer"] = float(enemy.get("regen_delay", 1.35))
		enemy["regen_active"] = false
		return
	enemy["regen_delay_timer"] = max(float(enemy.get("regen_delay_timer", 0.0)) - delta, 0.0)
	if float(enemy.get("regen_delay_timer", 0.0)) > 0.0:
		enemy["regen_active"] = false
		return
	enemy["regen_active"] = true
	enemy["hp"] = min(float(enemy.get("max_hp", 0.0)), float(enemy.get("hp", 0.0)) + float(enemy.get("regen_rate", 0.0)) * delta)
	if int(Time.get_ticks_msec()) % 180 < 18:
		run._add_hit_flash(enemy["node"].position, enemy["radius"] + 18.0, Color(0.08, 0.0, 0.0, 0.4), 0.1)

static func _fire_shadow_bolt(run: RunScene, enemy: Dictionary) -> void:
	var projectile_profile: Dictionary = enemy.get("projectile_profile", {})
	var projectile_data: Dictionary = projectile_profile.get("projectile", {})
	var direction: Vector2 = (run.player_pos - enemy["node"].position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT
	var spawn_pos: Vector2 = enemy["node"].position + direction * (enemy["radius"] + 10.0)
	run.boss_projectiles.append({
		"pos": spawn_pos,
		"velocity": direction * float(projectile_data.get("speed", 250.0)),
		"radius": float(projectile_data.get("radius", 18.0)),
		"contact_damage": float(projectile_data.get("contact_damage", 22.0)),
		"hp": float(projectile_data.get("hp", 28.0)),
		"max_hp": float(projectile_data.get("hp", 28.0)),
		"lifetime": float(projectile_data.get("lifetime", 4.5)),
		"flashlight_dps": float(Dictionary(projectile_data.get("light_damage", {})).get("flashlight_dps", 18.0)),
		"prism_light_dps": float(Dictionary(projectile_data.get("light_damage", {})).get("prism_light_dps", 26.0)),
		"light_decay": 0.0
	})
	run._add_hit_flash(spawn_pos, float(projectile_data.get("radius", 18.0)) + 10.0, Color(0.45, 0.12, 0.62, 0.55), 0.12)
	run.last_event = "Hollow Matriarch fired shadow bolt"

static func _start_pounce(run: RunScene, enemy: Dictionary) -> void:
	var profile: Dictionary = enemy.get("special_profile", {})
	enemy["special_state"] = "windup"
	enemy["special_timer"] = float(profile.get("windup", 0.65))
	var target := run.player_pos
	var light_state := run._light_state_for_position(enemy["node"].position)
	if bool(light_state.get("honest", false)):
		target = enemy["node"].position + (run.player_pos - enemy["node"].position).normalized() * float(profile.get("range", 220.0)) * 0.42
		target = target.clamp(run.ARENA_RECT.position + Vector2(32, 32), run.ARENA_RECT.end - Vector2(32, 32))
	enemy["special_target"] = target
	run.last_event = "Hollow Matriarch compresses for Veil Pounce"

static func _update_pounce_windup(run: RunScene, enemy: Dictionary, in_honest_light: bool, delta: float) -> void:
	enemy["special_timer"] = float(enemy.get("special_timer", 0.0)) - delta
	enemy["node"].position += Vector2(randf_range(-2.2, 2.2), randf_range(-2.2, 2.2))
	if float(enemy.get("special_lock_timer", 0.0)) > 0.0:
		enemy["special_state"] = "idle"
		enemy["special_timer"] = 0.0
		run.last_event = "Prism Surge jammed Veil Pounce"
		return
	if float(enemy.get("special_timer", 0.0)) > 0.0:
		return
	enemy["special_state"] = "pouncing"
	enemy["special_duration"] = 0.2 if not in_honest_light else 0.32
	enemy["special_timer"] = float(enemy["special_duration"])
	enemy["special_start"] = enemy["node"].position
	var target: Vector2 = enemy.get("special_target", run.player_pos)
	if in_honest_light:
		target = Vector2(enemy["special_start"]).lerp(target, 0.48)
	enemy["special_target"] = target
	run.last_event = "Hollow Matriarch launched Veil Pounce"

static func _update_pounce(run: RunScene, enemy: Dictionary, delta: float) -> void:
	var total_time: float = max(float(enemy.get("special_duration", 0.2)), 0.001)
	var remaining: float = max(float(enemy.get("special_timer", 0.0)) - delta, 0.0)
	var progress := 1.0 - remaining / total_time
	enemy["node"].position = Vector2(enemy.get("special_start", enemy["node"].position)).lerp(Vector2(enemy.get("special_target", enemy["node"].position)), progress)
	enemy["special_timer"] = remaining
	if remaining > 0.0:
		return
	enemy["special_state"] = "idle"
	enemy["special_timer"] = 0.0
	if enemy["node"].position.distance_to(run.player_pos) <= enemy["radius"] + run.PLAYER_RADIUS + 12.0:
		var profile: Dictionary = enemy.get("special_profile", {})
		run._apply_contact_damage(float(profile.get("impact_damage", 28.0)))
		run.last_event = "Veil Pounce connected"
	else:
		run.last_event = "Veil Pounce missed"

static func _projectile_interval(enemy: Dictionary) -> float:
	var base_cd := float(Dictionary(enemy.get("projectile_profile", {})).get("cooldown", 2.2))
	return base_cd * (0.78 if int(enemy.get("phase", 1)) >= 2 else 1.0)

static func _special_interval(enemy: Dictionary) -> float:
	var base_cd := float(Dictionary(enemy.get("special_profile", {})).get("cooldown", 5.5))
	return base_cd * (0.76 if int(enemy.get("phase", 1)) >= 2 else 1.0)

static func _skill_map(skills: Array) -> Dictionary:
	var map := {}
	for skill in skills:
		if typeof(skill) == TYPE_DICTIONARY:
			map[String(skill.get("id", ""))] = Dictionary(skill).duplicate(true)
	return map
