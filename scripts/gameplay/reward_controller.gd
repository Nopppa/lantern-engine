extends RefCounted
class_name RewardController

const UpgradeDefs = preload("res://scripts/data/upgrade_defs.gd")
const SfxController = preload("res://scripts/gameplay/sfx_controller.gd")

static func build_panel(run: RunScene) -> void:
	run.reward_panel = PanelContainer.new()
	run.reward_panel.visible = false
	run.reward_panel.position = Vector2(334, 148)
	run.reward_panel.size = Vector2(612, 364)
	run.reward_panel.add_theme_stylebox_override("panel", run._make_panel_style(Color(0.05, 0.07, 0.11, 0.97), Color(0.5, 0.78, 1.0, 1.0), 3, 12))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	run.reward_panel.add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	margin.add_child(vb)
	run.reward_title_label = Label.new()
	run.reward_title_label.text = "Choose one Prism upgrade"
	vb.add_child(run.reward_title_label)
	run.reward_buttons.clear()
	for i in 3:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 84)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		btn.pressed.connect(select_reward.bind(run, i))
		vb.add_child(btn)
		run.reward_buttons.append(btn)
	run.ui_layer.add_child(run.reward_panel)

static func show_rewards(run: RunScene) -> void:
	if run.reward_pending or run.reward_resolution_in_progress:
		return
	run.reward_pending = true
	run.reward_resolution_in_progress = false
	run.reward_panel.visible = true
	run.reward_selection_index = 0
	var options: Array = UpgradeDefs.POOL.duplicate(true)
	options.shuffle()
	for i in run.reward_buttons.size():
		var reward: Dictionary = options[i]
		run.reward_buttons[i].set_meta("reward", reward.duplicate(true))
		run.reward_buttons[i].set_meta("display_text", "[%d] %s\n%s" % [i + 1, reward["title"], reward["desc"]])
	update_button_states(run)
	SfxController.play(run, "reward_move")
	run.last_event = "Reward selection ready"

static func handle_input(run: RunScene) -> void:
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
		run.reward_selection_index = wrapi(run.reward_selection_index - 1, 0, run.reward_buttons.size())
		update_button_states(run)
		SfxController.play(run, "reward_move")
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
		run.reward_selection_index = wrapi(run.reward_selection_index + 1, 0, run.reward_buttons.size())
		update_button_states(run)
		SfxController.play(run, "reward_move")
	elif Input.is_action_just_pressed("spawn_moth"):
		select_reward(run, 0)
	elif Input.is_action_just_pressed("spawn_hollow"):
		select_reward(run, 1)
	elif Input.is_physical_key_pressed(KEY_3):
		select_reward(run, 2)
	elif Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		select_reward(run, run.reward_selection_index)

static func update_button_states(run: RunScene) -> void:
	for i in run.reward_buttons.size():
		var selected := i == run.reward_selection_index
		var reward: Dictionary = run.reward_buttons[i].get_meta("reward", {})
		var delta_text := String(reward.get("delta_text", ""))
		var prefix := "▶ " if selected else "  "
		run.reward_buttons[i].text = "%s%s\n%s" % [prefix, String(reward.get("title", "Upgrade")), delta_text]
		run.reward_buttons[i].tooltip_text = String(reward.get("desc", ""))
		var bg := Color(0.09, 0.13, 0.19, 0.98) if selected else Color(0.06, 0.08, 0.13, 0.94)
		var border := Color(0.98, 0.88, 0.48, 1.0) if selected else Color(0.34, 0.46, 0.66, 0.95)
		run.reward_buttons[i].add_theme_stylebox_override("normal", run._make_panel_style(bg, border, 2, 10))
		run.reward_buttons[i].add_theme_stylebox_override("hover", run._make_panel_style(bg.lightened(0.08), border.lightened(0.06), 2, 10))
		run.reward_buttons[i].add_theme_stylebox_override("focus", run._make_panel_style(bg.lightened(0.08), border.lightened(0.06), 3, 10))
		if selected:
			run.reward_buttons[i].grab_focus()
	run.reward_title_label.text = "Choose one Prism upgrade — [1/2/3] direct select, [W/S or ↑/↓] move, [E/Enter] confirm"

static func select_reward(run: RunScene, index: int) -> void:
	if not run.reward_pending or run.reward_resolution_in_progress:
		return
	if index < 0 or index >= run.reward_buttons.size():
		return
	run.reward_resolution_in_progress = true
	var reward: Dictionary = run.reward_buttons[index].get_meta("reward", {})
	if reward.is_empty():
		run.reward_resolution_in_progress = false
		return
	match reward.get("apply", ""):
		"bounce":
			run.beam_bounces += 1
		"range":
			run.beam_range = min(run.beam_range + 180.0, 960.0)
		"damage":
			run.beam_damage += 8.0
	run.reward_pending = false
	run.reward_panel.visible = false
	SfxController.play(run, "reward_pick")
	run.last_event = "Selected %s" % reward.get("title", "upgrade")
	if run.encounter_index + 1 < run.encounters.size():
		run._start_encounter(run.encounter_index + 1)
	else:
		run.run_over = true
		run.help_collapsed = false
		run.reward_resolution_in_progress = false
		run.last_event = "Prototype cleared — restart is ready"
