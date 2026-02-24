extends CanvasLayer
## RewardPopup - Celebration overlay shown after completing a game session.
## Displays star rating based on accuracy and final score.

signal play_again_requested()
signal back_to_menu_requested()

@onready var panel: PanelContainer = %RewardPanel
@onready var title_label: Label = %RewardTitle
@onready var score_label: Label = %RewardScoreLabel
@onready var stars_container: HBoxContainer = %StarsContainer
@onready var message_label: Label = %MessageLabel
@onready var play_again_button: Button = %PlayAgainButton
@onready var menu_button: Button = %MenuButton

var _star_labels: Array[Label] = []

const MESSAGES_BY_STARS := {
	1: ["Good try!", "Keep practicing!", "You can do it!"],
	2: ["Great job!", "Well done!", "Awesome work!"],
	3: ["Amazing!", "Perfect score!", "You are a star!"],
}


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	play_again_button.pressed.connect(_on_play_again)
	menu_button.pressed.connect(_on_back_to_menu)

	# Create star labels
	for i in range(3):
		var star := Label.new()
		star.text = "☆"
		star.add_theme_font_size_override("font_size", 56)
		star.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars_container.add_child(star)
		_star_labels.append(star)


func show_reward(score: int, accuracy: float) -> void:
	visible = true
	get_tree().paused = true

	# Calculate stars based on accuracy
	var star_count := _get_star_count(accuracy)

	# Set text
	score_label.text = "Score: %d" % score
	title_label.text = "Session Complete!"

	# Choose a random encouraging message
	var messages: Array = MESSAGES_BY_STARS[star_count]
	message_label.text = messages[randi() % messages.size()]

	# Animate stars
	_animate_stars(star_count)

	# Animate panel entrance
	if not AccessibilityManager.reduce_motion:
		panel.modulate.a = 0.0
		panel.scale = Vector2(0.7, 0.7)
		panel.pivot_offset = panel.size / 2.0
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "modulate:a", 1.0, 0.3)
		tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.5)


func _get_star_count(accuracy: float) -> int:
	if accuracy >= 0.85:
		return 3
	elif accuracy >= 0.6:
		return 2
	else:
		return 1


func _animate_stars(count: int) -> void:
	for i in range(3):
		_star_labels[i].text = "☆"
		_star_labels[i].add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	if AccessibilityManager.reduce_motion:
		for i in range(count):
			_star_labels[i].text = "★"
			_star_labels[i].add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		return

	# Animate each star with a delay
	for i in range(count):
		var delay := i * 0.3
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func():
			_star_labels[i].text = "★"
			_star_labels[i].add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
			# Bounce effect
			_star_labels[i].pivot_offset = _star_labels[i].size / 2.0
			_star_labels[i].scale = Vector2(1.5, 1.5)
			var bounce := create_tween()
			bounce.set_ease(Tween.EASE_OUT)
			bounce.set_trans(Tween.TRANS_ELASTIC)
			bounce.tween_property(_star_labels[i], "scale", Vector2.ONE, 0.5)
		)


func _on_play_again() -> void:
	get_tree().paused = false
	visible = false
	play_again_requested.emit()


func _on_back_to_menu() -> void:
	get_tree().paused = false
	visible = false
	back_to_menu_requested.emit()
