extends Control
## MindReader - Theory of Mind / Perspective-taking therapy game for ASD.
## Presents short stories where one character has a false belief, and the child
## must identify what the character thinks, not what is actually true.
## Based on classic Sally-Anne false-belief tasks adapted as age-appropriate stories.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var round_label: Label = %RoundLabel
@onready var characters_label: Label = %CharactersLabel
@onready var story_label: Label = %StoryLabel
@onready var question_label: Label = %QuestionLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer

const SCENARIOS := [
	{
		"id": 1,
		"characters": ["Sam", "Mom"],
		"character_emojis": ["boy", "woman"],
		"story": "Sam put his toy car in the red box. While Sam was outside playing, Mom moved the car to the blue box.",
		"question": "Where will Sam look for his car?",
		"correct": "In the red box",
		"wrong": ["In the blue box", "Under the bed"],
		"explanation": "Sam doesn't know Mom moved it!",
	},
	{
		"id": 2,
		"characters": ["Lily", "Tom"],
		"character_emojis": ["girl", "boy"],
		"story": "Lily has a cookie in her lunchbox. Tom sees Lily's lunchbox but doesn't open it.",
		"question": "Does Tom know there's a cookie inside?",
		"correct": "No, he can't see inside",
		"wrong": ["Yes, he knows", "Maybe"],
		"explanation": "Tom can only see the outside of the box!",
	},
	{
		"id": 3,
		"characters": ["Buddy the dog", "Emma"],
		"character_emojis": ["dog", "girl"],
		"story": "Emma hides a bone behind the tree. Buddy was sleeping and didn't see her.",
		"question": "Does Buddy know where the bone is?",
		"correct": "No, he was sleeping",
		"wrong": ["Yes, behind the tree", "He'll guess"],
		"explanation": "Buddy was asleep so he didn't see where it went!",
	},
	{
		"id": 4,
		"characters": ["Max", "Zoe"],
		"character_emojis": ["boy", "girl"],
		"story": "Max thinks the box has crayons. But Zoe secretly put stickers in it instead.",
		"question": "What does Max think is in the box?",
		"correct": "Crayons",
		"wrong": ["Stickers", "Nothing", "Toys"],
		"explanation": "Max didn't see Zoe change what's inside!",
	},
	{
		"id": 5,
		"characters": ["Dad", "Ben"],
		"character_emojis": ["man", "boy"],
		"story": "Ben drew a picture for Dad and hid it under Dad's pillow. Dad hasn't gone to bed yet.",
		"question": "Does Dad know about the surprise?",
		"correct": "No, not yet",
		"wrong": ["Yes, he saw it", "Maybe"],
		"explanation": "It's a surprise! Dad hasn't looked under his pillow.",
	},
	{
		"id": 6,
		"characters": ["Mia", "Ana"],
		"character_emojis": ["girl", "girl"],
		"story": "Mia is wearing a costume that makes her look like a cat. Ana hasn't seen Mia put it on.",
		"question": "Who does Ana think she sees?",
		"correct": "A cat",
		"wrong": ["Mia", "A dog"],
		"explanation": "Ana doesn't know it's Mia in a costume!",
	},
	{
		"id": 7,
		"characters": ["Leo", "Teacher"],
		"character_emojis": ["boy", "woman"],
		"story": "Leo knows the answer but the teacher hasn't called on him yet. Leo is raising his hand.",
		"question": "Does the teacher know that Leo knows the answer?",
		"correct": "Not yet, Leo is waiting to be called on",
		"wrong": ["Yes, the teacher knows", "Teachers always know"],
		"explanation": "The teacher can see Leo's hand up but hasn't heard his answer yet!",
	},
	{
		"id": 8,
		"characters": ["Kai", "Sara"],
		"character_emojis": ["boy", "girl"],
		"story": "Kai has a tummy ache but is smiling to be brave. Sara sees Kai smiling.",
		"question": "What does Sara think Kai is feeling?",
		"correct": "Happy, because Kai is smiling",
		"wrong": ["Sick", "Sad", "Angry"],
		"explanation": "Sara can only see Kai's smile, not the tummy ache!",
	},
	{
		"id": 9,
		"characters": ["Nina", "Jake"],
		"character_emojis": ["girl", "boy"],
		"story": "Nina wrapped a book as a birthday present for Jake. The wrapping paper has rockets on it.",
		"question": "What does Jake think is inside?",
		"correct": "He doesn't know yet - it's wrapped!",
		"wrong": ["A book", "A rocket toy"],
		"explanation": "Jake can't see through wrapping paper!",
	},
	{
		"id": 10,
		"characters": ["Whiskers", "Mouse"],
		"character_emojis": ["cat", "mouse"],
		"story": "Mouse hid in a shoebox. Whiskers the cat walked into the room but didn't see Mouse hide.",
		"question": "Does Whiskers know Mouse is in the box?",
		"correct": "No, Whiskers didn't see",
		"wrong": ["Yes, cats always know", "Maybe"],
		"explanation": "Whiskers wasn't looking when Mouse hid!",
	},
	{
		"id": 11,
		"characters": ["Ethan", "Ruby"],
		"character_emojis": ["boy", "girl"],
		"story": "Ethan put juice in a milk carton as a joke. Ruby picks up the milk carton.",
		"question": "What does Ruby think she'll drink?",
		"correct": "Milk",
		"wrong": ["Juice", "Water"],
		"explanation": "Ruby sees a milk carton, so she expects milk!",
	},
	{
		"id": 12,
		"characters": ["Ava", "Noah"],
		"character_emojis": ["girl", "boy"],
		"story": "Ava drew a surprise picture for Noah. She hid it in Noah's backpack when he wasn't looking.",
		"question": "Will Noah be surprised when he finds it?",
		"correct": "Yes, he doesn't know it's there",
		"wrong": ["No, he already knows", "Maybe not"],
		"explanation": "Noah didn't see Ava put it there, so it'll be a surprise!",
	},
	{
		"id": 13,
		"characters": ["Chef", "Ollie"],
		"character_emojis": ["man", "boy"],
		"story": "Chef made chocolate cake but put it in a plain white box. Ollie sees the white box on the table.",
		"question": "Does Ollie know there's cake inside?",
		"correct": "No, he only sees a white box",
		"wrong": ["Yes, he can smell it", "He guesses cake"],
		"explanation": "The box is plain, so Ollie can't tell what's inside!",
	},
	{
		"id": 14,
		"characters": ["Grace", "Finn"],
		"character_emojis": ["girl", "boy"],
		"story": "Grace is planning a surprise party for Finn. She told everyone except Finn.",
		"question": "Does Finn know about the party?",
		"correct": "No, it's a secret from him",
		"wrong": ["Yes, everyone knows", "He probably guessed"],
		"explanation": "Nobody told Finn - that's what makes it a surprise!",
	},
	{
		"id": 15,
		"characters": ["Fox", "Rabbit"],
		"character_emojis": ["fox", "rabbit"],
		"story": "Rabbit buried some carrots near the big rock. Fox was on the other side of the hill.",
		"question": "Can Fox find the carrots easily?",
		"correct": "No, Fox didn't see where they were buried",
		"wrong": ["Yes, near the rock", "Animals always find food"],
		"explanation": "Fox was too far away to see!",
	},
]

