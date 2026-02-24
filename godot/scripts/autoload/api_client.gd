extends Node
## ApiClient - HTTP client for communicating with the KidNeuro API.
## Autoloaded singleton handling authentication and API requests.

var api_base_url: String = "http://localhost:8000"
var access_token: String = ""
var _http_request: HTTPRequest


func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)

	# Load API URL from config or environment
	if OS.has_environment("API_URL"):
		api_base_url = OS.get_environment("API_URL")


func set_token(token: String) -> void:
	access_token = token


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
