class_name KeyDoor3D
extends Door3D
## A Biblioteca funciona normalmente em 1923. A fechadura atual exige uma chave
## encontrada na manutenção; destrancá-la hoje não altera nada no passado.
@export var key_item: String = "chave_biblioteca"
@export var unlock_flag: String = "biblioteca.porta.hoje"

func _on_interact(by: FirstPersonMotor) -> void:
	if by.era == Era.Id.PRESENT and not WorldState.is_set(unlock_flag):
		if by.get_held_item() != key_item:
			say("A fechadura tem o desenho de um livro aberto.")
			return
		WorldState.set_flag(unlock_flag)
		by.set_held_item("")
		say("A chave gira na fechadura.")
	super(by)
