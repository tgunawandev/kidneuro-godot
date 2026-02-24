extends Control
## FocusFilter - Selective attention / CPT-based therapy game for ADHD.
## Items appear one at a time in a display area. The child must tap only items
## matching the target rule (e.g. "Tap the BLUE STARS!") and ignore distractors.
## Tracks hits, misses, false alarms, correct rejections, and reaction time.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var item_count_label: Label = %ItemCountLabel
@onready var rule_panel: PanelContainer = %RulePanel
@onready var rule_label: Label = %RuleLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var stats_label: Label = %StatsLabel
@onready var display_area: Control = %DisplayArea

# Shape definitions: display text and name
const SHAPES := [
	{"name": "Star", "symbol": "\u2b50"},
	{"name": "Circle", "symbol": "\u25cf"},
	{"name": "Square", "symbol": "\u25a0"},
	{"name": "Triangle", "symbol": "\u25b2"},
	{"name": "Heart", "symbol": "\u2665"},
	{"name": "Diamond", "symbol": "\u25c6"},
]

# Color definitions: name and Color value
const COLORS := [
	{"name": "Blue", "color": Color(0.2, 0.5, 0.9)},
	{"name": "Red", "color": Color(0.9, 0.25, 0.25)},
	{"name": "Green", "color": Color(0.2, 0.75, 0.3)},
	{"name": "Yellow", "color": Color(0.9, 0.8, 0.1)},
	{"name": "Purple", "color": Color(0.65, 0.3, 0.85)},
	{"name": "Orange", "color": Color(0.95, 0.55, 0.15)},
]

# Target rules (predefined combinations)
const TARGET_RULES := [
	{"color_name": "Blue", "shape_name": "Star"},
	{"color_name": "Red", "shape_name": "Heart"},
	{"color_name": "Green", "shape_name": "Circle"},
	{"color_name": "Yellow", "shape_name": "Square"},
	{"color_name": "Purple", "shape_name": "Triangle"},
]

const TOTAL_ITEMS := 30

# Difficulty settings
var display_duration: float = 2.5  # How long each item stays visible
var pause_duration: float = 1.0    # Pause between items
var target_ratio: float = 0.30     # Percentage of items that are targets

# Current target rule
var target_color_name: String = ""
var target_color: Color = Color.WHITE
var target_shape_name: String = ""
var target_shape_symbol: String = ""

# Session state
var item_list: Array[Dictionary] = []
var current_item_index: int = 0
var current_item_button: Button = null
var item_was_tapped: bool = false
var item_show_time: float = 0.0
var is_running: bool = false

# Tracking stats
var hits: int = 0
var misses: int = 0
var false_alarms: int = 0
var correct_rejections: int = 0
var reaction_times: Array[float] = []


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	_style_rule_panel()
	_configure_difficulty()
	_start_game()


func _style_rule_panel() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.45, 0.75, 0.9)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.content_margin_left = 16.0
	panel_style.content_margin_right = 16.0
	panel_style.content_margin_top = 8.0
	panel_style.content_margin_bottom = 8.0
	rule_panel.add_theme_stylebox_override("panel", panel_style)


func _configure_difficulty() -> void:
	var level := GameManager.difficulty_level
	if level <= 3:
		display_duration = 2.5
		pause_duration = 1.0
		target_ratio = 0.30
	elif level <= 6:
		display_duration = 1.8
		pause_duration = 0.7
		target_ratio = 0.35
	else:
		display_duration = 1.2
		pause_duration = 0.5
		target_ratio = 0.40


func _start_game() -> void:
	GameManager.start_session("selective_attention")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ITEMS)
	current_item_index = 0
	hits = 0
	misses = 0
	false_alarms = 0
	correct_rejections = 0
	reaction_times.clear()
	feedback_label.text = ""
	stats_label.text = ""
	is_running = false

	# Pick a random target rule
	_select_target_rule()

	# Generate the item list
	_generate_items()

	# Start showing items
	_run_trial_sequence()


func _select_target_rule() -> void:
	var rule: Dictionary = TARGET_RULES[randi() % TARGET_RULES.size()]
	target_color_name = rule["color_name"]
	target_shape_name = rule["shape_name"]

	# Resolve color value
	for c in COLORS:
		if c["name"] == target_color_name:
			target_color = c["color"]
			break

	# Resolve shape symbol
	for s in SHAPES:
		if s["name"] == target_shape_name:
			target_shape_symbol = s["symbol"]
			break

	# Update rule display
	rule_label.text = "Tap the %s %sS! %s" % [target_color_name.to_upper(), target_shape_name.to_upper(), target_shape_symbol]


