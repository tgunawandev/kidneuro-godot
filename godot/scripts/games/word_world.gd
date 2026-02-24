extends Control
## WordWorld - Vocabulary and word-picture matching game for communication therapy.
## Alternates between two modes: emoji→word and word→emoji matching.
## Difficulty controls number of choices and word complexity.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var round_label: Label = %RoundLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var prompt_display: Label = %PromptDisplay
@onready var feedback_label: Label = %FeedbackLabel
@onready var choices_grid: GridContainer = %ChoicesGrid

const WORDS_EASY := [
	{"word": "Dog", "emoji": "🐶"},
	{"word": "Cat", "emoji": "🐱"},
	{"word": "Fish", "emoji": "🐟"},
	{"word": "Bird", "emoji": "🐦"},
	{"word": "Sun", "emoji": "☀️"},
	{"word": "Moon", "emoji": "🌙"},
	{"word": "Tree", "emoji": "🌳"},
	{"word": "Flower", "emoji": "🌸"},
	{"word": "Apple", "emoji": "🍎"},
	{"word": "Star", "emoji": "⭐"},
]

const WORDS_MEDIUM := [
	{"word": "Butterfly", "emoji": "🦋"},
	{"word": "Rainbow", "emoji": "🌈"},
	{"word": "Umbrella", "emoji": "☂️"},
	{"word": "Rocket", "emoji": "🚀"},
	{"word": "Castle", "emoji": "🏰"},
	{"word": "Guitar", "emoji": "🎸"},
	{"word": "Telescope", "emoji": "🔭"},
	{"word": "Diamond", "emoji": "💎"},
]

const WORDS_HARD := [
	{"word": "Volcano", "emoji": "🌋"},
	{"word": "Microscope", "emoji": "🔬"},
	{"word": "Constellation", "emoji": "✨"},
	{"word": "Helicopter", "emoji": "🚁"},
	{"word": "Stethoscope", "emoji": "🩺"},
	{"word": "Compass", "emoji": "🧭"},
]

const TOTAL_ROUNDS := 12

enum Mode { EMOJI_TO_WORD, WORD_TO_EMOJI }

var current_round: int = 0
var num_choices: int = 4
var current_mode: Mode = Mode.EMOJI_TO_WORD
var correct_item: Dictionary = {}
var waiting_for_input: bool = false
var round_start_time: float = 0.0
var word_pool: Array[Dictionary] = []


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	var level := GameManager.difficulty_level
	if level <= 3:
		num_choices = 2
		choices_grid.columns = 2
	elif level <= 6:
		num_choices = 4
		choices_grid.columns = 2
	else:
		num_choices = 6
		choices_grid.columns = 3


func _build_word_pool() -> void:
	word_pool.clear()
	var level := GameManager.difficulty_level

	# Always include easy words
	for w in WORDS_EASY:
		word_pool.append(w)

	# Add medium words for level 4+
	if level >= 4:
		for w in WORDS_MEDIUM:
			word_pool.append(w)

	# Add hard words for level 7+
	if level >= 7:
		for w in WORDS_HARD:
			word_pool.append(w)


func _start_game() -> void:
	GameManager.start_session("word_world")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	feedback_label.text = ""
	_build_word_pool()
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

	# Alternate between modes
	if current_round % 2 == 1:
		current_mode = Mode.EMOJI_TO_WORD
	else:
		current_mode = Mode.WORD_TO_EMOJI

	# Pick a random correct item
	correct_item = word_pool[randi() % word_pool.size()]

	# Set up display based on mode
	if current_mode == Mode.EMOJI_TO_WORD:
		prompt_display.text = correct_item["emoji"]
		prompt_display.add_theme_font_size_override("font_size", 80)
		instruction_label.text = "What is this called?"
	else:
		prompt_display.text = correct_item["word"]
		prompt_display.add_theme_font_size_override("font_size", 36)
		instruction_label.text = "Which picture shows this word?"

	# Build choices
	_build_choices()

	round_start_time = Time.get_unix_time_from_system()
	waiting_for_input = true

	GameManager.record_event("word_shown", {
		"round": current_round,
		"word": correct_item["word"],
		"emoji": correct_item["emoji"],
		"mode": "emoji_to_word" if current_mode == Mode.EMOJI_TO_WORD else "word_to_emoji",
		"difficulty": GameManager.difficulty_level,
		"num_choices": num_choices,
	})


