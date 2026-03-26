extends Control

const TEXTURAS_SUSHIS: Dictionary = {
	"Sashimi": "res://features/food/sashimi.png",
	"Nigiri": "res://features/food/nigiri.png",
	"Maki": "res://features/food/maki.png",
	"Temaki": "res://features/food/temaki.png",
	"Uramaki": "res://features/food/uramaki.png",
	"Hot_Filadelfia": "res://features/food/hot.png"
}

@onready var label_pedido = $VBoxContainer/LabelPedido
@onready var label_hud: Label = $HUDSuperior/HBoxHUD/LabelHUDUX
@onready var label_status = $HUDSuperior/HBoxHUD/LabelStatusUX
@onready var label_dialogo = $PainelDialogo/LabelDialogoUX
@onready var sprite_cliente = $SpriteCliente
@onready var order_manager = $OrderManager
@onready var barra_tempo: ProgressBar = $VBoxContainer/BarraTempo
@onready var bancada: TextureRect = $BancadaFundo
@onready var sprite_sushi_pronto: TextureRect = $BancadaFundo/SpriteSushiPronto
@onready var painel_resumo = $PainelResumo
@onready var label_resumo = $PainelResumo/VBox/LabelResumo
@onready var painel_loja = $PainelLoja
@onready var label_estoque: Label = $VBoxContainer/MarginContainerEstoque/LabelEstoqueUX
@onready var progress_bar_prep: ProgressBar = $VBoxContainer/HBoxPreparo/ProgressBarPrep
@onready var vbox_fritura: Control = $VBoxContainer/HBoxBancadaEFritura/VBoxFritura
@onready var painel_game_over = $PainelGameOver
@onready var vbox_ingredientes: VBoxContainer = $DockIngredientes/VBoxIngredientes
@onready var dock_ingredientes: Control = $DockIngredientes

enum EstadoTurno { PREPARANDO, ABERTO, FECHADO }
var estado_atual: EstadoTurno = EstadoTurno.PREPARANDO
var _prep_em_andamento: bool = false
var _jogo_finalizado: bool = false
var _sushi_pronto_pos_inicial: Vector2
var _entrega_em_andamento: bool = false

func _ready() -> void:
	GameManager.estoque_alterado.connect(_on_estoque_alterado)
	order_manager.pedido_gerado.connect(_on_pedido_gerado)
	order_manager.ingrediente_adicionado.connect(_on_ingrediente_adicionado)
	order_manager.montagem_atualizada.connect(_on_montagem_atualizada)
	order_manager.montagem_limpa.connect(_on_montagem_limpa)
	order_manager.pedido_entregue.connect(_on_pedido_entregue)
	order_manager.tempo_esgotado.connect(_on_tempo_esgotado)
	order_manager.expediente_encerrado.connect(_on_expediente_encerrado)

	_injetar_feedback_montagem_e_lixeira()
	_injetar_botoes_ferramentas()
	_atualizar_botoes_estoque_bancada()
	_atualizar_textos_botoes_preparo()
	
	painel_resumo.hide()
	painel_loja.hide()
	barra_tempo.hide()

	# Placeholder para o sushi pronto (substituível pela arte final depois).
	var placeholder_sushi := PlaceholderTexture2D.new()
	placeholder_sushi.size = Vector2(256, 256)
	sprite_sushi_pronto.texture = placeholder_sushi
	sprite_sushi_pronto.hide()
	_sushi_pronto_pos_inicial = sprite_sushi_pronto.position

	GameManager.restaurante_falido.connect(_on_restaurante_falido)
	painel_game_over.hide()
	_jogo_finalizado = false
	preparar_novo_dia()