# Emoji lookup for character display
const EMOJI_MAP := {
	"boy": "\ud83e\uddd2",
	"girl": "\ud83d\udc67",
	"man": "\ud83d\udc68",
	"woman": "\ud83e\uddd1",
	"dog": "\ud83d\udc36",
	"cat": "\ud83d\udc31",
	"mouse": "\ud83d\udc2d",
	"fox": "\ud83e\udd8a",
	"rabbit": "\ud83d\udc30",
}

const TOTAL_ROUNDS := 10

var current_round: int = 0
var num_choices: int = 3
var selected_scenarios: Array[Dictionary] = []
var current_scenario: Dictionary = {}
var waiting_for_input: bool = false

# Difficulty buckets: easier scenarios (obvious false belief) vs subtle ones
const EASY_IDS := [1, 2, 3, 5, 9, 10, 12, 14]
const SUBTLE_IDS := [4, 6, 7, 8, 11, 13, 15]


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	var level := GameManager.difficulty_level
	if level <= 3:
		num_choices = 3
	elif level <= 6:
		num_choices = 3
	else:
		num_choices = 4


func _start_game() -> void:
	GameManager.start_session("theory_of_mind")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	feedback_label.text = ""
	_select_scenarios()
	_next_round()


func _select_scenarios() -> void:
	selected_scenarios.clear()
	var level := GameManager.difficulty_level

	var pool: Array[Dictionary] = []

	if level <= 3:
		# Prefer easy scenarios
		for s in SCENARIOS:
			if s["id"] in EASY_IDS:
				pool.append(s)
		# Fill with subtle if needed
		for s in SCENARIOS:
			if s["id"] in SUBTLE_IDS and pool.size() < TOTAL_ROUNDS + 5:
				pool.append(s)
	elif level <= 6:
		# Mix of easy and subtle
		for s in SCENARIOS:
			pool.append(s)
	else:
		# Prefer subtle scenarios
		for s in SCENARIOS:
			if s["id"] in SUBTLE_IDS:
				pool.append(s)
		# Fill with easy if needed
		for s in SCENARIOS:
			if s["id"] in EASY_IDS and pool.size() < TOTAL_ROUNDS + 5:
				pool.append(s)

	pool.shuffle()
	for i in range(mini(TOTAL_ROUNDS, pool.size())):
		selected_scenarios.append(pool[i])

	# Ensure we have enough rounds
	while selected_scenarios.size() < TOTAL_ROUNDS:
		pool.shuffle()
		for p in pool:
			if selected_scenarios.size() >= TOTAL_ROUNDS:
				break
			selected_scenarios.append(p)


