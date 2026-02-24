extends CanvasLayer
## GameHUD - Shared game UI overlay showing score, level, timer, and progress.

signal pause_requested()
signal resume_requested()

@onready var score_label: Label = %ScoreLabel
@onready var level_label: Label = %LevelLabel
@onready var timer_label: Label = %TimerLabel
@onready var pause_button: Button = %PauseButton
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var pause_overlay: ColorRect = %PauseOverlay
@onready var resume_button: Button = %ResumeButton
@onready var quit_button: Button = %QuitButton

var elapsed_time: float = 0.0
var time_limit: float = 0.0  # 0 means no limit
var is_paused: bool = false
var is_running: bool = false


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	pause_overlay.visible = false
	update_score(0)
	update_level(GameManager.difficulty_level)
	update_progress(0, 1)


func _process(delta: float) -> void:
	if not is_running or is_paused:
		return
	elapsed_time += delta
	_update_timer_display()


func start(total_time: float = 0.0) -> void:
	time_limit = total_time
	elapsed_time = 0.0
	is_running = true
	is_paused = false
	_update_timer_display()


func stop() -> void:
	is_running = false


func update_score(value: int) -> void:
	score_label.text = "Score: %d" % value


func update_level(level: int) -> void:
	var difficulty_name := "Easy"
	if level >= 4:
		difficulty_name = "Medium"
	if level >= 7:
		difficulty_name = "Hard"
	level_label.text = "Level %d - %s" % [level, difficulty_name]


func update_progress(current: int, total: int) -> void:
	if total <= 0:
		progress_bar.value = 0
		return
	progress_bar.value = (float(current) / float(total)) * 100.0


func _update_timer_display() -> void:
	if time_limit > 0:
		var remaining := maxf(time_limit - elapsed_time, 0.0)
		var minutes := int(remaining) / 60
		var seconds := int(remaining) % 60
		timer_label.text = "%d:%02d" % [minutes, seconds]
		if remaining <= 10.0 and remaining > 0.0:
			timer_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
		else:
			timer_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		var minutes := int(elapsed_time) / 60
		var seconds := int(elapsed_time) % 60
		timer_label.text = "%d:%02d" % [minutes, seconds]


func _on_pause_pressed() -> void:
	is_paused = true
	pause_overlay.visible = true
	get_tree().paused = true
	pause_requested.emit()


func _on_resume_pressed() -> void:
	is_paused = false
	pause_overlay.visible = false
	get_tree().paused = false
	resume_requested.emit()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	GameManager.end_session()
	get_tree().change_scene_to_file("res://scenes/ui/game_select.tscn")
