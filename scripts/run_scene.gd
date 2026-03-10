extends Node2D
class_name RunScene

const EncounterDefs = preload("res://scripts/data/encounter_defs.gd")
const DebugActions = preload("res://scripts/player/debug_actions.gd")
const SkillDefs = preload("res://scripts/data/skill_defs.gd")
const RewardController = preload("res://scripts/gameplay/reward_controller.gd")
const EncounterController = preload("res://scripts/gameplay/encounter_controller.gd")
const BeamResolver = preload("res://scripts/gameplay/beam_resolver.gd")
const EnemyController = preload("res://scripts/gameplay/enemy_controller.gd")
const SkillController = preload("res://scripts/gameplay/skill_controller.gd")
const SfxController = preload("res://scripts/gameplay/sfx_controller.gd")
const RunSummary = preload("res://scripts/gameplay/run_summary.gd")
const HudText = preload("res://scripts/ui/hud_text.gd")

const ARENA_RECT := Rect2(Vector2(64, 64), Vector2(1152, 592))
const PLAYER_RADIUS := 14.0
const ENEMY_CONTACT_RADIUS := 20.0
const BEAM_OUTER_COLOR := Color(0.45, 0.95, 1.0, 0.42)
const BEAM_INNER_COLOR := Color(1.0, 0.96, 0.72, 0.95)
const BOUNCE_COLOR := Color(0.62, 0.95, 1.0, 0.95)
const PRISM_COLOR := Color(0.54, 0.93, 1.0, 1.0)
const SHADOW_COLOR := Color(0.02, 0.03, 0.06, 0.78)
const BEAM_PULSE_DURATION := 0.15
const BEAM_OFFSET := 4.0
const PRISM_RADIUS := 18.0
const PRISM_REDIRECT_ANGLE := 55.0
const BUILD_LABEL := "MVP-1.0 patch 4"

var player_hp := 100.0
var player_max_hp := 100.0
var energy := 100.0
var max_energy := 100.0
var energy_regen := 18.0
var beam_cost := 25.0
var beam_cooldown := 0.45
var beam_timer := 0.0
var prism_timer := 0.0
var prism_cooldown := 1.2
var prism_duration := 12.0
var prism_radius_bonus := 0.0
var prism_redirect_angle_bonus := 0.0
var prism_redirect_damage_bonus := 0.0
var prism_redirect_bonus_bounces := 0
var prism_surge_unlocked := true
var prism_surge_cooldown := 6.0
var prism_surge_timer := 0.0
var prism_surge_damage := 20.0
var prism_surge_radius := 118.0
var prism_surge_push_distance := 96.0
var prism_surge_energy_refund_on_hit := 8.0
var prism_surge_special_lock_duration := 2.2
var prism_surge_light_burn_duration := 4.0
var prism_surge_light_burn_tick := 0.5
var prism_surge_light_burn_damage := 1.5
var prism_node: Node2D
var player_velocity := Vector2.ZERO
var player_speed := 285.0
var player_pos := Vector2(260, 360)
var facing := Vector2.RIGHT
var beam_range := 330.0
var beam_damage := 18.0
var beam_bounces := 1
# --- Flashlight (MVP-0.3) ---
var flashlight_on := false
var flashlight_drain := 14.0        # energy/sec while active
var flashlight_range := 260.0       # cone length
var flashlight_half_angle := 28.0   # degrees, half-cone
# --- end flashlight ---
var encounter_index := 0
var encounter_active := false
var reward_pending := false
var run_over := false
var debug_visible := true
var debug_immortal := false
var last_event := "Booted MVP-0 sandbox"
var enemies: Array = []
var beam_segments: Array = []
var lit_zones: Array = []
var beam_flash := 0.0
var beam_pulse_timer := 0.0
var hit_flashes: Array = []
var sfx_players := {}
var sfx_cache := {}
var ui_layer: CanvasLayer
var hud_label: RichTextLabel
var status_label: RichTextLabel
var reward_panel: PanelContainer
var reward_title_label: Label
var reward_buttons: Array[Button] = []
var reward_selection_index := 0
var reward_resolution_in_progress := false
var end_panel: PanelContainer
var end_title_label: Label
var end_body_label: RichTextLabel
var help_collapsed := false
var run_summary := RunSummary.make_tracker()
var world_layer: Node2D
var fx_layer: Node2D
var player_node: Node2D
var arena_node: Node2D
var encounters := EncounterDefs.LIST.duplicate(true)

func _ready() -> void:
	randomize()
	_apply_skill_defaults()
	RunSummary.reset(self)
	_setup_scene()
	_start_encounter(0)

