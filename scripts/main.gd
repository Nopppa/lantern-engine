extends Node

const MAIN_MENU_SCENE := preload("res://scenes/main_menu.tscn")

@onready var _main_menu: Control = $MainMenu

func _ready() -> void:
	if _main_menu == null:
		_main_menu = MAIN_MENU_SCENE.instantiate()
		_main_menu.name = "MainMenu"
		add_child(_main_menu)

	if _main_menu.has_signal("launch_requested") and not _main_menu.launch_requested.is_connected(_on_launch_requested):
		_main_menu.launch_requested.connect(_on_launch_requested)

func _on_launch_requested(scene_path: String) -> void:
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_warning("[Main] Failed to load scene: %s (%d)" % [scene_path, err])
