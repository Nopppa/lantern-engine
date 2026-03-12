## ExplorationScene – biome-driven exploration world runtime scaffold.
##
## Milestone 2/3: Runtime integration with visual rendering and player movement.
## Loads a generated biome-world via GeneratedExplorationProvider and renders it
## with debug-first visualization while preserving the shared LightWorld pipeline.
##
## Design rules enforced here:
##   - Does NOT own lighting/material logic.
##   - Light Lab remains untouched.
##   - All world data flows through GeneratedExplorationProvider → LightWorldBuilder.
##   - The resulting LightWorld is the single world-truth object for this scene.
##   - Exploration scenes should feel like places (forest, meadow, street,
##     housing, industrial), not material test arenas.
##
extends Node2D
class_name ExplorationScene

const GeneratedExplorationProvider = preload("res://scripts/world/generated_exploration_provider.gd")
const PlayerScene = preload("res://scenes/player/player.tscn")
const LightTypes = preload("res://scripts/gameplay/light_types.gd")
const NativeLightPresentation = preload("res://scripts/gameplay/native_light_presentation.gd")
const ExplorationLightRuntime = preload("res://scripts/exploration/exploration_light_runtime.gd")
const ExplorationOverlayUi = preload("res://scripts/exploration/exploration_overlay_ui.gd")
const ExplorationPlayerController = preload("res://scripts/exploration/exploration_player_controller.gd")

# World rect kept compatible with current pipeline bootstrap.
const ARENA_RECT := Rect2(Vector2(-3000, -3000), Vector2(6000, 6000))
const SCENE_LABEL := "Exploration World v0.4-biome-layout"
const PLAYER_SPEED := 240.0
const PLAYER_RADIUS := 14.0
const LIGHT_CELL_SIZE := 32.0
const FLASHLIGHT_RANGE := 420.0
const FLASHLIGHT_HALF_ANGLE := 48.0
const BEAM_OFFSET := 4.0
const MAIN_MENU_SCENE_PATH := "res://scenes/main.tscn"

## Seed used for this scene instance. Change to explore different worlds.
@export var world_seed: int = 2001

var _provider: GeneratedExplorationProvider = null
var _light_world: LightWorld = null
var _player_node: Node2D = null
var _camera: Camera2D = null
var _player_pos: Vector2 = Vector2.ZERO
var _facing: Vector2 = Vector2.RIGHT
var _flashlight_on := true
var _light_runtime: ExplorationLightRuntime = null
var _overlay_ui: ExplorationOverlayUi = null
var _native_light_presentation: NativeLightPresentation = null
var _player_controller: ExplorationPlayerController = null
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

# Biome tint overlay for layout readability
const BIOME_TINTS := {
	"forest": Color(0.18, 0.33, 0.22, 0.10),
	"meadow": Color(0.30, 0.42, 0.20, 0.08),
	"street": Color(0.26, 0.26, 0.30, 0.10),
	"housing": Color(0.34, 0.28, 0.24, 0.10),
	"industrial": Color(0.22, 0.28, 0.34, 0.10)
}

# --- Lifecycle ---

func _ready() -> void:
	_setup_light_runtime()
	_setup_player_controller()
	_boot_world()
	_setup_scene()
	_overlay_ui.layout()
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

		if Input.is_action_just_pressed("cast_beam") and _light_runtime != null:
			_sync_light_runtime_state()
			_light_runtime.cast_beam(get_global_mouse_position())

		_sync_light_runtime_state()
		_light_runtime.process_frame(delta)
		_light_runtime.update_native_presentation(_native_light_presentation)

	_overlay_ui.layout()
	_update_overlay_ui()
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

	_player_controller.reset(_light_world)
	_player_pos = _player_controller.resolve_spawn(_player_pos)
	_light_runtime.reset(_light_world)
	_sync_light_runtime_state()

# --- Scene setup ---