func _setup_scene() -> void:
	world_layer = Node2D.new()
	add_child(world_layer)
	arena_node = Node2D.new()
	arena_node.name = "Arena"
	world_layer.add_child(arena_node)
	player_node = Node2D.new()
	player_node.name = "Player"
	world_layer.add_child(player_node)
	fx_layer = Node2D.new()
	fx_layer.name = "FX"
	world_layer.add_child(fx_layer)
	var camera := Camera2D.new()
	camera.enabled = true
	camera.position = Vector2(640, 360)
	add_child(camera)
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	_build_hud()
	SfxController.setup(self)
	queue_redraw()

func _apply_skill_defaults() -> void:
	var prism_surge: Dictionary = SkillDefs.get_skill("prism_surge")
	prism_surge_unlocked = not prism_surge.is_empty()
	prism_surge_cooldown = float(prism_surge.get("cooldown", 6.0))
	prism_surge_timer = 0.0
	prism_surge_damage = float(prism_surge.get("damage", 20.0))
	prism_surge_radius = float(prism_surge.get("radius", 118.0))
	prism_surge_push_distance = float(prism_surge.get("push_distance", 96.0))
	prism_surge_energy_refund_on_hit = float(prism_surge.get("energy_refund_on_hit", 8.0))
	prism_surge_special_lock_duration = float(prism_surge.get("special_lock_duration", 2.2))
	prism_surge_light_burn_duration = float(prism_surge.get("light_burn_duration", 4.0))
	prism_surge_light_burn_tick = float(prism_surge.get("light_burn_tick", 0.5))
	prism_surge_light_burn_damage = float(prism_surge.get("light_burn_damage", 1.5))

func _make_panel_style(bg: Color, border: Color, border_width: int = 2, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style

func _build_hud() -> void:
	hud_label = RichTextLabel.new()
	hud_label.fit_content = true
	hud_label.bbcode_enabled = true
	hud_label.scroll_active = false
	hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_label.position = Vector2(20, 16)
	hud_label.size = Vector2(460, 200)
	hud_label.add_theme_stylebox_override("normal", _make_panel_style(Color(0.05, 0.07, 0.11, 0.84), Color(0.36, 0.5, 0.7, 0.95), 2, 10))
	hud_label.add_theme_constant_override("margin_left", 14)
	hud_label.add_theme_constant_override("margin_top", 10)
	hud_label.add_theme_constant_override("margin_right", 14)
	hud_label.add_theme_constant_override("margin_bottom", 10)
	ui_layer.add_child(hud_label)
	status_label = RichTextLabel.new()
	status_label.fit_content = true
	status_label.bbcode_enabled = true
	status_label.scroll_active = false
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_label.position = Vector2(824, 18)
	status_label.size = Vector2(432, 190)
	status_label.visible = false
	status_label.add_theme_stylebox_override("normal", _make_panel_style(Color(0.04, 0.05, 0.09, 0.76), Color(0.27, 0.35, 0.52, 0.9), 2, 10))
	status_label.add_theme_constant_override("margin_left", 12)
	status_label.add_theme_constant_override("margin_top", 8)
	status_label.add_theme_constant_override("margin_right", 12)
	status_label.add_theme_constant_override("margin_bottom", 8)
	ui_layer.add_child(status_label)
	RewardController.build_panel(self)
	end_panel = PanelContainer.new()
	end_panel.visible = false
	end_panel.position = Vector2(360, 210)
	end_panel.size = Vector2(560, 220)
	end_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.07, 0.11, 0.96), Color(0.95, 0.9, 0.55, 1.0), 3, 12))
	var end_vb := VBoxContainer.new()
	end_vb.add_theme_constant_override("separation", 10)
	end_panel.add_child(end_vb)
	end_title_label = Label.new()
	end_title_label.text = "Run complete"
	end_vb.add_child(end_title_label)
	end_body_label = RichTextLabel.new()
	end_body_label.fit_content = true
	end_body_label.bbcode_enabled = true
	end_body_label.scroll_active = false
	end_body_label.custom_minimum_size = Vector2(0, 110)
	end_vb.add_child(end_body_label)
	var restart_button := Button.new()
	restart_button.text = "Restart run [R]"
	restart_button.custom_minimum_size = Vector2(0, 44)
	restart_button.pressed.connect(_restart_run)
	end_vb.add_child(restart_button)
	ui_layer.add_child(end_panel)
	_update_ui()

func _input(event: InputEvent) -> void:
	DebugActions.handle_key_input(self, event)

