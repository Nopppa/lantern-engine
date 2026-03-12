extends RefCounted
class_name ExplorationLightRuntime

const LightTypes = preload("res://scripts/gameplay/light_types.gd")
const LightField = preload("res://scripts/gameplay/light_field.gd")
const DeadAliveGrid = preload("res://scripts/gameplay/dead_alive_grid.gd")
const FlashlightVisuals = preload("res://scripts/gameplay/flashlight_visuals.gd")

const DEFAULT_FLASHLIGHT_RANGE := 420.0
const DEFAULT_FLASHLIGHT_HALF_ANGLE := 48.0
const DEFAULT_BEAM_OFFSET := 4.0

var arena_rect: Rect2 = Rect2()
var light_cell_size := 32.0
var flashlight_range := DEFAULT_FLASHLIGHT_RANGE
var flashlight_half_angle := DEFAULT_FLASHLIGHT_HALF_ANGLE
var BEAM_OFFSET := DEFAULT_BEAM_OFFSET

var light_world: LightWorld = null
var player_pos: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.RIGHT
var flashlight_on := true

var gameplay_light_field: LightField = null
var dead_alive_cells: Array = []
var flashlight_render_packet: Dictionary = LightTypes.empty_render_packet("flashlight")
var prism_render_packet: Dictionary = LightTypes.empty_render_packet("prism")
var approx_flashlight_frontier := {}
var approx_prism_frontiers := {}

func configure(config: Dictionary) -> void:
	arena_rect = Rect2(config.get("arena_rect", Rect2()))
	light_cell_size = float(config.get("light_cell_size", light_cell_size))
	flashlight_range = float(config.get("flashlight_range", flashlight_range))
	flashlight_half_angle = float(config.get("flashlight_half_angle", flashlight_half_angle))
	BEAM_OFFSET = float(config.get("beam_offset", BEAM_OFFSET))

func reset(world: LightWorld) -> void:
	light_world = world
	gameplay_light_field = LightField.new(arena_rect, light_cell_size, 1.25)
	dead_alive_cells = DeadAliveGrid.build(arena_rect, light_cell_size, light_world.metadata_array("dead_alive_zones") if light_world != null else [])
	flashlight_render_packet = LightTypes.empty_render_packet("flashlight")
	prism_render_packet = LightTypes.empty_render_packet("prism")
	approx_flashlight_frontier = {}
	approx_prism_frontiers = {}

func sync_player_runtime(pos: Vector2, dir: Vector2, flashlight_enabled: bool) -> void:
	player_pos = pos
	facing = dir
	flashlight_on = flashlight_enabled

func process_frame(delta: float) -> void:
	rebuild_gameplay_light_field()
	if gameplay_light_field != null:
		gameplay_light_field.process_field(delta)
	DeadAliveGrid.update(dead_alive_cells, delta, Callable(self, "sample_gameplay_light"))

func rebuild_gameplay_light_field() -> void:
	if gameplay_light_field == null:
		return
	gameplay_light_field.clear_dynamic_light()
	if not flashlight_on:
		flashlight_render_packet = LightTypes.empty_render_packet("flashlight")
		prism_render_packet = _build_exploration_prism_packet()
		approx_flashlight_frontier = {}
		_write_packet_to_light_field(prism_render_packet, 34.0, 28.0, 0.92, 0.72)
		return
	flashlight_render_packet = FlashlightVisuals.build_render_packet(self, _flashlight_source_options())
	approx_flashlight_frontier = flashlight_render_packet.get("frontier", {})
	prism_render_packet = _build_exploration_prism_packet()
	_write_packet_to_light_field(flashlight_render_packet, 30.0, 24.0, 0.86, 0.62)
	_write_packet_to_light_field(prism_render_packet, 34.0, 28.0, 0.92, 0.72)

func update_native_presentation(native_light_presentation: Node) -> void:
	if native_light_presentation == null:
		return
	native_light_presentation.update_from_packets(
		flashlight_render_packet,
		LightTypes.empty_render_packet("laser"),
		prism_render_packet,
		light_world.prism_emitters() if light_world != null else [],
		null,
		flashlight_on,
		player_pos,
		facing,
		light_world,
		[]
	)

func sample_gameplay_light(pos: Vector2) -> float:
	if gameplay_light_field == null:
		return 0.0
	return clampf(gameplay_light_field.sample_world(pos), 0.0, 1.0)

func dead_alive_cell_count() -> int:
	return dead_alive_cells.size()

func active_prism_emitter_count() -> int:
	var strengths := Dictionary(prism_render_packet.get("emitter_strengths", {}))
	var count := 0
	for key in strengths.keys():
		if float(strengths[key]) >= 0.95:
			count += 1
	return count

