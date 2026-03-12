## MeadowGround – open grass/field ground terrain scene component.
##
## Represents the base terrain layer for a meadow biome zone.
## Exports zone geometry so the world builder can resize or reposition
## individual instances without touching the scene structure.
##
## Rendering: a Polygon2D child provides the visual fill.
## Occlusion: meadow ground does not occlude light — no occluder segments.
## Zone tag: "meadow" — used by the world builder for zone-aware content placement.
extends Node2D
class_name MeadowGround

## World-space rect covered by this ground patch.
## Set by the world builder after instantiation to match the generated layout.
@export var zone_rect: Rect2 = Rect2(Vector2(-3000.0, -3000.0), Vector2(6000.0, 6000.0))

## Zone identity tag — consumed by layout and entity-placement systems.
@export var zone_tag: String = "meadow"

@onready var _polygon: Polygon2D = $TerrainPolygon

func _ready() -> void:
	_sync_polygon()

## Resize the ground patch to match a new rect (called by world builder).
func apply_rect(rect: Rect2) -> void:
	zone_rect = rect
	_sync_polygon()

func _sync_polygon() -> void:
	if _polygon == null:
		return
	var r := zone_rect
	_polygon.polygon = PackedVector2Array([
		r.position,
		Vector2(r.end.x, r.position.y),
		r.end,
		Vector2(r.position.x, r.end.y)
	])
