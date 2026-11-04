extends Control

const ResponsiveLayout = preload("res://scripts/ui/ResponsiveLayout.gd")

@onready var summary_label: Label = $VBox/Summary
@onready var personal_best_label: Label = $VBox/PersonalBest
@onready var hero_score_label: Label = $VBox/HeroScore
@onready var grade_label: Label = $VBox/Grade


func _ready() -> void:
	$VBox/Buttons/RetryButton.pressed.connect(_on_retry_pressed)
	$VBox/Buttons/SongLibraryButton.pressed.connect(_on_song_library_pressed)
	$VBox/Buttons/MenuButton.pressed.connect(_on_menu_pressed)
	get_viewport().size_changed.connect(_fit_panel)
	_fit_panel()
	var result: Dictionary = GameController.last_result
	if result.is_empty():
		summary_label.text = "No completed run is available."
		$VBox/Buttons/RetryButton.disabled = true
		return
	hero_score_label.text = "%07d" % int(result.get("score", 0))
	grade_label.text = "GRADE  %s" % String(result.get("grade", "F"))
	summary_label.text = "ACCURACY  %.1f%%\n\nPERFECT  %d     GOOD  %d     MISS  %d\nMAX COMBO  %d     NOTES  %d" % [
		float(result.get("accuracy", 0.0)),
		int(result.get("perfects", 0)),
		int(result.get("goods", 0)),
		int(result.get("misses", 0)),
		int(result.get("max_combo", 0)),
		int(result.get("total_notes", 0)),
	]
	var personal_best := PlayerProfile.get_high_score(String(result.get("song_id", "")))
	personal_best_label.text = "Personal best: %d%s" % [personal_best, "  •  NEW BEST" if bool(result.get("personal_best", false)) else ""]


func _fit_panel() -> void:
	var compact := get_viewport_rect().size.y < 600.0
	var vbox: VBoxContainer = $VBox
	ResponsiveLayout.fit_centered_box(vbox, 840.0, 720.0)
	vbox.add_theme_constant_override("separation", 8 if compact else 20)
	$VBox/Title.add_theme_font_size_override("font_size", 34 if compact else 52)
	hero_score_label.add_theme_font_size_override("font_size", 40 if compact else 64)
	grade_label.add_theme_font_size_override("font_size", 32 if compact else 48)
	summary_label.custom_minimum_size.y = 100.0 if compact else 160.0
	summary_label.add_theme_font_size_override("font_size", 18 if compact else 24)
	personal_best_label.add_theme_font_size_override("font_size", 16 if compact else 22)
	for button in $VBox/Buttons.get_children():
		(button as Button).custom_minimum_size.y = 48.0 if compact else 64.0


func _on_retry_pressed() -> void:
	var song_id := GameController.current_song_id
	var chart_path := GameController.current_chart_path
	if GameController.prepare_song(song_id, chart_path):
		get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
	else:
		_on_song_library_pressed()


func _on_song_library_pressed() -> void:
	GameController.exit_to_menu()
	GameStateManager.transition_to(GameStateManager.GameState.SONG_SELECTION)
	get_tree().change_scene_to_file("res://scenes/SongSelection.tscn")


func _on_menu_pressed() -> void:
	GameController.exit_to_menu()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
