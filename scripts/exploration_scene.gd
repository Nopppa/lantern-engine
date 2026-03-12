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
const NativeLightPresentation = preload("res://scripts/gameplay/native_light_presentation.gd")
const ExplorationLightRuntime = preload("res://scripts/exploration/exploration_light_runtime.gd")
const ExplorationOverlayUi = preload("res://scripts/exploration/exploration_overlay_ui.gd")

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
var _player_pos: Vector2 = Vector2.ZERO
var _facing: Vector2 = Vector2.RIGHT
var _flashlight_on := true
var _light_runtime: ExplorationLightRuntime = null
var _overlay_ui: ExplorationOverlayUi = null
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
	_setup_light_runtime()
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
	_player_pos = _find_valid_spawn(_player_pos)
	_light_runtime.reset(_light_world)
	_sync_light_runtime_state()

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
	
	if _overlay_ui == null:
		_overlay_ui = ExplorationOverlayUi.new()
		_overlay_ui.attach(self)
	_overlay_ui.set_pause_overlay_visible(_pause_open)

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

func _update_overlay_ui() -> void:
	if _overlay_ui == null:
		return
	var prism_entities := _light_world.prism_emitters() if _light_world != null else []
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
		"status_text": "[b]Exploration controls[/b]\nWASD / Arrows move | Mouse aim | [color=#8be9fd]F[/color] flashlight\n[color=#8be9fd]R[/color] next seed | [color=#8be9fd]T[/color] random seed | [color=#8be9fd]ESC[/color] pause/menu\n\n[b]Current mode goal[/b]\nTraverse the generated map, read material responses, and test shared light behavior in a playable shell.\n\n[b]Lighting status[/b]\nFlashlight uses shared render packets. Prism stations now react when energized by exploration light coverage."
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

# --- Shared lighting runtime bootstrap (Milestone 3, decomposed) ---

func _setup_light_runtime() -> void:
	_light_runtime = ExplorationLightRuntime.new()
	_light_runtime.configure({
		"arena_rect": ARENA_RECT,
		"light_cell_size": LIGHT_CELL_SIZE,
		"flashlight_range": FLASHLIGHT_RANGE,
		"flashlight_half_angle": FLASHLIGHT_HALF_ANGLE,
		"beam_offset": BEAM_OFFSET
	})

func _sync_light_runtime_state() -> void:
	if _light_runtime == null:
		return
	_light_runtime.sync_player_runtime(_player_pos, _facing, _flashlight_on)

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
