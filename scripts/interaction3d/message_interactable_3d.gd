class_name MessageInteractable3D
extends Interactable3D
## Ao interagir, mostra uma mensagem curta no HUD.

@export_multiline var message: String = ""


func _on_interact(_by: FirstPersonMotor) -> void:
	get_tree().call_group("hud", "show_message", message)
