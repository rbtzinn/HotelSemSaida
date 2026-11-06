class_name GuestBook3D
extends NoteInteractable3D
## Livro de hóspedes da recepção. Hoje, ganha um nome por capítulo terminado, e a assinatura
## úmida da última linha fica mais legível. Em 1923, depois de destrancar a entrada, Helena
## assina o próprio nome. Ler o nome de Lia depois de sair pela entrada encerra o jogo.

const HELENA_SIGNED := "saguao.livro.helena"
const ENTRANCE_UNLOCKED := "saguao.entrada.trava_1923"
const FINAL := "jogo.final"
const ENDED := "jogo.encerrado"
const CHAPTERS := ["cozinha.concluida", "biblioteca.concluida", "caldeiras.concluida"]
## Um trecho por desaparecido, na ordem das gerações.
const NAMES := [
	["cozinha.concluida", "Mais acima, um nome que você não tinha notado: Otília, cozinheira. A coluna \"Saída\" está vazia.\n\nA letra é a mesma do lápis no cardápio: \"3 8\"."],
	["biblioteca.concluida", "Dr. Caio Ferraz, 1951, quarto 214. Saída: em branco. Ao lado, alguém escreveu a lápis: \"médico — não saiu\"."],
	["saguao.bolsa.marta", "Marta Siqueira, 1979, \"imprensa\". Saída: em branco. A assinatura dela tem a mesma tinta úmida da última linha."],
	["caldeiras.concluida", "Tomás Reis, 2003. Não é letra de hóspede: está escrito por cima, na margem, como quem assina sem ninguém pedir."],
]


func _on_interact(by: FirstPersonMotor) -> void:
	if by.era == Era.Id.PAST_1923:
		NoteUI.open(get_tree(), title, _past_text(), photograph)
		return
	var ui := NoteUI.open(get_tree(), title, present_text(), photograph)
	if WorldState.is_set(FINAL) and not WorldState.is_set(ENDED):
		# O fim só vem depois de fechar a leitura
		ui.tree_exited.connect(func() -> void: WorldState.set_flag(ENDED))


func _past_text() -> String:
	var full := text
	if WorldState.is_set(HELENA_SIGNED):
		full += "\n\nSeu nome está na linha, com a tinta já seca. A coluna \"Saída\" continua em branco."
	elif WorldState.is_set(ENTRANCE_UNLOCKED):
		WorldState.set_flag(HELENA_SIGNED)
		full += "\n\nSua linha de chegada ficou em branco. Se a porta não deixa sair, que ao menos fique o registro." \
			+ "\n\nVocê escreve o seu nome. A coluna \"Saída\" fica esperando."
	return full


static func present_text() -> String:
	var parts: Array[String] = ["O livro está mofado. Na coluna \"Saída\", várias linhas em branco."]
	if WorldState.is_set(HELENA_SIGNED):
		parts.append("Na primeira página, em 1923: Helena. A coluna \"Saída\" está em branco.")
	for entry: Array in NAMES:
		if WorldState.is_set(entry[0]):
			parts.append(entry[1])
	if WorldState.is_set(FINAL):
		parts.append("A última linha tem a data de hoje. A tinta ainda está úmida, e agora dá para ler a assinatura: Lia." \
			+ "\n\nA coluna \"Saída\" está em branco.")
	else:
		var last := "A última linha tem a data de hoje, e a tinta ainda está úmida. Uma assinatura recente. A letra parece familiar."
		var done := 0
		for flag: String in CHAPTERS:
			done += 1 if WorldState.is_set(flag) else 0
		if done >= 2:
			last += " A primeira letra parece um L."
		parts.append(last)
	return "\n\n".join(parts)
