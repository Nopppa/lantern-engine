## LightBeam – reusable presentation-side beam scene.
##
## Scene-first visible beam asset for shared gameplay/world use. This does not
## own beam solving; it only exposes a configurable visual representation that
## mode scenes can instance and drive.
extends Node2D
class_name LightBeam

@export var beam_length: float = 160.0:
	set(value):
		beam_length = maxf(value, 0.0)
		_update_visuals()

@export var beam_width: float = 8.0:
	set(value):
		beam_width = maxf(value, 1.0)
		_update_visuals()

@export var beam_color: Color = Color(0.545, 0.875, 1.0, 0.9):
	set(value):
		beam_color = value
		_update_visuals()

@export var glow_color: Color = Color(0.545, 0.875, 1.0, 0.28):
	set(value):
		glow_color = value
		_update_visuals()

@export var visible_beam: bool = true:
	set(value):
		visible_beam = value
		_update_visuals()

@onready var _glow_line: Line2D = $GlowLine
@onready var _beam_line: Line2D = $BeamLine
@onready var _source_marker: ColorRect = $SourceMarker
@onready var _impact_marker: ColorRect = $ImpactMarker

func _ready() -> void:
	_update_visuals()

func set_endpoints(start_point: Vector2, end_point: Vector2) -> void:
	global_position = start_point
	rotation = (end_point - start_point).angle()
	beam_length = start_point.distance_to(end_point)
	_update_visuals()

func _update_visuals() -> void:
	if not is_node_ready():
		return

	var end_point := Vector2(beam_length, 0.0)
	var marker_size := Vector2(beam_width * 1.5, beam_width * 1.5)

	_glow_line.visible = visible_beam
	_glow_line.default_color = glow_color
	_glow_line.width = beam_width * 2.4
	_glow_line.points = PackedVector2Array([Vector2.ZERO, end_point])

	_beam_line.visible = visible_beam
	_beam_line.default_color = beam_color
	_beam_line.width = beam_width
	_beam_line.points = PackedVector2Array([Vector2.ZERO, end_point])

	_source_marker.visible = visible_beam
	_source_marker.color = beam_color
	_source_marker.size = marker_size
	_source_marker.position = -0.5 * marker_size

	_impact_marker.visible = visible_beam
	_impact_marker.color = glow_color.lerp(beam_color, 0.55)
	_impact_marker.size = marker_size
	_impact_marker.position = end_point - 0.5 * marker_size
