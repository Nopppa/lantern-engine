## ExplorationScene – RandomGEN exploration world runtime scaffold.
##
## Milestone 2: Runtime integration with visual rendering and player movement.
## Loads a generated LightWorld via GeneratedExplorationProvider and
## renders it with basic debug visualization.
##
## Design rules enforced here:
##   - Does NOT touch lighting/material logic.
##   - Light Lab is left untouched.
##   - All world data flows through GeneratedExplorationProvider → LightWorldBuilder.
##   - The resulting LightWorld is the single world-truth object for this scene.
##
extends Node2D
class_name ExplorationScene

const GeneratedExplorationProvider = preload("res://scripts/world/generated_exploration_provider.gd")
const LightLabCollision = preload("res://scripts/gameplay/light_lab_collision.gd")
const LightTypes = preload("res://scripts/gameplay/light_types.gd")
const LightField = preload("res://scripts/gameplay/light_field.gd")
const DeadAliveGrid = preload("res://scripts/gameplay/dead_alive_grid.gd")
const NativeLightPresentation = preload("res://scripts/gameplay/native_light_presentation.gd")
const FlashlightVisuals = preload("res://scripts/gameplay/flashlight_visuals.gd")

# Arena rect matching RunScene / Light Lab for pipeline compatibility.
const ARENA_RECT := Rect2(Vector2(64, 64), Vector2(1152, 592))
const SCENE_LABEL := "Exploration World v0.2-milestone2"
const PLAYER_SPEED := 240.0
const PLAYER_RADIUS := 14.0
const LIGHT_CELL_SIZE := 32.0
const FLASHLIGHT_RANGE := 420.0
const FLASHLIGHT_HALF_ANGLE := 48.0
const BEAM_OFFSET := 4.0
const MAIN_MENU_SCENE_PATH := "res://scenes/main.tscn"

## Seed used for this scene instance.  Change to explore different worlds.
@export var world_seed: int = 2001

var _provider: GeneratedExplorationProvider = null
var _light_world: LightWorld = null
var _player_node: Node2D = null
var _camera: Camera2D = null
var _hud_layer: CanvasLayer = null
var _hud_label: RichTextLabel = null
var _status_label: RichTextLabel = null
var _pause_panel: PanelContainer = null
var _pause_title_label: Label = null
var _pause_body_label: Label = null
var _player_pos: Vector2 = Vector2.ZERO
var _facing: Vector2 = Vector2.RIGHT
var _flashlight_on := true
var _gameplay_light_field: LightField = null
var _dead_alive_cells: Array = []
var _flashlight_render_packet: Dictionary = LightTypes.empty_render_packet("flashlight")
var _prism_render_packet: Dictionary = LightTypes.empty_render_packet("prism")
var _approx_flashlight_frontier := {}
var _approx_prism_frontiers := {}
var _native_light_presentation: NativeLightPresentation = null
var _pause_open := false

# Material color palette for visualization
const MATERIAL_COLORS := {
	"brick": Color(0.52, 0.32, 0.28, 0.85),
	"wood": Color(0.48, 0.36, 0.22, 0.85),
	"mirror": Color(0.72, 0.82, 0.95, 0.85),
	"glass": Color(0.62, 0.82, 0.92, 0.45),
	"wet": Color(0.28, 0.42, 0.58, 0.65),
	"tree": Color(0.32, 0.28, 0.18, 0.92)
}

# --- Lifecycle ---

func _ready() -> void:
	_boot_world()
	_setup_scene()
	_boot_shared_light_runtime()
	_layout_overlay_ui()
	queue_redraw()
	print("[ExplorationScene] %s booted — world_type: %s  seed: %d  spawn: %s" % [
		SCENE_LABEL,
		_light_world.metadata.get("world_type", "?"),
		world_seed,
		str(_provider.spawn_hint())
	])

