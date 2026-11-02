extends Node

signal song_loaded(song_id: String)
signal song_started(song_id: String)
signal song_paused(song_id: String)
signal song_completed(song_id: String)
signal game_over(song_id: String, final_score: int, max_combo: int, accuracy: float)

var current_song_id: String = ""
var current_chart_path: String = ""
var current_chart: Dictionary = {}
var is_game_active: bool = false


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
	emit_signal("song_loaded", song_id)
	return true


func start_song() -> void:
	if current_chart.is_empty():
		printerr("[GameController] No chart ready to start.")
		return
	is_game_active = true
	GameStateManager.transition_to(GameStateManager.GameState.PLAYING)
	AudioSync.start_audio_pipeline()
	emit_signal("song_started", current_song_id)


func pause_song() -> void:
	if not is_game_active:
		return
	AudioSync.pause_audio_pipeline()
	GameStateManager.transition_to(GameStateManager.GameState.PAUSED)
	emit_signal("song_paused", current_song_id)


func resume_song() -> void:
	if GameStateManager.current_state != GameStateManager.GameState.PAUSED:
		return
	AudioSync.resume_audio_pipeline()
	GameStateManager.transition_to(GameStateManager.GameState.PLAYING)


func complete_song() -> void:
	is_game_active = false
	AudioSync.stop_audio_pipeline()
	GameStateManager.transition_to(GameStateManager.GameState.RESULTS)
	emit_signal("song_completed", current_song_id)


func game_over(final_score: int = 0, max_combo: int = 0, accuracy: float = 0.0) -> void:
	is_game_active = false
	AudioSync.stop_audio_pipeline()
	GameStateManager.transition_to(GameStateManager.GameState.GAME_OVER)
	emit_signal("game_over", current_song_id, final_score, max_combo, accuracy)


func exit_to_menu() -> void:
	is_game_active = false
	AudioSync.stop_audio_pipeline()
	GameStateManager.reset_to_main_menu()
	current_chart.clear()
	current_song_id = ""
	current_chart_path = ""
