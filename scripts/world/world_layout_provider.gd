## WorldLayoutProvider – abstract base for world layout sources.
##
## Provides a unified interface for any system capable of producing a playable
## world layout (authored, procedural, biome-based, etc).
##
## The runtime interacts with the provider without caring how the world
## was created.
##
class_name WorldLayoutProvider
extends RefCounted


# ---------------------------------------------------------------------
# LAYOUT GENERATION
# ---------------------------------------------------------------------

## Return a layout dictionary describing the world geometry.
## Must be overridden by subclasses.
func build_static_layout(options: Dictionary = {}) -> Dictionary:
	push_error(
		"WorldLayoutProvider.build_static_layout: not implemented in "
		+ get_script().resource_path
	)
	return {}


# ---------------------------------------------------------------------
# LIGHTWORLD CONSTRUCTION
# ---------------------------------------------------------------------

## Build LightWorld runtime representation from layout data.
func build_light_world(layout: Dictionary, world_rect: Rect2, options: Dictionary = {}) -> LightWorld:
	var merged := _base_options().merged(options)

	return LightWorldBuilder.cached_from_layout(
		String(merged.get("cache_key", "world_layout_provider")),
		layout,
		world_rect,
		merged
	)


# ---------------------------------------------------------------------
# SPAWN HINT
# ---------------------------------------------------------------------

## Suggested player spawn position.
func spawn_hint() -> Vector2:
	return Vector2.INF


# ---------------------------------------------------------------------
# WORLD IDENTITY
# ---------------------------------------------------------------------

## Unique identifier for this world instance.
## Useful for save systems, debugging and caching.
func world_id() -> String:
	return "world_" + str(hash(metadata()))


# ---------------------------------------------------------------------
# METADATA
# ---------------------------------------------------------------------

## Describes the world provider configuration.
##
## Example:
## {
##   "world_type": "biome_generated_world",
##   "seed": 12345
## }
##
func metadata() -> Dictionary:
	return {}


# ---------------------------------------------------------------------
# REPRODUCIBLE STATE
# ---------------------------------------------------------------------

## Returns the minimal data required to recreate this provider.
##
## This is what should be stored in save files.
##
func reproducible_state() -> Dictionary:
	return {
		"type": get_class(),
		"metadata": metadata()
	}


# ---------------------------------------------------------------------
# FACTORY FROM SAVE STATE
# ---------------------------------------------------------------------

## Optional constructor helper for recreating providers from saved state.
##
## Subclasses may override this.
##
static func from_state(state: Dictionary) -> WorldLayoutProvider:
	push_error("WorldLayoutProvider.from_state not implemented")
	return null


# ---------------------------------------------------------------------
# BASE OPTIONS
# ---------------------------------------------------------------------

func _base_options() -> Dictionary:
	return {
		"world_type": "biome_generated_world",
		"ready_for_randomgen": true,
		"adapter": "world_layout_provider",
		"generation_model": "biome_layout"
	}
