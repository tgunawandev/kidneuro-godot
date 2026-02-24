extends Control
## ChatBuilder - Pragmatic language / conversation skills therapy game for ASD.
## Presents a chat-like UI with a virtual character "Sunny" who sends messages.
## The child picks the best conversational response from 3-4 options.
## Evaluates: on-topic relevance, social appropriateness, conversation-extending quality.
## Based on 5 conversation threads of 3 exchanges each (15 total exchanges).

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var round_label: Label = %RoundLabel
@onready var chat_scroll: ScrollContainer = %ChatScrollContainer
@onready var chat_vbox: VBoxContainer = %ChatVBox
@onready var feedback_label: Label = %FeedbackLabel
@onready var responses_container: VBoxContainer = %ResponsesContainer

# Each exchange: sunny_message, options with {text, quality, feedback}
# quality: "best" (+10, correct), "ok" (+5, correct), "poor" (0, incorrect), "bad" (-5, incorrect)
const THREADS := [
	# Thread 1 - Talking about pets
	{
		"id": "pets",
		"exchanges": [
			{
				"sunny": "I have a pet hamster named Peanut! \ud83d\udc39",
				"options": [
					{"text": "That's a cool name! What does Peanut look like?", "quality": "best", "feedback": "Great response! You showed interest and kept the conversation going!"},
					{"text": "I like hamsters too", "quality": "ok", "feedback": "That's a nice reply! Next time, try asking a question to keep chatting."},
					{"text": "I had pizza for lunch", "quality": "poor", "feedback": "That changed the subject. When someone tells you something, try to respond about the same topic."},
					{"text": "Hamsters are boring", "quality": "bad", "feedback": "That might hurt your friend's feelings. Try saying something kind about what they shared."},
				],
			},
			{
				"sunny": "Peanut is golden brown and super fluffy!",
				"options": [
					{"text": "Does Peanut do any funny tricks?", "quality": "best", "feedback": "Awesome! Asking questions shows you're interested in what your friend is saying!"},
					{"text": "That sounds cute!", "quality": "ok", "feedback": "Nice! That's a kind thing to say. You could also ask a question to learn more."},
					{"text": "My shoes are brown too", "quality": "poor", "feedback": "That's a bit off-topic. Try to keep talking about what your friend mentioned."},
				],
			},
			{
				"sunny": "Yes! Peanut runs on a wheel really fast at night!",
				"options": [
					{"text": "Ha! That must be noisy. Do you keep Peanut in your room?", "quality": "best", "feedback": "Great job! You showed you were listening and asked a follow-up question!"},
					{"text": "That's funny!", "quality": "ok", "feedback": "Nice reaction! You could add a question to keep the chat going longer."},
					{"text": "I want to talk about something else", "quality": "poor", "feedback": "It's better to let a conversation end naturally. Try adding to what your friend said instead."},
				],
			},
		],
	},
	# Thread 2 - Weekend plans
	{
		"id": "weekend",
		"exchanges": [
			{
				"sunny": "What did you do this weekend? \ud83c\udf89",
				"options": [
					{"text": "I went to the park! What about you?", "quality": "best", "feedback": "Perfect! You answered AND asked back. That's how great conversations work!"},
					{"text": "Nothing much", "quality": "ok", "feedback": "That's okay, but try to share a little more and ask your friend about their weekend too."},
					{"text": "I don't like weekends", "quality": "poor", "feedback": "When someone asks about your weekend, try to share something you did, even if it was small."},
					{"text": "That's none of your business", "quality": "bad", "feedback": "That might sound rude. Friends like to know about each other's lives. Try sharing something fun!"},
				],
			},
			{
				"sunny": "I went to my grandma's house! She baked cookies \ud83c\udf6a",
				"options": [
					{"text": "Yum! What kind of cookies did she make?", "quality": "best", "feedback": "Wonderful! You showed excitement and asked a great follow-up question!"},
					{"text": "That sounds nice", "quality": "ok", "feedback": "That's polite! You could make it even better by asking about the cookies."},
					{"text": "I'm better at baking than your grandma", "quality": "poor", "feedback": "Comparing yourself might not feel good to your friend. Try celebrating what they shared instead."},
				],
			},
			{
				"sunny": "Chocolate chip! They were so good!",
				"options": [
					{"text": "Chocolate chip is great! I like those too!", "quality": "best", "feedback": "You found something in common! Sharing what you both like makes friendships stronger!"},
					{"text": "Nice!", "quality": "ok", "feedback": "Short but sweet! You could add what your favorite cookie is too."},
					{"text": "Cookies make you fat", "quality": "poor", "feedback": "That might make your friend feel bad. When someone shares something happy, try to be positive!"},
				],
			},
		],
	},
	# Thread 3 - Favorite things
	{
		"id": "favorites",
		"exchanges": [
			{
				"sunny": "What's your favorite color? Mine is purple! \ud83d\udc9c",
				"options": [
					{"text": "I like blue! Why is purple your favorite?", "quality": "best", "feedback": "You shared your answer AND asked about theirs. That's excellent conversation skills!"},
					{"text": "Blue", "quality": "ok", "feedback": "You answered the question! Try adding a question back to keep the conversation flowing."},
					{"text": "Colors are dumb", "quality": "poor", "feedback": "That might seem dismissive. Even if you're not excited about colors, try to stay positive in conversations."},
				],
			},
			{
				"sunny": "I like purple because it reminds me of flowers! \ud83c\udf38",
				"options": [
					{"text": "That's a nice reason! Flowers are pretty", "quality": "best", "feedback": "You validated your friend's feelings. That makes people feel heard and happy!"},
					{"text": "Oh, cool", "quality": "ok", "feedback": "That works! You could make your friend feel even better by saying something nice about their reason."},
					{"text": "Purple is the worst color", "quality": "poor", "feedback": "That might hurt feelings. It's okay to have different favorites, but try to be respectful about it."},
				],
			},
			{
				"sunny": "Do you like flowers too?",
				"options": [
					{"text": "Yes! I really like sunflowers because they're big and bright", "quality": "best", "feedback": "You gave a detailed answer with a reason! That helps your friend know you better!"},
					{"text": "Yes, some of them", "quality": "ok", "feedback": "Good answer! Adding which flowers you like would make the conversation more interesting."},
					{"text": "Stop asking me questions", "quality": "poor", "feedback": "Questions are how friends learn about each other. It's nice when someone wants to know more about you!"},
				],
			},
		],
	},
	# Thread 4 - School
	{
		"id": "school",
		"exchanges": [
			{
				"sunny": "I learned about dinosaurs in school today! \ud83e\udd95",
				"options": [
					{"text": "Wow, dinosaurs are amazing! Which one is your favorite?", "quality": "best", "feedback": "You showed enthusiasm and asked a great question! That keeps conversations fun!"},
					{"text": "That's cool", "quality": "ok", "feedback": "Nice response! Adding a question would make it even better."},
					{"text": "School is dumb", "quality": "poor", "feedback": "Your friend is excited about what they learned. Try matching their energy!"},
				],
			},
			{
				"sunny": "I like T-Rex because it was so big and strong!",
				"options": [
					{"text": "T-Rex is awesome! Did you know it had tiny arms?", "quality": "best", "feedback": "Sharing a fun fact keeps the conversation interesting! Great conversation skill!"},
					{"text": "That's a good one", "quality": "ok", "feedback": "Supportive response! Try adding something you know about dinosaurs too."},
					{"text": "T-Rex isn't even real anymore", "quality": "poor", "feedback": "That might feel dismissive. When someone shares what they like, try to be positive about it."},
				],
			},
			{
				"sunny": "Haha, yes! Tiny arms but big teeth! \ud83d\ude04",
				"options": [
					{"text": "That's funny! I want to learn more about dinosaurs too", "quality": "best", "feedback": "Showing shared interest is a great way to bond with friends!"},
					{"text": "Yeah", "quality": "ok", "feedback": "Brief but okay! Adding more shows your friend you're enjoying the chat."},
					{"text": "Whatever", "quality": "poor", "feedback": "That sounds like you don't care. Your friend might feel bad. Try showing interest!"},
				],
			},
		],
	},
	# Thread 5 - Feelings
	{
		"id": "feelings",
		"exchanges": [
			{
				"sunny": "I'm feeling a little nervous about my test tomorrow \ud83d\ude1f",
				"options": [
					{"text": "I understand that feeling. What subject is it?", "quality": "best", "feedback": "You showed empathy! Understanding how others feel is a superpower!"},
					{"text": "You'll be fine", "quality": "ok", "feedback": "That's reassuring, but also try to acknowledge their feeling first."},
					{"text": "Tests are easy, why are you nervous?", "quality": "poor", "feedback": "That might make your friend feel worse. Everyone finds different things hard. Try being understanding."},
				],
			},
			{
				"sunny": "It's a math test. I'm not great at fractions.",
				"options": [
					{"text": "Fractions can be tricky! Maybe practicing tonight will help?", "quality": "best", "feedback": "You validated their struggle AND offered a helpful suggestion! That's being a great friend!"},
					{"text": "Good luck", "quality": "ok", "feedback": "Kind words! You could also show you understand by saying fractions are hard sometimes."},
					{"text": "I'm great at math", "quality": "poor", "feedback": "When a friend shares a struggle, focus on them, not yourself. Try being supportive instead."},
				],
			},
			{
				"sunny": "You're right, I'll study tonight. Thanks for listening! \ud83d\ude0a",
				"options": [
					{"text": "You're welcome! You'll do great, I believe in you!", "quality": "best", "feedback": "Encouraging words make friends feel supported. You're an amazing conversation partner!"},
					{"text": "No problem", "quality": "ok", "feedback": "Casual and friendly! Adding some encouragement would make it even better."},
					{"text": "You should have studied earlier", "quality": "poor", "feedback": "That sounds critical. When someone thanks you, a kind response keeps the friendship strong."},
				],
			},
		],
	},
]