func _next_round() -> void:
	if current_round >= TOTAL_ROUNDS:
		_end_game()
		return

	current_scenario = selected_scenarios[current_round]
	current_round += 1
	round_label.text = "Round %d / %d" % [current_round, TOTAL_ROUNDS]
	game_hud.update_progress(current_round - 1, TOTAL_ROUNDS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""

	# Display characters
	var char_names: Array = current_scenario["characters"]
	var char_emojis: Array = current_scenario["character_emojis"]
	var char_display := ""
	for i in range(char_names.size()):
		var emoji_key: String = char_emojis[i]
		var emoji_char: String = EMOJI_MAP.get(emoji_key, "\ud83e\uddd1")
		if i > 0:
			char_display += "   &   "
		char_display += "%s %s" % [emoji_char, char_names[i]]
	characters_label.text = char_display

	# Display story
	story_label.text = current_scenario["story"]

	# Display question
	question_label.text = current_scenario["question"]

	# Build choice buttons
	_build_choices()

	waiting_for_input = true

	GameManager.record_event("story_shown", {
		"scenario_id": current_scenario["id"],
		"characters": current_scenario["characters"],
	})


func _build_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()

	# Build answer set: correct + wrong answers
	var answers: Array[String] = [current_scenario["correct"]]
	var wrong: Array = current_scenario["wrong"]
	for w in wrong:
		if answers.size() < num_choices:
			answers.append(w)

	# Trim to num_choices if needed
	while answers.size() > num_choices:
		answers.pop_back()

	# Shuffle so correct answer is not always first
	var shuffled: Array[String] = []
	for a in answers:
		shuffled.append(a)
	shuffled.shuffle()

	for choice in shuffled:
		var btn := Button.new()
		btn.text = choice
		btn.custom_minimum_size = Vector2(300, 60)
		btn.add_theme_font_size_override("font_size", 20)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.95, 0.95, 1.0)
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
		hover.bg_color = Color(0.88, 0.88, 0.96)
		hover.corner_radius_top_left = 12
		hover.corner_radius_top_right = 12
		hover.corner_radius_bottom_left = 12
		hover.corner_radius_bottom_right = 12
		hover.content_margin_left = 16.0
		hover.content_margin_right = 16.0
		hover.content_margin_top = 10.0
		hover.content_margin_bottom = 10.0
		btn.add_theme_stylebox_override("hover", hover)

		var answer_text: String = choice
		btn.pressed.connect(func():
			_on_choice_selected(answer_text, btn)
		)

		choices_container.add_child(btn)


func _on_choice_selected(answer: String, button: Button) -> void:
	if not waiting_for_input:
		return
	waiting_for_input = false

	var is_correct := answer == current_scenario["correct"]
	GameManager.record_answer(is_correct)

	GameManager.record_event("answer_given", {
		"scenario_id": current_scenario["id"],
		"correct": is_correct,
		"answer": answer,
		"expected": current_scenario["correct"],
	})

	# Disable all choice buttons
	for btn in choices_container.get_children():
		if btn is Button:
			btn.disabled = true

	var explanation: String = current_scenario["explanation"]

	if is_correct:
		feedback_label.text = "That's right! %s" % explanation
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.3))

		var correct_style := StyleBoxFlat.new()
		correct_style.bg_color = Color(0.7, 1.0, 0.7)
		correct_style.corner_radius_top_left = 12
		correct_style.corner_radius_top_right = 12
		correct_style.corner_radius_bottom_left = 12
		correct_style.corner_radius_bottom_right = 12
		correct_style.content_margin_left = 16.0
		correct_style.content_margin_right = 16.0
		correct_style.content_margin_top = 10.0
		correct_style.content_margin_bottom = 10.0
		button.add_theme_stylebox_override("disabled", correct_style)
	else:
		feedback_label.text = "Not quite. %s" % explanation
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

		# Mark the pressed button red
		var wrong_style := StyleBoxFlat.new()
		wrong_style.bg_color = Color(1.0, 0.7, 0.7)
		wrong_style.corner_radius_top_left = 12
		wrong_style.corner_radius_top_right = 12
		wrong_style.corner_radius_bottom_left = 12
		wrong_style.corner_radius_bottom_right = 12
		wrong_style.content_margin_left = 16.0
		wrong_style.content_margin_right = 16.0
		wrong_style.content_margin_top = 10.0
		wrong_style.content_margin_bottom = 10.0
		button.add_theme_stylebox_override("disabled", wrong_style)

		# Highlight the correct answer green
		for btn in choices_container.get_children():
			if btn is Button and btn.text == current_scenario["correct"]:
				var hint_style := StyleBoxFlat.new()
				hint_style.bg_color = Color(0.7, 1.0, 0.7)
				hint_style.corner_radius_top_left = 12
				hint_style.corner_radius_top_right = 12
				hint_style.corner_radius_bottom_left = 12
				hint_style.corner_radius_bottom_right = 12
				hint_style.content_margin_left = 16.0
				hint_style.content_margin_right = 16.0
				hint_style.content_margin_top = 10.0
				hint_style.content_margin_bottom = 10.0
				btn.add_theme_stylebox_override("disabled", hint_style)

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
