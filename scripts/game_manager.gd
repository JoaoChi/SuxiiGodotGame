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
	"massa_empanar": false
}

const CUSTO_DESBLOQUEIO: Dictionary = {
	"cebolinha": 50.0,
	"gergelim": 75.0,
	"cream_cheese": 100.0,
	"massa_empanar": 150.0
}

const RECEITAS: Dictionary = {
	"Sashimi": ["salmao", "salmao", "salmao"],
	"Nigiri": ["arroz", "salmao"],
	"Maki": ["alga", "arroz", "salmao"],
	"Temaki": ["alga", "arroz", "salmao", "cebolinha"],
	"Uramaki": ["arroz", "alga", "salmao", "gergelim"],
	"Filadelfia": ["alga", "arroz", "salmao", "cream_cheese"],
	"Hot_Filadelfia": ["alga", "arroz", "salmao", "cream_cheese", "massa_empanar"]
}

const PRECOS_BASE: Dictionary = {
	"Sashimi": 15.0, "Nigiri": 10.0, "Maki": 12.0, "Temaki": 20.0,
	"Uramaki": 14.0, "Filadelfia": 18.0, "Hot_Filadelfia": 22.0
}

## Compara montagem com receita como multiconjuntos (ordem dos ingredientes ignora).
func montagem_confere_receita(montagem: Array, receita: Array) -> bool:
	if montagem.size() != receita.size():
		return false
	var contagens: Dictionary = {}
	for ing in montagem:
		contagens[ing] = int(contagens.get(ing, 0)) + 1
	for ing in receita:
		if not contagens.has(ing):
			return false
		contagens[ing] = int(contagens[ing]) - 1
	for v in contagens.values():
		if int(v) != 0:
			return false
	return true

# Custos fixos para reposição de estoque em lotes.
const CUSTO_REPOSICAO_BASICO: float = 15.0 # Custo para repor itens básicos (arroz, salmão, alga)
const CUSTO_REPOSICAO_ESPECIAL: float = 25.0 # Custo para repor itens especiais (cebolinha, gergelim, cream cheese, etc.)

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

func consumir_estoque(item: String) -> bool:
	if estoque_bancada.get(item, 0) > 0:
		estoque_bancada[item] -= 1
		emit_signal("estoque_alterado")
		return true
	return false

func repor_estoque(item: String, quantidade: int, custo: float) -> bool:
	if dinheiro_atual >= custo:
		dinheiro_atual -= custo
		estoque_bancada[item] = estoque_bancada.get(item, 0) + quantidade
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

func resetar_dia() -> void:
	combos_consecutivos = 0
	faturamento_dia = 0.0
	acertos_dia = 0
	erros_dia = 0
	estoque_bancada = _estoque_inicial()
	emit_signal("estoque_alterado")

func avancar_dia() -> void:
	dia_atual += 1
	resetar_dia()
