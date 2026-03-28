extends Control

signal fechar_configuracoes

const SETTINGS_FILE_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "video_audio"
const WINDOWED_MODE := 0
const FULLSCREEN_MODE := 1
const RESOLUTION_OPTIONS := [
	{"label": "1280x720 (16:9)", "size": Vector2i(1280, 720)},
	{"label": "1366x768 (16:9)", "size": Vector2i(1366, 768)},
	{"label": "1600x900 (16:9)", "size": Vector2i(1600, 900)},
	{"label": "1920x1080 (16:9)", "size": Vector2i(1920, 1080)},
	{"label": "1024x768 (4:3)", "size": Vector2i(1024, 768)},
	{"label": "1280x1024 (5:4)", "size": Vector2i(1280, 1024)}
]

@onready var volume_slider: HSlider = $VBoxContainer/VolumeContainer/VolumeSlider
@onready var volume_value_label: Label = $VBoxContainer/VolumeContainer/VolumeValue
@onready var window_mode_option: OptionButton = $VBoxContainer/WindowModeContainer/WindowModeOption
@onready var resolution_option: OptionButton = $VBoxContainer/ResolutionContainer/ResolutionOption
@onready var btn_voltar: Button = $VBoxContainer/Voltar
@onready var btn_menu_principal: Button = $VBoxContainer/MenuPrincipal

var current_resolution_index: int = 0
var current_window_mode: int = WINDOWED_MODE
@export var voltar_para_menu_principal: bool = true

func _ready() -> void:
	_populate_controls()
	_load_settings()
	_apply_audio_volume(float(volume_slider.value))
	call_deferred("_deferred_aplicar_video_inicial")
	if voltar_para_menu_principal:
		btn_voltar.text = "Voltar ao menu principal"
		btn_menu_principal.visible = false
	else:
		btn_voltar.text = "Voltar ao jogo"
		btn_menu_principal.visible = true


func _deferred_aplicar_video_inicial() -> void:
	_apply_window_mode(current_window_mode)
	_update_resolution_availability()
	if current_window_mode == WINDOWED_MODE:
		_apply_resolution(current_resolution_index)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_voltar_pressed()
		accept_event()

func _populate_controls() -> void:
	window_mode_option.clear()
	window_mode_option.add_item("Janela", WINDOWED_MODE)
	window_mode_option.add_item("Tela cheia", FULLSCREEN_MODE)

	resolution_option.clear()
	for item in RESOLUTION_OPTIONS:
		resolution_option.add_item(str(item["label"]))

func _get_music_bus_index() -> int:
	var music_bus_index: int = AudioServer.get_bus_index("Music")
	if music_bus_index >= 0:
		return music_bus_index
	return AudioServer.get_bus_index("Master")

func _apply_audio_volume(volume_percent: float) -> void:
	var normalized: float = clampf(volume_percent, 0.0, 100.0) / 100.0
	var db_value: float = linear_to_db(normalized)
	if normalized <= 0.0:
		db_value = -80.0

	AudioServer.set_bus_volume_db(_get_music_bus_index(), db_value)
	volume_value_label.text = "%d%%" % int(round(volume_percent))

func _obter_janela_raiz() -> Window:
	var w := get_window()
	if w != null:
		return w
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root as Window


func _apply_window_mode(mode_id: int) -> void:
	current_window_mode = mode_id
	var win := _obter_janela_raiz()
	if win == null:
		return
	if mode_id == FULLSCREEN_MODE:
		win.mode = Window.MODE_FULLSCREEN
	else:
		win.mode = Window.MODE_WINDOWED


func _apply_resolution(index: int) -> void:
	if index < 0 or index >= RESOLUTION_OPTIONS.size():
		return
	current_resolution_index = index
	if current_window_mode == FULLSCREEN_MODE:
		return
	var win := _obter_janela_raiz()
	if win == null:
		return
	var target_size: Vector2i = RESOLUTION_OPTIONS[index]["size"]
	win.min_size = Vector2i(0, 0)
	win.size = target_size
	win.move_to_center()

func _update_resolution_availability() -> void:
	resolution_option.disabled = current_window_mode == FULLSCREEN_MODE


func _sincronizar_estado_video_a_partir_da_ui() -> void:
	var wi: int = window_mode_option.selected
	if wi >= 0:
		current_window_mode = clampi(wi, WINDOWED_MODE, FULLSCREEN_MODE)
	var ri: int = resolution_option.selected
	if ri >= 0:
		current_resolution_index = clampi(ri, 0, RESOLUTION_OPTIONS.size() - 1)


func _save_settings() -> void:
	_sincronizar_estado_video_a_partir_da_ui()
	var config := ConfigFile.new()
	config.load(SETTINGS_FILE_PATH)
	config.set_value(SETTINGS_SECTION, "music_volume", volume_slider.value)
	config.set_value(SETTINGS_SECTION, "window_mode", current_window_mode)
	config.set_value(SETTINGS_SECTION, "resolution_index", current_resolution_index)
	var save_err: Error = config.save(SETTINGS_FILE_PATH)
	if save_err != OK:
		push_warning("settings: falha ao salvar settings.cfg (%d)." % save_err)


func _load_settings() -> void:
	var config := ConfigFile.new()
	var load_status: Error = config.load(SETTINGS_FILE_PATH)

	var saved_volume: float = 70.0
	var saved_mode: int = WINDOWED_MODE
	var saved_resolution_index: int = 0

	if load_status == OK:
		saved_volume = float(config.get_value(SETTINGS_SECTION, "music_volume", 70.0))
		saved_mode = int(config.get_value(SETTINGS_SECTION, "window_mode", WINDOWED_MODE))
		saved_resolution_index = int(config.get_value(SETTINGS_SECTION, "resolution_index", 0))

	current_window_mode = saved_mode if saved_mode in [WINDOWED_MODE, FULLSCREEN_MODE] else WINDOWED_MODE
	current_resolution_index = clampi(saved_resolution_index, 0, RESOLUTION_OPTIONS.size() - 1)

	volume_slider.value = clampf(saved_volume, 0.0, 100.0)
	window_mode_option.select(current_window_mode)
	resolution_option.select(current_resolution_index)
	_sincronizar_estado_video_a_partir_da_ui()

func _on_volume_slider_value_changed(value: float) -> void:
	_apply_audio_volume(value)
	_save_settings()

func _on_window_mode_option_item_selected(index: int) -> void:
	_apply_window_mode(index)
	_update_resolution_availability()
	if index == WINDOWED_MODE:
		call_deferred("_deferred_reaplicar_resolucao_apos_janela")
	_save_settings()


func _deferred_reaplicar_resolucao_apos_janela() -> void:
	if current_window_mode != WINDOWED_MODE:
		return
	_apply_resolution(current_resolution_index)


func _on_resolution_option_item_selected(index: int) -> void:
	_apply_resolution(index)
	_save_settings()

func _on_voltar_pressed() -> void:
	_save_settings()
	if voltar_para_menu_principal:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		emit_signal("fechar_configuracoes")


func _on_menu_principal_pressed() -> void:
	_save_settings()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
