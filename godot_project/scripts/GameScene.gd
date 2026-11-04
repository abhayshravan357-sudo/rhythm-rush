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

const VisualTokens = preload("res://scripts/ui/VisualTokens.gd")

@onready var score_label: Label = $HUD/ScoreLabel
@onready var combo_label: Label = $HUD/ComboLabel
@onready var rating_label: Label = $HUD/RatingLabel
@onready var accuracy_label: Label = $HUD/AccuracyLabel
@onready var song_title_label: Label = $HUD/SongTitleLabel
@onready var progress_fill: ColorRect = $HUD/ProgressTrack/ProgressFill
@onready var pause_menu_box: VBoxContainer = $PauseOverlay/VBox
@onready var pause_button: Button = $HUD/PauseButton
@onready var lane_manager: Node2D = $LaneManager
@onready var note_spawner: Node2D = $NoteSpawner
@onready var judgment_line: ColorRect = $JudgmentLine
@onready var pause_overlay: CanvasLayer = $PauseOverlay

var _is_paused: bool = false

# Judgment colors (RGBA).
const COLOR_PERFECT: Color = VisualTokens.PERFECT
const COLOR_GOOD: Color = VisualTokens.GOOD
const COLOR_MISS: Color = VisualTokens.MISS


func _ready() -> void:
	AudioSync.initialize_playback_channel($AudioPlayer)
	get_viewport().size_changed.connect(_sync_responsive_layout)
	_sync_responsive_layout()
	accuracy_label.text = "ACCURACY  %.1f%%" % ScoreManager.get_accuracy()
	var metadata: Dictionary = GameController.current_chart.get("metaData", {})
	song_title_label.text = String(metadata.get("songName", GameController.current_song_id)).replace("_", " ").to_upper()

	# Wire ScoreManager signals to HUD updates
	ScoreManager.alignment_processed.connect(_on_hit_evaluated)
	ScoreManager.sequence_tracking_concluded.connect(_on_song_completed)

	# Wire GameController lifecycle signals so pause/resume UI stays in sync
	GameController.song_paused.connect(_on_controller_paused)
	GameController.song_resumed.connect(_on_controller_resumed)
	GameController.song_completed.connect(_on_controller_completed)

	# Wire Pause button
	pause_button.pressed.connect(_on_pause_pressed)
	$PauseOverlay/VBox/PauseResumeButton.pressed.connect(_on_pause_pressed)
	$PauseOverlay/VBox/PauseRetryButton.pressed.connect(_on_retry_pressed)
	$PauseOverlay/VBox/PauseMenuButton.pressed.connect(_on_return_to_menu_pressed)
	pause_overlay.visible = false

	# Wire LaneManager input gating to GameStateManager
	lane_manager.set_input_enabled(false)

	# Start gameplay once systems are ready
	_bootstrap_gameplay()


func _process(_delta: float) -> void:
	if AudioSync.song_duration > 0.0:
		progress_fill.anchor_right = clampf(AudioSync.adjusted_system_time / AudioSync.song_duration, 0.0, 1.0)


func _sync_responsive_layout() -> void:
	if not is_node_ready():
		return
	var field_left: float = lane_manager.get_playfield_left()
	var field_width: float = lane_manager.get_playfield_width()
	judgment_line.position = Vector2(field_left, lane_manager.get_judgment_line_y())
	judgment_line.size = Vector2(field_width, 5.0)
	var viewport_width := get_viewport_rect().size.x
	var pause_width := minf(380.0, viewport_width - 32.0)
	pause_menu_box.offset_left = -pause_width * 0.5
	pause_menu_box.offset_right = pause_width * 0.5
	for button_name in ["PauseResumeButton", "PauseRetryButton", "PauseMenuButton"]:
		var action_button: Button = pause_menu_box.get_node(button_name)
		action_button.custom_minimum_size.x = maxf(160.0, pause_width - 48.0)
	var score_font := int(clampf(viewport_width * 0.018, 16.0, 34.0))
	score_label.offset_right = minf(520.0, viewport_width * 0.34)
	combo_label.offset_right = minf(360.0, viewport_width * 0.34)
	score_label.add_theme_font_size_override("font_size", score_font)
	combo_label.add_theme_font_size_override("font_size", int(clampf(viewport_width * 0.014, 14.0, 24.0)))
	accuracy_label.add_theme_font_size_override("font_size", int(clampf(viewport_width * 0.012, 14.0, 20.0)))
	if viewport_width < 640.0:
		song_title_label.visible = false
		accuracy_label.anchor_left = 1.0
		accuracy_label.anchor_right = 1.0
		accuracy_label.offset_left = -minf(225.0, viewport_width * 0.36)
		accuracy_label.offset_right = -104.0
		accuracy_label.offset_top = 68.0
		accuracy_label.offset_bottom = 104.0
	else:
		song_title_label.visible = true
		accuracy_label.anchor_left = 1.0
		accuracy_label.anchor_right = 1.0
		accuracy_label.offset_left = -380.0
		accuracy_label.offset_right = -130.0
		accuracy_label.offset_top = 65.0
		accuracy_label.offset_bottom = 103.0


