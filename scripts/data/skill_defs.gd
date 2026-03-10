extends RefCounted
class_name SkillDefs

const PRISM_SURGE := {
	"id": "prism_surge",
	"title": "Prism Surge",
	"control": "Q",
	"summary": "Collapse the active Prism Node into a radial burst that damages, shoves, sears enemies with Light Burn, and jams enemy special abilities briefly.",
	"cooldown": 6.0,
	"damage": 20.0,
	"radius": 118.0,
	"push_distance": 96.0,
	"energy_refund_on_hit": 8.0,
	"special_lock_duration": 2.2,
	"light_burn_duration": 4.0,
	"light_burn_tick": 0.5,
	"light_burn_damage": 1.5
}

static func get_skill(id: String) -> Dictionary:
	match id:
		"prism_surge":
			return PRISM_SURGE.duplicate(true)
		_:
			return {}
