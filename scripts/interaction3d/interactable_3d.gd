class_name Interactable3D
extends Area3D
## Base para objetos com interação em primeira pessoa: a personagem mira e aperta E.
## Mesmas regras do Interactable 2D (época, required_flag, done_flag); subclasses
## sobrescrevem _on_interact(). O prompt aparece no centro do HUD, junto da mira.
## Com `proximity`, vale por estar dentro da área (ex.: um piso inteiro), sem mirar.

enum Availability { PAST_ONLY, PRESENT_ONLY, BOTH }

signal interacted(by: FirstPersonMotor)

const PROXIMITY_GROUP: StringName = &"proximity_interactables"

@export var prompt_text: String = "Interagir"
@export var available_in: Availability = Availability.BOTH
## Só aceita interação com esta flag do WorldState ligada (vazio = sempre).
@export var required_flag: String = ""
## Deixa de aceitar interação quando esta flag liga (vazio = nunca).
@export var done_flag: String = ""
## Vale por estar dentro da área, quando nada está na mira.
@export var proximity: bool = false
## Só aceita com os pés acima desta altura (ex.: a portinhola, que só se alcança de cima
## da prateleira). O padrão aceita de qualquer altura.
@export var min_feet_height: float = -1000.0

var _bodies: Array[FirstPersonMotor] = []


func _ready() -> void:
	collision_layer = FirstPersonMotor.INTERACT_LAYER if not proximity else 0
	collision_mask = FirstPersonMotor.CHARACTER_LAYER if proximity else 0
	monitoring = proximity
	if proximity:
		add_to_group(PROXIMITY_GROUP)
		body_entered.connect(func(body: Node3D) -> void:
			if body is FirstPersonMotor and body not in _bodies:
				_bodies.append(body))
		body_exited.connect(func(body: Node3D) -> void: _bodies.erase(body))


func contains(body: FirstPersonMotor) -> bool:
	return body in _bodies and is_visible_in_tree() and can_process()


func get_prompt() -> String:
	return "[" + Settings.binding_label("interact") + "] " + prompt_text


func can_interact(by: FirstPersonMotor) -> bool:
	if by.is_traversing() or by.global_position.y < min_feet_height:
		return false
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


func say(text: String) -> void:
	get_tree().call_group("hud", "show_message", text)
