class_name MessageInteractable
extends Interactable
## Ao interagir, mostra uma mensagem curta no HUD.

@export_multiline var message: String = ""


func _on_interact(_by: PlayerMotor) -> void:
	get_tree().call_group("hud", "show_message", message)
