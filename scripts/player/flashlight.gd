## Flashlight – player-attached light emitter component.
##
## Scene-first component for the player's flashlight.  Holds configuration
## values that drive ExplorationLightRuntime without owning any rendering
## logic itself (the light pipeline owns rendering).
##
## Usage:
##   Attach to the Flashlight node inside player.tscn.
##   ExplorationScene (or future PlayerController) reads exported properties
##   when setting up the light runtime.
extends Node2D
class_name Flashlight

## Maximum reach of the flashlight cone (world units).
@export var beam_range: float = 420.0

## Half-angle of the flashlight cone in degrees.
@export var half_angle_deg: float = 48.0

## Whether the flashlight starts enabled.
@export var enabled: bool = true

## Emitted when the flashlight is toggled on or off.
signal toggled(is_on: bool)

func _ready() -> void:
	pass

## Toggle the flashlight and emit the signal.
func toggle() -> void:
	enabled = not enabled
	toggled.emit(enabled)

## Turn the flashlight on.
func turn_on() -> void:
	if not enabled:
		enabled = true
		toggled.emit(true)

## Turn the flashlight off.
func turn_off() -> void:
	if enabled:
		enabled = false
		toggled.emit(false)
