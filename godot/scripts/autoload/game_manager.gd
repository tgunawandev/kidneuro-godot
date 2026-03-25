extends Node
## GameManager - Global game state and session management.
## Autoloaded singleton managing child profiles, game sessions, difficulty,
## and real-time behavior-based game adaptations.

signal session_started(game_slug: String)
signal session_ended(game_slug: String, score: int)
signal difficulty_changed(new_level: int)
signal break_reminder()
signal calming_overlay_requested()
signal presence_prompt_requested()

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

# --- Behavior adaptation state ---
var _behavior_visual_intensity: float = 1.0  # 0.0 - 1.0 (1.0 = full intensity)
var _behavior_audio_volume_db: float = 0.0   # Adjustment in dB
var _behavior_animation_speed: float = 1.0   # Multiplier
var _behavior_game_paused: bool = false
var _calming_active: bool = false
var _presence_prompt_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Connect to behavior events from ApiClient
	if ApiClient.behavior_event_received.is_connected(_on_behavior_event):
		return
	ApiClient.behavior_event_received.connect(_on_behavior_event)


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

	# Reset behavior adaptation state
	_reset_behavior_adaptations()

	# Create session via API
	var session_data := {
		"child_id": child_id,
		"game_slug": game_slug,
		"difficulty_level": difficulty_level,
	}
	var response = await ApiClient.post("/api/v1/sessions", session_data)
	if response and response.has("id"):
		current_session_id = response["id"]

	# Connect to behavior WebSocket for this child
	if not child_id.is_empty():
		ApiClient.connect_behavior_ws(child_id)

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

	# Disconnect behavior WebSocket
	ApiClient.disconnect_behavior_ws()

	session_ended.emit(current_game_slug, score)

	# Adjust difficulty
	if auto_adjust_difficulty:
		_adjust_difficulty(accuracy)

	# Reset behavior state
	_reset_behavior_adaptations()

	current_session_id = ""
	current_game_slug = ""
	current_child_id = ""


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


# =============================================================================
# Behavior Adaptation
# =============================================================================

func _on_behavior_event(event_data: Dictionary) -> void:
	"""Handle real-time behavior events from the Savant video pipeline.

	Adapts the game environment based on detected child behaviors:
	- Repetitive motion: reduce stimulation (visuals, audio, animation speed)
	- High activity: pause and show calming overlay
	- Low presence: pause and prompt for re-engagement
	"""
	var event_type: String = event_data.get("event_type", "")
	var severity: String = event_data.get("severity", "info")
	var confidence: float = event_data.get("confidence", 0.0)

	# Only act on events with reasonable confidence
	if confidence < 0.5:
		return

	# Log the event for session analytics
	record_event("behavior_detected", {
		"behavior_type": event_type,
		"severity": severity,
		"confidence": confidence,
	})

	match event_type:
		"repetitive_motion_detected", "repetitive_motion":
			_handle_repetitive_motion(severity, confidence)
		"high_activity_level", "high_activity":
			_handle_high_activity(severity, confidence)
		"low_presence", "absence_detected":
			_handle_low_presence(severity, confidence)
		_:
			print("[GameManager] Unhandled behavior event: %s" % event_type)


func _handle_repetitive_motion(severity: String, confidence: float) -> void:
	"""Reduce sensory stimulation when repetitive motion is detected.

	- Reduce visual intensity (lower contrast/brightness)
	- Lower audio volume by 20%
	- Slow animation speed to 80%
	"""
	print("[GameManager] Repetitive motion detected (severity=%s, conf=%.2f)" % [severity, confidence])

	# Scale reduction by severity
	var intensity_reduction := 0.1
	var audio_reduction_db := -2.0
	var anim_speed_factor := 0.9

	if severity == "moderate":
		intensity_reduction = 0.2
		audio_reduction_db = -4.0
		anim_speed_factor = 0.8
	elif severity == "high" or severity == "severe":
		intensity_reduction = 0.3
		audio_reduction_db = -6.0
		anim_speed_factor = 0.7

	# Apply visual intensity reduction
	_behavior_visual_intensity = clampf(_behavior_visual_intensity - intensity_reduction, 0.3, 1.0)
	_apply_visual_intensity(_behavior_visual_intensity)

	# Lower audio volume by ~20% (approx -2 to -6 dB depending on severity)
	_behavior_audio_volume_db = clampf(_behavior_audio_volume_db + audio_reduction_db, -12.0, 0.0)
	_apply_audio_volume(_behavior_audio_volume_db)

	# Slow animation speed
	_behavior_animation_speed = clampf(_behavior_animation_speed * anim_speed_factor, 0.3, 1.0)
	_apply_animation_speed(_behavior_animation_speed)


