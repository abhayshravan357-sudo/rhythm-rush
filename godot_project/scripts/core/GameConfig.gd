extends Node

const DEFAULT_LANE_COUNT: int = 4
const ALLOWED_LANE_COUNTS: Array[int] = [4, 6]

const GAME_STATES: Dictionary = {
	"MAIN_MENU": "MAIN_MENU",
	"SONG_SELECTION": "SONG_SELECTION",
	"LOADING": "LOADING",
	"PLAYING": "PLAYING",
	"PAUSED": "PAUSED",
	"RESULTS": "RESULTS",
	"CALIBRATION": "CALIBRATION"
}

# Difficulty configuration used by gameplay and chart systems.
# Multipliers scale scoring/timing difficulty; density scales note spawn rate.
const DIFFICULTY_MULTIPLIERS: Dictionary = {
	"EASY": 0.7,
	"NORMAL": 1.0,
	"HARD": 1.4,
	"EXPERT": 2.0
}

const DIFFICULTY_NOTE_DENSITY: Dictionary = {
	"EASY": 0.5,
	"NORMAL": 1.0,
	"HARD": 1.5,
	"EXPERT": 2.0
}


static func normalize_lane_count(raw_count: int) -> int:
	var candidate: int = maxi(4, raw_count)
	if candidate in ALLOWED_LANE_COUNTS:
		return candidate
	return DEFAULT_LANE_COUNT


static func is_supported_lane_count(raw_count: int) -> bool:
	return raw_count in ALLOWED_LANE_COUNTS


static func get_difficulty_multiplier(difficulty: String) -> float:
	var value: Variant = DIFFICULTY_MULTIPLIERS.get(difficulty, DIFFICULTY_MULTIPLIERS["NORMAL"])
	return float(value)


static func get_note_density_multiplier(difficulty: String) -> float:
	var value: Variant = DIFFICULTY_NOTE_DENSITY.get(difficulty, DIFFICULTY_NOTE_DENSITY["NORMAL"])
	return float(value)
