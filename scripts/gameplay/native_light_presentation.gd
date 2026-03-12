extends Node2D
class_name NativeLightPresentation

const REFLECTED_BEAM_FILL_SCENE := preload("res://scenes/world/shared/reflected_beam_fill.tscn")
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

const AMBIENT_COLOR := Color(0.12, 0.13, 0.16, 1.0)

const NATIVE_LIGHT_ITEM_MASK := 3
const NATIVE_SHADOW_MASK := 3

const FLASH_ENERGY := 1.25
const FLASH_COLOR := Color(1.0, 0.92, 0.70, 1.0)
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

const OCCLUDER_SEGMENT_THICKNESS := 16.0
const OCCLUDER_SEGMENT_OVERLAP := 4.0
const OCCLUDER_MIN_LENGTH := 6.0
const TREE_OCCLUDER_POINTS := 14
const TREE_OCCLUDER_PADDING := 2.0

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

var canvas_modulate: CanvasModulate
var flashlight_light: PointLight2D
var inner_flashlight_light: PointLight2D
var secondary_flashlight_pool: Array[PointLight2D] = []
var reflected_beam_pool: Array[PointLight2D] = []  # 4 nodes spread along mirror hit segment
var _reflected_beam_poly: Polygon2D  # visual fill for the reflected cone
var beam_glow_pool: Array[PointLight2D] = []
var prism_station_lights: Dictionary = {}
var prism_node_light: PointLight2D

var _debug_r_hits: Array = []

const SECONDARY_FLASHLIGHT_POOL_SIZE := 8
const REFLECTED_BEAM_NODES := 4  # number of PointLight2D spread along mirror segment
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

	flashlight_light = _make_cone_light(FLASH_TEXTURE_SIZE, FLASH_COLOR, FLASH_ENERGY, 1.0, 48.0)
	flashlight_light.name = "FlashlightLight"
	flashlight_light.enabled = false
	add_child(flashlight_light)

	inner_flashlight_light = _make_cone_light(FLASH_TEXTURE_SIZE, Color(1.0, 0.98, 0.90, 1.0), FLASH_ENERGY * 1.5, 1.0, 18.0)
	inner_flashlight_light.name = "InnerFlashlightLight"
	inner_flashlight_light.enabled = false
	add_child(inner_flashlight_light)

	for i in range(SECONDARY_FLASHLIGHT_POOL_SIZE):
		var sec_light := _make_cone_light(FLASH_TEXTURE_SIZE, Color.WHITE, FLASH_ENERGY, 1.0, 22.0)
		sec_light.name = "SecondaryLight_%d" % i
		sec_light.enabled = false
		add_child(sec_light)
		secondary_flashlight_pool.append(sec_light)

	# Reflected beam: 4 nodes spread along the mirror hit segment
	for i in range(REFLECTED_BEAM_NODES):
		var rb := _make_cone_light(FLASH_TEXTURE_SIZE, FLASH_COLOR, FLASH_ENERGY / REFLECTED_BEAM_NODES, 1.0, 22.0)
		rb.name = "ReflectedBeam_%d" % i
		rb.enabled = false
		add_child(rb)
		reflected_beam_pool.append(rb)

	# Visual polygon fill for the reflected cone (drawn under the lights)
	_reflected_beam_poly = REFLECTED_BEAM_FILL_SCENE.instantiate() as Polygon2D
	add_child(_reflected_beam_poly)

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
	world = null,
	enemies: Array = []
) -> void:
	if not enabled:
		return
	var world_occluders: Array = []
	var tree_entities: Array = []
	if world != null:
		world_occluders = Array(world.occluder_segments)
		if world.has_method("entity_list"):
			tree_entities = world.entity_list("tree_trunk")
	_update_occluders(world_occluders, tree_entities, enemies)
	_update_flashlight(flashlight_packet, flashlight_on, player_pos, facing)
	_update_beam_glows(beam_packet)
	_update_prism_stations(prism_entities, prism_packet)
	_update_prism_node(prism_node_ref, prism_packet)

# ---------------------------------------------------------------------------
# Occluders
# ---------------------------------------------------------------------------