func _exit_tree() -> void:
	# AudioSync is an autoload and outlives this scene. Release its reference to
	# the scene-owned player before the player and its OGG playback are freed.
	AudioSync.stop_audio_pipeline()
	AudioSync.initialize_playback_channel(null)


func _bootstrap_gameplay() -> void:
	"""Initialize gameplay systems via GameController."""
	if GameController.current_chart.is_empty():
		# No chart ready — this scene was opened without preparation.
		# Fall back to main menu safely.
		GameController.exit_to_menu()
		return

	# Bind the local audio asset declared by the chart. Charts produced by the
	# pipeline store a filename, while packaged songs live under assets/audio.
	var metadata: Dictionary = GameController.current_chart.get("metaData", {})
	var audio_file: String = String(metadata.get("audioFile", ""))
	if audio_file.is_empty() or audio_file.get_file() != audio_file:
		_show_song_error("This chart does not name a valid local audio file.")
		return
	var audio_path := "res://assets/audio/" + audio_file
	if not ResourceLoader.exists(audio_path):
		_show_song_error("Audio file is missing: " + audio_file)
		return
	var audio_stream: AudioStream = load(audio_path)
	if audio_stream == null:
		_show_song_error("Audio file could not be loaded: " + audio_file)
		return
	$AudioPlayer.stream = audio_stream
	AudioSync.set_song_duration(audio_stream.get_length())

	# Enable input only after all systems are ready
	lane_manager.set_input_enabled(true)

	# Start spawning tiles from the chart
	var chart_data: Dictionary = GameController.current_chart
	note_spawner.start_spawning_sequence(chart_data)

	# Start the audio pipeline via GameController
	GameController.start_song()


func _show_song_error(message: String) -> void:
	push_error("[GameScene] " + message)
	GameController.exit_to_menu()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_hit_evaluated(rating: String, combo: int, accuracy: float = 0.0) -> void:
	score_label.text = "SCORE  %07d" % ScoreManager.get_final_score()
	combo_label.text = "COMBO  %03d" % combo if combo > 0 else ""
	accuracy_label.text = "ACCURACY  %.1f%%" % accuracy
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


func _on_controller_resumed(song_id: String) -> void:
	_toggle_pause_ui(false)


func _on_controller_completed(song_id: String) -> void:
	lane_manager.set_input_enabled(false)
	AudioSync.stop_audio_pipeline()
	GameStateManager.transition_to(GameStateManager.GameState.RESULTS)
	if not bool(get_meta("suppress_scene_transitions", false)):
		get_tree().change_scene_to_file("res://scenes/Results.tscn")


func _toggle_pause_ui(paused: bool) -> void:
	_is_paused = paused
	lane_manager.set_input_enabled(not _is_paused)
	pause_overlay.visible = _is_paused
	pause_button.text = "▶" if _is_paused else "II"

	if _is_paused:
		AudioSync.pause_audio_pipeline()
	else:
		AudioSync.start_audio_pipeline()


func _on_song_completed(final_score: int, max_combo: int, accuracy: float, _grade: String) -> void:
	lane_manager.set_input_enabled(false)
	GameController.complete_song()


func _on_retry_pressed() -> void:
	# Restart the same song
	var song_id: String = GameController.current_song_id
	var chart_path: String = GameController.current_chart_path
	GameController.prepare_song(song_id, chart_path)
	note_spawner.start_spawning_sequence(GameController.current_chart)
	GameController.start_song()
	lane_manager.set_input_enabled(true)
	score_label.text = "SCORE  000000"
	combo_label.text = ""
	rating_label.text = ""
	accuracy_label.text = "ACCURACY  %.1f%%" % ScoreManager.get_accuracy()
	progress_fill.anchor_right = 0.0


func _on_return_to_menu_pressed() -> void:
	GameController.exit_to_menu()
