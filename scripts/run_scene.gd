extends Node2D
class_name RunScene

const ARENA_RECT := Rect2(Vector2(64, 64), Vector2(1152, 592))
const PLAYER_RADIUS := 14.0
const ENEMY_CONTACT_RADIUS := 20.0
const UPGRADE_POOL := [
	{"id": "extra_bounce", "title": "+1 Bounce", "desc": "Refraction Beam gains one extra wall bounce.", "apply": "bounce"},
	{"id": "beam_range", "title": "Longer Beam", "desc": "Refraction Beam range +180.", "apply": "range"},
	{"id": "beam_damage", "title": "Focused Lens", "desc": "Refraction Beam damage +8.", "apply": "damage"}
]

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
var prism_node: Node2D
var player_velocity := Vector2.ZERO
var player_speed := 285.0
var player_pos := Vector2(260, 360)
var facing := Vector2.RIGHT
var beam_range := 330.0
var beam_damage := 18.0
var beam_bounces := 1
var encounter_index := 0
var encounter_active := false
var reward_pending := false
var run_over := false
var debug_visible := true
var last_event := "Booted MVP-0 sandbox"
var enemies: Array = []
var beam_segments: Array = []
var beam_flash := 0.0
var ui_layer: CanvasLayer
var hud_label: RichTextLabel
var status_label: RichTextLabel
var reward_panel: PanelContainer
var reward_buttons: Array[Button] = []
var world_layer: Node2D
var fx_layer: Node2D
var player_node: Node2D
var arena_node: Node2D
var encounters := [
	[
		{"type": "moth", "pos": Vector2(920, 200)},
		{"type": "moth", "pos": Vector2(980, 500)}
	],
	[
		{"type": "moth", "pos": Vector2(980, 220)},
		{"type": "hollow", "pos": Vector2(1030, 360)},
		{"type": "moth", "pos": Vector2(980, 520)}
	],
	[
		{"type": "hollow", "pos": Vector2(1000, 180)},
		{"type": "hollow", "pos": Vector2(1000, 540)},
		{"type": "moth", "pos": Vector2(940, 360)}
	]
]

func _ready() -> void:
	randomize()
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
	queue_redraw()

func _build_hud() -> void:
	hud_label = RichTextLabel.new()
	hud_label.fit_content = true
	hud_label.bbcode_enabled = true
	hud_label.scroll_active = false
	hud_label.position = Vector2(20, 16)
	hud_label.size = Vector2(480, 220)
	ui_layer.add_child(hud_label)
	status_label = RichTextLabel.new()
	status_label.fit_content = true
	status_label.bbcode_enabled = true
	status_label.scroll_active = false
	status_label.position = Vector2(20, 132)
	status_label.size = Vector2(520, 240)
	ui_layer.add_child(status_label)
	reward_panel = PanelContainer.new()
	reward_panel.visible = false
	reward_panel.position = Vector2(360, 170)
	reward_panel.size = Vector2(560, 320)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	reward_panel.add_child(vb)
	var title := Label.new()
	title.text = "Choose one Prism upgrade"
	vb.add_child(title)
	for i in 3:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 72)
		btn.pressed.connect(func(): _select_reward(i))
		vb.add_child(btn)
		reward_buttons.append(btn)
	ui_layer.add_child(reward_panel)
	_update_ui()

func _process(delta: float) -> void:
	if run_over:
		if Input.is_action_just_pressed("restart_run"):
			_restart_run()
		return
	beam_timer = max(beam_timer - delta, 0.0)
	prism_timer = max(prism_timer - delta, 0.0)
	beam_flash = max(beam_flash - delta * 2.0, 0.0)
	energy = min(max_energy, energy + energy_regen * delta)
	if prism_node and prism_timer <= 0.0:
		prism_node.queue_free()
		prism_node = null
	if Input.is_action_just_pressed("debug_toggle"):
		debug_visible = !debug_visible
		status_label.visible = debug_visible
	if Input.is_action_just_pressed("quick_refill"):
		player_hp = player_max_hp
		energy = max_energy
		last_event = "Dev refill"
	if Input.is_action_just_pressed("spawn_moth"):
		_spawn_enemy("moth", _random_spawn())
	if Input.is_action_just_pressed("spawn_hollow"):
		_spawn_enemy("hollow", _random_spawn())
	if Input.is_action_just_pressed("grant_upgrade") and not reward_pending:
		_show_rewards()
	if Input.is_action_just_pressed("restart_run"):
		_restart_run()
	if reward_pending:
		_update_ui()
		queue_redraw()
		return
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
	if Input.is_action_just_pressed("cast_beam"):
		_cast_refraction_beam(mouse_world)
	if Input.is_action_just_pressed("place_prism"):
		_place_prism(mouse_world)
	if prism_node:
		prism_node.position = prism_node.position.clamp(ARENA_RECT.position + Vector2(24, 24), ARENA_RECT.end - Vector2(24, 24))

