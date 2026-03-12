## Player – top-level player entity for scene-first architecture.
##
## Owns exported configuration for movement and the child Flashlight
## component.  Movement and collision resolution remain in
## ExplorationPlayerController (a RefCounted) to keep this node thin.
##
## The Camera2D child is retrieved by the host scene (ExplorationScene) and
## configured to follow the arena bounds.
extends Node2D
class_name Player

## Movement speed in world units per second.
@export var speed: float = 240.0

## Collision radius used by ExplorationPlayerController.
@export var radius: float = 14.0

## Convenience accessor for the Flashlight child component.
var flashlight: Flashlight:
	get:
		return $Flashlight as Flashlight

func _ready() -> void:
	pass
