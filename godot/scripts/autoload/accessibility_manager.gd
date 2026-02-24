extends Node
## AccessibilityManager - Handles accessibility settings for therapy games.
## Critical for ASD/ADHD children who may have sensory sensitivities.

signal settings_changed()

var large_text: bool = false
var high_contrast: bool = false
var reduce_motion: bool = false
var audio_descriptions: bool = false
var colorblind_mode: String = "none"  # none, protanopia, deuteranopia, tritanopia
var font_scale: float = 1.0
var animation_speed: float = 1.0

const SAVE_PATH := "user://accessibility.cfg"


func _ready() -> void:
	load_settings()


func apply_to_scene(scene: Node) -> void:
	if reduce_motion:
		_disable_animations(scene)

	if large_text:
		_scale_text(scene, font_scale)


func _disable_animations(node: Node) -> void:
	for child in node.get_children():
		if child is AnimationPlayer:
			child.speed_scale = 0.0 if reduce_motion else animation_speed
		_disable_animations(child)


func _scale_text(node: Node, scale: float) -> void:
	for child in node.get_children():
		if child is Label:
			child.add_theme_font_size_override("font_size", int(child.get_theme_font_size("font_size") * scale))
		if child is RichTextLabel:
			child.add_theme_font_size_override("normal_font_size", int(16 * scale))
		_scale_text(child, scale)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("accessibility", "large_text", large_text)
	config.set_value("accessibility", "high_contrast", high_contrast)
	config.set_value("accessibility", "reduce_motion", reduce_motion)
	config.set_value("accessibility", "audio_descriptions", audio_descriptions)
	config.set_value("accessibility", "colorblind_mode", colorblind_mode)
	config.set_value("accessibility", "font_scale", font_scale)
	config.set_value("accessibility", "animation_speed", animation_speed)
	config.save(SAVE_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	large_text = config.get_value("accessibility", "large_text", false)
	high_contrast = config.get_value("accessibility", "high_contrast", false)
	reduce_motion = config.get_value("accessibility", "reduce_motion", false)
	audio_descriptions = config.get_value("accessibility", "audio_descriptions", false)
	colorblind_mode = config.get_value("accessibility", "colorblind_mode", "none")
	font_scale = config.get_value("accessibility", "font_scale", 1.0)
	animation_speed = config.get_value("accessibility", "animation_speed", 1.0)
	settings_changed.emit()
