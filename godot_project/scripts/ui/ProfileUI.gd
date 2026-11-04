extends Control

const ResponsiveLayout = preload("res://scripts/ui/ResponsiveLayout.gd")

@onready var summary: Label = $VBox/Summary
@onready var bests: Label = $VBox/Bests


func _ready() -> void:
	var profile: Dictionary = PlayerProfile.get_profile()
	summary.text = "Level %d    XP %d / %d\nPlays %d    Total Score %d\nMax Combo %d\nPERFECT %d    GOOD %d    MISS %d" % [
		PlayerProfile.get_level(),
		PlayerProfile.get_xp(),
		PlayerProfile.get_xp_to_next(),
		int(profile.get("plays", 0)),
		int(profile.get("total_score", 0)),
		int(profile.get("max_combo_ever", 0)),
		int(profile.get("perfects", 0)),
		int(profile.get("goods", 0)),
		int(profile.get("misses", 0)),
	]
	var scores: Dictionary = profile.get("high_scores", {})
	var lines := PackedStringArray()
	for song_id: Variant in scores.keys():
		lines.append("%s  —  %d" % [String(song_id), int(scores[song_id])])
	lines.sort()
	bests.text = "PERSONAL BESTS\n" + ("\n".join(lines) if not lines.is_empty() else "No completed songs yet.")
	$VBox/BackButton.pressed.connect(_on_back_pressed)
	get_viewport().size_changed.connect(_fit_panel)
	_fit_panel()


func _fit_panel() -> void:
	var compact := get_viewport_rect().size.y < 600.0
	var vbox: VBoxContainer = $VBox
	ResponsiveLayout.fit_centered_box(vbox, 800.0, 680.0)
	vbox.add_theme_constant_override("separation", 12 if compact else 28)
	$VBox/Title.add_theme_font_size_override("font_size", 34 if compact else 52)
	summary.add_theme_font_size_override("font_size", 18 if compact else 26)
	bests.custom_minimum_size.y = 100.0 if compact else 150.0
	bests.add_theme_font_size_override("font_size", 17 if compact else 22)
	$VBox/BackButton.custom_minimum_size.y = 48.0 if compact else 64.0


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
