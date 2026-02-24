extends Control
## SocialStories - Social scenario navigation game for ASD therapy.
## Presents social situations and asks the child to choose the best response.
## Teaches greetings, sharing, turn-taking, empathy, and social conventions.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var round_label: Label = %RoundLabel
@onready var scenario_emoji: Label = %ScenarioEmoji
@onready var scenario_text: Label = %ScenarioText
@onready var feedback_label: Label = %FeedbackLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer

const SCENARIOS := [
	{
		"id": 1,
		"emoji": "\ud83c\udfeb",
		"scenario": "You arrive at school. Your friend waves at you.",
		"choices": [
			{"text": "Wave back and say hi!", "quality": "best", "feedback": "Waving and saying hi shows you are happy to see your friend."},
			{"text": "Smile at them", "quality": "ok", "feedback": "A smile is nice, but saying hi too makes your friend feel even more welcome."},
			{"text": "Ignore them", "quality": "poor", "feedback": "Ignoring a friend can hurt their feelings. Try waving back next time!"},
		],
	},
	{
		"id": 2,
		"emoji": "\ud83e\uddf8",
		"scenario": "Another child is playing with a toy you want.",
		"choices": [
			{"text": "Ask 'Can I play when you're done?'", "quality": "best", "feedback": "Asking politely shows respect and patience. Great job!"},
			{"text": "Wait quietly nearby", "quality": "ok", "feedback": "Waiting is patient, but asking lets them know you'd like a turn."},
			{"text": "Take the toy", "quality": "poor", "feedback": "Taking things without asking is not kind. Try asking first!"},
		],
	},
	{
		"id": 3,
		"emoji": "\ud83c\udf4e",
		"scenario": "A friend shares their snack with you.",
		"choices": [
			{"text": "Say 'Thank you! That's kind of you'", "quality": "best", "feedback": "Saying thank you and recognizing their kindness is wonderful!"},
			{"text": "Take it and smile", "quality": "ok", "feedback": "Smiling is nice, but saying thank you makes your friend feel appreciated."},
			{"text": "Say nothing", "quality": "poor", "feedback": "When someone shares, it is important to say thank you."},
		],
	},
	{
		"id": 4,
		"emoji": "\ud83d\ude22",
		"scenario": "Your friend falls down and is crying.",
		"choices": [
			{"text": "Ask 'Are you okay? Let me help'", "quality": "best", "feedback": "Checking on your friend and offering help shows you care about them."},
			{"text": "Tell a teacher", "quality": "ok", "feedback": "Getting help from a teacher is good, but also checking on your friend first is even better."},
			{"text": "Walk away", "quality": "poor", "feedback": "Walking away when a friend is hurt can make them feel alone. Try helping next time!"},
		],
	},
	{
		"id": 5,
		"emoji": "\ud83c\udfa8",
		"scenario": "You want to use the red crayon but someone has it.",
		"choices": [
			{"text": "Ask 'May I use it when you're done?'", "quality": "best", "feedback": "Asking politely and waiting your turn is the best approach!"},
			{"text": "Use a different color", "quality": "ok", "feedback": "Being flexible is good! You could also politely ask to use it after."},
			{"text": "Grab it", "quality": "poor", "feedback": "Grabbing things from others is not respectful. Try asking nicely!"},
		],
	},
	{
		"id": 6,
		"emoji": "\ud83d\udead",
		"scenario": "Someone holds the door open for you.",
		"choices": [
			{"text": "Say 'Thank you!'", "quality": "best", "feedback": "Saying thank you when someone helps you is always the right thing to do!"},
			{"text": "Smile and walk through", "quality": "ok", "feedback": "A smile is nice, but saying thank you is even better."},
			{"text": "Walk through without looking", "quality": "poor", "feedback": "When someone helps you, it is polite to notice and thank them."},
		],
	},
	{
		"id": 7,
		"emoji": "\ud83c\udf82",
		"scenario": "It's your friend's birthday party.",
		"choices": [
			{"text": "Say 'Happy birthday!' and give a hug", "quality": "best", "feedback": "Celebrating your friend's special day makes them feel loved!"},
			{"text": "Say happy birthday", "quality": "ok", "feedback": "Saying happy birthday is great! A hug or card makes it extra special."},
			{"text": "Ask when you get cake", "quality": "poor", "feedback": "The party is about your friend. Wish them happy birthday first!"},
		],
	},
	{
		"id": 8,
		"emoji": "\ud83e\udd1d",
		"scenario": "A new student joins your class.",
		"choices": [
			{"text": "Say 'Hi! Want to sit with me?'", "quality": "best", "feedback": "Welcoming a new person and including them is very kind and brave!"},
			{"text": "Wave at them", "quality": "ok", "feedback": "Waving is friendly! Talking to them and including them would be even better."},
			{"text": "Ignore them", "quality": "poor", "feedback": "New students can feel scared. Being friendly helps them feel welcome."},
		],
	},
	{
		"id": 9,
		"emoji": "\ud83c\udfae",
		"scenario": "You and a friend both want to go first in a game.",
		"choices": [
			{"text": "Say 'You can go first, I'll go next'", "quality": "best", "feedback": "Letting others go first shows kindness and good sportsmanship!"},
			{"text": "Suggest taking turns", "quality": "ok", "feedback": "Suggesting turns is fair! Letting your friend go first is extra generous."},
			{"text": "Insist on going first", "quality": "poor", "feedback": "Insisting on going first is not fair. Taking turns is important!"},
		],
	},
	{
		"id": 10,
		"emoji": "\ud83d\udcda",
		"scenario": "Your teacher asks the class a question you know.",
		"choices": [
			{"text": "Raise your hand and wait", "quality": "best", "feedback": "Raising your hand and waiting shows great self-control and respect!"},
			{"text": "Wait for the teacher to call on you", "quality": "ok", "feedback": "Waiting is good! Raising your hand helps the teacher see you know the answer."},
			{"text": "Shout out the answer", "quality": "poor", "feedback": "Shouting out does not give others a chance. Raise your hand instead!"},
		],
	},
	{
		"id": 11,
		"emoji": "\ud83c\udfe0",
		"scenario": "A friend invites you to play but you're tired.",
		"choices": [
			{"text": "Say 'Thanks for asking! Can we play tomorrow?'", "quality": "best", "feedback": "Thanking them and suggesting another time keeps the friendship strong!"},
			{"text": "Say 'Not today'", "quality": "ok", "feedback": "It is okay to say no, but thanking them and suggesting another time is even better."},
			{"text": "Say nothing and leave", "quality": "poor", "feedback": "Leaving without saying anything can confuse your friend. Use your words!"},
		],
	},
	{
		"id": 12,
		"emoji": "\ud83e\udde9",
		"scenario": "You're working on a puzzle and someone wants to help.",
		"choices": [
			{"text": "Say 'Sure! You can do this part'", "quality": "best", "feedback": "Working together and sharing tasks is a wonderful way to be a friend!"},
			{"text": "Let them watch", "quality": "ok", "feedback": "Letting them watch is okay, but working together is more fun for everyone!"},
			{"text": "Say 'Go away'", "quality": "poor", "feedback": "Saying 'go away' can hurt feelings. Try including others when you can."},
		],
	},
	{
		"id": 13,
		"emoji": "\u2602\ufe0f",
		"scenario": "It's raining and your friend forgot their umbrella.",
		"choices": [
			{"text": "Offer to share your umbrella", "quality": "best", "feedback": "Sharing your umbrella shows you care about your friend!"},
			{"text": "Tell them to hurry inside", "quality": "ok", "feedback": "Helping them get inside is thoughtful! Sharing your umbrella is even better."},
			{"text": "Laugh at them", "quality": "poor", "feedback": "Laughing at someone's problem is hurtful. Try helping instead!"},
		],
	},
	{
		"id": 14,
		"emoji": "\ud83c\udfb5",
		"scenario": "Someone is singing off-key during music class.",
		"choices": [
			{"text": "Keep singing your best", "quality": "best", "feedback": "Focusing on your own singing and being kind is the best choice!"},
			{"text": "Don't say anything", "quality": "ok", "feedback": "Staying quiet is respectful. Keep doing your own best work!"},
			{"text": "Tell them they sound bad", "quality": "poor", "feedback": "Criticizing others can be very hurtful. Everyone is learning and trying their best."},
		],
	},
	{
		"id": 15,
		"emoji": "\ud83d\udc15",
		"scenario": "Your friend is scared of a dog at the park.",
		"choices": [
			{"text": "Say 'It's okay, I'll stay with you'", "quality": "best", "feedback": "Being supportive and staying close makes your friend feel safe and cared for!"},
			{"text": "Suggest walking the other way", "quality": "ok", "feedback": "Avoiding the dog helps, but staying with your friend gives them even more comfort."},
			{"text": "Say 'Don't be silly'", "quality": "poor", "feedback": "Everyone has fears. Calling them silly can hurt their feelings. Be supportive!"},
		],
	},
]

