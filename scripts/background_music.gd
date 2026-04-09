extends Node

const SETTINGS_FILE_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "video_audio"
const MUSIC_PATH := "res://assets/trilha_sonora/soundTrack1.mp3"
const WINDOWED_MODE := 0
const FULLSCREEN_MODE := 1
const RESOLUTION_OPTIONS := [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(1024, 768),
	Vector2i(1280, 1024)
]

var _player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_player = AudioStreamPlayer.new()
	_player.name = "BackgroundMusicPlayer"
	_player.bus = _get_music_bus_name()
	_player.autoplay = false
	_player.stream = load(MUSIC_PATH) as AudioStream
	if _player.stream is AudioStreamMP3:
		(_player.stream as AudioStreamMP3).loop = true
	elif _player.stream is AudioStreamOggVorbis:
		(_player.stream as AudioStreamOggVorbis).loop = true
	add_child(_player)

	var settings: Dictionary = _load_or_create_settings()
	_apply_saved_music_volume(float(settings.get("music_volume", 70.0)))
	call_deferred("_deferred_aplicar_video_salvo")
	_ensure_playing()


func _deferred_aplicar_video_salvo() -> void:
	var settings: Dictionary = _load_or_create_settings()
	_apply_saved_display_settings(
		int(settings.get("window_mode", WINDOWED_MODE)),
		int(settings.get("resolution_index", 0))
	)

func _process(_delta: float) -> void:
	# Garante música contínua entre trocas de cena.
	_ensure_playing()

func _ensure_playing() -> void:
	if _player == null:
		return
	if _player.stream == null:
		return
	if not _player.playing:
		_player.play()

func _get_music_bus_name() -> String:
	if AudioServer.get_bus_index("Music") >= 0:
		return "Music"
	return "Master"

func _load_or_create_settings() -> Dictionary:
	var config := ConfigFile.new()
	var defaults: Dictionary = {
		"music_volume": 70.0,
		"window_mode": WINDOWED_MODE,
		"resolution_index": 0
	}

	var load_status: Error = config.load(SETTINGS_FILE_PATH)
	if load_status != OK:
		for key in defaults.keys():
			config.set_value(SETTINGS_SECTION, key, defaults[key])
		var werr: Error = config.save(SETTINGS_FILE_PATH)
		if werr != OK:
			push_warning("BackgroundMusic: não foi possível criar settings.cfg (%d)." % werr)
		return defaults

	return {
		"music_volume": float(config.get_value(SETTINGS_SECTION, "music_volume", 70.0)),
		"window_mode": int(config.get_value(SETTINGS_SECTION, "window_mode", WINDOWED_MODE)),
		"resolution_index": int(config.get_value(SETTINGS_SECTION, "resolution_index", 0))
	}

func _apply_saved_music_volume(volume_percent: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(_get_music_bus_name())
	if bus_index < 0:
		return

	var normalized: float = clampf(volume_percent, 0.0, 100.0) / 100.0
	var db_value: float = linear_to_db(normalized)
	if normalized <= 0.0:
		db_value = -80.0

	AudioServer.set_bus_volume_db(bus_index, db_value)

func _apply_saved_display_settings(window_mode: int, resolution_index: int) -> void:
	var safe_window_mode: int = window_mode if window_mode in [WINDOWED_MODE, FULLSCREEN_MODE] else WINDOWED_MODE
	var safe_resolution_index: int = clampi(resolution_index, 0, RESOLUTION_OPTIONS.size() - 1)
	var tree := get_tree()
	if tree == null:
		return
	var win := tree.root as Window
	if win == null:
		return
	if safe_window_mode == FULLSCREEN_MODE:
		win.mode = Window.MODE_FULLSCREEN
		return
	win.mode = Window.MODE_WINDOWED
	var target_size: Vector2i = RESOLUTION_OPTIONS[safe_resolution_index]
	win.min_size = Vector2i(0, 0)
	win.size = target_size
	win.move_to_center()
