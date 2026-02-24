extends Control
## FeelingThermometer - Emotion intensity rating and coping strategy selection game.
## Two phases per round: rate how strong the feeling is (1-5), then pick the best
## coping strategy. Builds emotional regulation skills for ASD+ADHD children.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var round_label: Label = %RoundLabel
@onready var phase_label: Label = %PhaseLabel
@onready var scenario_emoji: Label = %ScenarioEmoji
@onready var scenario_text: Label = %ScenarioText
@onready var feedback_label: Label = %FeedbackLabel
@onready var thermometer_container: HBoxContainer = %ThermometerContainer
@onready var coping_container: VBoxContainer = %CopingContainer

const SCENARIOS := [
	{
		"emoji": "😤",
		"scenario": "Someone cuts in front of you in line",
		"expected_intensity": 3,
		"coping": [
			{"text": "Take 3 deep breaths", "is_best": true},
			{"text": "Push them back", "is_best": false},
			{"text": "Tell a teacher calmly", "is_best": true},
			{"text": "Scream at them", "is_best": false},
		],
	},
	{
		"emoji": "😰",
		"scenario": "You have to present in front of the class",
		"expected_intensity": 4,
		"coping": [
			{"text": "Practice deep breathing before", "is_best": true},
			{"text": "Refuse to do it", "is_best": false},
			{"text": "Think of something funny to relax", "is_best": true},
			{"text": "Run out of the room", "is_best": false},
		],
	},
	{
		"emoji": "😊",
		"scenario": "Your friend invites you to a birthday party",
		"expected_intensity": 2,
		"coping": [
			{"text": "Say thank you and smile", "is_best": true},
			{"text": "Scream with excitement", "is_best": false},
			{"text": "Tell them you'll be there", "is_best": true},
		],
	},
	{
		"emoji": "😢",
		"scenario": "Your pet fish is sick",
		"expected_intensity": 4,
		"coping": [
			{"text": "Talk to someone about how you feel", "is_best": true},
			{"text": "Break something", "is_best": false},
			{"text": "Ask a parent for help", "is_best": true},
			{"text": "Pretend it's fine", "is_best": false},
		],
	},
	{
		"emoji": "😠",
		"scenario": "Someone breaks your favorite toy",
		"expected_intensity": 4,
		"coping": [
			{"text": "Count to 10 slowly", "is_best": true},
			{"text": "Hit them", "is_best": false},
			{"text": "Tell them how it made you feel", "is_best": true},
			{"text": "Break their toy", "is_best": false},
		],
	},
	{
		"emoji": "😨",
		"scenario": "There's a loud thunderstorm outside",
		"expected_intensity": 3,
		"coping": [
			{"text": "Find a cozy spot and take deep breaths", "is_best": true},
			{"text": "Scream and cry", "is_best": false},
			{"text": "Listen to calming music", "is_best": true},
			{"text": "Hide under the bed all day", "is_best": false},
		],
	},
	{
		"emoji": "🥺",
		"scenario": "Your best friend is playing with someone else",
		"expected_intensity": 3,
		"coping": [
			{"text": "Ask if you can join them", "is_best": true},
			{"text": "Say mean things about the other kid", "is_best": false},
			{"text": "Find another fun activity", "is_best": true},
			{"text": "Cry and run away", "is_best": false},
		],
	},
	{
		"emoji": "😖",
		"scenario": "You can't figure out a hard math problem",
		"expected_intensity": 3,
		"coping": [
			{"text": "Take a break and try again", "is_best": true},
			{"text": "Throw your book", "is_best": false},
			{"text": "Ask for help from a teacher", "is_best": true},
			{"text": "Give up completely", "is_best": false},
		],
	},
	{
		"emoji": "🤗",
		"scenario": "You helped a younger kid who was lost",
		"expected_intensity": 1,
		"coping": [
			{"text": "Feel proud of yourself", "is_best": true},
			{"text": "Brag to everyone", "is_best": false},
			{"text": "Tell your family about it", "is_best": true},
		],
	},
	{
		"emoji": "😓",
		"scenario": "You accidentally spill juice on the carpet",
		"expected_intensity": 3,
		"coping": [
			{"text": "Tell a parent and help clean it up", "is_best": true},
			{"text": "Hide the mess", "is_best": false},
			{"text": "Say sorry and get paper towels", "is_best": true},
			{"text": "Blame someone else", "is_best": false},
		],
	},
	{
		"emoji": "😔",
		"scenario": "You weren't picked for the school team",
		"expected_intensity": 4,
		"coping": [
			{"text": "Talk about your feelings with someone", "is_best": true},
			{"text": "Quit all sports forever", "is_best": false},
			{"text": "Practice more and try again next time", "is_best": true},
			{"text": "Say the team is stupid", "is_best": false},
		],
	},
	{
		"emoji": "😃",
		"scenario": "You got a gold star on your homework!",
		"expected_intensity": 1,
		"coping": [
			{"text": "Celebrate and keep working hard", "is_best": true},
			{"text": "Brag to everyone in class", "is_best": false},
			{"text": "Thank your teacher", "is_best": true},
		],
	},
]

