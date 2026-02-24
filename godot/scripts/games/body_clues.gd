extends Control
## BodyClues - Nonverbal communication / body language reading therapy game for ASD.
## Shows emoji-based character poses with text descriptions and the child must
## identify what the body language means. Teaches reading beyond facial expressions.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var round_label: Label = %RoundLabel
@onready var emoji_label: Label = %EmojiLabel
@onready var pose_label: Label = %PoseLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer

const SCENARIOS := [
	{
		"id": 1,
		"pose": "Arms crossed, looking away",
		"emoji": "\ud83d\ude24",
		"meaning": "Upset or not interested",
		"wrong": ["Happy and excited", "Ready to play", "Feeling sleepy"],
	},
	{
		"id": 2,
		"pose": "Hand raised high, bouncing on toes",
		"emoji": "\ud83d\ude4b",
		"meaning": "Excited and wants to share something",
		"wrong": ["Scared", "Angry", "Tired"],
	},
	{
		"id": 3,
		"pose": "Sitting alone, head down, shoulders drooped",
		"emoji": "\ud83d\ude14",
		"meaning": "Feeling sad or lonely",
		"wrong": ["Playing a game", "Resting happily", "Looking for something"],
	},
	{
		"id": 4,
		"pose": "Arms open wide, big smile, running toward you",
		"emoji": "\ud83e\udd17",
		"meaning": "Happy to see you, wants a hug",
		"wrong": ["Scared of something", "Angry at you", "Needs to sneeze"],
	},
	{
		"id": 5,
		"pose": "Hiding behind hands, peeking through fingers",
		"emoji": "\ud83e\udee3",
		"meaning": "Feeling shy or embarrassed",
		"wrong": ["Playing peek-a-boo", "Angry", "Very happy"],
	},
	{
		"id": 6,
		"pose": "Hands on hips, tapping one foot",
		"emoji": "\ud83d\ude24",
		"meaning": "Impatient or frustrated about waiting",
		"wrong": ["Dancing", "Exercising", "Feeling cold"],
	},
	{
		"id": 7,
		"pose": "Palms up, shoulders raised, head tilted",
		"emoji": "\ud83e\udd37",
		"meaning": "Doesn't know or is confused",
		"wrong": ["Exercising arms", "Feeling scared", "Being silly"],
	},
	{
		"id": 8,
		"pose": "Pointing at something, eyes wide",
		"emoji": "\ud83d\ude32",
		"meaning": "Wants to show you something interesting",
		"wrong": ["Being rude", "Feeling angry", "Doesn't care"],
	},
	{
		"id": 9,
		"pose": "Running away, looking back over shoulder",
		"emoji": "\ud83d\ude28",
		"meaning": "Scared of something",
		"wrong": ["Playing tag just for fun", "Late for school", "Exercise running"],
	},
	{
		"id": 10,
		"pose": "Both hands in the air, jumping up and down",
		"emoji": "\ud83c\udf89",
		"meaning": "Celebrating or very excited",
		"wrong": ["Asking for help", "Feeling scared", "Waving goodbye"],
	},
	{
		"id": 11,
		"pose": "Hands making a heart shape",
		"emoji": "\ud83e\udd70",
		"meaning": "Showing love or saying I love you",
		"wrong": ["Feeling cold", "Being weird", "Stretching hands"],
	},
	{
		"id": 12,
		"pose": "Palm out, arm straight",
		"emoji": "\ud83d\uded1",
		"meaning": "Wants you to stop or wait",
		"wrong": ["Waving hello", "High five", "Feeling tired"],
	},
	{
		"id": 13,
		"pose": "Reaching hand out to shake",
		"emoji": "\ud83e\udd1d",
		"meaning": "Being polite and saying hello or making a deal",
		"wrong": ["Wants food", "Feeling sick", "Being bossy"],
	},
	{
		"id": 14,
		"pose": "Head leaning to the side, eyes half closed",
		"emoji": "\ud83d\ude34",
		"meaning": "Very tired or sleepy",
		"wrong": ["Listening carefully", "Deep in thought", "Looking at something"],
	},
	{
		"id": 15,
		"pose": "Sitting still, eyes closed, hands on knees",
		"emoji": "\ud83e\uddd8",
		"meaning": "Trying to calm down or relax",
		"wrong": ["Sleeping", "Ignoring you", "Being lazy"],
	},
	{
		"id": 16,
		"pose": "Clapping hands together",
		"emoji": "\ud83d\udc4f",
		"meaning": "Showing they liked something or congratulating",
		"wrong": ["Trying to squish a bug", "Angry", "Bored"],
	},
	{
		"id": 17,
		"pose": "Hand over mouth, eyes wide",
		"emoji": "\ud83e\udee2",
		"meaning": "Surprised or said something they shouldn't have",
		"wrong": ["Yawning", "Eating", "Feeling cold"],
	},
	{
		"id": 18,
		"pose": "Arms crossed in X shape, shaking head",
		"emoji": "\ud83d\ude45",
		"meaning": "Saying no or they don't agree",
		"wrong": ["Dancing", "Exercising", "Being silly"],
	},
]

