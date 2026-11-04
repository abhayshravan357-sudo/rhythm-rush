# AudioSync.gd
# Autoload Singleton — hardware clock synchronisation engine.
#
# Reading get_playback_position() + AudioServer.get_time_since_last_mix() gives
# the most accurate available audio timestamp on mobile hardware, decoupled from
# frame delta accumulation drift.
#
# MVP-03 additions:
#   - pause_audio_pipeline() / resume_audio_pipeline() preserve timing across
#     pauses by seeking the AudioStreamPlayer to the paused position, so
#     adjusted_system_time never jumps backward on resume (no timing corruption).
#   - Song completion detection via playback-position-vs-duration comparison.
#   - Timing drift analysis: drift_ms() reports the delta between the audio
#     clock and the adjusted system clock over the session.
extends Node

signal song_completed
signal playback_paused
signal playback_resumed

const APPROACH_TIME: float = 1.5  ## Visible note window ahead of the hit line (seconds)
const JUDGMENT_WINDOW_PERFECT: float = 0.050  ## 50 ms PERFECT window
const JUDGMENT_WINDOW_GOOD: float = 0.100     ## 100 ms GOOD window

func get_judgment_window_perfect() -> float:
	return JUDGMENT_WINDOW_PERFECT

func get_judgment_window_good() -> float:
	return JUDGMENT_WINDOW_GOOD

var current_audio_time: float = 0.0
var adjusted_system_time: float = 0.0
var local_hardware_offset: float = 0.0

var audio_player_node: AudioStreamPlayer = null
var active_playback_flag: bool = false
var is_paused: bool = false

# Pause compensation: adjusted_system_time frozen at pause moment.
var _paused_adjusted_time: float = 0.0
# Song duration (seconds) for completion detection; 0.0 = unknown.
var song_duration: float = 0.0
# Drift samples: each entry is (audio_clock - adjusted_system_time) at a tick.
var _drift_samples: Array[float] = []


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


func is_paused_state() -> bool:
	return is_paused


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


# ── Drift analysis ────────────────────────────────────────────────────────────

func drift_ms() -> float:
	"""Mean timing drift (ms) between raw audio clock and adjusted clock.

	Positive means the audio clock runs ahead of adjusted time. Returns 0.0
	when no samples have been collected.
	"""
	if _drift_samples.is_empty():
		return 0.0
	var sum: float = 0.0
	for s in _drift_samples:
		sum += s
	return (sum / float(_drift_samples.size())) * 1000.0


func drift_sample_count() -> int:
	return _drift_samples.size()


func _record_drift_sample() -> void:
	var drift: float = current_audio_time - adjusted_system_time
	_drift_samples.append(drift)
	# Cap sample history to keep memory bounded.
	if _drift_samples.size() > 600:
		_drift_samples.pop_front()
	_auto_calibrate_offset()


# ── Auto-calibration ──────────────────────────────────────────────────────────

# Threshold (seconds) beyond which the offset is auto-corrected.
const DRIFT_CALIBRATE_THRESHOLD: float = 0.010  # 10 ms
# How often (in samples) to attempt auto-calibration.
const DRIFT_CALIBRATE_INTERVAL: int = 60


func _auto_calibrate_offset() -> void:
	"""Adjust local_hardware_offset when measured drift exceeds threshold.

	Prevents cumulative timing error between the audio hardware clock and
	adjusted_system_time from growing unbounded across a long song.
	Only applied when enough samples exist and drift is consistent in one
	direction.
	"""
	if _drift_samples.size() < DRIFT_CALIBRATE_INTERVAL:
		return
	if _drift_samples.size() % DRIFT_CALIBRATE_INTERVAL != 0:
		return

	# Use the median of the most recent samples to avoid outliers.
	var recent: Array[float] = _drift_samples.slice(-DRIFT_CALIBRATE_INTERVAL)
	recent.sort()
	var median_idx: int = DRIFT_CALIBRATE_INTERVAL / 2
	var median_drift: float = recent[median_idx]

	if absf(median_drift) > DRIFT_CALIBRATE_THRESHOLD:
		# Shift the offset by the median drift so adjusted_system_time tracks
		# the audio clock more closely.
		local_hardware_offset += median_drift

		# Persist the new offset so it survives restarts.
		var config := ConfigFile.new()
		if config.load("user://settings.cfg") != OK:
			config.set_value("audio", "user_offset", local_hardware_offset)
			config.save("user://settings.cfg")
		else:
			config.set_value("audio", "user_offset", local_hardware_offset)
			config.save("user://settings.cfg")


# ── Lifecycle ─────────────────────────────────────────────────────────────────

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
	is_paused = false
	current_audio_time = 0.0
	adjusted_system_time = 0.0
	_paused_adjusted_time = 0.0
	song_duration = 0.0
	_drift_samples.clear()


func set_song_duration(seconds: float) -> void:
	song_duration = max(0.0, float(seconds))


func start_audio_pipeline() -> void:
	if audio_player_node == null:
		printerr("[AudioSync] No AudioStreamPlayer assigned.")
		return
	if is_paused:
		_resume_from_pause()
		return
	audio_player_node.play()
	active_playback_flag = true
	is_paused = false
	current_audio_time = 0.0
	adjusted_system_time = 0.0


func pause_audio_pipeline() -> void:
	if not active_playback_flag or is_paused:
		return
	is_paused = true
	active_playback_flag = false
	_paused_adjusted_time = adjusted_system_time
	if audio_player_node != null:
		audio_player_node.stop()
	emit_signal("playback_paused")


func _resume_from_pause() -> void:
	if audio_player_node == null:
		return
	# Seek to the paused adjusted position (translated back to raw audio clock)
	# so playback resumes without a backward jump in adjusted_system_time.
	var seek_position: float = _paused_adjusted_time + local_hardware_offset
	seek_position = max(0.0, seek_position)
	audio_player_node.seek(seek_position)
	audio_player_node.play()
	active_playback_flag = true
	is_paused = false
	emit_signal("playback_resumed")


func stop_audio_pipeline() -> void:
	if audio_player_node != null:
		audio_player_node.stop()
	active_playback_flag = false
	is_paused = false
	current_audio_time = 0.0
	adjusted_system_time = 0.0
	_paused_adjusted_time = 0.0


func _process(_delta: float) -> void:
	if not active_playback_flag or audio_player_node == null:
		return

	if not audio_player_node.playing:
		active_playback_flag = false
		is_paused = false
		emit_signal("song_completed")
		return

	# Authoritative hardware clock: playback head + time since last mix.
	# No frame-delta accumulation is used for note timing.
	current_audio_time = (
		audio_player_node.get_playback_position()
		+ AudioServer.get_time_since_last_mix()
	)

	adjusted_system_time = current_audio_time - local_hardware_offset

	# Song completion detection: playback reached (or passed) the song duration.
	if song_duration > 0.0 and current_audio_time >= song_duration:
		active_playback_flag = false
		is_paused = false
		emit_signal("song_completed")
		return

	_record_drift_sample()
