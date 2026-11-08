class_name MartaBag3D
extends NoteInteractable3D
## Bolsa de câmera de Marta, no fundo do poço do elevador. Examinar só lê a foto; a chave miúda
## (abre o cadeado de 1979 da entrada) é pega à parte, para Lia não subir os andares com a mão ocupada.

const READ := "saguao.bolsa.marta"
const TAKEN := "saguao.chave.marta"
const KEY := "chave_portaria"
const STORY := "Uma cópia da fotografia da oficina. Desta vez dá para ler a borda inteira.\n\n" \
	+ "«Última chapa. Se a luz falhar outra vez, revelo o resto em casa.»\n\n" \
	+ "No verso: «O Dr. Ferraz morava no 214. A gerência nunca mais abriu o andar.»\n\nMarta Siqueira, 1979."


func _on_interact(_by: FirstPersonMotor) -> void:
	var ending := "\n\nNo bolso do filme, só a etiqueta de pano. Ainda se lê PORTARIA." if WorldState.is_set(TAKEN) \
		else "\n\nNo bolso do filme há uma chave miúda presa a uma etiqueta de pano. Ainda se lê PORTARIA."
	WorldState.set_flag(READ)
	NoteUI.open(get_tree(), title, STORY + ending, photograph)