func _process(delta: float) -> void:
	if DebugActions.handle_process_actions(self):
		return
	if reward_pending:
		RewardController.handle_input(self)
		_update_ui()
		queue_redraw()
		return
	if run_over:
		_update_ui()
		queue_redraw()
		return
	beam_timer = max(beam_timer - delta, 0.0)
	prism_timer = max(prism_timer - delta, 0.0)
	prism_surge_timer = max(prism_surge_timer - delta, 0.0)
	beam_flash = max(beam_flash - delta * 4.5, 0.0)
	beam_pulse_timer = max(beam_pulse_timer - delta, 0.0)
	_update_hit_flashes(delta)
	if beam_pulse_timer <= 0.0 and not beam_segments.is_empty():
		beam_segments.clear()
	lit_zones = _build_lit_zones()
	energy = min(max_energy, energy + energy_regen * delta)
	if prism_node and prism_timer <= 0.0:
		prism_node.queue_free()
		prism_node = null
	_handle_player(delta)
	_update_enemies(delta)
	_check_encounter_complete()
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
		_cast_refraction_beam(mouse_world)
	if Input.is_action_just_pressed("place_prism"):
		_place_prism(mouse_world)
	if Input.is_action_just_pressed("cast_prism_surge"):
		_cast_prism_surge()
	if prism_node:
		prism_node.position = prism_node.position.clamp(ARENA_RECT.position + Vector2(24, 24), ARENA_RECT.end - Vector2(24, 24))

func _cast_refraction_beam(target: Vector2) -> void:
	BeamResolver.cast_beam(self, target)

func _redirected_prism_direction(direction: Vector2) -> Vector2:
	return BeamResolver.redirected_prism_direction(self, direction)

func _cast_prism_surge() -> void:
	SkillController.cast_prism_surge(self)

func current_prism_radius() -> float:
	return PRISM_RADIUS + prism_radius_bonus

func current_prism_redirect_angle() -> float:
	return PRISM_REDIRECT_ANGLE + prism_redirect_angle_bonus

func _current_encounter() -> Dictionary:
	return EncounterDefs.get_encounter(encounter_index)

func _place_prism(target: Vector2) -> void:
	if prism_timer > 0.0:
		last_event = "Prism Node recharging"
		return
	prism_timer = prism_cooldown
	if prism_node:
		prism_node.queue_free()
	prism_node = Node2D.new()
	prism_node.position = target.clamp(ARENA_RECT.position + Vector2(32, 32), ARENA_RECT.end - Vector2(32, 32))
	world_layer.add_child(prism_node)
	var marker := Polygon2D.new()
	marker.polygon = PackedVector2Array([Vector2(0, -20), Vector2(18, 0), Vector2(0, 20), Vector2(-18, 0)])
	marker.color = PRISM_COLOR
	prism_node.add_child(marker)
	prism_timer = prism_duration
	RunSummary.note_prism_placed(self)
	last_event = "Prism Node deployed"

func _toggle_flashlight() -> void:
	if not flashlight_on and energy <= 0.0:
		last_event = "No energy for flashlight"
		return
	flashlight_on = !flashlight_on
	last_event = "Flashlight %s" % ("ON" if flashlight_on else "OFF")

func _is_in_flashlight_cone(pos: Vector2) -> bool:
	if not flashlight_on:
		return false
	var to_pos := pos - player_pos
	var dist := to_pos.length()
	if dist > flashlight_range or dist < 1.0:
		return false
	var angle_to: float = absf(facing.angle_to(to_pos.normalized()))
	return rad_to_deg(angle_to) <= flashlight_half_angle

func _apply_contact_damage(amount: float) -> void:
	if debug_immortal:
		last_event = "Immortal mode absorbed damage"
		return
	player_hp -= amount
	RunSummary.note_damage_taken(self, amount)
	if player_hp <= 0.0:
		player_hp = 0.0
		run_over = true
		RunSummary.finish(self)
		last_event = "Lantern extinguished"

func _update_enemies(delta: float) -> void:
	EnemyController.update_enemies(self, delta)

func _check_encounter_complete() -> void:
	EncounterController.check_complete(self)

func _start_encounter(index: int) -> void:
	EncounterController.start_encounter(self, index)

func _spawn_enemy(type: String, pos: Vector2) -> void:
	EncounterController.spawn_enemy(self, type, pos)

func _show_rewards() -> void:
	RewardController.show_rewards(self)

