extends Node2D

func _ready() -> void:
	var run := preload("res://scenes/run_scene.tscn").instantiate()
	add_child(run)
