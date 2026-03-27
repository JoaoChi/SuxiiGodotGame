extends Node

signal estoque_alterado
signal restaurante_falido # Novo sinal
signal status_atualizado

var dinheiro_atual: float = 0.0
var reputacao: float = 5.0 
var dia_atual: int = 1
var combos_consecutivos: int = 0

# Métricas do Turno
var faturamento_dia: float = 0.0
var acertos_dia: int = 0
var erros_dia: int = 0

# SISTEMA DE LOJA / INVENTÁRIO
# Começamos apenas com os básicos liberados
var ingredientes_desbloqueados: Dictionary = {
	"arroz": true,
	"salmao": true,
	"alga": true,
	"cebolinha": false,
	"gergelim": false,
	"cream_cheese": false,
	"massa_empanar": false,
	# Ferramentas são permanentes e sempre disponíveis.
	"faca": true,
	"esteira": true,
	"fritadeira": true
}

var ingredientes_comprados: Dictionary = {
	"cebolinha": false,
	"gergelim": false,
	"cream_cheese": false,
	"massa_empanar": false
}

const CUSTO_DESBLOQUEIO: Dictionary = {
	"cebolinha": 50.0,
	"gergelim": 75.0,
	"cream_cheese": 100.0,
	"massa_empanar": 150.0
}

const RECEITAS: Dictionary = {
	"Sashimi": ["salmao", "salmao", "salmao", "faca"],
	"Nigiri": ["arroz", "salmao"],
	"Maki": ["alga", "arroz", "salmao", "esteira", "faca"],
	"Temaki": ["alga", "arroz", "salmao", "cebolinha", "esteira"],
	"Uramaki": ["arroz", "alga", "salmao", "gergelim", "esteira", "faca"],
	"Hot_Filadelfia": ["alga", "arroz", "salmao", "cream_cheese", "esteira", "massa_empanar", "fritadeira", "faca"]
}

const PROGRESSAO_DIAS: Dictionary = {
	1: {
		"receitas_liberadas": ["Nigiri", "Sashimi"],
		"paciencia_base": 40.0,
		"ingredientes_iniciais": ["arroz", "salmao", "faca"]
	},
	2: {
		"receitas_liberadas": ["Nigiri", "Sashimi", "Maki"],
		"paciencia_base": 35.0,
		"ingredientes_iniciais": ["arroz", "salmao", "alga", "faca", "esteira"]
	},
	3: {
		"receitas_liberadas": ["Nigiri", "Sashimi", "Maki", "Temaki"],
		"paciencia_base": 30.0,
		"ingredientes_iniciais": ["arroz", "salmao", "alga", "cebolinha", "faca", "esteira"]
	},
	4: {
		"receitas_liberadas": ["Nigiri", "Sashimi", "Maki", "Temaki", "Uramaki"],
		"paciencia_base": 27.0,
		"ingredientes_iniciais": ["arroz", "salmao", "alga", "cebolinha", "gergelim", "faca", "esteira"]
	},
	5: {
		"receitas_liberadas": ["Nigiri", "Sashimi", "Maki", "Temaki", "Uramaki", "Hot_Filadelfia"],
		"paciencia_base": 24.0,
		"ingredientes_iniciais": ["arroz", "salmao", "alga", "cebolinha", "gergelim", "cream_cheese", "massa_empanar", "faca", "esteira", "fritadeira"]
	}
}

const PRECOS_BASE: Dictionary = {
	"Sashimi": 15.0, "Nigiri": 10.0, "Maki": 12.0, "Temaki": 20.0,
	"Uramaki": 14.0, "Filadelfia": 18.0, "Hot_Filadelfia": 22.0
}

const MERCADO: Dictionary = {
	"arroz": {"custo": 5.0, "rendimento": 20, "nome": "Pacote de Arroz"},
	"salmao": {"custo": 35.0, "rendimento": 10, "nome": "Salmão Inteiro"},
	"alga": {"custo": 10.0, "rendimento": 20, "nome": "Pacote de Nori"},
	"cebolinha": {"custo": 8.0, "rendimento": 15, "nome": "Maço de Cebolinha"},
	"gergelim": {"custo": 12.0, "rendimento": 20, "nome": "Pote de Gergelim"},
	"cream_cheese": {"custo": 15.0, "rendimento": 10, "nome": "Bisnaga de Cream Cheese"},
	"massa_empanar": {"custo": 8.0, "rendimento": 10, "nome": "Pacote de Panko"}
}

