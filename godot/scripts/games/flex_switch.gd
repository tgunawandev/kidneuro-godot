extends Control
## FlexSwitch - Cognitive Flexibility / Set-shifting game for ASD+ADHD therapy.
## Based on the Wisconsin Card Sorting Test adapted for children.
## Cards have shape and color properties; the child sorts by the active rule.
## Rule switches periodically, training the ability to shift mental sets
## without perseverating (getting stuck on the old rule).

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var card_label: Label = %CardLabel
@onready var rule_panel: PanelContainer = %RulePanel
@onready var rule_label: Label = %RuleLabel
@onready var switch_label: Label = %SwitchLabel
@onready var current_card: Button = %CurrentCard
@onready var feedback_label: Label = %FeedbackLabel
@onready var bins_container: HBoxContainer = %BinsContainer

const SHAPES := ["circle", "square", "triangle", "star"]
const SHAPE_SYMBOLS := {
	"circle": "\u25cf",
	"square": "\u25a0",
	"triangle": "\u25b2",
	"star": "\u2605",
}

const COLOR_NAMES := ["Red", "Blue", "Green", "Yellow"]
const COLORS := {
	"Red": Color(0.9, 0.25, 0.25),
	"Blue": Color(0.25, 0.55, 0.9),
	"Green": Color(0.3, 0.8, 0.3),
	"Yellow": Color(0.88, 0.75, 0.15),
}

const TOTAL_CARDS := 20
const RULES := ["COLOR", "SHAPE"]

var current_card_index: int = 0
var num_bins: int = 2
var switch_interval: int = 6
var switch_display_time: float = 2.0
var active_rule: String = "COLOR"
var previous_rule: String = ""
var cards_since_switch: int = 0
var card_sequence: Array[Dictionary] = []
var waiting_for_input: bool = false
var card_start_time: float = 0.0

# Bin data: which target values are shown in the bins
var bin_targets: Array[Dictionary] = []

# Tracking
var correct_sorts: int = 0
var perseveration_errors: int = 0
var other_errors: int = 0
var total_switch_cost_ms: float = 0.0
var switch_count: int = 0
var pre_switch_rt: Array[float] = []
var post_switch_rt: Array[float] = []
var just_switched: bool = false


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	current_card.visible = false
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	var level := GameManager.difficulty_level
	if level <= 3:
		num_bins = 2
		switch_interval = 6
		switch_display_time = 2.5
	elif level <= 6:
		num_bins = 3
		switch_interval = 5
		switch_display_time = 2.0
	else:
		num_bins = 4
		switch_interval = 4
		switch_display_time = 1.0


func _start_game() -> void:
	GameManager.start_session("cognitive_flexibility")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_CARDS)
	current_card_index = 0
	correct_sorts = 0
	perseveration_errors = 0
	other_errors = 0
	total_switch_cost_ms = 0.0
	switch_count = 0
	pre_switch_rt.clear()
	post_switch_rt.clear()
	cards_since_switch = 0
	just_switched = false
	feedback_label.text = ""
	switch_label.text = ""
	previous_rule = ""

	# Pick starting rule randomly
	active_rule = RULES[randi() % RULES.size()]

	_generate_card_sequence()
	_update_rule_display()
	_build_bins()
	_next_card()


func _generate_card_sequence() -> void:
	card_sequence.clear()
	for i in range(TOTAL_CARDS):
		var shape_idx := randi() % SHAPES.size()
		var color_idx := randi() % COLOR_NAMES.size()
		card_sequence.append({
			"shape": SHAPES[shape_idx],
			"shape_symbol": SHAPE_SYMBOLS[SHAPES[shape_idx]],
			"color_name": COLOR_NAMES[color_idx],
			"color": COLORS[COLOR_NAMES[color_idx]],
		})


func _update_rule_display() -> void:
	if active_rule == "COLOR":
		rule_label.text = "Sort by: COLOR \ud83c\udfa8"
	else:
		rule_label.text = "Sort by: SHAPE \ud83d\udd37"

	# Style the rule panel background
	var panel_style := StyleBoxFlat.new()
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 16.0
	panel_style.content_margin_right = 16.0
	panel_style.content_margin_top = 8.0
	panel_style.content_margin_bottom = 8.0

	if active_rule == "COLOR":
		panel_style.bg_color = Color(0.3, 0.45, 0.75)
	else:
		panel_style.bg_color = Color(0.55, 0.35, 0.7)

	rule_panel.add_theme_stylebox_override("panel", panel_style)


