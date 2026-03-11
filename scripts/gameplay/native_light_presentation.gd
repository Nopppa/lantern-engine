extends Node2D
class_name NativeLightPresentation
## Phase 4 — Native Godot 2D lighting decoration layer.
##
## This node manages CanvasModulate + PointLight2D nodes that sit above the
## packet-first lighting pipeline purely for atmosphere / presentation.
##
## Design constraints:
##   - Consumes render-packet data each frame; never writes gameplay truth.
##   - All Light2D nodes are decorative — they do not feed back into
##     LightWorld, _light_intensity_at(), or any solver.
##   - The CanvasModulate darkens the scene so that Light2D contributions
##     register visually; it does NOT affect gameplay darkness calculations.

# ---------------------------------------------------------------------------
# Tunables  (all presentation-only)
# ---------------------------------------------------------------------------

## Ambient modulate when no lights are active (dark scene base color).
const AMBIENT_COLOR := Color(0.06, 0.07, 0.10, 1.0)

## Flashlight light config
const FLASH_ENERGY := 0.80
const FLASH_COLOR := Color(1.0, 0.95, 0.78, 1.0)
const FLASH_TEXTURE_SIZE := 512

## Beam impact glow config
const BEAM_GLOW_ENERGY := 0.55
const BEAM_GLOW_COLOR := Color(0.52, 0.94, 1.0, 1.0)
const BEAM_GLOW_TEXTURE_SIZE := 128
const BEAM_GLOW_POOL_SIZE := 12  # max simultaneous impact glows

## Prism station ambient config
const PRISM_ENERGY := 0.45
const PRISM_COLOR := Color(0.54, 0.93, 1.0, 1.0)
const PRISM_TEXTURE_SIZE := 256

## Manual prism node config
const PRISM_NODE_ENERGY := 0.55
const PRISM_NODE_COLOR := Color(0.58, 0.96, 1.0, 1.0)

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

var canvas_modulate: CanvasModulate

## Flashlight source light — follows player, scales with packet range.
var flashlight_light: PointLight2D

## Pool of reusable beam-impact PointLight2D nodes.
var beam_glow_pool: Array[PointLight2D] = []

## Dictionary mapping "station_x_y" → PointLight2D for prism stations.
var prism_station_lights: Dictionary = {}

## Dedicated light for the player-placed prism node.
var prism_node_light: PointLight2D

## Cached radial textures (keyed by size).
var _texture_cache: Dictionary = {}

## Whether the layer is enabled. Toggle without tearing down nodes.
var enabled := true:
	set(value):
		enabled = value
		_apply_visibility()

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	name = "NativeLightPresentation"

	# --- CanvasModulate: ambient darkness ---
	canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = AMBIENT_COLOR
	add_child(canvas_modulate)

	# --- Flashlight PointLight2D ---
	flashlight_light = _make_light(FLASH_TEXTURE_SIZE, FLASH_COLOR, FLASH_ENERGY, 1.0)
	flashlight_light.name = "FlashlightLight"
	flashlight_light.enabled = false
	add_child(flashlight_light)

	# --- Beam glow pool ---
	for i in range(BEAM_GLOW_POOL_SIZE):
		var glow := _make_light(BEAM_GLOW_TEXTURE_SIZE, BEAM_GLOW_COLOR, BEAM_GLOW_ENERGY, 0.5)
		glow.name = "BeamGlow_%d" % i
		glow.enabled = false
		add_child(glow)
		beam_glow_pool.append(glow)

	# --- Prism node light (player-placed) ---
	prism_node_light = _make_light(PRISM_TEXTURE_SIZE, PRISM_NODE_COLOR, PRISM_NODE_ENERGY, 0.8)
	prism_node_light.name = "PrismNodeLight"
	prism_node_light.enabled = false
	add_child(prism_node_light)

# ---------------------------------------------------------------------------
# Per-frame update  — call from scene _process / after packet refresh
# ---------------------------------------------------------------------------

## Main entry point: feed current packet data, player state, and world data.
## This never touches gameplay truth — purely reads.
func update_from_packets(
	flashlight_packet: Dictionary,
	beam_packet: Dictionary,
	prism_entities: Array,
	prism_node_ref,  # Node2D or null
	flashlight_on: bool,
	player_pos: Vector2,
	facing: Vector2
) -> void:
	if not enabled:
		return
	_update_flashlight(flashlight_packet, flashlight_on, player_pos, facing)
	_update_beam_glows(beam_packet)
	_update_prism_stations(prism_entities)
	_update_prism_node(prism_node_ref)