func _process(delta: float) -> void:
	if not _pause_open:
		_update_player(delta)
		_rebuild_gameplay_light_field()
		if _gameplay_light_field != null:
			_gameplay_light_field.process_field(delta)
		DeadAliveGrid.update(_dead_alive_cells, delta, Callable(self, "_sample_gameplay_light"))
		_update_native_light_presentation()
	_layout_overlay_ui()
	_update_hud()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_toggle_pause_menu()
			return
		if _pause_open:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_M:
				_return_to_main_menu()
			return
		if event.keycode == KEY_R:
			reroll(world_seed + 1)
		elif event.keycode == KEY_T:
			reroll(randi())
		elif event.keycode == KEY_F:
			_flashlight_on = !_flashlight_on

# --- World initialisation ---

func _boot_world() -> void:
	_provider = GeneratedExplorationProvider.new(world_seed, ARENA_RECT)
	_light_world = _provider.build_world()
	_on_world_ready()

## Called once the LightWorld is ready.
func _on_world_ready() -> void:
	var spawn: Vector2 = _provider.spawn_hint()
	if spawn != Vector2.INF:
		_player_pos = spawn
	else:
		_player_pos = ARENA_RECT.get_center()
	_player_pos = _find_valid_spawn(_player_pos)
	_boot_shared_light_runtime()

# --- Scene setup (Milestone 2) ---

func _setup_scene() -> void:
	# Player node
	if _player_node == null:
		_player_node = Node2D.new()
		_player_node.name = "Player"
		add_child(_player_node)
	_player_node.position = _player_pos
	
	if _native_light_presentation == null:
		_native_light_presentation = NativeLightPresentation.new()
		add_child(_native_light_presentation)
	
	# Camera — attached to player so it follows movement
	if _camera == null:
		_camera = Camera2D.new()
		_camera.enabled = true
		_player_node.add_child(_camera)
	_camera.limit_left = int(ARENA_RECT.position.x)
	_camera.limit_top = int(ARENA_RECT.position.y)
	_camera.limit_right = int(ARENA_RECT.end.x)
	_camera.limit_bottom = int(ARENA_RECT.end.y)
	
	# HUD / overlay UI in screen space for resolution + fullscreen safety.
	if _hud_layer == null:
		_hud_layer = CanvasLayer.new()
		add_child(_hud_layer)
	
	if _hud_label == null:
		_hud_label = RichTextLabel.new()
		_hud_label.fit_content = true
		_hud_label.bbcode_enabled = true
		_hud_label.scroll_active = false
		_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud_label.position = Vector2(20, 20)
		_hud_label.size = Vector2(460, 220)
		_hud_layer.add_child(_hud_label)
	
	if _status_label == null:
		_status_label = RichTextLabel.new()
		_status_label.fit_content = true
		_status_label.bbcode_enabled = true
		_status_label.scroll_active = false
		_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_status_label.size = Vector2(420, 168)
		_hud_layer.add_child(_status_label)
	
	if _pause_panel == null:
		_pause_panel = PanelContainer.new()
		_pause_panel.visible = false
		_pause_panel.custom_minimum_size = Vector2(420, 136)
		_hud_layer.add_child(_pause_panel)
		var panel_vbox := VBoxContainer.new()
		panel_vbox.add_theme_constant_override("separation", 10)
		_pause_panel.add_child(panel_vbox)
		_pause_title_label = Label.new()
		_pause_title_label.text = "Exploration Paused"
		_pause_title_label.add_theme_font_size_override("font_size", 24)
		panel_vbox.add_child(_pause_title_label)
		_pause_body_label = Label.new()
		_pause_body_label.text = "ESC: resume\nEnter or M: return to main menu"
		_pause_body_label.add_theme_font_size_override("font_size", 18)
		panel_vbox.add_child(_pause_body_label)
	_set_pause_overlay_visible(_pause_open)

# --- Player movement (Milestone 2) ---

