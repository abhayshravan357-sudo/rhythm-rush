# MainHubUI.gd
# UI controller for the Main Hub scene.
#
# Wires the four-lane navigation hub's tile buttons to simple click logging.
# Each tile press prints the lane + tile identity to the console.
# Navigation/scene switching is intentionally deferred to the owning agents.
extends Node

## Tile button paths, grouped by lane.
const LANE_TILES: Dictionary = {
	"DISCOVER": [
		"HubContainer/Lane01/Lane01Tiles/TileDiscoverFeatured",
		"HubContainer/Lane01/Lane01Tiles/TileDiscoverNew",
		"HubContainer/Lane01/Lane01Tiles/TileDiscoverRecommended",
	],
	"PLAY": [
		"HubContainer/Lane02/Lane02Tiles/TilePlayQuickPlay",
		"HubContainer/Lane02/Lane02Tiles/TilePlaySongSelection",
		"HubContainer/Lane02/Lane02Tiles/TilePlayContinue",
	],
	"CHALLENGES": [
		"HubContainer/Lane03/Lane03Tiles/TileChallengeDaily",
		"HubContainer/Lane03/Lane03Tiles/TileChallengeCombo",
		"HubContainer/Lane03/Lane03Tiles/TileChallengeAccuracy",
	],
	"PLAYER_ZONE": [
		"HubContainer/Lane04/Lane04Tiles/TilePlayerProfile",
		"HubContainer/Lane04/Lane04Tiles/TilePlayerStatistics",
		"HubContainer/Lane04/Lane04Tiles/TilePlayerAchievements",
		"HubContainer/Lane04/Lane04Tiles/TilePlayerBests",
	],
}

@onready var _root: Node = self
@onready var _status_label: Label = _root.get_node("StatusLabel")


func _ready() -> void:
	for lane_name: String in LANE_TILES.keys():
		for tile_path: String in LANE_TILES[lane_name]:
			var tile: Button = _root.get_node(tile_path) as Button
			if tile == null:
				push_warning("[MainHubUI] Tile not found: ", tile_path)
				continue
			tile.pressed.connect(_on_tile_pressed.bind(lane_name, tile_path))
	_status_label.text = "Hub ready — tap a lane tile."


func _on_tile_pressed(lane_name: String, tile_path: String) -> void:
	var tile_name: String = tile_path.get_file()
	print("[MainHubUI] Tile pressed — lane: ", lane_name, " | tile: ", tile_name)
	_status_label.text = "Selected: %s — %s" % [lane_name, tile_name]
