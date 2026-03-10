extends RunScene
class_name LightLabScene

const LightMaterials = preload("res://scripts/data/light_materials.gd")
const DeadAliveGrid = preload("res://scripts/gameplay/dead_alive_grid.gd")
const LightSurfaceResolver = preload("res://scripts/gameplay/light_surface_resolver.gd")
const BossController = preload("res://scripts/gameplay/boss_controller.gd")
const LightLabCollision = preload("res://scripts/gameplay/light_lab_collision.gd")
const LightQuery = preload("res://scripts/gameplay/light_query.gd")
const LightLabLayout = preload("res://scripts/data/light_lab_layout.gd")
const FlashlightVisuals = preload("res://scripts/gameplay/flashlight_visuals.gd")
const LightApproximation = preload("res://scripts/gameplay/light_approximation.gd")

const LAB_LABEL := "Light Lab v0.5.5"
const CELL_SIZE := 32.0
const PROBE_RADIUS := 18.0

var surface_segments: Array = []
var surface_patches: Array = []
var prism_stations: Array = []
var tree_trunks: Array = []
var diffuse_zones: Array = []
var secondary_light_segments: Array = []
var secondary_light_zones: Array = []
var secondary_debug_points: Array = []
var flashlight_visual_segments: Array = []
var flashlight_visual_zones: Array = []
var flashlight_visual_debug_points: Array = []
var flashlight_visual_fills: Array = []
var dead_alive_cells: Array = []
var approx_refresh_timer := 999.0
var approx_state := {}
var approx_flashlight_frontier := {}
var approx_secondary_sample_order := {}
var perf_snapshot := {
	"secondary": {},
	"flashlight": {},
	"tier_b_ms": 0.0,
	"tier_c_ms": 0.0
}
var beam_debug_hits: Array = []
var beam_debug_enabled := true
var hp_overhead_enabled := true
var cursor_probe_enabled := true
var base_alive_flip := false
var movement_surface_probe := {}
var spawn_validation_enabled := true

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
	flashlight_half_angle = 34.0
	last_event = "Light Lab booted — readability + extraction pass active"
	_build_light_lab()
	_update_ui()

func _build_light_lab() -> void:
	surface_segments = []
	surface_patches = []
	prism_stations = []
	tree_trunks = []
	var layout := LightLabLayout.build_layout(base_alive_flip)
	dead_alive_cells = DeadAliveGrid.build(ARENA_RECT, CELL_SIZE, layout.get("dead_alive_cells", []))
	for segment: Dictionary in layout.get("segments", []):
		surface_segments.append(segment.duplicate(true))
	for patch: Dictionary in layout.get("patches", []):
		surface_patches.append(patch.duplicate(true))
	for prism_station: Dictionary in layout.get("prism_stations", []):
		prism_stations.append(prism_station.duplicate(true))
	for trunk: Dictionary in layout.get("tree_trunks", []):
		tree_trunks.append(trunk.duplicate(true))
	approx_state = {}
	approx_flashlight_frontier = {}
	approx_secondary_sample_order = {}
	approx_refresh_timer = 999.0

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
	approx_refresh_timer += delta
	_refresh_light_approximations_if_needed()
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

func _refresh_light_approximations_if_needed(force: bool = false) -> void:
	var prism_pos: Vector2 = prism_node.position if prism_node else Vector2.INF
	var state := {
		"flashlight_on": flashlight_on,
		"player_pos": player_pos.round(),
		"facing": Vector2(snapped(facing.x, 0.02), snapped(facing.y, 0.02)),
		"prism": prism_pos.round(),
		"beam_count": beam_segments.size()
	}
	var tier_b_due := force or approx_state != state or LightApproximation.should_refresh(approx_refresh_timer, "flashlight")
	var tier_c_due := force or approx_state != state or LightApproximation.should_refresh(approx_refresh_timer, "prism")
	if tier_c_due:
		var t0 := Time.get_ticks_usec()
		var secondary := LightSurfaceResolver.build_secondary_light(self)
		secondary_light_segments = secondary.get("segments", [])
		secondary_light_zones = secondary.get("zones", [])
		secondary_debug_points = secondary.get("debug_points", [])
		perf_snapshot["secondary"] = secondary.get("perf", {})
		perf_snapshot["tier_c_ms"] = (Time.get_ticks_usec() - t0) / 1000.0
	if tier_b_due:
		var t1 := Time.get_ticks_usec()
		var flashlight_visuals := FlashlightVisuals.build_visual_trace(self)
		flashlight_visual_segments = flashlight_visuals.get("segments", [])
		flashlight_visual_zones = flashlight_visuals.get("zones", [])
		flashlight_visual_debug_points = flashlight_visuals.get("debug_points", [])
		flashlight_visual_fills = flashlight_visuals.get("fills", [])
		approx_flashlight_frontier = flashlight_visuals.get("frontier", {})
		perf_snapshot["flashlight"] = flashlight_visuals.get("perf", {})
		perf_snapshot["tier_b_ms"] = (Time.get_ticks_usec() - t1) / 1000.0
	if tier_b_due or tier_c_due:
		approx_state = state
		approx_refresh_timer = 0.0

