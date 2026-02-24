extends Control
## TimeTimer - Time perception / time awareness therapy game for ADHD.
## Time blindness is one of the most impactful ADHD symptoms. This game trains
## internal clock awareness through three exercise types:
## Type 1: "How long is X seconds?" - press STOP when target time elapses
## Type 2: "How long does this take?" - pick the right time estimate for an activity
## Type 3: "Which takes longer?" - compare two activities' durations

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var round_label: Label = %RoundLabel
@onready var type_label: Label = %TypeLabel
@onready var emoji_label: Label = %EmojiLabel
@onready var prompt_label: Label = %PromptLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var stop_button: Button = %StopButton
@onready var choices_grid: GridContainer = %ChoicesGrid
@onready var comparison_container: HBoxContainer = %ComparisonContainer

# Type 2 data: time estimation for activities
const ESTIMATION_DATA := [
	{"activity": "Brushing teeth", "emoji": "\ud83e\udea5", "answer": "2 minutes", "options": ["5 seconds", "2 minutes", "1 hour", "1 day"]},
	{"activity": "Watching a movie", "emoji": "\ud83c\udfac", "answer": "2 hours", "options": ["5 minutes", "30 minutes", "2 hours", "2 days"]},
	{"activity": "Cooking dinner", "emoji": "\ud83c\udf73", "answer": "30 minutes", "options": ["1 minute", "30 minutes", "5 hours", "3 days"]},
	{"activity": "Reading a short story", "emoji": "\ud83d\udcd6", "answer": "10 minutes", "options": ["3 seconds", "10 minutes", "3 hours", "1 week"]},
	{"activity": "Writing your name", "emoji": "\u270f\ufe0f", "answer": "10 seconds", "options": ["10 seconds", "10 minutes", "1 hour", "1 day"]},
	{"activity": "Sleeping at night", "emoji": "\ud83d\udecf\ufe0f", "answer": "8 hours", "options": ["20 minutes", "1 hour", "8 hours", "3 days"]},
	{"activity": "A birthday party", "emoji": "\ud83c\udf82", "answer": "2 hours", "options": ["5 minutes", "2 hours", "2 days", "1 month"]},
	{"activity": "Driving to the store", "emoji": "\ud83d\ude97", "answer": "10 minutes", "options": ["2 seconds", "10 minutes", "5 hours", "1 week"]},
]

# Type 3 data: comparison of activity durations
const COMPARISON_DATA := [
	{"a": "\ud83d\udc0c A snail crossing the yard", "b": "\ud83d\udc06 A cheetah running across the yard", "longer": "a"},
	{"a": "\ud83c\udfb5 Listening to one song", "b": "\ud83c\udfb6 Listening to a whole album", "longer": "b"},
	{"a": "\ud83c\udfeb A school day", "b": "\ud83c\udf89 Summer vacation", "longer": "b"},
	{"a": "\u23f0 Waiting 1 minute", "b": "\u23f0 Waiting 1 hour", "longer": "b"},
	{"a": "\ud83e\udd5a Boiling an egg", "b": "\ud83c\udf82 Baking a cake", "longer": "b"},
	{"a": "\ud83d\udeb6 Walking to the mailbox", "b": "\ud83d\udeb6 Walking to school", "longer": "b"},
]

# Exercise types
enum ExerciseType { ESTIMATE_TIME, HOW_LONG_ACTIVITY, WHICH_LONGER }

const TOTAL_ROUNDS := 10

var current_round: int = 0
var exercise_sequence: Array[Dictionary] = []
var current_exercise: Dictionary = {}
var waiting_for_input: bool = false

# Type 1 state
var timer_running: bool = false
var timer_elapsed: float = 0.0
var target_seconds: float = 0.0
var pulse_phase: float = 0.0