func _flashlight_source_options() -> Dictionary:
	return {
		"source_type": "flashlight",
		"origin": player_pos,
		"direction": facing,
		"range": flashlight_range,
		"half_angle_deg": flashlight_half_angle,
		"center_intensity": 0.96,
		"edge_intensity": 0.42,
		"use_frontier_smoothing": true,
		"previous_frontier": approx_flashlight_frontier,
		"source_anchor": player_pos,
		"radial_emission": false
	}

func _packet_segments(packet: Dictionary) -> Array:
	return packet.get("segments", [])

func _packet_zones(packet: Dictionary) -> Array:
	return packet.get("zones", [])

func _packet_fills(packet: Dictionary) -> Array:
	return packet.get("fills", [])

func _zone_is_opaque_surface(zone: Dictionary) -> bool:
	var material_id := String(zone.get("material_id", ""))
	return material_id == "brick" or material_id == "wood" or material_id == "mirror" or material_id == "tree" or material_id == "stone" or material_id == "metal"

func _zone_front_facing(zone: Dictionary) -> bool:
	var normal: Vector2 = Vector2(zone.get("normal", Vector2.ZERO))
	var incoming_dir: Vector2 = Vector2(zone.get("incoming_dir", Vector2.ZERO))
	if normal == Vector2.ZERO or incoming_dir == Vector2.ZERO:
		return true
	return incoming_dir.normalized().dot(normal.normalized()) < -0.05

func _zone_effective_pos(zone: Dictionary, offset_scale: float) -> Vector2:
	var pos: Vector2 = Vector2(zone.get("pos", Vector2.ZERO))
	var normal: Vector2 = Vector2(zone.get("normal", Vector2.ZERO))
	if normal == Vector2.ZERO or not _zone_is_opaque_surface(zone):
		return pos
	return pos + normal.normalized() * float(zone.get("radius", 0.0)) * offset_scale

func _write_packet_to_light_field(packet: Dictionary, primary_radius: float, secondary_radius: float, primary_scale: float, secondary_scale: float) -> void:
	if gameplay_light_field == null:
		return
	for segment: Dictionary in _packet_segments(packet):
		var kind := String(segment.get("kind", "primary"))
		var is_continuation := (kind == "reflect" or kind == "transmit")
		var radius: float = primary_radius if (kind == "primary" or is_continuation) else secondary_radius
		var scale: float = (primary_scale * 0.88) if is_continuation else (primary_scale if kind == "primary" else secondary_scale)
		var a: Vector2 = segment["a"]
		var b: Vector2 = segment["b"]
		var length: float = a.distance_to(b)
		var mat_id := String(segment.get("material_id", ""))
		var is_end_solid: bool = (mat_id == "brick" or mat_id == "wood" or mat_id == "mirror" or mat_id == "tree" or mat_id == "stone" or mat_id == "metal")
		var steps: int = max(1, int(ceil(length / max(gameplay_light_field.cell_size * 0.75, 8.0))))
		for step in range(steps + 1):
			var t: float = float(step) / float(steps)
			var pos: Vector2 = a.lerp(b, t)
			var energy: float = clampf(float(segment.get("intensity", 0.0)) * scale, 0.0, 1.0)
			var eff_radius := radius
			if is_end_solid:
				var dist_to_b := pos.distance_to(b)
				if dist_to_b < radius:
					eff_radius = max(dist_to_b, 4.0)
			gameplay_light_field.add_splat_world(pos, eff_radius, energy)
		if kind == "primary" and mat_id == "mirror":
			var hit_energy := clampf(float(segment.get("intensity", 0.0)) * primary_scale, 0.0, 1.0)
			gameplay_light_field.add_splat_world(b, primary_radius * 1.2, hit_energy * 0.9)
		elif kind == "primary" and (mat_id == "glass" or mat_id == "wet"):
			var pass_energy := clampf(float(segment.get("intensity", 0.0)) * primary_scale, 0.0, 1.0)
			gameplay_light_field.add_splat_world(b, primary_radius * 0.9, pass_energy * 0.65)
	for zone: Dictionary in _packet_zones(packet):
		if _zone_is_opaque_surface(zone) and not _zone_front_facing(zone):
			continue
		var is_opaque := _zone_is_opaque_surface(zone)
		var zone_pos: Vector2 = _zone_effective_pos(zone, 0.85 if is_opaque else 0.24)
		var zone_radius: float = float(zone.get("radius", 0.0))
		if is_opaque:
			zone_radius *= 0.78
			if String(zone.get("kind", "")) == "block":
				zone_radius *= 0.72
		gameplay_light_field.add_splat_world(zone_pos, zone_radius, float(zone.get("strength", 0.0)))
	for fill: Dictionary in _packet_fills(packet):
		var pts: PackedVector2Array = fill.get("points", PackedVector2Array())
		if pts.size() < 3:
			continue
		var centroid := Vector2.ZERO
		for p: Vector2 in pts:
			centroid += p
		centroid /= float(pts.size())
		var fill_strength: float = clampf(float(fill.get("strength", 0.0)) * 0.38, 0.0, 1.0)
		if fill_strength > 0.01:
			gameplay_light_field.add_splat_world(centroid, primary_radius * 1.15, fill_strength)

