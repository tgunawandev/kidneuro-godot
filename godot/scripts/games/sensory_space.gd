extends Control
## SensorySpace - Calming sensory regulation activity for ASD+ADHD therapy.
## Guided breathing exercises with visual feedback and free-play ripple effects.
## Not scored with right/wrong - tracks engagement and completed breathing cycles.

@onready var game_hud: CanvasLayer = $GameHUD
@onready var reward_popup: CanvasLayer = $RewardPopup
@onready var cycle_label: Label = %CycleLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var breath_circle: ColorRect = %BreathCircle
@onready var breath_label: Label = %BreathLabel
@onready var mode_label: Label = %ModeLabel
@onready var continue_button: Button = %ContinueButton
@onready var tap_area: Control = %TapArea

const TOTAL_CYCLES := 5
const BREATHE_IN_COLORS := [
	Color(0.4, 0.55, 0.9, 0.6),
	Color(0.45, 0.7, 0.85, 0.6),
	Color(0.5, 0.8, 0.75, 0.6),
	Color(0.55, 0.65, 0.9, 0.6),
	Color(0.4, 0.6, 0.8, 0.6),
]

const RIPPLE_COLORS := [
	Color(0.5, 0.6, 1.0, 0.5),
	Color(0.6, 0.4, 0.9, 0.5),
	Color(0.4, 0.8, 0.7, 0.5),
	Color(0.9, 0.6, 0.8, 0.5),
	Color(0.7, 0.8, 0.4, 0.5),
	Color(0.5, 0.9, 0.9, 0.5),
]

var current_cycle: int = 0
var breathe_in_time: float = 4.0
var breathe_out_time: float = 4.0
var is_breathing: bool = false
var is_free_play: bool = false
var session_start: float = 0.0
var min_circle_size: float = 80.0
var max_circle_size: float = 220.0


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.visible = false
	breath_circle.visible = false
	_configure_difficulty()
	_start_game()


func _configure_difficulty() -> void:
	var level := GameManager.difficulty_level
	if level <= 3:
		breathe_in_time = 4.0
		breathe_out_time = 4.0
	elif level <= 6:
		breathe_in_time = 5.0
		breathe_out_time = 5.0
	else:
		breathe_in_time = 6.0
		breathe_out_time = 6.0


func _start_game() -> void:
	GameManager.start_session("sensory_regulation")
	game_hud.start()
	game_hud.update_progress(0, TOTAL_CYCLES)
	current_cycle = 0
	session_start = Time.get_unix_time_from_system()
	is_free_play = false
	breath_label.text = ""
	mode_label.text = "Tap anywhere to create ripples"
	instruction_label.text = "Let's calm down together..."

	_start_free_play()

	# Brief free play intro, then start breathing
	await get_tree().create_timer(2.0).timeout
	_next_cycle()


func _start_free_play() -> void:
	is_free_play = true
	tap_area.gui_input.connect(_on_tap_area_input)


func _stop_free_play() -> void:
	is_free_play = false
	if tap_area.gui_input.is_connected(_on_tap_area_input):
		tap_area.gui_input.disconnect(_on_tap_area_input)


func _on_tap_area_input(event: InputEvent) -> void:
	if not is_free_play:
		return
	if event is InputEventMouseButton and event.pressed:
		_create_ripple(event.position)
		GameManager.record_event("free_play_tap", {
			"position_x": event.position.x,
			"position_y": event.position.y,
		})
	elif event is InputEventScreenTouch and event.pressed:
		_create_ripple(event.position)
		GameManager.record_event("free_play_tap", {
			"position_x": event.position.x,
			"position_y": event.position.y,
		})


func _create_ripple(pos: Vector2) -> void:
	var ripple := ColorRect.new()
	var size_start := 20.0
	ripple.custom_minimum_size = Vector2(size_start, size_start)
	ripple.size = Vector2(size_start, size_start)
	ripple.position = pos - Vector2(size_start / 2.0, size_start / 2.0)
	ripple.color = RIPPLE_COLORS[randi() % RIPPLE_COLORS.size()]
	tap_area.add_child(ripple)

	if not AccessibilityManager.reduce_motion:
		var final_size := 160.0
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(ripple, "custom_minimum_size", Vector2(final_size, final_size), 1.0)
		tween.tween_property(ripple, "size", Vector2(final_size, final_size), 1.0)
		tween.tween_property(ripple, "position", pos - Vector2(final_size / 2.0, final_size / 2.0), 1.0)
		tween.tween_property(ripple, "modulate:a", 0.0, 1.0)
		tween.chain().tween_callback(ripple.queue_free)
	else:
		# Simplified: just fade out
		var tween := create_tween()
		tween.tween_property(ripple, "modulate:a", 0.0, 0.8)
		tween.tween_callback(ripple.queue_free)


