class_name CodeLockInteractable
extends Interactable
## Cadeado de código: com E, abre o minigame. Acertando, liga `flag_key`
## e deixa de aceitar interação.

@export var code: String = "0000"
@export var flag_key: String = ""
@export var solved_message: String = "O cadeado abriu."


func _ready() -> void:
	if done_flag == "":
		done_flag = flag_key
	super()


func _on_interact(_by: PlayerMotor) -> void:
	var ui := CodeLockUI.open(get_tree(), code)
	ui.solved.connect(_on_solved)


func _on_solved() -> void:
	WorldState.set_flag(flag_key)
	get_tree().call_group("hud", "show_message", solved_message)
