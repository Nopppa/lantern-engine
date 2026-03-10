extends RefCounted
class_name RunSummary

static func make_tracker() -> Dictionary:
	return {
		"encounters_started": [],
		"encounters_cleared": [],
		"upgrades": [],
		"upgrade_ids": [],
		"beams_cast": 0,
		"prisms_placed": 0,
		"prism_redirects": 0,
		"skill_casts": {"prism_surge": 0},
		"damage_dealt": 0.0,
		"damage_taken": 0.0,
		"kills": {"moth": 0, "hollow": 0},
		"started_at": Time.get_unix_time_from_system(),
		"ended_at": 0
	}

static func reset(run: RunScene) -> void:
	run.run_summary = make_tracker()

static func note_encounter_started(run: RunScene, encounter: Dictionary) -> void:
	run.run_summary["encounters_started"].append(String(encounter.get("title", "Encounter")))

static func note_encounter_cleared(run: RunScene, encounter: Dictionary) -> void:
	run.run_summary["encounters_cleared"].append(String(encounter.get("title", "Encounter")))

static func note_upgrade(run: RunScene, reward: Dictionary) -> void:
	run.run_summary["upgrades"].append(String(reward.get("title", "Upgrade")))
	run.run_summary["upgrade_ids"].append(String(reward.get("id", "")))

static func note_beam_cast(run: RunScene) -> void:
	run.run_summary["beams_cast"] += 1

static func note_prism_placed(run: RunScene) -> void:
	run.run_summary["prisms_placed"] += 1

static func note_prism_redirect(run: RunScene) -> void:
	run.run_summary["prism_redirects"] += 1

static func note_skill_cast(run: RunScene, skill_id: String) -> void:
	var skill_casts: Dictionary = run.run_summary.get("skill_casts", {})
	skill_casts[skill_id] = int(skill_casts.get(skill_id, 0)) + 1
	run.run_summary["skill_casts"] = skill_casts

static func note_damage_dealt(run: RunScene, amount: float) -> void:
	run.run_summary["damage_dealt"] = float(run.run_summary.get("damage_dealt", 0.0)) + amount

static func note_damage_taken(run: RunScene, amount: float) -> void:
	run.run_summary["damage_taken"] = float(run.run_summary.get("damage_taken", 0.0)) + amount

static func note_kill(run: RunScene, enemy_type: String) -> void:
	var kills: Dictionary = run.run_summary.get("kills", {})
	kills[enemy_type] = int(kills.get(enemy_type, 0)) + 1
	run.run_summary["kills"] = kills

static func finish(run: RunScene) -> void:
	run.run_summary["ended_at"] = Time.get_unix_time_from_system()

static func build_report(run: RunScene, victory: bool) -> String:
	var started_titles: Array = run.run_summary.get("encounters_started", [])
	var cleared_titles: Array = run.run_summary.get("encounters_cleared", [])
	var upgrades: Array = run.run_summary.get("upgrades", [])
	var kills: Dictionary = run.run_summary.get("kills", {})
	var skill_casts: Dictionary = run.run_summary.get("skill_casts", {})
	var duration: int = max(int(run.run_summary.get("ended_at", Time.get_unix_time_from_system())) - int(run.run_summary.get("started_at", Time.get_unix_time_from_system())), 0)
	var outcome: String = "[b]Prism Trial cleared.[/b]" if victory else "[b]Run ended before the trial was cleared.[/b]"
	var encounter_line: String = "%d/%d encounters cleared" % [cleared_titles.size(), max(started_titles.size(), run.encounters.size())]
	var upgrade_line: String = "None" if upgrades.is_empty() else ", ".join(upgrades)
	var cleared_line: String = "None" if cleared_titles.is_empty() else " → ".join(cleared_titles)
	return "%s\n%s in %ds.\n\n[b]Route[/b]\n%s\n\n[b]Build[/b]\n%s\n\n[b]Combat[/b]\nBeams cast: %d\nPrisms placed: %d\nPrism redirects: %d\nPrism Surges: %d\nDamage dealt: %.0f\nDamage taken: %.0f\nKills: %d Moth, %d Hollow" % [
		outcome,
		encounter_line,
		duration,
		cleared_line,
		upgrade_line,
		int(run.run_summary.get("beams_cast", 0)),
		int(run.run_summary.get("prisms_placed", 0)),
		int(run.run_summary.get("prism_redirects", 0)),
		int(skill_casts.get("prism_surge", 0)),
		float(run.run_summary.get("damage_dealt", 0.0)),
		float(run.run_summary.get("damage_taken", 0.0)),
		int(kills.get("moth", 0)),
		int(kills.get("hollow", 0))
	]