const TOTAL_ROUNDS := 10

var current_round: int = 0
var selected_scenarios: Array[Dictionary] = []
var current_scenario: Dictionary = {}
var waiting_for_input: bool = false


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	# Difficulty affects which scenarios are shown (easy vs nuanced)
	# and whether feedback is shown immediately
	pass


func _start_game() -> void:
	GameManager.start_session("social_skills")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	feedback_label.text = ""
	_select_scenarios()
	_next_round()


func _select_scenarios() -> void:
	selected_scenarios.clear()
	var pool: Array[Dictionary] = []
	for s in SCENARIOS:
		pool.append(s)
	pool.shuffle()
	for i in range(mini(TOTAL_ROUNDS, pool.size())):
		selected_scenarios.append(pool[i])


func _next_round() -> void:
	if current_round >= TOTAL_ROUNDS:
		_end_game()
		return

	current_scenario = selected_scenarios[current_round]
	current_round += 1
	round_label.text = "Scenario %d / %d" % [current_round, TOTAL_ROUNDS]
	game_hud.update_progress(current_round - 1, TOTAL_ROUNDS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""

	# Display scenario
	scenario_emoji.text = current_scenario["emoji"]
	scenario_text.text = current_scenario["scenario"]

	# Build choice buttons
	_build_choices()

	waiting_for_input = true

	GameManager.record_event("scenario_shown", {
		"scenario_id": current_scenario["id"],
		"scenario": current_scenario["scenario"],
	})


func _build_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()

	var choices: Array = current_scenario["choices"]
	# Shuffle a copy so button order varies
	var shuffled: Array = choices.duplicate()
	shuffled.shuffle()

	for choice in shuffled:
		var btn := Button.new()
		btn.text = choice["text"]
		btn.custom_minimum_size = Vector2(0, 56)
		btn.add_theme_font_size_override("font_size", 18)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.95, 0.93, 0.90)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.content_margin_left = 16.0
		style.content_margin_right = 16.0
		style.content_margin_top = 10.0
		style.content_margin_bottom = 10.0
		btn.add_theme_stylebox_override("normal", style)

		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.90, 0.88, 0.85)
		hover.corner_radius_top_left = 12
		hover.corner_radius_top_right = 12
		hover.corner_radius_bottom_left = 12
		hover.corner_radius_bottom_right = 12
		hover.content_margin_left = 16.0
		hover.content_margin_right = 16.0
		hover.content_margin_top = 10.0
		hover.content_margin_bottom = 10.0
		btn.add_theme_stylebox_override("hover", hover)

		var choice_data: Dictionary = choice
		btn.pressed.connect(func():
			_on_choice_selected(choice_data, btn)
		)

		choices_container.add_child(btn)


