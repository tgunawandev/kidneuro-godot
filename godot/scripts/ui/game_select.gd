extends Control
## GameSelect - Grid of game cards for children to choose their therapy game.

const GAMES := [
	{
		"slug": "attention_training",
		"title": "Find the Object!",
		"description": "Spot the matching shape in a grid. Train your focus!",
		"color": Color(0.38, 0.70, 0.91),
		"icon": "🔍",
		"scene": "res://scenes/games/attention_game.tscn",
	},
	{
		"slug": "impulse_control",
		"title": "Impulse Island!",
		"description": "Tap friendly creatures, avoid scary ones. Control your impulses!",
		"color": Color(0.30, 0.75, 0.85),
		"icon": "🏝️",
		"scene": "res://scenes/games/impulse_island.tscn",
	},
	{
		"slug": "memory_training",
		"title": "Sequence Repeat!",
		"description": "Watch the color pattern and repeat it. Boost your memory!",
		"color": Color(0.58, 0.78, 0.46),
		"icon": "🧠",
		"scene": "res://scenes/games/memory_game.tscn",
	},
	{
		"slug": "emotion_recognition",
		"title": "Emotion Match!",
		"description": "Look at the face and pick the right feeling!",
		"color": Color(0.73, 0.55, 0.82),
		"icon": "😊",
		"scene": "res://scenes/games/emotion_game.tscn",
	},
	{
		"slug": "feeling_thermometer",
		"title": "Feeling Thermometer!",
		"description": "Rate how strong feelings are and learn to cope!",
		"color": Color(0.85, 0.55, 0.65),
		"icon": "🌡️",
		"scene": "res://scenes/games/feeling_thermometer.tscn",
	},
	{
		"slug": "social_stories",
		"title": "Social Stories!",
		"description": "Choose the best way to act in social situations!",
		"color": Color(0.90, 0.72, 0.45),
		"icon": "🤝",
		"scene": "res://scenes/games/social_stories.tscn",
	},
	{
		"slug": "turn_taker",
		"title": "Turn Taker!",
		"description": "Practice taking turns with a friend in a dice game!",
		"color": Color(0.70, 0.60, 0.85),
		"icon": "🎲",
		"scene": "res://scenes/games/turn_taker.tscn",
	},
	{
		"slug": "sensory_space",
		"title": "Sensory Space!",
		"description": "Calm down with breathing exercises and soothing visuals!",
		"color": Color(0.25, 0.22, 0.45),
		"icon": "🌌",
		"scene": "res://scenes/games/sensory_space.tscn",
	},
	{
		"slug": "word_world",
		"title": "Word World!",
		"description": "Match words to pictures and build your vocabulary!",
		"color": Color(0.55, 0.65, 0.85),
		"icon": "📚",
		"scene": "res://scenes/games/word_world.tscn",
	},
	{
		"slug": "routine_builder",
		"title": "Routine Builder!",
		"description": "Put daily routine steps in the right order!",
		"color": Color(0.85, 0.75, 0.50),
		"icon": "📋",
		"scene": "res://scenes/games/routine_builder.tscn",
	},
	{
		"slug": "pattern_puzzles",
		"title": "Pattern Puzzles!",
		"description": "Find what comes next in fun patterns!",
		"color": Color(0.50, 0.80, 0.60),
		"icon": "🧩",
		"scene": "res://scenes/games/pattern_puzzles.tscn",
	},
	{
		"slug": "trace_draw",
		"title": "Trace & Draw!",
		"description": "Connect the dots to reveal fun shapes!",
		"color": Color(0.75, 0.70, 0.55),
		"icon": "✏️",
		"scene": "res://scenes/games/trace_draw.tscn",
	},
	{
		"slug": "mind_reader",
		"title": "Mind Reader!",
		"description": "Figure out what characters think and feel!",
		"color": Color(0.65, 0.45, 0.80),
		"icon": "🔮",
		"scene": "res://scenes/games/mind_reader.tscn",
	},
	{
		"slug": "flex_switch",
		"title": "Flex Switch!",
		"description": "Sort cards by changing rules. Stay flexible!",
		"color": Color(0.45, 0.75, 0.70),
		"icon": "🔄",
		"scene": "res://scenes/games/flex_switch.tscn",
	},
	{
		"slug": "chat_builder",
		"title": "Chat Builder!",
		"description": "Build conversations by picking great replies!",
		"color": Color(0.50, 0.70, 0.88),
		"icon": "💬",
		"scene": "res://scenes/games/chat_builder.tscn",
	},
	{
		"slug": "time_timer",
		"title": "Time Timer!",
		"description": "Guess how long things take and master time!",
		"color": Color(0.88, 0.65, 0.40),
		"icon": "⏱️",
		"scene": "res://scenes/games/time_timer.tscn",
	},
	{
		"slug": "body_clues",
		"title": "Body Clues!",
		"description": "Read body language to understand feelings!",
		"color": Color(0.75, 0.55, 0.70),
		"icon": "🕺",
		"scene": "res://scenes/games/body_clues.tscn",
	},
	{
		"slug": "focus_filter",
		"title": "Focus Filter!",
		"description": "Find the target and ignore distractions!",
		"color": Color(0.40, 0.65, 0.85),
		"icon": "🎯",
		"scene": "res://scenes/games/focus_filter.tscn",
	},
]

@onready var grid_container: GridContainer = %GridContainer
@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	back_button.pressed.connect(_on_back_pressed)
	_build_game_cards()


func _build_game_cards() -> void:
	for game_data in GAMES:
		var card := _create_game_card(game_data)
		grid_container.add_child(card)


func _create_game_card(data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 240)

	# Card background style
	var style := StyleBoxFlat.new()
	style.bg_color = data["color"]
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	style.shadow_color = Color(0, 0, 0, 0.15)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)

	# Icon label (emoji)
	var icon_label := Label.new()
	icon_label.text = data["icon"]
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(icon_label)

	# Title
	var title := Label.new()
	title.text = data["title"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title)

	# Description
	var desc := Label.new()
	desc.text = data["description"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	# Play button
	var play_btn := Button.new()
	play_btn.text = "  Play!  "
	play_btn.custom_minimum_size = Vector2(160, 56)
	play_btn.add_theme_font_size_override("font_size", 22)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(1, 1, 1, 0.3)
	btn_style.corner_radius_top_left = 12
	btn_style.corner_radius_top_right = 12
	btn_style.corner_radius_bottom_left = 12
	btn_style.corner_radius_bottom_right = 12
	play_btn.add_theme_stylebox_override("normal", btn_style)

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(1, 1, 1, 0.5)
	btn_hover.corner_radius_top_left = 12
	btn_hover.corner_radius_top_right = 12
	btn_hover.corner_radius_bottom_left = 12
	btn_hover.corner_radius_bottom_right = 12
	play_btn.add_theme_stylebox_override("hover", btn_hover)

	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = Color(1, 1, 1, 0.6)
	btn_pressed.corner_radius_top_left = 12
	btn_pressed.corner_radius_top_right = 12
	btn_pressed.corner_radius_bottom_left = 12
	btn_pressed.corner_radius_bottom_right = 12
	play_btn.add_theme_stylebox_override("pressed", btn_pressed)

	play_btn.add_theme_color_override("font_color", Color.WHITE)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var scene_path: String = data["scene"]
	play_btn.pressed.connect(func():
		_launch_game(scene_path)
	)
	vbox.add_child(play_btn)

	card.add_child(vbox)
	return card


func _launch_game(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
