## WorldLayoutProvider – abstract base for world layout sources.
##
## Both authored and generated worlds implement this interface.
## The concrete object is handed to scenes/runtimes that need a LightWorld
## without caring whether the data came from a hand-crafted layout or a seed.
##
## Usage pattern:
##   var provider := GeneratedExplorationProvider.new(seed, arena_rect)
##   var layout   := provider.build_static_layout()
##   var world    := provider.build_light_world(layout, arena_rect)
##   var hint     := provider.spawn_hint()
##
class_name WorldLayoutProvider
extends RefCounted

## Return the raw layout dictionary compatible with LightWorldBuilder.
## Subclasses must override this.
func build_static_layout(options: Dictionary = {}) -> Dictionary:
	push_error("WorldLayoutProvider.build_static_layout: not implemented in " + get_script().resource_path)
	return {}

## Build a LightWorld from a previously-obtained layout dict.
## Default implementation delegates to LightWorldBuilder.cached_from_layout.
func build_light_world(layout: Dictionary, arena_rect: Rect2, options: Dictionary = {}) -> LightWorld:
	var merged := _base_options().merged(options)
	return LightWorldBuilder.cached_from_layout(
		String(merged.get("cache_key", "world_layout_provider")),
		layout,
		arena_rect,
		merged
	)

## Spawn position hint, or Vector2.INF if not available.
func spawn_hint() -> Vector2:
	return Vector2.INF

## Metadata dictionary for this provider (world_type, seed, etc).
func metadata() -> Dictionary:
	return {}

# Override in subclasses to inject provider-level options.
func _base_options() -> Dictionary:
	return {
		"world_type": "generated_layout",
		"ready_for_randomgen": true,
		"adapter": "world_layout_provider"
	}
