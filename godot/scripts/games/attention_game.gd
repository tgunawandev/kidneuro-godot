extends Control
## AttentionGame - "Find the Object" therapy game for attention/focus training.
## Child must find and tap the matching target object in a grid of shapes.
## Tracks reaction time, accuracy, and adapts difficulty via GameManager.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var target_container: HBoxContainer = %TargetContainer
@onready var target_label: Label = %TargetLabel
@onready var target_display: Label = %TargetDisplay
@onready var grid_container: GridContainer = %ObjectGrid
@onready var feedback_label: Label = %FeedbackLabel
@onready var round_label: Label = %RoundLabel

const SHAPES := ["●", "■", "▲", "◆", "★", "♥", "♦", "♣", "♠", "▼", "◀", "▶"]
const SHAPE_COLORS := [
	Color(0.90, 0.30, 0.30),  # Red
	Color(0.30, 0.70, 0.90),  # Blue
	Color(0.40, 0.80, 0.40),  # Green
	Color(0.90, 0.75, 0.20),  # Yellow
	Color(0.75, 0.45, 0.85),  # Purple
	Color(0.95, 0.55, 0.25),  # Orange
	Color(0.50, 0.85, 0.85),  # Teal
	Color(0.85, 0.50, 0.65),  # Pink
]

const TOTAL_ROUNDS := 10

var current_round: int = 0
var target_shape: String = ""
var target_color: Color = Color.WHITE
var grid_size: int = 4
var round_start_time: float = 0.0
var waiting_for_input: bool = false


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	var level := GameManager.difficulty_level
	if level <= 3:
		grid_size = 4
	elif level <= 6:
		grid_size = 5
	else:
		grid_size = 6
	grid_container.columns = grid_size


func _start_game() -> void:
	GameManager.start_session("attention_training")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	feedback_label.text = ""
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

	# Choose a random target shape and color
	target_shape = SHAPES[randi() % SHAPES.size()]
	target_color = SHAPE_COLORS[randi() % SHAPE_COLORS.size()]

	# Display the target
	target_display.text = target_shape
	target_display.add_theme_color_override("font_color", target_color)

	# Build the grid
	_build_grid()

	round_start_time = Time.get_unix_time_from_system()
	waiting_for_input = true

	GameManager.record_event("round_start", {
		"round": current_round,
		"target_shape": target_shape,
		"grid_size": grid_size,
	})


func _build_grid() -> void:
	# Clear previous grid
	for child in grid_container.get_children():
		child.queue_free()

	var total_cells := grid_size * grid_size
	var target_position := randi() % total_cells

	for i in range(total_cells):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.add_theme_font_size_override("font_size", 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.95, 0.95, 0.97)
		btn_style.corner_radius_top_left = 10
		btn_style.corner_radius_top_right = 10
		btn_style.corner_radius_bottom_left = 10
		btn_style.corner_radius_bottom_right = 10
		btn.add_theme_stylebox_override("normal", btn_style)

		var btn_hover := StyleBoxFlat.new()
		btn_hover.bg_color = Color(0.88, 0.92, 1.0)
		btn_hover.corner_radius_top_left = 10
		btn_hover.corner_radius_top_right = 10
		btn_hover.corner_radius_bottom_left = 10
		btn_hover.corner_radius_bottom_right = 10
		btn.add_theme_stylebox_override("hover", btn_hover)

		if i == target_position:
			# This is the correct target
			btn.text = target_shape
			btn.add_theme_color_override("font_color", target_color)
			btn.pressed.connect(_on_object_tapped.bind(true, btn))
		else:
			# Distractor: different shape or color
			var distractor_shape := _pick_distractor_shape()
			var distractor_color := _pick_distractor_color()
			btn.text = distractor_shape
			btn.add_theme_color_override("font_color", distractor_color)
			btn.pressed.connect(_on_object_tapped.bind(false, btn))

		grid_container.add_child(btn)


func _pick_distractor_shape() -> String:
	var shape := SHAPES[randi() % SHAPES.size()]
	# For lower difficulty, use very different shapes
	# For higher difficulty, sometimes use the same shape with different color
	if GameManager.difficulty_level >= 5 and randf() < 0.3:
		return target_shape  # Same shape, will have different color
	while shape == target_shape:
		shape = SHAPES[randi() % SHAPES.size()]
	return shape


func _pick_distractor_color() -> Color:
	var color := SHAPE_COLORS[randi() % SHAPE_COLORS.size()]
	# For higher difficulty, sometimes use the same color with different shape
	if GameManager.difficulty_level >= 5 and randf() < 0.3:
		return target_color
	while color == target_color:
		color = SHAPE_COLORS[randi() % SHAPE_COLORS.size()]
	return color


func _on_object_tapped(is_correct: bool, button: Button) -> void:
	if not waiting_for_input:
		return
	waiting_for_input = false

	var reaction_time := Time.get_unix_time_from_system() - round_start_time

	GameManager.record_answer(is_correct)
	GameManager.record_event("object_tapped", {
		"round": current_round,
		"correct": is_correct,
		"reaction_time_ms": int(reaction_time * 1000),
	})

	if is_correct:
		_show_feedback(true, button)
	else:
		_show_feedback(false, button)

	game_hud.update_score(GameManager.score)

	# Wait before next round
	await get_tree().create_timer(1.2).timeout
	_next_round()


func _show_feedback(correct: bool, button: Button) -> void:
	if correct:
		feedback_label.text = "Correct!"
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.7, 1.0, 0.7)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		button.add_theme_stylebox_override("normal", style)
	else:
		feedback_label.text = "Try again next time!"
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

		var style := StyleBoxFlat.new()
		style.bg_color = Color(1.0, 0.7, 0.7)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		button.add_theme_stylebox_override("normal", style)

		# Highlight correct answer
		for child in grid_container.get_children():
			if child is Button and child.text == target_shape:
				var c: Color = Color.TRANSPARENT
				if child.has_theme_color_override("font_color"):
					c = child.get_theme_color("font_color")
				if c == target_color:
					var correct_style := StyleBoxFlat.new()
					correct_style.bg_color = Color(0.7, 1.0, 0.7)
					correct_style.corner_radius_top_left = 10
					correct_style.corner_radius_top_right = 10
					correct_style.corner_radius_bottom_left = 10
					correct_style.corner_radius_bottom_right = 10
					child.add_theme_stylebox_override("normal", correct_style)
					break

	# Animate feedback
	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)


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