func _injetar_feedback_montagem_e_lixeira() -> void:
	if not is_instance_valid(dock_ingredientes):
		return

	if dock_ingredientes.get_node_or_null("LabelMontagemAtual") == null:
		var label_montagem := Label.new()
		label_montagem.name = "LabelMontagemAtual"
		label_montagem.text = "Montagem: -"
		label_montagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_montagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dock_ingredientes.add_child(label_montagem)
		dock_ingredientes.move_child(label_montagem, 0)

	if get_node_or_null("VBoxContainer/BtnLixeira") == null:
		var btn_lixeira := Button.new()
		btn_lixeira.name = "BtnLixeira"
		btn_lixeira.text = "🗑️ Jogar Fora"
		btn_lixeira.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn_entregar: Button = get_node_or_null("VBoxContainer/BtnEntregar") as Button
		var vbox_principal: VBoxContainer = get_node_or_null("VBoxContainer") as VBoxContainer
		if is_instance_valid(vbox_principal):
			vbox_principal.add_child(btn_lixeira)
			if is_instance_valid(btn_entregar):
				vbox_principal.move_child(btn_lixeira, btn_entregar.get_index() + 1)
		btn_lixeira.pressed.connect(_on_lixeira_pressed)

func _injetar_botoes_ferramentas() -> void:
	if not is_instance_valid(vbox_ingredientes):
		return

	_criar_botao_ferramenta("btn_faca", "Cortar", "faca")
	_criar_botao_ferramenta("btn_esteira", "Enrolar", "esteira")
	_criar_botao_ferramenta("btn_fritadeira", "Fritar", "fritadeira")

func _criar_botao_ferramenta(nome_no: String, texto: String, token: String) -> void:
	# Evita duplicar botões quando a cena recarrega.
	if vbox_ingredientes.get_node_or_null(nome_no) != null:
		return

	var botao := Button.new()
	botao.name = nome_no
	botao.text = texto
	botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao.mouse_filter = Control.MOUSE_FILTER_STOP
	botao.pressed.connect(_on_ferramenta_pressed.bind(token))
	vbox_ingredientes.add_child(botao)

func _on_ferramenta_pressed(ferramenta: String) -> void:
	if not is_instance_valid(order_manager):
		return
	order_manager.adicionar_ingrediente(ferramenta)

func _atualizar_textos_botoes_preparo() -> void:
	var mapeamento_botoes: Dictionary = {
		"arroz": "VBoxContainer/HBoxPreparo/BtnPrepArroz",
		"salmao": "VBoxContainer/HBoxPreparo/BtnPrepSalmao",
		"alga": "VBoxContainer/HBoxPreparo/BtnPrepAlga",
		"cebolinha": "VBoxContainer/HBoxPreparo/BtnPrepCebolinha",
		"gergelim": "VBoxContainer/HBoxPreparo/BtnPrepGergelim",
		"cream_cheese": "VBoxContainer/HBoxPreparo/BtnPrepCreamCheese",
		"massa_empanar": "VBoxContainer/HBoxPreparo/BtnPrepMassaEmpanar"
	}

	for item in mapeamento_botoes.keys():
		if not GameManager.MERCADO.has(item):
			continue
		var botao: Button = get_node_or_null(mapeamento_botoes[item]) as Button
		if botao == null:
			continue

		var dados: Dictionary = GameManager.MERCADO[item]
		var nome_insumo: String = str(dados.get("nome", item))
		var custo: float = float(dados.get("custo", 0.0))
		botao.text = "%s\n($%.0f)" % [nome_insumo, custo]

func _process(_delta: float) -> void:
	# Feedback visual do tempo do pedido atual.
	# (o OrderManager controla timer_pedido e dispara tempo_esgotado quando acaba)
	if barra_tempo == null:
		return

	var timer: Timer = order_manager.timer_pedido
	if order_manager.cliente_ativo and timer != null and not timer.is_stopped():
		barra_tempo.show()
		var tempo_restante := timer.time_left
		var tempo_total := timer.wait_time

		var pct := 0.0
		if tempo_total > 0.0:
			pct = (tempo_restante / tempo_total) * 100.0

		barra_tempo.value = clampf(pct, 0.0, 100.0)

		# Ajusta cor conforme o tempo restante (verde -> amarelo -> vermelho).
		# Usamos modulate para um feedback rápido sem mexer no tema.
		if barra_tempo.value > 60.0:
			barra_tempo.modulate = Color(0.2, 1.0, 0.2, 1.0)
		elif barra_tempo.value > 30.0:
			barra_tempo.modulate = Color(1.0, 1.0, 0.2, 1.0)
		else:
			barra_tempo.modulate = Color(1.0, 0.2, 0.2, 1.0)
	else:
		barra_tempo.hide()

