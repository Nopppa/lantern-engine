extends RunScene
class_name LightLabScene

const LightMaterials = preload("res://scripts/data/light_materials.gd")
const DeadAliveGrid = preload("res://scripts/gameplay/dead_alive_grid.gd")
const LightSurfaceResolver = preload("res://scripts/gameplay/light_surface_resolver.gd")
const BossController = preload("res://scripts/gameplay/boss_controller.gd")

const LAB_LABEL := "Light Lab v0.5.0"
const CELL_SIZE := 32.0
const PROBE_RADIUS := 18.0

var surface_segments: Array = []
var surface_patches: Array = []
var prism_stations: Array = []
var diffuse_zones: Array = []
var dead_alive_cells: Array = []
var beam_debug_hits: Array = []
var beam_debug_enabled := true
var hp_overhead_enabled := true
var cursor_probe_enabled := true
var base_alive_flip := false

func _ready() -> void:
	randomize()
	_apply_skill_defaults()
	_setup_scene()
	player_pos = Vector2(228, 576)
	player_node.position = player_pos
	beam_range = 520.0
	beam_bounces = 4
	beam_damage = 22.0
	flashlight_on = true
	flashlight_range = 360.0
	flashlight_half_angle = 30.0
	last_event = "Light Lab booted — no auto waves, use debug spawn keys"
	_build_light_lab()
	_update_ui()

func _build_light_lab() -> void:
	surface_segments = []
	surface_patches = []
	prism_stations = []
	dead_alive_cells = DeadAliveGrid.build(ARENA_RECT, CELL_SIZE, [
		{"rect": Rect2(Vector2(128, 136), Vector2(192, 128)), "value": 1.0},
		{"rect": Rect2(Vector2(752, 152), Vector2(168, 120)), "value": 0.55 if not base_alive_flip else 1.0}
	])
	_add_outer_wall(Vector2(64, 64), Vector2(1216, 64), Vector2.DOWN, "brick")
	_add_outer_wall(Vector2(1216, 64), Vector2(1216, 656), Vector2.LEFT, "brick")
	_add_outer_wall(Vector2(1216, 656), Vector2(64, 656), Vector2.UP, "brick")
	_add_outer_wall(Vector2(64, 656), Vector2(64, 64), Vector2.RIGHT, "brick")
	_add_surface_patch(Rect2(Vector2(120, 96), Vector2(200, 150)), "brick", "Brick absorption bay")
	_add_surface_patch(Rect2(Vector2(356, 96), Vector2(170, 150)), "wood", "Wood diffusion bay")
	_add_surface_patch(Rect2(Vector2(580, 96), Vector2(170, 150)), "wet", "Wet reflection bay")
	_add_surface_patch(Rect2(Vector2(806, 96), Vector2(150, 150)), "mirror", "Mirror routing bay")
	_add_surface_patch(Rect2(Vector2(1012, 96), Vector2(150, 150)), "glass", "Glass transmission bay")
	_add_surface_patch(Rect2(Vector2(124, 438), Vector2(252, 140)), "brick", "Dead/alive fade lane")
	_add_surface_patch(Rect2(Vector2(744, 436), Vector2(288, 160)), "wet", "Open validation deck")
	_add_surface_segment(Vector2(148, 282), Vector2(334, 282), Vector2.DOWN, "brick")
	_add_surface_segment(Vector2(400, 300), Vector2(400, 520), Vector2.RIGHT, "wood")
	_add_surface_segment(Vector2(510, 404), Vector2(660, 404), Vector2.UP, "wet")
	_add_surface_segment(Vector2(840, 314), Vector2(980, 314), Vector2.DOWN, "mirror")
	_add_surface_segment(Vector2(1048, 306), Vector2(1048, 520), Vector2.LEFT, "glass")
	_add_surface_segment(Vector2(698, 280), Vector2(698, 580), Vector2.RIGHT, "brick")
	prism_stations.append({"pos": Vector2(1138, 480), "radius": 26.0, "label": "Prism station"})

