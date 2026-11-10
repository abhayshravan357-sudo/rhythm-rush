# SceneTransitionManager.gd
# Autoload Singleton — centralized scene loading with error handling.
#
# Provides a single entry point for all scene transitions so UI scripts and
# gameplay code do not duplicate hardcoded scene paths or bypass error handling.
# Registers a named scene registry so callers can transition by logical name
# instead of by path.
#
# Signals:
#   scene_loaded(path) — emitted when a scene is successfully loaded
#   scene_load_failed(path, reason) — emitted when loading or changing fails
extends Node

const SAVE_STATE_KEY := "last_scene"

# Default named scene registry. Paths are registered by logical name so the
# UI hub and other callers do not depend on literal scene paths.
var scene_registry: Dictionary = {
	"main_menu": "res://scenes/MainMenu.tscn",
	"song_selection": "res://scenes/SongSelection.tscn",
	"calibration": "res://scenes/CalibrationScene.tscn",
	"gameplay": "res://scenes/GameScene.tscn",
	"results": "res://scenes/Results.tscn",
	"settings": "res://scenes/Settings.tscn",
	"profile": "res://scenes/Profile.tscn",
}


signal scene_loaded(path: String)
signal scene_load_failed(path: String, reason: String)


func register_scene(name: String, path: String) -> void:
	scene_registry[name] = path


func get_scene_path(name: String) -> String:
	return scene_registry.get(name, "")


# ── Loading ───────────────────────────────────────────────────────────────────

func load_scene(path: String) -> PackedScene:
	"""Load a PackedScene from path. Returns null on failure and emits scene_load_failed."""
	if path.is_empty():
		printerr("[SceneTransitionManager] Empty scene path requested.")
		emit_signal("scene_load_failed", "", "Empty scene path")
		return null

	var res := load(path)
	if res == null:
		printerr("[SceneTransitionManager] Failed to load scene: ", path)
		emit_signal("scene_load_failed", path, "Resource returned null")
		return null

	if not (res is PackedScene):
		printerr("[SceneTransitionManager] Resource is not a PackedScene: ", path)
		emit_signal("scene_load_failed", path, "Not a PackedScene")
		return null

	emit_signal("scene_loaded", path)
	return res


# ── Scene changes ─────────────────────────────────────────────────────────────

func change_scene(path: String) -> bool:
	"""Load and change to the scene at path. Returns true on success."""
	var scene := load_scene(path)
	if scene == null:
		return false

	var err := get_tree().change_scene_to_packed(scene)
	if err != OK:
		printerr("[SceneTransitionManager] change_scene_to_packed failed for: ", path, " err: ", err)
		emit_signal("scene_load_failed", path, "change_scene_to_packed error: %d" % err)
		return false

	return true


func change_scene_to(scene_name: String) -> bool:
	"""Change to a scene by its registered logical name."""
	var path := get_scene_path(scene_name)
	if path.is_empty():
		printerr("[SceneTransitionManager] Unknown scene name: ", scene_name)
		emit_signal("scene_load_failed", scene_name, "Unknown scene name")
		return false

	return change_scene(path)
