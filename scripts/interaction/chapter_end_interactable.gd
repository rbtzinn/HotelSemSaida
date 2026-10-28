class_name ChapterEndInteractable
extends Interactable
## Saída de um andar: liga a flag de conclusão e mostra a tela de fim (provisória).

@export var flag_key: String = ""
@export var title: String = ""
@export_multiline var text: String = ""


func _on_interact(_by: PlayerMotor) -> void:
	WorldState.set_flag(flag_key)
	NoteUI.open(get_tree(), title, text)