func preparar_novo_dia() -> void:
	if _jogo_finalizado:
		return
	estado_atual = EstadoTurno.PREPARANDO
	GameManager.resetar_dia()

	label_pedido.text = "Dia %d - Restaurante Fechado\nDinheiro Disponível: R$ %.2f" % [GameManager.dia_atual, GameManager.dinheiro_atual]
	label_status.text = "Prepare sua bancada."
	label_dialogo.text = ""
	_limpar_textura_cliente_sprite()
	$BtnAbrir.show()
	atualizar_hud()
	atualizar_label_estoque()
	_atualizar_visibilidade_controles_turno()

func _on_estoque_alterado() -> void:
	atualizar_label_estoque()
	_atualizar_botoes_estoque_bancada()

func atualizar_label_estoque() -> void:
	var partes: PackedStringArray = []
	for item in ["arroz", "salmao", "alga", "cebolinha", "gergelim", "cream_cheese", "massa_empanar"]:
		if not GameManager.ingredientes_desbloqueados.get(item, false):
			continue
		var q: int = int(GameManager.estoque_bancada.get(item, 0))
		partes.append("%s: %d" % [item, q])
	label_estoque.text = "Estoque (bancada): " + ", ".join(partes)

func _atualizar_botoes_estoque_bancada() -> void:
	if not is_instance_valid(vbox_ingredientes):
		return

	for child in vbox_ingredientes.get_children():
		var botao: Button = child as Button
		if botao == null:
			continue

		var item: String = _resolver_item_botao_doca(botao)
		if item == "":
			continue

		if item in ["faca", "esteira", "fritadeira"]:
			continue

		if not GameManager.ingredientes_desbloqueados.get(item, false):
			botao.disabled = true
			continue

		var qtd: int = int(GameManager.estoque_bancada.get(item, 0))
		botao.text = "%s [ %d ]" % [_nome_legivel_item(item), qtd]
		botao.disabled = qtd <= 0

func _resolver_item_botao_doca(botao: Button) -> String:
	if not is_instance_valid(botao):
		return ""

	var nome_no: String = botao.name.to_lower()
	if nome_no.begins_with("btn_"):
		return nome_no.trim_prefix("btn_")

	if nome_no.begins_with("ingrediente"):
		var chave: String = nome_no.trim_prefix("ingrediente")
		match chave:
			"massa":
				return "massa_empanar"
			"creamcheese":
				return "cream_cheese"
			_:
				return chave

	return ""

func _atualizar_visibilidade_ingredientes_e_preparo() -> void:
	$DockIngredientes/VBoxIngredientes/IngredienteCebolinha.visible = GameManager.ingredientes_desbloqueados["cebolinha"]
	$DockIngredientes/VBoxIngredientes/IngredienteGergelim.visible = GameManager.ingredientes_desbloqueados["gergelim"]
	$DockIngredientes/VBoxIngredientes/IngredienteCreamCheese.visible = GameManager.ingredientes_desbloqueados["cream_cheese"]
	$DockIngredientes/VBoxIngredientes/IngredienteMassa.visible = GameManager.ingredientes_desbloqueados["massa_empanar"]
	$VBoxContainer/HBoxPreparo/BtnPrepCebolinha.visible = GameManager.ingredientes_desbloqueados["cebolinha"]
	$VBoxContainer/HBoxPreparo/BtnPrepGergelim.visible = GameManager.ingredientes_desbloqueados["gergelim"]
	$VBoxContainer/HBoxPreparo/BtnPrepCreamCheese.visible = GameManager.ingredientes_desbloqueados["cream_cheese"]
	vbox_fritura.visible = GameManager.ingredientes_desbloqueados["massa_empanar"]

