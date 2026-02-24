extends Control
## TraceDraw - Connect-the-dots fine motor training game for ASD therapy.
## Shows numbered dots that the child must tap in numerical order to reveal a shape.
## Tracks correct taps, mistakes, and completion time per shape.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var round_label: Label = %RoundLabel
@onready var shape_name_label: Label = %ShapeNameLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var dots_area: Control = %DotsArea

const SHAPES_EASY := [
	{
		"name": "Triangle",
		"dots": [Vector2(200, 20), Vector2(50, 340), Vector2(350, 340)],
	},
	{
		"name": "Square",
		"dots": [Vector2(60, 40), Vector2(340, 40), Vector2(340, 320), Vector2(60, 320)],
	},
	{
		"name": "Diamond",
		"dots": [Vector2(200, 20), Vector2(360, 190), Vector2(200, 360), Vector2(40, 190)],
	},
	{
		"name": "Letter L",
		"dots": [Vector2(80, 30), Vector2(80, 340), Vector2(320, 340)],
	},
]

const SHAPES_MEDIUM := [
	{
		"name": "Star",
		"dots": [Vector2(200, 10), Vector2(260, 140), Vector2(390, 140), Vector2(290, 230), Vector2(320, 360)],
	},
	{
		"name": "Pentagon",
		"dots": [Vector2(200, 20), Vector2(380, 130), Vector2(320, 340), Vector2(80, 340), Vector2(20, 130)],
	},
	{
		"name": "House",
		"dots": [Vector2(200, 20), Vector2(370, 160), Vector2(370, 360), Vector2(30, 360), Vector2(30, 160), Vector2(200, 20)],
	},
	{
		"name": "Heart",
		"dots": [Vector2(200, 360), Vector2(40, 180), Vector2(60, 60), Vector2(150, 20), Vector2(200, 80), Vector2(250, 20)],
	},
]

const SHAPES_HARD := [
	{
		"name": "Octagon",
		"dots": [
			Vector2(140, 20), Vector2(260, 20), Vector2(360, 100), Vector2(360, 240),
			Vector2(260, 340), Vector2(140, 340), Vector2(40, 240), Vector2(40, 100),
		],
	},
	{
		"name": "Butterfly",
		"dots": [
			Vector2(200, 180), Vector2(100, 40), Vector2(30, 100), Vector2(80, 260),
			Vector2(200, 180), Vector2(320, 260), Vector2(370, 100), Vector2(300, 40),
		],
	},
	{
		"name": "Tree",
		"dots": [
			Vector2(200, 10), Vector2(320, 120), Vector2(260, 120), Vector2(340, 230),
			Vector2(240, 230), Vector2(240, 370), Vector2(160, 370),
		],
	},
	{
		"name": "Rocket",
		"dots": [
			Vector2(200, 10), Vector2(280, 100), Vector2(280, 260), Vector2(340, 360),
			Vector2(200, 300), Vector2(60, 360), Vector2(120, 260), Vector2(120, 100),
		],
	},
]

const TOTAL_ROUNDS := 8
const DOT_SIZE := 60

var current_round: int = 0
var current_shape: Dictionary = {}
var shape_pool: Array[Dictionary] = []
var next_dot_index: int = 0
var dot_buttons: Array[Button] = []
var shape_start_time: float = 0.0
var shape_mistakes: int = 0
var waiting_for_input: bool = false
var _connected_lines: Array[Dictionary] = []  # Store connected dot pairs for drawing


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	# Difficulty determines shape pool
	pass


func _build_shape_pool() -> void:
	shape_pool.clear()
	var level := GameManager.difficulty_level

	# Always include easy shapes
	for s in SHAPES_EASY:
		shape_pool.append(s)

	# Add medium shapes for level 4+
	if level >= 4:
		for s in SHAPES_MEDIUM:
			shape_pool.append(s)

	# Add hard shapes for level 7+
	if level >= 7:
		for s in SHAPES_HARD:
			shape_pool.append(s)

	shape_pool.shuffle()


func _start_game() -> void:
	GameManager.start_session("trace_draw")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	feedback_label.text = ""
	_build_shape_pool()
	_next_round()


