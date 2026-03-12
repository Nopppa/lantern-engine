extends CanvasLayer
## In-game pause overlay.
## Signals up to the game scene for main-menu navigation.
## Save is placeholder-only.

signal return_to_main_menu_requested
signal closed

const OVERLAY_COLOR   := Color(0.04, 0.05, 0.08, 0.82)
const PANEL_COLOR     := Color(0.10, 0.12, 0.16, 0.97)
const PANEL_BORDER    := Color(0.35, 0.55, 0.72, 0.55)
const TEXT_COLOR      := Color(0.88, 0.93, 1.00, 1.00)
const SUBTEXT_COLOR   := Color(0.52, 0.60, 0.72, 0.88)
const BTN_NORMAL      := Color(0.18, 0.22, 0.30, 1.00)
const BTN_HOVER       := Color(0.26, 0.38, 0.54, 1.00)
const BTN_SAVE        := Color(0.14, 0.30, 0.22, 1.00)
const BTN_MENU        := Color(0.32, 0.18, 0.18, 1.00)

var _panel: Panel

func _ready() -> void:
	layer = 128          # well above HUD
	visible = false
	# Must process even when the scene tree is paused so buttons remain interactive.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	# Dark full-screen backdrop
	var bg := ColorRect.new()
	bg.color = OVERLAY_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# Centered panel
	_panel = Panel.new()
	var panel_size := Vector2(360, 280)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.set_offset(SIDE_LEFT,   -panel_size.x * 0.5)
	_panel.set_offset(SIDE_RIGHT,   panel_size.x * 0.5)
	_panel.set_offset(SIDE_TOP,    -panel_size.y * 0.5)
	_panel.set_offset(SIDE_BOTTOM,  panel_size.y * 0.5)

	var style := StyleBoxFlat.new()
	style.bg_color       = PANEL_COLOR
	style.border_color   = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	# VBox inside panel
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	# Add inner margin via a MarginContainer
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top",    28)
	margin.add_theme_constant_override("margin_bottom", 28)
	margin.add_theme_constant_override("margin_left",   36)
	margin.add_theme_constant_override("margin_right",  36)
	margin.add_child(vbox)
	_panel.add_child(margin)

	# Title
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", TEXT_COLOR)
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", PANEL_BORDER)
	vbox.add_child(sep)

	# Resume
	vbox.add_child(_make_button("Resume", BTN_NORMAL, "_on_resume_pressed"))

	# Save (placeholder)
	var save_btn := _make_button("Save  [placeholder]", BTN_SAVE, "_on_save_pressed")
	vbox.add_child(save_btn)

	# Main Menu
	vbox.add_child(_make_button("Return to Main Menu", BTN_MENU, "_on_main_menu_pressed"))

	# ESC hint
	var hint := Label.new()
	hint.text = "Press ESC to resume"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", SUBTEXT_COLOR)
	hint.add_theme_font_size_override("font_size", 12)
	vbox.add_child(hint)

func _make_button(label_text: String, bg: Color, callback: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0, 44)

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = bg
	style_normal.set_corner_radius_all(5)
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = bg.lightened(0.18)
	style_hover.set_corner_radius_all(5)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)

	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = bg.darkened(0.12)
	style_pressed.set_corner_radius_all(5)
	btn.add_theme_stylebox_override("pressed", style_pressed)

	btn.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1.0))
	btn.add_theme_font_size_override("font_size", 15)

	btn.pressed.connect(Callable(self, callback))
	return btn

# ─── public API ───────────────────────────────────────────────

func open() -> void:
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()

# ─── button handlers ──────────────────────────────────────────

func _on_resume_pressed() -> void:
	close()

func _on_save_pressed() -> void:
	# Placeholder — no persistence yet.
	print("[IngameMenu] Save placeholder triggered (not yet implemented).")

func _on_main_menu_pressed() -> void:
	visible = false
	get_tree().paused = false
	return_to_main_menu_requested.emit()

# ─── ESC while overlay is open ────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
