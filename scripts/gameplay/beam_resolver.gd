extends RefCounted
class_name BeamResolver

const SfxController = preload("res://scripts/gameplay/sfx_controller.gd")
const RunSummary = preload("res://scripts/gameplay/run_summary.gd")

static func cast_beam(run: RunScene, target: Vector2) -> void:
	if run.beam_timer > 0.0:
		run.last_event = "Beam on cooldown"
		return
	if run.energy < run.beam_cost:
		run.last_event = "Low energy"
		return
	run.energy -= run.beam_cost
	run.beam_timer = run.beam_cooldown
	run.beam_flash = 1.0
	run.beam_pulse_timer = run.BEAM_PULSE_DURATION
	run.beam_segments.clear()
	run.hit_flashes.clear()
	RunSummary.note_beam_cast(run)
	SfxController.play(run, "beam")
	var direction := (target - run.player_pos).normalized()
	if direction == Vector2.ZERO:
		direction = run.facing
	var current_origin := run.player_pos
	var current_direction := direction
	var bounces_left := run.beam_bounces
	var prism_redirect_used := false
	var prism_redirect_bounces_granted := false
	var remaining_range := run.beam_range
	var any_hit := false
	while remaining_range > 0.0:
		var segment := beam_to_bounds(run, current_origin, current_direction, remaining_range)
		var segment_start: Vector2 = segment[0]
		var segment_end: Vector2 = segment[1]
		var segment_damage := run.beam_damage + float(max(run.beam_bounces - bounces_left, 0)) * 4.0
		if prism_redirect_used:
			segment_damage += run.prism_redirect_damage_bonus
		var prism_hit := {}
		if run.prism_node and not prism_redirect_used:
			prism_hit = segment_circle_hit(segment_start, segment_end, run.prism_node.position, run.current_prism_radius())
		if prism_hit.size() > 0:
			var hit_pos: Vector2 = prism_hit["point"]
			run.beam_segments.append([segment_start, hit_pos])
			damage_enemies_along_segment(run, segment_start, hit_pos, segment_damage)
			remaining_range -= segment_start.distance_to(hit_pos)
			if remaining_range <= 0.0:
				break
			current_direction = redirected_prism_direction(run, current_direction)
			current_origin = hit_pos + current_direction * run.BEAM_OFFSET
			prism_redirect_used = true
			if not prism_redirect_bounces_granted:
				bounces_left += run.prism_redirect_bonus_bounces
				prism_redirect_bounces_granted = true
			RunSummary.note_prism_redirect(run)
			any_hit = true
			run.last_event = "Refraction Beam redirected through Prism Node"
			continue
		run.beam_segments.append([segment_start, segment_end])
		damage_enemies_along_segment(run, segment_start, segment_end, segment_damage)
		remaining_range -= segment_start.distance_to(segment_end)
		any_hit = true
		if remaining_range <= 0.0 or bounces_left <= 0:
			break
		var bounce_result := reflect_if_wall(run, segment_end, current_direction)
		if bounce_result.is_empty():
			break
		current_direction = bounce_result["direction"]
		current_origin = bounce_result["point"] + current_direction * run.BEAM_OFFSET
		bounces_left -= 1
		run.last_event = "Beam bounced off arena wall"
	if not any_hit:
		run.last_event = "Beam fizzled"
	run.lit_zones = run._build_lit_zones()

static func redirected_prism_direction(run: RunScene, direction: Vector2) -> Vector2:
	var redirect_angle: float = run.current_prism_redirect_angle()
	return direction.rotated(deg_to_rad(redirect_angle if direction.y >= 0.0 else -redirect_angle)).normalized()

static func beam_to_bounds(run: RunScene, origin: Vector2, direction: Vector2, length: float) -> Array:
	var end := origin + direction * length
	var t := 1.0
	if direction.x > 0.0:
		t = min(t, (run.ARENA_RECT.end.x - origin.x) / max(direction.x * length, 0.001))
	elif direction.x < 0.0:
		t = min(t, (run.ARENA_RECT.position.x - origin.x) / min(direction.x * length, -0.001))
	if direction.y > 0.0:
		t = min(t, (run.ARENA_RECT.end.y - origin.y) / max(direction.y * length, 0.001))
	elif direction.y < 0.0:
		t = min(t, (run.ARENA_RECT.position.y - origin.y) / min(direction.y * length, -0.001))
	end = origin + direction * length * clamp(t, 0.0, 1.0)
	return [origin, end]

static func reflect_if_wall(run: RunScene, end: Vector2, direction: Vector2) -> Dictionary:
	var reflected := direction
	var hit_wall := false
	if is_equal_approx(end.x, run.ARENA_RECT.position.x) or is_equal_approx(end.x, run.ARENA_RECT.end.x):
		reflected.x *= -1.0
		hit_wall = true
	if is_equal_approx(end.y, run.ARENA_RECT.position.y) or is_equal_approx(end.y, run.ARENA_RECT.end.y):
		reflected.y *= -1.0
		hit_wall = true
	if not hit_wall:
		return {}
	return {"point": end, "direction": reflected.normalized()}

static func segment_circle_hit(a: Vector2, b: Vector2, center: Vector2, radius: float) -> Dictionary:
	var ab: Vector2 = b - a
	var t: float = clamp((center - a).dot(ab) / max(ab.length_squared(), 0.001), 0.0, 1.0)
	var p: Vector2 = a + ab * t
	if p.distance_to(center) <= radius:
		return {"point": p, "t": t}
	return {}

static func damage_enemies_along_segment(run: RunScene, a: Vector2, b: Vector2, damage: float) -> void:
	for enemy: Dictionary in run.enemies:
		if not enemy["alive"]:
			continue
		var hit: Dictionary = segment_circle_hit(a, b, enemy["node"].position, enemy["radius"])
		if hit.size() > 0:
			enemy["hp"] -= damage
			RunSummary.note_damage_dealt(run, damage)
			enemy["flash"] = 0.25
			var hit_pos: Vector2 = hit["point"]
			var hit_color := Color(1.0, 0.82, 0.45, 0.95) if enemy["type"] == "moth" else Color(0.88, 0.72, 1.0, 0.95)
			run._add_hit_flash(hit_pos, enemy["radius"] + 12.0, hit_color)
			run.last_event = "Hit %s for %.0f" % [enemy["type"], damage]
			if enemy["hp"] <= 0.0:
				enemy["alive"] = false
				enemy["death_timer"] = 0.35
				RunSummary.note_kill(run, String(enemy["type"]))
				run._add_hit_flash(enemy["node"].position, enemy["radius"] + 22.0, Color(1.0, 0.96, 0.76, 1.0), 0.22)
				SfxController.play(run, "kill")
				run.last_event = "%s eliminated" % String(enemy["type"]).capitalize()
			else:
				SfxController.play(run, "hit")
