extends RefCounted
class_name LightLabWorldAdapter

const LightWorld = preload("res://scripts/gameplay/light_world.gd")
const LightTypes = preload("res://scripts/gameplay/light_types.gd")
const LightMaterials = preload("res://scripts/data/light_materials.gd")

static func build(layout: Dictionary, arena_rect: Rect2, prism_node = null, prism_radius: float = 18.0) -> Dictionary:
	var surface_segments: Array = []
	var surface_patches: Array = []
	var prism_stations: Array = []
	var tree_trunks: Array = []
	var entities: Array = []
	for segment: Dictionary in layout.get("segments", []):
		surface_segments.append(segment.duplicate(true))
	for patch: Dictionary in layout.get("patches", []):
		var normalized_patch := patch.duplicate(true)
		var material_id := String(normalized_patch.get("material_id", "brick"))
		normalized_patch["material_spec"] = LightTypes.light_material_spec(material_id, LightMaterials.get_definition(material_id))
		surface_patches.append(normalized_patch)
	for prism_station: Dictionary in layout.get("prism_stations", []):
		var station := prism_station.duplicate(true)
		prism_stations.append(station)
		entities.append({
			"kind": "prism_station",
			"pos": station.get("pos", Vector2.ZERO),
			"radius": station.get("radius", 18.0),
			"material_id": "prism"
		})
	for trunk: Dictionary in layout.get("tree_trunks", []):
		var tree := trunk.duplicate(true)
		tree_trunks.append(tree)
		entities.append({
			"kind": "tree_trunk",
			"pos": tree.get("pos", Vector2.ZERO),
			"radius": tree.get("radius", 0.0),
			"material_id": "tree",
			"material_spec": LightTypes.light_material_spec("tree", {"label": "Tree Trunk"})
		})
	if prism_node != null and is_instance_valid(prism_node):
		entities.append({
			"kind": "prism_node",
			"pos": prism_node.position,
			"radius": prism_radius,
			"material_id": "prism"
		})
	var world := LightWorld.new(surface_segments, surface_patches, entities, {
		"world_type": "light_lab",
		"arena_rect": arena_rect,
		"ready_for_randomgen": true,
		"adapter": "light_lab_world_adapter"
	})
	return {
		"surface_segments": surface_segments,
		"surface_patches": surface_patches,
		"prism_stations": prism_stations,
		"tree_trunks": tree_trunks,
		"light_world": world
	}
