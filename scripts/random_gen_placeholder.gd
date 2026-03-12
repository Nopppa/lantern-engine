extends CanvasLayer

# Random Gen Placeholder — intentionally minimal. Not a real runtime.

func _ready() -> void:
	pass

func _on_back_pressed() -> void:
	_router().show_main_menu()

func _router() -> Node:
	return get_parent()
