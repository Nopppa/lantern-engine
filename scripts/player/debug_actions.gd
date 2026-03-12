extends RefCounted
class_name DebugActions

static func handle_key_input(run: RunScene, event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F1:
				toggle_help(run)
				run.get_viewport().set_input_as_handled()
			KEY_F2:
				quick_refill(run)
				run.get_viewport().set_input_as_handled()
			KEY_F3:
				force_reward(run)
				run.get_viewport().set_input_as_handled()
			KEY_F4:
				toggle_immortal(run)
				run.get_viewport().set_input_as_handled()
			KEY_F5:
				if "legends_hidden" in run:
					run.legends_hidden = !run.legends_hidden
					run.last_event = "HUD Legends %s" % ("hidden" if run.legends_hidden else "shown")
				run.get_viewport().set_input_as_handled()

static func handle_process_actions(run: RunScene) -> bool:
	if Input.is_action_just_pressed("quick_refill"):
		quick_refill(run)
	if Input.is_action_just_pressed("restart_run"):
		run._restart_run()
		return true
	if Input.is_action_just_pressed("spawn_moth") and not run.reward_pending:
		run._spawn_enemy("moth", run._random_spawn())
	if Input.is_action_just_pressed("spawn_hollow") and not run.reward_pending:
		run._spawn_enemy("hollow", run._random_spawn())
	if Input.is_action_just_pressed("grant_upgrade"):
		force_reward(run)
	return false

static func quick_refill(run: RunScene) -> void:
	run.player_hp = run.player_max_hp
	run.energy = run.max_energy
	if run.run_over and run.player_hp > 0.0:
		run.run_over = false
		run.end_panel.visible = false
		run.last_event = "Dev refill + revive"
	else:
		run.last_event = "Dev refill"

static func force_reward(run: RunScene) -> void:
	if run.reward_pending or run.reward_resolution_in_progress:
		return
	if run.run_over:
		run.run_over = false
		run.end_panel.visible = false
	run._show_rewards()

static func toggle_help(run: RunScene) -> void:
	if "ui_overlays_hidden" in run:
		run.ui_overlays_hidden = !run.ui_overlays_hidden
		run.last_event = "UI overlays %s" % ("shown" if not run.ui_overlays_hidden else "hidden")
	else:
		run.help_collapsed = !run.help_collapsed
		run.last_event = "Overlay %s" % ("shown" if not run.help_collapsed else "hidden")

static func toggle_immortal(run: RunScene) -> void:
	run.debug_immortal = !run.debug_immortal
	run.last_event = "Dev immortality %s" % ("ON" if run.debug_immortal else "OFF")