# Score values for each quality level
const SCORE_MAP := {
	"best": 10,
	"ok": 5,
	"poor": 0,
	"bad": -5,
}

const TOTAL_ROUNDS := 10

var current_round: int = 0
var selected_exchanges: Array[Dictionary] = []
var current_exchange: Dictionary = {}
var current_thread_id: String = ""
var num_choices: int = 3
var waiting_for_input: bool = false


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
	GameManager.start_session("pragmatic_language")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_ROUNDS)
	current_round = 0
	feedback_label.text = ""
	_clear_chat()
	_clear_responses()
	_select_exchanges()
	_next_round()


func _select_exchanges() -> void:
	selected_exchanges.clear()
	var level := GameManager.difficulty_level

	# Pick 3-4 random threads, then use their exchanges in order
	var thread_pool: Array[Dictionary] = []
	for t in THREADS:
		thread_pool.append(t)
	thread_pool.shuffle()

	# Select enough threads to fill TOTAL_ROUNDS (~10 rounds from 3-4 threads of 3 exchanges)
	var threads_needed: int = ceili(float(TOTAL_ROUNDS) / 3.0)
	threads_needed = mini(threads_needed, thread_pool.size())

	for i in range(threads_needed):
		var thread: Dictionary = thread_pool[i]
		var exchanges: Array = thread["exchanges"]
		for exchange in exchanges:
			if selected_exchanges.size() < TOTAL_ROUNDS:
				var entry := {
					"thread_id": thread["id"],
					"sunny": exchange["sunny"],
					"options": exchange["options"],
				}
				selected_exchanges.append(entry)

	# If we still need more, pull from remaining threads
	while selected_exchanges.size() < TOTAL_ROUNDS:
		for t in thread_pool:
			var exchanges: Array = t["exchanges"]
			for exchange in exchanges:
				if selected_exchanges.size() < TOTAL_ROUNDS:
					var entry := {
						"thread_id": t["id"],
						"sunny": exchange["sunny"],
						"options": exchange["options"],
					}
					selected_exchanges.append(entry)
				if selected_exchanges.size() >= TOTAL_ROUNDS:
					break
			if selected_exchanges.size() >= TOTAL_ROUNDS:
				break


