extends CanvasLayer

# Main Menu — UI only. Calls up into the parent router for scene switching.

func _ready() -> void:
	pass

func _on_light_lab_pressed() -> void:
	_router().start_light_lab()

func _on_random_gen_pressed() -> void:
	_router().start_random_gen_placeholder()

func _router() -> Node:
	return get_parent()
