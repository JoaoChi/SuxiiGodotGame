extends ClienteData
class_name ClienteJoao

func _init() -> void:
	nome = "João"
	falas_recepcao = [
		"Oi… é… eu queria um %s… do jeito certo, se der…",
		"Boa… boa noite. Um %s, por favor… eu… gosto bem específico."
	]
	var path := "res://features/customes/joao.png"
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
		dinheiro = preco_base + 5.0 # Bônus fixo de felicidade
		estrelas = 1.0
	else:
		if montagem_atual.size() > 0 and montagem_atual[0] == receita_esperada[0]:
			dinheiro = preco_base * 0.8 # Penalidade muito leve, ele é compreensivo
			estrelas = 0.0 # Neutro, só fica triste
		else:
			dinheiro = 0.0
			estrelas = -0.5 # Não pune duramente a reputação
			
	return {"dinheiro": dinheiro, "estrelas": estrelas, "sucesso": sucesso_perfeito}
