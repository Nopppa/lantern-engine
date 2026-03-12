extends RefCounted
class_name LightMaterials

const DEFINITIONS := {
	"brick": {
		"label": "Brick",
		"reflectivity": 0.05,
		"diffusion": 0.20,
		"transmission": 0.0,
		"absorption": 0.75,
		"roughness": 0.82,
		"restoration_affinity": 0.55,
		"color": Color(0.47, 0.28, 0.24, 1.0),
		"alive_color": Color(0.72, 0.46, 0.40, 1.0)
	},
	"wood": {
		"label": "Wood",
		"reflectivity": 0.12,
		"diffusion": 0.42,
		"transmission": 0.0,
		"absorption": 0.46,
		"roughness": 0.82,
		"restoration_affinity": 0.78,
		"color": Color(0.42, 0.30, 0.18, 1.0),
		"alive_color": Color(0.64, 0.49, 0.29, 1.0)
	},
	"wet": {
		"label": "Wet Surface",
		"reflectivity": 0.50,
		"diffusion": 0.24,
		"transmission": 0.0,
		"absorption": 0.26,
		"roughness": 0.46,
		"restoration_affinity": 0.90,
		"color": Color(0.22, 0.32, 0.38, 1.0),
		"alive_color": Color(0.36, 0.58, 0.62, 1.0),
		"water_depth": 0.65,
		"move_speed_multiplier": 0.70
	},
	"mirror": {
		"label": "Mirror",
		"reflectivity": 0.95,
		"diffusion": 0.0,
		"transmission": 0.0,
		"absorption": 0.05,
		"roughness": 0.02,
		"restoration_affinity": 0.9,
		"color": Color(0.70, 0.80, 0.90, 1.0),
		"alive_color": Color(0.92, 0.98, 1.0, 1.0)
	},
	"glass": {
		"label": "Glass",
		"reflectivity": 0.14,
		"diffusion": 0.05,
		"transmission": 0.73,
		"absorption": 0.08,
		"roughness": 0.10,
		"restoration_affinity": 0.90,
		"refraction_strength": 0.10,  # legacy, kept for compat
		"ior": 1.52,                   # index of refraction (standard borosilicate glass)
		"thickness_hint": 0.0,         # optional future use: slab thickness in world units (0 = thin surface)
		"color": Color(0.44, 0.68, 0.78, 0.95),
		"alive_color": Color(0.68, 0.90, 0.98, 0.95)
	},
	"prism": {
		"label": "Prism",
		"reflectivity": 0.0,
		"diffusion": 0.0,
		"transmission": 1.0,
		"absorption": 0.0,
		"roughness": 0.0,
		"restoration_affinity": 1.0,
		"color": Color(0.56, 0.92, 1.0, 1.0),
		"alive_color": Color(0.88, 1.0, 1.0, 1.0)
	},
	"tree": {
		"label": "Tree Trunk",
		"reflectivity": 0.02,
		"diffusion": 0.18,
		"transmission": 0.0,
		"absorption": 0.80,
		"roughness": 0.88,
		"restoration_affinity": 0.48,
		"color": Color(0.34, 0.22, 0.14, 1.0),
		"alive_color": Color(0.42, 0.30, 0.18, 1.0)
	}
}

static func water_speed_multiplier(material: Dictionary) -> float:
	return clampf(float(material.get("move_speed_multiplier", 1.0)), 0.55, 1.0)

static func water_depth(material: Dictionary) -> float:
	return clampf(float(material.get("water_depth", 0.0)), 0.0, 1.0)

static func get_definition(id: String) -> Dictionary:
	return Dictionary(DEFINITIONS.get(id, DEFINITIONS["brick"])).duplicate(true)