func _build_bins() -> void:
	# Clear existing bins
	for child in bins_container.get_children():
		child.queue_free()

	bin_targets.clear()

	if active_rule == "COLOR":
		# Bins are labeled by color
		var color_pool: Array[String] = []
		for c in COLOR_NAMES:
			color_pool.append(c)
		color_pool.shuffle()

		for i in range(mini(num_bins, color_pool.size())):
			var color_name: String = color_pool[i]
			var target := {"type": "color", "value": color_name}
			bin_targets.append(target)

			var btn := Button.new()
			btn.custom_minimum_size = Vector2(100, 100)
			btn.add_theme_font_size_override("font_size", 18)

			# Show a colored square as the bin label
			btn.text = "\u25a0\n%s" % color_name
			btn.add_theme_color_override("font_color", COLORS[color_name])

			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.94, 0.94, 0.96)
			style.corner_radius_top_left = 14
			style.corner_radius_top_right = 14
			style.corner_radius_bottom_left = 14
			style.corner_radius_bottom_right = 14
			style.border_color = COLORS[color_name].darkened(0.2)
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_width_left = 3
			style.border_width_right = 3
			btn.add_theme_stylebox_override("normal", style)

			var hover := StyleBoxFlat.new()
			hover.bg_color = Color(0.88, 0.88, 0.92)
			hover.corner_radius_top_left = 14
			hover.corner_radius_top_right = 14
			hover.corner_radius_bottom_left = 14
			hover.corner_radius_bottom_right = 14
			hover.border_color = COLORS[color_name].darkened(0.1)
			hover.border_width_top = 3
			hover.border_width_bottom = 3
			hover.border_width_left = 3
			hover.border_width_right = 3
			btn.add_theme_stylebox_override("hover", hover)

			var bin_idx: int = i
			btn.pressed.connect(func():
				_on_bin_selected(bin_idx)
			)

			bins_container.add_child(btn)
	else:
		# Bins are labeled by shape
		var shape_pool: Array[String] = []
		for s in SHAPES:
			shape_pool.append(s)
		shape_pool.shuffle()

		for i in range(mini(num_bins, shape_pool.size())):
			var shape_name: String = shape_pool[i]
			var target := {"type": "shape", "value": shape_name}
			bin_targets.append(target)

			var btn := Button.new()
			btn.custom_minimum_size = Vector2(100, 100)
			btn.add_theme_font_size_override("font_size", 18)

			# Show shape symbol in black
			var cap_name: String = shape_name.capitalize()
			btn.text = "%s\n%s" % [SHAPE_SYMBOLS[shape_name], cap_name]
			btn.add_theme_color_override("font_color", Color(0.2, 0.2, 0.25))

			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.94, 0.94, 0.96)
			style.corner_radius_top_left = 14
			style.corner_radius_top_right = 14
			style.corner_radius_bottom_left = 14
			style.corner_radius_bottom_right = 14
			style.border_color = Color(0.5, 0.4, 0.6)
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_width_left = 3
			style.border_width_right = 3
			btn.add_theme_stylebox_override("normal", style)

			var hover := StyleBoxFlat.new()
			hover.bg_color = Color(0.88, 0.88, 0.92)
			hover.corner_radius_top_left = 14
			hover.corner_radius_top_right = 14
			hover.corner_radius_bottom_left = 14
			hover.corner_radius_bottom_right = 14
			hover.border_color = Color(0.4, 0.3, 0.5)
			hover.border_width_top = 3
			hover.border_width_bottom = 3
			hover.border_width_left = 3
			hover.border_width_right = 3
			btn.add_theme_stylebox_override("hover", hover)

			var bin_idx: int = i
			btn.pressed.connect(func():
				_on_bin_selected(bin_idx)
			)

			bins_container.add_child(btn)


