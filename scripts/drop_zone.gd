extends TextureRect
class_name DropZone

@onready var order_manager = get_tree().current_scene.get_node_or_null("OrderManager")

# Dicionário temporário para mapear strings para cores (Greyboxing)
const CORES_INGREDIENTES = {
	"arroz": Color(1.0, 1.0, 1.0, 1.0),         # Branco
	"salmao": Color(0.95, 0.45, 0.25, 1.0),     # Laranja
	"alga": Color(0.05, 0.25, 0.12, 1.0),       # Verde Escuro
	"cebolinha": Color(0.2, 0.8, 0.2, 1.0),     # Verde Claro
	"gergelim": Color(0.9, 0.8, 0.6, 1.0),      # Bege
	"cream_cheese": Color(1.0, 0.95, 0.9, 1.0), # Quase Branco
	"massa_empanar": Color(0.8, 0.5, 0.2, 1.0)  # Marrom Dourado
}

var offset_y_atual: float = 0.0

func _ready() -> void:
	if order_manager:
		# Escuta o sinal para limpar a mesa quando um novo cliente chega
		order_manager.pedido_gerado.connect(_on_pedido_gerado)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_STRING:
		return false
	if not order_manager or not order_manager.cliente_ativo:
		return false
	var nome_ingrediente := data as String
	return GameManager.estoque_bancada.get(nome_ingrediente, 0) > 0

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var nome_ingrediente = data as String

	if not order_manager or not order_manager.cliente_ativo:
		return

	# O OrderManager já valida/consome estoque; evita consumo duplicado.
	var tamanho_antes: int = order_manager.montagem_atual.size()
	order_manager.adicionar_ingrediente(nome_ingrediente)
	if order_manager.montagem_atual.size() <= tamanho_antes:
		return
	# O sinal ingrediente_adicionado pode completar o pedido e esconder a pilha;
	# não criar outra fatia depois disso (senão fica um ColorRect por cima do sprite).
	if GameManager.montagem_confere_receita(order_manager.montagem_atual, order_manager.receita_esperada):
		return
	_criar_visual_ingrediente(nome_ingrediente)

func _criar_visual_ingrediente(nome: String) -> void:
	var visual = ColorRect.new()
	visual.custom_minimum_size = Vector2(80, 20) # Formato de "fatia"
	visual.size = Vector2(80, 20)
	
	if CORES_INGREDIENTES.has(nome):
		visual.color = CORES_INGREDIENTES[nome]
	else:
		visual.color = Color.MAGENTA # Cor de erro gritante caso falte mapeamento
	
	# Empilha de baixo para cima, centralizado no eixo X da bancada
	visual.position = Vector2(
		(self.size.x / 2) - (visual.size.x / 2),
		(self.size.y / 2) + 40 - offset_y_atual
	)
	
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE # Evita que a fatia bloqueie novos drops
	add_child(visual)
	
	offset_y_atual += 22.0 # Sobe a altura da pilha para a próxima fatia

func _on_pedido_gerado(_nome_cliente: String, _fala_recepcao: String, _nome_sushi: String, _tempo_limite: float, _textura_cliente: Texture2D) -> void:
	# Destrói todas as fatias da mesa para o próximo pedido
	for child in get_children():
		# Mantém o sprite do sushi pronto, caso exista (ele vive dentro da mesma Bancada).
		if child.name == "SpriteSushiPronto":
			continue
		child.queue_free()
	offset_y_atual = 0.0
