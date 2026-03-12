extends Node2D

# Bootstrap router — owns exactly one active screen at a time.
# Do NOT put game logic here. Shell-layer only.

var _current_screen: Node = null

func _ready() -> void:
	show_main_menu()

func show_main_menu() -> void:
	_swap_screen("res://scenes/main_menu.tscn")

func start_light_lab() -> void:
	_swap_screen("res://scenes/light_lab_scene.tscn")

func start_random_gen_placeholder() -> void:
	_swap_screen("res://scenes/random_gen_placeholder.tscn")

func _swap_screen(scene_path: String) -> void:
	if _current_screen != null:
		_current_screen.queue_free()
		_current_screen = null
	var scene := load(scene_path) as PackedScene
	if scene == null:
		push_error("Main router: failed to load scene: " + scene_path)
		return
	_current_screen = scene.instantiate()
	add_child(_current_screen)