# ---------------------------------------------------------------------------
# Flashlight
# ---------------------------------------------------------------------------

func _update_flashlight(packet: Dictionary, on: bool, pos: Vector2, facing_dir: Vector2) -> void:
	if not on or not bool(packet.get("source", {}).get("intensity", 0)):
		flashlight_light.enabled = false
		return
	flashlight_light.enabled = true
	flashlight_light.position = pos
	# Scale texture to approximate the flashlight range visually.
	var source: Dictionary = packet.get("source", {})
	var fl_range := float(source.get("range", 260.0))
	flashlight_light.texture_scale = clampf(fl_range / 180.0, 0.6, 3.2)
	flashlight_light.energy = FLASH_ENERGY
	# Offset light slightly in facing direction for directional feel.
	flashlight_light.offset = facing_dir * (fl_range * 0.18)

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

	# Collect unique endpoint positions (de-duplicate endpoints close together).
	var points: Array[Dictionary] = []
	for seg: Dictionary in segments:
		var b_pos: Vector2 = seg.get("b", Vector2.ZERO)
		var intensity: float = float(seg.get("intensity", 1.0))
		var layer: int = int(seg.get("layer", 0))
		# Skip near-duplicate positions.
		var dominated := false
		for existing: Dictionary in points:
			if Vector2(existing["pos"]).distance_to(b_pos) < 18.0:
				# Keep the brighter one.
				if intensity > float(existing["intensity"]):
					existing["pos"] = b_pos
					existing["intensity"] = intensity
					existing["layer"] = layer
				dominated = true
				break
		if not dominated:
			points.append({"pos": b_pos, "intensity": intensity, "layer": layer})

	# Sort by intensity descending so the pool prioritises brightest impacts.
	points.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["intensity"]) > float(b["intensity"])
	)

	for i in range(beam_glow_pool.size()):
		var glow: PointLight2D = beam_glow_pool[i]
		if i < points.size():
			var pt: Dictionary = points[i]
			glow.position = pt["pos"]
			glow.enabled = true
			glow.energy = BEAM_GLOW_ENERGY * clampf(float(pt["intensity"]), 0.15, 1.0)
			# Deeper layers get slightly cooler tint.
			var layer_ratio := clampf(float(pt["layer"]) / 3.0, 0.0, 1.0)
			glow.color = BEAM_GLOW_COLOR.lerp(Color(0.42, 0.82, 1.0, 1.0), layer_ratio * 0.35)
			glow.texture_scale = lerpf(0.35, 0.65, clampf(float(pt["intensity"]), 0.0, 1.0))
		else:
			glow.enabled = false

# ---------------------------------------------------------------------------
# Prism stations (from LightWorld entities)
# ---------------------------------------------------------------------------

func _update_prism_stations(entities: Array) -> void:
	var active_keys: Dictionary = {}
	for entity: Dictionary in entities:
		if String(entity.get("kind", "")) != "prism_station":
			continue
		var pos: Vector2 = entity.get("pos", Vector2.ZERO)
		var key := "station_%d_%d" % [int(pos.x), int(pos.y)]
		active_keys[key] = true

		if not prism_station_lights.has(key):
			var light := _make_light(PRISM_TEXTURE_SIZE, PRISM_COLOR, PRISM_ENERGY, 0.7)
			light.name = "PrismStation_%s" % key
			add_child(light)
			prism_station_lights[key] = light

		var light: PointLight2D = prism_station_lights[key]
		light.position = pos
		light.enabled = true

	# Disable lights for removed stations.
	for key: String in prism_station_lights.keys():
		if not active_keys.has(key):
			(prism_station_lights[key] as PointLight2D).enabled = false

# ---------------------------------------------------------------------------
# Player-placed prism node
# ---------------------------------------------------------------------------

func _update_prism_node(prism_ref) -> void:
	if prism_ref == null or not is_instance_valid(prism_ref):
		prism_node_light.enabled = false
		return
	prism_node_light.enabled = true
	prism_node_light.position = prism_ref.position
	prism_node_light.texture_scale = 0.85

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
	light.shadow_enabled = false  # Phase 4 step 1 — shadows deferred to later pass
	light.range_item_cull_mask = 1  # default layer
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

func _apply_visibility() -> void:
	canvas_modulate.visible = enabled
	flashlight_light.visible = enabled
	for glow: PointLight2D in beam_glow_pool:
		glow.visible = enabled
	prism_node_light.visible = enabled
	for key: String in prism_station_lights.keys():
		(prism_station_lights[key] as PointLight2D).visible = enabled
