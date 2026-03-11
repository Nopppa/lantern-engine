extends Node2D
class_name NativeLightPresentation
## Phase 4 — Native Godot native-light decoration + decorative occluder shadows.
##
## This node manages CanvasModulate, PointLight2D, and LightOccluder2D nodes
## that sit above the packet-first lighting pipeline purely for atmosphere /
## presentation.
##
## Design constraints:
##   - Consumes render-packet data + world helper data; never writes gameplay truth.
##   - Native lights / occluders are decorative only — they do not feed back into
##     LightWorld, _light_intensity_at(), or any solver.
##   - Occluders are derived from existing world/occluder truth, not scene-local
##     replacement state.

# ---------------------------------------------------------------------------
# Tunables  (all presentation-only)
# ---------------------------------------------------------------------------

const AMBIENT_COLOR := Color(0.24, 0.25, 0.28, 1.0)

const NATIVE_LIGHT_ITEM_MASK := 1
const NATIVE_SHADOW_MASK := 2

const FLASH_ENERGY := 0.80
const FLASH_COLOR := Color(1.0, 0.95, 0.78, 1.0)
const FLASH_TEXTURE_SIZE := 512

const BEAM_GLOW_ENERGY := 0.55
const BEAM_GLOW_COLOR := Color(0.52, 0.94, 1.0, 1.0)
const BEAM_GLOW_TEXTURE_SIZE := 128
const BEAM_GLOW_POOL_SIZE := 10

const PRISM_ENERGY := 0.34
const PRISM_COLOR := Color(0.54, 0.93, 1.0, 1.0)
const PRISM_TEXTURE_SIZE := 256

const PRISM_NODE_ENERGY := 0.40
const PRISM_NODE_COLOR := Color(0.58, 0.96, 1.0, 1.0)

const OCCLUDER_SEGMENT_THICKNESS := 10.0
const OCCLUDER_MIN_LENGTH := 6.0
const TREE_OCCLUDER_POINTS := 14
const TREE_OCCLUDER_PADDING := 2.0

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

var canvas_modulate: CanvasModulate
var flashlight_light: PointLight2D
var beam_glow_pool: Array[PointLight2D] = []
var prism_station_lights: Dictionary = {}
var prism_node_light: PointLight2D
var _texture_cache: Dictionary = {}

var occluder_root: Node2D
var occluder_nodes: Dictionary = {}
var _occluder_signature := ""

var enabled := true:
	set(value):
		enabled = value
		_apply_visibility()

var shadows_enabled := true:
	set(value):
		shadows_enabled = value
		_apply_shadow_state()

func debug_state_summary() -> String:
	return "layer %s | flashlight shadows %s | items %d / shadows %d" % [
		("ON" if enabled else "OFF"),
		("ON" if shadows_enabled else "OFF"),
		NATIVE_LIGHT_ITEM_MASK,
		NATIVE_SHADOW_MASK
	]

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	name = "NativeLightPresentation"

	canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = AMBIENT_COLOR
	add_child(canvas_modulate)

	occluder_root = Node2D.new()
	occluder_root.name = "NativeOccluders"
	occluder_root.z_as_relative = false
	occluder_root.z_index = 1
	add_child(occluder_root)

	flashlight_light = _make_light(FLASH_TEXTURE_SIZE, FLASH_COLOR, FLASH_ENERGY, 1.0)
	flashlight_light.name = "FlashlightLight"
	flashlight_light.enabled = false
	add_child(flashlight_light)

	for i in range(BEAM_GLOW_POOL_SIZE):
		var glow := _make_light(BEAM_GLOW_TEXTURE_SIZE, BEAM_GLOW_COLOR, BEAM_GLOW_ENERGY, 0.5)
		glow.name = "BeamGlow_%d" % i
		glow.enabled = false
		add_child(glow)
		beam_glow_pool.append(glow)

	prism_node_light = _make_light(PRISM_TEXTURE_SIZE, PRISM_NODE_COLOR, PRISM_NODE_ENERGY, 0.8)
	prism_node_light.name = "PrismNodeLight"
	prism_node_light.enabled = false
	add_child(prism_node_light)

	_apply_shadow_state()

# ---------------------------------------------------------------------------
# Per-frame update  — call from scene _process / after packet refresh
# ---------------------------------------------------------------------------

