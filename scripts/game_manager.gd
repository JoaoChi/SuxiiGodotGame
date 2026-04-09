extends Node

const SAVE_PATH := "user://suxii_save.json"
const SAVE_VERSION := 1

## Definido pelo menu antes de trocar para a cena do jogo: "novo_jogo", "continuar" ou "".
var modo_entrada: String = ""

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


func tem_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func apagar_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.remove(SAVE_PATH.get_file())


func resetar_para_novo_jogo() -> void:
	dinheiro_atual = 0.0
	reputacao = 5.0
	dia_atual = 1
	combos_consecutivos = 0
	faturamento_dia = 0.0
	acertos_dia = 0
	erros_dia = 0
	ingredientes_desbloqueados = {
		"arroz": true,
		"salmao": true,
		"alga": true,
		"cebolinha": false,
		"gergelim": false,
		"cream_cheese": false,
		"massa_empanar": false,
		"faca": true,
		"esteira": true,
		"fritadeira": true
	}
	ingredientes_comprados = {
		"cebolinha": false,
		"gergelim": false,
		"cream_cheese": false,
		"massa_empanar": false
	}
	estoque_bancada = _estoque_inicial()
	_reaplicar_desbloqueios_por_dia_e_compra()
	emit_signal("estoque_alterado")
	emit_signal("status_atualizado")


func para_dicionario_save() -> Dictionary:
	return {
		"dinheiro_atual": dinheiro_atual,
		"reputacao": reputacao,
		"dia_atual": dia_atual,
		"combos_consecutivos": combos_consecutivos,
		"faturamento_dia": faturamento_dia,
		"acertos_dia": acertos_dia,
		"erros_dia": erros_dia,
		"ingredientes_desbloqueados": ingredientes_desbloqueados.duplicate(true),
		"ingredientes_comprados": ingredientes_comprados.duplicate(true),
		"estoque_bancada": estoque_bancada.duplicate(true)
	}


func aplicar_dicionario_save(d: Dictionary) -> void:
	if d.is_empty():
		return
	dinheiro_atual = float(d.get("dinheiro_atual", 0.0))
	reputacao = clampf(float(d.get("reputacao", 5.0)), 0.0, 5.0)
	dia_atual = maxi(1, int(d.get("dia_atual", 1)))
	combos_consecutivos = int(d.get("combos_consecutivos", 0))
	faturamento_dia = float(d.get("faturamento_dia", 0.0))
	acertos_dia = int(d.get("acertos_dia", 0))
	erros_dia = int(d.get("erros_dia", 0))
	var desb: Variant = d.get("ingredientes_desbloqueados", {})
	if typeof(desb) == TYPE_DICTIONARY:
		for k in ingredientes_desbloqueados.keys():
			if desb.has(k):
				ingredientes_desbloqueados[k] = bool(desb[k])
	var comp: Variant = d.get("ingredientes_comprados", {})
	if typeof(comp) == TYPE_DICTIONARY:
		for k in ingredientes_comprados.keys():
			if comp.has(k):
				ingredientes_comprados[k] = bool(comp[k])
	var est: Variant = d.get("estoque_bancada", {})
	if typeof(est) == TYPE_DICTIONARY:
		for k in estoque_bancada.keys():
			if est.has(k):
				estoque_bancada[k] = int(est[k])
	_reaplicar_desbloqueios_por_dia_e_compra()
	emit_signal("estoque_alterado")
	emit_signal("status_atualizado")


func ler_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var texto := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(texto) != OK:
		return {}
	var raiz: Variant = json.data
	if typeof(raiz) != TYPE_DICTIONARY:
		return {}
	return raiz


func gravar_save(payload: Dictionary) -> void:
	var saida := {"version": SAVE_VERSION}
	for k in payload.keys():
		saida[k] = payload[k]
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(saida, "\t"))
	f.close()
