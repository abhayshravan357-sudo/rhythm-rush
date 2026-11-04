# GameScene.gd
# Root node of the gameplay scene. Wires the HUD (score, combo, rating, timing
# and pause UI) to ScoreManager judgments and the GameController /
# GameStateManager lifecycle.
#
# Judgment feedback provided here (UI layer):
#   - Color-coded hit ratings (PERFECT / GOOD / MISS) as timing-quality feedback
#   - Rating pop-and-fade animation on every hit
#   - Floating score text (+300 / +100) that rises and fades
#   - Combo counter pop animation plus milestone bursts ("COMBO x50!")
#   - Real-time score + accuracy in the score label
#   - Timing-window legend and per-hit qualitative timing text
#   - Pause/resume UI synchronized with GameStateManager (pause overlay,
#     button text, input gating, audio pipeline)
#
# ScoreManager (Agent 05 autoload) owns hit evaluation and emits
# alignment_processed(rating, combo, accuracy) — it does not carry the per-hit
# error delta, so per-hit timing feedback here is judgment-class based plus the
# timing-window legend rather than fabricated millisecond values.
extends Node2D

## ── Judgment colors (timing quality) ────────────────────────────────────────
const RATING_COLOR_PERFECT: Color = Color(0.0, 1.0, 1.0, 1.0)   # cyan
const RATING_COLOR_GOOD: Color = Color(1.0, 1.0, 0.0, 1.0)     # yellow
const RATING_COLOR_MISS: Color = Color(1.0, 0.35, 0.35, 1.0)   # red

const POINTS_PERFECT: int = 300
const POINTS_GOOD: int = 100

## Combo values that trigger a milestone burst
const COMBO_MILESTONES: Array[int] = [10, 25, 50, 75, 100]

@onready var score_label: Label = $HUD/ScoreLabel
@onready var combo_label: Label = $HUD/ComboLabel
@onready var rating_label: Label = $HUD/RatingLabel
@onready var timing_label: Label = $HUD/TimingLabel
@onready var pause_button: Button = $HUD/PauseButton
@onready var pause_overlay: CanvasLayer = $PauseOverlay
@onready var lane_manager: Node2D = $LaneManager
@onready var note_spawner: Node2D = $NoteSpawner

var _rating_tween: Tween = null
var _combo_tween: Tween = null


func _ready() -> void:
	AudioSync.initialize_playback_channel($AudioPlayer)

	# Wire ScoreManager signals to HUD updates
	ScoreManager.alignment_processed.connect(_on_hit_evaluated)
	ScoreManager.sequence_tracking_concluded.connect(_on_song_completed)

	# Wire Pause button
	pause_button.pressed.connect(_on_pause_pressed)

	# Keep pause UI synchronized with the authoritative gameplay state
	GameStateManager.state_changed.connect(_on_game_state_changed)

	# Wire LaneManager input gating to GameStateManager
	lane_manager.set_input_enabled(false)

	# Timing-window legend (static timing reference shown to the player)
	timing_label.text = "PERFECT ≤ 50 ms   ·   GOOD ≤ 100 ms   ·   MISS > 100 ms"
	timing_label.modulate = Color(1.0, 1.0, 1.0, 0.4)

	# Pause overlay starts hidden
	pause_overlay.visible = false

	# Wire pause overlay buttons
	$PauseOverlay/VBox/PauseResumeButton.pressed.connect(_on_pause_pressed)
	$PauseOverlay/VBox/PauseRetryButton.pressed.connect(_on_retry_pressed)
	$PauseOverlay/VBox/PauseMenuButton.pressed.connect(_on_return_to_menu_pressed)

	# Start gameplay once systems are ready
	_bootstrap_gameplay()


func _bootstrap_gameplay() -> void:
	"""Initialize gameplay systems via GameController."""
	if GameController.current_chart.is_empty():
		# No chart ready — this scene was opened without preparation.
		# Fall back to main menu safely.
		GameController.exit_to_menu()
		return

	# Enable input only after all systems are ready
	lane_manager.set_input_enabled(true)

	# Start spawning tiles from the chart
	var chart_data: Dictionary = GameController.current_chart
	note_spawner.start_spawning_sequence(chart_data)

	# Start the audio pipeline
	AudioSync.start_audio_pipeline()
	GameStateManager.transition_to(GameStateManager.GameState.PLAYING)


func _on_hit_evaluated(rating: String, combo: int, accuracy: float) -> void:
	score_label.text = str(ScoreManager.get_final_score()) + "  (" + str(round(accuracy, 1)) + "%)"
	combo_label.text = "Combo: " + str(combo) if combo > 0 else ""
	_show_rating_feedback(rating)
	_show_timing_feedback(rating)
	_show_combo_feedback(combo)
	_show_floating_score(rating)


func _rating_color(rating: String) -> Color:
	if rating == "PERFECT":
		return RATING_COLOR_PERFECT
	if rating == "GOOD":
		return RATING_COLOR_GOOD
	return RATING_COLOR_MISS


func _show_rating_feedback(rating: String) -> void:
	if is_instance_valid(_rating_tween):
		_rating_tween.kill()
	_rating_tween = null

	var color: Color = _rating_color(rating)
	rating_label.text = rating
	rating_label.modulate = Color(color.r, color.g, color.b, 1.0)
	rating_label.scale = Vector2.ONE

	var tween := create_tween()
	tween.tween_property(rating_label, "scale", Vector2(1.35, 1.35), 0.10).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.TRANS_EASE_OUT)
	tween.tween_property(rating_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.TRANS_EASE_IN_OUT)
	tween.tween_property(rating_label, "modulate:a", 0.0, 0.45).set_delay(0.05)
	_rating_tween = tween