func update_from_packets(
	flashlight_packet: Dictionary,
	beam_packet: Dictionary,
	prism_packet: Dictionary,
	prism_entities: Array,
	prism_node_ref,
	flashlight_on: bool,
	player_pos: Vector2,
	facing: Vector2,
	world = null
) -> void:
	if not enabled:
		return
	var world_occluders: Array = []
	var tree_entities: Array = []
	if world != null:
		world_occluders = Array(world.occluder_segments)
		if world.has_method("entity_list"):
			tree_entities = world.entity_list("tree_trunk")
	_update_occluders(world_occluders, tree_entities)
	_update_flashlight(flashlight_packet, flashlight_on, player_pos, facing)
	_update_beam_glows(beam_packet)
	_update_prism_stations(prism_entities, prism_packet)
	_update_prism_node(prism_node_ref, prism_packet)

# ---------------------------------------------------------------------------
# Occluders
# ---------------------------------------------------------------------------

func _update_occluders(world_occluders: Array, tree_entities: Array) -> void:
	var signature := _build_occluder_signature(world_occluders, tree_entities)
	if signature == _occluder_signature:
		return
	_occluder_signature = signature

	var active_keys: Dictionary = {}

	for i in range(world_occluders.size()):
		var surface: Dictionary = world_occluders[i]
		if not surface.has("a") or not surface.has("b"):
			continue
		var a: Vector2 = surface.get("a", Vector2.ZERO)
		var b: Vector2 = surface.get("b", Vector2.ZERO)
		if a.distance_to(b) < OCCLUDER_MIN_LENGTH:
			continue
		var seg_key := "seg_%d_%d_%d_%d" % [int(round(a.x)), int(round(a.y)), int(round(b.x)), int(round(b.y))]
		active_keys[seg_key] = true
		var segment_node: LightOccluder2D = occluder_nodes.get(seg_key, null)
		if segment_node == null:
			segment_node = _make_segment_occluder(seg_key, a, b, OCCLUDER_SEGMENT_THICKNESS)
			occluder_nodes[seg_key] = segment_node
			occluder_root.add_child(segment_node)
		else:
			_configure_segment_occluder(segment_node, a, b, OCCLUDER_SEGMENT_THICKNESS)
			segment_node.visible = enabled

	for i in range(tree_entities.size()):
		var tree: Dictionary = tree_entities[i]
		var pos: Vector2 = tree.get("pos", Vector2.ZERO)
		var radius := float(tree.get("radius", 0.0))
		if radius <= 0.0:
			continue
		var tree_key := "tree_%d_%d_%d" % [int(round(pos.x)), int(round(pos.y)), int(round(radius))]
		active_keys[tree_key] = true
		var tree_node: LightOccluder2D = occluder_nodes.get(tree_key, null)
		if tree_node == null:
			tree_node = _make_circle_occluder(tree_key, pos, radius + TREE_OCCLUDER_PADDING, TREE_OCCLUDER_POINTS)
			occluder_nodes[tree_key] = tree_node
			occluder_root.add_child(tree_node)
		else:
			_configure_circle_occluder(tree_node, pos, radius + TREE_OCCLUDER_PADDING, TREE_OCCLUDER_POINTS)
			tree_node.visible = enabled

	for key in occluder_nodes.keys():
		if active_keys.has(key):
			continue
		var dead_node: LightOccluder2D = occluder_nodes[key]
		if is_instance_valid(dead_node):
			dead_node.queue_free()
		occluder_nodes.erase(key)

func _build_occluder_signature(world_occluders: Array, tree_entities: Array) -> String:
	var bits: PackedStringArray = []
	for surface: Dictionary in world_occluders:
		if not surface.has("a") or not surface.has("b"):
			continue
		var a: Vector2 = surface.get("a", Vector2.ZERO)
		var b: Vector2 = surface.get("b", Vector2.ZERO)
		bits.append("s:%d:%d:%d:%d" % [int(round(a.x)), int(round(a.y)), int(round(b.x)), int(round(b.y))])
	for tree: Dictionary in tree_entities:
		var pos: Vector2 = tree.get("pos", Vector2.ZERO)
		var radius := float(tree.get("radius", 0.0))
		bits.append("t:%d:%d:%d" % [int(round(pos.x)), int(round(pos.y)), int(round(radius))])
	return "|".join(bits)

