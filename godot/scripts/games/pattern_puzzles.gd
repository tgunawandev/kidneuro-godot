extends Control
## PatternPuzzles - Pattern recognition and completion game for ASD+ADHD therapy.
## Shows a sequence with a missing element and asks the child to pick the right one.
## Builds cognitive flexibility, sequencing skills, and logical thinking.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var round_label: Label = %RoundLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var pattern_container: HBoxContainer = %PatternContainer
@onready var feedback_label: Label = %FeedbackLabel
@onready var choices_container: HBoxContainer = %ChoicesContainer

const EASY_PATTERNS := [
	{
		"sequence": ["\ud83d\udd34", "\ud83d\udd35", "\ud83d\udd34", "\ud83d\udd35"],
		"answer": "\ud83d\udd34",
		"distractors": ["\ud83d\udd35", "\ud83d\udfe2", "\ud83d\udfe1"],
	},
	{
		"sequence": ["\u2b50", "\u2b50", "\ud83c\udf19", "\u2b50", "\u2b50"],
		"answer": "\ud83c\udf19",
		"distractors": ["\u2b50", "\u2600\ufe0f", "\ud83c\udf1f"],
	},
	{
		"sequence": ["\ud83d\udc31", "\ud83d\udc36", "\ud83d\udc31", "\ud83d\udc36"],
		"answer": "\ud83d\udc31",
		"distractors": ["\ud83d\udc36", "\ud83d\udc30", "\ud83d\udc38"],
	},
	{
		"sequence": ["\ud83d\udfe2", "\ud83d\udfe2", "\ud83d\udfe1", "\ud83d\udfe2", "\ud83d\udfe2"],
		"answer": "\ud83d\udfe1",
		"distractors": ["\ud83d\udfe2", "\ud83d\udd34", "\ud83d\udfe0"],
	},
	{
		"sequence": ["\ud83c\udf4e", "\ud83c\udf4c", "\ud83c\udf4e", "\ud83c\udf4c"],
		"answer": "\ud83c\udf4e",
		"distractors": ["\ud83c\udf4c", "\ud83c\udf47", "\ud83c\udf4a"],
	},
	{
		"sequence": ["\u2764\ufe0f", "\ud83d\udc99", "\u2764\ufe0f", "\ud83d\udc99"],
		"answer": "\u2764\ufe0f",
		"distractors": ["\ud83d\udc99", "\ud83d\udc9a", "\ud83d\udc9b"],
	},
	{
		"sequence": ["\ud83c\udf1e", "\ud83c\udf1d", "\ud83c\udf1e", "\ud83c\udf1d"],
		"answer": "\ud83c\udf1e",
		"distractors": ["\ud83c\udf1d", "\u2b50", "\u2601\ufe0f"],
	},
]

const MEDIUM_PATTERNS := [
	{
		"sequence": ["\ud83d\udd34", "\ud83d\udd35", "\ud83d\udfe2", "\ud83d\udd34", "\ud83d\udd35"],
		"answer": "\ud83d\udfe2",
		"distractors": ["\ud83d\udd34", "\ud83d\udd35", "\ud83d\udfe1"],
	},
	{
		"sequence": ["\u2b06\ufe0f", "\u27a1\ufe0f", "\u2b07\ufe0f", "\u2b05\ufe0f", "\u2b06\ufe0f"],
		"answer": "\u27a1\ufe0f",
		"distractors": ["\u2b07\ufe0f", "\u2b05\ufe0f", "\u2b06\ufe0f"],
	},
	{
		"sequence": ["1\ufe0f\u20e3", "2\ufe0f\u20e3", "3\ufe0f\u20e3", "4\ufe0f\u20e3"],
		"answer": "5\ufe0f\u20e3",
		"distractors": ["6\ufe0f\u20e3", "3\ufe0f\u20e3", "4\ufe0f\u20e3"],
	},
	{
		"sequence": ["\ud83c\udf11", "\ud83c\udf13", "\ud83c\udf15", "\ud83c\udf11", "\ud83c\udf13"],
		"answer": "\ud83c\udf15",
		"distractors": ["\ud83c\udf11", "\ud83c\udf13", "\ud83c\udf18"],
	},
	{
		"sequence": ["\ud83d\udc1c", "\ud83d\udc1c", "\ud83d\udc1d", "\ud83d\udc1c", "\ud83d\udc1c"],
		"answer": "\ud83d\udc1d",
		"distractors": ["\ud83d\udc1c", "\ud83e\udd8b", "\ud83d\udc1e"],
	},
	{
		"sequence": ["\ud83c\udf40", "\ud83c\udf37", "\ud83c\udf3b", "\ud83c\udf40", "\ud83c\udf37"],
		"answer": "\ud83c\udf3b",
		"distractors": ["\ud83c\udf40", "\ud83c\udf37", "\ud83c\udf39"],
	},
	{
		"sequence": ["\ud83d\ude00", "\ud83d\ude22", "\ud83d\ude00", "\ud83d\ude22"],
		"answer": "\ud83d\ude00",
		"distractors": ["\ud83d\ude22", "\ud83d\ude20", "\ud83d\ude32"],
	},
]

