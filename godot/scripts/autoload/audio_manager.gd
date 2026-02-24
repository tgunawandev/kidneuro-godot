extends Node
## AudioManager - Handles all game audio with accessibility controls.

var music_volume: float = 0.8
var sfx_volume: float = 1.0
var sound_enabled: bool = true

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)


func play_music(stream: AudioStream, fade_in: float = 1.0) -> void:
	if not sound_enabled:
		return
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(music_volume)
	_music_player.play()


func play_sfx(stream: AudioStream) -> void:
	if not sound_enabled:
		return
	_sfx_player.stream = stream
	_sfx_player.volume_db = linear_to_db(sfx_volume)
	_sfx_player.play()


func stop_music() -> void:
	_music_player.stop()


func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	if not enabled:
		stop_music()