const TOTAL_ROUNDS := 12

# Easy scenarios have more obvious/distinct body language
const EASY_IDS := [2, 3, 4, 7, 9, 10, 14, 16]
# Subtle scenarios require more nuanced interpretation
const SUBTLE_IDS := [1, 5, 6, 8, 11, 12, 13, 15, 17, 18]

var current_round: int = 0
var num_choices: int = 3
var selected_scenarios: Array[Dictionary] = []
var current_scenario: Dictionary = {}
var waiting_for_input: bool = false
var pose_accuracy: Dictionary = {}  # Track accuracy per scenario type


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	var level := GameManager.difficulty_level
	if level <= 3:
		num_choices = 3
	elif level <= 6:
		num_choices = 3
	else:
		num_choices = 4


func _start_game() -> void:
	GameManager.start_session("body_language")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	feedback_label.text = ""
	pose_accuracy.clear()
	_select_scenarios()
	_next_round()


func _select_scenarios() -> void:
	selected_scenarios.clear()
	var level := GameManager.difficulty_level

	var pool: Array[Dictionary] = []

	if level <= 3:
		# Prefer easy scenarios with obvious body language
		for s in SCENARIOS:
			if s["id"] in EASY_IDS:
				pool.append(s)
		for s in SCENARIOS:
			if s["id"] in SUBTLE_IDS and pool.size() < TOTAL_ROUNDS + 5:
				pool.append(s)
	elif level <= 6:
		# Mix of easy and subtle
		for s in SCENARIOS:
			pool.append(s)
	else:
		# Prefer subtle/nuanced body language
		for s in SCENARIOS:
			if s["id"] in SUBTLE_IDS:
				pool.append(s)
		for s in SCENARIOS:
			if s["id"] in EASY_IDS and pool.size() < TOTAL_ROUNDS + 5:
				pool.append(s)

	pool.shuffle()
	for i in range(mini(TOTAL_ROUNDS, pool.size())):
		selected_scenarios.append(pool[i])

	# Ensure we have enough rounds
	while selected_scenarios.size() < TOTAL_ROUNDS:
		pool.shuffle()
		for p in pool:
			if selected_scenarios.size() >= TOTAL_ROUNDS:
				break
			selected_scenarios.append(p)


func _next_round() -> void:
	if current_round >= TOTAL_ROUNDS:
		_end_game()
		return

	current_scenario = selected_scenarios[current_round]
	current_round += 1
	round_label.text = "Round %d / %d" % [current_round, TOTAL_ROUNDS]
	game_hud.update_progress(current_round - 1, TOTAL_ROUNDS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""
	instruction_label.text = "What does this body language mean?"

	# Show the emoji for the pose
	emoji_label.text = current_scenario["emoji"]

	# Show the pose description in italics-style text
	pose_label.text = current_scenario["pose"]

	# Build choice buttons
	_build_choices()

	waiting_for_input = true

	GameManager.record_event("pose_shown", {
		"round": current_round,
		"pose": current_scenario["pose"],
		"meaning": current_scenario["meaning"],
		"scenario_id": current_scenario["id"],
	})


func _build_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()

	# Build answer set: correct + wrong answers
	var answers: Array[String] = [current_scenario["meaning"]]
	var wrong: Array = current_scenario["wrong"]

	# For higher difficulty, include more similar distractors
	var level := GameManager.difficulty_level
	if level >= 7:
		# Use all wrong answers (up to num_choices - 1)
		for w in wrong:
			if answers.size() < num_choices:
				answers.append(w)
	elif level >= 4:
		# Use up to num_choices - 1 wrong answers, prefer first ones (more plausible)
		for w in wrong:
			if answers.size() < num_choices:
				answers.append(w)
	else:
		# Easy: use the most obviously different wrong answers
		# Take from the end of the wrong list (least similar)
		var reversed_wrong: Array = wrong.duplicate()
		reversed_wrong.reverse()
		for w in reversed_wrong:
			if answers.size() < num_choices:
				answers.append(w)

	# Trim to num_choices if needed
	while answers.size() > num_choices:
		answers.pop_back()

	# Shuffle so correct answer is not always first
	var shuffled: Array[String] = []
	for a in answers:
		shuffled.append(a)
	shuffled.shuffle()

	for choice in shuffled:
		var btn := Button.new()
		btn.text = choice
		btn.custom_minimum_size = Vector2(300, 60)
		btn.add_theme_font_size_override("font_size", 20)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.96, 0.94, 0.90)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.content_margin_left = 16.0
		style.content_margin_right = 16.0
		style.content_margin_top = 10.0
		style.content_margin_bottom = 10.0
		btn.add_theme_stylebox_override("normal", style)

		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.92, 0.88, 0.82)
		hover.corner_radius_top_left = 12
		hover.corner_radius_top_right = 12
		hover.corner_radius_bottom_left = 12
		hover.corner_radius_bottom_right = 12
		hover.content_margin_left = 16.0
		hover.content_margin_right = 16.0
		hover.content_margin_top = 10.0
		hover.content_margin_bottom = 10.0
		btn.add_theme_stylebox_override("hover", hover)

		var answer_text: String = choice
		btn.pressed.connect(func():
			_on_choice_selected(answer_text, btn)
		)

		choices_container.add_child(btn)


