extends Control

const VIDEO_MUTE_DB := -80.0
## >1.0 acelera o clipe de entrada (Continuar / Novo jogo).
const VIDEO_ENTRADA_SPEED_SCALE := 1.45

@onready var background_video: VideoStreamPlayer = $BackgroundVideo
@onready var video_player: VideoStreamPlayer = $ContinuarVideo
@onready var menu_panel: PanelContainer = $PanelContainer
@onready var btn_continuar: Button = $PanelContainer/VBoxContainer/Continuar

func _ready() -> void:
	# Mantem videos sempre sem audio.
	background_video.volume_db = VIDEO_MUTE_DB
	video_player.volume_db = VIDEO_MUTE_DB
	video_player.speed_scale = 1.0
	btn_continuar.disabled = not GameManager.tem_save()

func _tocar_video_entrada() -> void:
	menu_panel.visible = false
	video_player.visible = true
	video_player.volume_db = VIDEO_MUTE_DB
	video_player.speed_scale = VIDEO_ENTRADA_SPEED_SCALE
	video_player.play()

func _on_continuar_pressed() -> void:
	if not GameManager.tem_save():
		return
	GameManager.modo_entrada = "continuar"
	_tocar_video_entrada()

func _on_video_finished() -> void:
	video_player.visible = false
	video_player.speed_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_novo_jogo_pressed() -> void:
	GameManager.modo_entrada = "novo_jogo"
	_tocar_video_entrada()

func _on_configuracao_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
