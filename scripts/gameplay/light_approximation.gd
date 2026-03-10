extends RefCounted
class_name LightApproximation

const TIER_PRECISE := "A"
const TIER_GUIDED := "B"
const TIER_SECONDARY := "C"

const SOURCE_TIERS := {
	"laser": TIER_PRECISE,
	"flashlight": TIER_GUIDED,
	"prism": TIER_SECONDARY
}

const TIER_CONFIG := {
	TIER_PRECISE: {
		"label": "Precise beam logic",
		"update_interval": 0.0,
		"sample_budget": 32,
		"guide_rays": 0,
		"envelope_smoothing": 0.0
	},
	TIER_GUIDED: {
		"label": "Guided approximation",
		"update_interval": 0.10,
		"sample_budget": 8,
		"guide_rays": 7,
		"envelope_smoothing": 0.44
	},
	TIER_SECONDARY: {
		"label": "Cheap secondary response",
		"update_interval": 0.16,
		"sample_budget": 5,
		"guide_rays": 0,
		"envelope_smoothing": 0.28
	}
}

static func tier_for_source(source_type: String) -> String:
	return String(SOURCE_TIERS.get(source_type, TIER_SECONDARY))

static func config_for_source(source_type: String) -> Dictionary:
	var tier := tier_for_source(source_type)
	return Dictionary(TIER_CONFIG.get(tier, TIER_CONFIG[TIER_SECONDARY])).duplicate(true)

static func config_for_tier(tier: String) -> Dictionary:
	return Dictionary(TIER_CONFIG.get(tier, TIER_CONFIG[TIER_SECONDARY])).duplicate(true)

static func should_refresh(timer: float, source_type: String) -> bool:
	var interval := float(config_for_source(source_type).get("update_interval", 0.0))
	return interval <= 0.0 or timer >= interval
