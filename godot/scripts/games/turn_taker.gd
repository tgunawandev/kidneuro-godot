extends Control
## TurnTaker - Turn-taking simulation game for social skills therapy.
## Child plays a dice game with a virtual friend "Sunny" and must wait during
## Sunny's turn. Tracks wait compliance, turn response time, and social responses.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var round_label: Label = %RoundLabel
@onready var turn_label: Label = %TurnLabel
@onready var player_score_label: Label = %PlayerScoreLabel
@onready var sunny_score_label: Label = %SunnyScoreLabel
@onready var dice_display: Label = %DiceDisplay
@onready var feedback_label: Label = %FeedbackLabel
@onready var roll_button: Button = %RollButton
@onready var social_container: VBoxContainer = %SocialContainer
@onready var wait_timer_label: Label = %WaitTimerLabel

const DICE_FACES := ["⚀", "⚁", "⚂", "⚃", "⚄", "⚅"]

const SOCIAL_PROMPTS := [
	{"prompt": "Say 'Good job, Sunny!'", "response": "Good job, Sunny!"},
	{"prompt": "Say 'Nice roll!'", "response": "Nice roll!"},
	{"prompt": "Say 'Your turn was great!'", "response": "Your turn was great!"},
	{"prompt": "Say 'Well played!'", "response": "Well played!"},
	{"prompt": "Give Sunny a thumbs up!", "response": "👍 Thumbs up!"},
	{"prompt": "Say 'Let's keep going!'", "response": "Let's keep going!"},
	{"prompt": "Say 'That was fun!'", "response": "That was fun!"},
	{"prompt": "Say 'Good game so far!'", "response": "Good game so far!"},
]

const TOTAL_ROUNDS := 8  # 8 rounds = 4 player turns + 4 Sunny turns

enum TurnOwner { PLAYER, SUNNY }
enum TurnPhase { WAITING_TO_ROLL, ROLLING, SHOWING_RESULT, SOCIAL_PROMPT, WAITING_FOR_PARTNER }

var current_round: int = 0
var player_dice_score: int = 0
var sunny_dice_score: int = 0
var wait_time: float = 2.0
var current_turn: TurnOwner = TurnOwner.PLAYER
var current_phase: TurnPhase = TurnPhase.WAITING_TO_ROLL
var waiting_for_input: bool = false
var tapped_during_wait: bool = false
var successful_waits: int = 0
var failed_waits: int = 0
var social_responses: int = 0
var total_social_prompts: int = 0
var _wait_elapsed: float = 0.0
var _wait_active: bool = false
var _roll_animation_active: bool = false


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	roll_button.pressed.connect(_on_roll_pressed)

	# Style the roll button
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.45, 0.65, 0.90)
	btn_style.corner_radius_top_left = 16
	btn_style.corner_radius_top_right = 16
	btn_style.corner_radius_bottom_left = 16
	btn_style.corner_radius_bottom_right = 16
	btn_style.content_margin_left = 20.0
	btn_style.content_margin_right = 20.0
	btn_style.content_margin_top = 10.0
	btn_style.content_margin_bottom = 10.0
	roll_button.add_theme_stylebox_override("normal", btn_style)

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.55, 0.72, 0.95)
	btn_hover.corner_radius_top_left = 16
	btn_hover.corner_radius_top_right = 16
	btn_hover.corner_radius_bottom_left = 16
	btn_hover.corner_radius_bottom_right = 16
	btn_hover.content_margin_left = 20.0
	btn_hover.content_margin_right = 20.0
	btn_hover.content_margin_top = 10.0
	btn_hover.content_margin_bottom = 10.0
	roll_button.add_theme_stylebox_override("hover", btn_hover)

	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = Color(0.35, 0.55, 0.80)
	btn_pressed.corner_radius_top_left = 16
	btn_pressed.corner_radius_top_right = 16
	btn_pressed.corner_radius_bottom_left = 16
	btn_pressed.corner_radius_bottom_right = 16
	btn_pressed.content_margin_left = 20.0
	btn_pressed.content_margin_right = 20.0
	btn_pressed.content_margin_top = 10.0
	btn_pressed.content_margin_bottom = 10.0
	roll_button.add_theme_stylebox_override("pressed", btn_pressed)

	roll_button.add_theme_color_override("font_color", Color.WHITE)

	_configure_difficulty()
	_start_game()


func _process(delta: float) -> void:
	if _wait_active:
		_wait_elapsed += delta
		var remaining := maxf(wait_time - _wait_elapsed, 0.0)
		wait_timer_label.text = "Waiting... %.1fs" % remaining

		# Animate dice during Sunny's turn
		if _roll_animation_active and int(_wait_elapsed * 8) % 2 == 0:
			dice_display.text = DICE_FACES[randi() % DICE_FACES.size()]

		if _wait_elapsed >= wait_time:
			_wait_active = false
			_roll_animation_active = false
			_on_wait_completed()


