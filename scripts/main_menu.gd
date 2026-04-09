extends Control

const VIDEO_MUTE_DB := -80.0
## >1.0 acelera o clipe de entrada (Continuar / Novo jogo).
const VIDEO_ENTRADA_SPEED_SCALE := 1.45
const STREAM_CONTINUAR := preload("res://assets/videos/continuar.ogv")
## Godot 4 só reproduz Ogg Theora no motor; converta o .mp4 com ffmpeg (ver documentação "Playing videos").
const ROTAS_CUTSCENE_NOVO_JOGO: PackedStringArray = [
	"res://assets/videos/cutscene.ogv",
	"res://assets/videos/cutscene.mp4",
]

@onready var background_video: VideoStreamPlayer = $BackgroundVideo
@onready var video_player: VideoStreamPlayer = $ContinuarVideo
@onready var menu_panel: PanelContainer = $PanelContainer
@onready var btn_continuar: Button = $PanelContainer/VBoxContainer/Continuar

var _stream_cutscene_novo_jogo: VideoStream

func _ready() -> void:
	_stream_cutscene_novo_jogo = _carregar_primeiro_videostream_valido(ROTAS_CUTSCENE_NOVO_JOGO)
	# Mantem videos sempre sem audio.
	background_video.volume_db = VIDEO_MUTE_DB
	video_player.volume_db = VIDEO_MUTE_DB
	video_player.speed_scale = 1.0
	btn_continuar.disabled = not GameManager.tem_save()


func _carregar_primeiro_videostream_valido(rotas: PackedStringArray) -> VideoStream:
	for rota in rotas:
		if not ResourceLoader.exists(rota):
			continue
		var r: Resource = load(rota)
		if r is VideoStream:
			return r as VideoStream
	return null


func _tocar_video_entrada(velocidade: float = VIDEO_ENTRADA_SPEED_SCALE) -> void:
	menu_panel.visible = false
	video_player.visible = true
	video_player.volume_db = VIDEO_MUTE_DB
	video_player.speed_scale = velocidade
	video_player.play()


func _ir_para_cena_jogo() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_continuar_pressed() -> void:
	if not GameManager.tem_save():
		return
	GameManager.modo_entrada = "continuar"
	video_player.stream = STREAM_CONTINUAR
	video_player.loop = false
	_tocar_video_entrada()


func _on_video_finished() -> void:
	video_player.visible = false
	video_player.speed_scale = 1.0
	_ir_para_cena_jogo()


func _on_novo_jogo_pressed() -> void:
	GameManager.modo_entrada = "novo_jogo"
	if _stream_cutscene_novo_jogo != null:
		video_player.stream = _stream_cutscene_novo_jogo
		video_player.loop = false
		_tocar_video_entrada(1.0)
	else:
		push_warning(
			"Cutscene de novo jogo: nenhum VideoStream válido em cutscene.ogv/cutscene.mp4. "
			+ "No Godot 4 use Ogg Theora (.ogv). Ex.: ffmpeg -i cutscene.mp4 -q:v 6 -q:a 6 -g:v 64 cutscene.ogv"
		)
		_ir_para_cena_jogo()

func _on_configuracao_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
