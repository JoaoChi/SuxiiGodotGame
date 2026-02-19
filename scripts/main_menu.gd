extends Control

func _on_novo_jogo_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_configuracao_pressed():
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_sair_pressed():
	get_tree().quit()
