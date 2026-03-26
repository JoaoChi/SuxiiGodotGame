extends Node
class_name OrderManager

signal pedido_gerado(nome_cliente, fala_recepcao, nome_sushi, tempo_limite, textura_cliente)
signal ingrediente_adicionado(ingrediente)
signal montagem_atualizada(array_montagem_atual)
signal montagem_limpa()
signal pedido_entregue(sucesso, dinheiro_ganho, estrelas)
signal tempo_esgotado()
signal expediente_encerrado()

var pedido_atual_nome: String = ""
var receita_esperada: Array = []
var montagem_atual: Array = []
var cliente_ativo: bool = false
var timer_pedido: Timer

var pedidos_atendidos_hoje: int = 0
var meta_pedidos_dia: int = 0

# Pool de clientes disponíveis (Instanciados em memória para o protótipo)
var pool_clientes: Array[ClienteData] = []
var cliente_atual: ClienteData

func _ready() -> void:
	timer_pedido = Timer.new()
	timer_pedido.one_shot = true
	timer_pedido.timeout.connect(_on_timer_timeout)
	add_child(timer_pedido)
	
	# Popula o pool com os clientes específicos do GDD
	pool_clientes.clear()
	pool_clientes.append(ClienteAmanda.new())
	pool_clientes.append(ClienteJoao.new())
	pool_clientes.append(ClienteGabriela.new())
	pool_clientes.append(ClienteCasal.new())
	pool_clientes.append(ClienteJow.new())

func iniciar_expediente() -> void:
	pedidos_atendidos_hoje = 0
	meta_pedidos_dia = 3 + (GameManager.dia_atual * 2)
	gerar_novo_pedido()

func gerar_novo_pedido() -> void:
	if pedidos_atendidos_hoje >= meta_pedidos_dia:
		emit_signal("expediente_encerrado")
		return

	# 1. Filtrar apenas as receitas que o jogador PODE fazer no momento
	var receitas_possiveis: Array = _get_receitas_possiveis()
	if receitas_possiveis.is_empty():
		receitas_possiveis = ["Sashimi"]

	# 2. Chance do Jôw aparecer a partir do Dia 3
	var sorteio_jow := randf() < 0.20 and GameManager.dia_atual >= 3

	# Seleciona o cliente (mantendo a lógica anterior)
	if sorteio_jow:
		cliente_atual = ClienteJow.new()
	else:
		# Evita Jôw fora da chance definida (senão a rivalidade fica imprevisível demais)
		cliente_atual = _pick_cliente_nao_jow()

	# Define a quantidade de sushis por pedido conforme o dia
	var qtd_itens := 1
	if GameManager.dia_atual >= 4:
		qtd_itens = 2
	if GameManager.dia_atual >= 8:
		qtd_itens = randi_range(2, 3)

	var nomes_no_combo: Array[String] = []
	receita_esperada.clear()
	limpar_montagem()

	for i in range(qtd_itens):
		var escolha: String
		if sorteio_jow:
			# Jôw mira a receita mais "crítica"
			escolha = _get_receita_critica(receitas_possiveis)
		else:
			escolha = receitas_possiveis.pick_random()

		nomes_no_combo.append(escolha)
		receita_esperada.append_array(GameManager.RECEITAS[escolha])

	pedido_atual_nome = " + ".join(nomes_no_combo)
	var fala = cliente_atual.falas_recepcao.pick_random() % pedido_atual_nome
	cliente_ativo = true

	# O tempo escala com o total de ingredientes do combo.
	# O Jôw é impaciente: tempo reduzido.
	var tempo_limite := 10.0 + (receita_esperada.size() * 3.0)
	if sorteio_jow:
		tempo_limite = 8.0 + (receita_esperada.size() * 2.0)

	timer_pedido.start(tempo_limite)
	emit_signal("pedido_gerado", cliente_atual.nome, fala, pedido_atual_nome, tempo_limite, cliente_atual.textura_pixel_art)

