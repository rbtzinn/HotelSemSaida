class_name Interactable
extends Area2D
## Base para objetos com interação (ação "interact").
## Mostra um prompt curto quando uma personagem que pode usá-lo está dentro da área.
## Subclasses sobrescrevem _on_interact().

enum Availability { PAST_ONLY, PRESENT_ONLY, BOTH }

signal interacted(by: PlayerMotor)

const GROUP: StringName = &"interactables"

@export var prompt_text: String = "Interagir"
@export var available_in: Availability = Availability.BOTH
## Posição do prompt, relativa a esta área.
@export var prompt_position: Vector2 = Vector2(0, -14)
## Só aceita interação com esta flag do WorldState ligada (vazio = sempre).
@export var required_flag: String = ""
## Deixa de aceitar interação quando esta flag liga (vazio = nunca).
@export var done_flag: String = ""

## Desligado, o objeto não mostra prompt nem aceita interação.
var enabled: bool = true:
	set(value):
		enabled = value
		_update_prompt()

var _bodies: Array[PlayerMotor] = []
var _prompt: Label


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = 0
	collision_mask = 2 # personagens
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	WorldState.flag_changed.connect(func(_key: String, _value: Variant) -> void: _update_prompt())

	_prompt = Label.new()
	_prompt.text = "[E] " + prompt_text
	_prompt.position = prompt_position
	_prompt.add_theme_font_size_override("font_size", 8)
	_prompt.add_theme_color_override("font_color", Color("#E8E2D0"))
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 2)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt)
	_update_prompt()


func has_body(body: PlayerMotor) -> bool:
	return body in _bodies


func can_interact(by: PlayerMotor) -> bool:
	if not enabled:
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


func interact(by: PlayerMotor) -> void:
	if not can_interact(by):
		return
	_on_interact(by)
	interacted.emit(by)


## Sobrescreva nas subclasses.
func _on_interact(_by: PlayerMotor) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerMotor:
		_bodies.append(body)
		_update_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body is PlayerMotor:
		_bodies.erase(body)
		_update_prompt()


func _update_prompt() -> void:
	if _prompt == null:
		return
	_prompt.visible = _bodies.any(func(b: PlayerMotor) -> bool: return can_interact(b))
