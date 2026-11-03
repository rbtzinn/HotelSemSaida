@tool
class_name LobbyRoom
extends PlaceholderRoom
## Saguão visto de cima: monta por código a mesma geometria nas duas épocas
## (recepção, colunas, escada, elevador, piano, entrada e porta da Cozinha).
## Em 1923 o lustre está no teto (só um tapete marca o lugar); hoje ele caiu e é sólido.
## Os móveis têm a origem na base, para a ordenação por y desenhar quem está atrás.

## Liga a versão em ruínas (hoje).
@export var present: bool = false:
	set(value):
		present = value
		if is_inside_tree():
			_build()

const SIDE_WALL: int = 16
## Vão da porta da Cozinha na parede oeste (y).
const KITCHEN_DOOR := Vector2i(208, 256)
## Vão da entrada principal na parede sul (x).
const ENTRANCE := Vector2i(288, 352)

var _object_color: Color:
	get:
		return Color("#6E8596") if present else Color("#6B1E2A")


func _build() -> void:
	super._build()
	_build_walls()
	_build_stairs()
	_build_elevator()
	_build_reception()
	_build_columns()
	_build_chandelier()
	_build_piano()


## Paredes laterais e do sul, com os vãos da porta da Cozinha e da entrada.
func _build_walls() -> void:
	var walls := _new_body("SideWalls", Vector2.ZERO)
	var bottom: int = room_size.y - SIDE_WALL
	# Oeste: acima e abaixo da porta da Cozinha
	_add_solid(walls, Rect2(0, wall_height, SIDE_WALL, KITCHEN_DOOR.x - wall_height), detail_color)
	_add_solid(walls, Rect2(0, KITCHEN_DOOR.y, SIDE_WALL, bottom - KITCHEN_DOOR.y), detail_color)
	# Leste e sul
	_add_solid(walls, Rect2(room_size.x - SIDE_WALL, wall_height, SIDE_WALL, bottom - wall_height), detail_color)
	_add_solid(walls, Rect2(0, bottom, room_size.x, SIDE_WALL), detail_color)

	# Porta da Cozinha: em 1923, folha de serviço; hoje, madeira inchada e escura
	var door := _new_body("KitchenDoor", Vector2.ZERO)
	var door_rect := Rect2(0, KITCHEN_DOOR.x, SIDE_WALL, KITCHEN_DOOR.y - KITCHEN_DOOR.x)
	_add_solid(door, door_rect, _object_color)
	_add_rect(door, door_rect.grow_individual(-4, -4, -4, -4), wall_color.darkened(0.2))

	# Entrada principal: porta giratória em 1923; hoje, tábuas pregadas
	var entrance := _new_body("Entrance", Vector2.ZERO)
	var entrance_rect := Rect2(ENTRANCE.x, bottom, ENTRANCE.y - ENTRANCE.x, SIDE_WALL)
	_add_rect(entrance, entrance_rect, _object_color)
	if present:
		for i in 3:
			_add_rect(entrance, Rect2(ENTRANCE.x - 4, bottom + 2 + i * 5, ENTRANCE.y - ENTRANCE.x + 8, 3), Color("#4A3B2C"))
	else:
		_add_rect(entrance, Rect2(ENTRANCE.x + 30, bottom, 4, SIDE_WALL), detail_color)


## Escada a noroeste. Em 1923 sobe para fora da tela; hoje é um monte de escombros.
func _build_stairs() -> void:
	var stairs := _new_body("Stairs", Vector2(96, 112))
	if present:
		_add_rect(stairs, Rect2(-48, -96, 96, 96), wall_color.darkened(0.3))
		_add_rect(stairs, Rect2(-44, -40, 40, 36), detail_color)
		_add_rect(stairs, Rect2(-8, -28, 52, 24), detail_color.darkened(0.25))
		_add_rect(stairs, Rect2(4, -60, 28, 20), detail_color.lightened(0.1))
	else:
		_add_rect(stairs, Rect2(-48, -96, 96, 96), floor_color.darkened(0.2))
		for i in 6:
			_add_rect(stairs, Rect2(-44, -92 + i * 16, 88, 10), detail_color)
	_add_collision(stairs, Rect2(-48, -48, 96, 48))


## Elevador principal na parede norte (a parede já é sólida). Só visual por enquanto.
func _build_elevator() -> void:
	var elevator := _new_body("Elevator", Vector2(520, wall_height))
	_add_rect(elevator, Rect2(-26, -50, 52, 50), detail_color)
	if present:
		# Portas arrombadas e o poço escuro
		_add_rect(elevator, Rect2(-22, -46, 44, 46), Color("#0B0F14"))
		_add_rect(elevator, Rect2(-22, -46, 8, 46), _object_color.darkened(0.3))
		_add_rect(elevator, Rect2(16, -40, 6, 40), _object_color.darkened(0.3))
	else:
		# Grade pantográfica art déco
		_add_rect(elevator, Rect2(-22, -46, 44, 46), wall_color.darkened(0.4))
		for i in 5:
			_add_rect(elevator, Rect2(-20 + i * 10, -46, 2, 46), detail_color)