func _update_player(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
	
	var mouse_world := get_global_mouse_position()
	if mouse_world.distance_to(_player_pos) > 8.0:
		_facing = (mouse_world - _player_pos).normalized()
	
	if input_dir.length() > 0.0:
		input_dir = input_dir.normalized()
		var target_pos := LightLabCollision.resolve_circle_motion_in_space(
			_player_pos,
			PLAYER_RADIUS,
			input_dir * PLAYER_SPEED * delta,
			_collision_space()
		)
		_player_pos = _clamp_player_to_arena(target_pos)
		_player_node.position = _player_pos

func _update_hud() -> void:
	if _hud_label == null:
		return
	var pause_line := "[color=#8be9fd]ESC[/color] pause"
	if _pause_open:
		pause_line = "[color=#ffb86c]PAUSED[/color] — [color=#8be9fd]ESC[/color] resume | [color=#8be9fd]Enter/M[/color] main menu"
	var prism_entities := _light_world_prism_entities()
	var energized_stations := _active_prism_emitter_count(_prism_render_packet)
	_hud_label.text = "[b]%s[/b]\n[color=#a4b1cd]Mode:[/color] RandomGEN exploration | [color=#a4b1cd]Seed:[/color] %d | [color=#a4b1cd]World:[/color] %s\n[color=#a4b1cd]Player:[/color] (%.0f, %.0f) | [color=#a4b1cd]Light:[/color] %.2f | [color=#a4b1cd]Flashlight:[/color] %s\n[color=#a4b1cd]World geo:[/color] %d segments | %d patches | %d entities\n[color=#a4b1cd]Prisms:[/color] %d stations | %d energized | [color=#a4b1cd]Light cells:[/color] %d\n%s" % [
		SCENE_LABEL,
		world_seed,
		String(_light_world.metadata.get("world_type", "generated")) if _light_world != null else "generated",
		_player_pos.x,
		_player_pos.y,
		_sample_gameplay_light(_player_pos),
		("[color=#f1fa8c]ON[/color]" if _flashlight_on else "[color=#6272a4]OFF[/color]"),
		segment_count(),
		patch_count(),
		entity_count(),
		prism_entities.size(),
		energized_stations,
		_dead_alive_cells.size(),
		pause_line
	]
	if _status_label != null:
		_status_label.text = "[b]Exploration controls[/b]\nWASD / Arrows move | Mouse aim | [color=#8be9fd]F[/color] flashlight\n[color=#8be9fd]R[/color] next seed | [color=#8be9fd]T[/color] random seed | [color=#8be9fd]ESC[/color] pause/menu\n\n[b]Current mode goal[/b]\nTraverse the generated map, read material responses, and test shared light behavior in a playable shell.\n\n[b]Lighting status[/b]\nFlashlight uses shared render packets. Prism stations now react when energized by exploration light coverage."

# --- Public API ---

## Current world truth object.
func light_world() -> LightWorld:
	return _light_world

## Re-generate with a new seed.
func reroll(new_seed: int) -> void:
	world_seed = new_seed
	_boot_world()
	if _player_node != null:
		_player_node.position = _player_pos
	queue_redraw()
	print("[ExplorationScene] Rerolled — seed: %d  spawn: %s" % [world_seed, str(_provider.spawn_hint())])

func _toggle_pause_menu() -> void:
	_pause_open = not _pause_open
	_set_pause_overlay_visible(_pause_open)

func _return_to_main_menu() -> void:
	_pause_open = false
	_set_pause_overlay_visible(false)
	var err := get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
	if err != OK:
		push_warning("[ExplorationScene] Failed to return to main menu scene: %s (%d)" % [MAIN_MENU_SCENE_PATH, err])

## World metadata passthrough.
func world_metadata() -> Dictionary:
	if _light_world == null:
		return {}
	return _light_world.metadata.duplicate(true)

## Spawn hint from provider.
func spawn_hint() -> Vector2:
	if _provider == null:
		return Vector2.INF
	return _provider.spawn_hint()

## Number of occluder segments in the current world.
func segment_count() -> int:
	if _light_world == null:
		return 0
	return _light_world.occluder_segments.size()

## Number of material patches in the current world.
func patch_count() -> int:
	if _light_world == null:
		return 0
	return _light_world.material_patches.size()

## Number of light entities (prism stations, tree trunks, etc.).
func entity_count() -> int:
	if _light_world == null:
		return 0
	return _light_world.light_entities.size()

func _collision_space() -> Dictionary:
	if _light_world == null:
		return {"segments": [], "circles": []}
	return _light_world.collision_space()

func _clamp_player_to_arena(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, ARENA_RECT.position.x + PLAYER_RADIUS, ARENA_RECT.end.x - PLAYER_RADIUS),
		clampf(pos.y, ARENA_RECT.position.y + PLAYER_RADIUS, ARENA_RECT.end.y - PLAYER_RADIUS)
	)

