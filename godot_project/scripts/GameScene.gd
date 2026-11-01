# GameScene.gd
# Root node of the gameplay scene. Wires the AudioStreamPlayer into the
# AudioSync autoload so the authoritative audio clock drives note timing.
extends Node2D


func _ready() -> void:
	AudioSync.initialize_playback_channel($AudioPlayer)
