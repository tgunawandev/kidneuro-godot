extends Node
## GameManager - Global game state and session management.
## Autoloaded singleton managing child profiles, game sessions, and difficulty.

signal session_started(game_slug: String)
signal session_ended(game_slug: String, score: int)
signal difficulty_changed(new_level: int)
signal break_reminder()

var current_child_id: String = ""
var current_session_id: String = ""
var current_game_slug: String = ""
var difficulty_level: int = 1
var session_start_time: float = 0.0
var score: int = 0
var correct_answers: int = 0
var total_questions: int = 0

# Settings
var break_reminder_minutes: float = 15.0
var max_session_minutes: float = 45.0
var auto_adjust_difficulty: bool = true

var _break_timer: float = 0.0
var _session_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if current_session_id.is_empty():
		return

	_break_timer += delta
	_session_timer += delta

	if _break_timer >= break_reminder_minutes * 60.0:
		_break_timer = 0.0
		break_reminder.emit()

	if _session_timer >= max_session_minutes * 60.0:
		end_session()


func start_session(game_slug: String, child_id: String = "") -> void:
	current_game_slug = game_slug
	current_child_id = child_id
	session_start_time = Time.get_unix_time_from_system()
	score = 0
	correct_answers = 0
	total_questions = 0
	_break_timer = 0.0
	_session_timer = 0.0

	# Create session via API
	var session_data := {
		"child_id": child_id,
		"game_slug": game_slug,
		"difficulty_level": difficulty_level,
	}
	var response = await ApiClient.post("/api/v1/sessions", session_data)
	if response and response.has("id"):
		current_session_id = response["id"]

	session_started.emit(game_slug)


func end_session() -> void:
	if current_session_id.is_empty():
		return

	var duration := Time.get_unix_time_from_system() - session_start_time
	var accuracy := 0.0
	if total_questions > 0:
		accuracy = float(correct_answers) / float(total_questions)

	# Update session via API
	var update_data := {
		"status": "completed",
		"score": score,
		"accuracy": accuracy,
		"duration_seconds": int(duration),
		"difficulty_level": difficulty_level,
		"metrics": {
			"correct_answers": correct_answers,
			"total_questions": total_questions,
		}
	}
	ApiClient.patch("/api/v1/sessions/%s" % current_session_id, update_data)

	session_ended.emit(current_game_slug, score)

	# Adjust difficulty
	if auto_adjust_difficulty:
		_adjust_difficulty(accuracy)

	current_session_id = ""
	current_game_slug = ""


func record_answer(is_correct: bool) -> void:
	total_questions += 1
	if is_correct:
		correct_answers += 1
		score += 10 * difficulty_level


func record_event(event_type: String, data: Dictionary = {}) -> void:
	if current_session_id.is_empty():
		return
	ApiClient.post(
		"/api/v1/sessions/%s/events" % current_session_id,
		{"event_type": event_type, "data": data}
	)


func _adjust_difficulty(accuracy: float) -> void:
	var old_level := difficulty_level
	if accuracy >= 0.85 and difficulty_level < 10:
		difficulty_level += 1
	elif accuracy < 0.5 and difficulty_level > 1:
		difficulty_level -= 1

	if difficulty_level != old_level:
		difficulty_changed.emit(difficulty_level)
