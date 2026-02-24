extends Control
## MainMenu - Entry point for KidNeuro. Kid-friendly main menu with play and settings.

@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel


func _ready() -> void:
	AccessibilityManager.apply_to_scene(self)
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	_animate_entrance()


func _animate_entrance() -> void:
	if AccessibilityManager.reduce_motion:
		return

	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	play_button.modulate.a = 0.0
	settings_button.modulate.a = 0.0

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.5)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.4)
	tween.tween_property(play_button, "modulate:a", 1.0, 0.3)
	tween.tween_property(settings_button, "modulate:a", 1.0, 0.3)

	# Gentle bounce for the title
	title_label.pivot_offset = title_label.size / 2.0
	title_label.scale = Vector2(0.8, 0.8)
	var bounce := create_tween()
	bounce.set_ease(Tween.EASE_OUT)
	bounce.set_trans(Tween.TRANS_ELASTIC)
	bounce.tween_property(title_label, "scale", Vector2.ONE, 0.8)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_select.tscn")


func _on_settings_pressed() -> void:
	# Toggle accessibility settings inline for now
	_show_settings_dialog()


func _show_settings_dialog() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Settings"
	dialog.dialog_text = "Accessibility Settings"
	dialog.min_size = Vector2i(400, 350)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)

	# Large text toggle
	var large_text_check := CheckBox.new()
	large_text_check.text = "Large Text"
	large_text_check.button_pressed = AccessibilityManager.large_text
	large_text_check.toggled.connect(func(on: bool):
		AccessibilityManager.large_text = on
		AccessibilityManager.font_scale = 1.4 if on else 1.0
	)
	vbox.add_child(large_text_check)

	# High contrast toggle
	var contrast_check := CheckBox.new()
	contrast_check.text = "High Contrast"
	contrast_check.button_pressed = AccessibilityManager.high_contrast
	contrast_check.toggled.connect(func(on: bool):
		AccessibilityManager.high_contrast = on
	)
	vbox.add_child(contrast_check)

	# Reduce motion toggle
	var motion_check := CheckBox.new()
	motion_check.text = "Reduce Motion"
	motion_check.button_pressed = AccessibilityManager.reduce_motion
	motion_check.toggled.connect(func(on: bool):
		AccessibilityManager.reduce_motion = on
	)
	vbox.add_child(motion_check)

	# Sound toggle
	var sound_check := CheckBox.new()
	sound_check.text = "Sound Effects"
	sound_check.button_pressed = AudioManager.sound_enabled
	sound_check.toggled.connect(func(on: bool):
		AudioManager.set_sound_enabled(on)
	)
	vbox.add_child(sound_check)

	dialog.add_child(vbox)
	dialog.confirmed.connect(func():
		AccessibilityManager.save_settings()
		AccessibilityManager.apply_to_scene(self)
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered()