func _show_timing_feedback(rating: String) -> void:
	var text: String
	if rating == "PERFECT":
		text = "Hit on time"
	elif rating == "GOOD":
		text = "Slightly off"
	else:
		text = "Missed window"

	var color: Color = _rating_color(rating)
	timing_label.text = text
	timing_label.modulate = Color(color.r, color.g, color.b, 1.0)

	var tween := create_tween()
	tween.tween_property(timing_label, "modulate:a", 0.0, 0.6)


func _show_combo_feedback(combo: int) -> void:
	if combo <= 0:
		return
	if is_instance_valid(_combo_tween):
		_combo_tween.kill()
	_combo_tween = null

	combo_label.scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(combo_label, "scale", Vector2(1.25, 1.25), 0.10)
	tween.tween_property(combo_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.TRANS_EASE_OUT)
	_combo_tween = tween

	if combo in COMBO_MILESTONES:
		_show_combo_burst(combo)


func _show_combo_burst(combo: int) -> void:
	var burst: Label = Label.new()
	burst.text = "COMBO x" + str(combo) + "!"
	burst.theme_override_font_sizes["font_size"] = 48
	burst.horizontal_alignment = 1
	burst.modulate = Color(1.0, 0.85, 0.0, 1.0)
	burst.scale = Vector2.ONE

	combo_label.add_child(burst)
	burst.position = Vector2(0.0, -40.0)

	var tween := create_tween()
	tween.tween_property(burst, "scale", Vector2(1.5, 1.5), 0.20)
	tween.tween_property(burst, "modulate:a", 0.0, 0.60).set_delay(0.10)
	tween.tween_callback(Callable(burst, "queue_free"))


func _show_floating_score(rating: String) -> void:
	var points: int
	if rating == "PERFECT":
		points = POINTS_PERFECT
	elif rating == "GOOD":
		points = POINTS_GOOD
	else:
		return  # no floating text for misses

	var float_label: Label = Label.new()
	float_label.text = "+" + str(points)
	float_label.theme_override_font_sizes["font_size"] = 32
	float_label.horizontal_alignment = 1
	float_label.modulate = _rating_color(rating)
	float_label.scale = Vector2.ONE

	rating_label.add_child(float_label)
	float_label.position = Vector2(0.0, -50.0)

	var start_position: Vector2 = float_label.position
	var tween := create_tween()
	tween.tween_property(float_label, "position", start_position + Vector2(0.0, -70.0), 0.70)
	tween.tween_property(float_label, "modulate:a", 0.0, 0.70)
	tween.tween_callback(Callable(float_label, "queue_free"))


func _apply_pause_ui(paused: bool) -> void:
	lane_manager.set_input_enabled(not paused)
	pause_overlay.visible = paused
	if paused:
		AudioSync.stop_audio_pipeline()
	else:
		AudioSync.start_audio_pipeline()


func _on_game_state_changed(from_state: String, to_state: String) -> void:
	var entering_paused: bool = to_state == GameStateManager.GameState.PAUSED
	var leaving_paused: bool = from_state == GameStateManager.GameState.PAUSED

	if entering_paused:
		_apply_pause_ui(true)
	elif leaving_paused:
		_apply_pause_ui(false)

	pause_button.text = "▶" if GameStateManager.is_paused() else "II"
	pause_button.disabled = not (
		GameStateManager.is_playing() or GameStateManager.is_paused()
	)


func _on_pause_pressed() -> void:
	if GameStateManager.is_paused():
		GameController.resume_song()
	else:
		GameController.pause_song()
	# Pause UI is driven reactively by GameStateManager.state_changed.


func _on_song_completed(final_score: int, max_combo: int, accuracy: float, grade: String) -> void:
	lane_manager.set_input_enabled(false)
	AudioSync.stop_audio_pipeline()
	GameStateManager.transition_to(GameStateManager.GameState.RESULTS)
	rating_label.text = "Song Complete — Grade: " + grade
	rating_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	rating_label.scale = Vector2.ONE
	combo_label.text = "Final Score: " + str(final_score) + " | Max Combo: " + str(max_combo) + " | Accuracy: " + str(round(accuracy * 100, 1)) + "%"
	score_label.text = str(final_score)
	timing_label.text = "PERFECT ≤ 50 ms   ·   GOOD ≤ 100 ms   ·   MISS > 100 ms"
	timing_label.modulate = Color(1.0, 1.0, 1.0, 0.4)


func _on_retry_pressed() -> void:
	# Restart the same song
	GameController.prepare_song(GameController.current_song_id, GameController.current_chart_path)
	note_spawner.start_spawning_sequence(GameController.current_chart)
	AudioSync.start_audio_pipeline()
	GameStateManager.transition_to(GameStateManager.GameState.PLAYING)
	lane_manager.set_input_enabled(true)
	score_label.text = "0"
	combo_label.text = ""
	rating_label.text = ""
	timing_label.text = "PERFECT ≤ 50 ms   ·   GOOD ≤ 100 ms   ·   MISS > 100 ms"
	timing_label.modulate = Color(1.0, 1.0, 1.0, 0.4)


func _on_return_to_menu_pressed() -> void:
	GameController.exit_to_menu()
	var scene: PackedScene = load("res://scenes/MainMenu.tscn")
	if scene != null:
		get_tree().change_scene_to_packed(scene)