func _make_segment_occluder(name_hint: String, a: Vector2, b: Vector2, thickness: float) -> LightOccluder2D:
	var occluder := LightOccluder2D.new()
	occluder.name = name_hint
	occluder.occluder_light_mask = NATIVE_SHADOW_MASK
	_configure_segment_occluder(occluder, a, b, thickness)
	return occluder

func _configure_segment_occluder(occluder: LightOccluder2D, a: Vector2, b: Vector2, thickness: float) -> void:
	var poly := OccluderPolygon2D.new()
	var dir := (b - a).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var normal := Vector2(-dir.y, dir.x) * (thickness * 0.5)
	poly.polygon = PackedVector2Array([
		a + normal,
		b + normal,
		b - normal,
		a - normal
	])
	occluder.occluder = poly
	occluder.visible = enabled

func _make_circle_occluder(name_hint: String, pos: Vector2, radius: float, point_count: int) -> LightOccluder2D:
	var occluder := LightOccluder2D.new()
	occluder.name = name_hint
	occluder.occluder_light_mask = NATIVE_SHADOW_MASK
	_configure_circle_occluder(occluder, pos, radius, point_count)
	return occluder

func _configure_circle_occluder(occluder: LightOccluder2D, pos: Vector2, radius: float, point_count: int) -> void:
	var poly := OccluderPolygon2D.new()
	var points := PackedVector2Array()
	for i in range(point_count):
		var angle := TAU * float(i) / float(point_count)
		points.append(pos + Vector2.RIGHT.rotated(angle) * radius)
	poly.polygon = points
	occluder.occluder = poly
	occluder.visible = enabled

# ---------------------------------------------------------------------------
# Flashlight
# ---------------------------------------------------------------------------

func _update_flashlight(packet: Dictionary, on: bool, pos: Vector2, facing_dir: Vector2) -> void:
	if not on or not bool(packet.get("source", {}).get("intensity", 0)):
		flashlight_light.enabled = false
		return
	flashlight_light.enabled = true
	flashlight_light.position = pos
	var source: Dictionary = packet.get("source", {})
	var fl_range := float(source.get("range", 260.0))
	flashlight_light.texture_scale = clampf(fl_range / 180.0, 0.6, 3.2)
	flashlight_light.energy = lerpf(FLASH_ENERGY * 0.72, FLASH_ENERGY, clampf(fl_range / 320.0, 0.0, 1.0))
	flashlight_light.offset = facing_dir * (fl_range * 0.18)
	flashlight_light.rotation = facing_dir.angle()

# ---------------------------------------------------------------------------
# Beam impact glows
# ---------------------------------------------------------------------------

func _update_beam_glows(packet: Dictionary) -> void:
	var segments: Array = packet.get("segments", [])
	var active_flag := bool(packet.get("active", false))
	if not active_flag or segments.is_empty():
		for glow: PointLight2D in beam_glow_pool:
			glow.enabled = false
		return

	var points: Array[Dictionary] = []
	for seg: Dictionary in segments:
		var a_pos: Vector2 = seg.get("a", Vector2.ZERO)
		var b_pos: Vector2 = seg.get("b", Vector2.ZERO)
		var intensity: float = float(seg.get("intensity", 1.0))
		var layer: int = int(seg.get("layer", 0))
		var length: float = a_pos.distance_to(b_pos)
		if length <= 4.0:
			continue
		var sample_count: int = max(1, min(3, int(ceil(length / 120.0))))
		for sample_idx in range(sample_count):
			var t: float = (float(sample_idx) + 0.5) / float(sample_count)
			var sample_pos: Vector2 = a_pos.lerp(b_pos, t)
			var sample_intensity: float = intensity * lerpf(0.78, 1.0, 1.0 - absf(t - 0.5) * 2.0)
			points.append({
				"pos": sample_pos,
				"intensity": sample_intensity,
				"layer": layer,
				"length": length
			})

	points.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["intensity"]) * float(a["length"]) > float(b["intensity"]) * float(b["length"])
	)

	for i in range(beam_glow_pool.size()):
		var glow: PointLight2D = beam_glow_pool[i]
		if i < points.size():
			var pt: Dictionary = points[i]
			glow.position = pt["pos"]
			glow.enabled = true
			glow.energy = BEAM_GLOW_ENERGY * clampf(float(pt["intensity"]), 0.18, 1.0)
			var layer_ratio := clampf(float(pt["layer"]) / 3.0, 0.0, 1.0)
			glow.color = BEAM_GLOW_COLOR.lerp(Color(0.42, 0.82, 1.0, 1.0), layer_ratio * 0.35)
			glow.texture_scale = lerpf(0.48, 0.92, clampf(float(pt["intensity"]), 0.0, 1.0))
		else:
			glow.enabled = false