func _restart_run() -> void:
	player_hp = player_max_hp
	energy = max_energy
	beam_timer = 0.0
	prism_timer = 0.0
	beam_range = 330.0
	beam_damage = 18.0
	beam_bounces = 1
	prism_duration = 12.0
	encounters = EncounterDefs.LIST.duplicate(true)
	prism_radius_bonus = 0.0
	prism_redirect_angle_bonus = 0.0
	prism_redirect_damage_bonus = 0.0
	prism_redirect_bonus_bounces = 0
	_apply_skill_defaults()
	player_pos = Vector2(260, 360)
	if prism_node:
		prism_node.queue_free()
		prism_node = null
	flashlight_on = false
	run_over = false
	reward_pending = false
	reward_resolution_in_progress = false
	reward_panel.visible = false
	end_panel.visible = false
	beam_segments.clear()
	hit_flashes.clear()
	beam_pulse_timer = 0.0
	RunSummary.reset(self)
	_start_encounter(0)
	last_event = "Run restarted"

func _random_spawn() -> Vector2:
	return Vector2(randf_range(840, 1080), randf_range(120, 600))

func _add_hit_flash(pos: Vector2, radius: float, color: Color, duration: float = 0.14) -> void:
	hit_flashes.append({"pos": pos, "radius": radius, "color": color, "timer": duration, "duration": duration})

func _update_hit_flashes(delta: float) -> void:
	for i in range(hit_flashes.size() - 1, -1, -1):
		hit_flashes[i]["timer"] = max(float(hit_flashes[i]["timer"]) - delta, 0.0)
		if hit_flashes[i]["timer"] <= 0.0:
			hit_flashes.remove_at(i)

func _build_lit_zones() -> Array:
	var zones: Array = []
	zones.append({"pos": player_pos, "radius": 140.0, "color": Color(1.0, 0.94, 0.7, 0.08)})
	if prism_node:
		zones.append({"pos": prism_node.position, "radius": 88.0, "color": Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.08)})
	for segment: Array in beam_segments:
		var a: Vector2 = segment[0]
		var b: Vector2 = segment[1]
		var distance: float = a.distance_to(b)
		var steps: int = max(2, int(ceil(distance / 70.0)))
		for step in range(steps + 1):
			var t: float = float(step) / float(steps)
			var pos: Vector2 = a.lerp(b, t)
			var alpha := 0.045 if step == 0 or step == steps else 0.07
			zones.append({"pos": pos, "radius": 42.0, "color": Color(0.55, 0.9, 1.0, alpha)})
		zones.append({"pos": a.lerp(b, 0.5), "radius": max(distance * 0.36, 72.0), "color": Color(0.65, 0.95, 1.0, 0.08)})
		zones.append({"pos": b, "radius": 60.0, "color": Color(1.0, 0.96, 0.72, 0.1)})
	for enemy: Dictionary in enemies:
		if enemy["alive"] and is_instance_valid(enemy["node"]):
			var enemy_color := Color(1.0, 0.72, 0.42, 0.03) if enemy["type"] == "moth" else Color(0.74, 0.58, 1.0, 0.035)
			zones.append({"pos": enemy["node"].position, "radius": 44.0, "color": enemy_color})
	return zones