func _next_round() -> void:
	if current_round >= TOTAL_ROUNDS:
		_end_game()
		return

	current_exchange = selected_exchanges[current_round]
	current_thread_id = current_exchange["thread_id"]
	current_round += 1
	round_label.text = "Exchange %d / %d" % [current_round, TOTAL_ROUNDS]
	game_hud.update_progress(current_round - 1, TOTAL_ROUNDS)
	game_hud.update_score(GameManager.score)
	feedback_label.text = ""
	_clear_responses()

	# Add Sunny's message bubble to the chat
	_add_sunny_bubble(current_exchange["sunny"])

	# Scroll to bottom
	await get_tree().process_frame
	await get_tree().process_frame
	chat_scroll.scroll_vertical = int(chat_scroll.get_v_scroll_bar().max_value)

	GameManager.record_event("message_shown", {
		"thread": current_thread_id,
		"exchange": current_round,
		"sunny_message": current_exchange["sunny"],
	})

	# Brief delay before showing response options
	await get_tree().create_timer(0.8).timeout

	# Build response buttons
	_build_responses()
	waiting_for_input = true


func _add_sunny_bubble(message: String) -> void:
	var bubble_hbox := HBoxContainer.new()
	bubble_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Sunny avatar
	var avatar := Label.new()
	avatar.text = "\u2600\ufe0f"
	avatar.add_theme_font_size_override("font_size", 36)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bubble_hbox.add_child(avatar)

	# Message panel
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 0.97, 0.85)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.content_margin_left = 14.0
	panel_style.content_margin_right = 14.0
	panel_style.content_margin_top = 10.0
	panel_style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", panel_style)

	var msg_label := Label.new()
	msg_label.text = message
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.add_theme_color_override("font_color", Color(0.25, 0.25, 0.3))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(msg_label)

	bubble_hbox.add_child(panel)

	# Spacer on right to keep bubble on the left side
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(60, 0)
	bubble_hbox.add_child(spacer)

	chat_vbox.add_child(bubble_hbox)

	# Animate in
	if not AccessibilityManager.reduce_motion:
		bubble_hbox.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(bubble_hbox, "modulate:a", 1.0, 0.3)


