class_name IceDrop3D
extends Interactable3D
## Piso da despensa em 1923 (zona de proximidade): com o gelo na mão, Helena o deixa no chão
## à frente dos pés. Só o ponto certo (onde hoje passa a corrente de ar) apodrece o piso em
## 100 anos. Deixar outro bloco substitui o anterior. Filho: Bloco (o gelo no chão).

const ITEM: String = "gelo"
const X_FLAG: String = "cozinha.gelo.x"
const Z_FLAG: String = "cozinha.gelo.z"
const PLACED_FLAG: String = "cozinha.gelo.posto"
const ROT_FLAG: String = "cozinha.piso.apodrecido"

## Distância, à frente dos pés, onde as mãos deixam o bloco (metros).
const REACH: float = 0.6

## Ponto da fresta no piso (x, z), em metros.
@export var target: Vector2 = Vector2(11.75, 3.2)
## Distância máxima, em metros, entre o gelo e a fresta.
@export var tolerance: float = 0.4

@onready var _block: Node3D = $Bloco


func _ready() -> void:
	proximity = true
	super()
	_refresh_block()


func can_interact(by: FirstPersonMotor) -> bool:
	return super(by) and by.get_held_item() == ITEM


func _on_interact(by: FirstPersonMotor) -> void:
	var spot := by.global_position + by.get_forward() * REACH
	drop_at(by, Vector2(spot.x, spot.z))


## Deixa o bloco no ponto (x, z) do piso e decide se a madeira vai apodrecer.
func drop_at(by: FirstPersonMotor, spot: Vector2) -> void:
	by.set_held_item("")
	WorldState.set_flag(X_FLAG, snappedf(spot.x, 0.01))
	WorldState.set_flag(Z_FLAG, snappedf(spot.y, 0.01))
	WorldState.set_flag(PLACED_FLAG, true)
	WorldState.set_flag(ROT_FLAG, spot.distance_to(target) <= tolerance)
	_refresh_block()
	say("O bloco de gelo ficou no chão, derretendo.")


static func placed_position() -> Vector2:
	return Vector2(float(WorldState.get_flag(X_FLAG, 0.0)), float(WorldState.get_flag(Z_FLAG, 0.0)))


func _refresh_block() -> void:
	_block.visible = WorldState.is_set(PLACED_FLAG)
	var spot := placed_position()
	_block.global_position = Vector3(spot.x, _block.global_position.y, spot.y)