func _handle_player(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed_scale := _movement_speed_multiplier_at(player_pos)
	player_velocity = input * player_speed * speed_scale
	if input.length() > 0.1:
		facing = input.normalized()
	var target_pos := LightLabCollision.resolve_circle_motion(player_pos, PLAYER_RADIUS + 5.0, player_velocity * delta, surface_segments, tree_trunks)
	target_pos.x = clamp(target_pos.x, ARENA_RECT.position.x + PLAYER_RADIUS, ARENA_RECT.end.x - PLAYER_RADIUS)
	target_pos.y = clamp(target_pos.y, ARENA_RECT.position.y + PLAYER_RADIUS, ARENA_RECT.end.y - PLAYER_RADIUS)
	player_pos = target_pos
	player_node.position = player_pos
	movement_surface_probe = _surface_patch_at(player_pos)
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
	flashlight_visual_segments.clear()
	flashlight_visual_zones.clear()
	flashlight_visual_debug_points.clear()
	flashlight_visual_fills.clear()
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
	approx_state = {}
	approx_flashlight_frontier = {}
	approx_secondary_sample_order = {}
	approx_refresh_timer = 999.0
	last_event = "Light Lab reset"

func _spawn_debug_enemy(type: String) -> void:
	var pos := _find_valid_spawn(get_global_mouse_position().clamp(ARENA_RECT.position + Vector2(32, 32), ARENA_RECT.end - Vector2(32, 32)), 24.0 if type == "boss_hollow_matriarch" else 18.0)
	if pos == Vector2.INF:
		last_event = "Spawn blocked by wall or tree"
		return
	if type == "boss_hollow_matriarch":
		BossController.spawn_boss(self, "hollow_matriarch", pos)
	else:
		EncounterController.spawn_enemy(self, type, pos)
	last_event = "Spawned %s" % type

func _place_prism(target: Vector2) -> void:
	if prism_timer > 0.0:
		last_event = "Prism Node recharging"
		return
	var valid := _find_valid_spawn(target.clamp(ARENA_RECT.position + Vector2(32, 32), ARENA_RECT.end - Vector2(32, 32)), 22.0)
	if valid == Vector2.INF:
		last_event = "Prism placement blocked"
		return
	super._place_prism(valid)

func _surface_patch_at(pos: Vector2) -> Dictionary:
	for patch: Dictionary in surface_patches:
		if Rect2(patch["rect"]).has_point(pos):
			return patch
	return {}

func _movement_speed_multiplier_at(pos: Vector2) -> float:
	var patch := _surface_patch_at(pos)
	if patch.is_empty():
		return 1.0
	var material := LightMaterials.get_definition(String(patch.get("material_id", "brick")))
	var title := String(patch.get("title", patch.get("label", "")))
	if title.contains("Shallow"):
		return 0.76
	if title.contains("Deep"):
		return 0.56
	var multiplier := LightMaterials.water_speed_multiplier(material)
	return multiplier if LightMaterials.water_depth(material) > 0.0 else 1.0

func _find_valid_spawn(target: Vector2, radius: float) -> Vector2:
	var candidate := target
	for ring in range(5):
		for step in range(12):
			var angle := TAU * float(step) / 12.0
			var probe := candidate + Vector2.RIGHT.rotated(angle) * float(ring) * 18.0
			probe = _resolve_point_in_lab(probe, radius)
			if not LightLabCollision.is_circle_blocked(probe, radius, surface_segments, tree_trunks):
				return probe
	return Vector2.INF

func _resolve_actor_motion(position: Vector2, radius: float, motion: Vector2) -> Vector2:
	var resolved := LightLabCollision.resolve_circle_motion(position, radius, motion, surface_segments, tree_trunks)
	return _resolve_point_in_lab(resolved, radius)

func _resolve_point_in_lab(position: Vector2, radius: float) -> Vector2:
	return position.clamp(ARENA_RECT.position + Vector2(radius, radius), ARENA_RECT.end - Vector2(radius, radius))

func _flashlight_intensity(source_pos: Vector2, source_facing: Vector2, target: Vector2, max_range: float, half_angle_deg: float, base_intensity: float) -> float:
	var raw := LightQuery.flashlight_intensity(source_pos, source_facing, target, max_range, half_angle_deg, base_intensity)
	if raw <= 0.0:
		return 0.0
	var visibility := _visibility_between(source_pos, target)
	if visibility <= 0.0:
		return 0.0
	return raw * visibility

func _segment_intensity(a: Vector2, b: Vector2, point: Vector2, radius: float, strength: float) -> float:
	return LightQuery.segment_intensity(a, b, point, radius, strength)

func _radial_intensity(origin: Vector2, point: Vector2, radius: float, strength: float) -> float:
	return LightQuery.radial_intensity(origin, point, radius, strength)

func _visibility_between(a: Vector2, b: Vector2) -> float:
	var distance_to_target: float = a.distance_to(b)
	for surface: Dictionary in surface_segments:
		if not bool(surface.get("blocks_flashlight", true)):
			continue
		var hit := LightSurfaceResolver._ray_segment_intersection(a, (b - a).normalized(), Vector2(surface["a"]), Vector2(surface["b"]))
		if hit.is_empty():
			continue
		var t: float = float(hit["t"])
		if t > 0.001 and t < distance_to_target - 1.0:
			return 0.0
	for trunk: Dictionary in tree_trunks:
		var trunk_hit := LightLabCollision.segment_intersects_circle(a, b, Vector2(trunk["pos"]), float(trunk["radius"]))
		if not trunk_hit.is_empty() and float(trunk_hit["t"]) > 0.001 and float(trunk_hit["t"]) < 0.98:
			return 0.0
	return 1.0

func _light_intensity_at(pos: Vector2) -> float:
	var intensity := _flashlight_intensity(player_pos, facing, pos, flashlight_range, flashlight_half_angle, 1.0 if flashlight_on else 0.0)
	for segment: Dictionary in flashlight_visual_segments:
		intensity = max(intensity, _segment_intensity(segment["a"], segment["b"], pos, 32.0 if String(segment.get("kind", "primary")) == "primary" else 26.0, float(segment["intensity"]) * (0.9 if String(segment.get("kind", "primary")) == "primary" else 0.7)))
	for zone: Dictionary in flashlight_visual_zones:
		intensity = max(intensity, _radial_intensity(zone["pos"], pos, zone["radius"], float(zone["strength"])))
	for segment: Dictionary in beam_segments:
		intensity = max(intensity, _segment_intensity(segment["a"], segment["b"], pos, 42.0, float(segment["intensity"])))
	for diffuse: Dictionary in diffuse_zones:
		intensity = max(intensity, _radial_intensity(diffuse["pos"], pos, diffuse["radius"], diffuse["strength"]))
	for segment: Dictionary in secondary_light_segments:
		intensity = max(intensity, _segment_intensity(segment["a"], segment["b"], pos, 38.0, float(segment["intensity"])))
	for zone: Dictionary in secondary_light_zones:
		intensity = max(intensity, _radial_intensity(zone["pos"], pos, zone["radius"], zone["strength"]))
	for prism_station: Dictionary in prism_stations:
		intensity = max(intensity, _radial_intensity(prism_station["pos"], pos, 64.0, 0.42))
	if prism_node:
		intensity = max(intensity, _radial_intensity(prism_node.position, pos, 100.0, 0.66))
	return clampf(intensity, 0.0, 1.0)

func _is_in_flashlight_cone(pos: Vector2) -> bool:
	return _light_intensity_at(pos) > 0.12 and flashlight_on

func _is_in_prism_light(pos: Vector2) -> bool:
	if prism_node and prism_node.position.distance_to(pos) <= 100.0:
		return true
	for prism_station: Dictionary in prism_stations:
		if prism_station["pos"].distance_to(pos) <= 64.0:
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
		zones.append({"pos": player_pos + facing * 116.0, "radius": 176.0, "color": Color(1.0, 0.95, 0.72, 0.06), "layer": 0})
	for segment: Dictionary in flashlight_visual_segments:
		zones.append({"pos": Vector2(segment["a"]).lerp(Vector2(segment["b"]), 0.5), "radius": max(Vector2(segment["a"]).distance_to(Vector2(segment["b"])) * 0.18, 24.0), "color": Color(1.0, 0.92, 0.72, 0.028 + 0.035 * float(segment["intensity"])), "layer": 0})
	for zone: Dictionary in flashlight_visual_zones:
		zones.append({"pos": zone["pos"], "radius": zone["radius"], "color": Color(1.0, 0.90, 0.68, 0.022 + 0.032 * float(zone["strength"])), "layer": 0})
	for segment: Dictionary in beam_segments:
		var layer_alpha: float = max(0.03, 0.08 - float(segment.get("layer", 0)) * 0.008)
		zones.append({"pos": Vector2(segment["a"]).lerp(Vector2(segment["b"]), 0.5), "radius": max(Vector2(segment["a"]).distance_to(Vector2(segment["b"])) * 0.32, 64.0), "color": Color(0.55, 0.92, 1.0, layer_alpha * float(segment["intensity"])), "layer": int(segment.get("layer", 0))})
	for diffuse: Dictionary in diffuse_zones:
		zones.append({"pos": diffuse["pos"], "radius": diffuse["radius"], "color": Color(1.0, 0.92, 0.72, 0.05 * float(diffuse["strength"]) + 0.02), "layer": int(diffuse.get("layer", 1))})
	for segment: Dictionary in secondary_light_segments:
		var seg_color: Color = _secondary_color(segment)
		zones.append({"pos": Vector2(segment["a"]).lerp(Vector2(segment["b"]), 0.5), "radius": max(Vector2(segment["a"]).distance_to(Vector2(segment["b"])) * 0.24, 42.0), "color": Color(seg_color.r, seg_color.g, seg_color.b, 0.05 * float(segment["intensity"]) + 0.018), "layer": int(segment.get("layer", 1))})
	for zone: Dictionary in secondary_light_zones:
		var zone_color: Color = _secondary_zone_color(zone)
		zones.append({"pos": zone["pos"], "radius": zone["radius"], "color": Color(zone_color.r, zone_color.g, zone_color.b, 0.038 * float(zone["strength"]) + 0.02), "layer": int(zone.get("layer", 1))})
	if prism_node:
		zones.append({"pos": prism_node.position, "radius": 100.0, "color": Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.08), "layer": 0})
	for prism_station: Dictionary in prism_stations:
		zones.append({"pos": prism_station["pos"], "radius": 64.0, "color": Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.06), "layer": 0})
	return zones