func _cast_refraction_beam(target: Vector2) -> void:
	if beam_timer > 0.0:
		last_event = "Beam on cooldown"
		return
	if energy < beam_cost:
		last_event = "Low energy"
		return
	energy -= beam_cost
	beam_timer = beam_cooldown
	beam_flash = 0.5
	var direction := (target - player_pos).normalized()
	if direction == Vector2.ZERO:
		direction = facing
	beam_segments.clear()
	var current_origin := player_pos
	var current_direction := direction
	var bounces_left := beam_bounces
	for i in range(beam_bounces + 1):
		var segment := _beam_to_bounds(current_origin, current_direction, beam_range)
		beam_segments.append(segment)
		_damage_enemies_along_segment(segment[0], segment[1], beam_damage + float(beam_bounces - bounces_left) * 4.0)
		if prism_node:
			var prism_hit := _segment_circle_hit(segment[0], segment[1], prism_node.position, 18.0)
			if prism_hit.size() > 0:
				var hit_pos: Vector2 = prism_hit["point"]
				beam_segments[-1][1] = hit_pos
				_damage_enemies_along_segment(segment[0], hit_pos, beam_damage)
				var redirected := current_direction.rotated(deg_to_rad(55.0 if current_direction.y >= 0.0 else -55.0)).normalized()
				var redirect_segment := _beam_to_bounds(hit_pos, redirected, beam_range * 0.7)
				beam_segments.append(redirect_segment)
				_damage_enemies_along_segment(redirect_segment[0], redirect_segment[1], beam_damage + 6.0)
				last_event = "Refraction Beam redirected through Prism Node"
				break
		if bounces_left <= 0:
			break
		var bounce_result := _reflect_if_wall(segment[0], segment[1], current_direction)
		if bounce_result.is_empty():
			break
		current_origin = bounce_result["point"] + bounce_result["direction"] * 4.0
		current_direction = bounce_result["direction"]
		bounces_left -= 1
		last_event = "Beam bounced off arena wall"
	if beam_segments.is_empty():
		last_event = "Beam fizzled"

func _beam_to_bounds(origin: Vector2, direction: Vector2, length: float) -> Array:
	var end := origin + direction * length
	var t := 1.0
	if direction.x > 0.0:
		t = min(t, (ARENA_RECT.end.x - origin.x) / max(direction.x * length, 0.001))
	elif direction.x < 0.0:
		t = min(t, (ARENA_RECT.position.x - origin.x) / min(direction.x * length, -0.001))
	if direction.y > 0.0:
		t = min(t, (ARENA_RECT.end.y - origin.y) / max(direction.y * length, 0.001))
	elif direction.y < 0.0:
		t = min(t, (ARENA_RECT.position.y - origin.y) / min(direction.y * length, -0.001))
	end = origin + direction * length * clamp(t, 0.0, 1.0)
	return [origin, end]

func _reflect_if_wall(start: Vector2, end: Vector2, direction: Vector2) -> Dictionary:
	var reflected := direction
	var hit := end
	var hit_wall := false
	if is_equal_approx(end.x, ARENA_RECT.position.x) or is_equal_approx(end.x, ARENA_RECT.end.x):
		reflected.x *= -1.0
		hit_wall = true
	if is_equal_approx(end.y, ARENA_RECT.position.y) or is_equal_approx(end.y, ARENA_RECT.end.y):
		reflected.y *= -1.0
		hit_wall = true
	if not hit_wall:
		return {}
	return {"point": hit, "direction": reflected.normalized()}

