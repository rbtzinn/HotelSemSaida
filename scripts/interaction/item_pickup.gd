class_name ItemPickup
extends Interactable
## Objeto que a personagem pega com E e passa a segurar na mão (um por vez).
## Com as mãos ocupadas, o prompt não aparece.
## Liga `taken_flag` para o objeto não voltar a aparecer, nem depois de carregar o jogo.
## Com `infinite`, a fonte nunca acaba (ex.: gelo da geladeira) e não usa flag.

@export var item_id: String = ""
@export var taken_flag: String = ""
@export var infinite: bool = false


func _ready() -> void:
	if done_flag == "" and not infinite:
		done_flag = taken_flag
	super()


func can_interact(by: PlayerMotor) -> bool:
	return super(by) and by.get_held_item() == ""


func _on_interact(by: PlayerMotor) -> void:
	by.set_held_item(item_id)
	if not infinite:
		WorldState.set_flag(taken_flag)
	get_tree().call_group("hud", "show_message", "Pegou: %s." % Items.display_name(item_id))
