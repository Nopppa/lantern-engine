## ExplorationScene – RandomGEN exploration world runtime scaffold.
##
## First milestone implementation.
## Loads a generated LightWorld via GeneratedExplorationProvider and
## makes it available as the scene's world truth.  Movement, rendering, and
## gameplay loop come in later milestones.
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
const SCENE_LABEL := "Exploration World v0.1-scaffold"

## Seed used for this scene instance.  Change to explore different worlds.
@export var world_seed: int = 2001

var _provider: GeneratedExplorationProvider = null
var _light_world: LightWorld = null

# --- Lifecycle ---

func _ready() -> void:
	_boot_world()
	print("[ExplorationScene] %s booted — world_type: %s  seed: %d  spawn: %s" % [
		SCENE_LABEL,
		_light_world.metadata.get("world_type", "?"),
		world_seed,
		str(_provider.spawn_hint())
	])

# --- World initialisation ---

func _boot_world() -> void:
	_provider = GeneratedExplorationProvider.new(world_seed, ARENA_RECT)
	_light_world = _provider.build_world()
	_on_world_ready()

## Called once the LightWorld is ready.
## Subclasses or future milestones can override/extend here.
func _on_world_ready() -> void:
	pass  # Placeholder for movement, collision, light pipeline init.

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
