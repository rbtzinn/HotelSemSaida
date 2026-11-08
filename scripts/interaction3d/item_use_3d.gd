class_name ItemUse3D
extends Interactable3D
## Lugar onde a personagem usa o objeto que tem na mão (ex.: fermento no forno).
## Com o objeto certo: esvazia a mão e liga `result_flag`. Sem ele: só uma descrição.

@export var accepted_item: String = ""
@export var result_flag: String = ""
@export var success_message: String = ""
## Mensagem com a mão vazia ou com outro objeto. Descreve, não dá dica.
@export var idle_message: String = "Nada acontece."


## Som ao usar (ver Interactable3D.sound).
func _default_sound() -> String:
	return "pegar"


func _ready() -> void:
	if done_flag == "":
		done_flag = result_flag
	super()


func _on_interact(by: FirstPersonMotor) -> void:
	if by.get_held_item() != accepted_item:
		say(idle_message)
		return
	by.set_held_item("")
	WorldState.set_flag(result_flag)
	say(success_message)