func _add_outer_wall(a: Vector2, b: Vector2, normal: Vector2, material_id: String) -> void:
	_add_surface_segment(a, b, normal, material_id)

func _add_surface_segment(a: Vector2, b: Vector2, normal: Vector2, material_id: String) -> void:
	surface_segments.append({"a": a, "b": b, "normal": normal, "material_id": material_id})

func _add_surface_patch(rect: Rect2, material_id: String, label: String) -> void:
	surface_patches.append({"rect": rect, "material_id": material_id, "label": label})

func _input(event: InputEvent) -> void:
	DebugActions.handle_key_input(self, event)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:
				_spawn_debug_enemy("moth")
			KEY_2:
				_spawn_debug_enemy("hollow")
			KEY_3:
				_spawn_debug_enemy("boss_hollow_matriarch")
			KEY_4:
				_place_prism(get_global_mouse_position())
			KEY_5:
				cursor_probe_enabled = !cursor_probe_enabled
				last_event = "Cursor probe %s" % ("ON" if cursor_probe_enabled else "OFF")
			KEY_6:
				beam_debug_enabled = !beam_debug_enabled
				last_event = "Beam debug %s" % ("ON" if beam_debug_enabled else "OFF")
			KEY_7:
				hp_overhead_enabled = !hp_overhead_enabled
				last_event = "Enemy HP overlay %s" % ("ON" if hp_overhead_enabled else "OFF")
			KEY_8:
				base_alive_flip = !base_alive_flip
				_build_light_lab()
				last_event = "Dead/alive base zones toggled"

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quick_refill"):
		DebugActions.quick_refill(self)
	if Input.is_action_just_pressed("restart_run"):
		_restart_lab()
	beam_timer = max(beam_timer - delta, 0.0)
	prism_timer = max(prism_timer - delta, 0.0)
	prism_surge_timer = max(prism_surge_timer - delta, 0.0)
	beam_flash = max(beam_flash - delta * 4.5, 0.0)
	beam_pulse_timer = max(beam_pulse_timer - delta, 0.0)
	_update_hit_flashes(delta)
	if beam_pulse_timer <= 0.0 and not beam_segments.is_empty():
		beam_segments.clear()
		beam_debug_hits.clear()
	diffuse_zones.clear()
	energy = min(max_energy, energy + energy_regen * delta)
	if prism_node and prism_timer <= 0.0:
		prism_node.queue_free()
		prism_node = null
	_handle_player(delta)
	EnemyController.update_enemies(self, delta)
	DeadAliveGrid.update(dead_alive_cells, delta, Callable(self, "_light_intensity_at"))
	lit_zones = _build_lit_zones()
	_update_ui()
	queue_redraw()

