extends Control
## RoutineBuilder - Daily routine sequencing game for ASD+ADHD therapy.
## Child taps scrambled routine steps in the correct order to build daily routines.
## Teaches morning, bedtime, getting ready, school, and mealtime sequences.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var round_label: Label = %RoundLabel
@onready var routine_title: Label = %RoutineTitle
@onready var instruction_label: Label = %InstructionLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var steps_container: VBoxContainer = %StepsContainer

const ROUTINES := [
	{
		"name": "Morning Routine",
		"steps": [
			{"emoji": "\ud83c\udf05", "text": "Wake up"},
			{"emoji": "\ud83e\udea5", "text": "Brush teeth"},
			{"emoji": "\ud83d\udc55", "text": "Get dressed"},
			{"emoji": "\ud83e\udd63", "text": "Eat breakfast"},
			{"emoji": "\ud83c\udf92", "text": "Pack backpack"},
			{"emoji": "\ud83d\ude8c", "text": "Go to school"},
		],
	},
	{
		"name": "Bedtime Routine",
		"steps": [
			{"emoji": "\ud83d\udec1", "text": "Take a bath"},
			{"emoji": "\ud83e\udea5", "text": "Brush teeth"},
			{"emoji": "\ud83d\udcda", "text": "Read a story"},
			{"emoji": "\ud83e\uddf8", "text": "Get in bed"},
			{"emoji": "\ud83d\udca4", "text": "Close eyes and sleep"},
		],
	},
	{
		"name": "Getting Ready",
		"steps": [
			{"emoji": "\ud83e\udde6", "text": "Put on socks"},
			{"emoji": "\ud83d\udc5f", "text": "Put on shoes"},
			{"emoji": "\ud83e\udde5", "text": "Put on jacket"},
			{"emoji": "\ud83c\udf92", "text": "Grab backpack"},
			{"emoji": "\ud83d\udeaa", "text": "Go outside"},
		],
	},
	{
		"name": "School Time",
		"steps": [
			{"emoji": "\ud83d\udcd6", "text": "Open your book"},
			{"emoji": "\u270f\ufe0f", "text": "Write your name"},
			{"emoji": "\ud83d\udc42", "text": "Listen to teacher"},
			{"emoji": "\u270b", "text": "Raise hand to answer"},
			{"emoji": "\ud83d\udcdd", "text": "Do your worksheet"},
			{"emoji": "\ud83d\udd14", "text": "Pack up when bell rings"},
		],
	},
	{
		"name": "Mealtime",
		"steps": [
			{"emoji": "\ud83e\uddfc", "text": "Wash hands"},
			{"emoji": "\ud83c\udf7d\ufe0f", "text": "Set the table"},
			{"emoji": "\ud83e\udd44", "text": "Eat your food"},
			{"emoji": "\ud83e\uddf9", "text": "Clean up"},
			{"emoji": "\ud83d\ude4f", "text": "Say thank you"},
		],
	},
]

const TOTAL_ROUNDS := 6

var current_round: int = 0
var selected_routines: Array[Dictionary] = []
var current_routine: Dictionary = {}
var current_steps: Array[Dictionary] = []
var next_expected_step: int = 0
var step_buttons: Array[Button] = []
var show_hints: bool = true
var max_steps_shown: int = 5
var attempts_this_step: int = 0
var waiting_for_input: bool = false


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	var level := GameManager.difficulty_level
	if level <= 3:
		max_steps_shown = 3
		show_hints = true
	elif level <= 6:
		max_steps_shown = 5
		show_hints = false
	else:
		max_steps_shown = 7
		show_hints = false


func _start_game() -> void:
	GameManager.start_session("routine_building")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	feedback_label.text = ""
	_select_routines()
	_next_round()


func _select_routines() -> void:
	selected_routines.clear()
	# Pick routines ensuring variety - 2 from each category where possible
	var pool: Array[Dictionary] = []
	for r in ROUTINES:
		pool.append(r)
		pool.append(r)  # Add each twice for potential repeat
	pool.shuffle()

	for i in range(mini(TOTAL_ROUNDS, pool.size())):
		selected_routines.append(pool[i])


func _next_round() -> void:
	if current_round >= TOTAL_ROUNDS:
		_end_game()
		return

	current_routine = selected_routines[current_round]
	current_round += 1
	round_label.text = "Routine %d / %d" % [current_round, TOTAL_ROUNDS]
	game_hud.update_progress(current_round - 1, TOTAL_ROUNDS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""

	routine_title.text = current_routine["name"]
	instruction_label.text = "Tap the steps in the right order!"

	# Get steps and limit by difficulty
	var all_steps: Array = current_routine["steps"]
	current_steps.clear()
	for i in range(mini(max_steps_shown, all_steps.size())):
		current_steps.append(all_steps[i])

	next_expected_step = 0
	attempts_this_step = 0

	_build_step_buttons()

	waiting_for_input = true

	GameManager.record_event("routine_shown", {
		"routine_name": current_routine["name"],
		"num_steps": current_steps.size(),
	})


func _build_step_buttons() -> void:
	for child in steps_container.get_children():
		child.queue_free()
	step_buttons.clear()

	# Create a shuffled order for display
	var indices: Array[int] = []
	for i in range(current_steps.size()):
		indices.append(i)
	indices.shuffle()

	for display_idx in range(indices.size()):
		var step_idx: int = indices[display_idx]
		var step: Dictionary = current_steps[step_idx]

		var btn := Button.new()
		var btn_text: String = "%s  %s" % [step["emoji"], step["text"]]
		if show_hints:
			# Show hint numbers for easy mode
			btn_text = "%s  %s" % [step["emoji"], step["text"]]
		btn.text = btn_text
		btn.custom_minimum_size = Vector2(0, 64)
		btn.add_theme_font_size_override("font_size", 20)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.96, 0.94, 0.90)
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
		hover.bg_color = Color(0.92, 0.90, 0.86)
		hover.corner_radius_top_left = 12
		hover.corner_radius_top_right = 12
		hover.corner_radius_bottom_left = 12
		hover.corner_radius_bottom_right = 12
		hover.content_margin_left = 16.0
		hover.content_margin_right = 16.0
		hover.content_margin_top = 8.0
		hover.content_margin_bottom = 8.0
		btn.add_theme_stylebox_override("hover", hover)

		var captured_idx: int = step_idx
		btn.pressed.connect(func():
			_on_step_tapped(captured_idx, btn)
		)

		steps_container.add_child(btn)
		step_buttons.append(btn)