func _next_round() -> void:
	if current_round >= TOTAL_ROUNDS:
		_end_game()
		return

	# Pick shape (cycle through pool)
	current_shape = shape_pool[current_round % shape_pool.size()]
	current_round += 1
	round_label.text = "Shape %d / %d" % [current_round, TOTAL_ROUNDS]
	game_hud.update_progress(current_round - 1, TOTAL_ROUNDS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""
	shape_name_label.text = "Connect the dots to draw a %s!" % current_shape["name"]

	next_dot_index = 0
	shape_mistakes = 0
	_connected_lines.clear()
	shape_start_time = Time.get_unix_time_from_system()

	_build_dots()
	waiting_for_input = true

	GameManager.record_event("shape_shown", {
		"round": current_round,
		"shape_name": current_shape["name"],
		"num_dots": current_shape["dots"].size(),
	})


func _build_dots() -> void:
	# Clear existing dots
	for child in dots_area.get_children():
		child.queue_free()
	dot_buttons.clear()

	var dots: Array = current_shape["dots"]

	# Calculate offset to center dots in the area
	var area_size := dots_area.size
	if area_size == Vector2.ZERO:
		area_size = Vector2(400, 420)

	# Find bounding box of the dots
	var min_pos := Vector2(9999, 9999)
	var max_pos := Vector2(-9999, -9999)
	for dot_pos in dots:
		var dp: Vector2 = dot_pos
		min_pos.x = minf(min_pos.x, dp.x)
		min_pos.y = minf(min_pos.y, dp.y)
		max_pos.x = maxf(max_pos.x, dp.x)
		max_pos.y = maxf(max_pos.y, dp.y)

	var dots_width := max_pos.x - min_pos.x
	var dots_height := max_pos.y - min_pos.y
	var offset_x := (area_size.x - dots_width) / 2.0 - min_pos.x
	var offset_y := (area_size.y - dots_height) / 2.0 - min_pos.y

	for i in range(dots.size()):
		var dot_pos: Vector2 = dots[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(DOT_SIZE, DOT_SIZE)
		btn.size = Vector2(DOT_SIZE, DOT_SIZE)
		btn.text = str(i + 1)
		btn.add_theme_font_size_override("font_size", 22)
		btn.position = Vector2(
			dot_pos.x + offset_x - DOT_SIZE / 2.0,
			dot_pos.y + offset_y - DOT_SIZE / 2.0
		)

		# Style: circular appearance (high corner radius)
		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 30
		style.corner_radius_top_right = 30
		style.corner_radius_bottom_left = 30
		style.corner_radius_bottom_right = 30

		if i == 0:
			# First dot is highlighted to show where to start
			style.bg_color = Color(0.4, 0.75, 0.95)
			style.border_color = Color(0.2, 0.55, 0.85)
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_width_left = 3
			style.border_width_right = 3
		else:
			style.bg_color = Color(0.88, 0.86, 0.82)
			style.border_color = Color(0.7, 0.68, 0.64)
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.border_width_left = 2
			style.border_width_right = 2
		btn.add_theme_stylebox_override("normal", style)

		var hover := StyleBoxFlat.new()
		hover.bg_color = style.bg_color.lightened(0.15)
		hover.corner_radius_top_left = 30
		hover.corner_radius_top_right = 30
		hover.corner_radius_bottom_left = 30
		hover.corner_radius_bottom_right = 30
		hover.border_color = style.border_color
		hover.border_width_top = 2
		hover.border_width_bottom = 2
		hover.border_width_left = 2
		hover.border_width_right = 2
		btn.add_theme_stylebox_override("hover", hover)

		var dot_index: int = i
		btn.pressed.connect(func():
			_on_dot_tapped(dot_index, btn)
		)

		dots_area.add_child(btn)
		dot_buttons.append(btn)


func _on_dot_tapped(index: int, button: Button) -> void:
	if not waiting_for_input:
		return

	var is_correct := index == next_dot_index

	GameManager.record_event("dot_tapped", {
		"round": current_round,
		"dot_num": index + 1,
		"expected": next_dot_index + 1,
		"correct": is_correct,
		"position": {"x": button.position.x, "y": button.position.y},
	})

	if is_correct:
		# Correct dot tapped!
		_mark_dot_completed(button, index)
		next_dot_index += 1

		# Highlight next dot if exists
		if next_dot_index < dot_buttons.size():
			_highlight_next_dot(dot_buttons[next_dot_index])

		# Check if shape is complete
		if next_dot_index >= current_shape["dots"].size():
			waiting_for_input = false
			var total_time := Time.get_unix_time_from_system() - shape_start_time

			# Record as correct answer
			GameManager.record_answer(true)

			# Bonus points based on mistakes (fewer mistakes = more points)
			if shape_mistakes == 0:
				GameManager.score += 5  # Bonus on top of record_answer

			GameManager.record_event("shape_complete", {
				"round": current_round,
				"shape_name": current_shape["name"],
				"total_time_ms": int(total_time * 1000),
				"mistakes": shape_mistakes,
			})

			feedback_label.text = "Great job! You drew a %s!" % current_shape["name"]
			feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))

			if not AccessibilityManager.reduce_motion:
				feedback_label.modulate.a = 0.0
				var tween := create_tween()
				tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

			game_hud.update_score(GameManager.score)

			await get_tree().create_timer(1.8).timeout
			_next_round()
	else:
		# Wrong dot - brief red flash
		shape_mistakes += 1
		_flash_dot_error(button)


