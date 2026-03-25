extends Button

@onready var progress_bar: ProgressBar = $ProgressBar
var preparando: bool = false

func _ready() -> void:
	progress_bar.value = 0
	progress_bar.hide()
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if preparando:
		return

	preparando = true
	progress_bar.show()

	var tween := create_tween()
	tween.tween_property(progress_bar, "value", 100, 2.0)
	tween.finished.connect(_finalizar_preparo)

func _finalizar_preparo() -> void:
	preparando = false
	progress_bar.value = 0
	progress_bar.hide()

	# Tenta repor o lote básico pagando o custo único da tábua.
	var sucesso := GameManager.repor_estoque("salmao", 5, GameManager.CUSTO_REPOSICAO_BASICO)
	if sucesso:
		# Custos 0 pois já foi pago no lote.
		GameManager.repor_estoque("arroz", 5, 0)
		GameManager.repor_estoque("alga", 5, 0)
	else:
		print("Dinheiro insuficiente para repor estoque!")
