extends ColorRect
class_name DraggableIngredient

@export var nome_ingrediente: String = ""

var label_qtd: Label

func _ready() -> void:
	label_qtd = Label.new()
	label_qtd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_qtd.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_qtd.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label_qtd.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
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

	var preview := ColorRect.new()
	preview.custom_minimum_size = size
	preview.color = color
	preview.modulate.a = 0.6

	var control := Control.new()
	control.add_child(preview)
	preview.position = -0.5 * size

	set_drag_preview(control)

	return nome_ingrediente