func _add_child_bubble(message: String, color: Color) -> void:
	var bubble_hbox := HBoxContainer.new()
	bubble_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Spacer on left to keep bubble on the right side
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(60, 0)
	bubble_hbox.add_child(spacer)

	# Message panel
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.content_margin_left = 14.0
	panel_style.content_margin_right = 14.0
	panel_style.content_margin_top = 10.0
	panel_style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", panel_style)

	var msg_label := Label.new()
	msg_label.text = message
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.25))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(msg_label)

	bubble_hbox.add_child(panel)

	chat_vbox.add_child(bubble_hbox)

	# Animate in
	if not AccessibilityManager.reduce_motion:
		bubble_hbox.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(bubble_hbox, "modulate:a", 1.0, 0.2)


func _build_responses() -> void:
	_clear_responses()

	var options: Array = current_exchange["options"]
	var level := GameManager.difficulty_level

	# Filter options based on difficulty
	var available: Array[Dictionary] = []
	for opt in options:
		available.append(opt)

	# Easy: exclude "bad" options, limit to 3
	if level <= 3:
		var filtered: Array[Dictionary] = []
		for opt in available:
			if opt["quality"] != "bad":
				filtered.append(opt)
		available = filtered

	# Trim to num_choices
	while available.size() > num_choices:
		# Remove the worst-quality option first
		var worst_idx := -1
		var worst_priority := 999
		var priority_map := {"bad": 0, "poor": 1, "ok": 2, "best": 3}
		for i in range(available.size()):
			var p: int = priority_map.get(available[i]["quality"], 2)
			if p < worst_priority:
				worst_priority = p
				worst_idx = i
		if worst_idx >= 0:
			available.remove_at(worst_idx)

	# Ensure we always keep the best option
	var has_best := false
	for opt in available:
		if opt["quality"] == "best":
			has_best = true
			break
	if not has_best:
		# Swap in the best option
		for opt in options:
			if opt["quality"] == "best":
				if available.size() >= num_choices:
					available[available.size() - 1] = opt
				else:
					available.append(opt)
				break

	# Shuffle so best answer is not always in the same position
	available.shuffle()

	for opt in available:
		var btn := Button.new()
		btn.text = opt["text"]
		btn.custom_minimum_size = Vector2(300, 80)
		btn.add_theme_font_size_override("font_size", 18)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var style := StyleBoxFlat.new()
		style.bg_color = Color(1.0, 1.0, 1.0)
		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 14
		style.corner_radius_bottom_left = 14
		style.corner_radius_bottom_right = 14
		style.content_margin_left = 16.0
		style.content_margin_right = 16.0
		style.content_margin_top = 10.0
		style.content_margin_bottom = 10.0
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = Color(0.82, 0.88, 0.95)
		btn.add_theme_stylebox_override("normal", style)

		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.93, 0.96, 1.0)
		hover.corner_radius_top_left = 14
		hover.corner_radius_top_right = 14
		hover.corner_radius_bottom_left = 14
		hover.corner_radius_bottom_right = 14
		hover.content_margin_left = 16.0
		hover.content_margin_right = 16.0
		hover.content_margin_top = 10.0
		hover.content_margin_bottom = 10.0
		hover.border_width_top = 2
		hover.border_width_bottom = 2
		hover.border_width_left = 2
		hover.border_width_right = 2
		hover.border_color = Color(0.6, 0.75, 0.9)
		btn.add_theme_stylebox_override("hover", hover)

		btn.add_theme_color_override("font_color", Color(0.2, 0.25, 0.35))

		var option_data: Dictionary = opt
		btn.pressed.connect(func():
			_on_response_selected(option_data, btn)
		)

		responses_container.add_child(btn)


