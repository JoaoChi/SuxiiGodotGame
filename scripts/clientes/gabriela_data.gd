extends ClienteData
class_name ClienteGabriela

func _init() -> void:
	nome = "Gabriela"
	escala_retrato_ui = 1.32
	falas_recepcao = [
		"Boa noite. Um %s. Sem alterações.",
		"Com licença. Um %s, por favor. E seja rápido."
	]
	var path := "res://features/customes/gabriela.png"
	if ResourceLoader.exists(path):
		textura_pixel_art = load(path)

func calcular_resultado(pedido_nome: String, montagem_atual: Array, receita_esperada: Array, _tempo_restante: float) -> Dictionary:
	var sucesso_perfeito = (montagem_atual == receita_esperada)
	# Combo: exemplo "Maki + Sashimi". Somamos os preços das partes.
	var preco_base: float = 0.0
	for parte in pedido_nome.split(" + "):
		preco_base += GameManager.PRECOS_BASE.get(parte, 10.0)
	
	# Recalcula o tempo total da receita para tirar a porcentagem
	var tempo_total = 10.0 + (receita_esperada.size() * 3.0)
	var foi_rapido = _tempo_restante >= (tempo_total * 0.5) # Bônus se feito na metade do tempo
	
	var dinheiro: float = 0.0
	var estrelas: float = 0.0
	
	if sucesso_perfeito:
		dinheiro = preco_base
		estrelas = 1.0
		if foi_rapido:
			dinheiro *= 1.5
	else:
		dinheiro = 0.0
		estrelas = -2.0
			
	return {"dinheiro": dinheiro, "estrelas": estrelas, "sucesso": sucesso_perfeito}
