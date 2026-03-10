extends RefCounted
class_name LightMaterials

const DEFINITIONS := {
	"brick": {
		"label": "Brick",
		"reflectivity": 0.05,
		"diffusion": 0.20,
		"transmission": 0.0,
		"absorption": 0.75,
		"restoration_affinity": 0.55,
		"color": Color(0.47, 0.28, 0.24, 1.0),
		"alive_color": Color(0.72, 0.46, 0.40, 1.0)
	},
	"wood": {
		"label": "Wood",
		"reflectivity": 0.10,
		"diffusion": 0.35,
		"transmission": 0.0,
		"absorption": 0.55,
		"restoration_affinity": 0.72,
		"color": Color(0.42, 0.30, 0.18, 1.0),
		"alive_color": Color(0.64, 0.49, 0.29, 1.0)
	},
	"wet": {
		"label": "Wet Stone",
		"reflectivity": 0.45,
		"diffusion": 0.20,
		"transmission": 0.0,
		"absorption": 0.35,
		"restoration_affinity": 0.85,
		"color": Color(0.22, 0.32, 0.38, 1.0),
		"alive_color": Color(0.36, 0.58, 0.62, 1.0)
	},
	"mirror": {
		"label": "Mirror",
		"reflectivity": 0.95,
		"diffusion": 0.0,
		"transmission": 0.0,
		"absorption": 0.05,
		"restoration_affinity": 0.9,
		"color": Color(0.70, 0.80, 0.90, 1.0),
		"alive_color": Color(0.92, 0.98, 1.0, 1.0)
	},
	"glass": {
		"label": "Glass",
		"reflectivity": 0.15,
		"diffusion": 0.05,
		"transmission": 0.70,
		"absorption": 0.10,
		"restoration_affinity": 0.88,
		"color": Color(0.44, 0.68, 0.78, 0.95),
		"alive_color": Color(0.68, 0.90, 0.98, 0.95)
	},
	"prism": {
		"label": "Prism",
		"reflectivity": 0.0,
		"diffusion": 0.0,
		"transmission": 1.0,
		"absorption": 0.0,
		"restoration_affinity": 1.0,
		"color": Color(0.56, 0.92, 1.0, 1.0),
		"alive_color": Color(0.88, 1.0, 1.0, 1.0)
	}
}

static func get_definition(id: String) -> Dictionary:
	return Dictionary(DEFINITIONS.get(id, DEFINITIONS["brick"])).duplicate(true)