func _setup_scene() -> void:
	if _player_node == null:
		_player_node = PlayerScene.instantiate()
		_player_node.name = "Player"
		add_child(_player_node)

	_player_node.position = _player_pos

	if _native_light_presentation == null:
		_native_light_presentation = NativeLightPresentation.new()
		add_child(_native_light_presentation)

	# Camera is part of the player scene; retrieve the existing node.
	if _camera == null:
		_camera = _player_node.get_node_or_null("Camera2D") as Camera2D
	if _camera == null:
		# Fallback: create manually (legacy path, should not be hit with player.tscn).
		_camera = Camera2D.new()
		_camera.enabled = true
		_player_node.add_child(_camera)

	_camera.limit_left = int(ARENA_RECT.position.x)
	_camera.limit_top = int(ARENA_RECT.position.y)
	_camera.limit_right = int(ARENA_RECT.end.x)
	_camera.limit_bottom = int(ARENA_RECT.end.y)

	# If player.tscn carries a Flashlight component, let it drive the runtime config.
	_apply_flashlight_from_player_scene()

	if _overlay_ui == null:
		_overlay_ui = ExplorationOverlayUi.new()
		_overlay_ui.attach(self)

	_overlay_ui.set_pause_overlay_visible(_pause_open)

# --- Player movement ---

func _update_player(delta: float) -> void:
	if _player_controller == null:
		return

	var player_state := _player_controller.step(_player_pos, _facing, get_global_mouse_position(), delta)
	_player_pos = Vector2(player_state.get("position", _player_pos))
	_facing = Vector2(player_state.get("facing", _facing))

	if _player_node != null:
		_player_node.position = _player_pos

func _update_overlay_ui() -> void:
	if _overlay_ui == null:
		return

	var prism_entities := _light_world.prism_emitters() if _light_world != null else []
	var biome_summary := _format_biome_summary()

	_overlay_ui.update_hud({
		"scene_label": SCENE_LABEL,
		"world_seed": world_seed,
		"world_type": String(_light_world.metadata.get("world_type", "generated")) if _light_world != null else "generated",
		"player_x": _player_pos.x,
		"player_y": _player_pos.y,
		"sample_light": _light_runtime.sample_gameplay_light(_player_pos) if _light_runtime != null else 0.0,
		"flashlight_status": ("[color=#f1fa8c]ON[/color]" if _flashlight_on else "[color=#6272a4]OFF[/color]"),
		"segment_count": segment_count(),
		"patch_count": patch_count(),
		"entity_count": entity_count(),
		"prism_station_count": prism_entities.size(),
		"energized_station_count": _light_runtime.active_prism_emitter_count() if _light_runtime != null else 0,
		"light_cell_count": _light_runtime.dead_alive_cell_count() if _light_runtime != null else 0,
		"pause_open": _pause_open,
		"status_text": "[b]Exploration controls[/b]\nWASD / Arrows move | Mouse aim | [color=#8be9fd]F[/color] flashlight | [color=#8be9fd]LMB[/color] beam\n[color=#8be9fd]R[/color] next seed | [color=#8be9fd]T[/color] random seed | [color=#8be9fd]ESC[/color] pause/menu\n\n[b]Current mode goal[/b]\nTraverse a biome-driven procedural world with calm spawn space, believable places, linked routes, and a deeper destination.\n\n[b]Biome graph[/b]\n%s\n\n[b]Lighting status[/b]\nFlashlight uses shared render packets. Beam segments reuse the shared resolver/presentation path, feed gameplay light, and can energize prism stations placed for route-reading and redirection.\nBeam: %s | segments: %d | active: %s | event: %s" % [
			biome_summary,
			("[color=#8be9fd]READY[/color]" if _light_runtime != null and _light_runtime.beam_ready() else "[color=#ffb86c]%.2fs[/color]" % (_light_runtime.beam_cooldown_remaining() if _light_runtime != null else 0.0)),
			(_light_runtime.beam_segment_count() if _light_runtime != null else 0),
			("yes" if _light_runtime != null and _light_runtime.beam_active() else "no"),
			(_light_runtime.last_event if _light_runtime != null else "")
		]
	})

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
	if _overlay_ui != null:
		_overlay_ui.set_pause_overlay_visible(_pause_open)