const TOTAL_ROUNDS := 8

const THERMOMETER_LABELS := ["😌", "😊", "😐", "😟", "😡"]
const THERMOMETER_COLORS := [
	Color(0.45, 0.70, 0.90),  # Cool blue (1)
	Color(0.50, 0.80, 0.65),  # Teal-green (2)
	Color(0.95, 0.85, 0.35),  # Yellow (3)
	Color(0.95, 0.60, 0.30),  # Orange (4)
	Color(0.90, 0.30, 0.30),  # Hot red (5)
]

enum Phase { INTENSITY, COPING }

var current_round: int = 0
var current_phase: Phase = Phase.INTENSITY
var current_scenario: Dictionary = {}
var scenario_pool: Array[Dictionary] = []
var waiting_for_input: bool = false
var selected_intensity: int = 0


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	# Difficulty affects point thresholds but gameplay stays accessible
	pass


func _start_game() -> void:
	GameManager.start_session("feeling_thermometer")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	feedback_label.text = ""

	# Create shuffled scenario pool
	scenario_pool.clear()
	var all_scenarios: Array[Dictionary] = []
	for s in SCENARIOS:
		all_scenarios.append(s)
	all_scenarios.shuffle()
	for i in range(mini(TOTAL_ROUNDS, all_scenarios.size())):
		scenario_pool.append(all_scenarios[i])

	_next_round()


func _next_round() -> void:
	if current_round >= TOTAL_ROUNDS:
		_end_game()
		return

	current_scenario = scenario_pool[current_round]
	current_round += 1
	round_label.text = "Scenario %d / %d" % [current_round, TOTAL_ROUNDS]
	game_hud.update_progress(current_round - 1, TOTAL_ROUNDS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""
	selected_intensity = 0

	# Show scenario
	scenario_emoji.text = current_scenario["emoji"]
	scenario_text.text = current_scenario["scenario"]

	# Start Phase 1: Intensity rating
	_show_intensity_phase()

	GameManager.record_event("scenario_shown", {
		"round": current_round,
		"scenario": current_scenario["scenario"],
		"expected_intensity": current_scenario["expected_intensity"],
	})


func _show_intensity_phase() -> void:
	current_phase = Phase.INTENSITY
	phase_label.text = "How strong is this feeling?"

	# Clear containers
	_clear_children(thermometer_container)
	_clear_children(coping_container)

	# Show thermometer container, hide coping container
	thermometer_container.visible = true
	coping_container.visible = false

	# Build 5 thermometer buttons
	for i in range(5):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.add_theme_font_size_override("font_size", 32)
		btn.text = "%s\n%d" % [THERMOMETER_LABELS[i], i + 1]

		var style := StyleBoxFlat.new()
		style.bg_color = THERMOMETER_COLORS[i].darkened(0.1)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.content_margin_left = 8.0
		style.content_margin_right = 8.0
		style.content_margin_top = 4.0
		style.content_margin_bottom = 4.0
		btn.add_theme_stylebox_override("normal", style)

		var hover := StyleBoxFlat.new()
		hover.bg_color = THERMOMETER_COLORS[i].lightened(0.15)
		hover.corner_radius_top_left = 12
		hover.corner_radius_top_right = 12
		hover.corner_radius_bottom_left = 12
		hover.corner_radius_bottom_right = 12
		hover.content_margin_left = 8.0
		hover.content_margin_right = 8.0
		hover.content_margin_top = 4.0
		hover.content_margin_bottom = 4.0
		btn.add_theme_stylebox_override("hover", hover)

		var intensity_value: int = i + 1
		btn.pressed.connect(func():
			_on_intensity_selected(intensity_value, btn)
		)

		thermometer_container.add_child(btn)

	waiting_for_input = true


func _on_intensity_selected(intensity: int, button: Button) -> void:
	if not waiting_for_input or current_phase != Phase.INTENSITY:
		return
	waiting_for_input = false
	selected_intensity = intensity

	var expected: int = current_scenario["expected_intensity"]
	var diff := absi(intensity - expected)
	var is_reasonable := diff <= 1

	# Score for reasonable intensity
	if is_reasonable:
		GameManager.score += 5

	# Highlight the selected button
	var result_style := StyleBoxFlat.new()
	result_style.corner_radius_top_left = 12
	result_style.corner_radius_top_right = 12
	result_style.corner_radius_bottom_left = 12
	result_style.corner_radius_bottom_right = 12
	result_style.content_margin_left = 8.0
	result_style.content_margin_right = 8.0
	result_style.content_margin_top = 4.0
	result_style.content_margin_bottom = 4.0
	if is_reasonable:
		result_style.bg_color = Color(0.7, 1.0, 0.7)
		feedback_label.text = "Good rating! Now pick a coping strategy."
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))
	else:
		result_style.bg_color = Color(1.0, 0.85, 0.7)
		feedback_label.text = "That's okay! Now pick a coping strategy."
		feedback_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.2))
	result_style.border_color = Color.WHITE
	result_style.border_width_top = 3
	result_style.border_width_bottom = 3
	result_style.border_width_left = 3
	result_style.border_width_right = 3
	button.add_theme_stylebox_override("normal", result_style)

	# Disable all thermometer buttons
	for child in thermometer_container.get_children():
		if child is Button:
			child.disabled = true

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

	GameManager.record_event("intensity_rated", {
		"round": current_round,
		"scenario": current_scenario["scenario"],
		"rating": intensity,
		"expected": expected,
		"reasonable": is_reasonable,
	})

	game_hud.update_score(GameManager.score)

	# Brief pause then show coping phase
	await get_tree().create_timer(1.2).timeout
	_show_coping_phase()