func _pick_cliente_nao_jow() -> ClienteData:
	var candidatos: Array[ClienteData] = []
	for c in pool_clientes:
		if not (c is ClienteJow):
			candidatos.append(c)
	if candidatos.is_empty():
		return ClienteJow.new()
	return candidatos.pick_random()

func adicionar_ingrediente(ingrediente: String) -> void:
	if not cliente_ativo: return
	montagem_atual.append(ingrediente)
	emit_signal("ingrediente_adicionado", ingrediente)
	emit_signal("montagem_atualizada", montagem_atual.duplicate())

func limpar_montagem() -> void:
	montagem_atual.clear()
	emit_signal("montagem_limpa")

func entregar_pedido() -> void:
	if not cliente_ativo: return
	cliente_ativo = false
	var tempo_restante = timer_pedido.time_left
	timer_pedido.stop()
	
	# Delega a matemática pesada para a classe do cliente
	var resultado = cliente_atual.calcular_resultado(pedido_atual_nome, montagem_atual, receita_esperada, tempo_restante)
	var dinheiro_ganho: float = resultado["dinheiro"]
	var estrelas_ganhas: float = resultado["estrelas"]
	var sucesso_perfeito: bool = resultado["sucesso"]
	
	# Aplica modificadores globais (Combos)
	if sucesso_perfeito:
		GameManager.combos_consecutivos += 1
		GameManager.acertos_dia += 1
		# Só aplica bônus de combo se o cliente estiver disposto a pagar algo
		if dinheiro_ganho > 0:
			dinheiro_ganho += (GameManager.combos_consecutivos * 2.0)
	else:
		GameManager.combos_consecutivos = 0
		GameManager.erros_dia += 1
			
	GameManager.adicionar_dinheiro(dinheiro_ganho)
	GameManager.processar_reputacao(estrelas_ganhas)
	
	pedidos_atendidos_hoje += 1
	emit_signal("pedido_entregue", sucesso_perfeito, dinheiro_ganho, estrelas_ganhas)
	limpar_montagem()

func _on_timer_timeout() -> void:
	if not cliente_ativo: return
	cliente_ativo = false
	GameManager.combos_consecutivos = 0
	GameManager.erros_dia += 1
	GameManager.processar_reputacao(-1.5)
	pedidos_atendidos_hoje += 1
	emit_signal("tempo_esgotado")
	limpar_montagem()

# Função para identificar a receita mais “crítica” para o jogador
# (o Jôw mira o ingrediente com MENOR estoque entre as receitas possíveis)
func _get_receita_critica(lista: Array) -> String:
	if lista.is_empty():
		return "Sashimi"

	# Junta todos os ingredientes que existem nas receitas disponíveis
	var ingredientes_candidatos: Dictionary = {}
	for r in lista:
		for ing in GameManager.RECEITAS[r]:
			ingredientes_candidatos[ing] = true

	# Encontra o ingrediente com menor quantidade na bancada
	var ingrediente_mais_escarso: String = ""
	var menor_qtd := 1e9
	for ing in ingredientes_candidatos.keys():
		var qtd: int = int(GameManager.estoque_bancada.get(ing, 0))
		if qtd < menor_qtd:
			menor_qtd = qtd
			ingrediente_mais_escarso = ing

	# Retorna uma receita que use esse ingrediente
	var receitas_com_ingrediente: Array = []
	for r in lista:
		if ingrediente_mais_escarso in GameManager.RECEITAS[r]:
			receitas_com_ingrediente.append(r)

	if receitas_com_ingrediente.size() > 0:
		return receitas_com_ingrediente.pick_random()

	return lista.pick_random()

func _get_receitas_possiveis() -> Array:
	var possiveis: Array = []
	for nome in GameManager.RECEITAS.keys():
		var pode := true
		for ing in GameManager.RECEITAS[nome]:
			if not GameManager.ingredientes_desbloqueados.get(ing, false):
				pode = false
				break
		if pode:
			possiveis.append(nome)
	return possiveis
