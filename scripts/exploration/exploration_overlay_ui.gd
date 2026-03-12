extends RefCounted
class_name ExplorationOverlayUi

const OVERLAY_SCENE := preload("res://scenes/ui/exploration_overlay.tscn")

var _host: Node = null
var _overlay_root: CanvasLayer = null
var _hud_label: RichTextLabel = null
var _status_label: RichTextLabel = null
var _pause_panel: PanelContainer = null
var _pause_title_label: Label = null
var _pause_body_label: Label = null

func attach(host: Node) -> void:
	_host = host
	_ensure_nodes()

func update_hud(data: Dictionary) -> void:
	if _hud_label == null:
		return
	var pause_open := bool(data.get("pause_open", false))
	var pause_line := "[color=#8be9fd]ESC[/color] pause"
	if pause_open:
		pause_line = "[color=#ffb86c]PAUSED[/color] — [color=#8be9fd]ESC[/color] resume | [color=#8be9fd]Enter/M[/color] main menu"
	_hud_label.text = "[b]%s[/b]\n[color=#a4b1cd]Mode:[/color] RandomGEN exploration | [color=#a4b1cd]Seed:[/color] %d | [color=#a4b1cd]World:[/color] %s\n[color=#a4b1cd]Player:[/color] (%.0f, %.0f) | [color=#a4b1cd]Light:[/color] %.2f | [color=#a4b1cd]Flashlight:[/color] %s\n[color=#a4b1cd]World geo:[/color] %d segments | %d patches | %d entities\n[color=#a4b1cd]Prisms:[/color] %d stations | %d energized | [color=#a4b1cd]Light cells:[/color] %d\n%s" % [
		String(data.get("scene_label", "Exploration")),
		int(data.get("world_seed", 0)),
		String(data.get("world_type", "generated")),
		float(data.get("player_x", 0.0)),
		float(data.get("player_y", 0.0)),
		float(data.get("sample_light", 0.0)),
		String(data.get("flashlight_status", "OFF")),
		int(data.get("segment_count", 0)),
		int(data.get("patch_count", 0)),
		int(data.get("entity_count", 0)),
		int(data.get("prism_station_count", 0)),
		int(data.get("energized_station_count", 0)),
		int(data.get("light_cell_count", 0)),
		pause_line
	]
	if _status_label != null:
		_status_label.text = String(data.get("status_text", ""))

func set_pause_overlay_visible(visible: bool) -> void:
	if _pause_panel != null:
		_pause_panel.visible = visible

func layout() -> void:
	if _host == null or _hud_label == null or _status_label == null or _pause_panel == null:
		return
	var viewport_size := _viewport_size()
	var margin := Vector2(20.0, 20.0)
	var hud_width := clampf(viewport_size.x * 0.36, 360.0, 460.0)
	var status_width := clampf(viewport_size.x * 0.33, 320.0, 420.0)
	var pause_width := clampf(viewport_size.x * 0.4, 320.0, 420.0)
	_hud_label.position = margin
	_hud_label.size = Vector2(hud_width, 220.0)
	_status_label.size = Vector2(status_width, 168.0)
	_status_label.position = Vector2(
		viewport_size.x - status_width - margin.x,
		viewport_size.y - _status_label.get_content_height() - margin.y
	)
	_pause_panel.custom_minimum_size = Vector2(pause_width, 136.0)
	_pause_panel.position = Vector2(
		0.5 * (viewport_size.x - pause_width),
		0.22 * viewport_size.y
	)

func _ensure_nodes() -> void:
	if _host == null:
		return
	if _overlay_root == null:
		_overlay_root = OVERLAY_SCENE.instantiate()
		_overlay_root.name = "ExplorationOverlayUi"
		_host.add_child(_overlay_root)
		_hud_label = _overlay_root.get_node("HudLabel") as RichTextLabel
		_status_label = _overlay_root.get_node("StatusLabel") as RichTextLabel
		_pause_panel = _overlay_root.get_node("PausePanel") as PanelContainer
		_pause_title_label = _overlay_root.get_node("PausePanel/VBox/PauseTitleLabel") as Label
		_pause_body_label = _overlay_root.get_node("PausePanel/VBox/PauseBodyLabel") as Label
		_apply_styles()

func _apply_styles() -> void:
	if _hud_label != null:
		_hud_label.add_theme_stylebox_override("normal", _make_panel_style(Color(0.05, 0.07, 0.11, 0.84), Color(0.36, 0.5, 0.7, 0.95), 2, 10))
		_hud_label.add_theme_constant_override("margin_left", 14)
		_hud_label.add_theme_constant_override("margin_top", 10)
		_hud_label.add_theme_constant_override("margin_right", 14)
		_hud_label.add_theme_constant_override("margin_bottom", 10)
	if _status_label != null:
		_status_label.add_theme_stylebox_override("normal", _make_panel_style(Color(0.04, 0.05, 0.09, 0.76), Color(0.27, 0.35, 0.52, 0.9), 2, 10))
		_status_label.add_theme_constant_override("margin_left", 12)
		_status_label.add_theme_constant_override("margin_top", 8)
		_status_label.add_theme_constant_override("margin_right", 12)
		_status_label.add_theme_constant_override("margin_bottom", 8)
	if _pause_panel != null:
		_pause_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.07, 0.11, 0.96), Color(0.95, 0.9, 0.55, 1.0), 3, 12))

func _make_panel_style(bg: Color, border: Color, border_width: int = 2, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style

func _viewport_size() -> Vector2:
	var viewport := _host.get_viewport() if _host != null else null
	if viewport == null:
		return Vector2(1280.0, 720.0)
	return viewport.get_visible_rect().size
