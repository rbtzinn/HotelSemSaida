class_name MartaBag3D
extends NoteInteractable3D
## Bolsa de câmera de Marta, no fundo do poço do elevador. Ao examinar, Lia lê a foto e,
## com a mão livre, solta a chave miúda da etiqueta (abre o cadeado de 1979 da entrada).

const READ := "saguao.bolsa.marta"
const TAKEN := "saguao.chave.marta"
const KEY := "chave_portaria"
const STORY := "Uma cópia da fotografia da oficina. Desta vez dá para ler a borda inteira.\n\n" \
	+ "«Última chapa. Se a luz falhar outra vez, revelo o resto em casa.»\n\nMarta Siqueira, 1979."


func _on_interact(by: FirstPersonMotor) -> void:
	var ending := "No bolso do filme, só a etiqueta de pano. Ainda se lê PORTARIA."
	if not WorldState.is_set(TAKEN):
		if by.get_held_item() == "":
			by.set_held_item(KEY)
			WorldState.set_flag(TAKEN)
			ending = "No bolso do filme há uma chave miúda presa a uma etiqueta de pano. Ainda se lê PORTARIA.\n\n" \
				+ "Você solta a chave e a guarda."
		else:
			ending = "No bolso do filme há uma chave miúda presa a uma etiqueta de pano. Ainda se lê PORTARIA.\n\n" \
				+ "Com a mão ocupada, você a deixa onde está."
	WorldState.set_flag(READ)
	NoteUI.open(get_tree(), title, STORY + " " + ending, photograph)
