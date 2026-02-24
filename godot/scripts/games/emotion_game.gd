extends Control
## EmotionGame - "Emotion Match" therapy game for emotion recognition training.
## Shows a face/emoji and the child selects the correct emotion label.
## Tracks accuracy per emotion type; difficulty controls number of choices.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var face_label: Label = %FaceLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var feedback_label: Label = %FeedbackLabel
@onready var round_label: Label = %RoundLabel

const EMOTIONS := [
	{"name": "Happy", "emoji": "😊", "similar": ["Excited", "Proud"]},
	{"name": "Sad", "emoji": "😢", "similar": ["Lonely", "Disappointed"]},
	{"name": "Angry", "emoji": "😠", "similar": ["Frustrated", "Annoyed"]},
	{"name": "Surprised", "emoji": "😲", "similar": ["Shocked", "Amazed"]},
	{"name": "Scared", "emoji": "😨", "similar": ["Nervous", "Worried"]},
	{"name": "Confused", "emoji": "😕", "similar": ["Puzzled", "Unsure"]},
	{"name": "Excited", "emoji": "🤩", "similar": ["Happy", "Proud"]},
	{"name": "Proud", "emoji": "😤", "similar": ["Happy", "Confident"]},
	{"name": "Shy", "emoji": "😳", "similar": ["Nervous", "Embarrassed"]},
	{"name": "Tired", "emoji": "😴", "similar": ["Bored", "Sleepy"]},
	{"name": "Silly", "emoji": "🤪", "similar": ["Playful", "Goofy"]},
	{"name": "Loved", "emoji": "🥰", "similar": ["Happy", "Grateful"]},
]

const TOTAL_ROUNDS := 12

var current_round: int = 0
var num_choices: int = 4
var correct_emotion: Dictionary = {}
var waiting_for_input: bool = false
var emotion_accuracy: Dictionary = {}  # Track accuracy per emotion type


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	var level := GameManager.difficulty_level
	if level <= 3:
		num_choices = 2
	elif level <= 6:
		num_choices = 4
	else:
		num_choices = 6


func _start_game() -> void:
	GameManager.start_session("emotion_recognition")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	feedback_label.text = ""
	emotion_accuracy.clear()
	_next_round()


func _next_round() -> void:
	if current_round >= TOTAL_ROUNDS:
		_end_game()
		return

	current_round += 1
	round_label.text = "Round %d / %d" % [current_round, TOTAL_ROUNDS]
	game_hud.update_progress(current_round - 1, TOTAL_ROUNDS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""
	instruction_label.text = "What emotion is this face showing?"

	# Pick a random emotion
	correct_emotion = EMOTIONS[randi() % EMOTIONS.size()]

	# Show the emoji face
	face_label.text = correct_emotion["emoji"]

	# Build choice buttons
	_build_choices()

	waiting_for_input = true

	GameManager.record_event("emotion_shown", {
		"round": current_round,
		"emotion": correct_emotion["name"],
		"num_choices": num_choices,
	})


func _build_choices() -> void:
	# Clear existing choices
	for child in choices_container.get_children():
		child.queue_free()

	# Gather the answer set: correct + distractors
	var answers: Array[String] = [correct_emotion["name"]]

	# For higher difficulty, include similar emotions as distractors
	var pool: Array[String] = []
	if GameManager.difficulty_level >= 5:
		# Use similar emotions for harder distractors
		var similar: Array = correct_emotion["similar"]
		for s in similar:
			if s != correct_emotion["name"] and s not in pool:
				pool.append(s)

	# Fill remaining from all emotion names
	for e in EMOTIONS:
		if e["name"] != correct_emotion["name"] and e["name"] not in pool:
			pool.append(e["name"])

	# Shuffle the pool
	pool.shuffle()

	# Take enough distractors
	var needed := num_choices - 1
	for i in range(mini(needed, pool.size())):
		answers.append(pool[i])

	# Shuffle answers so correct isn't always first
	var shuffled: Array[String] = []
	for a in answers:
		shuffled.append(a)
	shuffled.shuffle()

	# Create buttons in rows of 2
	var row: HBoxContainer = null
	for i in range(shuffled.size()):
		if i % 2 == 0:
			row = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 16)
			choices_container.add_child(row)

		var btn := Button.new()
		btn.text = "  %s  " % shuffled[i]
		btn.custom_minimum_size = Vector2(200, 64)
		btn.add_theme_font_size_override("font_size", 24)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.92, 0.92, 0.96)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.content_margin_left = 16.0
		style.content_margin_right = 16.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		btn.add_theme_stylebox_override("normal", style)

		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.82, 0.86, 0.95)
		hover.corner_radius_top_left = 12
		hover.corner_radius_top_right = 12
		hover.corner_radius_bottom_left = 12
		hover.corner_radius_bottom_right = 12
		hover.content_margin_left = 16.0
		hover.content_margin_right = 16.0
		hover.content_margin_top = 8.0
		hover.content_margin_bottom = 8.0
		btn.add_theme_stylebox_override("hover", hover)

		var answer_text: String = shuffled[i]
		btn.pressed.connect(func():
			_on_choice_selected(answer_text, btn)
		)

		if row:
			row.add_child(btn)