## Valida montagem em sequência estrita: ordem e tamanho precisam bater.
func montagem_confere_receita(montagem: Array, receita: Array) -> bool:
	if montagem.size() != receita.size():
		return false

	for i in range(receita.size()):
		if montagem[i] != receita[i]:
			return false
	return true

# Bancada: básicos com carga inicial; especiais começam em 0 (preparo obrigatório).
var estoque_bancada: Dictionary = {
	"arroz": 10,
	"salmao": 10,
	"alga": 10,
	"cebolinha": 0,
	"gergelim": 0,
	"cream_cheese": 0,
	"massa_empanar": 0,
}

func _estoque_inicial() -> Dictionary:
	return {
		"arroz": 10,
		"salmao": 10,
		"alga": 10,
		"cebolinha": 0,
		"gergelim": 0,
		"cream_cheese": 0,
		"massa_empanar": 0,
	}

func desbloquear_ingrediente(item: String) -> void:
	if not ingredientes_desbloqueados.has(item):
		return
	ingredientes_desbloqueados[item] = true
	if ingredientes_comprados.has(item):
		ingredientes_comprados[item] = true

func _reaplicar_desbloqueios_por_dia_e_compra() -> void:
	var dados_dia: Dictionary = get_progressao_dia()
	var ingredientes_iniciais: Array = dados_dia.get("ingredientes_iniciais", [])

	for chave in ingredientes_desbloqueados.keys():
		ingredientes_desbloqueados[chave] = false

	# Ferramentas sao permanentes e sempre habilitadas.
	for ferramenta in ["faca", "esteira", "fritadeira"]:
		ingredientes_desbloqueados[ferramenta] = true

	# Habilita o que a progressao do dia libera.
	for item in ingredientes_iniciais:
		var item_str: String = str(item)
		if ingredientes_desbloqueados.has(item_str):
			ingredientes_desbloqueados[item_str] = true

	# Mantem liberado tudo que foi comprado na loja.
	for item in ingredientes_comprados.keys():
		if bool(ingredientes_comprados[item]):
			ingredientes_desbloqueados[item] = true

func consumir_estoque(item: String) -> bool:
	if item in ["faca", "esteira", "fritadeira"]:
		return true

	if not MERCADO.has(item):
		return false

	var quantidade_atual: int = int(estoque_bancada.get(item, 0))
	if quantidade_atual > 0:
		estoque_bancada[item] = quantidade_atual - 1
		emit_signal("estoque_alterado")
		return true

	return false

func repor_estoque(item: String) -> bool:
	if not MERCADO.has(item):
		return false

	var dados: Dictionary = MERCADO[item]
	var custo: float = float(dados.get("custo", 0.0))
	var rendimento: int = int(dados.get("rendimento", 0))
	if rendimento <= 0:
		return false

	if dinheiro_atual >= custo:
		dinheiro_atual -= custo
		estoque_bancada[item] = int(estoque_bancada.get(item, 0)) + rendimento
		emit_signal("estoque_alterado")
		emit_signal("status_atualizado")
		return true
	return false

func adicionar_dinheiro(valor: float) -> void:
	dinheiro_atual += valor
	faturamento_dia += valor

func processar_reputacao(valor: float) -> void:
	reputacao += valor
	reputacao = clamp(reputacao, 0.0, 5.0)
	emit_signal("status_atualizado")
	
	if reputacao <= 0.0:
		emit_signal("restaurante_falido")

func get_progressao_dia(dia: int = -1) -> Dictionary:
	if PROGRESSAO_DIAS.is_empty():
		return {}

	var dia_consulta: int = dia_atual if dia < 0 else dia
	var maior_dia: int = 1
	for chave in PROGRESSAO_DIAS.keys():
		var chave_int: int = int(chave)
		if chave_int > maior_dia:
			maior_dia = chave_int

	var dia_efetivo: int = mini(maxi(dia_consulta, 1), maior_dia)
	return PROGRESSAO_DIAS.get(dia_efetivo, PROGRESSAO_DIAS.get(maior_dia, {}))

func resetar_dia() -> void:
	combos_consecutivos = 0
	faturamento_dia = 0.0
	acertos_dia = 0
	erros_dia = 0

	_reaplicar_desbloqueios_por_dia_e_compra()
	estoque_bancada = _estoque_inicial()
	emit_signal("estoque_alterado")

func avancar_dia() -> void:
	dia_atual += 1
	resetar_dia()
