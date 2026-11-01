extends Node
class_name GameConfig

const DEFAULT_LANE_COUNT: int = 4
const ALLOWED_LANE_COUNTS: PackedInt32Array = PackedInt32Array([4, 6])

const GAME_STATES: Dictionary = {
	"MAIN_MENU": "MAIN_MENU",
	"SONG_SELECTION": "SONG_SELECTION",
	"LOADING": "LOADING",
	"PLAYING": "PLAYING",
	"PAUSED": "PAUSED",
	"RESULTS": "RESULTS",
	"CALIBRATION": "CALIBRATION"
}


static func normalize_lane_count(raw_count: int) -> int:
	var candidate: int = maxi(4, raw_count)
	if candidate in ALLOWED_LANE_COUNTS:
		return candidate
	return DEFAULT_LANE_COUNT


static func is_supported_lane_count(raw_count: int) -> bool:
	return raw_count in ALLOWED_LANE_COUNTS
