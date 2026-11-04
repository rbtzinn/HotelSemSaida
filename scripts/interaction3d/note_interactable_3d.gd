class_name NoteInteractable3D
extends Interactable3D
## Algo para ler (livro de hóspedes, bilhete). Abre a tela de leitura com E.
## Com `extra_flag` ligada, `extra_text` entra no fim (ex.: um nome novo no livro).

@export var title: String = ""
@export var photograph: Texture2D
@export_multiline var text: String = ""
@export var extra_flag: String = ""
@export_multiline var extra_text: String = ""


func _on_interact(_by: FirstPersonMotor) -> void:
	var full := text
	if extra_flag != "" and WorldState.is_set(extra_flag):
		full += "\n\n" + extra_text
	NoteUI.open(get_tree(), title, full, photograph)
