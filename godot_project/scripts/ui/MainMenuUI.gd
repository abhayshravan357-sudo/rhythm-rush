# MainMenuUI.gd
# UI controller for the Main Menu scene.
#
# Wires menu buttons to the game state machine (GameStateManager / GameController
# autoloads) and drives scene transitions. Kept as a child node of MainMenu so the
# existing MenuNetworkSyncReceiver script on the root is preserved.
extends Node

## Scene paths
const SCENE_SONG_SELECTION: String = "res://scenes/SongSelection.tscn"
const SCENE_GAMEPLAY: String = "res://scenes/GameScene.tscn"
const SCENE_CALIBRATION: String = "res://scenes/CalibrationScene.tscn"

@onready var _play_button: Button = get_parent().get_node("VBox/PlayButton")
@onready var _song_library_button: Button = get_parent().get_node("VBox/SongLibraryButton")
@onready var _settings_button: Button = get_parent().get_node("VBox/SettingsButton")
@onready var _calibrate_button: Button = get_parent().get_node("VBox/CalibrateButton")
@onready var _status_label: Label = get_parent().get_node("VBox/StatusLabel")


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_song_library_button.pressed.connect(_on_song_library_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_calibrate_button.pressed.connect(_on_calibrate_pressed)
	_status_label.text = ""


func _on_play_pressed() -> void:
	_status_label.text = "Starting game..."
	go_to_gameplay("example_track", "res://charts/example_chart.json")


func _on_song_library_pressed() -> void:
	_status_label.text = "Loading song library..."
	go_to_song_selection()


func _on_settings_pressed() -> void:
	_status_label.text = "Settings — coming soon."
	GameStateManager.transition_to(GameStateManager.GameState.MAIN_MENU)


func _on_calibrate_pressed() -> void:
	_status_label.text = "Opening calibration..."
	go_to_calibration()


## ── Scene transitions ────────────────────────────────────────────────────────

func go_to_song_selection() -> void:
	var scene: PackedScene = load(SCENE_SONG_SELECTION)
	if scene == null:
		_status_label.text = "Error: song selection scene missing."
		printerr("[MainMenuUI] Failed to load: ", SCENE_SONG_SELECTION)
		return
	GameStateManager.transition_to(GameStateManager.GameState.SONG_SELECTION)
	get_tree().change_scene_to_packed(scene)


func go_to_calibration() -> void:
	var scene: PackedScene = load(SCENE_CALIBRATION)
	if scene == null:
		_status_label.text = "Error: calibration scene missing."
		printerr("[MainMenuUI] Failed to load: ", SCENE_CALIBRATION)
		return
	GameStateManager.transition_to(GameStateManager.GameState.CALIBRATION)
	get_tree().change_scene_to_packed(scene)


func go_to_gameplay(song_id: String, chart_path: String) -> void:
	if GameController.prepare_song(song_id, chart_path):
		get_tree().change_scene_to_packed(load(SCENE_GAMEPLAY))
		GameController.start_song()
	else:
		_status_label.text = "Failed to load chart: " + song_id
		GameStateManager.reset_to_main_menu()