func _handle_player(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_velocity = input * player_speed
	if input.length() > 0.1:
		facing = input.normalized()
	player_pos += player_velocity * delta
	player_pos.x = clamp(player_pos.x, ARENA_RECT.position.x + PLAYER_RADIUS, ARENA_RECT.end.x - PLAYER_RADIUS)
	player_pos.y = clamp(player_pos.y, ARENA_RECT.position.y + PLAYER_RADIUS, ARENA_RECT.end.y - PLAYER_RADIUS)
	player_node.position = player_pos
	var mouse_world := get_global_mouse_position()
	if (mouse_world - player_pos).length() > 8.0:
		facing = (mouse_world - player_pos).normalized()
	if Input.is_action_just_pressed("toggle_flashlight"):
		_toggle_flashlight()
	if flashlight_on:
		energy -= flashlight_drain * delta
		if energy <= 0.0:
			energy = 0.0
			flashlight_on = false
			last_event = "Flashlight off — no energy"
	if Input.is_action_just_pressed("cast_beam"):
		LightSurfaceResolver.cast_beam(self, mouse_world)
	if Input.is_action_just_pressed("place_prism"):
		_place_prism(mouse_world)
	if Input.is_action_just_pressed("cast_prism_surge"):
		_cast_prism_surge()
	if prism_node:
		prism_node.position = prism_node.position.clamp(ARENA_RECT.position + Vector2(24, 24), ARENA_RECT.end - Vector2(24, 24))

func _restart_lab() -> void:
	for enemy: Dictionary in enemies:
		if is_instance_valid(enemy.get("node", null)):
			enemy["node"].queue_free()
	enemies.clear()
	boss_projectiles.clear()
	beam_segments.clear()
	beam_debug_hits.clear()
	diffuse_zones.clear()
	player_hp = player_max_hp
	energy = max_energy
	player_pos = Vector2(228, 576)
	player_node.position = player_pos
	if prism_node:
		prism_node.queue_free()
		prism_node = null
	prism_timer = 0.0
	beam_timer = 0.0
	prism_surge_timer = 0.0
	flashlight_on = true
	_build_light_lab()
	last_event = "Light Lab reset"

func _spawn_debug_enemy(type: String) -> void:
	var pos := get_global_mouse_position().clamp(ARENA_RECT.position + Vector2(32, 32), ARENA_RECT.end - Vector2(32, 32))
	if type == "boss_hollow_matriarch":
		BossController.spawn_boss(self, "hollow_matriarch", pos)
	else:
		EncounterController.spawn_enemy(self, type, pos)
	last_event = "Spawned %s" % type

func _flashlight_intensity(source_pos: Vector2, source_facing: Vector2, target: Vector2, max_range: float, half_angle_deg: float, base_intensity: float) -> float:
	var to_target := target - source_pos
	var distance := to_target.length()
	if distance <= 0.001 or distance > max_range:
		return 0.0
	var dir := to_target / distance
	var angle_ratio: float = absf(rad_to_deg(source_facing.angle_to(dir))) / max(half_angle_deg, 0.001)
	if angle_ratio > 1.0:
		return 0.0
	var center_weight: float = pow(max(0.0, 1.0 - angle_ratio), 1.65)
	var distance_weight: float = pow(max(0.0, 1.0 - distance / max_range), 1.35)
	return clampf(base_intensity * center_weight * distance_weight, 0.0, 1.0)

func _segment_intensity(a: Vector2, b: Vector2, point: Vector2, radius: float, strength: float) -> float:
	var ab := b - a
	var t := clampf((point - a).dot(ab) / max(ab.length_squared(), 0.001), 0.0, 1.0)
	var closest := a + ab * t
	var distance := closest.distance_to(point)
	if distance > radius:
		return 0.0
	var dist_weight: float = 1.0 - distance / max(radius, 0.001)
	var along_weight: float = 0.78 + 0.22 * (1.0 - absf(t - 0.5) * 2.0)
	return clampf(strength * dist_weight * along_weight, 0.0, 1.0)

func _radial_intensity(origin: Vector2, point: Vector2, radius: float, strength: float) -> float:
	var distance := origin.distance_to(point)
	if distance > radius:
		return 0.0
	return clampf(strength * pow(1.0 - distance / max(radius, 0.001), 1.25), 0.0, 1.0)

func _light_intensity_at(pos: Vector2) -> float:
	var intensity := _flashlight_intensity(player_pos, facing, pos, flashlight_range, flashlight_half_angle, 1.0 if flashlight_on else 0.0)
	for segment: Dictionary in beam_segments:
		intensity = max(intensity, _segment_intensity(segment["a"], segment["b"], pos, 42.0, float(segment["intensity"])))
	for diffuse: Dictionary in diffuse_zones:
		intensity = max(intensity, _radial_intensity(diffuse["pos"], pos, diffuse["radius"], diffuse["strength"]))
	for prism_station: Dictionary in prism_stations:
		intensity = max(intensity, _radial_intensity(prism_station["pos"], pos, 58.0, 0.42))
	if prism_node:
		intensity = max(intensity, _radial_intensity(prism_node.position, pos, 92.0, 0.66))
	return clampf(intensity, 0.0, 1.0)

func _is_in_flashlight_cone(pos: Vector2) -> bool:
	return _light_intensity_at(pos) > 0.14 and flashlight_on

func _is_in_prism_light(pos: Vector2) -> bool:
	if prism_node and prism_node.position.distance_to(pos) <= 92.0:
		return true
	for prism_station: Dictionary in prism_stations:
		if prism_station["pos"].distance_to(pos) <= 58.0:
			return true
	return false

func _is_in_beam_light(pos: Vector2) -> bool:
	for segment: Dictionary in beam_segments:
		if _segment_intensity(segment["a"], segment["b"], pos, 34.0, float(segment["intensity"])) > 0.12:
			return true
	return false

func _light_state_for_position(pos: Vector2) -> Dictionary:
	var intensity := _light_intensity_at(pos)
	return {
		"flashlight": flashlight_on and _flashlight_intensity(player_pos, facing, pos, flashlight_range, flashlight_half_angle, 1.0) > 0.12,
		"prism": _is_in_prism_light(pos),
		"beam": _is_in_beam_light(pos),
		"honest": intensity > 0.12,
		"intensity": intensity
	}

func _build_lit_zones() -> Array:
	var zones: Array = []
	if flashlight_on:
		zones.append({"pos": player_pos + facing * 110.0, "radius": 160.0, "color": Color(1.0, 0.95, 0.72, 0.08)})
	for segment: Dictionary in beam_segments:
		zones.append({"pos": Vector2(segment["a"]).lerp(Vector2(segment["b"]), 0.5), "radius": max(Vector2(segment["a"]).distance_to(Vector2(segment["b"])) * 0.32, 64.0), "color": Color(0.55, 0.92, 1.0, 0.08 * float(segment["intensity"]))})
	for diffuse: Dictionary in diffuse_zones:
		zones.append({"pos": diffuse["pos"], "radius": diffuse["radius"], "color": Color(1.0, 0.92, 0.72, 0.05 * float(diffuse["strength"]) + 0.02)})
	if prism_node:
		zones.append({"pos": prism_node.position, "radius": 92.0, "color": Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.08)})
	for prism_station: Dictionary in prism_stations:
		zones.append({"pos": prism_station["pos"], "radius": 58.0, "color": Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.06)})
	return zones

