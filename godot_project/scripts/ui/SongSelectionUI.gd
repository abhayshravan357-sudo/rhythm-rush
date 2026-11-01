# SongSelectionUI.gd
# UI controller for the Song Selection (library) scene.
#
# Presents a demo catalogue, lets the user pick a song, and transitions into
# gameplay via GameController.prepare_song / GameController.start_song while
# driving GameStateManager. Back returns to the main menu.
extends Node

const SCENE_MAIN_MENU: String = "res://scenes/MainMenu.tscn"
const SCENE_GAMEPLAY: String = "res://scenes/GameScene.tscn"

var _selected_song_index: int = -1

var _songs: Array[Dictionary] = [
	{"id": "neon_pulse", "title": "Neon Pulse", "artist": "Synthex", "chart": "res://assets/data/neon_pulse.json"},
	{"id": "midnight_drive", "title": "Midnight Drive", "artist": "Lumen", "chart": "res://assets/data/midnight_drive.json"},
	{"id": "cyan_circuit", "title": "Cyan Circuit", "artist": "Flux", "chart": "res://assets/data/cyan_circuit.json"},
]

@onready var _song_list: ItemList = get_parent().get_node("VBox/SongList")
@onready var _play_button: Button = get_parent().get_node("VBox/HBox/PlayButton")
@onready var _back_button: Button = get_parent().get_node("VBox/HBox/BackButton")
@onready var _status_label: Label = get_parent().get_node("VBox/StatusLabel")


func _ready() -> void:
	_populate_list()
	_song_list.item_selected.connect(_on_song_selected)
	_song_list.item_activated.connect(_on_song_activated)
	_play_button.pressed.connect(_on_play_pressed)
	_play_button.disabled = true
	_back_button.pressed.connect(_on_back_pressed)
	_status_label.text = ""


func _populate_list() -> void:
	for song: Dictionary in _songs:
		_song_list.add_item(song["title"] + "  —  " + song["artist"])


func _on_song_selected(index: int) -> void:
	_selected_song_index = index
	_play_button.disabled = index < 0


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
		GameController.start_song()
	else:
		_status_label.text = "No chart available for demo song (chart assets pending)."
		GameStateManager.reset_to_main_menu()