func _on_choice_selected(answer: String, button: Button) -> void:
	if not waiting_for_input:
		return
	waiting_for_input = false

	var is_correct := answer == correct_emotion["name"]
	GameManager.record_answer(is_correct)

	# Track per-emotion accuracy
	var emotion_name: String = correct_emotion["name"]
	if not emotion_accuracy.has(emotion_name):
		emotion_accuracy[emotion_name] = {"correct": 0, "total": 0}
	emotion_accuracy[emotion_name]["total"] += 1
	if is_correct:
		emotion_accuracy[emotion_name]["correct"] += 1

	GameManager.record_event("emotion_answer", {
		"round": current_round,
		"emotion": emotion_name,
		"answer": answer,
		"correct": is_correct,
		"per_emotion_stats": emotion_accuracy,
	})

	_show_feedback(is_correct, button, answer)
	game_hud.update_score(GameManager.score)

	await get_tree().create_timer(1.5).timeout
	_next_round()


func _show_feedback(correct: bool, pressed_button: Button, answer: String) -> void:
	# Disable all choice buttons
	for row in choices_container.get_children():
		if row is HBoxContainer:
			for btn in row.get_children():
				if btn is Button:
					btn.disabled = true

	if correct:
		feedback_label.text = "That is right! It is %s!" % correct_emotion["name"]
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.7, 1.0, 0.7)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		pressed_button.add_theme_stylebox_override("disabled", style)
	else:
		feedback_label.text = "Not quite. The answer is %s." % correct_emotion["name"]
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

		# Mark the pressed button red
		var wrong_style := StyleBoxFlat.new()
		wrong_style.bg_color = Color(1.0, 0.7, 0.7)
		wrong_style.corner_radius_top_left = 12
		wrong_style.corner_radius_top_right = 12
		wrong_style.corner_radius_bottom_left = 12
		wrong_style.corner_radius_bottom_right = 12
		pressed_button.add_theme_stylebox_override("disabled", wrong_style)

		# Highlight the correct answer green
		for row in choices_container.get_children():
			if row is HBoxContainer:
				for btn in row.get_children():
					if btn is Button and btn.text.strip_edges() == correct_emotion["name"]:
						var correct_style := StyleBoxFlat.new()
						correct_style.bg_color = Color(0.7, 1.0, 0.7)
						correct_style.corner_radius_top_left = 12
						correct_style.corner_radius_top_right = 12
						correct_style.corner_radius_bottom_left = 12
						correct_style.corner_radius_bottom_right = 12
						btn.add_theme_stylebox_override("disabled", correct_style)

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)


func _end_game() -> void:
	waiting_for_input = false
	game_hud.stop()

	# Send per-emotion accuracy as final event
	GameManager.record_event("session_summary", {
		"emotion_accuracy": emotion_accuracy,
	})

	GameManager.end_session()

	var accuracy := 0.0
	if GameManager.total_questions > 0:
		accuracy = float(GameManager.correct_answers) / float(GameManager.total_questions)

	reward_popup.show_reward(GameManager.score, accuracy)
	reward_popup.play_again_requested.connect(_on_play_again)
	reward_popup.back_to_menu_requested.connect(_on_back_to_menu)


func _on_play_again() -> void:
	_configure_difficulty()
	_start_game()


func _on_back_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_select.tscn")
