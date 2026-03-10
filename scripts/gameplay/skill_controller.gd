extends RefCounted
class_name SkillController

const SfxController = preload("res://scripts/gameplay/sfx_controller.gd")
const RunSummary = preload("res://scripts/gameplay/run_summary.gd")

static func cast_prism_surge(run: RunScene) -> void:
	if not run.prism_surge_unlocked:
		run.last_event = "Prism Surge not unlocked"
		return
	if run.prism_surge_timer > 0.0:
		run.last_event = "Prism Surge recharging"
		return
	if not run.prism_node:
		run.last_event = "Prism Surge needs an active Prism Node"
		return
	var origin: Vector2 = run.prism_node.position
	var hit_count := 0
	for enemy: Dictionary in run.enemies:
		if not enemy["alive"]:
			continue
		if not is_instance_valid(enemy["node"]):
			continue
		var distance: float = enemy["node"].position.distance_to(origin)
		if distance > run.prism_surge_radius + enemy["radius"]:
			continue
		hit_count += 1
		enemy["hp"] -= run.prism_surge_damage
		RunSummary.note_damage_dealt(run, run.prism_surge_damage)
		enemy["flash"] = 0.35
		var push_dir: Vector2 = (enemy["node"].position - origin).normalized()
		if push_dir == Vector2.ZERO:
			push_dir = Vector2.RIGHT.rotated(randf() * TAU)
		enemy["node"].position = (enemy["node"].position + push_dir * run.prism_surge_push_distance).clamp(run.ARENA_RECT.position + Vector2(enemy["radius"], enemy["radius"]), run.ARENA_RECT.end - Vector2(enemy["radius"], enemy["radius"]))
		if enemy["type"] == "hollow":
			enemy["attack_timer"] = max(float(enemy.get("attack_timer", 0.0)), 1.4)
			enemy["blink_winding_up"] = false
			enemy["blink_transiting"] = false
			enemy["shimmer_timer"] = max(float(enemy.get("shimmer_timer", 0.0)), 0.45)
		var hit_color := Color(0.72, 0.96, 1.0, 0.95)
		run._add_hit_flash(enemy["node"].position, enemy["radius"] + 20.0, hit_color, 0.18)
		if enemy["hp"] <= 0.0:
			enemy["alive"] = false
			enemy["death_timer"] = 0.35
			RunSummary.note_kill(run, String(enemy["type"]))
			run._add_hit_flash(enemy["node"].position, enemy["radius"] + 24.0, Color(1.0, 0.98, 0.82, 1.0), 0.24)
	var refunded_energy: float = minf(run.max_energy - run.energy, float(hit_count) * run.prism_surge_energy_refund_on_hit)
	run.energy += refunded_energy
	run._add_hit_flash(origin, run.prism_surge_radius, Color(0.62, 0.94, 1.0, 0.9), 0.26)
	if run.prism_node:
		run.prism_node.queue_free()
		run.prism_node = null
	run.prism_timer = max(run.prism_timer, run.prism_cooldown)
	run.prism_surge_timer = run.prism_surge_cooldown
	RunSummary.note_skill_cast(run, "prism_surge")
	SfxController.play(run, "beam")
	if hit_count > 0:
		run.last_event = "Prism Surge burst for %.0f across %d target%s" % [run.prism_surge_damage, hit_count, "" if hit_count == 1 else "s"]
	else:
		run.last_event = "Prism Surge discharged with no target in the blast"
