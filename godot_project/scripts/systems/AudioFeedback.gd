extends Node

const SAMPLE_RATE := 22050

var _player: AudioStreamPlayer
var _streams: Dictionary = {}


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "SFX"
	add_child(_player)
	ScoreManager.alignment_processed.connect(_on_judgment)
	_streams["PERFECT"] = _make_tone(880.0, 0.075)
	_streams["GOOD"] = _make_tone(620.0, 0.09)
	_streams["MISS"] = _make_tone(220.0, 0.12)


func _exit_tree() -> void:
	if ScoreManager.alignment_processed.is_connected(_on_judgment):
		ScoreManager.alignment_processed.disconnect(_on_judgment)
	if is_instance_valid(_player):
		_player.stop()
		_player.stream = null
	_streams.clear()


func _on_judgment(rating: String, _combo: int, _accuracy: float) -> void:
	if not _streams.has(rating):
		return
	_player.stop()
	_player.stream = _streams[rating]
	_player.play()


func _make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var frame_count := int(SAMPLE_RATE * duration)
	var pcm := PackedByteArray()
	pcm.resize(frame_count * 2)
	for frame in range(frame_count):
		var phase := TAU * frequency * float(frame) / float(SAMPLE_RATE)
		var envelope := 1.0 - float(frame) / float(frame_count)
		var sample := int(sin(phase) * envelope * 10000.0)
		pcm.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	return stream
