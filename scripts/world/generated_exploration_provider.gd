## GeneratedExplorationProvider
##
## Produces procedurally-generated layouts for the exploration world.
## Reuses LightWorldBuilder.build_generated_light_lab_layout as the core
## generator so all material/occluder data aligns with the shared pipeline.
##
## This is the first scaffold implementation.  The layout shape is intentionally
## kept identical to what LightWorldBuilder already produces so the full lighting
## and material pipeline works without any changes to shared systems.
##
class_name GeneratedExplorationProvider
extends WorldLayoutProvider

const LightWorldBuilder = preload("res://scripts/gameplay/light_world_builder.gd")

var _seed: int
var _arena_rect: Rect2
var _last_layout: Dictionary = {}

func _init(seed_value: int, arena_rect: Rect2) -> void:
	_seed = seed_value
	_arena_rect = arena_rect

# --- WorldLayoutProvider interface ---

func build_static_layout(options: Dictionary = {}) -> Dictionary:
	_last_layout = LightWorldBuilder.build_generated_light_lab_layout(_arena_rect, _seed)
	return _last_layout

func spawn_hint() -> Vector2:
	if _last_layout.is_empty():
		# Generate silently so hint is always available.
		build_static_layout()
	var hint = _last_layout.get("spawn_hint", Vector2.INF)
	if hint is Vector2:
		return hint
	return Vector2.INF

func metadata() -> Dictionary:
	return {
		"world_type": "generated_exploration",
		"provider": "GeneratedExplorationProvider",
		"seed": _seed,
		"arena_rect": _arena_rect,
		"ready_for_randomgen": true
	}

func _base_options() -> Dictionary:
	return {
		"world_type": "generated_exploration",
		"cache_key": "generated_exploration_%d" % _seed,
		"ready_for_randomgen": true,
		"adapter": "generated_exploration_provider",
		"generated_seed": _seed
	}

# --- Convenience API ---

## Re-roll with a new seed.  Clears layout cache for this provider.
func reseed(new_seed: int) -> void:
	_seed = new_seed
	_last_layout = {}

## Build a LightWorld directly from the current seed (shorthand).
func build_world() -> LightWorld:
	var layout := build_static_layout()
	return build_light_world(layout, _arena_rect)

## Current seed value.
func current_seed() -> int:
	return _seed