func _update_ui() -> void:
	var beam_ready := "[color=#8be9fd]READY[/color]" if beam_timer <= 0.0 else "[color=#ffb86c]%.2fs[/color]" % beam_timer
	var prism_state := "[color=#8be9fd]ACTIVE %.1fs[/color]" % prism_timer if prism_node else ("[color=#ffb86c]%.1fs[/color]" % prism_timer if prism_timer > 0.0 else "[color=#50fa7b]READY[/color]")
	var surge_state := "[color=#8be9fd]READY[/color]" if prism_surge_timer <= 0.0 else "[color=#ffb86c]%.1fs[/color]" % prism_surge_timer
	var current_encounter := _current_encounter()
	var encounter_title := String(current_encounter.get("title", "Encounter"))
	var objective := "Pick one upgrade" if reward_pending else (String(current_encounter.get("summary", "Survive encounter and route beam through walls/prism")) if not run_over else ("Run complete — restart from center panel or R" if player_hp > 0.0 else "Run failed — restart from center panel or R"))
	var immortal_text := "[color=#50fa7b]ON[/color]" if debug_immortal else "[color=#6272a4]OFF[/color]"
	var flashlight_text := "[color=#f1fa8c]ON[/color] (%.0f/s)" % flashlight_drain if flashlight_on else "[color=#6272a4]OFF[/color]"
	hud_label.text = "[b]Lantern Engine %s[/b]\n[color=#a4b1cd]Encounter:[/color] %s\n[color=#a4b1cd]Objective:[/color] %s\n\n[color=#ff6b6b]HP[/color]  %.0f / %.0f  %s\n[color=#8be9fd]EN[/color]  %.0f / %.0f  %s\n\n[color=#f1fa8c]Beam[/color] %.0f dmg  |  %.0f range  |  %d bounce\n[color=#f1fa8c]Prism[/color] +%.0f redirect dmg | +%.0f radius | +%.0f° bend | +%d post-prism bounce\n[color=#f1fa8c]Surge[/color] %.0f burst  |  %.0f radius  |  [color=#fff1a8]Light Burn[/color] %.1f/%.1fs for %.1fs  |  [color=#a4b1cd]Q[/color] %s\n[color=#f1fa8c]Flashlight[/color] %s    [color=#a4b1cd]Beam:[/color] %s    [color=#a4b1cd]Prism:[/color] %s\n[color=#a4b1cd]Encounter:[/color] %d / %d    [color=#a4b1cd]Enemies:[/color] %d\n[color=#a4b1cd]Immortal:[/color] %s" % [BUILD_LABEL, encounter_title, objective, player_hp, player_max_hp, HudText.bar(player_hp, player_max_hp), energy, max_energy, HudText.bar(energy, max_energy), beam_damage, beam_range, beam_bounces, prism_redirect_damage_bonus, prism_radius_bonus, prism_redirect_angle_bonus, prism_redirect_bonus_bounces, prism_surge_damage, prism_surge_radius, prism_surge_light_burn_damage, prism_surge_light_burn_tick, prism_surge_light_burn_duration, surge_state, flashlight_text, beam_ready, prism_state, min(encounter_index + 1, encounters.size()), encounters.size(), _alive_enemy_count(), immortal_text]
	var help_hint := "[color=#8be9fd]F1 show full help[/color]" if help_collapsed else "[color=#8be9fd]F1 hide full help[/color]"
	var immortal_hint := "[color=#50fa7b]ON[/color]" if debug_immortal else "[color=#6272a4]OFF[/color]"
	if reward_pending:
		if reward_title_label:
			reward_title_label.text = "Choose one Prism upgrade — current beam: %.0f dmg | %.0f range | %d bounce" % [beam_damage, beam_range, beam_bounces]
		RewardController.update_button_states(self)
		status_label.text = "[b]Reward pause[/b]\nChoose one Prism upgrade before the next encounter.\n\n[color=#8be9fd]1/2/3[/color] direct pick\n[color=#8be9fd]W/S or ↑/↓[/color] move highlight\n[color=#8be9fd]E / Enter[/color] confirm highlighted reward\n\n[b]Current kit[/b]\nBeam %.0f dmg | %.0f range | %d bounce\nSurge %.0f burst | %.0f radius | Light Burn %.1f/%.1fs | Q" % [beam_damage, beam_range, beam_bounces, prism_surge_damage, prism_surge_radius, prism_surge_light_burn_damage, prism_surge_light_burn_tick]
	elif help_collapsed and not run_over:
		status_label.text = "[b]Event[/b]\n%s\n\n%s\n[color=#6272a4]Key actions: F1 help | F flashlight | R restart | F4 immortal %s[/color]" % [last_event, help_hint, immortal_hint]
	else:
		status_label.text = "[b]Readability legend[/b]\n[color=#f1fa8c]Warm core[/color] + [color=#8be9fd]cyan bloom[/color] = live beam path\n[color=#8be9fd]Cyan wall ring[/color] = bounce / redirect point\n[color=#8be9fd]Diamond aura[/color] = Prism Node\n[color=#ffb86c]Orange[/color] moth | [color=#bd93f9]Purple[/color] hollow\n\n[b]Controls[/b]\nWASD move | LMB beam | RMB prism | Q Prism Surge | F flashlight | R restart\nReward: 1/2/3 or W/S + E/Enter\nF1 help | F2 refill | F3 reward | F4 immortal | 1/2 spawn\n\n[b]Event[/b]\n%s" % [last_event]
	status_label.visible = true
	if run_over:
		end_title_label.text = "Run complete" if player_hp > 0.0 else "Lantern extinguished"
		end_body_label.text = RunSummary.build_report(self, player_hp > 0.0) + "\n\nPress [b]R[/b] or click [b]Restart run[/b] below."
		end_panel.visible = true
	else:
		end_panel.visible = false

func _alive_enemy_count() -> int:
	var alive := 0
	for enemy: Dictionary in enemies:
		if enemy["alive"]:
			alive += 1
	return alive

