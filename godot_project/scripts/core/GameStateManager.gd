extends Node

signal state_changed(from_state: String, to_state: String)

enum GameState {
	MAIN_MENU,
	SONG_SELECTION,
	LOADING,
	PLAYING,
	PAUSED,
	RESULTS,
	GAME_OVER,
	CALIBRATION
}

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU


func transition_to(next_state: GameState) -> void:
	if next_state == current_state:
		return
	previous_state = current_state
	current_state = next_state
	emit_signal("state_changed", GameState.keys()[previous_state], GameState.keys()[current_state])


func is_playing() -> bool:
	return current_state == GameState.PLAYING


func is_paused() -> bool:
	return current_state == GameState.PAUSED


func is_game_over() -> bool:
	return current_state == GameState.GAME_OVER


func reset_to_main_menu() -> void:
	transition_to(GameState.MAIN_MENU)