func _prism_source_spec(origin: Vector2, direction: Vector2 = Vector2.RIGHT) -> Dictionary:
	return LightTypes.light_source_spec("prism", origin, direction, 1.0, 118.0, {
		"guide_rays": 16,
		"radial_emission": false
	})

func _light_world_prism_entities() -> Array:
	return light_world.prism_emitters() if light_world != null else []

func _prism_emitter_energized(pos: Vector2, radius: float) -> bool:
	for segment: Dictionary in _packet_segments(flashlight_render_packet):
		var a: Vector2 = Vector2(segment.get("a", Vector2.ZERO))
		var b: Vector2 = Vector2(segment.get("b", Vector2.ZERO))
		var intensity := float(segment.get("intensity", 0.0))
		if intensity <= 0.08:
			continue
		var closest := _closest_point_on_segment(pos, a, b)
		if closest.distance_to(pos) <= maxf(radius, 26.0):
			return true
	return false

func _build_combined_prism_packet(segments: Array, zones: Array, fills: Array, emitter_keys: Array = [], emitter_strengths: Dictionary = {}) -> Dictionary:
	var prism_entities := _light_world_prism_entities()
	var origin := Vector2(prism_entities[0].get("pos", Vector2.ZERO)) if not prism_entities.is_empty() else Vector2.ZERO
	return LightTypes.light_render_packet("prism", _prism_source_spec(origin), segments, [], fills, zones, {
		"emitter_count": prism_entities.size(),
		"emitter_keys": emitter_keys.duplicate(),
		"emitter_strengths": emitter_strengths.duplicate(true),
		"active": not emitter_keys.is_empty() or not segments.is_empty() or not zones.is_empty()
	})

func _build_exploration_prism_packet() -> Dictionary:
	var accum_segments: Array = []
	var accum_zones: Array = []
	var accum_fills: Array = []
	var active_prism_keys: Array = []
	var prism_strengths: Dictionary = {}
	for prism_entity: Dictionary in _light_world_prism_entities():
		if String(prism_entity.get("kind", "")) != "prism_station":
			continue
		var pos := Vector2(prism_entity.get("pos", Vector2.ZERO))
		var radius := float(prism_entity.get("radius", 18.0))
		var station_key := "station_%d_%d" % [int(pos.x), int(pos.y)]
		accum_zones.append(LightTypes.render_zone(pos, maxf(26.0, radius * 1.8), 0.14, {
			"kind": "emitter_ambient",
			"source_type": "prism",
			"emitter_key": station_key
		}))
		active_prism_keys.append(station_key)
		if not _prism_emitter_energized(pos, radius + 8.0):
			prism_strengths[station_key] = 0.32
			continue
		var station_out_dir := (pos - player_pos).normalized()
		if station_out_dir == Vector2.ZERO:
			station_out_dir = Vector2.RIGHT
		var station_packet := FlashlightVisuals.build_render_packet(self, {
			"source_type": "prism",
			"origin": pos,
			"direction": station_out_dir,
			"range": 104.0,
			"half_angle_deg": 110.0,
			"guide_rays": 16,
			"center_intensity": 0.72,
			"edge_intensity": 0.34,
			"use_frontier_smoothing": true,
			"previous_frontier": approx_prism_frontiers.get(station_key, {}),
			"source_anchor": pos,
			"radial_emission": false
		})
		accum_segments.append_array(station_packet.get("segments", []))
		accum_zones.append_array(station_packet.get("zones", []))
		accum_fills.append_array(station_packet.get("fills", []))
		approx_prism_frontiers[station_key] = station_packet.get("frontier", {})
		accum_zones.append(LightTypes.render_zone(pos, maxf(24.0, radius * 1.35), 0.44, {
			"kind": "emitter_core",
			"source_type": "prism",
			"emitter_key": station_key
		}))
		prism_strengths[station_key] = 1.0
	return _build_combined_prism_packet(accum_segments, accum_zones, accum_fills, active_prism_keys, prism_strengths)

func _closest_point_on_segment(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var denom := maxf(ab.length_squared(), 0.0001)
	var t := clampf((point - a).dot(ab) / denom, 0.0, 1.0)
	return a + ab * t

func _light_world_patches() -> Array:
	return light_world.material_patches if light_world != null else []

func _light_world_occluders() -> Array:
	return light_world.occluder_segments if light_world != null else []

func _light_world_tree_entities() -> Array:
	return light_world.entity_list("tree_trunk") if light_world != null else []
