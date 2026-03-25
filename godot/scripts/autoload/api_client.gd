extends Node
## ApiClient - HTTP client for communicating with the KidNeuro API.
## Autoloaded singleton handling authentication, API requests, and
## real-time WebSocket connection for behavior events from Savant.

signal behavior_event_received(event_data: Dictionary)

var api_base_url: String = "http://localhost:8000"
var access_token: String = ""
var _http_request: HTTPRequest

# --- WebSocket for real-time behavior events ---
var behavior_ws: WebSocketPeer = null
var _ws_connected: bool = false
var _ws_child_id: String = ""
var _ws_reconnect_timer: float = 0.0
var _ws_reconnect_delay: float = 3.0
var _ws_should_reconnect: bool = false
var _ws_max_reconnect_attempts: int = 10
var _ws_reconnect_attempts: int = 0


func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)

	# Load API URL from config or environment
	if OS.has_environment("API_URL"):
		api_base_url = OS.get_environment("API_URL")


func _process(delta: float) -> void:
	# Process WebSocket messages
	if behavior_ws != null:
		behavior_ws.poll()

		var state := behavior_ws.get_ready_state()

		match state:
			WebSocketPeer.STATE_OPEN:
				if not _ws_connected:
					_ws_connected = true
					_ws_reconnect_attempts = 0
					print("[ApiClient] Behavior WebSocket connected for child: ", _ws_child_id)

				# Read all available messages
				while behavior_ws.get_available_packet_count() > 0:
					var packet := behavior_ws.get_packet()
					_handle_ws_message(packet)

			WebSocketPeer.STATE_CLOSING:
				pass  # Wait for close to complete

			WebSocketPeer.STATE_CLOSED:
				var code := behavior_ws.get_close_code()
				var reason := behavior_ws.get_close_reason()
				print("[ApiClient] Behavior WebSocket closed: code=%d reason=%s" % [code, reason])
				_ws_connected = false
				behavior_ws = null

				# Attempt reconnection
				if _ws_should_reconnect:
					_ws_reconnect_timer = 0.0

	# Handle reconnection timer
	if _ws_should_reconnect and behavior_ws == null and not _ws_child_id.is_empty():
		_ws_reconnect_timer += delta
		if _ws_reconnect_timer >= _ws_reconnect_delay:
			_ws_reconnect_timer = 0.0
			if _ws_reconnect_attempts < _ws_max_reconnect_attempts:
				_ws_reconnect_attempts += 1
				print("[ApiClient] Reconnecting behavior WS (attempt %d/%d)..." % [
					_ws_reconnect_attempts, _ws_max_reconnect_attempts
				])
				_connect_ws_internal(_ws_child_id)
			else:
				print("[ApiClient] Max reconnection attempts reached. Giving up.")
				_ws_should_reconnect = false


func set_token(token: String) -> void:
	access_token = token


# =============================================================================
# HTTP Methods
# =============================================================================

func get(path: String) -> Variant:
	return await _request("GET", path)


func post(path: String, body: Dictionary = {}) -> Variant:
	return await _request("POST", path, body)


func patch(path: String, body: Dictionary = {}) -> Variant:
	return await _request("PATCH", path, body)


func delete(path: String) -> Variant:
	return await _request("DELETE", path)


func _request(method: String, path: String, body: Dictionary = {}) -> Variant:
	var url := api_base_url + path
	var headers := PackedStringArray([
		"Content-Type: application/json",
	])

	if not access_token.is_empty():
		headers.append("Authorization: Bearer %s" % access_token)

	var http := HTTPRequest.new()
	add_child(http)

	var method_enum: int
	match method:
		"GET": method_enum = HTTPClient.METHOD_GET
		"POST": method_enum = HTTPClient.METHOD_POST
		"PATCH": method_enum = HTTPClient.METHOD_PATCH
		"DELETE": method_enum = HTTPClient.METHOD_DELETE
		_: method_enum = HTTPClient.METHOD_GET

	var body_str := JSON.stringify(body) if not body.is_empty() else ""
	var error := http.request(url, headers, method_enum, body_str)

	if error != OK:
		push_warning("API request failed: %s %s" % [method, path])
		http.queue_free()
		return null

	var result = await http.request_completed
	http.queue_free()

	var response_code: int = result[1]
	var response_body: PackedByteArray = result[3]

	if response_code < 200 or response_code >= 300:
		push_warning("API %s %s returned %d" % [method, path, response_code])
		return null

	if response_body.size() == 0:
		return {}

	var json := JSON.new()
	var parse_error := json.parse(response_body.get_string_from_utf8())
	if parse_error != OK:
		return null

	return json.data


# =============================================================================
# WebSocket - Behavior Events
# =============================================================================

func connect_behavior_ws(child_id: String) -> void:
	"""Connect to the behavior events WebSocket for a specific child.

	Receives real-time behavior detection events from the Savant video
	pipeline (repetitive motion, activity level, presence changes).
	"""
	# Disconnect existing connection first
	if behavior_ws != null:
		disconnect_behavior_ws()

	_ws_child_id = child_id
	_ws_should_reconnect = true
	_ws_reconnect_attempts = 0
	_connect_ws_internal(child_id)


func _connect_ws_internal(child_id: String) -> void:
	"""Internal: create WebSocket and initiate connection."""
	# Derive WebSocket URL from API base URL
	var gateway_url := api_base_url.replace("http://", "").replace("https://", "")
	var ws_scheme := "wss://" if api_base_url.begins_with("https") else "ws://"
	var ws_url := "%s%s/ws/behavior/%s" % [ws_scheme, gateway_url, child_id]

	behavior_ws = WebSocketPeer.new()

	# Add auth header if we have a token
	var headers := PackedStringArray()
	if not access_token.is_empty():
		headers.append("Authorization: Bearer %s" % access_token)

	var err := behavior_ws.connect_to_url(ws_url, TLSOptions.client(), false, headers)
	if err != OK:
		push_warning("[ApiClient] Failed to connect behavior WS to %s: error %d" % [ws_url, err])
		behavior_ws = null
	else:
		print("[ApiClient] Connecting behavior WS to: ", ws_url)


func disconnect_behavior_ws() -> void:
	"""Disconnect from the behavior events WebSocket."""
	_ws_should_reconnect = false
	_ws_child_id = ""
	_ws_reconnect_attempts = 0

	if behavior_ws != null:
		if _ws_connected:
			behavior_ws.close(1000, "Client disconnect")
		behavior_ws = null
		_ws_connected = false
		print("[ApiClient] Behavior WebSocket disconnected")


func _handle_ws_message(packet: PackedByteArray) -> void:
	"""Parse incoming WebSocket message and emit signal."""
	var text := packet.get_string_from_utf8()
	if text.is_empty():
		return

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("[ApiClient] Failed to parse behavior WS message: %s" % text)
		return

	var data: Dictionary = json.data
	if data.is_empty():
		return

	behavior_event_received.emit(data)