func _update_ui() -> void:
	if help_collapsed:
		hud_label.visible = false
		status_label.visible = false
		return
	hud_label.visible = true
	status_label.visible = true
	var mouse_world := get_global_mouse_position()
	var material := _material_under_cursor(mouse_world)
	var mat_name := String(material.get("label", "Floor"))
	var intensity := _light_intensity_at(mouse_world)
	var move_patch := _surface_patch_at(player_pos)
	var move_label := String(move_patch.get("title", move_patch.get("label", "Dry floor")))
	var move_scale := _movement_speed_multiplier_at(player_pos)
	var beam_ready := "[color=#8be9fd]READY[/color]" if beam_timer <= 0.0 else "[color=#ffb86c]%.2fs[/color]" % beam_timer
	var prism_state := "[color=#8be9fd]ACTIVE %.1fs[/color]" % prism_timer if prism_node else ("[color=#ffb86c]%.1fs[/color]" % prism_timer if prism_timer > 0.0 else "[color=#50fa7b]READY[/color]")
	var surge_state := "[color=#8be9fd]READY[/color]" if prism_surge_timer <= 0.0 else "[color=#ffb86c]%.1fs[/color]" % prism_surge_timer
	var immortal_text := "[color=#50fa7b]ON[/color]" if debug_immortal else "[color=#6272a4]OFF[/color]"
	var beam_layers := 0
	for segment: Dictionary in beam_segments:
		beam_layers = max(beam_layers, int(segment.get("layer", 0)) + 1)
	var tier_b_ms := float(perf_snapshot.get("tier_b_ms", 0.0))
	var tier_c_ms := float(perf_snapshot.get("tier_c_ms", 0.0))
	var secondary_perf: Dictionary = perf_snapshot.get("secondary", {})
	var flash_perf: Dictionary = perf_snapshot.get("flashlight", {})
	hud_label.text = "[b]Lantern Engine — %s[/b]\n[color=#a4b1cd]Mode:[/color] Permanent validation map (no auto encounters)\n[color=#a4b1cd]Goal:[/color] Behavioral light truth + cheaper approximation\n\n[color=#ff6b6b]HP[/color] %.0f / %.0f %s\n[color=#8be9fd]EN[/color] %.0f / %.0f %s\n\n[color=#f1fa8c]Beam[/color] %.0f dmg | %.0f range | %d beam branches | [color=#a4b1cd]Trace layers:[/color] %d\n[color=#f1fa8c]Flashlight[/color] %.0f range | %d° half-angle | unified beam fill | [color=#a4b1cd]F[/color] %s\n[color=#f1fa8c]Prism[/color] station + manual node | [color=#a4b1cd]RMB[/color] %s | [color=#a4b1cd]Q[/color] %s\n[color=#a4b1cd]Cursor:[/color] %s | [color=#a4b1cd]Light:[/color] %.2f | [color=#a4b1cd]Step:[/color] %s x%.2f | [color=#a4b1cd]Immortal:[/color] %s\n[color=#a4b1cd]Approx:[/color] T-B %.2fms / %d rays / %d fills | T-C %.2fms / %d samples / %d zones" % [LAB_LABEL, player_hp, player_max_hp, HudText.bar(player_hp, player_max_hp), energy, max_energy, HudText.bar(energy, max_energy), beam_damage, beam_range, beam_bounces, beam_layers, flashlight_range, int(flashlight_half_angle), ("[color=#f1fa8c]ON[/color]" if flashlight_on else "[color=#6272a4]OFF[/color]"), prism_state, surge_state, mat_name, intensity, move_label, move_scale, immortal_text, tier_b_ms, int(flash_perf.get("guide_rays", 0)), int(flash_perf.get("fills", 0)), tier_c_ms, int(secondary_perf.get("samples", 0)), int(secondary_perf.get("zones", 0))]
	status_label.text = "[b]Light Lab controls[/b]\nWASD move | LMB beam | RMB prism | Q Prism Surge | F flashlight\n1 Moth | 2 Hollow | 3 Matriarch | 4 Prism at cursor\n5 cursor probe | 6 path debug | 7 HP labels | 8 base alive toggle\nF1 hide/show ALL overlays | F2 refill | F4 immortal\n\n[b]Approximation tiers[/b]\nTier A laser = precise beam logic\nTier B flashlight = guided beam fill from guide rays\nTier C prism/scatter = cheap material-aware secondary response\n\n[b]Readability legend[/b]\nWarm beam fill = main flashlight volume | faint lines = guide truth only\nBlue ring = bounce | Prism ring = redirect | Amber cloud = diffuse\nAqua dashed = glass continuation | Wood = soft scatter | Wet = glossy disturbance\n\n[b]Event[/b]\n%s" % last_event