func _atualizar_visibilidade_controles_turno() -> void:
	# Esconde ações que não fazem sentido no estado atual (ex.: Entregar com restaurante fechado).
	var btn_entregar: Button = $VBoxContainer/BtnEntregar
	var btn_lixeira: Button = get_node_or_null("VBoxContainer/BtnLixeira") as Button
	var hbox_ing: Control = $DockIngredientes
	var grupo_preparo_bancada: Array[Control] = [
		$VBoxContainer/MarginContainerEstoque,
		$VBoxContainer/BtnTabua,
		$VBoxContainer/HBoxPreparo,
		$VBoxContainer/SpacerBancada,
		$VBoxContainer/HBoxBancadaEFritura,
	]

	if _jogo_finalizado:
		btn_entregar.hide()
		if is_instance_valid(btn_lixeira):
			btn_lixeira.hide()
		btn_entregar.disabled = false
		hbox_ing.hide()
		for n in grupo_preparo_bancada:
			n.hide()
		return

	var painel_bloqueando: bool = painel_resumo.visible or painel_loja.visible
	if painel_bloqueando:
		btn_entregar.hide()
		if is_instance_valid(btn_lixeira):
			btn_lixeira.hide()
		btn_entregar.disabled = false
		hbox_ing.hide()
		for n in grupo_preparo_bancada:
			n.hide()
		return

	for n in grupo_preparo_bancada:
		n.show()

	match estado_atual:
		EstadoTurno.PREPARANDO:
			btn_entregar.hide()
			if is_instance_valid(btn_lixeira):
				btn_lixeira.hide()
			btn_entregar.disabled = false
			hbox_ing.hide()
		EstadoTurno.ABERTO:
			var em_pedido: bool = order_manager.cliente_ativo
			btn_entregar.visible = em_pedido
			if is_instance_valid(btn_lixeira):
				btn_lixeira.visible = em_pedido
			btn_entregar.disabled = false
			hbox_ing.visible = em_pedido
		EstadoTurno.FECHADO:
			btn_entregar.hide()
			if is_instance_valid(btn_lixeira):
				btn_lixeira.hide()
			btn_entregar.disabled = false
			hbox_ing.hide()
			for n in grupo_preparo_bancada:
				n.hide()

	_atualizar_visibilidade_ingredientes_e_preparo()

func _set_botoes_preparo_desabilitados(desabilitar: bool) -> void:
	var h := $VBoxContainer/HBoxPreparo
	for c in h.get_children():
		if c is Button:
			(c as Button).disabled = desabilitar

func _iniciar_preparo(item: String, segundos: float = 3.0) -> void:
	if _jogo_finalizado:
		return
	if _prep_em_andamento:
		return
	if not GameManager.ingredientes_desbloqueados.get(item, false):
		return
	if not GameManager.MERCADO.has(item):
		return
	_prep_em_andamento = true
	_set_botoes_preparo_desabilitados(true)
	progress_bar_prep.visible = true
	progress_bar_prep.value = 0.0
	var tween_prep := create_tween()
	tween_prep.tween_method(
		func(v: float) -> void: progress_bar_prep.value = v,
		0.0,
		100.0,
		segundos
	)
	tween_prep.finished.connect(_finalizar_preparo.bind(item))

func _finalizar_preparo(item: String) -> void:
	var sucesso := GameManager.repor_estoque(item)
	if not sucesso:
		var dados_item: Dictionary = GameManager.MERCADO.get(item, {})
		var nome_item: String = str(dados_item.get("nome", item))
		print("Dinheiro insuficiente para comprar: %s" % nome_item)
	progress_bar_prep.visible = false
	_set_botoes_preparo_desabilitados(false)
	_prep_em_andamento = false
	atualizar_hud()