func _generate_items() -> void:
	item_list.clear()
	var level := GameManager.difficulty_level

	# Determine item counts
	var num_targets := int(TOTAL_ITEMS * target_ratio)
	var num_same_color := int(TOTAL_ITEMS * 0.20)
	var num_same_shape := int(TOTAL_ITEMS * 0.20)
	var num_different := TOTAL_ITEMS - num_targets - num_same_color - num_same_shape

	# Ensure non-negative
	if num_different < 0:
		num_different = 0
		num_same_color = int((TOTAL_ITEMS - num_targets) / 2)
		num_same_shape = TOTAL_ITEMS - num_targets - num_same_color

	# Generate targets (correct color + correct shape)
	for i in range(num_targets):
		item_list.append({
			"color_name": target_color_name,
			"color": target_color,
			"shape_name": target_shape_name,
			"symbol": target_shape_symbol,
			"is_target": true,
			"item_type": "target",
		})

	# Generate same-color distractors (correct color, wrong shape)
	for i in range(num_same_color):
		var shape: Dictionary = _pick_random_shape_except(target_shape_name)
		item_list.append({
			"color_name": target_color_name,
			"color": target_color,
			"shape_name": shape["name"],
			"symbol": shape["symbol"],
			"is_target": false,
			"item_type": "same_color",
		})

	# Generate same-shape distractors (wrong color, correct shape)
	for i in range(num_same_shape):
		var col: Dictionary = _pick_random_color_except(target_color_name)
		item_list.append({
			"color_name": col["name"],
			"color": col["color"],
			"shape_name": target_shape_name,
			"symbol": target_shape_symbol,
			"is_target": false,
			"item_type": "same_shape",
		})

	# Generate totally different distractors
	for i in range(num_different):
		var shape: Dictionary = _pick_random_shape_except(target_shape_name)
		var col: Dictionary = _pick_random_color_except(target_color_name)
		item_list.append({
			"color_name": col["name"],
			"color": col["color"],
			"shape_name": shape["name"],
			"symbol": shape["symbol"],
			"is_target": false,
			"item_type": "different",
		})

	# Shuffle the item list
	item_list.shuffle()


func _pick_random_shape_except(exclude_name: String) -> Dictionary:
	var options: Array[Dictionary] = []
	for s in SHAPES:
		if s["name"] != exclude_name:
			options.append(s)
	return options[randi() % options.size()]


func _pick_random_color_except(exclude_name: String) -> Dictionary:
	var options: Array[Dictionary] = []
	for c in COLORS:
		if c["name"] != exclude_name:
			options.append(c)
	return options[randi() % options.size()]


func _run_trial_sequence() -> void:
	is_running = true

	while current_item_index < TOTAL_ITEMS and is_running:
		var item: Dictionary = item_list[current_item_index]

		item_count_label.text = "Item %d / %d" % [current_item_index + 1, TOTAL_ITEMS]
		game_hud.update_progress(current_item_index, TOTAL_ITEMS)
		game_hud.update_score(GameManager.score)
		feedback_label.text = ""

		# Show the item
		_show_item(item)

		GameManager.record_event("item_shown", {
			"shape": item["shape_name"],
			"color": item["color_name"],
			"is_target": item["is_target"],
			"item_index": current_item_index,
			"item_type": item["item_type"],
		})

		# Wait for display duration or tap
		item_was_tapped = false
		item_show_time = Time.get_unix_time_from_system()

		await get_tree().create_timer(display_duration).timeout

		# Process the result if item wasn't already tapped
		if not item_was_tapped:
			_process_timeout(item)

		# Remove the item button
		_clear_display()

		# Update stats display
		_update_stats_display()

		current_item_index += 1

		# Brief pause between items
		if current_item_index < TOTAL_ITEMS and is_running:
			await get_tree().create_timer(pause_duration).timeout

	if is_running:
		_end_game()


func _show_item(item: Dictionary) -> void:
	_clear_display()

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(100, 100)
	btn.add_theme_font_size_override("font_size", 56)
	btn.add_theme_color_override("font_color", item["color"])
	btn.text = item["symbol"]

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.95)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal", style)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.93, 0.95, 1.0, 0.95)
	hover.corner_radius_top_left = 16
	hover.corner_radius_top_right = 16
	hover.corner_radius_bottom_left = 16
	hover.corner_radius_bottom_right = 16
	hover.content_margin_left = 12.0
	hover.content_margin_right = 12.0
	hover.content_margin_top = 8.0
	hover.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("hover", hover)

	# Place at random position within display area
	var area_size := display_area.size
	var margin := 60.0  # Keep away from edges
	var x := randf_range(margin, maxf(area_size.x - 100.0 - margin, margin + 1.0))
	var y := randf_range(margin, maxf(area_size.y - 100.0 - margin, margin + 1.0))
	btn.position = Vector2(x, y)

	var item_ref: Dictionary = item_list[current_item_index]
	btn.pressed.connect(func():
		_on_item_tapped(item_ref)
	)

	display_area.add_child(btn)
	current_item_button = btn

	# Entrance animation
	if not AccessibilityManager.reduce_motion:
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.5, 0.5)
		btn.pivot_offset = Vector2(50, 50)
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(btn, "modulate:a", 1.0, 0.15)
		tween.parallel().tween_property(btn, "scale", Vector2.ONE, 0.2)