func _find_valid_spawn(target: Vector2) -> Vector2:
	var candidate := _clamp_player_to_arena(target)
	var collision_space := _collision_space()
	if not LightLabCollision.is_circle_blocked_in_space(candidate, PLAYER_RADIUS, collision_space):
		return candidate
	for ring in range(1, 7):
		for step in range(16):
			var angle := TAU * float(step) / 16.0
			var probe := candidate + Vector2.RIGHT.rotated(angle) * float(ring) * 20.0
			probe = _clamp_player_to_arena(probe)
			if not LightLabCollision.is_circle_blocked_in_space(probe, PLAYER_RADIUS, collision_space):
				return probe
	return _clamp_player_to_arena(ARENA_RECT.get_center())

# --- Shared lighting runtime bootstrap (Milestone 3, minimal integration) ---

func _boot_shared_light_runtime() -> void:
	_gameplay_light_field = LightField.new(ARENA_RECT, LIGHT_CELL_SIZE, 1.25)
	_dead_alive_cells = DeadAliveGrid.build(ARENA_RECT, LIGHT_CELL_SIZE, _light_world.metadata_array("dead_alive_zones") if _light_world != null else [])
	_flashlight_render_packet = LightTypes.empty_render_packet("flashlight")
	_prism_render_packet = LightTypes.empty_render_packet("prism")
	_approx_flashlight_frontier = {}
	_approx_prism_frontiers = {}

func _flashlight_source_options() -> Dictionary:
	return {
		"source_type": "flashlight",
		"origin": _player_pos,
		"direction": _facing,
		"range": FLASHLIGHT_RANGE,
		"half_angle_deg": FLASHLIGHT_HALF_ANGLE,
		"center_intensity": 0.96,
		"edge_intensity": 0.42,
		"use_frontier_smoothing": true,
		"previous_frontier": _approx_flashlight_frontier,
		"source_anchor": _player_pos,
		"radial_emission": false
	}

func _rebuild_gameplay_light_field() -> void:
	if _gameplay_light_field == null:
		return
	_gameplay_light_field.clear_dynamic_light()
	if not _flashlight_on:
		_flashlight_render_packet = LightTypes.empty_render_packet("flashlight")
		_prism_render_packet = _build_exploration_prism_packet()
		_approx_flashlight_frontier = {}
		_write_packet_to_light_field(_prism_render_packet, 34.0, 28.0, 0.92, 0.72)
		return
	_flashlight_render_packet = FlashlightVisuals.build_render_packet(self, _flashlight_source_options())
	_approx_flashlight_frontier = _flashlight_render_packet.get("frontier", {})
	_prism_render_packet = _build_exploration_prism_packet()
	_write_packet_to_light_field(_flashlight_render_packet, 30.0, 24.0, 0.86, 0.62)
	_write_packet_to_light_field(_prism_render_packet, 34.0, 28.0, 0.92, 0.72)

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
	if _gameplay_light_field == null:
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
		var steps: int = max(1, int(ceil(length / max(_gameplay_light_field.cell_size * 0.75, 8.0))))
		for step in range(steps + 1):
			var t: float = float(step) / float(steps)
			var pos: Vector2 = a.lerp(b, t)
			var energy: float = clampf(float(segment.get("intensity", 0.0)) * scale, 0.0, 1.0)
			var eff_radius := radius
			if is_end_solid:
				var dist_to_b := pos.distance_to(b)
				if dist_to_b < radius:
					eff_radius = max(dist_to_b, 4.0)
			_gameplay_light_field.add_splat_world(pos, eff_radius, energy)
		if kind == "primary" and mat_id == "mirror":
			var hit_energy := clampf(float(segment.get("intensity", 0.0)) * primary_scale, 0.0, 1.0)
			_gameplay_light_field.add_splat_world(b, primary_radius * 1.2, hit_energy * 0.9)
		elif kind == "primary" and (mat_id == "glass" or mat_id == "wet"):
			var pass_energy := clampf(float(segment.get("intensity", 0.0)) * primary_scale, 0.0, 1.0)
			_gameplay_light_field.add_splat_world(b, primary_radius * 0.9, pass_energy * 0.65)
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
		_gameplay_light_field.add_splat_world(zone_pos, zone_radius, float(zone.get("strength", 0.0)))
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
			_gameplay_light_field.add_splat_world(centroid, primary_radius * 1.15, fill_strength)