func _on_btn_prep_arroz_pressed() -> void:
	_iniciar_preparo("arroz")

func _on_btn_prep_salmao_pressed() -> void:
	_iniciar_preparo("salmao")

func _on_btn_prep_alga_pressed() -> void:
	_iniciar_preparo("alga")

func _on_btn_prep_cebolinha_pressed() -> void:
	_iniciar_preparo("cebolinha")

func _on_btn_prep_gergelim_pressed() -> void:
	_iniciar_preparo("gergelim")

func _on_btn_prep_cream_cheese_pressed() -> void:
	_iniciar_preparo("cream_cheese")

func abrir_restaurante() -> void:
	if _jogo_finalizado:
		return
	if estado_atual != EstadoTurno.PREPARANDO: return
	estado_atual = EstadoTurno.ABERTO
	$BtnAbrir.hide()
	label_pedido.text = "Restaurante Aberto!"
	label_status.text = "Aguardando o primeiro cliente..."
	_atualizar_visibilidade_controles_turno()
	get_tree().create_timer(1.5).timeout.connect(order_manager.iniciar_expediente)

func atualizar_hud() -> void:
	label_hud.text = "Dinheiro: R$ %.2f | Reputação: %.1f | Combo: %d" % [GameManager.dinheiro_atual, GameManager.reputacao, GameManager.combos_consecutivos]

func _aplicar_textura_cliente(tex: Texture2D) -> void:
	var escala := 1.0
	if is_instance_valid(order_manager) and order_manager.cliente_ativo and order_manager.cliente_atual != null:
		escala = clampf(order_manager.cliente_atual.escala_retrato_ui, 0.5, 2.0)
	sprite_cliente.scale = Vector2(escala, escala)
	sprite_cliente.modulate = Color.WHITE
	sprite_cliente.texture = tex

func _limpar_textura_cliente_sprite() -> void:
	sprite_cliente.texture = null
	sprite_cliente.scale = Vector2.ONE

func _on_pedido_gerado(nome_cliente: String, fala_recepcao: String, nome_sushi: String, tempo_limite: float, textura: Texture2D) -> void:
	if estado_atual != EstadoTurno.ABERTO: return
	_limpar_pilha_visual()
	label_dialogo.text = "[%s]: \"%s\"" % [nome_cliente, fala_recepcao]
	label_pedido.text = "Receita: %s\nIngredientes Esperados: %s" % [nome_sushi, str(order_manager.receita_esperada)]
	label_status.text = "Montando... (0 itens)"
	
	if textura:
		_aplicar_textura_cliente(textura)
	else:
		var placeholder := PlaceholderTexture2D.new()
		placeholder.size = sprite_cliente.custom_minimum_size
		_aplicar_textura_cliente(placeholder)

	atualizar_hud()
	_atualizar_visibilidade_controles_turno()

func _on_ingrediente_adicionado(_ing: String) -> void:
	label_status.text = "Montando... (%d itens)" % order_manager.montagem_atual.size()

	# Só considera completo quando bate com o pedido inteiro (inclui combos).
	if GameManager.montagem_confere_receita(order_manager.montagem_atual, order_manager.receita_esperada):
		_mostrar_sushi_finalizado(_nome_receita_para_arte_sushi_pronto())
	else:
		_esconder_sushi_pronto()

func _on_montagem_atualizada(array_montagem_atual: Array) -> void:
	var label_montagem: Label = dock_ingredientes.get_node_or_null("LabelMontagemAtual") as Label
	if not is_instance_valid(label_montagem):
		return
	label_montagem.text = "Montagem: %s" % _formatar_montagem_para_label(array_montagem_atual)

func _on_montagem_limpa() -> void:
	var label_montagem: Label = dock_ingredientes.get_node_or_null("LabelMontagemAtual") as Label
	if not is_instance_valid(label_montagem):
		return
	label_montagem.text = "Montagem: -"

func _on_lixeira_pressed() -> void:
	if not is_instance_valid(order_manager):
		return
	order_manager.limpar_montagem()
	_on_montagem_limpa()

