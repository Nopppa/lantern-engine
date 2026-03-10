extends RefCounted
class_name DebugActions

static func handle_key_input(run: RunScene, event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F1:
				toggle_help(run)
				run.get_viewport().set_input_as_handled()
			KEY_F4:
				toggle_immortal(run)
				run.get_viewport().set_input_as_handled()

static func handle_process_actions(run: RunScene) -> bool:
	if Input.is_action_just_pressed("quick_refill"):
		run.player_hp = run.player_max_hp
		run.energy = run.max_energy
		run.last_event = "Dev refill"
	if Input.is_action_just_pressed("restart_run"):
		run._restart_run()
		return true
	if Input.is_action_just_pressed("spawn_moth") and not run.reward_pending:
		run._spawn_enemy("moth", run._random_spawn())
	if Input.is_action_just_pressed("spawn_hollow") and not run.reward_pending:
		run._spawn_enemy("hollow", run._random_spawn())
	if Input.is_action_just_pressed("grant_upgrade") and not run.reward_pending:
		run._show_rewards()
	return false

static func toggle_help(run: RunScene) -> void:
	run.help_collapsed = !run.help_collapsed
	run.last_event = "Help %s" % ("shown" if not run.help_collapsed else "collapsed")

static func toggle_immortal(run: RunScene) -> void:
	run.debug_immortal = !run.debug_immortal
	run.last_event = "Dev immortality %s" % ("ON" if run.debug_immortal else "OFF")
