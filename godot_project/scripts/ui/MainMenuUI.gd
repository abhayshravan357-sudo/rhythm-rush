# MainMenuUI.gd
# UI controller for the Main Menu scene.
#
# Wires menu buttons to the game state machine (GameStateManager / GameController
# autoloads) and drives scene transitions. Kept as a child node of MainMenu so the
# existing MenuNetworkSyncReceiver script on the root is preserved.
extends Node

const ResponsiveLayout = preload("res://scripts/ui/ResponsiveLayout.gd")

## Scene paths
const SCENE_SONG_SELECTION: String = "res://scenes/SongSelection.tscn"
const SCENE_GAMEPLAY: String = "res://scenes/GameScene.tscn"
const SCENE_CALIBRATION: String = "res://scenes/CalibrationScene.tscn"
const SCENE_SETTINGS: String = "res://scenes/Settings.tscn"
const SCENE_PROFILE: String = "res://scenes/Profile.tscn"

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
	get_parent().get_node("ProfileButton").pressed.connect(_on_profile_pressed)
	get_parent().get_node("VBox/ExitButton").pressed.connect(_on_exit_pressed)
	_status_label.text = ""
	get_viewport().size_changed.connect(_fit_menu)
	_fit_menu()


func _fit_menu() -> void:
	var root: Control = get_parent() as Control
	ResponsiveLayout.fit_centered_box(root.get_node("VBox") as Control, 550.0, 820.0)
	var viewport_size := root.get_viewport_rect().size
	var title_label: Label = root.get_node("VBox/TitleLabel") as Label
	var compact := viewport_size.y < 560.0
	title_label.add_theme_font_size_override("font_size", int(clampf(minf(viewport_size.x * 0.04, viewport_size.y * 0.11), 30.0, 76.0)))
	var logo: TextureRect = root.get_node("VBox/Logo") as TextureRect
	logo.visible = not compact
	logo.custom_minimum_size.y = minf(64.0, viewport_size.y * 0.09)
	root.get_node("VBox/Tagline").visible = not compact
	root.get_node("VBox/CalibrateButton").visible = not OS.has_feature("mobile")
	root.get_node("VBox/ExitButton").visible = not OS.has_feature("mobile")
	root.get_node("VBox/Spacer").custom_minimum_size.y = 22.0 if not compact else 0.0
	var menu_box: VBoxContainer = root.get_node("VBox") as VBoxContainer
	menu_box.add_theme_constant_override("separation", 8 if compact else 12)
	root.get_node("VBox/PlayButton").custom_minimum_size.y = 72.0 if not compact else 48.0
	root.get_node("VBox/SongLibraryButton").custom_minimum_size.y = 64.0 if not compact else 44.0
	root.get_node("VBox/CalibrateButton").custom_minimum_size.y = 64.0 if not compact else 44.0
	root.get_node("VBox/SettingsButton").custom_minimum_size.y = 64.0 if not compact else 44.0
	root.get_node("VBox/ExitButton").custom_minimum_size.y = 54.0 if not compact else 42.0


func _on_play_pressed() -> void:
	_status_label.text = "Starting game..."
	go_to_gameplay("example_track", "res://charts/example_track_chart.json")


func _on_song_library_pressed() -> void:
	_status_label.text = "Loading song library..."
	go_to_song_selection()


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(SCENE_SETTINGS)


func _on_profile_pressed() -> void:
	get_tree().change_scene_to_file(SCENE_PROFILE)


func _on_exit_pressed() -> void:
	get_tree().quit()


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
	else:
		_status_label.text = "Failed to load chart: " + song_id
		GameStateManager.reset_to_main_menu()
