extends Control

const ResponsiveLayout = preload("res://scripts/ui/ResponsiveLayout.gd")

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const CALIBRATION_SCENE := "res://scenes/CalibrationScene.tscn"

@onready var music_slider: HSlider = $VBox/MusicSlider
@onready var sfx_slider: HSlider = $VBox/SfxSlider
@onready var status_label: Label = $VBox/StatusLabel
@onready var music_label: Label = $VBox/MusicLabel
@onready var sfx_label: Label = $VBox/SfxLabel


func _ready() -> void:
	music_slider.value = SettingsManager.music_volume * 100.0
	sfx_slider.value = SettingsManager.sfx_volume * 100.0
	_update_slider_labels()
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	$VBox/Buttons/ResetButton.pressed.connect(_on_reset_pressed)
	$VBox/Buttons/CalibrationButton.pressed.connect(_on_calibration_pressed)
	$VBox/Buttons/BackButton.pressed.connect(_on_back_pressed)
	get_viewport().size_changed.connect(_fit_panel)
	_fit_panel()


func _fit_panel() -> void:
	var viewport_height := get_viewport_rect().size.y
	var compact := viewport_height < 600.0
	var vbox: VBoxContainer = $VBox
	ResponsiveLayout.fit_centered_box(vbox, 720.0, 680.0)
	vbox.add_theme_constant_override("separation", 8 if compact else 24)
	$VBox/Title.add_theme_font_size_override("font_size", 36 if compact else 56)
	music_label.add_theme_font_size_override("font_size", 19 if compact else 26)
	sfx_label.add_theme_font_size_override("font_size", 19 if compact else 26)
	$VBox/OffsetLabel.add_theme_font_size_override("font_size", 15 if compact else 20)
	music_slider.custom_minimum_size.y = 36.0 if compact else 44.0
	sfx_slider.custom_minimum_size.y = 36.0 if compact else 44.0
	for button in $VBox/Buttons.get_children():
		(button as Button).custom_minimum_size = Vector2(120.0, 48.0) if compact else Vector2(180.0, 60.0)


func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value / 100.0)
	_update_slider_labels()
	status_label.text = "Music volume saved."


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value / 100.0)
	_update_slider_labels()
	status_label.text = "Sound effects volume saved."


func _on_reset_pressed() -> void:
	SettingsManager.reset_settings()
	music_slider.value = SettingsManager.music_volume * 100.0
	sfx_slider.value = SettingsManager.sfx_volume * 100.0
	status_label.text = "Audio settings restored to defaults."
	_update_slider_labels()


func _update_slider_labels() -> void:
	music_label.text = "MUSIC VOLUME  ·  %d%%" % int(round(music_slider.value))
	sfx_label.text = "SOUND EFFECTS  ·  %d%%" % int(round(sfx_slider.value))


func _on_calibration_pressed() -> void:
	get_tree().change_scene_to_file(CALIBRATION_SCENE)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
