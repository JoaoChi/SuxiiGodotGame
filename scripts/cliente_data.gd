extends Resource
class_name ClienteData

@export var nome: String = "Cliente Anônimo"
# Ideal: PNGs em features/customes com o mesmo tamanho de canvas; o jogo força o mesmo retângulo na UI.
@export var textura_pixel_art: Texture2D
@export var falas_recepcao: Array[String] = ["Um sushi, por favor."]
## Útil quando o desenho ocupa menos o quadro que os outros (ex.: casal, retratos afastados).
var escala_retrato_ui: float = 1.0
## Parte superior da textura (0–1) que permanece visível; o restante simula pernas atrás do balcão.
var fracao_retrato_tronco: float = 0.52
## Multiplicador da largura do retângulo do retrato (ex.: arte larga com duas pessoas).
var retrato_largura_mul: float = 1.0
## Multiplica a faixa vertical do layout (mantém proporção entre “tronco” e recorte).
var retrato_altura_slot_mul: float = 1.0
## Soma em px ao deslocamento vertical global (positivo = retrato mais alto na tela).
var retrato_subir_extra_px: float = 0.0

# Retorna um dicionário com o resultado financeiro e de reputação da interação
func calcular_resultado(pedido_nome: String, montagem_atual: Array, receita_esperada: Array, tempo_restante: float) -> Dictionary:
	var sucesso_perfeito = (montagem_atual == receita_esperada)
	# Combo: exemplo "Maki + Sashimi". Somamos os preços das partes.
	var preco_base: float = 0.0
	for parte in pedido_nome.split(" + "):
		preco_base += GameManager.PRECOS_BASE.get(parte, 10.0)
	
	var dinheiro: float = 0.0
	var estrelas: float = 0.0
	
	if sucesso_perfeito:
		dinheiro = preco_base + (tempo_restante * 0.5)
		estrelas = 1.0
	else:
		if montagem_atual.size() > 0 and montagem_atual[0] == receita_esperada[0]:
			dinheiro = preco_base * 0.4 # Erro parcial
			estrelas = -0.5
		else:
			estrelas = -1.0 # Erro total
			
	return {"dinheiro": dinheiro, "estrelas": estrelas, "sucesso": sucesso_perfeito}
