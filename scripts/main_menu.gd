extends Control

@onready var video_player: VideoStreamPlayer = $ContinuarVideo
@onready var menu_panel: PanelContainer = $PanelContainer

func _on_continuar_pressed() -> void:
	menu_panel.visible = false
	video_player.visible = true
	video_player.play()

func _on_video_finished() -> void:
	video_player.visible = false
	menu_panel.visible = true
	get_tree().change_scene_to_file("res://scenes/atendente.tscn")

func _on_novo_jogo_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_configuracao_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
