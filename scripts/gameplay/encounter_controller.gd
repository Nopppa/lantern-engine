extends RefCounted
class_name EncounterController

const EncounterDefs = preload("res://scripts/data/encounter_defs.gd")
const RunSummary = preload("res://scripts/gameplay/run_summary.gd")

static func check_complete(run: RunScene) -> void:
	if not run.encounter_active:
		return
	for enemy: Dictionary in run.enemies:
		if enemy["alive"]:
			return
	run.encounter_active = false
	var encounter := EncounterDefs.get_encounter(run.encounter_index)
	RunSummary.note_encounter_cleared(run, encounter)
	if run.encounter_index + 1 >= run.encounters.size():
		run.run_over = true
		run.help_collapsed = false
		run.reward_pending = false
		run.reward_resolution_in_progress = false
		run.reward_panel.visible = false
		RunSummary.finish(run)
		run.last_event = "%s cleared — review run summary" % String(encounter.get("title", "Final encounter"))
		return
	run._show_rewards()

static func start_encounter(run: RunScene, index: int) -> void:
	var encounter := EncounterDefs.get_encounter(index)
	run.encounter_index = index
	run.enemies.clear()
	for child in run.world_layer.get_children():
		if child.name.begins_with("Enemy_"):
			child.queue_free()
	run.encounter_active = true
	run.reward_pending = false
	run.reward_resolution_in_progress = false
	run.reward_panel.visible = false
	run.end_panel.visible = false
	for spec: Dictionary in encounter.get("spawns", []):
		spawn_enemy(run, spec["type"], spec["pos"])
	RunSummary.note_encounter_started(run, encounter)
	run.last_event = "%s started" % String(encounter.get("title", "Encounter %d" % [index + 1]))

static func spawn_enemy(run: RunScene, type: String, pos: Vector2) -> void:
	var node := Node2D.new()
	node.name = "Enemy_%s_%d" % [type, randi() % 9999]
	node.position = pos
	run.world_layer.add_child(node)
	var sprite := Polygon2D.new()
	if type == "moth":
		sprite.polygon = PackedVector2Array([Vector2(-14, 0), Vector2(0, -10), Vector2(14, 0), Vector2(0, 10)])
		sprite.color = Color("ffb86c")
		run.enemies.append({"node": node, "type": type, "hp": 24.0, "speed": 116.0, "radius": 16.0, "contact_damage": 14.0, "alive": true, "flash": 0.0, "death_timer": 0.0, "attack_timer": 0.0})
	else:
		sprite.polygon = PackedVector2Array([Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12), Vector2(-12, 12)])
		sprite.color = Color("bd93f9")
		run.enemies.append({"node": node, "type": type, "hp": 34.0, "speed": 92.0, "radius": 16.0, "contact_damage": 19.0, "alive": true, "flash": 0.0, "death_timer": 0.0, "attack_timer": 1.3, "revealed_by_light": false, "shimmer_timer": 0.0, "blink_windup": 0.0, "blink_winding_up": false, "blink_transiting": false, "blink_transit_timer": 0.0, "blink_transit_duration": 0.0, "blink_transit_start": Vector2.ZERO, "blink_transit_end": Vector2.ZERO})
	node.add_child(sprite)