# Difficulty settings
var easy_targets := [5, 10]
var medium_targets := [10, 15, 20]
var hard_targets := [15, 20, 25, 30]


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	stop_button.pressed.connect(_on_stop_pressed)

	# Style the stop button (big red)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.85, 0.25, 0.25)
	btn_style.corner_radius_top_left = 20
	btn_style.corner_radius_top_right = 20
	btn_style.corner_radius_bottom_left = 20
	btn_style.corner_radius_bottom_right = 20
	btn_style.content_margin_left = 30.0
	btn_style.content_margin_right = 30.0
	btn_style.content_margin_top = 14.0
	btn_style.content_margin_bottom = 14.0
	stop_button.add_theme_stylebox_override("normal", btn_style)

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.95, 0.3, 0.3)
	btn_hover.corner_radius_top_left = 20
	btn_hover.corner_radius_top_right = 20
	btn_hover.corner_radius_bottom_left = 20
	btn_hover.corner_radius_bottom_right = 20
	btn_hover.content_margin_left = 30.0
	btn_hover.content_margin_right = 30.0
	btn_hover.content_margin_top = 14.0
	btn_hover.content_margin_bottom = 14.0
	stop_button.add_theme_stylebox_override("hover", btn_hover)

	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = Color(0.7, 0.15, 0.15)
	btn_pressed.corner_radius_top_left = 20
	btn_pressed.corner_radius_top_right = 20
	btn_pressed.corner_radius_bottom_left = 20
	btn_pressed.corner_radius_bottom_right = 20
	btn_pressed.content_margin_left = 30.0
	btn_pressed.content_margin_right = 30.0
	btn_pressed.content_margin_top = 14.0
	btn_pressed.content_margin_bottom = 14.0
	stop_button.add_theme_stylebox_override("pressed", btn_pressed)

	stop_button.add_theme_color_override("font_color", Color.WHITE)

	_configure_difficulty()
	_start_game()


func _process(delta: float) -> void:
	if timer_running:
		timer_elapsed += delta

		# Subtle pulse animation on STOP button while waiting
		if not AccessibilityManager.reduce_motion:
			pulse_phase += delta * 2.0
			var pulse_scale := 1.0 + sin(pulse_phase) * 0.03
			stop_button.scale = Vector2(pulse_scale, pulse_scale)
			stop_button.pivot_offset = stop_button.size / 2.0


func _configure_difficulty() -> void:
	var level := GameManager.difficulty_level
	if level <= 3:
		easy_targets = [5, 10]
		medium_targets = [10, 15]
		hard_targets = [15, 20]
	elif level <= 6:
		easy_targets = [10, 15]
		medium_targets = [10, 15, 20]
		hard_targets = [15, 20, 25]
	else:
		easy_targets = [15, 20]
		medium_targets = [15, 20, 25]
		hard_targets = [20, 25, 30]


func _start_game() -> void:
	GameManager.start_session("time_awareness")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	feedback_label.text = ""
	_hide_all_controls()
	_generate_exercise_sequence()
	_next_round()


func _generate_exercise_sequence() -> void:
	exercise_sequence.clear()

	# 4x Type 1, 3x Type 2, 3x Type 3
	var type1_count := 4
	var type2_count := 3
	var type3_count := 3

	# Generate Type 1 exercises
	var level := GameManager.difficulty_level
	var targets: Array
	if level <= 3:
		targets = easy_targets
	elif level <= 6:
		targets = medium_targets
	else:
		targets = hard_targets

	for i in range(type1_count):
		var target_val: int = targets[randi() % targets.size()]
		exercise_sequence.append({
			"type": ExerciseType.ESTIMATE_TIME,
			"target_seconds": target_val,
		})

	# Generate Type 2 exercises
	var estimation_pool: Array[Dictionary] = []
	for e in ESTIMATION_DATA:
		estimation_pool.append(e)
	estimation_pool.shuffle()
	for i in range(mini(type2_count, estimation_pool.size())):
		exercise_sequence.append({
			"type": ExerciseType.HOW_LONG_ACTIVITY,
			"data": estimation_pool[i],
		})

	# Generate Type 3 exercises
	var comparison_pool: Array[Dictionary] = []
	for c in COMPARISON_DATA:
		comparison_pool.append(c)
	comparison_pool.shuffle()
	for i in range(mini(type3_count, comparison_pool.size())):
		exercise_sequence.append({
			"type": ExerciseType.WHICH_LONGER,
			"data": comparison_pool[i],
		})

	# Shuffle the full sequence
	exercise_sequence.shuffle()


