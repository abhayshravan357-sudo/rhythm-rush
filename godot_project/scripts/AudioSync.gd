# AudioSync.gd
# Autoload Singleton — authoritative playback-clock synchronization engine.
#
# The gameplay timing source of truth is the hardware audio clock
# (AudioStreamPlayer.get_playback_position() + AudioServer.get_time_since_last_mix()),
# NOT accumulated frame delta. This is decoupled from frame-rate jitter and
# mobile audio latency.
#
# All hit judgment, note spawning, and scoring read the playback position from
# this singleton via get_playback_position_seconds().
extends Node

signal song_completed
signal playback_paused
signal playback_resumed

# ── Timing judgment windows (single source of truth) ─────────────────────────
# One-sided delta from a note's hit timestamp. Deterministic note judgment:
#   PERFECT : |delta| <= JUDGMENT_WINDOW_PERFECT
#   GOOD    : |delta| <= JUDGMENT_WINDOW_GOOD
#   MISS    : otherwise
# ScoreManager.gd reads these at call time so both systems always agree.
const JUDGMENT_WINDOW_PERFECT: float = 0.050  # 50 ms  -> 300 pts, combo +1
const JUDGMENT_WINDOW_GOOD: float = 0.100     # 100 ms -> 100 pts, combo +1

const APPROACH_TIME: float = 1.5  # Visible note window ahead of the hit line (seconds)

# ── Hardware clock state ─────────────────────────────────────────────────────
var current_audio_time: float = 0.0      # Raw audio clock position, pre-offset
var adjusted_system_time: float = 0.0    # Authoritative playback position (post-offset)
var local_hardware_offset: float = 0.0   # User calibration offset (seconds)

var audio_player_node: AudioStreamPlayer = null
var active_playback_flag: bool = false
var is_paused: bool = false

# ── Timing drift analysis ────────────────────────────────────────────────────
# Compares the rate of the hardware audio clock against wall-clock (process
# delta) to detect playback drift on mobile hardware.
#   drift_sample = audio_clock_delta - wall_clock_delta  (seconds)
# Positive drift = audio clock runs ahead of wall clock; negative = slow.
var _last_process_tick: int = 0
var _last_audio_time: float = 0.0
var _drift_accumulator: float = 0.0
var _drift_sample_count: int = 0
const DRIFT_MAX_SAMPLES: int = 120


# ── Public API ───────────────────────────────────────────────────────────────

func get_playback_position_seconds() -> float:
	"""Authoritative adjusted playback position (seconds) used for hit judgment.

	Decoupled from frame-delta accumulation; derived from the hardware audio
	clock each process tick. Frozen while paused so pause/resume does not
	corrupt song position.
	"""
	return adjusted_system_time


func get_raw_audio_time() -> float:
	"""Raw hardware audio clock position (playback head + mix lag), pre-offset."""
	return current_audio_time


func is_playing() -> bool:
	return active_playback_flag and audio_player_node != null and audio_player_node.playing


func is_paused() -> bool:
	return is_paused


func get_offset() -> float:
	return local_hardware_offset


func set_offset(seconds: float) -> void:
	local_hardware_offset = float(seconds)
	_persist_offset(local_hardware_offset)


func get_approach_time() -> float:
	return APPROACH_TIME


func get_judgment_window_perfect() -> float:
	return JUDGMENT_WINDOW_PERFECT


func get_judgment_window_good() -> float:
	return JUDGMENT_WINDOW_GOOD


# ── Timing drift analysis ────────────────────────────────────────────────────

func get_timing_drift_ms() -> float:
	"""Average hardware-clock drift in milliseconds over the current sample window.

	Positive = audio clock runs ahead of wall clock; negative = slow.
	Returns 0.0 until at least one process tick has been observed while playing.
	"""
	if _drift_sample_count == 0:
		return 0.0
	return _drift_accumulator / float(_drift_sample_count) * 1000.0


func get_drift_sample_count() -> int:
	return _drift_sample_count


# ── Lifecycle ────────────────────────────────────────────────────────────────

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


func _persist_offset(seconds: float) -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		config.set_value("audio", "user_offset", seconds)
	else:
		config.set_value("audio", "user_offset", seconds)
	config.save("user://settings.cfg")


func initialize_playback_channel(target_player: AudioStreamPlayer) -> void:
	audio_player_node = target_player
	active_playback_flag = false
	is_paused = false
	current_audio_time = 0.0
	adjusted_system_time = 0.0
	_reset_drift()


func start_audio_pipeline() -> void:
	if audio_player_node == null:
		printerr("[AudioSync] No AudioStreamPlayer assigned.")
		return
	audio_player_node.play()
	active_playback_flag = true
	is_paused = false
	_reset_drift()


func pause_audio_pipeline() -> void:
	"""Pause playback without corrupting song position.

	The hardware clock freezes at the pause position; adjusted_system_time is
	not advanced while paused, so resume continues from the exact same point.
	"""
	if not is_playing() or is_paused or audio_player_node == null:
		return
	audio_player_node.pause()
	is_paused = true
	emit_signal("playback_paused")


func resume_audio_pipeline() -> void:
	"""Resume playback from the frozen pause position without position corruption.

	Godot resumes the AudioStreamPlayer from the paused playback head, so the
	clock picks up exactly where it left off.
	"""
	if not is_paused or audio_player_node == null:
		return
	audio_player_node.play()
	is_paused = false
	emit_signal("playback_resumed")
	_reset_drift()


func toggle_pause() -> void:
	if is_paused:
		resume_audio_pipeline()
	else:
		pause_audio_pipeline()


func stop_audio_pipeline() -> void:
	if audio_player_node != null:
		audio_player_node.stop()
	active_playback_flag = false
	is_paused = false
	_reset_drift()


func _reset_drift() -> void:
	_last_process_tick = Time.get_ticks_msec()
	_last_audio_time = current_audio_time
	_drift_accumulator = 0.0
	_drift_sample_count = 0


func _record_drift_sample() -> void:
	var now_ms: int = Time.get_ticks_msec()
	var wall_delta: float = float(now_ms - _last_process_tick) / 1000.0
	var audio_delta: float = current_audio_time - _last_audio_time
	var drift_sample: float = audio_delta - wall_delta

	_drift_accumulator += drift_sample
	_drift_sample_count += 1
	if _drift_sample_count >= DRIFT_MAX_SAMPLES:
		_drift_accumulator = 0.0
		_drift_sample_count = 0

	_last_process_tick = now_ms
	_last_audio_time = current_audio_time


func _process(_delta: float) -> void:
	if not active_playback_flag or audio_player_node == null:
		return

	if is_paused:
		# Frozen: hold position at the pause point; do not advance the clock,
		# do not accumulate drift, and do not report completion while paused.
		return

	if not audio_player_node.playing:
		# Song reached its natural end (not paused, not manually stopped).
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

	# ── Drift analysis ─────────────────────────────────────────────────
	_record_drift_sample()
