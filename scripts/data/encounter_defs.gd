extends RefCounted
class_name EncounterDefs

const RUN := {
	"id": "mvp1_patch1",
	"title": "Prism Trial",
	"encounters": [
		{
			"id": "opening_sweep",
			"title": "Opening Sweep",
			"summary": "Two moths establish the first safe bank-shot rhythm.",
			"reward_tags": ["core", "prism"],
			"spawns": [
				{"type": "moth", "pos": Vector2(920, 210)},
				{"type": "moth", "pos": Vector2(995, 505)}
			]
		},
		{
			"id": "crossing_pressure",
			"title": "Crossing Pressure",
			"summary": "Moths squeeze lanes while one Hollow tests flashlight disruption.",
			"reward_tags": ["core", "prism"],
			"spawns": [
				{"type": "moth", "pos": Vector2(980, 185)},
				{"type": "hollow", "pos": Vector2(1035, 360)},
				{"type": "moth", "pos": Vector2(980, 535)}
			]
		},
		{
			"id": "split_angles",
			"title": "Split Angles",
			"summary": "Two Hollows break timing while one Moth punishes static aiming.",
			"reward_tags": ["core", "prism", "prism"],
			"spawns": [
				{"type": "hollow", "pos": Vector2(1000, 180)},
				{"type": "moth", "pos": Vector2(930, 360)},
				{"type": "hollow", "pos": Vector2(1000, 540)}
			]
		},
		{
			"id": "lens_lock",
			"title": "Lens Lock",
			"summary": "Mixed pressure asks for deliberate Prism placement and bounce continuation.",
			"reward_tags": ["core", "prism", "prism"],
			"spawns": [
				{"type": "moth", "pos": Vector2(965, 160)},
				{"type": "hollow", "pos": Vector2(1060, 290)},
				{"type": "moth", "pos": Vector2(1040, 430)},
				{"type": "hollow", "pos": Vector2(945, 575)}
			]
		},
		{
			"id": "final_convergence",
			"title": "Final Convergence",
			"summary": "Full mixed pressure closes the run without stepping into miniboss scope.",
			"reward_tags": ["core", "prism", "prism"],
			"spawns": [
				{"type": "hollow", "pos": Vector2(965, 155)},
				{"type": "moth", "pos": Vector2(1080, 245)},
				{"type": "hollow", "pos": Vector2(1040, 360)},
				{"type": "moth", "pos": Vector2(1080, 470)},
				{"type": "hollow", "pos": Vector2(965, 570)}
			]
		}
	]
}

const LIST := RUN["encounters"]

static func count() -> int:
	return LIST.size()

static func get_encounter(index: int) -> Dictionary:
	if LIST.is_empty():
		return {}
	return LIST[clampi(index, 0, LIST.size() - 1)].duplicate(true)

static func get_reward_tags(index: int) -> Array:
	var encounter := get_encounter(index)
	return encounter.get("reward_tags", ["core", "prism"])