func _next_round() -> void:
	if current_round >= TOTAL_ROUNDS:
		_end_game()
		return

	current_exercise = exercise_sequence[current_round]
	current_round += 1
	round_label.text = "Round %d / %d" % [current_round, TOTAL_ROUNDS]
	game_hud.update_progress(current_round - 1, TOTAL_ROUNDS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""
	_hide_all_controls()

	var exercise_type: int = current_exercise["type"]
	match exercise_type:
		ExerciseType.ESTIMATE_TIME:
			_show_time_estimate_exercise()
		ExerciseType.HOW_LONG_ACTIVITY:
			_show_activity_duration_exercise()
		ExerciseType.WHICH_LONGER:
			_show_comparison_exercise()


func _hide_all_controls() -> void:
	stop_button.visible = false
	stop_button.scale = Vector2.ONE
	_clear_grid()
	_clear_comparison()
	type_label.text = ""
	emoji_label.text = ""
	prompt_label.text = ""
	timer_running = false


func _clear_grid() -> void:
	for child in choices_grid.get_children():
		child.queue_free()


func _clear_comparison() -> void:
	for child in comparison_container.get_children():
		child.queue_free()


# --- TYPE 1: Time Estimation (Stop when X seconds passed) ---

func _show_time_estimate_exercise() -> void:
	target_seconds = float(current_exercise["target_seconds"])
	timer_elapsed = 0.0
	pulse_phase = 0.0

	type_label.text = "Feel the Time!"
	emoji_label.text = "\u23f1\ufe0f"
	prompt_label.text = "Press STOP when you think %d seconds have passed" % int(target_seconds)

	stop_button.visible = true
	stop_button.disabled = false
	stop_button.text = "STOP"

	GameManager.record_event("exercise_shown", {
		"type": "estimate_time",
		"target_seconds": int(target_seconds),
	})

	# Brief countdown before starting
	await get_tree().create_timer(0.5).timeout
	prompt_label.text = "Starting now... press STOP when %d seconds pass!" % int(target_seconds)
	timer_running = true
	waiting_for_input = true


func _on_stop_pressed() -> void:
	if not waiting_for_input or not timer_running:
		return
	waiting_for_input = false
	timer_running = false
	stop_button.disabled = true
	stop_button.scale = Vector2.ONE

	var actual := timer_elapsed
	var error := absf(actual - target_seconds)
	var points := 0

	if error <= 1.0:
		points = 15
		feedback_label.text = "Perfect! You stopped at %.1f seconds. The target was %d seconds!" % [actual, int(target_seconds)]
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))
		GameManager.record_answer(true)
	elif error <= 2.0:
		points = 10
		feedback_label.text = "Great! You stopped at %.1f seconds. The target was %d seconds. Only %.1f seconds off!" % [actual, int(target_seconds), error]
		feedback_label.add_theme_color_override("font_color", Color(0.3, 0.65, 0.2))
		GameManager.record_answer(true)
		# Adjust: record_answer gave +10*level, we want 10 base
		# No extra adjustment needed since record_answer gives 10*level and we want that
	elif error <= 3.0:
		points = 5
		feedback_label.text = "Good try! You stopped at %.1f seconds. The target was %d seconds. %.1f seconds off." % [actual, int(target_seconds), error]
		feedback_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.1))
		GameManager.record_answer(true)
		# Adjust: record_answer gave +10*level, we want 5 base
		var adjustment: int = -5 * GameManager.difficulty_level
		GameManager.score = maxi(GameManager.score + adjustment, 0)
	else:
		points = 0
		feedback_label.text = "You stopped at %.1f seconds. The target was %d seconds. You were %.1f seconds off. Keep practicing!" % [actual, int(target_seconds), error]
		feedback_label.add_theme_color_override("font_color", Color(0.7, 0.4, 0.2))
		GameManager.record_answer(false)

	# Show visual bar comparison
	_show_time_comparison_visual(actual, target_seconds)

	GameManager.record_event("time_estimate", {
		"target": int(target_seconds),
		"actual": snapped(actual, 0.1),
		"error_seconds": snapped(error, 0.1),
	})

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

	game_hud.update_score(GameManager.score)

	await get_tree().create_timer(3.0).timeout
	_clear_comparison()
	_next_round()


