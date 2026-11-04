class_name Interactable3D
extends Area3D
## Base para objetos com interação em primeira pessoa: a personagem mira e aperta E.
## Mesmas regras do Interactable 2D (época, required_flag, done_flag); subclasses
## sobrescrevem _on_interact(). O prompt aparece no centro do HUD, junto da mira.

enum Availability { PAST_ONLY, PRESENT_ONLY, BOTH }

signal interacted(by: FirstPersonMotor)

@export var prompt_text: String = "Interagir"
@export var available_in: Availability = Availability.BOTH
## Só aceita interação com esta flag do WorldState ligada (vazio = sempre).
@export var required_flag: String = ""
## Deixa de aceitar interação quando esta flag liga (vazio = nunca).
@export var done_flag: String = ""


func _ready() -> void:
	collision_layer = FirstPersonMotor.INTERACT_LAYER
	collision_mask = 0
	monitoring = false


func get_prompt() -> String:
	return "[" + Settings.binding_label("interact") + "] " + prompt_text


func can_interact(by: FirstPersonMotor) -> bool:
	if required_flag != "" and not WorldState.is_set(required_flag):
		return false
	if done_flag != "" and WorldState.is_set(done_flag):
		return false
	match available_in:
		Availability.PAST_ONLY:
			return by.era == Era.Id.PAST_1923
		Availability.PRESENT_ONLY:
			return by.era == Era.Id.PRESENT
	return true


func interact(by: FirstPersonMotor) -> void:
	if not can_interact(by):
		return
	_on_interact(by)
	interacted.emit(by)


## Sobrescreva nas subclasses.
func _on_interact(_by: FirstPersonMotor) -> void:
	pass