func _mark_dot_completed(button: Button, index: int) -> void:
	var completed_style := StyleBoxFlat.new()
	completed_style.bg_color = Color(0.4, 0.85, 0.4)
	completed_style.corner_radius_top_left = 30
	completed_style.corner_radius_top_right = 30
	completed_style.corner_radius_bottom_left = 30
	completed_style.corner_radius_bottom_right = 30
	completed_style.border_color = Color(0.2, 0.7, 0.2)
	completed_style.border_width_top = 3
	completed_style.border_width_bottom = 3
	completed_style.border_width_left = 3
	completed_style.border_width_right = 3
	button.add_theme_stylebox_override("normal", completed_style)
	button.add_theme_stylebox_override("hover", completed_style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.disabled = true

	# Also set the disabled style so it looks the same
	var disabled_style := completed_style.duplicate()
	button.add_theme_stylebox_override("disabled", disabled_style)

	# Brief scale animation
	if not AccessibilityManager.reduce_motion:
		button.pivot_offset = button.size / 2.0
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(button, "scale", Vector2.ONE, 0.15)

	# Draw connecting line to previous dot if not the first one
	if index > 0:
		_connected_lines.append({"from": index - 1, "to": index})
		dots_area.queue_redraw()


func _highlight_next_dot(button: Button) -> void:
	var highlight_style := StyleBoxFlat.new()
	highlight_style.bg_color = Color(0.4, 0.75, 0.95)
	highlight_style.corner_radius_top_left = 30
	highlight_style.corner_radius_top_right = 30
	highlight_style.corner_radius_bottom_left = 30
	highlight_style.corner_radius_bottom_right = 30
	highlight_style.border_color = Color(0.2, 0.55, 0.85)
	highlight_style.border_width_top = 3
	highlight_style.border_width_bottom = 3
	highlight_style.border_width_left = 3
	highlight_style.border_width_right = 3
	button.add_theme_stylebox_override("normal", highlight_style)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.5, 0.82, 0.97)
	hover.corner_radius_top_left = 30
	hover.corner_radius_top_right = 30
	hover.corner_radius_bottom_left = 30
	hover.corner_radius_bottom_right = 30
	hover.border_color = Color(0.2, 0.55, 0.85)
	hover.border_width_top = 3
	hover.border_width_bottom = 3
	hover.border_width_left = 3
	hover.border_width_right = 3
	button.add_theme_stylebox_override("hover", hover)

	# Pulse animation
	if not AccessibilityManager.reduce_motion:
		button.pivot_offset = button.size / 2.0
		var tween := create_tween().set_loops(3)
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.3)
		tween.tween_property(button, "scale", Vector2.ONE, 0.3)


func _flash_dot_error(button: Button) -> void:
	var original_style: StyleBoxFlat = button.get_theme_stylebox("normal") as StyleBoxFlat
	var error_style := StyleBoxFlat.new()
	error_style.bg_color = Color(0.95, 0.4, 0.4)
	error_style.corner_radius_top_left = 30
	error_style.corner_radius_top_right = 30
	error_style.corner_radius_bottom_left = 30
	error_style.corner_radius_bottom_right = 30
	error_style.border_color = Color(0.8, 0.2, 0.2)
	error_style.border_width_top = 2
	error_style.border_width_bottom = 2
	error_style.border_width_left = 2
	error_style.border_width_right = 2
	button.add_theme_stylebox_override("normal", error_style)

	feedback_label.text = "Not that one! Find dot %d." % (next_dot_index + 1)
	feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.15)

	# Restore after brief flash
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(button) and original_style:
		button.add_theme_stylebox_override("normal", original_style)


func _end_game() -> void:
	waiting_for_input = false
	game_hud.stop()

	GameManager.record_event("session_summary", {
		"total_shapes": TOTAL_ROUNDS,
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