func _on_response_selected(option: Dictionary, button: Button) -> void:
	if not waiting_for_input:
		return
	waiting_for_input = false

	var quality: String = option["quality"]
	var feedback_text: String = option["feedback"]
	var is_correct := quality == "best" or quality == "ok"
	var score_value: int = SCORE_MAP[quality]

	# Record answer (best and ok count as correct)
	GameManager.record_answer(is_correct)

	# Apply score adjustment: record_answer gives +10*level for correct.
	# We want: best=+10, ok=+5, poor=0, bad=-5 (base, before difficulty scaling)
	# record_answer already gave +10*level if correct, so we adjust.
	if is_correct:
		# record_answer added 10*level; we want score_value*level
		var adjustment: int = (score_value - 10) * GameManager.difficulty_level
		GameManager.score = maxi(GameManager.score + adjustment, 0)
	else:
		# record_answer added 0; we want score_value (negative or zero)
		GameManager.score = maxi(GameManager.score + score_value, 0)

	GameManager.record_event("response_chosen", {
		"response": option["text"],
		"quality": quality,
		"thread": current_thread_id,
	})

	# Disable all response buttons
	for btn in responses_container.get_children():
		if btn is Button:
			btn.disabled = true

	# Color the selected button based on quality
	var selected_color: Color
	match quality:
		"best":
			selected_color = Color(0.7, 1.0, 0.7)
		"ok":
			selected_color = Color(0.85, 0.95, 0.75)
		"poor":
			selected_color = Color(1.0, 0.9, 0.7)
		"bad":
			selected_color = Color(1.0, 0.7, 0.7)

	var selected_style := StyleBoxFlat.new()
	selected_style.bg_color = selected_color
	selected_style.corner_radius_top_left = 14
	selected_style.corner_radius_top_right = 14
	selected_style.corner_radius_bottom_left = 14
	selected_style.corner_radius_bottom_right = 14
	selected_style.content_margin_left = 16.0
	selected_style.content_margin_right = 16.0
	selected_style.content_margin_top = 10.0
	selected_style.content_margin_bottom = 10.0
	selected_style.border_width_top = 2
	selected_style.border_width_bottom = 2
	selected_style.border_width_left = 2
	selected_style.border_width_right = 2
	selected_style.border_color = selected_color.darkened(0.2)
	button.add_theme_stylebox_override("disabled", selected_style)

	# If wrong, highlight the best answer green
	if quality != "best":
		for btn in responses_container.get_children():
			if btn is Button:
				# Find the best option text to match
				for opt in current_exchange["options"]:
					if opt["quality"] == "best" and btn.text == opt["text"]:
						var best_style := StyleBoxFlat.new()
						best_style.bg_color = Color(0.7, 1.0, 0.7)
						best_style.corner_radius_top_left = 14
						best_style.corner_radius_top_right = 14
						best_style.corner_radius_bottom_left = 14
						best_style.corner_radius_bottom_right = 14
						best_style.content_margin_left = 16.0
						best_style.content_margin_right = 16.0
						best_style.content_margin_top = 10.0
						best_style.content_margin_bottom = 10.0
						best_style.border_width_top = 2
						best_style.border_width_bottom = 2
						best_style.border_width_left = 2
						best_style.border_width_right = 2
						best_style.border_color = Color(0.4, 0.8, 0.4)
						btn.add_theme_stylebox_override("disabled", best_style)

	# Add the child's chosen response as a chat bubble
	var bubble_color: Color
	if quality == "best" or quality == "ok":
		bubble_color = Color(0.85, 0.93, 1.0)
	else:
		bubble_color = Color(1.0, 0.9, 0.85)
	_add_child_bubble(option["text"], bubble_color)

	# Show feedback
	feedback_label.text = feedback_text
	if quality == "best":
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.3))
	elif quality == "ok":
		feedback_label.add_theme_color_override("font_color", Color(0.4, 0.65, 0.2))
	elif quality == "poor":
		feedback_label.add_theme_color_override("font_color", Color(0.7, 0.55, 0.1))
	else:
		feedback_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))

	if not AccessibilityManager.reduce_motion:
		feedback_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.2)

	game_hud.update_score(GameManager.score)

	# Scroll chat to bottom
	await get_tree().process_frame
	await get_tree().process_frame
	chat_scroll.scroll_vertical = int(chat_scroll.get_v_scroll_bar().max_value)

	await get_tree().create_timer(3.0).timeout
	_next_round()


func _clear_chat() -> void:
	for child in chat_vbox.get_children():
		child.queue_free()


func _clear_responses() -> void:
	for child in responses_container.get_children():
		child.queue_free()


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
	_clear_chat()
	_configure_difficulty()
	_start_game()


func _on_back_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_select.tscn")
