@global_class
extends SceneTree

var _scenes: Array = [
	"res://scenes/MainHub.tscn",
	"res://scenes/MainMenu.tscn",
	"res://scenes/GameScene.tscn",
]
var _index: int = 0

func _ready() -> void:
	_run_next()

func _run_next() -> void:
	if _index >= _scenes.size():
		print("ALL SCENES VALIDATED")
		quit()
		return
	var path: String = _scenes[_index]
	_index += 1
	var res: Resource = load(path)
	if res == null:
		print("FAIL: could not load ", path)
		_run_next()
		return
	if res.get_class() != "PackedScene":
		print("FAIL: ", path, " is not PackedScene (got ", res.get_class(), ")")
		_run_next()
		return
	var instance: Node = res.instantiate()
	if instance == null:
		print("FAIL: could not instantiate ", path)
		_run_next()
		return
	print("OK: ", path, " -> ", instance.get_class(), " (", instance.get_name(), ")")
	instance.queue_free()
	call_deferred("_run_next")

func _process(_delta: float) -> bool:
	return false