func _material_under_cursor(pos: Vector2) -> Dictionary:
	for patch: Dictionary in surface_patches:
		if Rect2(patch["rect"]).has_point(pos):
			var mat := LightMaterials.get_definition(patch["material_id"])
			mat["source_label"] = patch["label"]
			mat["hint"] = patch.get("hint", "")
			return mat
	for trunk: Dictionary in tree_trunks:
		if Vector2(trunk["pos"]).distance_to(pos) <= float(trunk["radius"]):
			var tree_mat := LightMaterials.get_definition("wood")
			tree_mat["label"] = "Tree Trunk"
			tree_mat["hint"] = "solid blocker"
			return tree_mat
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
		var patch_color := Color(mat["color"].r, mat["color"].g, mat["color"].b, 0.82)
		var title := String(patch.get("title", patch.get("label", "")))
		if title.contains("Shallow"):
			patch_color = patch_color.lightened(0.12)
		elif title.contains("Deep"):
			patch_color = patch_color.darkened(0.08)
		draw_rect(patch["rect"], patch_color, true)
		draw_rect(patch["rect"], Color(1, 1, 1, 0.08), false, 2.0)
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
	for trunk: Dictionary in tree_trunks:
		var pos: Vector2 = trunk["pos"]
		var radius: float = float(trunk["radius"])
		draw_circle(pos, radius + 12.0, Color(0.12, 0.22, 0.12, 0.18))
		draw_circle(pos, radius + 4.0, Color(0.22, 0.42, 0.24, 0.28))
		draw_circle(pos, radius, Color(0.34, 0.22, 0.14, 1.0))
		draw_arc(pos, radius + 2.0, 0.0, TAU, 22, Color(0.62, 0.44, 0.28, 0.65), 2.0)
	for prism_station: Dictionary in prism_stations:
		draw_circle(prism_station["pos"], 26.0, Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.18))
		draw_arc(prism_station["pos"], 26.0, 0.0, TAU, 24, PRISM_COLOR, 3.0)
	if not help_collapsed:
		for patch: Dictionary in surface_patches:
			_draw_sign_patch(patch)
	_draw_flashlight_trace()
	_draw_primary_beam_segments()
	_draw_secondary_overlays()
	if beam_debug_enabled and not help_collapsed:
		_draw_debug_markers()
	for enemy: Dictionary in enemies:
		if not is_instance_valid(enemy["node"]):
			continue
		var color: Color = Color("ffb86c") if enemy["type"] == "moth" else (Color("ff4fd8") if enemy["type"] == "boss_hollow_matriarch" else Color("bd93f9"))
		draw_circle(enemy["node"].position, enemy["radius"] + 7.0, Color(color.r, color.g, color.b, 0.15))
		draw_circle(enemy["node"].position, enemy["radius"], color)
		if hp_overhead_enabled and not help_collapsed:
			draw_string(ThemeDB.fallback_font, enemy["node"].position + Vector2(-28, -24), "%d/%d" % [int(ceil(float(enemy["hp"]))), int(ceil(float(enemy.get("max_hp", enemy["hp"]))))], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1,1,1,0.9))
	draw_circle(player_pos, PLAYER_RADIUS + 10.0, Color(1.0, 0.95, 0.72, 0.12))
	draw_circle(player_pos, PLAYER_RADIUS, Color("f1fa8c"))
	draw_line(player_pos, player_pos + facing * 26.0, Color(0.14, 0.18, 0.24, 1.0), 2.0)
	if cursor_probe_enabled and not help_collapsed and ARENA_RECT.has_point(get_global_mouse_position()):
		var probe := get_global_mouse_position()
		var intensity := _light_intensity_at(probe)
		var mat := _material_under_cursor(probe)
		draw_arc(probe, PROBE_RADIUS, 0.0, TAU, 24, Color(0.85, 0.95, 1.0, 0.55), 1.5)
		draw_arc(probe, PROBE_RADIUS + 7.0, -PI * 0.5, -PI * 0.5 + TAU * intensity, 24, Color(1.0, 0.95, 0.72, 0.85), 2.0)
		var probe_text := "%s | I %.2f | R %.2f D %.2f T %.2f | %s" % [String(mat.get("label", "Floor")), intensity, float(mat.get("reflectivity", 0.0)), float(mat.get("diffusion", 0.0)), float(mat.get("transmission", 0.0)), String(mat.get("hint", ""))]
		draw_string(ThemeDB.fallback_font, probe + Vector2(20, -12), probe_text, HORIZONTAL_ALIGNMENT_LEFT, 320.0, 12, Color(1, 1, 1, 0.88))

