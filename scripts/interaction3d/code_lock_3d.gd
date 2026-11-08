class_name CodeLock3D
extends Interactable3D
## Cadeado de código: com E, abre o minigame. Acertando, liga `flag_key`
## e deixa de aceitar interação.

@export var code: String = "0000"
@export var flag_key: String = ""
@export var solved_message: String = "O cadeado abriu."


## Som ao usar (ver Interactable3D.sound).
func _default_sound() -> String:
	return ""


func _ready() -> void:
	if done_flag == "":
		done_flag = flag_key
	super()


func _on_interact(_by: FirstPersonMotor) -> void:
	var ui := CodeLockUI.open(get_tree(), code)
	ui.solved.connect(func() -> void:
		WorldState.set_flag(flag_key)
		say(solved_message))