func _sample_gameplay_light(pos: Vector2) -> float:
	if _gameplay_light_field == null:
		return 0.0
	return clampf(_gameplay_light_field.sample_world(pos), 0.0, 1.0)

func _prism_source_spec(origin: Vector2, direction: Vector2 = Vector2.RIGHT) -> Dictionary:
	return LightTypes.light_source_spec("prism", origin, direction, 1.0, 118.0, {
		"guide_rays": 16,
		"radial_emission": false
	})

func _light_world_prism_entities() -> Array:
	return _light_world.prism_emitters() if _light_world != null else []

func _prism_emitter_energized(pos: Vector2, radius: float) -> bool:
	for segment: Dictionary in _packet_segments(_flashlight_render_packet):
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
		var station_out_dir := (pos - _player_pos).normalized()
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
			"previous_frontier": _approx_prism_frontiers.get(station_key, {}),
			"source_anchor": pos,
			"radial_emission": false
		})
		accum_segments.append_array(station_packet.get("segments", []))
		accum_zones.append_array(station_packet.get("zones", []))
		accum_fills.append_array(station_packet.get("fills", []))
		_approx_prism_frontiers[station_key] = station_packet.get("frontier", {})
		accum_zones.append(LightTypes.render_zone(pos, maxf(24.0, radius * 1.35), 0.44, {
			"kind": "emitter_core",
			"source_type": "prism",
			"emitter_key": station_key
		}))
		prism_strengths[station_key] = 1.0
	return _build_combined_prism_packet(accum_segments, accum_zones, accum_fills, active_prism_keys, prism_strengths)

func _active_prism_emitter_count(packet: Dictionary) -> int:
	var strengths := Dictionary(packet.get("emitter_strengths", {}))
	var count := 0
	for key in strengths.keys():
		if float(strengths[key]) >= 0.95:
			count += 1
	return count