func _draw_flashlight_trace() -> void:
	if not flashlight_on:
		return
	for fill: Dictionary in flashlight_visual_fills:
		var points: PackedVector2Array = fill["points"]
		var strength: float = float(fill.get("strength", 1.0))
		draw_colored_polygon(points, Color(1.0, 0.94, 0.72, 0.060 * strength))
		draw_polyline(points, Color(1.0, 0.98, 0.84, 0.11 * strength), 1.2, true)
	for zone: Dictionary in flashlight_visual_zones:
		var kind := String(zone.get("kind", "diffuse"))
		var zone_color := Color(1.0, 0.90, 0.62, 0.08 * float(zone["strength"]))
		if String(zone.get("material_id", "")) == "glass":
			zone_color = Color(0.72, 0.96, 1.0, 0.07 * float(zone["strength"]))
		elif String(zone.get("material_id", "")) == "wet":
			zone_color = Color(0.76, 0.95, 1.0, 0.08 * float(zone["strength"]))
		draw_circle(zone["pos"], zone["radius"], zone_color)
		if kind != "block":
			draw_arc(zone["pos"], float(zone["radius"]) * 0.56, 0.0, TAU, 20, Color(zone_color.r, zone_color.g, zone_color.b, 0.22 + 0.18 * float(zone["strength"])), 1.8)
	for segment: Dictionary in flashlight_visual_segments:
		var a: Vector2 = segment["a"]
		var b: Vector2 = segment["b"]
		var intensity: float = float(segment["intensity"])
		var kind := String(segment.get("kind", "primary"))
		var material_id := String(segment.get("material_id", "open"))
		var tint := Color(1.0, 0.95, 0.78, 1.0)
		var width := 4.0
		if kind == "transmit":
			tint = Color(0.70, 0.96, 1.0, 1.0)
			width = 3.0
		elif kind == "reflect":
			tint = Color(1.0, 0.90, 0.70, 1.0)
			width = 3.6
		elif kind == "scatter":
			tint = Color(1.0, 0.82, 0.56, 1.0)
			width = 2.8
		elif kind == "disturb":
			tint = Color(0.78, 0.96, 1.0, 1.0)
			width = 2.6
		var is_primary := kind == "primary"
		draw_line(a, b, Color(tint.r, tint.g, tint.b, (0.035 if is_primary else 0.07) * intensity), 10.0 if is_primary else 12.0)
		draw_line(a, b, Color(tint.r, tint.g, tint.b, (0.08 if is_primary else 0.18) * intensity), 5.5 if is_primary else 7.0)
		draw_line(a, b, Color(tint.r, tint.g, tint.b, (0.22 if is_primary else 0.55) * intensity), 2.2 if is_primary else width)
		if kind == "transmit":
			var distance: float = a.distance_to(b)
			var steps: int = max(2, int(distance / 24.0))
			for i in range(steps):
				if i % 2 == 0:
					continue
				var da: Vector2 = a.lerp(b, float(i) / float(steps))
				var db: Vector2 = a.lerp(b, min(1.0, float(i) / float(steps) + 0.08))
				draw_line(da, db, Color(1.0, 1.0, 1.0, 0.34 * intensity), 1.4)
		if material_id == "wood" and kind == "primary":
			var wood_mid := a.lerp(b, 0.6)
			draw_arc(wood_mid, 12.0, -0.45, 0.45, 10, Color(1.0, 0.88, 0.58, 0.25 * intensity), 1.4)
			draw_arc(wood_mid + Vector2(6, -2), 18.0, -0.30, 0.55, 10, Color(1.0, 0.80, 0.50, 0.18 * intensity), 1.2)
		if material_id == "wet":
			var wet_mid := a.lerp(b, 0.48)
			draw_arc(wet_mid, 10.0, 0.0, TAU, 16, Color(0.76, 0.96, 1.0, 0.30 * intensity), 1.2)
		if not help_collapsed and kind != "primary":
			var label := "FX" if kind == "reflect" else ("TX" if kind == "transmit" else "SC")
			draw_string(ThemeDB.fallback_font, a.lerp(b, 0.5) + Vector2(-8, -8), label, HORIZONTAL_ALIGNMENT_LEFT, 28.0, 9, Color(1, 1, 1, 0.65))

