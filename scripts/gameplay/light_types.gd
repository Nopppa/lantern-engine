extends RefCounted
class_name LightTypes

static func light_source_spec(source_type: String, origin: Vector2, direction: Vector2 = Vector2.RIGHT, intensity: float = 1.0, max_range: float = 0.0, extra: Dictionary = {}) -> Dictionary:
	var spec := {
		"source_type": source_type,
		"origin": origin,
		"direction": direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT,
		"intensity": intensity,
		"range": max_range
	}
	for key in extra.keys():
		spec[key] = extra[key]
	return spec

static func light_material_spec(material_id: String, material: Dictionary) -> Dictionary:
	return {
		"material_id": material_id,
		"label": String(material.get("label", material_id)),
		"reflectivity": float(material.get("reflectivity", 0.0)),
		"diffusion": float(material.get("diffusion", 0.0)),
		"transmission": float(material.get("transmission", 0.0)),
		"absorption": float(material.get("absorption", 0.0)),
		"roughness": float(material.get("roughness", 0.0)),
		"restoration_affinity": float(material.get("restoration_affinity", 1.0)),
		"refraction_strength": float(material.get("refraction_strength", 0.0)),
		"color": material.get("color", Color.WHITE),
		"alive_color": material.get("alive_color", Color.WHITE)
	}

static func light_render_packet(packet_type: String, source_spec: Dictionary, segments: Array = [], frontier: Array = [], fills: Array = [], zones: Array = [], extra: Dictionary = {}) -> Dictionary:
	var packet := {
		"packet_type": packet_type,
		"source": source_spec.duplicate(true),
		"segments": segments.duplicate(true),
		"frontier": frontier.duplicate(true),
		"fills": fills.duplicate(true),
		"zones": zones.duplicate(true)
	}
	for key in extra.keys():
		packet[key] = extra[key]
	return packet

static func empty_render_packet(packet_type: String = "none") -> Dictionary:
	return light_render_packet(packet_type, light_source_spec("none", Vector2.ZERO), [], [], [], [], {"active": false})

static func render_segment(a: Vector2, b: Vector2, intensity: float = 1.0, extra: Dictionary = {}) -> Dictionary:
	var segment := {
		"a": a,
		"b": b,
		"intensity": intensity
	}
	for key in extra.keys():
		segment[key] = extra[key]
	return segment

static func render_fill(points: PackedVector2Array, strength: float = 1.0, extra: Dictionary = {}) -> Dictionary:
	var fill := {
		"points": points,
		"strength": strength
	}
	for key in extra.keys():
		fill[key] = extra[key]
	return fill

static func render_zone(pos: Vector2, radius: float, strength: float = 1.0, extra: Dictionary = {}) -> Dictionary:
	var zone := {
		"pos": pos,
		"radius": radius,
		"strength": strength
	}
	for key in extra.keys():
		zone[key] = extra[key]
	return zone
