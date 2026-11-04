# SongSelectionUI.gd
# UI controller for the Song Selection (library) scene.
#
# Presents a demo catalogue, lets the user pick a song, and transitions into
# gameplay via GameController.prepare_song / GameController.start_song while
# driving GameStateManager. Back returns to the main menu.
extends Node

const ResponsiveLayout = preload("res://scripts/ui/ResponsiveLayout.gd")

const SCENE_MAIN_MENU: String = "res://scenes/MainMenu.tscn"
const SCENE_GAMEPLAY: String = "res://scenes/GameScene.tscn"

var _selected_song_index: int = -1

var _songs: Array[Dictionary] = [
	{"id": "example_track", "title": "Example Track", "chart": "res://charts/example_track_chart.json"},
]

@onready var _song_list: ItemList = get_node("VBox/SongList")
@onready var _play_button: Button = get_node("VBox/HBox/PlayButton")
@onready var _back_button: Button = get_node("VBox/HBox/BackButton")
@onready var _status_label: Label = get_node("VBox/StatusLabel")
@onready var _selected_title: Label = get_node("VBox/SelectedTitle")
@onready var _song_metadata: Label = get_node("VBox/SongMetadata")
@onready var _best_score: Label = get_node("VBox/BestScore")


func _ready() -> void:
	_populate_list()
	_song_list.item_selected.connect(_on_song_selected)
	_song_list.item_activated.connect(_on_song_activated)
	_play_button.pressed.connect(_on_play_pressed)
	_play_button.disabled = true
	_back_button.pressed.connect(_on_back_pressed)
	_status_label.text = ""
	get_viewport().size_changed.connect(_fit_panel)
	_fit_panel()


func _fit_panel() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var compact := viewport_size.y < 600.0
	var vbox: VBoxContainer = get_node("VBox") as VBoxContainer
	ResponsiveLayout.fit_centered_box(vbox, 720.0, 820.0)
	vbox.add_theme_constant_override("separation", 6 if compact else 12)
	get_node("VBox/TitleLabel").add_theme_font_size_override("font_size", int(clampf(viewport_size.y * 0.09, 30.0, 50.0)))
	get_node("VBox/SelectedTitle").add_theme_font_size_override("font_size", int(clampf(viewport_size.y * 0.055, 18.0, 30.0)))
	get_node("VBox/SongMetadata").add_theme_font_size_override("font_size", 16 if compact else 18)
	get_node("VBox/BestScore").add_theme_font_size_override("font_size", 16 if compact else 18)
	get_node("VBox/Spacer1").custom_minimum_size.y = 8.0 if compact else 20.0
	get_node("VBox/Spacer2").custom_minimum_size.y = 8.0 if compact else 20.0
	get_node("VBox/SongList").custom_minimum_size.y = minf(320.0, maxf(96.0, viewport_size.y * 0.26))
	_play_button.custom_minimum_size.y = 48.0 if compact else 60.0
	_back_button.custom_minimum_size.y = 48.0 if compact else 60.0


func _populate_list() -> void:
	for song: Dictionary in _songs:
		_song_list.add_item(song["title"])
	if _songs.is_empty():
		_selected_title.text = "NO LOCAL TRACKS"
		_song_metadata.text = "Add a chart and its audio file to the local song library."
		_status_label.text = "Your library is empty."


func _on_song_selected(index: int) -> void:
	_selected_song_index = index
	_play_button.disabled = true
	if index < 0 or index >= _songs.size():
		return
	var song: Dictionary = _songs[index]
	_selected_title.text = String(song.get("title", "Unknown track")).to_upper()
	_best_score.text = ""
	var chart: Dictionary = ChartLoader.load_chart(String(song.get("chart", "")))
	if chart.is_empty():
		_song_metadata.text = "Chart unavailable or invalid."
		_status_label.text = "This track cannot be loaded."
		return
	var metadata: Dictionary = chart.get("metaData", {})
	var bpm := float(metadata.get("bpm", 0.0))
	var lane_count := int(metadata.get("laneCount", GameConfig.DEFAULT_LANE_COUNT))
	var details := "%.1f BPM   ·   %d lanes" % [bpm, lane_count]
	var difficulty := String(metadata.get("difficulty", ""))
	if not difficulty.is_empty():
		details += "   ·   " + difficulty.to_upper()
	_song_metadata.text = details
	var best := PlayerProfile.get_high_score(String(song.get("id", "")))
	_best_score.text = "PERSONAL BEST  %07d" % best if best > 0 else "NO PERSONAL BEST YET"
	var audio_file := String(metadata.get("audioFile", ""))
	if audio_file.is_empty() or audio_file.get_file() != audio_file or not ResourceLoader.exists("res://assets/audio/" + audio_file):
		_status_label.text = "Audio file is missing for this track."
		return
	_status_label.text = "Ready to play."
	_play_button.disabled = false


func _on_song_activated(index: int) -> void:
	_on_play_pressed()


func _on_play_pressed() -> void:
	if _selected_song_index < 0:
		return
	var song: Dictionary = _songs[_selected_song_index]
	_status_label.text = "Preparing " + song["title"] + "..."
	go_to_gameplay(song["id"], song["chart"])


func _on_back_pressed() -> void:
	var scene: PackedScene = load(SCENE_MAIN_MENU)
	if scene == null:
		_status_label.text = "Error: main menu scene missing."
		printerr("[SongSelectionUI] Failed to load: ", SCENE_MAIN_MENU)
		return
	GameStateManager.transition_to(GameStateManager.GameState.MAIN_MENU)
	get_tree().change_scene_to_packed(scene)


func go_to_gameplay(song_id: String, chart_path: String) -> void:
	if GameController.prepare_song(song_id, chart_path):
		get_tree().change_scene_to_packed(load(SCENE_GAMEPLAY))
	else:
		_status_label.text = "Unable to load this song. Check its chart file."
		GameStateManager.reset_to_main_menu()