func _build_choices() -> void:
	# Clear existing choices
	for child in choices_grid.get_children():
		child.queue_free()

	# Build answer set: correct + distractors
	var distractors: Array[Dictionary] = []
	var pool_copy: Array[Dictionary] = []
	for w in word_pool:
		if w["word"] != correct_item["word"]:
			pool_copy.append(w)
	pool_copy.shuffle()

	var needed := num_choices - 1
	for i in range(mini(needed, pool_copy.size())):
		distractors.append(pool_copy[i])

	# Combine and shuffle
	var all_items: Array[Dictionary] = [correct_item]
	for d in distractors:
		all_items.append(d)
	all_items.shuffle()

	# Create buttons
	for item in all_items:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(140, 80)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL

		if current_mode == Mode.EMOJI_TO_WORD:
			# Show word text as choices
			btn.text = "  %s  " % item["word"]
			btn.add_theme_font_size_override("font_size", 24)
		else:
			# Show emoji as choices
			btn.text = item["emoji"]
			btn.add_theme_font_size_override("font_size", 42)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.92, 0.93, 0.98)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.content_margin_left = 12.0
		style.content_margin_right = 12.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		btn.add_theme_stylebox_override("normal", style)

		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.84, 0.88, 0.96)
		hover.corner_radius_top_left = 12
		hover.corner_radius_top_right = 12
		hover.corner_radius_bottom_left = 12
		hover.corner_radius_bottom_right = 12
		hover.content_margin_left = 12.0
		hover.content_margin_right = 12.0
		hover.content_margin_top = 8.0
		hover.content_margin_bottom = 8.0
		btn.add_theme_stylebox_override("hover", hover)

		var choice_item: Dictionary = item
		btn.pressed.connect(func():
			_on_choice_selected(choice_item, btn)
		)

		choices_grid.add_child(btn)


func _on_choice_selected(item: Dictionary, button: Button) -> void:
	if not waiting_for_input:
		return
	waiting_for_input = false

	var reaction_time := Time.get_unix_time_from_system() - round_start_time
	var is_correct := item["word"] == correct_item["word"]

	GameManager.record_answer(is_correct)

	GameManager.record_event("word_answer", {
		"round": current_round,
		"word": correct_item["word"],
		"selected": item["word"],
		"correct": is_correct,
		"reaction_time_ms": int(reaction_time * 1000),
		"mode": "emoji_to_word" if current_mode == Mode.EMOJI_TO_WORD else "word_to_emoji",
	})

	_show_feedback(is_correct, button)
	game_hud.update_score(GameManager.score)

	await get_tree().create_timer(1.5).timeout
	_next_round()


func _show_feedback(correct: bool, pressed_button: Button) -> void:
	# Disable all choice buttons
	for child in choices_grid.get_children():
		if child is Button:
			child.disabled = true

	if correct:
		feedback_label.text = "Correct! That's %s %s!" % [correct_item["emoji"], correct_item["word"]]
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.7, 1.0, 0.7)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		pressed_button.add_theme_stylebox_override("disabled", style)
	else:
		var correct_display: String
		if current_mode == Mode.EMOJI_TO_WORD:
			correct_display = correct_item["word"]
		else:
			correct_display = correct_item["emoji"]
		feedback_label.text = "Not quite. The answer is %s." % correct_display
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

		# Mark pressed button red
		var wrong_style := StyleBoxFlat.new()
		wrong_style.bg_color = Color(1.0, 0.7, 0.7)
		wrong_style.corner_radius_top_left = 12
		wrong_style.corner_radius_top_right = 12
		wrong_style.corner_radius_bottom_left = 12
		wrong_style.corner_radius_bottom_right = 12
		pressed_button.add_theme_stylebox_override("disabled", wrong_style)

		# Highlight the correct answer green
		for child in choices_grid.get_children():
			if child is Button:
				# Determine if this button represents the correct item
				var btn_text: String = child.text.strip_edges()
				var is_correct_btn := false
				if current_mode == Mode.EMOJI_TO_WORD:
					is_correct_btn = btn_text == correct_item["word"]
				else:
					is_correct_btn = btn_text == correct_item["emoji"]

				if is_correct_btn:
					var correct_style := StyleBoxFlat.new()
					correct_style.bg_color = Color(0.7, 1.0, 0.7)
					correct_style.corner_radius_top_left = 12
					correct_style.corner_radius_top_right = 12
					correct_style.corner_radius_bottom_left = 12
					correct_style.corner_radius_bottom_right = 12
					child.add_theme_stylebox_override("disabled", correct_style)
					break

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)


func _end_game() -> void:
	waiting_for_input = false
	game_hud.stop()

	GameManager.record_event("session_summary", {
		"total_rounds": TOTAL_ROUNDS,
		"difficulty": GameManager.difficulty_level,
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