func _update_ui() -> void:
	var mouse_world := get_global_mouse_position()
	var material := _material_under_cursor(mouse_world)
	var mat_name := String(material.get("label", "Floor"))
	var intensity := _light_intensity_at(mouse_world)
	var beam_ready := "[color=#8be9fd]READY[/color]" if beam_timer <= 0.0 else "[color=#ffb86c]%.2fs[/color]" % beam_timer
	var prism_state := "[color=#8be9fd]ACTIVE %.1fs[/color]" % prism_timer if prism_node else ("[color=#ffb86c]%.1fs[/color]" % prism_timer if prism_timer > 0.0 else "[color=#50fa7b]READY[/color]")
	var surge_state := "[color=#8be9fd]READY[/color]" if prism_surge_timer <= 0.0 else "[color=#ffb86c]%.1fs[/color]" % prism_surge_timer
	var immortal_text := "[color=#50fa7b]ON[/color]" if debug_immortal else "[color=#6272a4]OFF[/color]"
	hud_label.text = "[b]Lantern Engine — %s[/b]\n[color=#a4b1cd]Mode:[/color] Permanent validation map (no auto encounters)\n[color=#a4b1cd]Goal:[/color] Test flashlight, beam routing, surfaces, and dead/alive blend\n\n[color=#ff6b6b]HP[/color] %.0f / %.0f %s\n[color=#8be9fd]EN[/color] %.0f / %.0f %s\n\n[color=#f1fa8c]Beam[/color] %.0f dmg | %.0f range | %d beam branches\n[color=#f1fa8c]Flashlight[/color] %.0f range | %d° half-angle | [color=#a4b1cd]F[/color] %s\n[color=#f1fa8c]Prism[/color] station + manual node | [color=#a4b1cd]RMB[/color] %s | [color=#a4b1cd]Q[/color] %s\n[color=#a4b1cd]Cursor:[/color] %s | [color=#a4b1cd]Light:[/color] %.2f | [color=#a4b1cd]Immortal:[/color] %s" % [LAB_LABEL, player_hp, player_max_hp, HudText.bar(player_hp, player_max_hp), energy, max_energy, HudText.bar(energy, max_energy), beam_damage, beam_range, beam_bounces, flashlight_range, int(flashlight_half_angle), ("[color=#f1fa8c]ON[/color]" if flashlight_on else "[color=#6272a4]OFF[/color]"), prism_state, surge_state, mat_name, intensity, immortal_text]
	status_label.visible = true
	status_label.text = "[b]Light Lab controls[/b]\nWASD move | LMB beam | RMB prism | Q Prism Surge | F flashlight\n1 Moth | 2 Hollow | 3 Matriarch | 4 Prism at cursor\n5 cursor probe | 6 beam debug | 7 HP labels | 8 base alive toggle\nF1 help | F2 refill | F4 immortal\n\n[b]Authored bays[/b]\nBrick absorb | Wood diffuse | Wet reflect | Mirror bounce | Glass transmit | Prism routing | Dead/alive fade lane | Open spawn deck\n\n[b]Event[/b]\n%s" % last_event