func _on_step_tapped(step_idx: int, button: Button) -> void:
	if not waiting_for_input:
		return

	attempts_this_step += 1
	var is_correct := step_idx == next_expected_step

	GameManager.record_event("step_selected", {
		"step": current_steps[step_idx]["text"],
		"position": step_idx,
		"expected": next_expected_step,
		"correct": is_correct,
		"attempts": attempts_this_step,
	})

	if is_correct:
		# Mark as correct
		var correct_style := StyleBoxFlat.new()
		correct_style.bg_color = Color(0.7, 0.95, 0.7)
		correct_style.corner_radius_top_left = 12
		correct_style.corner_radius_top_right = 12
		correct_style.corner_radius_bottom_left = 12
		correct_style.corner_radius_bottom_right = 12
		correct_style.content_margin_left = 16.0
		correct_style.content_margin_right = 16.0
		correct_style.content_margin_top = 8.0
		correct_style.content_margin_bottom = 8.0
		button.add_theme_stylebox_override("normal", correct_style)
		button.add_theme_stylebox_override("hover", correct_style)
		button.add_theme_stylebox_override("disabled", correct_style)
		button.disabled = true

		# Show the sequence number
		var step: Dictionary = current_steps[step_idx]
		button.text = "%d.  %s  %s" % [next_expected_step + 1, step["emoji"], step["text"]]

		feedback_label.text = "Correct! Step %d done!" % (next_expected_step + 1)
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.3))

		next_expected_step += 1
		attempts_this_step = 0

		if not AccessibilityManager.reduce_motion:
			feedback_label.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

		# Check if routine is complete
		if next_expected_step >= current_steps.size():
			waiting_for_input = false
			GameManager.record_answer(true)
			feedback_label.text = "You completed the routine!"
			feedback_label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.3))
			game_hud.update_score(GameManager.score)

			await get_tree().create_timer(1.5).timeout
			_next_round()
	else:
		# Wrong step - flash red briefly
		feedback_label.text = "Not quite! Think about what comes next."
		feedback_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))

		var wrong_style := StyleBoxFlat.new()
		wrong_style.bg_color = Color(1.0, 0.8, 0.8)
		wrong_style.corner_radius_top_left = 12
		wrong_style.corner_radius_top_right = 12
		wrong_style.corner_radius_bottom_left = 12
		wrong_style.corner_radius_bottom_right = 12
		wrong_style.content_margin_left = 16.0
		wrong_style.content_margin_right = 16.0
		wrong_style.content_margin_top = 8.0
		wrong_style.content_margin_bottom = 8.0
		button.add_theme_stylebox_override("normal", wrong_style)

		if not AccessibilityManager.reduce_motion:
			feedback_label.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

		# Reset button style after a moment
		await get_tree().create_timer(0.8).timeout
		if is_instance_valid(button) and not button.disabled:
			var normal_style := StyleBoxFlat.new()
			normal_style.bg_color = Color(0.96, 0.94, 0.90)
			normal_style.corner_radius_top_left = 12
			normal_style.corner_radius_top_right = 12
			normal_style.corner_radius_bottom_left = 12
			normal_style.corner_radius_bottom_right = 12
			normal_style.content_margin_left = 16.0
			normal_style.content_margin_right = 16.0
			normal_style.content_margin_top = 8.0
			normal_style.content_margin_bottom = 8.0
			button.add_theme_stylebox_override("normal", normal_style)

		# If too many attempts on one step, mark routine as failed and move on
		if attempts_this_step >= 3:
			waiting_for_input = false
			GameManager.record_answer(false)
			feedback_label.text = "Let's try another routine!"
			feedback_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.3))

			# Highlight the correct next step
			_highlight_correct_step()

			game_hud.update_score(GameManager.score)
			await get_tree().create_timer(2.0).timeout
			_next_round()


func _highlight_correct_step() -> void:
	# Find and highlight the button for the expected step
	var expected_step: Dictionary = current_steps[next_expected_step]
	var expected_text: String = expected_step["text"]

	for btn in step_buttons:
		if is_instance_valid(btn) and not btn.disabled:
			if btn.text.find(expected_text) >= 0:
				var hint_style := StyleBoxFlat.new()
				hint_style.bg_color = Color(0.7, 0.95, 0.7)
				hint_style.corner_radius_top_left = 12
				hint_style.corner_radius_top_right = 12
				hint_style.corner_radius_bottom_left = 12
				hint_style.corner_radius_bottom_right = 12
				hint_style.content_margin_left = 16.0
				hint_style.content_margin_right = 16.0
				hint_style.content_margin_top = 8.0
				hint_style.content_margin_bottom = 8.0
				btn.add_theme_stylebox_override("normal", hint_style)
				break


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