func _segment_circle_hit(a: Vector2, b: Vector2, center: Vector2, radius: float) -> Dictionary:
	var ab: Vector2 = b - a
	var t: float = clamp((center - a).dot(ab) / max(ab.length_squared(), 0.001), 0.0, 1.0)
	var p: Vector2 = a + ab * t
	if p.distance_to(center) <= radius:
		return {"point": p, "t": t}
	return {}

func _damage_enemies_along_segment(a: Vector2, b: Vector2, damage: float) -> void:
	for enemy: Dictionary in enemies:
		if not enemy["alive"]:
			continue
		var hit: Dictionary = _segment_circle_hit(a, b, enemy["node"].position, enemy["radius"])
		if hit.size() > 0:
			enemy["hp"] -= damage
			enemy["flash"] = 0.25
			last_event = "Hit %s for %.0f" % [enemy["type"], damage]
			if enemy["hp"] <= 0.0:
				enemy["alive"] = false
				enemy["death_timer"] = 0.35
				last_event = "%s eliminated" % String(enemy["type"]).capitalize()

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
	marker.color = Color("8be9fd")
	prism_node.add_child(marker)
	prism_timer = prism_duration
	last_event = "Prism Node deployed"

func _update_enemies(delta: float) -> void:
	for enemy: Dictionary in enemies:
		if not enemy["alive"]:
			enemy["death_timer"] -= delta
			enemy["flash"] = max(enemy["flash"] - delta, 0.0)
			enemy["node"].scale = Vector2.ONE * max(enemy["death_timer"] * 2.0, 0.1)
			if enemy["death_timer"] <= 0.0 and is_instance_valid(enemy["node"]):
				enemy["node"].queue_free()
			continue
		enemy["flash"] = max(enemy["flash"] - delta, 0.0)
		var dir: Vector2 = (player_pos - enemy["node"].position).normalized()
		if enemy["type"] == "moth":
			enemy["node"].position += dir * enemy["speed"] * delta
		elif enemy["type"] == "hollow":
			enemy["attack_timer"] -= delta
			if enemy["attack_timer"] <= 0.0:
				enemy["attack_timer"] = 2.4
				var flank: Vector2 = Vector2(randf_range(-80, 80), randf_range(-80, 80))
				enemy["node"].position = (player_pos + dir.rotated(PI) * 140.0 + flank).clamp(ARENA_RECT.position + Vector2(32, 32), ARENA_RECT.end - Vector2(32, 32))
				last_event = "Hollow ambush blink"
			else:
				enemy["node"].position += dir * enemy["speed"] * 0.55 * delta
		if enemy["node"].position.distance_to(player_pos) < ENEMY_CONTACT_RADIUS + enemy["radius"]:
			player_hp -= enemy["contact_damage"] * delta
			if player_hp <= 0.0:
				player_hp = 0.0
				run_over = true
				last_event = "Lantern extinguished"

func _check_encounter_complete() -> void:
	if not encounter_active:
		return
	for enemy: Dictionary in enemies:
		if enemy["alive"]:
			return
	encounter_active = false
	_show_rewards()

func _start_encounter(index: int) -> void:
	encounter_index = index
	enemies.clear()
	for child in world_layer.get_children():
		if child.name.begins_with("Enemy_"):
			child.queue_free()
	encounter_active = true
	reward_pending = false
	reward_panel.visible = false
	for spec: Dictionary in encounters[min(index, encounters.size() - 1)]:
		_spawn_enemy(spec["type"], spec["pos"])
	last_event = "Encounter %d started" % [index + 1]

func _spawn_enemy(type: String, pos: Vector2) -> void:
	var node := Node2D.new()
	node.name = "Enemy_%s_%d" % [type, randi() % 9999]
	node.position = pos
	world_layer.add_child(node)
	var sprite := Polygon2D.new()
	if type == "moth":
		sprite.polygon = PackedVector2Array([Vector2(-14, 0), Vector2(0, -10), Vector2(14, 0), Vector2(0, 10)])
		sprite.color = Color("ffb86c")
		enemies.append({"node": node, "type": type, "hp": 24.0, "speed": 116.0, "radius": 16.0, "contact_damage": 14.0, "alive": true, "flash": 0.0, "death_timer": 0.0, "attack_timer": 0.0})
	else:
		sprite.polygon = PackedVector2Array([Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12), Vector2(-12, 12)])
		sprite.color = Color("bd93f9")
		enemies.append({"node": node, "type": type, "hp": 34.0, "speed": 92.0, "radius": 16.0, "contact_damage": 19.0, "alive": true, "flash": 0.0, "death_timer": 0.0, "attack_timer": 1.3})
	node.add_child(sprite)

