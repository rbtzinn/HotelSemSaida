class_name IceDropZone
extends Interactable
## Piso da despensa em 1923: Helena deixa o bloco de gelo onde estiver parada.
## Só o ponto certo (onde hoje passa a corrente de ar) apodrece o piso em 100 anos.
## Deixar outro bloco substitui o anterior.

const ITEM: String = "gelo"
const X_FLAG: String = "cozinha.gelo.x"
const PLACED_FLAG: String = "cozinha.gelo.posto"
const ROT_FLAG: String = "cozinha.piso.apodrecido"

## Distância, à frente dos pés, onde o bloco fica no último quadro da animação de uso.
const REACH: float = 15.0

@export var target_x: float = 376.0
## Distância máxima, em pixels, entre o gelo e o ponto certo.
@export var tolerance: float = 12.0

@onready var _block: Control = $Bloco


func _ready() -> void:
	super()
	_refresh_block()


func _process(_delta: float) -> void:
	# A área cobre o piso todo, então o prompt acompanha a personagem
	if not _bodies.is_empty():
		_prompt.global_position = _bodies[0].global_position + Vector2(-28, -62)


func can_interact(by: PlayerMotor) -> bool:
	return super(by) and by.get_held_item() == ITEM


func _on_interact(by: PlayerMotor) -> void:
	# O bloco fica onde as mãos o deixam, à frente dela, e não sob os pés
	var x := roundi(by.global_position.x + REACH * by.get_facing())
	if by.play_item_use(ITEM, _finish_drop.bind(by,x)):
		return
	_finish_drop(by,x)


func _finish_drop(by: PlayerMotor, x: int) -> void:
	if by.get_held_item() != ITEM:
		return
	by.set_held_item("")
	WorldState.set_flag(X_FLAG, x)
	WorldState.set_flag(PLACED_FLAG, true)
	WorldState.set_flag(ROT_FLAG, absf(x - target_x) <= tolerance)
	_refresh_block()
	get_tree().call_group("hud", "show_message", "O bloco de gelo ficou no chão, derretendo.")


func _refresh_block() -> void:
	_block.visible = WorldState.is_set(PLACED_FLAG)
	_block.position.x = float(WorldState.get_flag(X_FLAG, 0)) - _block.size.x / 2.0