## Recepção: balcão com o livro de hóspedes; na parede atrás, quadro de chaves e cofre.
func _build_reception() -> void:
	# Itens de parede: a faixa da parede fica sempre atrás das personagens
	var wall_items := _new_body("ReceptionWall", Vector2(0, wall_height))
	var rack := Rect2(232, 22 - wall_height, 40, 30)
	_add_rect(wall_items, rack, Color("#4A3B2C") if present else Color("#5C3A1E"))
	for row in 2:
		for col in 6:
			var hook := Rect2(rack.position.x + 3 + col * 6, rack.position.y + 4 + row * 14, 3, 3)
			_add_rect(wall_items, hook, detail_color)
			if not present:
				_add_rect(wall_items, Rect2(hook.position.x, hook.position.y + 3, 3, 6), detail_color.lightened(0.3))
	var safe := Rect2(372, 24 - wall_height, 36, 34)
	_add_rect(wall_items, safe, Color("#3A3A3A") if present else Color("#2E2A26"))
	_add_rect(wall_items, Rect2(safe.position.x + 14, safe.position.y + 13, 8, 8), detail_color)

	var counter := _new_body("ReceptionCounter", Vector2(320, 128))
	_add_rect(counter, Rect2(-96, -32, 192, 32), _object_color.darkened(0.2))
	_add_rect(counter, Rect2(-96, -32, 192, 4), detail_color)
	# Livro de hóspedes aberto no centro do balcão
	var book_color := Color("#8C8A70") if present else Color("#E8DCC0")
	_add_rect(counter, Rect2(-12, -26, 24, 12), book_color)
	_add_rect(counter, Rect2(-1, -26, 2, 12), _object_color.darkened(0.4))
	_add_collision(counter, Rect2(-96, -16, 192, 16))


func _build_columns() -> void:
	for base: Vector2 in [Vector2(160, 176), Vector2(480, 176), Vector2(160, 304), Vector2(480, 304)]:
		var column := _new_body("Column", base)
		_add_rect(column, Rect2(-8, -40, 16, 40), detail_color if not present else detail_color.lightened(0.15))
		_add_rect(column, Rect2(-10, -4, 20, 4), detail_color.darkened(0.3))
		_add_collision(column, Rect2(-8, -12, 16, 12))


## Lustre: em 1923, um tapete redondo marca o lugar dele no teto; hoje, ele está no chão.
func _build_chandelier() -> void:
	if present:
		var fallen := _new_body("FallenChandelier", Vector2(320, 256))
		_add_rect(fallen, Rect2(-64, -60, 128, 60), Color("#4A4636"))
		_add_rect(fallen, Rect2(-56, -52, 112, 44), Color("#6B6450"))
		# Coroa de latão, à vista na lateral de baixo
		_add_rect(fallen, Rect2(-16, -14, 32, 10), detail_color.lightened(0.35))
		_add_collision(fallen, Rect2(-64, -36, 128, 36))
	else:
		# Fica num nó com y = 0 para ser desenhado logo depois do piso, embaixo de todos
		var rug := Node2D.new()
		rug.name = "Rug"
		_add_generated(rug)
		_add_rect(rug, Rect2(256, 192, 128, 64), detail_color.darkened(0.35))
		_add_rect(rug, Rect2(264, 198, 112, 52), _object_color.darkened(0.1))


## Piano de cauda a leste. Hoje, coberto por uma lona.
func _build_piano() -> void:
	var piano := _new_body("Piano", Vector2(544, 280))
	if present:
		_add_rect(piano, Rect2(-44, -50, 88, 50), Color("#5A6470"))
		_add_rect(piano, Rect2(-40, -30, 80, 4), Color("#4A525C"))
	else:
		_add_rect(piano, Rect2(-40, -48, 80, 48), Color("#120C0E"))
		_add_rect(piano, Rect2(-40, -10, 80, 6), Color("#E8E2D0"))
	_add_collision(piano, Rect2(-40, -24, 80, 24))


func _new_body(body_name: String, base: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name
	body.position = base
	_add_generated(body)
	return body


func _add_rect(parent: Node, rect: Rect2, color: Color) -> void:
	parent.add_child(_make_block("Block", rect, color, null))


func _add_solid(body: StaticBody2D, rect: Rect2, color: Color) -> void:
	_add_rect(body, rect, color)
	_add_collision(body, rect)
