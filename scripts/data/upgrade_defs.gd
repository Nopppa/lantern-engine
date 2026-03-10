extends RefCounted
class_name UpgradeDefs

const POOL := [
	{"id": "extra_bounce", "title": "+1 Bounce", "desc": "Refraction Beam gains one extra wall bounce.", "delta_text": "+1 total bounce for bank shots and prism follow-through.", "apply": "beam_bounces", "value": 1, "tags": ["core"]},
	{"id": "beam_range", "title": "Longer Beam", "desc": "Refraction Beam range +160.", "delta_text": "+160 range so bounce + redirect lines stay alive longer.", "apply": "beam_range", "value": 160.0, "tags": ["core"]},
	{"id": "beam_damage", "title": "Focused Lens", "desc": "Refraction Beam damage +7.", "delta_text": "+7 damage for faster clears and safer Hollow punishes.", "apply": "beam_damage", "value": 7.0, "tags": ["core"]},
	{"id": "prism_overclock", "title": "Prism Overclock", "desc": "Redirected segments hit harder and the node lasts longer.", "delta_text": "+6 redirected damage, +3s Prism duration.", "apply": "prism_overclock", "tags": ["prism"]},
	{"id": "wide_refraction", "title": "Wide Refraction", "desc": "Prism node catches shots more reliably and bends them harder.", "delta_text": "+10 Prism radius, +8° redirect angle.", "apply": "wide_refraction", "tags": ["prism"]},
	{"id": "echo_lens", "title": "Echo Lens", "desc": "Prism redirects preserve momentum into one more bounce.", "delta_text": "+1 bounce after Prism redirect.", "apply": "echo_lens", "tags": ["prism"]},
	{"id": "surge_capacitors", "title": "Surge Capacitors", "desc": "Prism Surge hits a larger area, harder, and cycles back sooner.", "delta_text": "+8 Surge damage, +22 radius, -1.0s cooldown.", "apply": "surge_capacitors", "tags": ["prism"]}
]

static func get_pool(tags: Array = [], exclude_ids: Array = []) -> Array:
	var normalized_tags: Array[String] = []
	for tag in tags:
		normalized_tags.append(String(tag))
	var blocked := {}
	for entry in exclude_ids:
		blocked[String(entry)] = true
	var results: Array = []
	for reward: Dictionary in POOL:
		var reward_id := String(reward.get("id", ""))
		if blocked.has(reward_id):
			continue
		var reward_tags: Array = reward.get("tags", [])
		if normalized_tags.is_empty() or _matches_any_tag(reward_tags, normalized_tags):
			results.append(reward.duplicate(true))
	return results

static func _matches_any_tag(reward_tags: Array, requested_tags: Array[String]) -> bool:
	for tag in reward_tags:
		if requested_tags.has(String(tag)):
			return true
	return false