func _next_card() -> void:
	if current_card_index >= TOTAL_CARDS:
		_end_game()
		return

	# Check if we need to switch the rule
	if current_card_index > 0 and cards_since_switch >= switch_interval:
		await _perform_rule_switch()

	var card_data: Dictionary = card_sequence[current_card_index]
	current_card_index += 1
	cards_since_switch += 1

	card_label.text = "Card %d / %d" % [current_card_index, TOTAL_CARDS]
	game_hud.update_progress(current_card_index - 1, TOTAL_CARDS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""

	# Ensure the current card's correct target exists in bins, regenerate if needed
	_ensure_valid_bins(card_data)

	# Display the card
	current_card.text = card_data["shape_symbol"]
	current_card.add_theme_color_override("font_color", card_data["color"])
	current_card.visible = true

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1.0, 1.0, 1.0)
	card_style.corner_radius_top_left = 16
	card_style.corner_radius_top_right = 16
	card_style.corner_radius_bottom_left = 16
	card_style.corner_radius_bottom_right = 16
	card_style.border_color = Color(0.7, 0.7, 0.75)
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	current_card.add_theme_stylebox_override("normal", card_style)

	var card_hover := StyleBoxFlat.new()
	card_hover.bg_color = Color(0.97, 0.97, 1.0)
	card_hover.corner_radius_top_left = 16
	card_hover.corner_radius_top_right = 16
	card_hover.corner_radius_bottom_left = 16
	card_hover.corner_radius_bottom_right = 16
	card_hover.border_color = Color(0.6, 0.6, 0.7)
	card_hover.border_width_top = 2
	card_hover.border_width_bottom = 2
	card_hover.border_width_left = 2
	card_hover.border_width_right = 2
	current_card.add_theme_stylebox_override("hover", card_hover)

	# Enable bin buttons
	for btn in bins_container.get_children():
		if btn is Button:
			btn.disabled = false

	card_start_time = Time.get_unix_time_from_system()
	waiting_for_input = true

	GameManager.record_event("card_shown", {
		"card_index": current_card_index,
		"shape": card_data["shape"],
		"color": card_data["color_name"],
		"rule": active_rule,
	})


func _ensure_valid_bins(card_data: Dictionary) -> void:
	# Check if the card's correct value for the active rule is represented in bins
	var target_value: String = ""
	if active_rule == "COLOR":
		target_value = card_data["color_name"]
	else:
		target_value = card_data["shape"]

	var found := false
	for bt in bin_targets:
		if bt["value"] == target_value:
			found = true
			break

	if not found:
		# Replace a random bin (not the first one for stability) with the correct target
		var replace_idx := randi() % bin_targets.size()
		bin_targets[replace_idx]["value"] = target_value
		_rebuild_bins_display()


func _rebuild_bins_display() -> void:
	# Rebuild the bin button labels/colors based on updated bin_targets
	var children := bins_container.get_children()
	for i in range(mini(children.size(), bin_targets.size())):
		var btn: Button = children[i]
		var target: Dictionary = bin_targets[i]

		if target["type"] == "color":
			var color_name: String = target["value"]
			btn.text = "\u25a0\n%s" % color_name
			btn.add_theme_color_override("font_color", COLORS[color_name])

			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.94, 0.94, 0.96)
			style.corner_radius_top_left = 14
			style.corner_radius_top_right = 14
			style.corner_radius_bottom_left = 14
			style.corner_radius_bottom_right = 14
			style.border_color = COLORS[color_name].darkened(0.2)
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_width_left = 3
			style.border_width_right = 3
			btn.add_theme_stylebox_override("normal", style)
		else:
			var shape_name: String = target["value"]
			var cap_name: String = shape_name.capitalize()
			btn.text = "%s\n%s" % [SHAPE_SYMBOLS[shape_name], cap_name]
			btn.add_theme_color_override("font_color", Color(0.2, 0.2, 0.25))

			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.94, 0.94, 0.96)
			style.corner_radius_top_left = 14
			style.corner_radius_top_right = 14
			style.corner_radius_bottom_left = 14
			style.corner_radius_bottom_right = 14
			style.border_color = Color(0.5, 0.4, 0.6)
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_width_left = 3
			style.border_width_right = 3
			btn.add_theme_stylebox_override("normal", style)


func _perform_rule_switch() -> void:
	previous_rule = active_rule

	# Switch to the other rule
	if active_rule == "COLOR":
		active_rule = "SHAPE"
	else:
		active_rule = "COLOR"

	cards_since_switch = 0
	switch_count += 1
	just_switched = true

	GameManager.record_event("rule_switch", {
		"from_rule": previous_rule,
		"to_rule": active_rule,
		"cards_since_last": switch_interval,
	})

	# Show switch announcement
	switch_label.text = "NEW RULE!"
	switch_label.add_theme_color_override("font_color", Color(0.85, 0.4, 0.15))

	if not AccessibilityManager.reduce_motion:
		switch_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(switch_label, "modulate:a", 1.0, 0.2)

	# Update rule display and rebuild bins
	_update_rule_display()
	_build_bins()

	# Wait for the announcement to be read
	await get_tree().create_timer(switch_display_time).timeout

	# Fade out the switch label
	if not AccessibilityManager.reduce_motion:
		var fade_tween := create_tween()
		fade_tween.tween_property(switch_label, "modulate:a", 0.0, 0.3)
		await fade_tween.finished
	switch_label.text = ""
	switch_label.modulate.a = 1.0