func _draw_sign_patch(patch: Dictionary) -> void:
	var rect: Rect2 = patch["rect"]
	var sign_rect := Rect2(rect.position + Vector2(8, 8), Vector2(min(rect.size.x - 16.0, 160.0), 42.0))
	draw_rect(sign_rect, Color(0.03, 0.05, 0.08, 0.78), true)
	draw_rect(sign_rect, Color(1, 1, 1, 0.14), false, 1.0)
	draw_string(ThemeDB.fallback_font, sign_rect.position + Vector2(8, 14), String(patch.get("title", patch.get("label", ""))), HORIZONTAL_ALIGNMENT_LEFT, sign_rect.size.x - 12.0, 13, Color(1, 1, 1, 0.9))
	draw_string(ThemeDB.fallback_font, sign_rect.position + Vector2(8, 28), String(patch.get("subtitle", "")), HORIZONTAL_ALIGNMENT_LEFT, sign_rect.size.x - 12.0, 11, Color(0.78, 0.86, 0.95, 0.76))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, rect.size.y - 10), String(patch.get("hint", "")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 11, Color(1.0, 0.95, 0.72, 0.82))

func _draw_primary_beam_segments() -> void:
	for segment: Dictionary in beam_segments:
		var a: Vector2 = segment["a"]
		var b: Vector2 = segment["b"]
		var alpha := clampf(float(segment["intensity"]), 0.12, 1.0)
		var layer := int(segment.get("layer", 0))
		var layer_tint := Color(0.48, 0.92 - min(layer * 0.06, 0.24), 1.0, 1.0)
		if layer == 0:
			layer_tint = Color(0.50, 0.96, 1.0, 1.0)
		draw_line(a, b, Color(layer_tint.r, layer_tint.g, layer_tint.b, 0.15 * alpha), 22.0)
		draw_line(a, b, Color(layer_tint.r, layer_tint.g, layer_tint.b, 0.34 * alpha), 12.0)
		draw_line(a, b, Color(1.0, 0.96, 0.76, 0.92 * alpha), 4.0)
		if _segment_crosses_wet(a, b):
			var mid: Vector2 = a.lerp(b, 0.5)
			draw_arc(mid, 18.0, 0.0, TAU, 18, Color(0.72, 0.94, 1.0, 0.38 * alpha), 2.0)
			draw_arc(mid + Vector2(8, -4), 10.0, 0.0, TAU, 16, Color(1.0, 1.0, 1.0, 0.24 * alpha), 1.5)
		if not help_collapsed:
			var mid2: Vector2 = a.lerp(b, 0.5)
			draw_circle(mid2, 10.0, Color(0.02, 0.04, 0.08, 0.36))
			draw_string(ThemeDB.fallback_font, mid2 + Vector2(-10, 4), "L%d" % layer, HORIZONTAL_ALIGNMENT_LEFT, 24.0, 11, Color(0.92, 0.98, 1.0, 0.9))