func _update_occluders(world_occluders: Array, tree_entities: Array, enemies: Array) -> void:
	var signature := _build_occluder_signature(world_occluders, tree_entities, enemies)
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
		var is_glass: bool = String(surface.get("material_id", "")) == "glass" or not bool(surface.get("blocks_flashlight", true))
		var target_mask: int = 0 if is_glass else NATIVE_SHADOW_MASK

		if segment_node == null:
			segment_node = _make_segment_occluder(seg_key, a, b, OCCLUDER_SEGMENT_THICKNESS)
			segment_node.occluder_light_mask = target_mask
			occluder_nodes[seg_key] = segment_node
			occluder_root.add_child(segment_node)
		else:
			_configure_segment_occluder(segment_node, a, b, OCCLUDER_SEGMENT_THICKNESS)
			segment_node.occluder_light_mask = target_mask
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

	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		if not enemy.get("alive", false) or not is_instance_valid(enemy.get("node")):
			continue
		var pos: Vector2 = enemy["node"].position
		var radius := float(enemy.get("radius", 0.0))
		if radius <= 0.0:
			continue
		# Rebuild shadow every frame since enemies move
		var enemy_key := "enemy_idx_%d" % i
		active_keys[enemy_key] = true
		var enemy_node: LightOccluder2D = occluder_nodes.get(enemy_key, null)
		if enemy_node == null:
			# Subtract a little padding so the enemy doesn't cast shadow over itself entirely
			enemy_node = _make_circle_occluder(enemy_key, pos, max(radius - 2.0, 4.0), TREE_OCCLUDER_POINTS)
			occluder_nodes[enemy_key] = enemy_node
			occluder_root.add_child(enemy_node)
		else:
			_configure_circle_occluder(enemy_node, pos, max(radius - 2.0, 4.0), TREE_OCCLUDER_POINTS)
			enemy_node.visible = enabled

	for key in occluder_nodes.keys():
		if active_keys.has(key):
			continue
		var dead_node: LightOccluder2D = occluder_nodes[key]
		if is_instance_valid(dead_node):
			dead_node.queue_free()
		occluder_nodes.erase(key)

func _build_occluder_signature(world_occluders: Array, tree_entities: Array, enemies: Array) -> String:
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
	for enemy: Dictionary in enemies:
		if not enemy.get("alive", false) or not is_instance_valid(enemy.get("node")):
			continue
		var pos: Vector2 = enemy["node"].position
		bits.append("e:%d:%d" % [int(round(pos.x)), int(round(pos.y))])
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
	var point_a := a - dir * OCCLUDER_SEGMENT_OVERLAP
	var point_b := b + dir * OCCLUDER_SEGMENT_OVERLAP
	poly.polygon = PackedVector2Array([
		point_a + normal,
		point_b + normal,
		point_b - normal,
		point_a - normal
	])
	poly.closed = true
	poly.cull_mode = OccluderPolygon2D.CULL_DISABLED
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
	poly.closed = true
	poly.cull_mode = OccluderPolygon2D.CULL_DISABLED
	occluder.occluder = poly
	occluder.visible = enabled

# ---------------------------------------------------------------------------
# Flashlight
# ---------------------------------------------------------------------------

