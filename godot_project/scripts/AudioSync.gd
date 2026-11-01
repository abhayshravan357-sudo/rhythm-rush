# AudioSync.gd
# Autoload Singleton — hardware clock synchronisation engine.
#
# Reading get_playback_position() + AudioServer.get_time_since_last_mix() gives
# the most accurate available audio timestamp on mobile hardware, decoupled from
# frame delta accumulation drift.
extends Node

signal song_completed

const APPROACH_TIME: float = 1.5  ## Visible note window ahead of the hit line (seconds)

var current_audio_time: float = 0.0
var adjusted_system_time: float = 0.0
var local_hardware_offset: float = 0.0

var audio_player_node: AudioStreamPlayer = null
var active_playback_flag: bool = false


func get_playback_position_seconds() -> float:
	"""Authoritative adjusted playback position (seconds) used for hit judgment.

	Decoupled from frame-delta accumulation; derived from the hardware audio
	clock each process tick.
	"""
	return adjusted_system_time


func get_raw_audio_time() -> float:
	"""Raw hardware audio clock position (playback head + mix lag), pre-offset."""
	return current_audio_time


func is_playing() -> bool:
	return active_playback_flag and audio_player_node != null and audio_player_node.playing


func get_offset() -> float:
	return local_hardware_offset


func set_offset(seconds: float) -> void:
	local_hardware_offset = float(seconds)
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		config.set_value("audio", "user_offset", local_hardware_offset)
		config.save("user://settings.cfg")
	else:
		config.set_value("audio", "user_offset", local_hardware_offset)
		config.save("user://settings.cfg")


func get_approach_time() -> float:
	return APPROACH_TIME


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	load_calibration_data()


func load_calibration_data() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		local_hardware_offset = config.get_value("audio", "user_offset", 0.0)
		print("[AudioSync] Loaded offset calibration: ", local_hardware_offset, "s")
	else:
		local_hardware_offset = 0.0


func initialize_playback_channel(target_player: AudioStreamPlayer) -> void:
	audio_player_node = target_player
	active_playback_flag = false
	current_audio_time = 0.0
	adjusted_system_time = 0.0


func start_audio_pipeline() -> void:
	if audio_player_node == null:
		printerr("[AudioSync] No AudioStreamPlayer assigned.")
		return
	audio_player_node.play()
	active_playback_flag = true


func stop_audio_pipeline() -> void:
	if audio_player_node != null:
		audio_player_node.stop()
	active_playback_flag = false


func _process(_delta: float) -> void:
	if not active_playback_flag or audio_player_node == null:
		return

	if not audio_player_node.playing:
		active_playback_flag = false
		emit_signal("song_completed")
		return

	# Authoritative hardware clock: playback head + time since last mix.
	# No frame-delta accumulation is used for note timing.
	current_audio_time = (
		audio_player_node.get_playback_position()
		+ AudioServer.get_time_since_last_mix()
	)

	adjusted_system_time = current_audio_time - local_hardware_offset