func _show_coping_phase() -> void:
	current_phase = Phase.COPING
	phase_label.text = "What's a good way to handle this?"
	feedback_label.text = ""

	# Hide thermometer, show coping
	thermometer_container.visible = false
	coping_container.visible = true
	_clear_children(coping_container)

	# Build coping strategy buttons
	var strategies: Array = current_scenario["coping"]
	var shuffled: Array = strategies.duplicate()
	shuffled.shuffle()

	for item in shuffled:
		var btn := Button.new()
		btn.text = "  %s  " % item["text"]
		btn.custom_minimum_size = Vector2(300, 56)
		btn.add_theme_font_size_override("font_size", 18)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.95, 0.92, 0.92)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.content_margin_left = 16.0
		style.content_margin_right = 16.0
		style.content_margin_top = 10.0
		style.content_margin_bottom = 10.0
		btn.add_theme_stylebox_override("normal", style)

		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.92, 0.88, 0.92)
		hover.corner_radius_top_left = 10
		hover.corner_radius_top_right = 10
		hover.corner_radius_bottom_left = 10
		hover.corner_radius_bottom_right = 10
		hover.content_margin_left = 16.0
		hover.content_margin_right = 16.0
		hover.content_margin_top = 10.0
		hover.content_margin_bottom = 10.0
		btn.add_theme_stylebox_override("hover", hover)

		var strategy_data: Dictionary = item
		btn.pressed.connect(func():
			_on_coping_selected(strategy_data, btn)
		)

		coping_container.add_child(btn)

	waiting_for_input = true


func _on_coping_selected(strategy: Dictionary, button: Button) -> void:
	if not waiting_for_input or current_phase != Phase.COPING:
		return
	waiting_for_input = false

	var is_best: bool = strategy["is_best"]

	# Record as correct/incorrect for GameManager tracking
	GameManager.record_answer(is_best)

	# Additional score for best strategy
	if is_best:
		# record_answer already gave 10*level, add extra 0 (it's already generous)
		pass

	# Disable all coping buttons
	for child in coping_container.get_children():
		if child is Button:
			child.disabled = true

	# Show feedback
	if is_best:
		feedback_label.text = "That's a good way to handle it!"
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))

		var correct_style := StyleBoxFlat.new()
		correct_style.bg_color = Color(0.7, 1.0, 0.7)
		correct_style.corner_radius_top_left = 10
		correct_style.corner_radius_top_right = 10
		correct_style.corner_radius_bottom_left = 10
		correct_style.corner_radius_bottom_right = 10
		button.add_theme_stylebox_override("disabled", correct_style)
	else:
		# Find a best option to suggest
		var best_option: String = ""
		for item in current_scenario["coping"]:
			if item["is_best"]:
				best_option = item["text"]
				break
		feedback_label.text = "That could work, but \"%s\" might help more." % best_option
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.5, 0.3))

		var wrong_style := StyleBoxFlat.new()
		wrong_style.bg_color = Color(1.0, 0.85, 0.8)
		wrong_style.corner_radius_top_left = 10
		wrong_style.corner_radius_top_right = 10
		wrong_style.corner_radius_bottom_left = 10
		wrong_style.corner_radius_bottom_right = 10
		button.add_theme_stylebox_override("disabled", wrong_style)

		# Highlight a best option green
		for child in coping_container.get_children():
			if child is Button:
				var btn_text: String = child.text.strip_edges()
				for item in current_scenario["coping"]:
					if item["is_best"] and btn_text == item["text"]:
						var best_style := StyleBoxFlat.new()
						best_style.bg_color = Color(0.7, 1.0, 0.7)
						best_style.corner_radius_top_left = 10
						best_style.corner_radius_top_right = 10
						best_style.corner_radius_bottom_left = 10
						best_style.corner_radius_bottom_right = 10
						child.add_theme_stylebox_override("disabled", best_style)
						break

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

	GameManager.record_event("coping_selected", {
		"round": current_round,
		"scenario": current_scenario["scenario"],
		"strategy": strategy["text"],
		"is_best": is_best,
		"intensity_rated": selected_intensity,
	})

	game_hud.update_score(GameManager.score)

	await get_tree().create_timer(2.0).timeout
	_next_round()


func _clear_children(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()


func _end_game() -> void:
	waiting_for_input = false
	game_hud.stop()

	GameManager.record_event("session_summary", {
		"total_scenarios": TOTAL_ROUNDS,
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