func _update_flashlight(packet: Dictionary, on: bool, pos: Vector2, facing_dir: Vector2) -> void:
	if not on or not bool(packet.get("source", {}).get("intensity", 0)):
		flashlight_light.enabled = false
		inner_flashlight_light.enabled = false
		for rb: PointLight2D in reflected_beam_pool:
			rb.enabled = false
		_reflected_beam_poly.visible = false
		_debug_r_hits.clear()
		queue_redraw()
		for sec: PointLight2D in secondary_flashlight_pool:
			sec.enabled = false
		return
	flashlight_light.enabled = true
	flashlight_light.position = pos
	inner_flashlight_light.enabled = true
	inner_flashlight_light.position = pos
	
	var source: Dictionary = packet.get("source", {})
	var fl_range := float(source.get("range", 260.0))
	var half_angle := float(source.get("half_angle_deg", 48.0))
	
	flashlight_light.texture = _get_cone_texture(FLASH_TEXTURE_SIZE, Color.WHITE, half_angle)
	flashlight_light.texture_scale = clampf(fl_range / (FLASH_TEXTURE_SIZE * 0.5), 1.0, 4.5)
	flashlight_light.energy = lerpf(FLASH_ENERGY * 0.82, FLASH_ENERGY, clampf(fl_range / 320.0, 0.0, 1.0))
	flashlight_light.offset = Vector2.ZERO
	flashlight_light.rotation = facing_dir.angle()
	flashlight_light.shadow_color = Color(0.01, 0.01, 0.02, 0.98)
	flashlight_light.shadow_filter = Light2D.SHADOW_FILTER_NONE
	flashlight_light.shadow_filter_smooth = 0.0

	var inner_half_angle := half_angle * 0.4
	var inner_range := fl_range * 0.90
	inner_flashlight_light.texture = _get_cone_texture(FLASH_TEXTURE_SIZE, Color.WHITE, inner_half_angle)
	inner_flashlight_light.texture_scale = clampf(inner_range / (FLASH_TEXTURE_SIZE * 0.5), 1.0, 4.5)
	inner_flashlight_light.energy = lerpf(FLASH_ENERGY * 0.6, FLASH_ENERGY * 1.6, clampf(inner_range / 320.0, 0.0, 1.0))
	inner_flashlight_light.offset = Vector2.ZERO
	inner_flashlight_light.rotation = facing_dir.angle()
	inner_flashlight_light.shadow_color = Color(0.0, 0.0, 0.0, 1.0) # Full occlusion for inner beam
	inner_flashlight_light.shadow_filter = Light2D.SHADOW_FILTER_NONE
	inner_flashlight_light.shadow_filter_smooth = 0.0

	# ---- Reflected beam: segment-emitter approach ----
	var r_hits: Array = []
	var r_ends: Array = []
	var r_dirs: Array = []
	var r_intensity_sum := 0.0
	var r_max_range := 0.0

	for seg in packet.get("segments", []):
		if not seg is Dictionary:
			continue
		if seg.get("kind", "") != "reflect":
			continue
		var a := Vector2(seg.get("a", Vector2.ZERO))
		var b := Vector2(seg.get("b", Vector2.ZERO))
		var si := float(seg.get("intensity", 0.0))
		if si < 0.03 or a.distance_to(b) < 4.0:
			continue
		r_hits.append(a)
		r_ends.append(b)
		r_dirs.append((b - a).normalized())
		r_intensity_sum += si
		r_max_range = max(r_max_range, a.distance_to(b))

	if r_hits.size() >= 2:
		# Average reflected direction
		var dir_sum := Vector2.ZERO
		for i in range(r_dirs.size()):
			dir_sum += Vector2(r_dirs[i])
		var avg_dir := dir_sum.normalized()
		var avg_intensity := r_intensity_sum / float(r_hits.size())

		# The rays in r_hits are perfectly sequential directly from the flashlight raycast sweep.
		# Therefore, index 0 is one side of the sweep, and index -1 is the other side.
		# We don't need any dot product projections to map them!
		var left_idx := 0
		var right_idx := r_hits.size() - 1

		var p_left := Vector2(r_hits[left_idx])
		var p_right := Vector2(r_hits[right_idx])
		var e_left := Vector2(r_ends[left_idx])
		var e_right := Vector2(r_ends[right_idx])
		var angle_left := Vector2(r_dirs[left_idx]).angle()
		var angle_right := Vector2(r_dirs[right_idx]).angle()

		# Unwrap the right angle to prevent the interpolation from crossing over via the shortest path
		var diff := wrapf(angle_right - angle_left, -PI, PI)
		var angle_right_unwrapped := angle_left + diff

		# Build visual polygon as a simple quadrilateral matching the sweep extremes
		var frontier_pts := PackedVector2Array()
		frontier_pts.append(p_left)
		frontier_pts.append(e_left)
		frontier_pts.append(e_right)
		frontier_pts.append(p_right)

		_reflected_beam_poly.polygon = frontier_pts
		_reflected_beam_poly.color = Color(FLASH_COLOR.r, FLASH_COLOR.g, FLASH_COLOR.b,
			clampf(avg_intensity * 0.25, 0.08, 0.35))
		_reflected_beam_poly.visible = enabled

		# Spread REFLECTED_BEAM_NODES evenly along the segment and interpolate angles
		var energy_per := FLASH_ENERGY * clampf(avg_intensity * 0.88, 0.08, 1.4) / float(REFLECTED_BEAM_NODES)
		var tex := _get_cone_texture(FLASH_TEXTURE_SIZE, Color.WHITE, half_angle * 0.95)
		var tex_scale := clampf(r_max_range / (FLASH_TEXTURE_SIZE * 0.5), 0.5, 4.5)

		# Offset slightly so the light origin is not trapped inside the mirror's Godot LightOccluder2D
		var spawn_offset := avg_dir * (OCCLUDER_SEGMENT_THICKNESS * 0.5 + 2.0)

		for i in range(REFLECTED_BEAM_NODES):
			var t := float(i) / float(REFLECTED_BEAM_NODES - 1) if REFLECTED_BEAM_NODES > 1 else 0.5
			var rb: PointLight2D = reflected_beam_pool[i]
			rb.enabled = true
			rb.position = p_left.lerp(p_right, t) + spawn_offset
			rb.rotation = lerp(angle_left, angle_right_unwrapped, t)
			rb.texture = tex
			rb.texture_scale = tex_scale
			rb.color = FLASH_COLOR
			rb.energy = energy_per
			rb.shadow_color = Color(0.01, 0.02, 0.03, 0.92)
			rb.shadow_filter = Light2D.SHADOW_FILTER_NONE
			rb.shadow_filter_smooth = 0.0
	else:
		for rb in reflected_beam_pool:
			rb.enabled = false
		_reflected_beam_poly.visible = false

	_debug_r_hits = r_hits
	queue_redraw()

	# ---- Transmit (glass pass-through) secondary lights — keep one-per-segment ----
	var sec_index := 0
	for segment in packet.get("segments", []):
		if sec_index >= SECONDARY_FLASHLIGHT_POOL_SIZE:
			break
		if not segment is Dictionary:
			continue
		if String(segment.get("kind", "")) != "transmit":
			continue
		if not bool(segment.get("visible", true)):
			continue
		var a: Vector2 = segment.get("a", Vector2.ZERO)
		var b: Vector2 = segment.get("b", Vector2.ZERO)
		var intensity: float = float(segment.get("intensity", 0.0))
		if intensity < 0.05 or a.distance_to(b) < 5.0:
			continue
		var out_dir := (b - a).normalized()
		var bounce_range := a.distance_to(b)
		var sec_light: PointLight2D = secondary_flashlight_pool[sec_index]
		sec_light.enabled = true
		sec_light.position = a
		sec_light.rotation = out_dir.angle()
		sec_light.texture = _get_cone_texture(FLASH_TEXTURE_SIZE, Color.WHITE, half_angle * 1.2)
		sec_light.texture_scale = clampf(bounce_range / (FLASH_TEXTURE_SIZE * 0.5), 0.5, 4.5)
		sec_light.color = Color(0.70, 0.96, 1.0, 1.0).lerp(FLASH_COLOR, 0.4)
		sec_light.energy = FLASH_ENERGY * intensity * 0.9
		sec_light.shadow_color = Color(0.01, 0.03, 0.06, 0.85)
		sec_light.shadow_filter = Light2D.SHADOW_FILTER_NONE
		sec_light.shadow_filter_smooth = 0.0
		sec_index += 1

	for i in range(sec_index, SECONDARY_FLASHLIGHT_POOL_SIZE):
		secondary_flashlight_pool[i].enabled = false






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

