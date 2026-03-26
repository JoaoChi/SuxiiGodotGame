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

	# Compra o lote básico de forma atômica para evitar reposição parcial.
	var itens_lote: Array[String] = ["salmao", "arroz", "alga"]
	var custo_total: float = 0.0
	for item in itens_lote:
		var dados: Dictionary = GameManager.MERCADO.get(item, {})
		custo_total += float(dados.get("custo", 0.0))

	if GameManager.dinheiro_atual < custo_total:
		print("Dinheiro insuficiente para repor lote básico!")
		return

	for item in itens_lote:
		var sucesso_item := GameManager.repor_estoque(item)
		if not sucesso_item:
			print("Falha inesperada ao repor: %s" % item)
			return