func _return_to_main_menu() -> void:
	_pause_open = false

	if _overlay_ui != null:
		_overlay_ui.set_pause_overlay_visible(false)

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

# --- Shared lighting runtime bootstrap ---

func _setup_light_runtime() -> void:
	_light_runtime = ExplorationLightRuntime.new()
	_light_runtime.configure({
		"arena_rect": ARENA_RECT,
		"light_cell_size": LIGHT_CELL_SIZE,
		"flashlight_range": FLASHLIGHT_RANGE,
		"flashlight_half_angle": FLASHLIGHT_HALF_ANGLE,
		"beam_offset": BEAM_OFFSET
	})

## Read Flashlight component from the instanced player scene and push its
## exported values into the light runtime.  Falls back silently if the
## Flashlight node is absent (legacy or headless test scenarios).
func _apply_flashlight_from_player_scene() -> void:
	if _player_node == null or _light_runtime == null:
		return
	var fl := _player_node.get_node_or_null("Flashlight")
	if fl == null:
		return
	# Only reconfigure if the scene values differ from the defaults already set.
	var scene_range: float = float(fl.get("beam_range") if fl.get("beam_range") != null else FLASHLIGHT_RANGE)
	var scene_angle: float = float(fl.get("half_angle_deg") if fl.get("half_angle_deg") != null else FLASHLIGHT_HALF_ANGLE)
	if is_equal_approx(scene_range, FLASHLIGHT_RANGE) and is_equal_approx(scene_angle, FLASHLIGHT_HALF_ANGLE):
		return  # Nothing to update.
	_light_runtime.configure({
		"arena_rect": ARENA_RECT,
		"light_cell_size": LIGHT_CELL_SIZE,
		"flashlight_range": scene_range,
		"flashlight_half_angle": scene_angle,
		"beam_offset": BEAM_OFFSET
	})

func _setup_player_controller() -> void:
	_player_controller = ExplorationPlayerController.new()
	_player_controller.configure({
		"arena_rect": ARENA_RECT,
		"player_radius": PLAYER_RADIUS,
		"player_speed": PLAYER_SPEED
	})

func _sync_light_runtime_state() -> void:
	if _light_runtime == null:
		return
	_light_runtime.sync_player_runtime(_player_pos, _facing, _flashlight_on)

# --- Rendering ---