func _prism_packet_strengths(packet: Dictionary) -> Dictionary:
	return Dictionary(packet.get("emitter_strengths", {})).duplicate(true)

func _update_prism_stations(entities: Array, prism_packet: Dictionary) -> void:
	var active_keys: Dictionary = {}
	var packet_keys := _prism_packet_keys(prism_packet)
	var strengths := _prism_packet_strengths(prism_packet)
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
		var strength: float = clampf(float(strengths.get(key, 0.0)), 0.0, 1.0)
		light.position = pos
		light.texture_scale = lerpf(0.46, 0.70, strength)
		light.energy = lerpf(PRISM_ENERGY * 0.36, PRISM_ENERGY * 1.12, strength)
		light.enabled = packet_keys.has(key)

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
	var packet_keys := _prism_packet_keys(prism_packet)
	var strengths := _prism_packet_strengths(prism_packet)
	prism_node_light.enabled = packet_keys.has("manual")
	if not prism_node_light.enabled:
		return
	var strength: float = clampf(float(strengths.get("manual", 0.0)), 0.0, 1.0)
	prism_node_light.position = prism_ref.position
	prism_node_light.texture_scale = lerpf(0.48, 0.84, strength)
	prism_node_light.energy = lerpf(PRISM_NODE_ENERGY * 0.34, PRISM_NODE_ENERGY * 1.18, strength)
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