func _on_item_tapped(item: Dictionary) -> void:
	if item_was_tapped:
		return
	item_was_tapped = true

	var reaction_time := Time.get_unix_time_from_system() - item_show_time
	var reaction_time_ms := int(reaction_time * 1000)

	if item["is_target"]:
		# Hit - correctly tapped target
		hits += 1
		reaction_times.append(reaction_time)
		GameManager.record_answer(true)
		_add_score(10)
		_show_item_feedback(true, "Hit!")

		GameManager.record_event("item_response", {
			"tapped": true,
			"correct": true,
			"reaction_time_ms": reaction_time_ms,
			"item_type": item["item_type"],
			"item_index": current_item_index,
		})
	else:
		# False alarm - tapped a distractor
		false_alarms += 1
		GameManager.record_answer(false)
		_add_score(-5)
		_show_item_feedback(false, "Oops! Not a target")

		GameManager.record_event("item_response", {
			"tapped": true,
			"correct": false,
			"reaction_time_ms": reaction_time_ms,
			"item_type": item["item_type"],
			"item_index": current_item_index,
		})


func _process_timeout(item: Dictionary) -> void:
	if item["is_target"]:
		# Miss - target was not tapped
		misses += 1
		GameManager.record_answer(false)
		_show_item_feedback(false, "Missed a target!")

		GameManager.record_event("item_response", {
			"tapped": false,
			"correct": false,
			"reaction_time_ms": -1,
			"item_type": item["item_type"],
			"item_index": current_item_index,
		})
	else:
		# Correct rejection - distractor was correctly ignored
		correct_rejections += 1
		# Only score for partial-match distractors (same color or same shape)
		if item["item_type"] == "same_color" or item["item_type"] == "same_shape":
			GameManager.record_answer(true)
			_add_score(5)
		# No feedback needed for correct rejections

		GameManager.record_event("item_response", {
			"tapped": false,
			"correct": true,
			"reaction_time_ms": -1,
			"item_type": item["item_type"],
			"item_index": current_item_index,
		})


func _add_score(points: int) -> void:
	GameManager.score += points
	if GameManager.score < 0:
		GameManager.score = 0
	game_hud.update_score(GameManager.score)


func _show_item_feedback(positive: bool, message: String) -> void:
	feedback_label.text = message
	if positive:
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.3))
	else:
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

	# Flash the item button
	if current_item_button and is_instance_valid(current_item_button):
		var flash_style := StyleBoxFlat.new()
		if positive:
			flash_style.bg_color = Color(0.7, 1.0, 0.7, 0.95)
		else:
			flash_style.bg_color = Color(1.0, 0.7, 0.7, 0.95)
		flash_style.corner_radius_top_left = 16
		flash_style.corner_radius_top_right = 16
		flash_style.corner_radius_bottom_left = 16
		flash_style.corner_radius_bottom_right = 16
		flash_style.content_margin_left = 12.0
		flash_style.content_margin_right = 12.0
		flash_style.content_margin_top = 8.0
		flash_style.content_margin_bottom = 8.0
		current_item_button.add_theme_stylebox_override("normal", flash_style)
		current_item_button.add_theme_stylebox_override("hover", flash_style)
		current_item_button.add_theme_stylebox_override("disabled", flash_style)
		current_item_button.disabled = true

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.15)


func _update_stats_display() -> void:
	var total_shown := current_item_index + 1
	stats_label.text = "Hits: %d  |  Misses: %d  |  False Alarms: %d" % [hits, misses, false_alarms]


func _clear_display() -> void:
	for child in display_area.get_children():
		child.queue_free()
	current_item_button = null


func _end_game() -> void:
	is_running = false
	game_hud.stop()

	# Calculate average reaction time
	var avg_rt: float = 0.0
	if reaction_times.size() > 0:
		var total_rt: float = 0.0
		for rt in reaction_times:
			total_rt += rt
		avg_rt = total_rt / reaction_times.size()

	# Send summary event
	GameManager.record_event("session_summary", {
		"hits": hits,
		"misses": misses,
		"false_alarms": false_alarms,
		"correct_rejections": correct_rejections,
		"avg_reaction_time_ms": int(avg_rt * 1000),
		"target_rule": "%s %s" % [target_color_name, target_shape_name],
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
	is_running = false
	get_tree().change_scene_to_file("res://scenes/ui/game_select.tscn")