func _handle_high_activity(severity: String, _confidence: float) -> void:
	"""Pause game briefly and show calming overlay when high activity detected."""
	if _calming_active:
		return  # Already showing calming overlay

	print("[GameManager] High activity level detected (severity=%s)" % severity)

	_calming_active = true
	_behavior_game_paused = true
	get_tree().paused = true

	# Emit signal so UI can display calming overlay
	calming_overlay_requested.emit()

	# Record the pause event
	record_event("calming_pause_triggered", {"severity": severity})

	# Auto-resume after a brief calming period (5 seconds)
	await get_tree().create_timer(5.0).timeout
	_resume_from_calming()


func _handle_low_presence(_severity: String, _confidence: float) -> void:
	"""Pause game and show 'Are you there?' prompt when child is not detected."""
	if _presence_prompt_active:
		return  # Already showing prompt

	print("[GameManager] Low presence detected - showing engagement prompt")

	_presence_prompt_active = true
	_behavior_game_paused = true
	get_tree().paused = true

	# Emit signal so UI can display "Are you there?" prompt
	presence_prompt_requested.emit()

	# Record the event
	record_event("presence_prompt_shown", {})


func resume_from_presence_prompt() -> void:
	"""Called by UI when child acknowledges the presence prompt."""
	if not _presence_prompt_active:
		return

	_presence_prompt_active = false
	_behavior_game_paused = false
	get_tree().paused = false
	record_event("presence_prompt_acknowledged", {})
	print("[GameManager] Resumed from presence prompt")


func _resume_from_calming() -> void:
	"""Resume game after calming overlay period."""
	if not _calming_active:
		return

	_calming_active = false
	_behavior_game_paused = false
	get_tree().paused = false
	print("[GameManager] Resumed from calming pause")


func _apply_visual_intensity(intensity: float) -> void:
	"""Apply visual intensity adjustment to the game viewport.

	Adjusts environment brightness/modulate. Games can override this
	by connecting to the tree's root viewport.
	"""
	var root := get_tree().root
	if root:
		# Modulate the viewport canvas to reduce visual intensity
		# White (1,1,1) = full intensity, darker = reduced
		var gray := intensity
		root.canvas_transform = root.canvas_transform  # Force refresh
		# Apply via CanvasModulate if available, otherwise use world environment
		var modulate_nodes := get_tree().get_nodes_in_group("canvas_modulate")
		if modulate_nodes.size() > 0:
			for node in modulate_nodes:
				if node is CanvasModulate:
					node.color = Color(gray, gray, gray, 1.0)


func _apply_audio_volume(volume_db_adjustment: float) -> void:
	"""Apply audio volume adjustment to the master bus."""
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		var base_volume := 0.0  # 0 dB = normal
		AudioServer.set_bus_volume_db(bus_idx, base_volume + volume_db_adjustment)


func _apply_animation_speed(speed_scale: float) -> void:
	"""Apply animation speed adjustment to all AnimationPlayer nodes."""
	var anim_players := get_tree().get_nodes_in_group("game_animations")
	for player in anim_players:
		if player is AnimationPlayer:
			player.speed_scale = speed_scale

	# Also adjust Engine time scale as a fallback for physics-based animations
	Engine.time_scale = clampf(speed_scale, 0.5, 1.0)


func _reset_behavior_adaptations() -> void:
	"""Reset all behavior-driven adaptations to defaults."""
	_behavior_visual_intensity = 1.0
	_behavior_audio_volume_db = 0.0
	_behavior_animation_speed = 1.0
	_behavior_game_paused = false
	_calming_active = false
	_presence_prompt_active = false

	# Restore defaults
	_apply_visual_intensity(1.0)
	_apply_audio_volume(0.0)
	_apply_animation_speed(1.0)
	Engine.time_scale = 1.0

	if get_tree():
		get_tree().paused = false


# =============================================================================
# Behavior state getters (for UI/game scenes to query)
# =============================================================================

func get_visual_intensity() -> float:
	return _behavior_visual_intensity


func get_animation_speed() -> float:
	return _behavior_animation_speed


func is_behavior_paused() -> bool:
	return _behavior_game_paused


func _adjust_difficulty(accuracy: float) -> void:
	var old_level := difficulty_level
	if accuracy >= 0.85 and difficulty_level < 10:
		difficulty_level += 1
	elif accuracy < 0.5 and difficulty_level > 1:
		difficulty_level -= 1

	if difficulty_level != old_level:
		difficulty_changed.emit(difficulty_level)
