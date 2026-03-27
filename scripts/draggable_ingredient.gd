extends TextureRect
class_name DraggableIngredient

@export var nome_ingrediente: String = ""

var label_qtd: Label

func _resolver_caminho_textura() -> String:
	var slug: String = nome_ingrediente
	var tentativas: Array[String] = [
		"res://features/ingredients/%s.png" % slug,
		"res://assets/ingredientes/%s.png" % slug,
	]
	if slug == "gergelim":
		tentativas.append("res://features/ingredients/gergilim.png")
		tentativas.append("res://assets/ingredientes/gergilim.png")

	for caminho in tentativas:
		if ResourceLoader.exists(caminho):
			return caminho
	return ""

func _ready() -> void:
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var caminho: String = _resolver_caminho_textura()
	if caminho != "":
		var tex: Texture2D = load(caminho) as Texture2D
		if tex != null:
			texture = tex

	label_qtd = Label.new()
	label_qtd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_qtd.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_qtd.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label_qtd.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label_qtd.offset_right = -2
	label_qtd.offset_bottom = -2
	label_qtd.add_theme_color_override("font_outline_color", Color.BLACK)
	label_qtd.add_theme_constant_override("outline_size", 4)
	add_child(label_qtd)

	GameManager.estoque_alterado.connect(_atualizar_visual)
	_atualizar_visual()

func _atualizar_visual() -> void:
	var qtd: int = GameManager.estoque_bancada.get(nome_ingrediente, 0)
	label_qtd.text = "x%d" % qtd
	modulate = Color.WHITE if qtd > 0 else Color.RED

func _get_drag_data(_at_position: Vector2) -> Variant:
	if nome_ingrediente == "":
		return null
	if not GameManager.ingredientes_desbloqueados.get(nome_ingrediente, false):
		return null

	var qtd: int = GameManager.estoque_bancada.get(nome_ingrediente, 0)
	if qtd <= 0 and nome_ingrediente != "massa_empanar":
		return null

	var control := Control.new()
	var preview: Control
	if texture != null:
		var tr := TextureRect.new()
		tr.texture = texture
		tr.custom_minimum_size = size
		tr.size = size
		tr.stretch_mode = stretch_mode
		tr.modulate.a = 0.6
		preview = tr
	else:
		var cr := ColorRect.new()
		cr.custom_minimum_size = size
		cr.color = Color(0.65, 0.65, 0.65)
		cr.modulate.a = 0.6
		preview = cr
	control.add_child(preview)
	preview.position = -0.5 * size

	set_drag_preview(control)

	return nome_ingrediente
