# GameScene.gd
# Root node of the gameplay scene. Wires the AudioStreamPlayer into the
# AudioSync autoload so the authoritative audio clock drives note timing.
# Connects HUD elements to ScoreManager signals and GameController lifecycle.
#
# MVP-03 UI/UX refinement:
#   - Judgment feedback improved: rating color by judgment (PERFECT/GOOD/MISS).
#   - Combo feedback: combo counter highlighted on milestones.
#   - Pause/resume UI synced to GameController lifecycle signals.
#   - Visual timing feedback: judgment-line flash on hit.
extends Node2D

@onready var score_label: Label = $HUD/ScoreLabel
@onready var combo_label: Label = $HUD/ComboLabel
@onready var rating_label: Label = $HUD/RatingLabel
@onready var pause_button: Button = $HUD/PauseButton
@onready var lane_manager: Node2D = $LaneManager
@onready var note_spawner: Node2D = $NoteSpawner
@onready var judgment_line: ColorRect = $JudgmentLine

var _is_paused: bool = false

# Judgment colors (RGBA).
const COLOR_PERFECT: Color = Color(0.2, 0.8, 1.0, 1)   # Cyan
const COLOR_GOOD: Color = Color(0.9, 0.9, 0.2, 1)      # Yellow
const COLOR_MISS: Color = Color(1.0, 0.2, 0.2, 1)      # Red


func _ready() -> void:
	AudioSync.initialize_playback_channel($AudioPlayer)

	# Wire ScoreManager signals to HUD updates
	ScoreManager.alignment_processed.connect(_on_hit_evaluated)
	ScoreManager.sequence_tracking_concluded.connect(_on_song_completed)

	# Wire GameController lifecycle signals so pause/resume UI stays in sync
	GameController.song_paused.connect(_on_controller_paused)
	GameController.song_completed.connect(_on_controller_completed)

	# Wire Pause button
	pause_button.pressed.connect(_on_pause_pressed)

	# Wire LaneManager input gating to GameStateManager
	lane_manager.set_input_enabled(false)

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


func _on_hit_evaluated(rating: String, combo: int) -> void:
	score_label.text = str(ScoreManager.get_final_score())
	combo_label.text = "Combo: " + str(combo) if combo > 0 else ""
	_show_rating_feedback(rating)
	_show_combo_feedback(combo)
	_flash_judgment_line()


func _show_rating_feedback(rating: String) -> void:
	var color: Color
	match rating:
		"PERFECT":
			color = COLOR_PERFECT
		"GOOD":
			color = COLOR_GOOD
		"MISS":
			color = COLOR_MISS
		_:
			color = Color(1.0, 1.0, 1.0, 1)
	rating_label.text = rating
	rating_label.modulate = color
	rating_label.set("modulate:a", 1.0)
	var tween := create_tween()
	tween.tween_property(rating_label, "modulate:a", 0.0, 0.4)


func _show_combo_feedback(combo: int) -> void:
	if combo > 0 and combo % 10 == 0:
		# Highlight combo on every 10-hit milestone.
		var tween := create_tween()
		tween.tween_property(combo_label, "modulate:a", 0.0, 0.2)
		tween.tween_property(combo_label, "modulate:a", 1.0, 0.2)


func _flash_judgment_line() -> void:
	var original := judgment_line.modulate
	judgment_line.modulate = Color(1.0, 1.0, 1.0, 1)
	var tween := create_tween()
	tween.tween_property(judgment_line, "modulate:a", 0.4, 0.15)
	tween.tween_property(judgment_line, "modulate:a", 1.0, 0.15)


func _on_pause_pressed() -> void:
	if _is_paused:
		GameController.resume_song()
	else:
		GameController.pause_song()


func _on_controller_paused(song_id: String) -> void:
	_toggle_pause_ui(true)


func _on_controller_completed(song_id: String) -> void:
	# Handled by ScoreManager sequence_tracking_concluded; keep UI consistent.
	lane_manager.set_input_enabled(false)
	AudioSync.stop_audio_pipeline()
	GameStateManager.transition_to(GameStateManager.GameState.RESULTS)


func _toggle_pause_ui(paused: bool) -> void:
	_is_paused = paused
	lane_manager.set_input_enabled(not _is_paused)
	pause_button.text = "▶" if _is_paused else "II"

	if _is_paused:
		AudioSync.pause_audio_pipeline()
	else:
		AudioSync.start_audio_pipeline()


func _on_song_completed(final_score: int, max_combo: int, accuracy: float) -> void:
	lane_manager.set_input_enabled(false)
	AudioSync.stop_audio_pipeline()
	GameStateManager.transition_to(GameStateManager.GameState.RESULTS)
	rating_label.text = "Song Complete — Grade: " + ScoreManager.get_grade()
	rating_label.modulate = Color(1.0, 1.0, 1.0, 1)
	combo_label.text = "Final Score: " + str(final_score) + " | Max Combo: " + str(max_combo) + " | Accuracy: " + str(round(accuracy * 100, 1)) + "%"


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


func _on_return_to_menu_pressed() -> void:
	GameController.exit_to_menu()