func _configure_difficulty() -> void:
	var level := GameManager.difficulty_level
	if level <= 3:
		wait_time = 2.0
	elif level <= 6:
		wait_time = 3.0
	else:
		wait_time = 5.0


func _start_game() -> void:
	GameManager.start_session("turn_taker")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	player_dice_score = 0
	sunny_dice_score = 0
	successful_waits = 0
	failed_waits = 0
	social_responses = 0
	total_social_prompts = 0
	feedback_label.text = ""
	wait_timer_label.text = ""
	_update_scoreboard()
	_clear_social_container()

	_next_turn()


func _next_turn() -> void:
	if current_round >= TOTAL_ROUNDS:
		_end_game()
		return

	current_round += 1
	round_label.text = "Round %d / %d" % [current_round, TOTAL_ROUNDS]
	game_hud.update_progress(current_round - 1, TOTAL_ROUNDS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""
	wait_timer_label.text = ""
	_clear_social_container()

	# Alternate turns: odd rounds = player, even rounds = Sunny
	if current_round % 2 == 1:
		current_turn = TurnOwner.PLAYER
		_start_player_turn()
	else:
		current_turn = TurnOwner.SUNNY
		_start_sunny_turn()

	GameManager.record_event("turn_start", {
		"round": current_round,
		"whose_turn": "player" if current_turn == TurnOwner.PLAYER else "sunny",
	})


func _start_player_turn() -> void:
	current_phase = TurnPhase.WAITING_TO_ROLL
	turn_label.text = "Your turn! Tap to roll!"
	turn_label.add_theme_color_override("font_color", Color(0.3, 0.5, 0.8))
	dice_display.text = "🎲"
	roll_button.visible = true
	roll_button.disabled = false
	waiting_for_input = true


func _start_sunny_turn() -> void:
	current_phase = TurnPhase.WAITING_FOR_PARTNER
	turn_label.text = "☀️ Sunny's turn - please wait!"
	turn_label.add_theme_color_override("font_color", Color(0.85, 0.6, 0.2))
	dice_display.text = "🎲"

	# Show roll button but it should NOT be tapped
	roll_button.visible = true
	roll_button.disabled = false
	tapped_during_wait = false
	waiting_for_input = true

	# Start the wait timer
	_wait_elapsed = 0.0
	_wait_active = true
	_roll_animation_active = true


func _on_roll_pressed() -> void:
	if current_turn == TurnOwner.PLAYER and current_phase == TurnPhase.WAITING_TO_ROLL:
		# Player rolling on their turn - correct!
		waiting_for_input = false
		roll_button.disabled = true
		_do_player_roll()
	elif current_turn == TurnOwner.SUNNY and current_phase == TurnPhase.WAITING_FOR_PARTNER:
		# Child tapped during Sunny's turn - impulse failure!
		if not tapped_during_wait:
			tapped_during_wait = true
			failed_waits += 1

			feedback_label.text = "Oops! It's Sunny's turn - try to wait!"
			feedback_label.add_theme_color_override("font_color", Color(0.85, 0.4, 0.3))

			if not AccessibilityManager.reduce_motion:
				feedback_label.modulate.a = 0.0
				var tween := create_tween()
				tween.tween_property(feedback_label, "modulate:a", 1.0, 0.15)

			GameManager.record_event("wait_result", {
				"round": current_round,
				"waited_successfully": false,
				"tapped_early": true,
			})


func _do_player_roll() -> void:
	current_phase = TurnPhase.ROLLING

	# Animate dice roll
	if not AccessibilityManager.reduce_motion:
		for i in range(8):
			dice_display.text = DICE_FACES[randi() % DICE_FACES.size()]
			await get_tree().create_timer(0.1).timeout

	# Final result
	var roll_value := (randi() % 6) + 1
	dice_display.text = DICE_FACES[roll_value - 1]
	player_dice_score += roll_value
	_update_scoreboard()

	# Award points
	GameManager.record_answer(true)
	game_hud.update_score(GameManager.score)

	current_phase = TurnPhase.SHOWING_RESULT
	feedback_label.text = "You rolled a %d!" % roll_value
	feedback_label.add_theme_color_override("font_color", Color(0.3, 0.5, 0.8))

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

	GameManager.record_event("roll_result", {
		"round": current_round,
		"player": "child",
		"value": roll_value,
	})

	roll_button.visible = false

	await get_tree().create_timer(1.5).timeout
	_next_turn()


func _on_wait_completed() -> void:
	# Sunny's roll is done
	var roll_value := (randi() % 6) + 1
	dice_display.text = DICE_FACES[roll_value - 1]
	sunny_dice_score += roll_value
	_update_scoreboard()

	roll_button.visible = false
	roll_button.disabled = true
	wait_timer_label.text = ""

	GameManager.record_event("roll_result", {
		"round": current_round,
		"player": "sunny",
		"value": roll_value,
	})

	# Check wait compliance
	if not tapped_during_wait:
		successful_waits += 1
		GameManager.score += 15  # Bonus for successful wait
		feedback_label.text = "☀️ Sunny rolled a %d! Great waiting!" % roll_value
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))

		GameManager.record_event("wait_result", {
			"round": current_round,
			"waited_successfully": true,
			"tapped_early": false,
		})
	else:
		feedback_label.text = "☀️ Sunny rolled a %d. Try waiting next time!" % roll_value
		feedback_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.2))

	game_hud.update_score(GameManager.score)

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

	waiting_for_input = false

	await get_tree().create_timer(1.5).timeout

	# Show social prompt after Sunny's turn
	_show_social_prompt()


