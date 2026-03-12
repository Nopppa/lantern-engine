## RoadSection – dirt road or stone path segment for the exploration world.
##
## Represents a single road segment placed by the world builder.
## Orientation: horizontal by default (length along X axis).
## The world builder sets position, rotation, and road_length to match the
## road graph edge it materialises.
##
## Zone tag: "road" — consumed by layout and entity-placement systems.
## No light occlusion: roads are open traversable surfaces.
extends Node2D
class_name RoadSection

## Length of the road segment (world units). Controls polygon width along X.
@export var road_length: float = 256.0

## Width of the road across its perpendicular axis.
@export var road_width: float = 64.0

## Visual material hint — "dirt" or "stone".
@export_enum("dirt", "stone") var surface: String = "dirt"

@onready var _polygon: Polygon2D = $RoadPolygon

func _ready() -> void:
	_sync_polygon()
	_sync_color()

## Resize this segment to new dimensions (called by world builder).
func apply_dimensions(length: float, width: float) -> void:
	road_length = length
	road_width = width
	_sync_polygon()

func _sync_polygon() -> void:
	if _polygon == null:
		return
	var hw := road_length * 0.5
	var hh := road_width * 0.5
	_polygon.polygon = PackedVector2Array([
		Vector2(-hw, -hh),
		Vector2( hw, -hh),
		Vector2( hw,  hh),
		Vector2(-hw,  hh)
	])

func _sync_color() -> void:
	if _polygon == null:
		return
	_polygon.color = Color(0.42, 0.34, 0.22, 1.0) if surface == "dirt" else Color(0.55, 0.52, 0.47, 1.0)
