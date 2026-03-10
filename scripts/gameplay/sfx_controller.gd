extends RefCounted
class_name SfxController

static func setup(run: RunScene) -> void:
	run.sfx_players = {}
	run.sfx_cache = {
		"beam": _make_tone(620.0, 0.07, 0.18, 0.05),
		"hit": _make_tone(920.0, 0.05, 0.16, 0.22),
		"kill": _make_descend(880.0, 540.0, 0.11, 0.20),
		"reward_move": _make_tone(760.0, 0.03, 0.10, 0.02),
		"reward_pick": _make_descend(980.0, 720.0, 0.08, 0.16)
	}
	for key in run.sfx_cache.keys():
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -10.0
		player.stream = run.sfx_cache[key]
		run.ui_layer.add_child(player)
		run.sfx_players[key] = player

static func play(run: RunScene, name: String) -> void:
	var player: AudioStreamPlayer = run.sfx_players.get(name)
	if player == null:
		return
	if player.playing:
		player.stop()
	player.play()

static func _make_tone(freq: float, duration: float, volume: float, decay: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_frames := int(max(1.0, duration * sample_rate))
	var bytes := PackedByteArray()
	bytes.resize(total_frames * 2)
	for i in range(total_frames):
		var t := float(i) / float(sample_rate)
		var env := exp(-t / max(decay, 0.001))
		var sample := sin(TAU * freq * t) * volume * env
		bytes.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = bytes
	return wav

static func _make_descend(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_frames := int(max(1.0, duration * sample_rate))
	var bytes := PackedByteArray()
	bytes.resize(total_frames * 2)
	var phase := 0.0
	for i in range(total_frames):
		var t := float(i) / float(sample_rate)
		var progress := clampf(t / max(duration, 0.001), 0.0, 1.0)
		var freq := lerpf(start_freq, end_freq, progress)
		phase += TAU * freq / sample_rate
		var env := exp(-t / max(duration * 0.65, 0.001))
		var sample := sin(phase) * volume * env
		bytes.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = bytes
	return wav
