# MenuNetworkSyncReceiver.gd
# Dynamic network asset fetcher for the Main Menu.
#
# Flow:
#   1. initialize_manifest_fetch(ip)  → GET http://<ip>:8000/manifest.json
#   2. evaluate_manifest_payload()    → parse "songs" array, emit manifest_loaded
#   3. download_song(song_entry)      → GET chart JSON + audio OGG, save to user://
#   4. emit download_complete or download_failed
#
# Downloads are saved to:
#   Charts : user://data/<chart_filename>
#   Audio  : user://audio/<audio_filename>
extends Node

signal manifest_loaded(songs: Array)
signal download_progress(song_id: String, bytes_done: int, bytes_total: int)
signal download_complete(song_id: String)
signal download_failed(song_id: String, reason: String)

const PORT: int = 8000

var _http: HTTPRequest = null
var _host_ip: String = ""

# State machine for the sequential download pair (chart → audio)
enum _State { IDLE, FETCHING_MANIFEST, FETCHING_CHART, FETCHING_AUDIO }
var _state: _State = _State.IDLE
var _pending_song: Dictionary = {}   # The song entry currently being downloaded


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_http.use_threads = true  # Non-blocking downloads on mobile


func initialize_manifest_fetch(target_ip: String) -> void:
	if _state != _State.IDLE:
		push_warning("[NetworkSync] A request is already in flight.")
		return
	_host_ip = target_ip.strip_edges()
	var url: String = "http://%s:%d/manifest.json" % [_host_ip, PORT]
	print("[NetworkSync] Fetching manifest: ", url)
	_state = _State.FETCHING_MANIFEST
	var err := _http.request(url)
	if err != OK:
		_state = _State.IDLE
		emit_signal("download_failed", "manifest", "HTTP request error: %d" % err)


func download_song(song_entry: Dictionary) -> void:
	## Call this with one entry from the manifest's "songs" array.
	if _state != _State.IDLE:
		push_warning("[NetworkSync] Cannot start download while another is in progress.")
		return
	_pending_song = song_entry
	_fetch_chart_file()


# ── Internal helpers ───────────────────────────────────────────────────────────

func _fetch_chart_file() -> void:
	var url: String = "http://%s:%d/%s" % [_host_ip, PORT, _pending_song["chart"]]
	print("[NetworkSync] Downloading chart: ", url)
	_state = _State.FETCHING_CHART
	var err := _http.request(url)
	if err != OK:
		_state = _State.IDLE
		emit_signal("download_failed", _pending_song.get("id", "?"), "Chart fetch error: %d" % err)


func _fetch_audio_file() -> void:
	var url: String = "http://%s:%d/%s" % [_host_ip, PORT, _pending_song["audio"]]
	print("[NetworkSync] Downloading audio: ", url)
	_state = _State.FETCHING_AUDIO
	var err := _http.request(url)
	if err != OK:
		_state = _State.IDLE
		emit_signal("download_failed", _pending_song.get("id", "?"), "Audio fetch error: %d" % err)


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		var reason: String = "HTTP %d / result %d" % [response_code, result]
		_state = _State.IDLE
		emit_signal("download_failed", _pending_song.get("id", "manifest"), reason)
		return

	match _state:
		_State.FETCHING_MANIFEST:
			_handle_manifest_response(body)
		_State.FETCHING_CHART:
			_handle_chart_response(body)
		_State.FETCHING_AUDIO:
			_handle_audio_response(body)


func _handle_manifest_response(body: PackedByteArray) -> void:
	_state = _State.IDLE
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		emit_signal("download_failed", "manifest", "JSON parse error")
		return

	var data: Variant = json.get_data()
	if typeof(data) != TYPE_DICTIONARY or not data.has("songs"):
		emit_signal("download_failed", "manifest", "Unexpected manifest structure")
		return

	var songs: Array = data["songs"]
	print("[NetworkSync] Manifest loaded — %d song(s)" % songs.size())
	emit_signal("manifest_loaded", songs)


func _handle_chart_response(body: PackedByteArray) -> void:
	# Ensure destination directory exists
	DirAccess.make_dir_recursive_absolute("user://data")
	var save_path: String = "user://data/" + _pending_song["chart"]
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		_state = _State.IDLE
		emit_signal("download_failed", _pending_song["id"], "Cannot write chart to disk")
		return
	file.store_buffer(body)
	file.close()
	print("[NetworkSync] Chart saved: ", save_path)
	# Immediately chain into downloading the audio file
	_fetch_audio_file()


func _handle_audio_response(body: PackedByteArray) -> void:
	DirAccess.make_dir_recursive_absolute("user://audio")
	var save_path: String = "user://audio/" + _pending_song["audio"]
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		_state = _State.IDLE
		emit_signal("download_failed", _pending_song["id"], "Cannot write audio to disk")
		return
	file.store_buffer(body)
	file.close()
	print("[NetworkSync] Audio saved: ", save_path)

	_state = _State.IDLE
	emit_signal("download_complete", _pending_song["id"])