func _make_cone_light(tex_size: int, color: Color, energy_val: float, scale: float, half_angle_deg: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = _get_cone_texture(tex_size, Color.WHITE, half_angle_deg)
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

func _get_cone_texture(size: int, color: Color, half_angle_deg: float) -> Texture2D:
	var cache_key := "cone_%d_%d" % [size, int(half_angle_deg)]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var max_r := size * 0.5
	var half_angle_rad := deg_to_rad(half_angle_deg)
	
	for y in range(size):
		for x in range(size):
			var pos := Vector2(x, y)
			var offset := pos - center
			var dist := offset.length() / max_r
			if dist > 1.0 or dist == 0.0:
				image.set_pixel(x, y, Color(color.r, color.g, color.b, 0.0))
				continue
				
			var angle_diff := absf(offset.angle())
			if angle_diff > half_angle_rad:
				image.set_pixel(x, y, Color(color.r, color.g, color.b, 0.0))
				continue
				
			var distance_falloff := clampf(1.0 - dist, 0.0, 1.0)
			# Make distance falloff linear and then sharper near the very end
			if distance_falloff < 0.15:
				distance_falloff *= (distance_falloff / 0.15)
			
			var angle_ratio := angle_diff / half_angle_rad
			var angle_falloff := 1.0
			# Hard cutoff for comic-book style
			if angle_ratio > 0.92:
				angle_falloff = clampf(1.0 - ((angle_ratio - 0.92) / 0.08), 0.0, 1.0)
			
			var alpha := distance_falloff * angle_falloff
			image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
			
	var tex := ImageTexture.create_from_image(image)
	_texture_cache[cache_key] = tex
	return tex

func _get_radial_texture(size: int, color: Color) -> Texture2D:
	var cache_key := "rad_%d" % size
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
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
	_texture_cache[cache_key] = tex
	return tex

func _apply_shadow_state() -> void:
	if flashlight_light:
		flashlight_light.shadow_enabled = shadows_enabled
	if inner_flashlight_light:
		inner_flashlight_light.shadow_enabled = shadows_enabled
	for sec: PointLight2D in secondary_flashlight_pool:
		sec.shadow_enabled = shadows_enabled
	for rb: PointLight2D in reflected_beam_pool:
		rb.shadow_enabled = shadows_enabled
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
	if inner_flashlight_light:
		inner_flashlight_light.visible = enabled
	for sec: PointLight2D in secondary_flashlight_pool:
		sec.visible = enabled
	for rb: PointLight2D in reflected_beam_pool:
		rb.visible = enabled
	if _reflected_beam_poly:
		_reflected_beam_poly.visible = (enabled and _reflected_beam_poly.polygon.size() > 2)
	for glow: PointLight2D in beam_glow_pool:
		glow.visible = enabled
	if prism_node_light:
		prism_node_light.visible = enabled
	for key: String in prism_station_lights.keys():
		(prism_station_lights[key] as PointLight2D).visible = enabled
	for key: String in occluder_nodes.keys():
		(occluder_nodes[key] as LightOccluder2D).visible = enabled