func _show_time_comparison_visual(actual: float, target: float) -> void:
	_clear_comparison()

	var max_val := maxf(actual, target) * 1.2
	if max_val <= 0:
		max_val = 1.0

	# Target bar
	var target_vbox := VBoxContainer.new()
	target_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_vbox.alignment = BoxContainer.ALIGNMENT_END

	var target_bar_label := Label.new()
	target_bar_label.text = "Target: %ds" % int(target)
	target_bar_label.add_theme_font_size_override("font_size", 14)
	target_bar_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	target_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_vbox.add_child(target_bar_label)

	var target_bar := ColorRect.new()
	var target_ratio := target / max_val
	target_bar.custom_minimum_size = Vector2(80, maxf(target_ratio * 80.0, 10.0))
	target_bar.color = Color(0.4, 0.7, 0.9)
	target_vbox.add_child(target_bar)

	comparison_container.add_child(target_vbox)

	# Actual bar
	var actual_vbox := VBoxContainer.new()
	actual_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actual_vbox.alignment = BoxContainer.ALIGNMENT_END

	var actual_bar_label := Label.new()
	actual_bar_label.text = "You: %.1fs" % actual
	actual_bar_label.add_theme_font_size_override("font_size", 14)
	actual_bar_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	actual_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actual_vbox.add_child(actual_bar_label)

	var actual_bar := ColorRect.new()
	var actual_ratio := actual / max_val
	actual_bar.custom_minimum_size = Vector2(80, maxf(actual_ratio * 80.0, 10.0))
	var error := absf(actual - target)
	if error <= 1.0:
		actual_bar.color = Color(0.4, 0.85, 0.4)
	elif error <= 2.0:
		actual_bar.color = Color(0.7, 0.85, 0.3)
	elif error <= 3.0:
		actual_bar.color = Color(0.9, 0.75, 0.2)
	else:
		actual_bar.color = Color(0.9, 0.45, 0.3)
	actual_vbox.add_child(actual_bar)

	comparison_container.add_child(actual_vbox)


# --- TYPE 2: Activity Duration ("How long does this take?") ---

func _show_activity_duration_exercise() -> void:
	var data: Dictionary = current_exercise["data"]

	type_label.text = "How Long Does This Take?"
	emoji_label.text = data["emoji"]
	prompt_label.text = data["activity"]

	GameManager.record_event("exercise_shown", {
		"type": "how_long_activity",
		"activity": data["activity"],
	})

	# Build option buttons in 2x2 grid
	_clear_grid()
	var options: Array = data["options"]
	var correct_answer: String = data["answer"]

	# Shuffle options
	var shuffled: Array[String] = []
	for o in options:
		shuffled.append(o)
	shuffled.shuffle()

	for option_text in shuffled:
		var btn := Button.new()
		btn.text = option_text
		btn.custom_minimum_size = Vector2(140, 80)
		btn.add_theme_font_size_override("font_size", 18)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.95, 0.93, 0.88)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.content_margin_left = 12.0
		style.content_margin_right = 12.0
		style.content_margin_top = 10.0
		style.content_margin_bottom = 10.0
		btn.add_theme_stylebox_override("normal", style)

		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.9, 0.88, 0.82)
		hover.corner_radius_top_left = 12
		hover.corner_radius_top_right = 12
		hover.corner_radius_bottom_left = 12
		hover.corner_radius_bottom_right = 12
		hover.content_margin_left = 12.0
		hover.content_margin_right = 12.0
		hover.content_margin_top = 10.0
		hover.content_margin_bottom = 10.0
		btn.add_theme_stylebox_override("hover", hover)

		var answer: String = option_text
		btn.pressed.connect(func():
			_on_duration_selected(answer, correct_answer, btn)
		)

		choices_grid.add_child(btn)

	waiting_for_input = true


