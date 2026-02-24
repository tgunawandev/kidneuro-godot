extends Control
## ImpulseIsland - Go/No-Go impulse control game for ADHD therapy.
## Green objects (friendly creatures) = TAP (Go trials).
## Red objects (scary creatures) = DON'T TAP (No-Go trials).
## Tracks reaction time, false alarms, misses, and correct inhibitions.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var trial_label: Label = %TrialLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var stimulus_button: Button = %StimulusButton
@onready var wait_label: Label = %WaitLabel

const GO_STIMULI := [
	{"emoji": "\ud83d\udc1f", "name": "Fish"},
	{"emoji": "\u2b50", "name": "Star"},
	{"emoji": "\ud83e\udd8b", "name": "Butterfly"},
]

const NOGO_STIMULI := [
	{"emoji": "\ud83e\udd80", "name": "Crab"},
	{"emoji": "\ud83d\udd77\ufe0f", "name": "Spider"},
	{"emoji": "\ud83d\udca3", "name": "Bomb"},
]

const TOTAL_TRIALS := 20

var current_trial: int = 0
var display_time: float = 2.5
var nogo_ratio: float = 0.3
var trial_sequence: Array[Dictionary] = []
var trial_start_time: float = 0.0
var waiting_for_input: bool = false
var tapped_this_trial: bool = false
var current_stimulus: Dictionary = {}
var trial_timer: SceneTreeTimer = null

# Detailed tracking
var correct_taps: int = 0
var false_alarms: int = 0
var misses: int = 0
var correct_inhibitions: int = 0


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	stimulus_button.pressed.connect(_on_stimulus_tapped)
	stimulus_button.visible = false
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	var level := GameManager.difficulty_level
	if level <= 3:
		display_time = 2.5
		nogo_ratio = 0.25
	elif level <= 6:
		display_time = 1.5
		nogo_ratio = 0.35
	else:
		display_time = 1.0
		nogo_ratio = 0.40


func _start_game() -> void:
	GameManager.start_session("impulse_control")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_TRIALS)
	current_trial = 0
	correct_taps = 0
	false_alarms = 0
	misses = 0
	correct_inhibitions = 0
	feedback_label.text = ""
	wait_label.text = ""
	_generate_trial_sequence()
	_next_trial()


func _generate_trial_sequence() -> void:
	trial_sequence.clear()
	var nogo_count := int(TOTAL_TRIALS * nogo_ratio)
	var go_count := TOTAL_TRIALS - nogo_count

	for i in range(go_count):
		var stim: Dictionary = GO_STIMULI[randi() % GO_STIMULI.size()]
		trial_sequence.append({"stimulus": stim, "is_go": true})

	for i in range(nogo_count):
		var stim: Dictionary = NOGO_STIMULI[randi() % NOGO_STIMULI.size()]
		trial_sequence.append({"stimulus": stim, "is_go": false})

	trial_sequence.shuffle()


