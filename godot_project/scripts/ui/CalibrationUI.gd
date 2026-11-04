extends Control

const ResponsiveLayout = preload("res://scripts/ui/ResponsiveLayout.gd")

@onready var tap_button: Button = $VBox/TapButton
@onready var start_button: Button = $VBox/HBox/StartButton
@onready var beat_indicator: ColorRect = $VBox/BeatIndicator
@onready var beat_label: Label = $VBox/BeatIndicator/BeatLabel
@onready var tap_count_label: Label = $VBox/TapCountLabel
@onready var result_label: Label = $VBox/ResultLabel


func _ready() -> void:
	OffsetCalibration.calibration_tick.connect(_on_calibration_tick)
	OffsetCalibration.calibration_complete.connect(_on_calibration_complete)
	tap_button.pressed.connect(_on_tap_pressed)
	start_button.pressed.connect(_on_start_pressed)
	$VBox/HBox/BackButton.pressed.connect(_on_back_pressed)
	OffsetCalibration.stop_calibration()
	tap_count_label.text = "Taps: 0 / %d" % OffsetCalibration.REQUIRED_TAPS
	get_viewport().size_changed.connect(_fit_panel)
	_fit_panel()


func _fit_panel() -> void:
	var compact := get_viewport_rect().size.y < 600.0
	var vbox: VBoxContainer = $VBox
	ResponsiveLayout.fit_centered_box(vbox, 900.0, 900.0, 20.0)
	vbox.add_theme_constant_override("separation", 5 if compact else 8)
	$VBox/TitleLabel.add_theme_font_size_override("font_size", 34 if compact else 52)
	$VBox/InstructionLabel.add_theme_font_size_override("font_size", 15 if compact else 22)
	$VBox/Spacer1.custom_minimum_size.y = 6.0 if compact else 30.0
	$VBox/Spacer2.custom_minimum_size.y = 6.0 if compact else 30.0
	$VBox/Spacer3.custom_minimum_size.y = 6.0 if compact else 20.0
	$VBox/Spacer4.custom_minimum_size.y = 6.0 if compact else 20.0
	beat_indicator.custom_minimum_size.y = 68.0 if compact else 140.0
	tap_button.custom_minimum_size.y = 58.0 if compact else 120.0
	tap_count_label.add_theme_font_size_override("font_size", 17 if compact else 24)
	result_label.add_theme_font_size_override("font_size", 18 if compact else 28)
	start_button.custom_minimum_size.y = 48.0 if compact else 70.0
	$VBox/HBox/BackButton.custom_minimum_size.y = 48.0 if compact else 70.0


func _exit_tree() -> void:
	OffsetCalibration.stop_calibration()
	if OffsetCalibration.calibration_tick.is_connected(_on_calibration_tick):
		OffsetCalibration.calibration_tick.disconnect(_on_calibration_tick)
	if OffsetCalibration.calibration_complete.is_connected(_on_calibration_complete):
		OffsetCalibration.calibration_complete.disconnect(_on_calibration_complete)


func _on_start_pressed() -> void:
	OffsetCalibration.start_calibration()
	tap_button.disabled = false
	start_button.disabled = true
	result_label.text = "Tap in time with the pulse."
	tap_count_label.text = "Taps: 0 / %d" % OffsetCalibration.REQUIRED_TAPS


func _on_tap_pressed() -> void:
	OffsetCalibration.register_tap()
	tap_count_label.text = "Taps: %d / %d" % [OffsetCalibration.get_tap_count(), OffsetCalibration.REQUIRED_TAPS]


func _on_calibration_tick() -> void:
	beat_indicator.color = Color(0.12, 0.62, 0.92, 1)
	beat_label.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(beat_indicator, "color", Color(0.15, 0.15, 0.2, 1), 0.2)
	tween.parallel().tween_property(beat_label, "modulate", Color(0.3, 0.3, 0.3, 1), 0.2)


func _on_calibration_complete(offset_seconds: float) -> void:
	tap_button.disabled = true
	start_button.disabled = false
	result_label.text = "Saved offset: %+.1f ms" % (offset_seconds * 1000.0)
	tap_count_label.text = "Calibration complete"


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")
