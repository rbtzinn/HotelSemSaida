class_name NoteInteractable3D
extends Interactable3D
## Algo para ler (livro de hóspedes, bilhete). Abre a tela de leitura com E.

@export var title: String = ""
@export_multiline var text: String = ""


func _on_interact(_by: FirstPersonMotor) -> void:
	NoteUI.open(get_tree(), title, text)
