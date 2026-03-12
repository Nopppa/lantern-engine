## HouseSmall – minimal rural house scene for the exploration world.
##
## Represents a small farmhouse / cottage placed by the world builder.
## Visual: wall footprint Polygon2D (stone/plaster colour) + dark interior fill.
## Light pipeline: the four outer wall segments register as occluder segments
## in the LightWorld — this is done by the world builder, not here.
##
## Zone association: "settlement" — placed by world builder in settlement zones.
extends Node2D
class_name HouseSmall

## Footprint half-width (world units). Full width = 2 × this.
@export var half_width: float = 52.0

## Footprint half-height (world units). Full height = 2 × this.
@export var half_height: float = 38.0

## Wall thickness for the visual polygon ring.
@export var wall_thickness: float = 8.0

@onready var _interior: Polygon2D = $Interior
@onready var _walls: Polygon2D = $Walls

func _ready() -> void:
	_sync_visuals()

func _sync_visuals() -> void:
	if _interior != null:
		var iw := half_width - wall_thickness
		var ih := half_height - wall_thickness
		_interior.polygon = PackedVector2Array([
			Vector2(-iw, -ih), Vector2(iw, -ih),
			Vector2(iw,  ih), Vector2(-iw,  ih)
		])
	if _walls != null:
		_walls.polygon = PackedVector2Array([
			Vector2(-half_width, -half_height),
			Vector2( half_width, -half_height),
			Vector2( half_width,  half_height),
			Vector2(-half_width,  half_height)
		])
