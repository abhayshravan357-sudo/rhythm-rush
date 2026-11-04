extends Node

signal setting_changed(key: String, value: float)

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_MUSIC_VOLUME := 0.8
const DEFAULT_SFX_VOLUME := 0.8
const DEFAULT_AUDIO_OFFSET := 0.0

var music_volume := DEFAULT_MUSIC_VOLUME
var sfx_volume := DEFAULT_SFX_VOLUME


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var load_result := config.load(SETTINGS_PATH)
	if load_result != OK and load_result != ERR_FILE_NOT_FOUND:
		printerr("[SettingsManager] Invalid settings file; using defaults.")
	music_volume = _validated_volume(config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME), DEFAULT_MUSIC_VOLUME)
	sfx_volume = _validated_volume(config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME), DEFAULT_SFX_VOLUME)
	var offset_value: Variant = config.get_value("audio", "user_offset", DEFAULT_AUDIO_OFFSET)
	var audio_offset := float(offset_value) if offset_value is float or offset_value is int else DEFAULT_AUDIO_OFFSET
	if not is_finite(audio_offset) or absf(audio_offset) > 1.0:
		audio_offset = DEFAULT_AUDIO_OFFSET
	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("SFX", sfx_volume)
	AudioSync.local_hardware_offset = audio_offset
	if load_result != OK or config.get_value("audio", "music_volume", null) == null or config.get_value("audio", "sfx_volume", null) == null:
		save_settings()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume("Music", music_volume)
	save_settings()
	emit_signal("setting_changed", "music_volume", music_volume)


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume("SFX", sfx_volume)
	save_settings()
	emit_signal("setting_changed", "sfx_volume", sfx_volume)


func reset_settings() -> void:
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	AudioSync.local_hardware_offset = DEFAULT_AUDIO_OFFSET
	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("SFX", sfx_volume)
	save_settings()


func save_settings() -> bool:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		config = ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "user_offset", AudioSync.local_hardware_offset)
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		printerr("[SettingsManager] Could not save settings: ", err)
	return err == OK


func _apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_error("[SettingsManager] Missing audio bus: " + bus_name)
		return
	AudioServer.set_bus_mute(bus_index, value <= 0.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.0001)))


func _validated_volume(value: Variant, fallback: float) -> float:
	if not (value is float or value is int):
		return fallback
	var parsed := float(value)
	return clampf(parsed, 0.0, 1.0) if is_finite(parsed) else fallback