func _on_bin_selected(bin_idx: int) -> void:
	if not waiting_for_input:
		return
	waiting_for_input = false

	var reaction_time := Time.get_unix_time_from_system() - card_start_time
	var reaction_ms := int(reaction_time * 1000)

	var card_data: Dictionary = card_sequence[current_card_index - 1]
	var selected_target: Dictionary = bin_targets[bin_idx]

	# Determine what the correct bin value is for the active rule
	var correct_value: String = ""
	if active_rule == "COLOR":
		correct_value = card_data["color_name"]
	else:
		correct_value = card_data["shape"]

	var is_correct := selected_target["value"] == correct_value

	# Check for perseveration: did the child sort by the OLD rule?
	var is_perseveration := false
	if not is_correct and previous_rule != "":
		var old_rule_value: String = ""
		if previous_rule == "COLOR":
			old_rule_value = card_data["color_name"]
		else:
			old_rule_value = card_data["shape"]

		if selected_target["value"] == old_rule_value:
			is_perseveration = true

	# Track reaction times for switch cost calculation
	if just_switched:
		post_switch_rt.append(reaction_time)
		just_switched = false
	else:
		pre_switch_rt.append(reaction_time)

	# Scoring
	if is_correct:
		correct_sorts += 1
		GameManager.record_answer(true)
	elif is_perseveration:
		perseveration_errors += 1
		GameManager.record_answer(false)
		# Extra penalty for perseveration
		GameManager.score = maxi(GameManager.score - 3, 0)
	else:
		other_errors += 1
		GameManager.record_answer(false)

	GameManager.record_event("card_sorted", {
		"card_index": current_card_index,
		"correct": is_correct,
		"perseveration": is_perseveration,
		"bin_value": selected_target["value"],
		"expected_value": correct_value,
		"rule": active_rule,
		"reaction_time_ms": reaction_ms,
	})

	# Disable bin buttons
	for btn in bins_container.get_children():
		if btn is Button:
			btn.disabled = true

	# Visual feedback on the selected bin
	var children := bins_container.get_children()
	if bin_idx < children.size():
		var selected_btn: Button = children[bin_idx]

		var fb_style := StyleBoxFlat.new()
		fb_style.corner_radius_top_left = 14
		fb_style.corner_radius_top_right = 14
		fb_style.corner_radius_bottom_left = 14
		fb_style.corner_radius_bottom_right = 14
		fb_style.border_width_top = 3
		fb_style.border_width_bottom = 3
		fb_style.border_width_left = 3
		fb_style.border_width_right = 3

		if is_correct:
			fb_style.bg_color = Color(0.7, 1.0, 0.7)
			fb_style.border_color = Color(0.3, 0.7, 0.3)
		elif is_perseveration:
			fb_style.bg_color = Color(1.0, 0.8, 0.6)
			fb_style.border_color = Color(0.85, 0.5, 0.2)
		else:
			fb_style.bg_color = Color(1.0, 0.7, 0.7)
			fb_style.border_color = Color(0.7, 0.3, 0.3)

		selected_btn.add_theme_stylebox_override("disabled", fb_style)

	# Show feedback text
	if is_correct:
		feedback_label.text = "Correct!"
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))
	elif is_perseveration:
		feedback_label.text = "Oops! Remember the NEW rule: sort by %s!" % active_rule
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.5, 0.15))
	else:
		feedback_label.text = "Not quite. Try to sort by %s." % active_rule
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

	game_hud.update_score(GameManager.score)
	current_card.visible = false

	await get_tree().create_timer(1.5).timeout
	_next_card()


func _end_game() -> void:
	waiting_for_input = false
	current_card.visible = false
	game_hud.stop()

	# Calculate switch cost
	var avg_pre := 0.0
	if pre_switch_rt.size() > 0:
		var sum := 0.0
		for rt in pre_switch_rt:
			sum += rt
		avg_pre = sum / float(pre_switch_rt.size())

	var avg_post := 0.0
	if post_switch_rt.size() > 0:
		var sum := 0.0
		for rt in post_switch_rt:
			sum += rt
		avg_post = sum / float(post_switch_rt.size())

	var switch_cost_ms := int((avg_post - avg_pre) * 1000)

	GameManager.record_event("session_summary", {
		"correct_sorts": correct_sorts,
		"perseveration_errors": perseveration_errors,
		"other_errors": other_errors,
		"switch_count": switch_count,
		"switch_cost_ms": switch_cost_ms,
		"avg_pre_switch_rt_ms": int(avg_pre * 1000),
		"avg_post_switch_rt_ms": int(avg_post * 1000),
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
