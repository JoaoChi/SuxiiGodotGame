extends ClienteData
class_name ClienteCasal

func _init() -> void:
	nome = "João e Milena"
	# Dois rostos: arte larga + zoom maior; slot mais alto e sobe o quadro para aparecer acima do balcão.
	escala_retrato_ui = 1.4
	fracao_retrato_tronco = 0.62
	retrato_largura_mul = 2.55
	retrato_altura_slot_mul = 1.16
	retrato_subir_extra_px = 67.0
	falas_recepcao = [
		"João: Boa noite, vai ser um %s e um hambúrguer pra ela. Como assim não tem hambúrguer?? Milena: Aff ta, pode ser o mesmo!",
		"Milena: Eu jurava que era hambúrguer… João: Tá, tudo bem. Vamos de %s então, por favor."
	]
	var path := "res://features/customes/casal.png"
	if ResourceLoader.exists(path):
		textura_pixel_art = load(path)

func calcular_resultado(pedido_nome: String, montagem_atual: Array, receita_esperada: Array, _tempo_restante: float) -> Dictionary:
	var sucesso_perfeito = (montagem_atual == receita_esperada)
	# Combo: exemplo "Maki + Sashimi". Somamos os preços das partes.
	var preco_base: float = 0.0
	for parte in pedido_nome.split(" + "):
		preco_base += GameManager.PRECOS_BASE.get(parte, 10.0)
	
	# O Casal SEMPRE paga o valor base, independente de estar certo ou errado.
	var dinheiro: float = preco_base
	var estrelas: float = 0.0
	
	if sucesso_perfeito:
		estrelas = 1.0 # Ficam surpresos e felizes
	else:
		estrelas = 0.5 # Acharam a "aventura" diferente, dão meia estrela
			
	return {"dinheiro": dinheiro, "estrelas": estrelas, "sucesso": sucesso_perfeito}