const HARD_PATTERNS := [
	{
		"sequence": ["\ud83d\udd35", "\ud83d\udd34", "\ud83d\udd34", "\ud83d\udd35", "\ud83d\udd34", "\ud83d\udd34"],
		"answer": "\ud83d\udd35",
		"distractors": ["\ud83d\udd34", "\ud83d\udfe2", "\ud83d\udfe1"],
	},
	{
		"sequence": ["\u2b50", "\ud83c\udf19", "\u2b50", "\u2b50", "\ud83c\udf19", "\u2b50", "\u2b50", "\u2b50"],
		"answer": "\ud83c\udf19",
		"distractors": ["\u2b50", "\u2600\ufe0f", "\ud83c\udf1f"],
	},
	{
		"sequence": ["\ud83d\udfe2", "\ud83d\udfe1", "\ud83d\udd34", "\ud83d\udfe2", "\ud83d\udfe1"],
		"answer": "\ud83d\udd34",
		"distractors": ["\ud83d\udfe2", "\ud83d\udfe1", "\ud83d\udd35"],
	},
	{
		"sequence": ["\ud83d\udc31", "\ud83d\udc36", "\ud83d\udc26", "\ud83d\udc31", "\ud83d\udc36"],
		"answer": "\ud83d\udc26",
		"distractors": ["\ud83d\udc31", "\ud83d\udc36", "\ud83d\udc30"],
	},
	{
		"sequence": ["\ud83c\udf4e", "\ud83c\udf4a", "\ud83c\udf4b", "\ud83c\udf4e", "\ud83c\udf4a"],
		"answer": "\ud83c\udf4b",
		"distractors": ["\ud83c\udf4e", "\ud83c\udf4a", "\ud83c\udf47"],
	},
	{
		"sequence": ["\u2b06\ufe0f", "\u27a1\ufe0f", "\u2b07\ufe0f", "\u2b05\ufe0f", "\u2b06\ufe0f", "\u27a1\ufe0f", "\u2b07\ufe0f"],
		"answer": "\u2b05\ufe0f",
		"distractors": ["\u2b06\ufe0f", "\u27a1\ufe0f", "\u2b07\ufe0f"],
	},
]

const TOTAL_ROUNDS := 10

var current_round: int = 0
var selected_patterns: Array[Dictionary] = []
var current_pattern: Dictionary = {}
var waiting_for_input: bool = false
var round_start_time: float = 0.0


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	# Difficulty is used to select pattern pools during pattern selection
	pass


func _start_game() -> void:
	GameManager.start_session("pattern_recognition")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	feedback_label.text = ""
	_select_patterns()
	_next_round()


func _select_patterns() -> void:
	selected_patterns.clear()
	var level := GameManager.difficulty_level

	var pool: Array[Dictionary] = []

	if level <= 3:
		# Mostly easy, a few medium
		for p in EASY_PATTERNS:
			pool.append(p)
		for p in MEDIUM_PATTERNS:
			pool.append(p)
	elif level <= 6:
		# Mix of easy, medium, hard
		for p in EASY_PATTERNS:
			pool.append(p)
		for p in MEDIUM_PATTERNS:
			pool.append(p)
		for p in HARD_PATTERNS:
			pool.append(p)
	else:
		# Mostly medium and hard
		for p in MEDIUM_PATTERNS:
			pool.append(p)
		for p in HARD_PATTERNS:
			pool.append(p)
		for p in HARD_PATTERNS:
			pool.append(p)  # Double hard for higher chance

	pool.shuffle()
	for i in range(mini(TOTAL_ROUNDS, pool.size())):
		selected_patterns.append(pool[i])

	# If we need more patterns, repeat from pool
	while selected_patterns.size() < TOTAL_ROUNDS:
		pool.shuffle()
		for p in pool:
			if selected_patterns.size() >= TOTAL_ROUNDS:
				break
			selected_patterns.append(p)