func _next_trial() -> void:
	if current_trial >= TOTAL_TRIALS:
		_end_game()
		return

	current_stimulus = trial_sequence[current_trial]
	current_trial += 1
	trial_label.text = "Trial %d / %d" % [current_trial, TOTAL_TRIALS]
	game_hud.update_progress(current_trial - 1, TOTAL_TRIALS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""
	wait_label.text = ""
	tapped_this_trial = false

	# Brief pause between trials
	stimulus_button.visible = false
	await get_tree().create_timer(0.8).timeout

	# Show stimulus
	var stim_data: Dictionary = current_stimulus["stimulus"]
	var is_go: bool = current_stimulus["is_go"]
	stimulus_button.text = stim_data["emoji"]
	stimulus_button.visible = true

	# Style the button based on Go/No-Go
	var btn_style := StyleBoxFlat.new()
	btn_style.corner_radius_top_left = 20
	btn_style.corner_radius_top_right = 20
	btn_style.corner_radius_bottom_left = 20
	btn_style.corner_radius_bottom_right = 20
	if is_go:
		btn_style.bg_color = Color(0.85, 0.95, 0.85)
		btn_style.border_color = Color(0.4, 0.8, 0.4)
	else:
		btn_style.bg_color = Color(0.95, 0.85, 0.85)
		btn_style.border_color = Color(0.8, 0.4, 0.4)
	btn_style.border_width_top = 3
	btn_style.border_width_bottom = 3
	btn_style.border_width_left = 3
	btn_style.border_width_right = 3
	stimulus_button.add_theme_stylebox_override("normal", btn_style)

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = btn_style.bg_color.lightened(0.1)
	btn_hover.border_color = btn_style.border_color
	btn_hover.corner_radius_top_left = 20
	btn_hover.corner_radius_top_right = 20
	btn_hover.corner_radius_bottom_left = 20
	btn_hover.corner_radius_bottom_right = 20
	btn_hover.border_width_top = 3
	btn_hover.border_width_bottom = 3
	btn_hover.border_width_left = 3
	btn_hover.border_width_right = 3
	stimulus_button.add_theme_stylebox_override("hover", btn_hover)

	if is_go:
		wait_label.text = "Tap now!"
		wait_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.3))
	else:
		wait_label.text = "Don't tap!"
		wait_label.add_theme_color_override("font_color", Color(0.7, 0.3, 0.3))

	trial_start_time = Time.get_unix_time_from_system()
	waiting_for_input = true

	GameManager.record_event("trial_start", {
		"trial_num": current_trial,
		"stimulus": stim_data["name"],
		"is_go": is_go,
	})

	# Start timer for this trial
	trial_timer = get_tree().create_timer(display_time)
	await trial_timer.timeout

	# If we get here, the timer expired
	if waiting_for_input:
		_handle_timeout()


func _on_stimulus_tapped() -> void:
	if not waiting_for_input:
		return
	waiting_for_input = false

	var reaction_time := Time.get_unix_time_from_system() - trial_start_time
	var is_go: bool = current_stimulus["is_go"]

	if is_go:
		# Correct tap on a Go stimulus
		correct_taps += 1
		GameManager.record_answer(true)
		GameManager.score += 10 - 10  # record_answer already adds 10*level, adjust
		_show_feedback(true, "Great tap!")
	else:
		# False alarm: tapped a No-Go stimulus
		false_alarms += 1
		GameManager.record_answer(false)
		GameManager.score = maxi(GameManager.score - 5, 0)
		_show_feedback(false, "Oops! Don't tap that one!")

	GameManager.record_event("trial_response", {
		"trial_num": current_trial,
		"tapped": true,
		"correct": is_go,
		"reaction_time_ms": int(reaction_time * 1000),
	})

	game_hud.update_score(GameManager.score)
	stimulus_button.visible = false

	await get_tree().create_timer(1.2).timeout
	_next_trial()


func _handle_timeout() -> void:
	waiting_for_input = false
	var is_go: bool = current_stimulus["is_go"]

	if is_go:
		# Miss: didn't tap a Go stimulus
		misses += 1
		GameManager.record_answer(false)
		_show_feedback(false, "Too slow! Try to tap faster!")
	else:
		# Correct inhibition: didn't tap a No-Go stimulus (reward more)
		correct_inhibitions += 1
		GameManager.record_answer(true)
		GameManager.score += 5  # Extra +5 on top of record_answer's +10*level
		_show_feedback(true, "Great self-control!")

	GameManager.record_event("trial_response", {
		"trial_num": current_trial,
		"tapped": false,
		"correct": not is_go,
		"reaction_time_ms": -1,
	})

	game_hud.update_score(GameManager.score)
	stimulus_button.visible = false

	await get_tree().create_timer(1.2).timeout
	_next_trial()


func _show_feedback(correct: bool, message: String) -> void:
	feedback_label.text = message
	wait_label.text = ""
	if correct:
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))
	else:
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)


func _end_game() -> void:
	waiting_for_input = false
	stimulus_button.visible = false
	game_hud.stop()

	GameManager.record_event("session_summary", {
		"correct_taps": correct_taps,
		"false_alarms": false_alarms,
		"misses": misses,
		"correct_inhibitions": correct_inhibitions,
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
