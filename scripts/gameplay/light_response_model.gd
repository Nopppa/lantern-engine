extends RefCounted
class_name LightResponseModel

const LightMaterials = preload("res://scripts/data/light_materials.gd")

const SOURCE_PROFILES := {
	"laser": {
		"label": "Laser",
		"reflect_scale": 1.0,
		"diffuse_scale": 0.9,
		"transmission_scale": 1.0,
		"range_scale": 1.0,
		"min_branch_intensity": 0.08,
		"diffuse_radius": 56.0,
		"roughness_scale": 0.45
	},
	"flashlight": {
		"label": "Flashlight",
		"reflect_scale": 0.42,
		"diffuse_scale": 1.18,
		"transmission_scale": 0.62,
		"range_scale": 0.46,
		"min_branch_intensity": 0.05,
		"diffuse_radius": 68.0,
		"roughness_scale": 1.0
	},
	"prism": {
		"label": "Prism Light",
		"reflect_scale": 0.62,
		"diffuse_scale": 0.95,
		"transmission_scale": 0.82,
		"range_scale": 0.58,
		"min_branch_intensity": 0.05,
		"diffuse_radius": 62.0,
		"roughness_scale": 0.8
	}
}

static func source_profile(source_type: String) -> Dictionary:
	return Dictionary(SOURCE_PROFILES.get(source_type, SOURCE_PROFILES["laser"]))

static func response(material_id: String, source_type: String, intensity: float, incoming_dir: Vector2, normal: Vector2) -> Dictionary:
	var material: Dictionary = LightMaterials.get_definition(material_id)
	var profile: Dictionary = source_profile(source_type)
	var reflectivity: float = clampf(float(material.get("reflectivity", 0.0)) * float(profile.get("reflect_scale", 1.0)), 0.0, 1.0)
	var diffusion: float = clampf(float(material.get("diffusion", 0.0)) * float(profile.get("diffuse_scale", 1.0)), 0.0, 1.0)
	var transmission: float = clampf(float(material.get("transmission", 0.0)) * float(profile.get("transmission_scale", 1.0)), 0.0, 1.0)
	var absorption: float = clampf(float(material.get("absorption", 0.0)), 0.0, 1.0)
	var total: float = max(reflectivity + diffusion + transmission + absorption, 0.001)
	reflectivity /= total
	diffusion /= total
	transmission /= total
	absorption /= total
	var incoming := incoming_dir.normalized()
	var reflect_dir: Vector2 = incoming.bounce(normal).normalized()
	if reflect_dir == Vector2.ZERO:
		reflect_dir = incoming
	var refraction_strength: float = clampf(float(material.get("refraction_strength", 0.0)), 0.0, 0.35)
	var transmit_dir := incoming
	if refraction_strength > 0.0:
		transmit_dir = incoming.lerp(incoming.slide(normal).normalized(), refraction_strength).normalized()
		if transmit_dir == Vector2.ZERO:
			transmit_dir = incoming
	var roughness: float = clampf(float(material.get("roughness", diffusion)) * float(profile.get("roughness_scale", 1.0)), 0.0, 1.0)
	return {
		"material_id": material_id,
		"material": material,
		"source_type": source_type,
		"intensity": intensity,
		"reflectivity": reflectivity,
		"diffusion": diffusion,
		"transmission": transmission,
		"absorption": absorption,
		"reflect_dir": reflect_dir,
		"transmit_dir": transmit_dir,
		"branch_min": float(profile.get("min_branch_intensity", 0.05)),
		"branch_range_scale": float(profile.get("range_scale", 1.0)),
		"diffuse_radius": float(profile.get("diffuse_radius", 56.0)) * (0.7 + diffusion * 0.7),
		"roughness": roughness,
		"restoration_affinity": float(material.get("restoration_affinity", 1.0))
	}