func _formatar_montagem_para_label(montagem: Array) -> String:
	if montagem.is_empty():
		return "-"
	var partes: PackedStringArray = []
	for item in montagem:
		partes.append(_nome_legivel_item(str(item)))
	return " > ".join(partes)

func _nome_legivel_item(item: String) -> String:
	var nomes_legiveis: Dictionary = {
		"alga": "Alga",
		"arroz": "Arroz",
		"salmao": "Salmao",
		"cebolinha": "Cebolinha",
		"gergelim": "Gergelim",
		"cream_cheese": "Cream Cheese",
		"massa_empanar": "Massa Empanar",
		"faca": "Cortar",
		"esteira": "Enrolar",
		"fritadeira": "Fritar"
	}
	return str(nomes_legiveis.get(item, item.capitalize()))

func _nome_receita_para_arte_sushi_pronto() -> String:
	# Combo "Nigiri + Maki": usamos a arte do primeiro item (há uma chave em TEXTURAS_SUSHIS).
	var partes: PackedStringArray = order_manager.pedido_atual_nome.split(" + ")
	if partes.size() > 1:
		return partes[0]
	return order_manager.pedido_atual_nome

func _set_pilha_visual_ativa(ativa: bool) -> void:
	# Mostra/esconde apenas as "fatias" visuais (ColorRect) criadas pelo DropZone.
	for child in bancada.get_children():
		if child is ColorRect:
			(child as ColorRect).visible = ativa

func _get_cor_sushi_pronto(nome: String) -> Color:
	# Cores de feedback (substituíveis depois pela arte final).
	match nome:
		"Sashimi":
			return Color(0.2, 1.0, 0.2, 1.0)
		"Nigiri":
			return Color(1.0, 0.85, 0.2, 1.0)
		"Maki":
			return Color(0.2, 0.6, 1.0, 1.0)
		"Temaki":
			return Color(0.7, 0.4, 1.0, 1.0)
		"Uramaki":
			return Color(1.0, 0.6, 0.2, 1.0)
		"Filadelfia":
			return Color(1.0, 0.4, 0.6, 1.0)
		"Hot_Filadelfia":
			return Color(1.0, 0.2, 0.2, 1.0)
		_:
			return Color(1.0, 1.0, 1.0, 1.0)

func _mostrar_sushi_finalizado(nome: String) -> void:
	# Visualiza o sushi pronto e "transforma" a pilha: esconde as fatias da bancada.
	var path: String = TEXTURAS_SUSHIS.get(nome, "")
	# Se existir a arte pronta, usa; senão, cai no fallback visual.
	if path != "" and ResourceLoader.exists(path):
		sprite_sushi_pronto.texture = load(path)
		sprite_sushi_pronto.modulate = Color(1, 1, 1, 1)
	else:
		sprite_sushi_pronto.texture = null
		sprite_sushi_pronto.modulate = Color.GOLDENROD

	# Reset posição caso tenha sido animado no turno anterior.
	sprite_sushi_pronto.position = _sushi_pronto_pos_inicial
	sprite_sushi_pronto.show()
	_set_pilha_visual_ativa(false)

	# Feedback imediato (mais humano durante a montagem).
	label_status.text = "Sushi pronto: %s!" % nome

func _esconder_sushi_pronto() -> void:
	# Volta para o estado de "ingredientes na mesa".
	if is_instance_valid(sprite_sushi_pronto):
		sprite_sushi_pronto.hide()
		# Garante que na próxima "montagem" o sprite reaparece na posição correta.
		sprite_sushi_pronto.position = _sushi_pronto_pos_inicial
	_set_pilha_visual_ativa(true)

func _limpar_pilha_visual() -> void:
	# Usado no fim do pedido (entregue/tempo esgotado).
	# Mantém a cena limpa até o DropZone destruir as fatias no próximo pedido.
	_esconder_sushi_pronto()
	for child in bancada.get_children():
		if child is ColorRect:
			(child as ColorRect).visible = false

