extends Control
class_name MainMenu

signal launch_requested(scene_path: String)

const LIGHT_LAB_SCENE_PATH := "res://scenes/light_lab_scene.tscn"
const RUN_SCENE_PATH := "res://scenes/run_scene.tscn"
const EXPLORATION_SCENE_PATH := "res://scenes/exploration_scene.tscn"

@onready var _description_label: RichTextLabel = %DescriptionLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_setup_button(%ExplorationButton, EXPLORATION_SCENE_PATH, "Biome-driven RandomGEN exploration using the shared lighting runtime, pause overlay, and current world-layout experiments.")
	_setup_button(%LightLabButton, LIGHT_LAB_SCENE_PATH, "Author-facing light simulation sandbox for beam, material, and prism behavior validation.")
	_setup_button(%RunSceneButton, RUN_SCENE_PATH, "Combat/run-mode prototype scene with encounter and reward-loop gameplay.")
	
	%QuitButton.pressed.connect(_on_quit_pressed)
	%QuitButton.mouse_entered.connect(_set_description.bind("Close the application window."))
	%QuitButton.focus_entered.connect(_set_description.bind("Close the application window."))

	%ExplorationButton.grab_focus()
	_set_description("Biome-driven RandomGEN exploration using the shared lighting runtime, pause overlay, and current world-layout experiments.")

func _setup_button(button: Button, scene_path: String, description: String) -> void:
	if button == null:
		return
	button.pressed.connect(_on_scene_button_pressed.bind(scene_path))
	button.mouse_entered.connect(_set_description.bind(description))
	button.focus_entered.connect(_set_description.bind(description))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_quit_pressed()

func _on_scene_button_pressed(scene_path: String) -> void:
	launch_requested.emit(scene_path)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _set_description(text: String) -> void:
	if _description_label != null:
		_description_label.text = "[color=#c9d4ea]%s[/color]" % text