func _next_round() -> void:
	if current_round >= TOTAL_ROUNDS:
		_end_game()
		return

	current_pattern = selected_patterns[current_round]
	current_round += 1
	round_label.text = "Pattern %d / %d" % [current_round, TOTAL_ROUNDS]
	game_hud.update_progress(current_round - 1, TOTAL_ROUNDS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""
	instruction_label.text = "What comes next?"

	_display_pattern()
	_build_choices()

	round_start_time = Time.get_unix_time_from_system()
	waiting_for_input = true

	GameManager.record_event("pattern_shown", {
		"round": current_round,
		"pattern": current_pattern["sequence"],
		"answer": current_pattern["answer"],
	})


func _display_pattern() -> void:
	for child in pattern_container.get_children():
		child.queue_free()

	var sequence: Array = current_pattern["sequence"]
	for item in sequence:
		var lbl := Label.new()
		lbl.text = item
		lbl.add_theme_font_size_override("font_size", 42)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(50, 60)
		pattern_container.add_child(lbl)

	# Add the mystery item
	var mystery := Label.new()
	mystery.text = "\u2753"
	mystery.add_theme_font_size_override("font_size", 42)
	mystery.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mystery.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mystery.custom_minimum_size = Vector2(50, 60)
	mystery.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
	pattern_container.add_child(mystery)


func _build_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()

	# Build the answer set
	var answers: Array[String] = [current_pattern["answer"]]
	var distractors: Array = current_pattern["distractors"]
	for d in distractors:
		if d != current_pattern["answer"] and d not in answers:
			answers.append(d)

	# Limit to 4 choices max
	while answers.size() > 4:
		answers.pop_back()

	# Shuffle
	var shuffled: Array[String] = []
	for a in answers:
		shuffled.append(a)
	shuffled.shuffle()

	for choice in shuffled:
		var btn := Button.new()
		btn.text = choice
		btn.custom_minimum_size = Vector2(90, 90)
		btn.add_theme_font_size_override("font_size", 40)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.92, 0.96, 0.92)
		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 14
		style.corner_radius_bottom_left = 14
		style.corner_radius_bottom_right = 14
		btn.add_theme_stylebox_override("normal", style)

		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.85, 0.92, 0.85)
		hover.corner_radius_top_left = 14
		hover.corner_radius_top_right = 14
		hover.corner_radius_bottom_left = 14
		hover.corner_radius_bottom_right = 14
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

	var reaction_time := Time.get_unix_time_from_system() - round_start_time
	var is_correct := answer == current_pattern["answer"]

	GameManager.record_answer(is_correct)

	GameManager.record_event("pattern_answer", {
		"round": current_round,
		"answer": answer,
		"expected": current_pattern["answer"],
		"correct": is_correct,
		"reaction_time_ms": int(reaction_time * 1000),
	})

	# Disable all choice buttons
	for btn in choices_container.get_children():
		if btn is Button:
			btn.disabled = true

	if is_correct:
		feedback_label.text = "Correct! Great pattern skills!"
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))

		var correct_style := StyleBoxFlat.new()
		correct_style.bg_color = Color(0.7, 1.0, 0.7)
		correct_style.corner_radius_top_left = 14
		correct_style.corner_radius_top_right = 14
		correct_style.corner_radius_bottom_left = 14
		correct_style.corner_radius_bottom_right = 14
		button.add_theme_stylebox_override("disabled", correct_style)

		# Update the mystery item in the pattern to show the answer
		_reveal_answer()
	else:
		feedback_label.text = "Not quite. The answer was %s" % current_pattern["answer"]
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

		var wrong_style := StyleBoxFlat.new()
		wrong_style.bg_color = Color(1.0, 0.7, 0.7)
		wrong_style.corner_radius_top_left = 14
		wrong_style.corner_radius_top_right = 14
		wrong_style.corner_radius_bottom_left = 14
		wrong_style.corner_radius_bottom_right = 14
		button.add_theme_stylebox_override("disabled", wrong_style)

		# Highlight correct answer
		for btn in choices_container.get_children():
			if btn is Button and btn.text == current_pattern["answer"]:
				var hint_style := StyleBoxFlat.new()
				hint_style.bg_color = Color(0.7, 1.0, 0.7)
				hint_style.corner_radius_top_left = 14
				hint_style.corner_radius_top_right = 14
				hint_style.corner_radius_bottom_left = 14
				hint_style.corner_radius_bottom_right = 14
				btn.add_theme_stylebox_override("disabled", hint_style)

		_reveal_answer()

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

	game_hud.update_score(GameManager.score)

	await get_tree().create_timer(1.5).timeout
	_next_round()


func _reveal_answer() -> void:
	# Replace the mystery "?" with the correct answer
	var children := pattern_container.get_children()
	if children.size() > 0:
		var mystery_label: Label = children[children.size() - 1]
		mystery_label.text = current_pattern["answer"]
		mystery_label.remove_theme_color_override("font_color")

		if not AccessibilityManager.reduce_motion:
			mystery_label.modulate.a = 0.5
			var tween := create_tween()
			tween.tween_property(mystery_label, "modulate:a", 1.0, 0.3)


func _end_game() -> void:
	waiting_for_input = false
	game_hud.stop()
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
