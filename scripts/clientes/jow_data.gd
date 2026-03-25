extends ClienteData
class_name ClienteJow

func _init() -> void:
	nome = "Jôw (Rival)"
	falas_recepcao = [
		"Olha só… você é o chef daqui? Tá. Faz um %s pra mim… e tenta não estragar.",
		"Vamos ver se você sabe mesmo o que tá fazendo. Um %s, caprichado. Ou pelo menos tenta."
	]
	var path := "res://features/customes/jow.png"
	if ResourceLoader.exists(path):
		textura_pixel_art = load(path)

func calcular_resultado(pedido_nome: String, montagem_atual: Array, receita_esperada: Array, tempo_restante: float) -> Dictionary:
	var sucesso_perfeito = (montagem_atual == receita_esperada)
	# Combo: exemplo "Maki + Sashimi". Somamos os preços das partes.
	var preco_base: float = 0.0
	for parte in pedido_nome.split(" + "):
		preco_base += GameManager.PRECOS_BASE.get(parte, 10.0)
	
	var dinheiro: float = 0.0
	var estrelas: float = 0.0
	
	if sucesso_perfeito:
		dinheiro = preco_base + 15.0 # Dá uma gorjeta alta disfarçada de crítica
		estrelas = 1.5
	else:
		dinheiro = 0.0
		estrelas = -3.0 # Punição severa na reputação do restaurante
			
	return {"dinheiro": dinheiro, "estrelas": estrelas, "sucesso": sucesso_perfeito}
