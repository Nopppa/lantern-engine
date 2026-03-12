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
const LightTypes = preload("res://scripts/gameplay/light_types.gd")

# Arena rect matching RunScene / Light Lab for pipeline compatibility.
const ARENA_RECT := Rect2(Vector2(64, 64), Vector2(1152, 592))
const SCENE_LABEL := "Exploration World v0.2-milestone2"
const PLAYER_SPEED := 240.0
const PLAYER_RADIUS := 14.0

## Seed used for this scene instance.  Change to explore different worlds.
@export var world_seed: int = 2001

var _provider: GeneratedExplorationProvider = null
var _light_world: LightWorld = null
var _player_node: Node2D = null
var _camera: Camera2D = null
var _hud_layer: CanvasLayer = null
var _hud_label: Label = null
var _player_pos: Vector2 = Vector2.ZERO

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
	queue_redraw()
	print("[ExplorationScene] %s booted — world_type: %s  seed: %d  spawn: %s" % [
		SCENE_LABEL,
		_light_world.metadata.get("world_type", "?"),
		world_seed,
		str(_provider.spawn_hint())
	])

func _process(delta: float) -> void:
	_update_player(delta)
	_update_hud()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			reroll(world_seed + 1)
		elif event.keycode == KEY_T:
			reroll(randi())

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

# --- Scene setup (Milestone 2) ---

func _setup_scene() -> void:
	# Player node
	_player_node = Node2D.new()
	_player_node.name = "Player"
	_player_node.position = _player_pos
	add_child(_player_node)
	
	# Camera — attached to player so it follows movement
	_camera = Camera2D.new()
	_camera.enabled = true
	_player_node.add_child(_camera)
	
	# HUD
	_hud_layer = CanvasLayer.new()
	add_child(_hud_layer)
	
	_hud_label = Label.new()
	_hud_label.position = Vector2(20, 20)
	_hud_label.add_theme_font_size_override("font_size", 14)
	_hud_layer.add_child(_hud_label)

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
	
	if input_dir.length() > 0.0:
		input_dir = input_dir.normalized()
		_player_pos += input_dir * PLAYER_SPEED * delta
		_player_pos.x = clampf(_player_pos.x, ARENA_RECT.position.x + PLAYER_RADIUS, ARENA_RECT.end.x - PLAYER_RADIUS)
		_player_pos.y = clampf(_player_pos.y, ARENA_RECT.position.y + PLAYER_RADIUS, ARENA_RECT.end.y - PLAYER_RADIUS)
		_player_node.position = _player_pos

func _update_hud() -> void:
	if _hud_label == null:
		return
	_hud_label.text = "[%s]\nSeed: %d\nSegments: %d  |  Patches: %d  |  Entities: %d\nPlayer: (%.0f, %.0f)\n\nControls: WASD/Arrows = Move  |  R = Next Seed  |  T = Random Seed" % [
		SCENE_LABEL,
		world_seed,
		segment_count(),
		patch_count(),
		entity_count(),
		_player_pos.x,
		_player_pos.y
	]

# --- Public API ---

## Current world truth object.
func light_world() -> LightWorld:
	return _light_world

## Re-generate with a new seed.
func reroll(new_seed: int) -> void:
	world_seed = new_seed
	_boot_world()
	print("[ExplorationScene] Rerolled — seed: %d  spawn: %s" % [world_seed, str(_provider.spawn_hint())])

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
