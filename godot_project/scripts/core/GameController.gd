extends Node

signal song_loaded(song_id: String)
signal song_started(song_id: String)
signal song_paused(song_id: String)
signal song_resumed(song_id: String)
signal song_completed(song_id: String)
signal game_over_triggered(song_id: String, final_score: int, max_combo: int, accuracy: float)

var current_song_id: String = ""
var current_chart_path: String = ""
var current_chart: Dictionary = {}
var is_game_active: bool = false
var last_result: Dictionary = {}
var _run_recorded: bool = false


func prepare_song(song_id: String, chart_path: String) -> bool:
	current_song_id = song_id
	current_chart_path = chart_path
	GameStateManager.transition_to(GameStateManager.GameState.LOADING)
	current_chart = ChartLoader.load_chart(chart_path)
	if current_chart.is_empty():
		printerr("[GameController] Failed to load chart for: ", song_id)
		GameStateManager.reset_to_main_menu()
		return false
	ScoreManager.reset_scoring_matrix(current_chart)
	last_result.clear()
	_run_recorded = false
	emit_signal("song_loaded", song_id)
	return true


func start_song() -> void:
	if current_chart.is_empty():
		printerr("[GameController] No chart ready to start.")
		return
	is_game_active = true
	GameStateManager.transition_to(GameStateManager.GameState.PLAYING)
	emit_signal("song_resumed", current_song_id)
	AudioSync.start_audio_pipeline()
	emit_signal("song_started", current_song_id)


func pause_song() -> void:
	GameStateManager.transition_to(GameStateManager.GameState.PAUSED)
	AudioSync.pause_audio_pipeline()
	emit_signal("song_paused", current_song_id)


func resume_song() -> void:
	if GameStateManager.current_state != GameStateManager.GameState.PAUSED:
		return
	is_game_active = true
	GameStateManager.transition_to(GameStateManager.GameState.PLAYING)
	AudioSync.start_audio_pipeline()
	emit_signal("song_resumed", current_song_id)


func complete_song() -> void:
	if _run_recorded:
		return
	is_game_active = false
	AudioSync.stop_audio_pipeline()
	last_result = {
		"song_id": current_song_id,
		"mode": "classic",
		"score": ScoreManager.get_score(),
		"accuracy": ScoreManager.get_accuracy(),
		"grade": ScoreManager.get_grade(),
		"perfects": ScoreManager.get_perfect_count(),
		"goods": ScoreManager.get_good_count(),
		"misses": ScoreManager.get_miss_count(),
		"max_combo": ScoreManager.get_max_combo(),
		"total_notes": ScoreManager.total_note_count,
		"played_at": int(Time.get_unix_time_from_system()),
	}
	last_result["personal_best"] = ScoreManager.get_score() > PlayerProfile.get_high_score(current_song_id)
	PlayerProfile.record_play(last_result)
	PlayerProfile.add_xp(maxi(1, int(ScoreManager.get_score() / 1000)))
	PlayerProfile.save_profile()
	_run_recorded = true
	GameStateManager.transition_to(GameStateManager.GameState.RESULTS)
	emit_signal("song_completed", current_song_id)


func game_over(final_score: int = 0, max_combo: int = 0, accuracy: float = 0.0) -> void:
	is_game_active = false
	AudioSync.stop_audio_pipeline()
	GameStateManager.transition_to(GameStateManager.GameState.GAME_OVER)
	emit_signal("game_over_triggered", current_song_id, final_score, max_combo, accuracy)


func exit_to_menu() -> void:
	is_game_active = false
	AudioSync.stop_audio_pipeline()
	GameStateManager.reset_to_main_menu()
	current_chart.clear()
	current_song_id = ""
	current_chart_path = ""