func _on_choice_selected(answer: String, button: Button) -> void:
	if not waiting_for_input:
		return
	waiting_for_input = false

	var is_correct := answer == current_scenario["meaning"]
	GameManager.record_answer(is_correct)

	# Track per-pose accuracy
	var scenario_id: int = current_scenario["id"]
	var id_key := str(scenario_id)
	if not pose_accuracy.has(id_key):
		pose_accuracy[id_key] = {"correct": 0, "total": 0, "pose": current_scenario["pose"]}
	pose_accuracy[id_key]["total"] += 1
	if is_correct:
		pose_accuracy[id_key]["correct"] += 1

	GameManager.record_event("pose_answer", {
		"round": current_round,
		"correct": is_correct,
		"chosen": answer,
		"expected": current_scenario["meaning"],
		"scenario_id": scenario_id,
	})

	_show_feedback(is_correct, button)
	game_hud.update_score(GameManager.score)

	await get_tree().create_timer(2.0).timeout
	_next_round()


func _show_feedback(correct: bool, pressed_button: Button) -> void:
	# Disable all choice buttons
	for btn in choices_container.get_children():
		if btn is Button:
			btn.disabled = true

	if correct:
		feedback_label.text = "That's right! %s" % current_scenario["meaning"]
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.3))

		var correct_style := StyleBoxFlat.new()
		correct_style.bg_color = Color(0.7, 1.0, 0.7)
		correct_style.corner_radius_top_left = 12
		correct_style.corner_radius_top_right = 12
		correct_style.corner_radius_bottom_left = 12
		correct_style.corner_radius_bottom_right = 12
		correct_style.content_margin_left = 16.0
		correct_style.content_margin_right = 16.0
		correct_style.content_margin_top = 10.0
		correct_style.content_margin_bottom = 10.0
		pressed_button.add_theme_stylebox_override("disabled", correct_style)
	else:
		feedback_label.text = "Not quite. The answer is: %s" % current_scenario["meaning"]
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

		# Mark the pressed button red
		var wrong_style := StyleBoxFlat.new()
		wrong_style.bg_color = Color(1.0, 0.7, 0.7)
		wrong_style.corner_radius_top_left = 12
		wrong_style.corner_radius_top_right = 12
		wrong_style.corner_radius_bottom_left = 12
		wrong_style.corner_radius_bottom_right = 12
		wrong_style.content_margin_left = 16.0
		wrong_style.content_margin_right = 16.0
		wrong_style.content_margin_top = 10.0
		wrong_style.content_margin_bottom = 10.0
		pressed_button.add_theme_stylebox_override("disabled", wrong_style)

		# Highlight the correct answer green
		for btn in choices_container.get_children():
			if btn is Button and btn.text == current_scenario["meaning"]:
				var hint_style := StyleBoxFlat.new()
				hint_style.bg_color = Color(0.7, 1.0, 0.7)
				hint_style.corner_radius_top_left = 12
				hint_style.corner_radius_top_right = 12
				hint_style.corner_radius_bottom_left = 12
				hint_style.corner_radius_bottom_right = 12
				hint_style.content_margin_left = 16.0
				hint_style.content_margin_right = 16.0
				hint_style.content_margin_top = 10.0
				hint_style.content_margin_bottom = 10.0
				btn.add_theme_stylebox_override("disabled", hint_style)

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)


func _end_game() -> void:
	waiting_for_input = false
	game_hud.stop()

	# Send per-pose accuracy as final event
	GameManager.record_event("session_summary", {
		"pose_accuracy": pose_accuracy,
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
