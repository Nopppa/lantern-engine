## TreeBroadleaf – broadleaf tree scene component for the exploration world.
##
## Visual: canopy Polygon2D (dark green, octoagonal) + trunk Polygon2D (brown).
## Light pipeline: exports trunk_radius so the world builder can register a
## circular occluder at this node's world position — matching the "tree_trunk"
## entity kind used by GeneratedExplorationProvider.
##
## The occluder itself is NOT registered here; that is the world builder's
## responsibility (Plan → Build → Runtime boundary from TRUTH.md).
## This scene is the Runtime representation of a placed tree.
extends Node2D
class_name TreeBroadleaf

## Radius of the trunk circle used for light occlusion registration.
## Must match the radius the world builder wrote into the LightWorld entity.
@export var trunk_radius: float = 14.0

## Canopy display radius (visual only, no occlusion effect).
@export var canopy_radius: float = 40.0

@onready var _trunk: Polygon2D = $Trunk
@onready var _canopy: Polygon2D = $Canopy

func _ready() -> void:
	_sync_visuals()

## Rebuild polygons if exported values change at runtime (editor preview).
func _sync_visuals() -> void:
	if _trunk != null:
		_trunk.polygon = _rect_polygon(trunk_radius * 0.55, trunk_radius)

	if _canopy != null:
		_canopy.polygon = _circle_polygon(canopy_radius, 10)

## Build a roughly rectangular polygon (trunk shape).
static func _rect_polygon(half_w: float, half_h: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2( half_w, -half_h),
		Vector2( half_w,  half_h),
		Vector2(-half_w,  half_h)
	])

## Build an n-sided regular polygon approximating a circle.
static func _circle_polygon(radius: float, sides: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(sides)
	for i in sides:
		var angle := TAU * float(i) / float(sides)
		pts[i] = Vector2(cos(angle), sin(angle)) * radius
	return pts
