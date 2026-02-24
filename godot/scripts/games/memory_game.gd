extends Control
## MemoryGame - "Sequence Repeat" therapy game for working memory training.
## Shows a sequence of colored buttons that light up; child repeats the pattern.
## Difficulty controls sequence length, speed, and number of buttons.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var buttons_container: GridContainer = %ButtonsGrid
@onready var instruction_label: Label = %InstructionLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var round_label: Label = %RoundLabel

const BUTTON_COLORS := [
	Color(0.90, 0.25, 0.25),  # Red
	Color(0.25, 0.60, 0.90),  # Blue
	Color(0.30, 0.80, 0.30),  # Green
	Color(0.95, 0.80, 0.15),  # Yellow
	Color(0.75, 0.40, 0.85),  # Purple
	Color(0.95, 0.55, 0.20),  # Orange
	Color(0.50, 0.85, 0.85),  # Teal
	Color(0.85, 0.50, 0.70),  # Pink
]

const TOTAL_ROUNDS := 8
const BASE_SEQUENCE_LENGTH := 2
const HIGHLIGHT_DURATION := 0.6
const HIGHLIGHT_PAUSE := 0.3

var current_round: int = 0
var num_buttons: int = 4
var sequence: Array[int] = []
var player_input: Array[int] = []
var accepting_input: bool = false
var showing_sequence: bool = false
var _color_buttons: Array[Button] = []
var _base_styles: Array[StyleBoxFlat] = []
var sequence_speed: float = 1.0


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	var level := GameManager.difficulty_level
	if level <= 3:
		num_buttons = 4
		sequence_speed = 1.0
	elif level <= 6:
		num_buttons = 6
		sequence_speed = 0.8
	else:
		num_buttons = 8
		sequence_speed = 0.6

	# Arrange buttons in a grid
	if num_buttons <= 4:
		buttons_container.columns = 2
	elif num_buttons <= 6:
		buttons_container.columns = 3
	else:
		buttons_container.columns = 4


func _start_game() -> void:
	GameManager.start_session("memory_training")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	feedback_label.text = ""
	_build_buttons()
	_next_round()


func _build_buttons() -> void:
	# Clear existing
	for child in buttons_container.get_children():
		child.queue_free()
	_color_buttons.clear()
	_base_styles.clear()

	for i in range(num_buttons):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(100, 100)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.text = ""

		var base_color: Color = BUTTON_COLORS[i % BUTTON_COLORS.size()]

		var style := StyleBoxFlat.new()
		style.bg_color = base_color.darkened(0.3)
		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 14
		style.corner_radius_bottom_left = 14
		style.corner_radius_bottom_right = 14
		btn.add_theme_stylebox_override("normal", style)

		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = base_color.darkened(0.15)
		hover_style.corner_radius_top_left = 14
		hover_style.corner_radius_top_right = 14
		hover_style.corner_radius_bottom_left = 14
		hover_style.corner_radius_bottom_right = 14
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = base_color
		pressed_style.corner_radius_top_left = 14
		pressed_style.corner_radius_top_right = 14
		pressed_style.corner_radius_bottom_left = 14
		pressed_style.corner_radius_bottom_right = 14
		btn.add_theme_stylebox_override("pressed", pressed_style)

		var index := i
		btn.pressed.connect(func():
			_on_button_pressed(index)
		)

		buttons_container.add_child(btn)
		_color_buttons.append(btn)
		_base_styles.append(style)


