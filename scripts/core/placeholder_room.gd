@tool
class_name PlaceholderRoom
extends Node2D
## Monta por código uma sala de blocos (parede, realces e piso), lateral ou vista de cima.
## Cada bloco usa a textura correspondente, repetida, quando houver; senão, a cor.
## Os blocos são recriados a cada carregamento e não ficam salvos na cena.
## Ficam atrás dos outros filhos (móveis, objetos), que são desenhados por cima.

@export var top_down: bool = false
@export var room_size: Vector2i = Vector2i(640, 360)
## Lateral: altura do piso. De cima: não usado.
@export var floor_height: int = 48
## De cima: altura da faixa de parede no alto da tela. Lateral: não usado.
@export var wall_height: int = 64
@export var wall_color: Color = Color("#3B1A1F")
@export var detail_color: Color = Color("#C9973B")
@export var floor_color: Color = Color("#1F3A2E")
@export var wall_texture: Texture2D
## Escurece a parede para os objetos e as personagens se destacarem dela.
@export var wall_tint: Color = Color.WHITE
@export var detail_texture: Texture2D
@export var floor_texture: Texture2D
## Blocos sólidos extras (pisos intermediários, prateleiras), com a cor do piso e colisão.
@export var solid_blocks: Array[Rect2] = []
## Índices dos blocos que são plataformas: atravessáveis por baixo, sólidos por cima.
@export var one_way_block_indices: PackedInt32Array = PackedInt32Array()
## Faixas de realce extras (rodapés de outros andares), sem colisão.
@export var detail_blocks: Array[Rect2] = []

var _generated_count: int = 0


func _ready() -> void:
	_build()


func _build() -> void:
	for child in get_children():
		if child.has_meta("generated"):
			# Sai da árvore já, para os novos blocos não colidirem com os nomes antigos
			remove_child(child)
			child.queue_free()
	_generated_count = 0

	if top_down:
		_build_top_down()
	else:
		_build_side()


func _build_side() -> void:
	var floor_top: int = room_size.y - floor_height

	# Parede de fundo
	_add_block("Wall", Rect2(0, 0, room_size.x, floor_top), wall_color, wall_texture)
	get_child(_generated_count - 1).modulate = wall_tint
	# Sanca perto do teto e rodapé logo acima do piso
	_add_block("Cornice", Rect2(0, 32, room_size.x, 4), detail_color, detail_texture)
	_add_block("Baseboard", Rect2(0, floor_top - 8, room_size.x, 8), detail_color, detail_texture)
	for rect in detail_blocks:
		_add_block("Detail", rect, detail_color, detail_texture)

	# Piso com colisão
	var floor_body := StaticBody2D.new()
	floor_body.name = "Floor"
	_add_generated(floor_body)
	var floor_rect := Rect2(0, floor_top, room_size.x, floor_height)
	floor_body.add_child(_make_block("FloorBlock", floor_rect, floor_color, floor_texture))
	_add_collision(floor_body, floor_rect)
	for index in solid_blocks.size():
		var rect := solid_blocks[index]
		floor_body.add_child(_make_block("Solid", rect, floor_color, floor_texture))
		_add_collision(floor_body, rect, index in one_way_block_indices)

	# Paredes invisíveis nas bordas, para ninguém sair da tela
	_add_collision(floor_body, Rect2(-16, 0, 16, room_size.y))
	_add_collision(floor_body, Rect2(room_size.x, 0, 16, room_size.y))


func _build_top_down() -> void:
	# Piso na sala toda e a parede do fundo como uma faixa no alto
	_add_block("Floor", Rect2(0, 0, room_size.x, room_size.y), floor_color, floor_texture)
	_add_block("Wall", Rect2(0, 0, room_size.x, wall_height), wall_color, wall_texture)
	get_child(_generated_count - 1).modulate = wall_tint
	_add_block("Baseboard", Rect2(0, wall_height - 8, room_size.x, 8), detail_color, detail_texture)

	# Limites: parede do fundo e bordas invisíveis da tela
	var bounds := StaticBody2D.new()
	bounds.name = "Bounds"
	_add_generated(bounds)
	_add_collision(bounds, Rect2(0, 0, room_size.x, wall_height))
	_add_collision(bounds, Rect2(-16, 0, 16, room_size.y))
	_add_collision(bounds, Rect2(room_size.x, 0, 16, room_size.y))
	_add_collision(bounds, Rect2(0, room_size.y, room_size.x, 16))


func _add_block(block_name: String, rect: Rect2, color: Color, texture: Texture2D) -> void:
	_add_generated(_make_block(block_name, rect, color, texture))


## Adiciona um nó gerado logo depois dos gerados anteriores, antes dos filhos da cena.
func _add_generated(node: Node) -> void:
	node.set_meta("generated", true)
	add_child(node)
	move_child(node, _generated_count)
	_generated_count += 1


func _add_collision(body: StaticBody2D, rect: Rect2, one_way: bool = false) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = rect.get_center()
	collision.one_way_collision = one_way
	collision.one_way_collision_margin = 1.0
	body.add_child(collision)


## Bloco com a textura repetida (lado a lado) ou, sem textura, na cor lisa.
func _make_block(block_name: String, rect: Rect2, color: Color, texture: Texture2D) -> Control:
	var block: Control
	if texture:
		var textured := TextureRect.new()
		textured.texture = texture
		textured.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		textured.stretch_mode = TextureRect.STRETCH_TILE
		block = textured
	else:
		var plain := ColorRect.new()
		plain.color = color
		block = plain
	block.name = block_name
	block.position = rect.position
	block.size = rect.size
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return block