func _on_duration_selected(answer: String, correct: String, button: Button) -> void:
	if not waiting_for_input:
		return
	waiting_for_input = false

	var is_correct := answer == correct
	GameManager.record_answer(is_correct)

	GameManager.record_event("time_question_answer", {
		"correct": is_correct,
		"question_type": "how_long_activity",
		"answer": answer,
		"expected": correct,
	})

	# Disable all buttons
	for btn in choices_grid.get_children():
		if btn is Button:
			btn.disabled = true

	if is_correct:
		feedback_label.text = "That's right! %s takes about %s." % [current_exercise["data"]["activity"], correct]
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))

		var correct_style := StyleBoxFlat.new()
		correct_style.bg_color = Color(0.7, 1.0, 0.7)
		correct_style.corner_radius_top_left = 12
		correct_style.corner_radius_top_right = 12
		correct_style.corner_radius_bottom_left = 12
		correct_style.corner_radius_bottom_right = 12
		correct_style.content_margin_left = 12.0
		correct_style.content_margin_right = 12.0
		correct_style.content_margin_top = 10.0
		correct_style.content_margin_bottom = 10.0
		button.add_theme_stylebox_override("disabled", correct_style)
	else:
		feedback_label.text = "Not quite! %s takes about %s." % [current_exercise["data"]["activity"], correct]
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

		# Mark pressed button red
		var wrong_style := StyleBoxFlat.new()
		wrong_style.bg_color = Color(1.0, 0.7, 0.7)
		wrong_style.corner_radius_top_left = 12
		wrong_style.corner_radius_top_right = 12
		wrong_style.corner_radius_bottom_left = 12
		wrong_style.corner_radius_bottom_right = 12
		wrong_style.content_margin_left = 12.0
		wrong_style.content_margin_right = 12.0
		wrong_style.content_margin_top = 10.0
		wrong_style.content_margin_bottom = 10.0
		button.add_theme_stylebox_override("disabled", wrong_style)

		# Highlight the correct answer green
		for btn in choices_grid.get_children():
			if btn is Button and btn.text == correct:
				var hint_style := StyleBoxFlat.new()
				hint_style.bg_color = Color(0.7, 1.0, 0.7)
				hint_style.corner_radius_top_left = 12
				hint_style.corner_radius_top_right = 12
				hint_style.corner_radius_bottom_left = 12
				hint_style.corner_radius_bottom_right = 12
				hint_style.content_margin_left = 12.0
				hint_style.content_margin_right = 12.0
				hint_style.content_margin_top = 10.0
				hint_style.content_margin_bottom = 10.0
				btn.add_theme_stylebox_override("disabled", hint_style)

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

	game_hud.update_score(GameManager.score)

	await get_tree().create_timer(2.5).timeout
	_next_round()


# --- TYPE 3: Comparison ("Which takes longer?") ---

func _show_comparison_exercise() -> void:
	var data: Dictionary = current_exercise["data"]

	type_label.text = "Which Takes LONGER?"
	emoji_label.text = "\u2696\ufe0f"
	prompt_label.text = "Tap the activity that takes more time"

	GameManager.record_event("exercise_shown", {
		"type": "which_longer",
		"activity_a": data["a"],
		"activity_b": data["b"],
	})

	# Build two side-by-side activity panels
	_clear_comparison()

	var correct_side: String = data["longer"]

	# Panel A
	var panel_a := _create_comparison_panel(data["a"], "a", correct_side)
	comparison_container.add_child(panel_a)

	# VS label
	var vs_label := Label.new()
	vs_label.text = "VS"
	vs_label.add_theme_font_size_override("font_size", 24)
	vs_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vs_label.custom_minimum_size = Vector2(40, 0)
	comparison_container.add_child(vs_label)

	# Panel B
	var panel_b := _create_comparison_panel(data["b"], "b", correct_side)
	comparison_container.add_child(panel_b)

	waiting_for_input = true


func _create_comparison_panel(activity_text: String, side: String, correct_side: String) -> Button:
	var btn := Button.new()
	btn.text = activity_text
	btn.custom_minimum_size = Vector2(140, 120)
	btn.add_theme_font_size_override("font_size", 16)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.93, 0.88)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.85, 0.83, 0.78)
	btn.add_theme_stylebox_override("normal", style)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.9, 0.88, 0.82)
	hover.corner_radius_top_left = 14
	hover.corner_radius_top_right = 14
	hover.corner_radius_bottom_left = 14
	hover.corner_radius_bottom_right = 14
	hover.content_margin_left = 14.0
	hover.content_margin_right = 14.0
	hover.content_margin_top = 14.0
	hover.content_margin_bottom = 14.0
	hover.border_width_top = 2
	hover.border_width_bottom = 2
	hover.border_width_left = 2
	hover.border_width_right = 2
	hover.border_color = Color(0.7, 0.68, 0.6)
	btn.add_theme_stylebox_override("hover", hover)

	var chosen_side: String = side
	btn.pressed.connect(func():
		_on_comparison_selected(chosen_side, correct_side, btn)
	)

	return btn


