extends ColorRect
class_name FryerDropZone

var _ocupado: bool = false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if _ocupado:
		return false
	if typeof(data) != TYPE_STRING:
		return false
	if (data as String) != "massa_empanar":
		return false
	return GameManager.ingredientes_desbloqueados.get("massa_empanar", false)

func _drop_data(_at_position: Vector2, _data: Variant) -> void:
	_iniciar_fritura()

func _iniciar_fritura() -> void:
	_ocupado = true
	var barra: ProgressBar = get_node_or_null("ProgressBarFritura")
	if barra:
		barra.visible = true
		barra.value = 0.0
	var duracao := 3.0
	var tween := create_tween()
	tween.tween_method(
		func(v: float) -> void: if barra: barra.value = v,
		0.0,
		100.0,
		duracao
	)
	tween.finished.connect(_on_fritura_finalizada.bind(barra))

func _on_fritura_finalizada(barra: ProgressBar) -> void:
	var _sucesso := GameManager.repor_estoque("massa_empanar", 10, GameManager.CUSTO_REPOSICAO_ESPECIAL)
	_ocupado = false
	if barra:
		barra.visible = false
		barra.value = 0.0