func _draw_secondary_overlays() -> void:
	for diffuse: Dictionary in diffuse_zones:
		draw_circle(diffuse["pos"], diffuse["radius"], Color(1.0, 0.84, 0.48, 0.06 * float(diffuse["strength"])))
		draw_arc(diffuse["pos"], diffuse["radius"] * 0.58, 0.0, TAU, 20, Color(1.0, 0.88, 0.54, 0.18 * float(diffuse["strength"])), 2.0)
	for zone: Dictionary in secondary_light_zones:
		var zmat := LightMaterials.get_definition(zone["material_id"])
		var zone_color: Color = _secondary_zone_color(zone)
		draw_circle(zone["pos"], zone["radius"], Color(zone_color.r, zone_color.g, zone_color.b, 0.07 * float(zone["strength"])))
		draw_arc(zone["pos"], zone["radius"] * 0.52, 0.0, TAU, 20, Color(zmat["alive_color"].r, zmat["alive_color"].g, zmat["alive_color"].b, 0.18 * float(zone["strength"])), 1.6)
	for segment: Dictionary in secondary_light_segments:
		var sa: Vector2 = segment["a"]
		var sb: Vector2 = segment["b"]
		var tint: Color = _secondary_color(segment)
		var intensity: float = float(segment["intensity"])
		var kind := String(segment.get("kind", "reflect"))
		var width := 4.0 if kind == "transmit" else 6.0
		draw_line(sa, sb, Color(tint.r, tint.g, tint.b, 0.14 * intensity), 12.0)
		draw_line(sa, sb, Color(tint.r, tint.g, tint.b, 0.36 * intensity), width)
		if String(segment.get("material_id", "")) == "wet":
			var wet_mid: Vector2 = sa.lerp(sb, 0.45)
			draw_arc(wet_mid, 14.0, 0.0, TAU, 16, Color(0.74, 0.95, 1.0, 0.32 * intensity), 1.8)
		if kind == "transmit":
			var distance: float = sa.distance_to(sb)
			var steps: int = max(2, int(distance / 26.0))
			for i in range(steps):
				if i % 2 == 0:
					continue
				var t0: float = float(i) / float(steps)
				var t1: float = min(1.0, t0 + 0.08)
				var da: Vector2 = sa.lerp(sb, t0)
				var db: Vector2 = sa.lerp(sb, t1)
				draw_line(da, db, Color(1.0, 1.0, 1.0, 0.42 * intensity), 2.0)