func _show_social_prompt() -> void:
	current_phase = TurnPhase.SOCIAL_PROMPT
	_clear_social_container()

	var prompt_data: Dictionary = SOCIAL_PROMPTS[randi() % SOCIAL_PROMPTS.size()]
	total_social_prompts += 1

	# Show the prompt text
	var prompt_label := Label.new()
	prompt_label.text = prompt_data["prompt"]
	prompt_label.add_theme_font_size_override("font_size", 20)
	prompt_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.55))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	social_container.add_child(prompt_label)

	# Create response button
	var btn := Button.new()
	btn.text = "  %s  " % prompt_data["response"]
	btn.custom_minimum_size = Vector2(260, 56)
	btn.add_theme_font_size_override("font_size", 20)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.90, 0.85, 0.95)
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
	hover.bg_color = Color(0.85, 0.78, 0.92)
	hover.corner_radius_top_left = 12
	hover.corner_radius_top_right = 12
	hover.corner_radius_bottom_left = 12
	hover.corner_radius_bottom_right = 12
	hover.content_margin_left = 16.0
	hover.content_margin_right = 16.0
	hover.content_margin_top = 8.0
	hover.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("hover", hover)

	var response_text: String = prompt_data["response"]
	btn.pressed.connect(func():
		_on_social_response(response_text, btn)
	)

	social_container.add_child(btn)

	feedback_label.text = ""
	turn_label.text = "Say something nice to Sunny!"
	turn_label.add_theme_color_override("font_color", Color(0.55, 0.45, 0.7))
	waiting_for_input = true

	# Auto-advance after a timeout if child doesn't respond
	await get_tree().create_timer(6.0).timeout
	if current_phase == TurnPhase.SOCIAL_PROMPT and waiting_for_input:
		# Child didn't respond
		waiting_for_input = false

		GameManager.record_event("social_response", {
			"round": current_round,
			"prompt": prompt_data["prompt"],
			"responded": false,
		})

		feedback_label.text = "That's okay! Let's keep playing."
		feedback_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		_clear_social_container()

		await get_tree().create_timer(1.0).timeout
		_next_turn()


func _on_social_response(response: String, button: Button) -> void:
	if not waiting_for_input or current_phase != TurnPhase.SOCIAL_PROMPT:
		return
	waiting_for_input = false

	social_responses += 1
	GameManager.score += 5  # Points for social response

	# Style button as confirmed
	var confirmed_style := StyleBoxFlat.new()
	confirmed_style.bg_color = Color(0.7, 1.0, 0.7)
	confirmed_style.corner_radius_top_left = 12
	confirmed_style.corner_radius_top_right = 12
	confirmed_style.corner_radius_bottom_left = 12
	confirmed_style.corner_radius_bottom_right = 12
	button.add_theme_stylebox_override("normal", confirmed_style)
	button.disabled = true

	feedback_label.text = "That was so kind! ☀️ Sunny is happy!"
	feedback_label.add_theme_color_override("font_color", Color(0.2, 0.75, 0.3))

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

	game_hud.update_score(GameManager.score)

	GameManager.record_event("social_response", {
		"round": current_round,
		"response": response,
		"responded": true,
	})

	await get_tree().create_timer(1.5).timeout
	_clear_social_container()
	_next_turn()


func _update_scoreboard() -> void:
	player_score_label.text = "You: %d" % player_dice_score
	sunny_score_label.text = "☀️ Sunny: %d" % sunny_dice_score


func _clear_social_container() -> void:
	for child in social_container.get_children():
		child.queue_free()


func _end_game() -> void:
	waiting_for_input = false
	_wait_active = false
	_roll_animation_active = false
	roll_button.visible = false
	game_hud.stop()

	GameManager.record_event("session_summary", {
		"player_dice_total": player_dice_score,
		"sunny_dice_total": sunny_dice_score,
		"successful_waits": successful_waits,
		"failed_waits": failed_waits,
		"social_responses": social_responses,
		"total_social_prompts": total_social_prompts,
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