func _material_under_cursor(pos: Vector2) -> Dictionary:
	for patch: Dictionary in surface_patches:
		if Rect2(patch["rect"]).has_point(pos):
			var mat := LightMaterials.get_definition(patch["material_id"])
			mat["source_label"] = patch["label"]
			return mat
	var nearest := {}
	var nearest_dist := 20.0
	for surface: Dictionary in surface_segments:
		var a: Vector2 = surface["a"]
		var b: Vector2 = surface["b"]
		var ab := b - a
		var t := clampf((pos - a).dot(ab) / max(ab.length_squared(), 0.001), 0.0, 1.0)
		var closest := a + ab * t
		var dist := closest.distance_to(pos)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = LightMaterials.get_definition(surface["material_id"])
	return nearest

func _draw() -> void:
	draw_rect(get_viewport_rect(), Color(0.01, 0.015, 0.03, 1.0), true)
	draw_rect(ARENA_RECT.grow(28.0), Color(0.03, 0.05, 0.08, 0.92), true)
	draw_rect(ARENA_RECT, Color(0.08, 0.09, 0.12, 1.0), true)
	for cell: Dictionary in dead_alive_cells:
		var rect: Rect2 = cell["rect"]
		var blend: float = float(cell["display"])
		var dead_color := Color(0.17, 0.19, 0.22, 1.0)
		var alive_color := Color(0.28, 0.46, 0.31, 1.0)
		draw_rect(rect, dead_color, true)
		if blend > 0.01:
			draw_rect(rect, Color(alive_color.r, alive_color.g, alive_color.b, blend * 0.95), true)
	for patch: Dictionary in surface_patches:
		var mat := LightMaterials.get_definition(patch["material_id"])
		draw_rect(patch["rect"], Color(mat["color"].r, mat["color"].g, mat["color"].b, 0.82), true)
	for zone: Dictionary in lit_zones:
		draw_circle(zone["pos"], zone["radius"], zone["color"])
	for flash: Dictionary in hit_flashes:
		var flash_t := clampf(float(flash["timer"]) / float(flash["duration"]), 0.0, 1.0)
		var flash_radius := lerpf(float(flash["radius"]) * 1.55, float(flash["radius"]) * 0.72, 1.0 - flash_t)
		var flash_color: Color = flash["color"]
		draw_circle(flash["pos"], flash_radius, Color(flash_color.r, flash_color.g, flash_color.b, 0.12 * flash_t))
	for surface: Dictionary in surface_segments:
		var mat := LightMaterials.get_definition(surface["material_id"])
		draw_line(surface["a"], surface["b"], mat["color"], 10.0)
		draw_line(surface["a"], surface["b"], Color(1, 1, 1, 0.12), 2.0)
	for prism_station: Dictionary in prism_stations:
		draw_circle(prism_station["pos"], 26.0, Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.18))
		draw_arc(prism_station["pos"], 26.0, 0.0, TAU, 24, PRISM_COLOR, 3.0)
	if flashlight_on:
		var cone_angle := deg_to_rad(flashlight_half_angle)
		var base_angle := facing.angle()
		var cone_segments := 28
		var cone_points := PackedVector2Array([player_pos])
		for ci in range(cone_segments + 1):
			var t_angle := base_angle - cone_angle + (2.0 * cone_angle) * (float(ci) / float(cone_segments))
			cone_points.append(player_pos + Vector2(cos(t_angle), sin(t_angle)) * flashlight_range)
		var colors := PackedColorArray()
		for point in cone_points:
			var dist_ratio: float = player_pos.distance_to(point) / max(flashlight_range, 1.0)
			colors.append(Color(1.0, 0.96, 0.74, 0.18 * (1.0 - dist_ratio * 0.6)))
		draw_polygon(cone_points, colors)
	for segment: Dictionary in beam_segments:
		var a: Vector2 = segment["a"]
		var b: Vector2 = segment["b"]
		var alpha := clampf(float(segment["intensity"]), 0.12, 1.0)
		draw_line(a, b, Color(0.48, 0.92, 1.0, 0.18 * alpha), 20.0)
		draw_line(a, b, Color(0.55, 0.95, 1.0, 0.42 * alpha), 10.0)
		draw_line(a, b, Color(1.0, 0.96, 0.76, 0.88 * alpha), 4.0)
	for diffuse: Dictionary in diffuse_zones:
		var mat := LightMaterials.get_definition(diffuse["material_id"])
		draw_circle(diffuse["pos"], diffuse["radius"], Color(mat["alive_color"].r, mat["alive_color"].g, mat["alive_color"].b, 0.08 * float(diffuse["strength"])))
	if beam_debug_enabled:
		for hit: Dictionary in beam_debug_hits:
			draw_circle(hit["point"], 8.0, Color(0.9, 1.0, 1.0, 0.4))
	for enemy: Dictionary in enemies:
		if not is_instance_valid(enemy["node"]):
			continue
		var color: Color = Color("ffb86c") if enemy["type"] == "moth" else (Color("ff4fd8") if enemy["type"] == "boss_hollow_matriarch" else Color("bd93f9"))
		draw_circle(enemy["node"].position, enemy["radius"] + 7.0, Color(color.r, color.g, color.b, 0.15))
		draw_circle(enemy["node"].position, enemy["radius"], color)
		if hp_overhead_enabled:
			draw_string(ThemeDB.fallback_font, enemy["node"].position + Vector2(-28, -24), "%d/%d" % [int(ceil(float(enemy["hp"]))), int(ceil(float(enemy.get("max_hp", enemy["hp"]))))], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1,1,1,0.9))
	draw_circle(player_pos, PLAYER_RADIUS + 10.0, Color(1.0, 0.95, 0.72, 0.12))
	draw_circle(player_pos, PLAYER_RADIUS, Color("f1fa8c"))
	draw_line(player_pos, player_pos + facing * 26.0, Color(0.14, 0.18, 0.24, 1.0), 2.0)
	if cursor_probe_enabled and ARENA_RECT.has_point(get_global_mouse_position()):
		var probe := get_global_mouse_position()
		var intensity := _light_intensity_at(probe)
		draw_arc(probe, PROBE_RADIUS, 0.0, TAU, 24, Color(0.85, 0.95, 1.0, 0.55), 1.5)
		draw_arc(probe, PROBE_RADIUS + 7.0, -PI * 0.5, -PI * 0.5 + TAU * intensity, 24, Color(1.0, 0.95, 0.72, 0.85), 2.0)