func _draw() -> void:
	var viewport_rect := get_viewport_rect()
	draw_rect(viewport_rect, Color(0.01, 0.015, 0.03, 1.0), true)
	draw_rect(ARENA_RECT.grow(28.0), Color(0.02, 0.04, 0.07, 0.88), true)
	draw_rect(ARENA_RECT, Color("111827"), true)
	draw_rect(Rect2(ARENA_RECT.position + Vector2(10, 10), ARENA_RECT.size - Vector2(20, 20)), Color(0.06, 0.08, 0.14, 0.95), true)
	for zone: Dictionary in lit_zones:
		draw_circle(zone["pos"], zone["radius"], zone["color"])
	for flash: Dictionary in hit_flashes:
		var flash_t := clampf(float(flash["timer"]) / float(flash["duration"]), 0.0, 1.0)
		var flash_radius := lerpf(float(flash["radius"]) * 1.55, float(flash["radius"]) * 0.72, 1.0 - flash_t)
		var flash_color: Color = flash["color"]
		draw_circle(flash["pos"], flash_radius, Color(flash_color.r, flash_color.g, flash_color.b, 0.12 * flash_t))
		draw_arc(flash["pos"], flash_radius, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, 0.45 * flash_t), 2.0)
	for x in range(int(ARENA_RECT.position.x) + 64, int(ARENA_RECT.end.x), 128):
		draw_line(Vector2(x, ARENA_RECT.position.y + 14), Vector2(x, ARENA_RECT.end.y - 14), Color(0.3, 0.42, 0.58, 0.08), 1.0)
	for y in range(int(ARENA_RECT.position.y) + 64, int(ARENA_RECT.end.y), 128):
		draw_line(Vector2(ARENA_RECT.position.x + 14, y), Vector2(ARENA_RECT.end.x - 14, y), Color(0.3, 0.42, 0.58, 0.08), 1.0)
	draw_rect(ARENA_RECT, Color(0.46, 0.68, 0.95, 0.95), false, 6.0)
	draw_rect(ARENA_RECT.grow(-8.0), Color(0.76, 0.9, 1.0, 0.18), false, 2.0)
	draw_rect(Rect2(ARENA_RECT.position + Vector2(140, 130), Vector2(180, 140)), Color(0.18, 0.21, 0.28, 0.18), true)
	draw_rect(Rect2(ARENA_RECT.position + Vector2(720, 320), Vector2(160, 150)), Color(0.18, 0.21, 0.28, 0.18), true)
	if prism_node:
		var pulse := 0.78 + 0.22 * sin(Time.get_ticks_msec() / 160.0)
		draw_circle(prism_node.position, 56.0, Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.04 * pulse))
		draw_circle(prism_node.position, 40.0, Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.08 * pulse))
		draw_arc(prism_node.position, 26.0, 0.0, TAU, 40, Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.85), 3.0)
		draw_arc(prism_node.position, 18.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.45), 1.5)
		draw_line(prism_node.position + Vector2(-24, 0), prism_node.position + Vector2(24, 0), Color(1.0, 1.0, 1.0, 0.16), 2.0)
		draw_line(prism_node.position + Vector2(0, -24), prism_node.position + Vector2(0, 24), Color(1.0, 1.0, 1.0, 0.16), 2.0)
		var prism_preview_dir := _redirected_prism_direction(facing)
		draw_circle(prism_node.position, current_prism_radius(), Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.08))
		draw_circle(prism_node.position, prism_surge_radius, Color(0.62, 0.94, 1.0, 0.035 if prism_surge_timer <= 0.0 else 0.02))
		draw_line(prism_node.position, prism_node.position + prism_preview_dir * 46.0, Color(PRISM_COLOR.r, PRISM_COLOR.g, PRISM_COLOR.b, 0.4), 2.0)
	# --- Flashlight cone ---
	if flashlight_on:
		var cone_angle := deg_to_rad(flashlight_half_angle)
		var base_angle := facing.angle()
		var cone_segments := 24
		var cone_points := PackedVector2Array()
		cone_points.append(player_pos)
		for ci in range(cone_segments + 1):
			var t_angle := base_angle - cone_angle + (2.0 * cone_angle) * (float(ci) / float(cone_segments))
			cone_points.append(player_pos + Vector2(cos(t_angle), sin(t_angle)) * flashlight_range)
		var cone_colors := PackedColorArray()
		for ci in range(cone_points.size()):
			cone_colors.append(Color(1.0, 0.96, 0.72, 0.12))
		draw_polygon(cone_points, cone_colors)
		# Cone edge lines
		var left_dir := Vector2(cos(base_angle - cone_angle), sin(base_angle - cone_angle))
		var right_dir := Vector2(cos(base_angle + cone_angle), sin(base_angle + cone_angle))
		draw_line(player_pos, player_pos + left_dir * flashlight_range, Color(1.0, 0.94, 0.6, 0.35), 2.0)
		draw_line(player_pos, player_pos + right_dir * flashlight_range, Color(1.0, 0.94, 0.6, 0.35), 2.0)
		# Cone arc at range
		draw_arc(player_pos, flashlight_range, base_angle - cone_angle, base_angle + cone_angle, 20, Color(1.0, 0.94, 0.6, 0.25), 2.0)
	# --- End flashlight cone ---

	for enemy: Dictionary in enemies:
		if not is_instance_valid(enemy["node"]):
			continue
		var color: Color = Color("ffb86c") if enemy["type"] == "moth" else Color("bd93f9")
		if enemy["flash"] > 0.0:
			color = Color.WHITE
		# Disrupted transit flicker for hollows moving through light
		if enemy["type"] == "hollow" and bool(enemy.get("blink_transiting", false)):
			var t_flick := fmod(Time.get_ticks_msec() / 25.0, 2.0)
			if t_flick < 1.0:
				# Rapidly flicker visibility — skip drawing main body half the time
				draw_circle(enemy["node"].position, enemy["radius"] + 12.0, Color(1.0, 0.7, 0.3, 0.35))
				draw_arc(enemy["node"].position, enemy["radius"] + 18.0, 0.0, TAU, 16, Color(1.0, 0.85, 0.4, 0.55), 2.5)
			else:
				# Ghost afterimage
				draw_circle(enemy["node"].position, enemy["radius"] + 6.0, Color(0.74, 0.58, 1.0, 0.15))
			# Transit trail line
			var t_start: Vector2 = Vector2(enemy["blink_transit_start"])
			var t_end: Vector2 = Vector2(enemy["blink_transit_end"])
			draw_line(t_start, t_end, Color(0.74, 0.58, 1.0, 0.12), 2.0)
		# Blink windup flicker for hollows in flashlight
		if enemy["type"] == "hollow" and bool(enemy.get("blink_winding_up", false)):
			var flicker := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 35.0)
			var flicker2 := 0.5 + 0.5 * cos(Time.get_ticks_msec() / 50.0)
			# Rapid pulsing disruption rings
			draw_circle(enemy["node"].position, enemy["radius"] + 20.0, Color(1.0, 0.5, 0.3, 0.22 * flicker))
			draw_arc(enemy["node"].position, enemy["radius"] + 16.0 * flicker2, 0.0, TAU, 16, Color(1.0, 0.85, 0.4, 0.65 * flicker), 3.0)
			draw_arc(enemy["node"].position, enemy["radius"] + 8.0, 0.0, TAU, 12, Color(1.0, 0.3, 0.2, 0.4 * flicker2), 2.0)
		var special_lock_timer: float = float(enemy.get("special_lock_timer", 0.0))
		if special_lock_timer > 0.0:
			var lock_ratio: float = clampf(special_lock_timer / max(prism_surge_special_lock_duration, 0.01), 0.0, 1.0)
			draw_arc(enemy["node"].position, enemy["radius"] + 14.0, -PI * 0.5, -PI * 0.5 + TAU * lock_ratio, 24, Color(0.62, 0.94, 1.0, 0.8), 2.5)
			draw_circle(enemy["node"].position, enemy["radius"] + 10.0, Color(0.62, 0.94, 1.0, 0.08))
		var light_burn_timer: float = float(enemy.get("light_burn_timer", 0.0))
		if light_burn_timer > 0.0:
			var burn_ratio: float = clampf(light_burn_timer / max(prism_surge_light_burn_duration, 0.01), 0.0, 1.0)
			var burn_pulse: float = 0.45 + 0.55 * sin(Time.get_ticks_msec() / 70.0)
			var burn_glow: float = max(float(enemy.get("light_burn_pulse", 0.0)), 0.0)
			draw_circle(enemy["node"].position, enemy["radius"] + 7.0 + burn_glow * 8.0, Color(1.0, 0.95, 0.62, 0.08 + 0.07 * burn_pulse + burn_glow * 0.08))
			draw_arc(enemy["node"].position, enemy["radius"] + 18.0, -PI * 0.5, -PI * 0.5 + TAU * burn_ratio, 26, Color(1.0, 0.9, 0.52, 0.82), 3.0)
			draw_arc(enemy["node"].position, enemy["radius"] + 11.0 + burn_glow * 4.0, 0.0, TAU, 18, Color(1.0, 0.98, 0.8, 0.26 + burn_glow * 0.24), 1.8)
		# Flashlight reveal shimmer for hollows
		var is_revealed: bool = bool(enemy.get("revealed_by_light", false)) or float(enemy.get("shimmer_timer", 0.0)) > 0.0
		if enemy["type"] == "hollow" and is_revealed:
			var shimmer_pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 80.0)
			draw_circle(enemy["node"].position, enemy["radius"] + 14.0, Color(1.0, 0.94, 0.6, 0.18 * shimmer_pulse))
			draw_arc(enemy["node"].position, enemy["radius"] + 10.0, 0.0, TAU, 20, Color(1.0, 0.96, 0.72, 0.5 * shimmer_pulse), 2.0)
		draw_circle(enemy["node"].position + Vector2(4, 6), enemy["radius"] + 2.0, SHADOW_COLOR)
		draw_circle(enemy["node"].position, enemy["radius"] + 8.0, Color(color.r, color.g, color.b, 0.1))
		draw_circle(enemy["node"].position, enemy["radius"] + 4.0, Color(color.r, color.g, color.b, 0.18))
		draw_circle(enemy["node"].position, enemy["radius"], color)
		draw_arc(enemy["node"].position, enemy["radius"] + 6.0, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.08), 1.0)
	for i in range(beam_segments.size()):
		var segment: Array = beam_segments[i]
		var pulse_alpha: float = clamp(beam_pulse_timer / BEAM_PULSE_DURATION, 0.0, 1.0)
		var glow_alpha := 0.34 * pulse_alpha
		draw_line(segment[0], segment[1], Color(0.48, 0.92, 1.0, glow_alpha * 0.45), 28.0)
		draw_line(segment[0], segment[1], Color(0.55, 0.95, 1.0, glow_alpha * 0.7), 18.0)
		draw_line(segment[0], segment[1], Color(BEAM_OUTER_COLOR.r, BEAM_OUTER_COLOR.g, BEAM_OUTER_COLOR.b, BEAM_OUTER_COLOR.a * pulse_alpha), 12.0)
		draw_line(segment[0], segment[1], Color(BEAM_INNER_COLOR.r, BEAM_INNER_COLOR.g, BEAM_INNER_COLOR.b, BEAM_INNER_COLOR.a * pulse_alpha), 5.0)
		var distance: float = segment[0].distance_to(segment[1])
		var sparkle_count: int = max(1, int(ceil(distance / 110.0)))
		for sparkle_index in range(1, sparkle_count):
			var sparkle_t: float = float(sparkle_index) / float(sparkle_count)
			var sparkle_pos: Vector2 = segment[0].lerp(segment[1], sparkle_t)
			draw_circle(sparkle_pos, 8.0 + 4.0 * pulse_alpha, Color(0.72, 0.97, 1.0, 0.08 * pulse_alpha))
		draw_circle(segment[0], 5.0 + 3.0 * pulse_alpha, Color(1.0, 1.0, 1.0, 0.28 * pulse_alpha))
		var end_radius: float = 11.0 if i < beam_segments.size() - 1 else 8.0
		var end_color: Color = BOUNCE_COLOR if i < beam_segments.size() - 1 else Color(0.92, 1.0, 1.0, 0.82)
		draw_circle(segment[1], end_radius + 6.0 * pulse_alpha, Color(end_color.r, end_color.g, end_color.b, 0.12 * pulse_alpha))
		draw_circle(segment[1], end_radius * 0.55 + 2.0 * pulse_alpha, Color(end_color.r, end_color.g, end_color.b, end_color.a * pulse_alpha))
	draw_circle(player_pos + Vector2(4, 6), PLAYER_RADIUS + 4.0, SHADOW_COLOR)
	draw_circle(player_pos, PLAYER_RADIUS + 16.0, Color(1.0, 0.94, 0.7, 0.05))
	draw_circle(player_pos, PLAYER_RADIUS + 9.0 + beam_flash * 8.0, Color(0.95, 0.98, 0.63, 0.14 + beam_flash * 0.22))
	draw_circle(player_pos, PLAYER_RADIUS + beam_flash * 5.0, Color("f1fa8c"))
	draw_arc(player_pos, PLAYER_RADIUS + 5.0, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.18), 1.5)
	draw_line(player_pos, player_pos + facing * 24.0, Color.BLACK, 4.0)
	draw_line(player_pos, player_pos + facing * 24.0, Color(0.16, 0.2, 0.28, 1.0), 2.0)
	var mouse_world := get_global_mouse_position()
	if ARENA_RECT.has_point(mouse_world):
		draw_arc(mouse_world, 10.0, 0.0, TAU, 20, Color(0.85, 0.95, 1.0, 0.45), 1.5)
		draw_line(mouse_world + Vector2(-6, 0), mouse_world + Vector2(6, 0), Color(0.85, 0.95, 1.0, 0.25), 1.0)
		draw_line(mouse_world + Vector2(0, -6), mouse_world + Vector2(0, 6), Color(0.85, 0.95, 1.0, 0.25), 1.0)