func _on_choice_selected(choice: Dictionary, button: Button) -> void:
	if not waiting_for_input:
		return
	waiting_for_input = false

	var quality: String = choice["quality"]
	var feedback: String = choice["feedback"]
	var points: int = 0
	var is_correct: bool = false

	match quality:
		"best":
			points = 10
			is_correct = true
		"ok":
			points = 5
			is_correct = true
		"poor":
			points = 0
			is_correct = false

	# Record the answer - only "best" counts as fully correct for GameManager
	GameManager.record_answer(quality == "best")
	if quality == "ok":
		GameManager.score += 5  # Manual adjustment for partial credit

	GameManager.record_event("choice_made", {
		"scenario_id": current_scenario["id"],
		"choice": choice["text"],
		"quality": quality,
		"feedback": feedback,
	})

	# Disable all buttons
	for btn in choices_container.get_children():
		if btn is Button:
			btn.disabled = true

	# Style the pressed button
	var pressed_style := StyleBoxFlat.new()
	pressed_style.corner_radius_top_left = 12
	pressed_style.corner_radius_top_right = 12
	pressed_style.corner_radius_bottom_left = 12
	pressed_style.corner_radius_bottom_right = 12
	pressed_style.content_margin_left = 16.0
	pressed_style.content_margin_right = 16.0
	pressed_style.content_margin_top = 10.0
	pressed_style.content_margin_bottom = 10.0

	match quality:
		"best":
			pressed_style.bg_color = Color(0.7, 1.0, 0.7)
		"ok":
			pressed_style.bg_color = Color(1.0, 0.95, 0.7)
		"poor":
			pressed_style.bg_color = Color(1.0, 0.7, 0.7)

	button.add_theme_stylebox_override("disabled", pressed_style)

	# If not best, highlight the best answer
	if quality != "best":
		var best_text := ""
		for c in current_scenario["choices"]:
			if c["quality"] == "best":
				best_text = c["text"]
				break
		for btn in choices_container.get_children():
			if btn is Button and btn.text == best_text:
				var best_style := StyleBoxFlat.new()
				best_style.bg_color = Color(0.7, 1.0, 0.7)
				best_style.corner_radius_top_left = 12
				best_style.corner_radius_top_right = 12
				best_style.corner_radius_bottom_left = 12
				best_style.corner_radius_bottom_right = 12
				best_style.content_margin_left = 16.0
				best_style.content_margin_right = 16.0
				best_style.content_margin_top = 10.0
				best_style.content_margin_bottom = 10.0
				btn.add_theme_stylebox_override("disabled", best_style)

	# Show feedback
	feedback_label.text = feedback
	if quality == "best":
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.3))
	elif quality == "ok":
		feedback_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.2))
	else:
		feedback_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

	game_hud.update_score(GameManager.score)

	await get_tree().create_timer(2.5).timeout
	_next_round()


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
