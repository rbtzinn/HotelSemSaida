class_name ItemPickup3D
extends Interactable3D
## Objeto que a personagem pega com E e passa a segurar na mão (um por vez).
## Com as mãos ocupadas, o aviso não aparece. Liga `taken_flag` para o objeto não voltar
## a aparecer; com `infinite`, a fonte nunca acaba (ex.: gelo da geladeira).

@export var item_id: String = ""
@export var taken_flag: String = ""
@export var infinite: bool = false


func _ready() -> void:
	if done_flag == "" and not infinite:
		done_flag = taken_flag
	super()


func can_interact(by: FirstPersonMotor) -> bool:
	return super(by) and by.get_held_item() == ""


func _on_interact(by: FirstPersonMotor) -> void:
	by.set_held_item(item_id)
	if not infinite:
		WorldState.set_flag(taken_flag)
	say("Pegou: %s." % Items.display_name(item_id))
