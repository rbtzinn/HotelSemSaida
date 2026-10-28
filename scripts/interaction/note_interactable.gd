class_name NoteInteractable
extends Interactable
## Algo para ler (cardápio, bilhete, jornal). Abre a tela de leitura com E.

@export var title: String = ""
@export_multiline var text: String = ""


func _on_interact(_by: PlayerMotor) -> void:
	NoteUI.open(get_tree(), title, text)