# ---------------------------------------------------------------------------
# Prism stations (from LightWorld entities)
# ---------------------------------------------------------------------------

func _prism_packet_keys(packet: Dictionary) -> Dictionary:
	var keys: Dictionary = {}
	for key in Array(packet.get("emitter_keys", [])):
		keys[String(key)] = true
	return keys

func _update_prism_stations(entities: Array, prism_packet: Dictionary) -> void:
	var active_keys: Dictionary = {}
	var energized_keys := _prism_packet_keys(prism_packet)
	for entity: Dictionary in entities:
		if String(entity.get("kind", "")) != "prism_station":
			continue
		var pos: Vector2 = entity.get("pos", Vector2.ZERO)
		var key := "station_%d_%d" % [int(pos.x), int(pos.y)]
		active_keys[key] = true

		if not prism_station_lights.has(key):
			var light := _make_light(PRISM_TEXTURE_SIZE, PRISM_COLOR, PRISM_ENERGY, 0.7)
			light.name = "PrismStation_%s" % key
			light.shadow_enabled = false
			add_child(light)
			prism_station_lights[key] = light

		var light: PointLight2D = prism_station_lights[key]
		light.position = pos
		light.texture_scale = 0.70
		light.energy = PRISM_ENERGY * 1.12
		light.enabled = energized_keys.has(key)

	for key: String in prism_station_lights.keys():
		if not active_keys.has(key):
			(prism_station_lights[key] as PointLight2D).enabled = false

# ---------------------------------------------------------------------------
# Player-placed prism node
# ---------------------------------------------------------------------------

func _update_prism_node(prism_ref, prism_packet: Dictionary) -> void:
	if prism_ref == null or not is_instance_valid(prism_ref):
		prism_node_light.enabled = false
		return
	var energized_keys := _prism_packet_keys(prism_packet)
	prism_node_light.enabled = energized_keys.has("manual")
	if not prism_node_light.enabled:
		return
	prism_node_light.position = prism_ref.position
	prism_node_light.texture_scale = 0.84
	prism_node_light.energy = PRISM_NODE_ENERGY * 1.18
	prism_node_light.shadow_enabled = false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_light(tex_size: int, color: Color, energy_val: float, scale: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = _get_radial_texture(tex_size, Color.WHITE)
	light.color = color
	light.energy = energy_val
	light.texture_scale = scale
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.shadow_enabled = false
	light.range_item_cull_mask = NATIVE_LIGHT_ITEM_MASK
	light.shadow_item_cull_mask = NATIVE_SHADOW_MASK
	light.z_as_relative = false
	light.z_index = 2
	return light

func _get_radial_texture(size: int, color: Color) -> Texture2D:
	if _texture_cache.has(size):
		return _texture_cache[size]
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) * 0.5
	var max_r := size * 0.5
	for y in range(size):
		for x in range(size):
			var dist := center.distance_to(Vector2(x, y)) / max_r
			var falloff := clampf(1.0 - dist, 0.0, 1.0)
			var alpha := pow(falloff, 2.2)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	var tex := ImageTexture.create_from_image(image)
	_texture_cache[size] = tex
	return tex

func _apply_shadow_state() -> void:
	if flashlight_light:
		flashlight_light.shadow_enabled = shadows_enabled
	for glow: PointLight2D in beam_glow_pool:
		glow.shadow_enabled = false
	if prism_node_light:
		prism_node_light.shadow_enabled = false
	for key: String in prism_station_lights.keys():
		(prism_station_lights[key] as PointLight2D).shadow_enabled = false

func _apply_visibility() -> void:
	if canvas_modulate:
		canvas_modulate.visible = enabled
	if occluder_root:
		occluder_root.visible = enabled
	if flashlight_light:
		flashlight_light.visible = enabled
	for glow: PointLight2D in beam_glow_pool:
		glow.visible = enabled
	if prism_node_light:
		prism_node_light.visible = enabled
	for key: String in prism_station_lights.keys():
		(prism_station_lights[key] as PointLight2D).visible = enabled
	for key: String in occluder_nodes.keys():
		(occluder_nodes[key] as LightOccluder2D).visible = enabled