func _on_comparison_selected(chosen: String, correct: String, button: Button) -> void:
	if not waiting_for_input:
		return
	waiting_for_input = false

	var is_correct := chosen == correct
	GameManager.record_answer(is_correct)

	var data: Dictionary = current_exercise["data"]
	var correct_activity: String = data[correct]

	GameManager.record_event("time_question_answer", {
		"correct": is_correct,
		"question_type": "which_longer",
		"chosen_side": chosen,
		"correct_side": correct,
	})

	# Disable all comparison buttons
	for child in comparison_container.get_children():
		if child is Button:
			child.disabled = true

	if is_correct:
		feedback_label.text = "Correct! \"%s\" takes longer!" % correct_activity
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))

		var correct_style := StyleBoxFlat.new()
		correct_style.bg_color = Color(0.7, 1.0, 0.7)
		correct_style.corner_radius_top_left = 14
		correct_style.corner_radius_top_right = 14
		correct_style.corner_radius_bottom_left = 14
		correct_style.corner_radius_bottom_right = 14
		correct_style.content_margin_left = 14.0
		correct_style.content_margin_right = 14.0
		correct_style.content_margin_top = 14.0
		correct_style.content_margin_bottom = 14.0
		correct_style.border_width_top = 2
		correct_style.border_width_bottom = 2
		correct_style.border_width_left = 2
		correct_style.border_width_right = 2
		correct_style.border_color = Color(0.4, 0.8, 0.4)
		button.add_theme_stylebox_override("disabled", correct_style)
	else:
		feedback_label.text = "Not quite! \"%s\" actually takes longer." % correct_activity
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

		# Mark pressed button red
		var wrong_style := StyleBoxFlat.new()
		wrong_style.bg_color = Color(1.0, 0.7, 0.7)
		wrong_style.corner_radius_top_left = 14
		wrong_style.corner_radius_top_right = 14
		wrong_style.corner_radius_bottom_left = 14
		wrong_style.corner_radius_bottom_right = 14
		wrong_style.content_margin_left = 14.0
		wrong_style.content_margin_right = 14.0
		wrong_style.content_margin_top = 14.0
		wrong_style.content_margin_bottom = 14.0
		wrong_style.border_width_top = 2
		wrong_style.border_width_bottom = 2
		wrong_style.border_width_left = 2
		wrong_style.border_width_right = 2
		wrong_style.border_color = Color(0.8, 0.4, 0.4)
		button.add_theme_stylebox_override("disabled", wrong_style)

		# Highlight the correct answer green
		var idx := 0
		for child in comparison_container.get_children():
			if child is Button:
				# First button = side a, second button = side b
				var child_side := "a" if idx == 0 else "b"
				if child_side == correct:
					var hint_style := StyleBoxFlat.new()
					hint_style.bg_color = Color(0.7, 1.0, 0.7)
					hint_style.corner_radius_top_left = 14
					hint_style.corner_radius_top_right = 14
					hint_style.corner_radius_bottom_left = 14
					hint_style.corner_radius_bottom_right = 14
					hint_style.content_margin_left = 14.0
					hint_style.content_margin_right = 14.0
					hint_style.content_margin_top = 14.0
					hint_style.content_margin_bottom = 14.0
					hint_style.border_width_top = 2
					hint_style.border_width_bottom = 2
					hint_style.border_width_left = 2
					hint_style.border_width_right = 2
					hint_style.border_color = Color(0.4, 0.8, 0.4)
					child.add_theme_stylebox_override("disabled", hint_style)
				idx += 1

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

	game_hud.update_score(GameManager.score)

	await get_tree().create_timer(2.5).timeout
	_next_round()


# --- End Game ---

func _end_game() -> void:
	waiting_for_input = false
	timer_running = false
	_hide_all_controls()
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