func _next_round() -> void:
	if current_round >= TOTAL_ROUNDS:
		_end_game()
		return

	current_round += 1
	round_label.text = "Round %d / %d" % [current_round, TOTAL_ROUNDS]
	game_hud.update_progress(current_round - 1, TOTAL_ROUNDS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""
	instruction_label.text = "Watch the pattern..."
	accepting_input = false
	player_input.clear()

	# Generate sequence
	var seq_length := BASE_SEQUENCE_LENGTH + int(float(current_round - 1) * 0.5)
	# Clamp to reasonable maximum
	seq_length = mini(seq_length, num_buttons + 2)
	sequence.clear()
	for i in range(seq_length):
		sequence.append(randi() % num_buttons)

	GameManager.record_event("sequence_shown", {
		"round": current_round,
		"sequence_length": seq_length,
		"num_buttons": num_buttons,
	})

	# Show the sequence
	await _show_sequence()

	# Now accept input
	instruction_label.text = "Your turn! Repeat the pattern."
	accepting_input = true


func _show_sequence() -> void:
	showing_sequence = true
	_set_buttons_disabled(true)

	await get_tree().create_timer(0.5).timeout

	for idx in sequence:
		_highlight_button(idx)
		await get_tree().create_timer(HIGHLIGHT_DURATION * sequence_speed).timeout
		_unhighlight_button(idx)
		await get_tree().create_timer(HIGHLIGHT_PAUSE * sequence_speed).timeout

	_set_buttons_disabled(false)
	showing_sequence = false


func _highlight_button(index: int) -> void:
	if index < 0 or index >= _color_buttons.size():
		return
	var btn := _color_buttons[index]
	var base_color: Color = BUTTON_COLORS[index % BUTTON_COLORS.size()]

	var lit_style := StyleBoxFlat.new()
	lit_style.bg_color = base_color.lightened(0.3)
	lit_style.corner_radius_top_left = 14
	lit_style.corner_radius_top_right = 14
	lit_style.corner_radius_bottom_left = 14
	lit_style.corner_radius_bottom_right = 14
	lit_style.border_color = Color.WHITE
	lit_style.border_width_top = 3
	lit_style.border_width_bottom = 3
	lit_style.border_width_left = 3
	lit_style.border_width_right = 3
	btn.add_theme_stylebox_override("normal", lit_style)

	if not AccessibilityManager.reduce_motion:
		btn.pivot_offset = btn.size / 2.0
		var tween := create_tween()
		tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)


func _unhighlight_button(index: int) -> void:
	if index < 0 or index >= _color_buttons.size():
		return
	var btn := _color_buttons[index]
	btn.add_theme_stylebox_override("normal", _base_styles[index])

	if not AccessibilityManager.reduce_motion:
		var tween := create_tween()
		tween.tween_property(btn, "scale", Vector2.ONE, 0.1)


func _set_buttons_disabled(disabled: bool) -> void:
	for btn in _color_buttons:
		btn.disabled = disabled


func _on_button_pressed(index: int) -> void:
	if not accepting_input or showing_sequence:
		return

	player_input.append(index)

	# Flash the pressed button
	_highlight_button(index)
	await get_tree().create_timer(0.2).timeout
	_unhighlight_button(index)

	var current_step := player_input.size() - 1

	# Check if the input so far is correct
	if player_input[current_step] != sequence[current_step]:
		# Wrong input
		accepting_input = false
		GameManager.record_answer(false)
		GameManager.record_event("sequence_error", {
			"round": current_round,
			"step": current_step,
			"expected": sequence[current_step],
			"got": index,
		})
		_show_feedback(false)
		await get_tree().create_timer(1.5).timeout
		_next_round()
		return

	# Check if the full sequence has been entered correctly
	if player_input.size() == sequence.size():
		accepting_input = false
		GameManager.record_answer(true)
		GameManager.record_event("sequence_correct", {
			"round": current_round,
			"sequence_length": sequence.size(),
		})
		_show_feedback(true)
		await get_tree().create_timer(1.5).timeout
		_next_round()


func _show_feedback(correct: bool) -> void:
	if correct:
		feedback_label.text = "Perfect!"
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))
	else:
		feedback_label.text = "Not quite - keep trying!"
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)


func _end_game() -> void:
	accepting_input = false
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
	_build_buttons()
	_start_game()


func _on_back_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_select.tscn")
