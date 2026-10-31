# OffsetCalibration.gd
# Autoload Singleton — metronome-based latency measurement and persistence.
#
# How it works:
#   1. A 0.5 s metronome pulse fires repeatedly.
#   2. The user taps a button in sync with each pulse.
#   3. The signed delta between their tap and the beat is recorded.
#   4. After 12 taps the mean delta is written to user://settings.cfg
#      under [audio] user_offset.
#   5. AudioSync reads that value on startup and subtracts it from
#      every adjusted_system_time calculation.
extends Node

signal calibration_tick                          ## Fired on each metronome beat (visual feedback)
signal calibration_complete(mean_offset: float)  ## Fired when result is saved

const INTERVAL_SECONDS: float = 0.5   ## Metronome pulse period
const REQUIRED_TAPS: int = 12          ## Number of taps before computing result
const OUTLIER_THRESHOLD: float = 0.250 ## Taps more than 250 ms off are discarded

var _accumulator: float = 0.0
var _beat_number: int = 0
var _taps: Array[float] = []
var _running: bool = false


func start_calibration() -> void:
	_accumulator = 0.0
	_beat_number = 0
	_taps.clear()
	_running = true
	print("[OffsetCalibration] Calibration started — tap in time with each beat.")


func stop_calibration() -> void:
	_running = false


func _process(delta: float) -> void:
	if not _running:
		return

	_accumulator += delta
	if _accumulator >= INTERVAL_SECONDS:
		_accumulator -= INTERVAL_SECONDS
		_beat_number += 1
		emit_signal("calibration_tick")


func register_tap() -> void:
	## Call this from a UI button's pressed signal while calibration is running.
	if not _running:
		return

	# How far is the tap from the most recent beat boundary?
	# _accumulator holds the fractional time since the last beat.
	# A perfectly on-time tap has _accumulator ≈ 0; late taps are positive.
	var signed_delta: float = _accumulator
	# Wrap to [-0.25, +0.25] window
	if signed_delta > INTERVAL_SECONDS / 2.0:
		signed_delta -= INTERVAL_SECONDS

	if absf(signed_delta) < OUTLIER_THRESHOLD:
		_taps.append(signed_delta)
		print("[OffsetCalibration] Tap recorded: ", snappedf(signed_delta * 1000.0, 0.1), " ms")

	if _taps.size() >= REQUIRED_TAPS:
		_finalise()


func _finalise() -> void:
	_running = false
	var sum: float = 0.0
	for v: float in _taps:
		sum += v
	var mean: float = sum / float(_taps.size())

	# Persist to settings file — AudioSync reads this on next startup
	var config := ConfigFile.new()
	config.load("user://settings.cfg")  # Load existing keys so we don't wipe them
	config.set_value("audio", "user_offset", mean)
	config.save("user://settings.cfg")

	print("[OffsetCalibration] Saved offset: ", snappedf(mean * 1000.0, 0.1), " ms")
	emit_signal("calibration_complete", mean)

	# Reload AudioSync offset immediately without requiring a restart
	AudioSync.local_hardware_offset = mean