func _show_rewards() -> void:
	reward_pending = true
	reward_panel.visible = true
	var options: Array = UPGRADE_POOL.duplicate()
	options.shuffle()
	for i in reward_buttons.size():
		var reward: Dictionary = options[i]
		reward_buttons[i].text = "%s\n%s" % [reward["title"], reward["desc"]]
		reward_buttons[i].set_meta("reward", reward)
	last_event = "Reward selection ready"

func _select_reward(index: int) -> void:
	if index >= reward_buttons.size():
		return
	var reward: Dictionary = reward_buttons[index].get_meta("reward", {})
	match reward.get("apply", ""):
		"bounce":
			beam_bounces += 1
		"range":
			beam_range += 180.0
		"damage":
			beam_damage += 8.0
	reward_pending = false
	reward_panel.visible = false
	last_event = "Selected %s" % reward.get("title", "upgrade")
	if encounter_index + 1 < encounters.size():
		_start_encounter(encounter_index + 1)
	else:
		run_over = true
		last_event = "Prototype cleared — press R to restart"

func _restart_run() -> void:
	player_hp = player_max_hp
	energy = max_energy
	beam_timer = 0.0
	prism_timer = 0.0
	beam_range = 330.0
	beam_damage = 18.0
	beam_bounces = 1
	player_pos = Vector2(260, 360)
	if prism_node:
		prism_node.queue_free()
		prism_node = null
	run_over = false
	beam_segments.clear()
	_start_encounter(0)
	last_event = "Run restarted"

func _random_spawn() -> Vector2:
	return Vector2(randf_range(840, 1080), randf_range(120, 600))

func _update_ui() -> void:
	hud_label.text = "[b]Lantern Engine MVP-0[/b]\nHP %.0f / %.0f\nEnergy %.0f / %.0f\nBeam dmg %.0f | range %.0f | bounces %d\nEncounter %d / %d%s" % [player_hp, player_max_hp, energy, max_energy, beam_damage, beam_range, beam_bounces, min(encounter_index + 1, encounters.size()), encounters.size(), "\nPress R to restart" if run_over else ""]
	status_label.text = "[b]Controls[/b] WASD move | LMB beam | RMB prism | E choose in menu | R restart\nF1 debug | F2 refill | F3 reward | 1/2 spawn enemies\n[b]Event[/b] %s\n[b]Enemies alive[/b] %d" % [last_event, _alive_enemy_count()]

func _alive_enemy_count() -> int:
	var alive := 0
	for enemy: Dictionary in enemies:
		if enemy["alive"]:
			alive += 1
	return alive

func _draw() -> void:
	draw_rect(ARENA_RECT, Color("10141f"), true)
	draw_rect(ARENA_RECT, Color("3a4a68"), false, 4.0)
	draw_rect(Rect2(ARENA_RECT.position + Vector2(140, 130), Vector2(180, 140)), Color(0.18, 0.21, 0.28, 0.35), true)
	draw_rect(Rect2(ARENA_RECT.position + Vector2(720, 320), Vector2(160, 150)), Color(0.18, 0.21, 0.28, 0.35), true)
	if prism_node:
		draw_circle(prism_node.position, 34.0, Color(0.2, 0.9, 1.0, 0.08))
	for enemy: Dictionary in enemies:
		if not is_instance_valid(enemy["node"]):
			continue
		var color: Color = Color("ffb86c") if enemy["type"] == "moth" else Color("bd93f9")
		if enemy["flash"] > 0.0:
			color = Color.WHITE
		draw_circle(enemy["node"].position, enemy["radius"], color)
	for segment in beam_segments:
		draw_line(segment[0], segment[1], Color(1.0, 0.96, 0.65, 0.9), 6.0)
		draw_circle(segment[1], 8.0, Color(0.9, 1.0, 1.0, 0.8))
	draw_circle(player_pos, PLAYER_RADIUS + beam_flash * 6.0, Color("f1fa8c"))
	draw_line(player_pos, player_pos + facing * 24.0, Color.BLACK, 3.0)