func _draw_debug_markers() -> void:
	for hit: Dictionary in beam_debug_hits:
		var color := Color(0.9, 1.0, 1.0, 0.4)
		if String(hit.get("kind", "bounce")) == "redirect":
			color = Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.55)
		draw_circle(hit["point"], 8.0, color)
		draw_arc(hit["point"], 13.0, 0.0, TAU, 18, color, 2.0)
		draw_string(ThemeDB.fallback_font, hit["point"] + Vector2(12, -10), "L%d" % int(hit.get("layer", 0)), HORIZONTAL_ALIGNMENT_LEFT, 24.0, 10, Color(1, 1, 1, 0.8))
	for point: Dictionary in secondary_debug_points:
		var segment_color: Color = _secondary_color({"source_type": point.get("source_type", "flashlight"), "kind": "reflect"})
		draw_circle(point["point"], 6.0, Color(segment_color.r, segment_color.g, segment_color.b, 0.48))
		draw_line(point["point"], point["point"] + Vector2(Dictionary(point["response"]).get("reflect_dir", Vector2.RIGHT)) * 18.0, Color(segment_color.r, segment_color.g, segment_color.b, 0.45), 1.5)

func _secondary_color(segment: Dictionary) -> Color:
	var source_type := String(segment.get("source_type", "flashlight"))
	var kind := String(segment.get("kind", "reflect"))
	if kind == "transmit":
		return Color(0.66, 0.95, 1.0, 1.0)
	if source_type == "prism":
		return Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 1.0)
	return Color(1.0, 0.94, 0.76, 1.0)

func _secondary_zone_color(zone: Dictionary) -> Color:
	if String(zone.get("source_type", "flashlight")) == "prism":
		return Color(0.62, 0.92, 1.0, 1.0)
	return Color(1.0, 0.86, 0.58, 1.0)

func _segment_crosses_wet(a: Vector2, b: Vector2) -> bool:
	for patch: Dictionary in surface_patches:
		if String(patch.get("material_id", "")) != "wet":
			continue
		var rect: Rect2 = patch["rect"]
		for step in range(6):
			var t: float = float(step) / 5.0
			if rect.has_point(a.lerp(b, t)):
				return true
	return false
