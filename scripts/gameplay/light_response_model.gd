extends RefCounted
class_name LightResponseModel

const LightApproximation = preload("res://scripts/gameplay/light_approximation.gd")
const LightMaterials = preload("res://scripts/data/light_materials.gd")
const LightTypes = preload("res://scripts/gameplay/light_types.gd")

const SOURCE_PROFILES := {
	"laser": {
		"label": "Laser",
		"reflect_scale": 1.0,
		"diffuse_scale": 0.9,
		"transmission_scale": 1.0,
		"range_scale": 1.0,
		"min_branch_intensity": 0.08,
		"diffuse_radius": 56.0,
		"roughness_scale": 0.45,
		"tier": LightApproximation.TIER_PRECISE
	},
	"flashlight": {
		"label": "Flashlight",
		"reflect_scale": 0.40,
		"diffuse_scale": 1.10,
		"transmission_scale": 0.58,
		"range_scale": 0.42,
		"min_branch_intensity": 0.06,
		"diffuse_radius": 72.0,
		"roughness_scale": 1.0,
		"tier": LightApproximation.TIER_GUIDED
	},
	"prism": {
		"label": "Prism Light",
		"reflect_scale": 0.52,
		"diffuse_scale": 0.90,
		"transmission_scale": 0.74,
		"range_scale": 0.50,
		"min_branch_intensity": 0.06,
		"diffuse_radius": 66.0,
		"roughness_scale": 0.82,
		"tier": LightApproximation.TIER_SECONDARY
	}
}

static func source_profile(source_type: String) -> Dictionary:
	return Dictionary(SOURCE_PROFILES.get(source_type, SOURCE_PROFILES["laser"])).duplicate(true)

static func response(material_id: String, source_type: String, intensity: float, incoming_dir: Vector2, normal: Vector2) -> Dictionary:
	var material: Dictionary = LightMaterials.get_definition(material_id)
	var material_spec := LightTypes.light_material_spec(material_id, material)
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
	# Transmission direction: use Snell's law vector form when material has IOR, else straight-through.
	# n1 * sin(theta_i) = n2 * sin(theta_t), entering from air (n1=1.0) into material (n2=ior).
	var transmit_dir := incoming
	var ior: float = clampf(float(material.get("ior", 1.0)), 1.0, 2.8)
	if ior > 1.01:
		var n := normal.normalized()
		# Orient normal to face the incoming ray (inward normal)
		var dot_in := incoming.dot(n)
		if dot_in > 0.0:
			n = -n
			dot_in = -dot_in
		var n_ratio: float = 1.0 / ior  # n_air / n_material (entering glass)
		var cos_i: float = -dot_in      # cos of angle of incidence (positive)
		var sin2_t: float = n_ratio * n_ratio * (1.0 - cos_i * cos_i)
		if sin2_t < 1.0:  # no total internal reflection
			var cos_t: float = sqrt(1.0 - sin2_t)
			var refracted := (n_ratio * incoming + (n_ratio * cos_i - cos_t) * n).normalized()
			if refracted != Vector2.ZERO:
				transmit_dir = refracted
	var roughness: float = clampf(float(material.get("roughness", diffusion)) * float(profile.get("roughness_scale", 1.0)), 0.0, 1.0)
	return {
		"material_id": material_id,
		"material": material,
		"material_spec": material_spec,
		"source_type": source_type,
		"source_tier": String(profile.get("tier", LightApproximation.TIER_SECONDARY)),
		"intensity": intensity,
		"reflectivity": reflectivity,
		"diffusion": diffusion,
		"transmission": transmission,
		"absorption": absorption,
		"reflect_dir": reflect_dir,
		"transmit_dir": transmit_dir,
		"branch_min": float(profile.get("min_branch_intensity", 0.05)),
		"branch_range_scale": float(profile.get("range_scale", 1.0)),
		"diffuse_radius": float(profile.get("diffuse_radius", 56.0)) * (0.68 + diffusion * 0.76),
		"roughness": roughness,
		"restoration_affinity": float(material.get("restoration_affinity", 1.0))
	}