func _gerar_feedback_visual(sucesso: bool) -> void:
	# "Game Juice": pequenos ícones voam do cliente para o HUD.
	var cor := Color.GOLD if sucesso else Color.DARK_GRAY
	var quantidade := 5 if sucesso else 2

	for i in range(quantidade):
		var particula := Label.new()
		particula.text = "$" if sucesso else "!"
		particula.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particula.modulate = cor
		particula.modulate.a = 1.0
		particula.global_position = sprite_cliente.global_position + Vector2(
			randf_range(-50.0, 50.0),
			randf_range(-50.0, 50.0)
		)
		add_child(particula)

		var destino := particula.global_position + Vector2(
			randf_range(-120.0, 120.0),
			-220.0
		)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(particula, "global_position", destino, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(particula, "modulate:a", 0.0, 0.6)
		tween.finished.connect(particula.queue_free)

func _on_pedido_entregue(sucesso: bool, dinheiro: float, estrelas: float) -> void:
	if _jogo_finalizado:
		return
	_gerar_feedback_visual(sucesso)
	_entrega_em_andamento = false
	barra_tempo.hide()
	_limpar_textura_cliente_sprite()

	if sucesso:
		label_status.text = "Pedido entregue! Ganhou R$ %.2f" % dinheiro
		label_dialogo.text = "[%s]: Muito obrigado! Estava ótimo." % order_manager.cliente_atual.nome
	else:
		label_status.text = "O cliente não gostou do preparo..."
		label_dialogo.text = "[%s]: Eu não pedi isso! Que horror." % order_manager.cliente_atual.nome

	atualizar_hud()
	_limpar_pilha_visual()
	_atualizar_visibilidade_controles_turno()
	get_tree().create_timer(2.0).timeout.connect(order_manager.gerar_novo_pedido)

func _on_tempo_esgotado() -> void:
	if _jogo_finalizado:
		return
	barra_tempo.hide()
	_limpar_textura_cliente_sprite()

	label_status.text = "Tempo esgotado!"
	label_dialogo.text = "[%s]: Cansei de esperar. Vou comer no Jôw!" % order_manager.cliente_atual.nome

	atualizar_hud()
	_limpar_pilha_visual()
	_atualizar_visibilidade_controles_turno()
	get_tree().create_timer(2.0).timeout.connect(order_manager.gerar_novo_pedido)

func _on_expediente_encerrado() -> void:
	if _jogo_finalizado:
		return
	estado_atual = EstadoTurno.FECHADO
	label_pedido.text = "Expediente Encerrado!"
	label_status.text = "Limpando a bancada..."
	
	# Configura e exibe a tela de resumo
	label_resumo.text = "Fim do Dia %d\n\nFaturamento: R$ %.2f\nPedidos Perfeitos: %d\nErros/Perdas: %d" % [GameManager.dia_atual, GameManager.faturamento_dia, GameManager.acertos_dia, GameManager.erros_dia]
	painel_resumo.show()
	_atualizar_visibilidade_controles_turno()

func _on_btn_abrir_pressed() -> void:
	abrir_restaurante()

func _on_btn_entregar_pressed() -> void:
	if _jogo_finalizado:
		return
	if _entrega_em_andamento:
		return
	if not order_manager.cliente_ativo:
		return

	# Se o sushi pronto estiver visível, animamos a entrega antes de entregar.
	if sprite_sushi_pronto.visible and is_instance_valid(sprite_sushi_pronto):
		var tween := create_tween()
		# Voar em direção ao cliente (na prática: animação global).
		var alvo: Vector2 = sprite_cliente.global_position
		_entrega_em_andamento = true
		tween.tween_property(
			sprite_sushi_pronto,
			"global_position",
			alvo,
			0.3
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func() -> void:
			_entrega_em_andamento = false
			order_manager.entregar_pedido()
		)
	else:
		# Entrega de erro (sem sushi pronto).
		order_manager.entregar_pedido()
func _on_btn_proximo_dia_pressed() -> void:
	if _jogo_finalizado:
		return
	painel_resumo.hide()
	painel_loja.show()
	_atualizar_botoes_loja()
	_atualizar_visibilidade_controles_turno()

func _atualizar_botoes_loja() -> void:
	$PainelLoja/VBox/LabelTituloLoja.text = "Loja - Saldo: R$ %.2f" % GameManager.dinheiro_atual
	
	_configurar_botao_compra("cebolinha", $PainelLoja/VBox/HBoxCebolinha/BtnComprarCebolinha)
	_configurar_botao_compra("gergelim", $PainelLoja/VBox/HBoxGergelim/BtnComprarGergelim)
	_configurar_botao_compra("cream_cheese", $PainelLoja/VBox/HBoxCreamCheese/BtnComprarCreamCheese)
	_configurar_botao_compra("massa_empanar", $PainelLoja/VBox/HBoxMassaEmpanar/BtnComprarMassaEmpanar)

func _configurar_botao_compra(item: String, botao: Button) -> void:
	if GameManager.ingredientes_desbloqueados[item]:
		botao.text = "Comprado"
		botao.disabled = true
	else:
		var custo = GameManager.CUSTO_DESBLOQUEIO[item]
		botao.text = "Comprar (R$ %.2f)" % custo
		botao.disabled = GameManager.dinheiro_atual < custo

func _tentar_comprar(item: String) -> void:
	if _jogo_finalizado:
		return
	var custo = GameManager.CUSTO_DESBLOQUEIO[item]
	if GameManager.dinheiro_atual >= custo:
		GameManager.dinheiro_atual -= custo
		GameManager.ingredientes_desbloqueados[item] = true
		_atualizar_botoes_loja()
		_atualizar_visibilidade_controles_turno()
		atualizar_label_estoque()
		atualizar_hud()

func _on_btn_comprar_cebolinha_pressed() -> void: _tentar_comprar("cebolinha")
func _on_btn_comprar_gergelim_pressed() -> void: _tentar_comprar("gergelim")
func _on_btn_comprar_cream_cheese_pressed() -> void: _tentar_comprar("cream_cheese")
func _on_btn_comprar_massa_empanar_pressed() -> void: _tentar_comprar("massa_empanar")

func _on_btn_voltar_loja_pressed() -> void:
	if _jogo_finalizado:
		return
	painel_loja.hide()
	GameManager.avancar_dia()
	preparar_novo_dia()

func _on_restaurante_falido() -> void:
	_jogo_finalizado = true
	estado_atual = EstadoTurno.FECHADO
	order_manager.timer_pedido.stop()
	
	# Bloqueia UI e evita ações/timers do turno atual.
	painel_resumo.hide()
	painel_loja.hide()
	$BtnAbrir.hide()
	_set_botoes_preparo_desabilitados(true)
	_atualizar_visibilidade_controles_turno()

	# Preenche os dados da derrota
	$PainelGameOver/VBox/LabelEstatisticas.text = "Dias sobrevividos: %d\nDinheiro acumulado: R$ %.2f" % [GameManager.dia_atual, GameManager.dinheiro_atual]
	$PainelGameOver/VBox/LabelMotivo.text = "A sua reputação chegou a zero. O Su XIII fechou as portas."
	
	# Se o último cliente foi o Jôw, podemos dar um "toque especial"
	if order_manager.cliente_atual is ClienteJow:
		$PainelGameOver/VBox/LabelMotivo.text = "O Jôw espalhou boatos terríveis sobre a sua comida. Você faliu!"
	
	painel_game_over.show()

func _on_btn_reiniciar_pressed() -> void:
	# Reset total do singleton para o estado de "Novo Jogo"
	GameManager.dinheiro_atual = 0.0
	GameManager.reputacao = 5.0
	GameManager.dia_atual = 1
	# Opcional: resetar ingredientes_desbloqueados para o padrão inicial
	get_tree().reload_current_scene()