func _draw() -> void:
	if _light_world == null:
		return

	var viewport_rect := get_viewport_rect()
	draw_rect(viewport_rect, Color(0.01, 0.015, 0.03, 1.0), true)
	draw_rect(ARENA_RECT.grow(28.0), Color(0.02, 0.04, 0.07, 0.88), true)
	draw_rect(ARENA_RECT, Color("111827"), true)

	# Grid overlay
	for x in range(int(ARENA_RECT.position.x) + 64, int(ARENA_RECT.end.x), 128):
		draw_line(
			Vector2(x, ARENA_RECT.position.y + 14),
			Vector2(x, ARENA_RECT.end.y - 14),
			Color(0.3, 0.42, 0.58, 0.08),
			1.0
		)
	for y in range(int(ARENA_RECT.position.y) + 64, int(ARENA_RECT.end.y), 128):
		draw_line(
			Vector2(ARENA_RECT.position.x + 14, y),
			Vector2(ARENA_RECT.end.x - 14, y),
			Color(0.3, 0.42, 0.58, 0.08),
			1.0
		)

	# Biome zone tint pass (readability only; not gameplay logic)
	var layout_nodes: Array = _light_world.metadata.get("layout_nodes", [])
	for node: Dictionary in layout_nodes:
		var rect: Rect2 = node.get("rect", Rect2())
		if rect.size == Vector2.ZERO:
			continue

		var biome := String(node.get("biome", ""))
		if biome == "":
			biome = String(node.get("theme", "")) # backward compatibility if older metadata sneaks in

		var tint: Color = BIOME_TINTS.get(biome, Color(1.0, 1.0, 1.0, 0.0))
		if tint.a > 0.0:
			draw_rect(rect, tint, true)
			draw_rect(rect, tint.lightened(0.3), false, 2.0)

	# Material patches
	for patch: Dictionary in _light_world.material_patches:
		var patch_rect: Rect2 = patch.get("rect", Rect2())
		var material_id := String(patch.get("material_id", "brick"))
		var color: Color = MATERIAL_COLORS.get(material_id, Color(0.5, 0.5, 0.5, 0.5))
		draw_rect(patch_rect, color, true)
		draw_rect(patch_rect, color.lightened(0.3), false, 2.0)

	# Corridor/link visualization
	var layout_links: Array = _light_world.metadata.get("layout_links", [])
	for link: Dictionary in layout_links:
		var points: Array = link.get("corridor_points", [])
		var route_kind := String(link.get("route_kind", "main"))
		var link_color := Color(0.72, 0.86, 1.0, 0.18) if route_kind == "main" else Color(0.62, 0.72, 0.82, 0.12)

		for i in range(points.size() - 1):
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			draw_line(a, b, link_color, 10.0)
			draw_line(a, b, link_color.lightened(0.2), 3.0)

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

	# Node centers and biome labels
	for node: Dictionary in layout_nodes:
		var center: Vector2 = node.get("center", Vector2.ZERO)
		var rect: Rect2 = node.get("rect", Rect2())
		var kind := String(node.get("kind", "zone"))
		var biome := String(node.get("biome", ""))
		if biome == "":
			biome = String(node.get("theme", ""))

		var node_color := Color(0.55, 0.95, 0.70, 0.9) if kind == "spawn" else Color(0.95, 0.72, 0.25, 0.85)
		if kind == "progression":
			node_color = Color(0.95, 0.50, 0.35, 0.92)

		draw_circle(center, 8.0, node_color)
		draw_circle(center, 12.0, Color(node_color.r, node_color.g, node_color.b, 0.20))

		if rect.size != Vector2.ZERO:
			var label_pos := rect.position + Vector2(10.0, 18.0)
			draw_string(
				ThemeDB.fallback_font,
				label_pos,
				("%s%s" % [biome.capitalize(), " (Exit)" if kind == "progression" else ""]),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				14,
				Color(0.92, 0.95, 1.0, 0.78)
			)

	# Arena border
	draw_rect(ARENA_RECT, Color(0.46, 0.68, 0.95, 0.95), false, 6.0)
	draw_rect(ARENA_RECT.grow(-8.0), Color(0.76, 0.9, 1.0, 0.18), false, 2.0)

	# Player
	if _player_node != null:
		draw_circle(_player_pos, PLAYER_RADIUS, Color(0.95, 0.72, 0.25, 0.9))
		draw_circle(_player_pos, PLAYER_RADIUS - 4.0, Color(1.0, 0.85, 0.45, 1.0))
		draw_arc(_player_pos, PLAYER_RADIUS, 0.0, TAU, 16, Color(1.0, 0.95, 0.7, 0.95), 2.0)

# --- Helpers ---

func _format_biome_summary() -> String:
	if _light_world == null:
		return "no world"

	var summaries: Array = _light_world.metadata.get("zone_summaries", [])
	if summaries.is_empty():
		return "no biome summary"

	var biome_names: Array[String] = []
	for summary: Dictionary in summaries:
		var biome := String(summary.get("biome", ""))
		if biome == "":
			biome = String(summary.get("theme", ""))
		if biome != "":
			biome_names.append(biome)

	if biome_names.is_empty():
		return "no biome summary"

	return " → ".join(biome_names)