func _next_cycle() -> void:
	if current_cycle >= TOTAL_CYCLES:
		_end_game()
		return

	current_cycle += 1
	cycle_label.text = "Breath %d / %d" % [current_cycle, TOTAL_CYCLES]
	game_hud.update_progress(current_cycle - 1, TOTAL_CYCLES)
	continue_button.visible = false
	is_breathing = true
	breath_circle.visible = true

	# Set breath circle initial state (small)
	var color: Color = BREATHE_IN_COLORS[(current_cycle - 1) % BREATHE_IN_COLORS.size()]
	breath_circle.color = color
	breath_circle.custom_minimum_size = Vector2(min_circle_size, min_circle_size)
	breath_circle.size = Vector2(min_circle_size, min_circle_size)

	# Breathe In phase
	breath_label.text = "Breathe In..."
	breath_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1))
	instruction_label.text = "Slowly fill your lungs with air..."
	mode_label.text = ""

	if not AccessibilityManager.reduce_motion:
		var expand_tween := create_tween()
		expand_tween.set_ease(Tween.EASE_IN_OUT)
		expand_tween.set_trans(Tween.TRANS_SINE)
		expand_tween.tween_property(breath_circle, "custom_minimum_size",
			Vector2(max_circle_size, max_circle_size), breathe_in_time)
		expand_tween.parallel().tween_property(breath_circle, "size",
			Vector2(max_circle_size, max_circle_size), breathe_in_time)

	await get_tree().create_timer(breathe_in_time).timeout

	# Brief hold
	breath_label.text = "Hold..."
	instruction_label.text = "Hold your breath gently..."
	await get_tree().create_timer(1.5).timeout

	# Breathe Out phase
	breath_label.text = "Breathe Out..."
	breath_label.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0, 1))
	instruction_label.text = "Slowly let all the air out..."

	if not AccessibilityManager.reduce_motion:
		var shrink_tween := create_tween()
		shrink_tween.set_ease(Tween.EASE_IN_OUT)
		shrink_tween.set_trans(Tween.TRANS_SINE)
		shrink_tween.tween_property(breath_circle, "custom_minimum_size",
			Vector2(min_circle_size, min_circle_size), breathe_out_time)
		shrink_tween.parallel().tween_property(breath_circle, "size",
			Vector2(min_circle_size, min_circle_size), breathe_out_time)

	await get_tree().create_timer(breathe_out_time).timeout

	# Cycle complete
	is_breathing = false
	var cycle_duration := breathe_in_time + 1.5 + breathe_out_time

	GameManager.record_event("breath_cycle_complete", {
		"cycle_num": current_cycle,
		"duration": cycle_duration,
	})

	breath_label.text = "Well done!"
	breath_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7, 1))
	instruction_label.text = "Great breathing! Take a moment..."
	mode_label.text = "Tap anywhere to create ripples"

	if current_cycle < TOTAL_CYCLES:
		continue_button.text = "Next Breath"
		continue_button.visible = true
	else:
		# Auto-proceed to end after a brief moment
		await get_tree().create_timer(1.5).timeout
		_end_game()


func _on_continue_pressed() -> void:
	continue_button.visible = false
	_next_cycle()


func _end_game() -> void:
	is_breathing = false
	_stop_free_play()
	game_hud.stop()
	breath_circle.visible = false

	var total_duration := Time.get_unix_time_from_system() - session_start
	var calm_score := current_cycle * int(total_duration)

	GameManager.record_event("session_calm_score", {
		"cycles_completed": current_cycle,
		"total_duration": total_duration,
		"calm_score": calm_score,
	})

	# Set a manual score for display
	GameManager.score = calm_score

	GameManager.end_session()

	# Calculate accuracy based on completed cycles
	var accuracy: float = 1.0
	if current_cycle >= TOTAL_CYCLES:
		accuracy = 1.0
	elif current_cycle >= 3:
		accuracy = 0.7
	elif current_cycle >= 1:
		accuracy = 0.4
	else:
		accuracy = 0.2

	reward_popup.show_reward(GameManager.score, accuracy)
	reward_popup.play_again_requested.connect(_on_play_again)
	reward_popup.back_to_menu_requested.connect(_on_back_to_menu)


func _on_play_again() -> void:
	_configure_difficulty()
	_start_game()


func _on_back_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_select.tscn")
