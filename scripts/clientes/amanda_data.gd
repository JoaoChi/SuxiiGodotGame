extends ClienteData
class_name ClienteAmanda

func _init() -> void:
	nome = "Amanda"
	falas_recepcao = [
		"Oii! Cheguei! Já tô gravando! Então… hoje eu quero um %s bem caprichado, tá?",
		"Bom diaaa! Já gostei da vibe daqui. Prepara um %s pra mim, bem alinhadinho."
	]
	var path := "res://features/customes/amanda.png"
	if ResourceLoader.exists(path):
		textura_pixel_art = load(path)

# Sobrescreve a lógica base com o comportamento anômalo da Amanda
func calcular_resultado(pedido_nome: String, montagem_atual: Array, receita_esperada: Array, tempo_restante: float) -> Dictionary:
	var sucesso_perfeito = (montagem_atual == receita_esperada)
	# Combo: exemplo "Maki + Sashimi". Somamos os preços das partes.
	var preco_base: float = 0.0
	for parte in pedido_nome.split(" + "):
		preco_base += GameManager.PRECOS_BASE.get(parte, 10.0)
	
	var dinheiro: float = 0.0
	var estrelas: float = 0.0
	
	if sucesso_perfeito:
		# Tira foto e vai embora sem pagar, mas gera reputação máxima
		dinheiro = 0.0 
		if tempo_restante > 10.0:
			dinheiro += 5.0 # Dá gorjeta se for muito rápido
		estrelas = 2.0 # Bônus de influencer
	else:
		if montagem_atual.size() > 0 and montagem_atual[0] == receita_esperada[0]:
			# Reclama, mas paga o sushi
			dinheiro = preco_base 
			estrelas = -0.5
		else:
			# Desdenha e vai embora sem pagar
			dinheiro = 0.0
			estrelas = -2.0 
			
	return {"dinheiro": dinheiro, "estrelas": estrelas, "sucesso": sucesso_perfeito}