func _closest_point_on_segment(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var denom := maxf(ab.length_squared(), 0.0001)
	var t := clampf((point - a).dot(ab) / denom, 0.0, 1.0)
	return a + ab * t

func _layout_overlay_ui() -> void:
	var viewport_rect := get_viewport_rect()
	var viewport_size := viewport_rect.size
	if _hud_label != null:
		_hud_label.position = Vector2(20, 20)
		_hud_label.size = Vector2(minf(560.0, maxf(viewport_size.x - 40.0, 260.0)), 160)
	if _status_label != null:
		var status_width := minf(520.0, maxf(viewport_size.x - 40.0, 260.0))
		_status_label.size = Vector2(status_width, 150)
		_status_label.position = Vector2(20, maxf(190.0, viewport_size.y - _status_label.size.y - 20.0))
	if _pause_panel != null:
		var panel_size := _pause_panel.custom_minimum_size
		_pause_panel.position = viewport_rect.size * 0.5 - panel_size * 0.5
		_pause_panel.size = panel_size

func _set_pause_overlay_visible(visible: bool) -> void:
	if _pause_panel != null:
		_pause_panel.visible = visible

func _light_world_patches() -> Array:
	return _light_world.material_patches if _light_world != null else []

func _light_world_occluders() -> Array:
	return _light_world.occluder_segments if _light_world != null else []

func _light_world_tree_entities() -> Array:
	return _light_world.entity_list("tree_trunk") if _light_world != null else []

func _update_native_light_presentation() -> void:
	if _native_light_presentation == null:
		return
	_native_light_presentation.update_from_packets(
		_flashlight_render_packet,
		LightTypes.empty_render_packet("laser"),
		_prism_render_packet,
		_light_world.prism_emitters() if _light_world != null else [],
		null,
		_flashlight_on,
		_player_pos,
		_facing,
		_light_world,
		[]
	)

# --- Rendering (Milestone 2) ---

func _draw() -> void:
	if _light_world == null:
		return
	
	# Background
	var viewport_rect := get_viewport_rect()
	draw_rect(viewport_rect, Color(0.01, 0.015, 0.03, 1.0), true)
	draw_rect(ARENA_RECT.grow(28.0), Color(0.02, 0.04, 0.07, 0.88), true)
	draw_rect(ARENA_RECT, Color("111827"), true)
	
	# Grid overlay
	for x in range(int(ARENA_RECT.position.x) + 64, int(ARENA_RECT.end.x), 128):
		draw_line(Vector2(x, ARENA_RECT.position.y + 14), Vector2(x, ARENA_RECT.end.y - 14), Color(0.3, 0.42, 0.58, 0.08), 1.0)
	for y in range(int(ARENA_RECT.position.y) + 64, int(ARENA_RECT.end.y), 128):
		draw_line(Vector2(ARENA_RECT.position.x + 14, y), Vector2(ARENA_RECT.end.x - 14, y), Color(0.3, 0.42, 0.58, 0.08), 1.0)
	
	# Material patches
	for patch: Dictionary in _light_world.material_patches:
		var patch_rect: Rect2 = patch.get("rect", Rect2())
		var material_id := String(patch.get("material_id", "brick"))
		var color: Color = MATERIAL_COLORS.get(material_id, Color(0.5, 0.5, 0.5, 0.5))
		draw_rect(patch_rect, color, true)
		draw_rect(patch_rect, color.lightened(0.3), false, 2.0)
	
	# Occluder segments
	for segment: Dictionary in _light_world.occluder_segments:
		var a: Vector2 = segment.get("a", Vector2.ZERO)
		var b: Vector2 = segment.get("b", Vector2.ZERO)
		var material_id := String(segment.get("material_id", "brick"))
		var color: Color = MATERIAL_COLORS.get(material_id, Color(0.7, 0.7, 0.7, 0.9))
		draw_line(a, b, color, 4.0)
		draw_line(a, b, color.lightened(0.4), 2.0)
	
	# Light entities (tree trunks, prism stations)
	for entity: Dictionary in _light_world.light_entities:
		var kind := String(entity.get("kind", ""))
		var pos: Vector2 = entity.get("pos", Vector2.ZERO)
		var radius: float = float(entity.get("radius", 18.0))
		
		match kind:
			"tree_trunk":
				draw_circle(pos, radius, MATERIAL_COLORS.get("tree", Color(0.3, 0.25, 0.18, 0.9)))
				draw_circle(pos, radius - 4.0, Color(0.28, 0.22, 0.16, 1.0))
				draw_arc(pos, radius, 0.0, TAU, 24, Color(0.5, 0.4, 0.3, 0.6), 2.0)
			
			"prism_station":
				var prism_color := Color(0.54, 0.93, 1.0, 0.85)
				draw_circle(pos, radius + 8.0, Color(prism_color.r, prism_color.g, prism_color.b, 0.15))
				draw_circle(pos, radius, prism_color)
				draw_circle(pos, radius - 6.0, Color(1.0, 1.0, 1.0, 0.5))
				draw_arc(pos, radius, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, 0.7), 2.5)
	
	# Arena border
	draw_rect(ARENA_RECT, Color(0.46, 0.68, 0.95, 0.95), false, 6.0)
	draw_rect(ARENA_RECT.grow(-8.0), Color(0.76, 0.9, 1.0, 0.18), false, 2.0)
	
	# Player
	if _player_node != null:
		draw_circle(_player_pos, PLAYER_RADIUS, Color(0.95, 0.72, 0.25, 0.9))
		draw_circle(_player_pos, PLAYER_RADIUS - 4.0, Color(1.0, 0.85, 0.45, 1.0))
		draw_arc(_player_pos, PLAYER_RADIUS, 0.0, TAU, 16, Color(1.0, 0.95, 0.7, 0.95), 2.0)
