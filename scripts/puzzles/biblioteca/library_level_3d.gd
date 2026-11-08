class_name LibraryLevel3D
extends ChapterRoom3D
## Biblioteca em quatro enigmas: volumes trocados, cifra, livro preservado e arquivo secreto.
## As ações da Lia só registram leitura; os mecanismos pertencem à Helena.
##
## A cifra não tem atalho: qualquer um dos quatro livros da mesa pode ser levado e guardado
## no registro oco. Só o atlas recebe, em 1951, as anotações de Caio; um livro errado
## aparece hoje intacto e mudo, e Helena pode tirá-lo e tentar de novo.

const TITLES := ["ATLAS", "BOTÂNICA", "CRÔNICAS", "DIÁRIOS"]
const BOOK_ITEMS := ["atlas", "livro_botanica", "livro_cronicas", "livro_diarios"]
const HEIGHTS := [0.46, 0.58, 0.36, 0.28]
const ROLES := ["mahogany", "green_velvet", "oak", "velvet"]
## Ordem certa dos volumes na estante (ids 1..4, da esquerda para a direita).
const ORDER := [2, 4, 1, 3]
const EXIT_CODE := "7264"
const ATLAS := 0

const ORDERED := "biblioteca.estante.ordenada"
const CIPHER := "biblioteca.cifra.resolvida"
const ATLAS_TAKEN := "biblioteca.livro.pego"
const ATLAS_STORED := "biblioteca.livro.guardado"
## Qual livro está dentro do registro oco: 0 = vazio, 1..4 = índice em TITLES + 1.
const REGISTER := "biblioteca.registro"
const ARCHIVE := "biblioteca.arquivo.aberto"

const DOOR := preload("res://scripts/interaction3d/door_3d.gd")
const ACTION := preload("res://scripts/interaction3d/interactable_3d.gd")
const NOTE := preload("res://scripts/interaction3d/note_interactable_3d.gd")
const LOCK := preload("res://scripts/interaction3d/code_lock_3d.gd")

var _selected: int = -1
var _books: Array[Node3D] = []
var _secret_shelves: Array[Node3D] = []
## Livros da mesa: [época][índice] -> nó com capa e título.
var _table_books: Array = [[], []]
var _register_views: Array[MeshInstance3D] = []
var _drawer: Node3D


func _ready() -> void:
	StoryTrigger.attach(self, "biblioteca.concluida", StoryCutscenes.library_end)
	for present: bool in [false, true]:
		var world := make_world(preload("res://scripts/puzzles/biblioteca/library_room_3d.gd"), present)
		_build_doors(world, present)
		_build_shelf_volumes(world, present)
		_build_clues(world, present)
		_build_table(world, present)
		_build_register(world, present)
		_build_secret_shelf(world, present)
		_build_archive(world, present)
	marker("DoSaguao", Vector3(9, 0, 11.5))
	marker("DaManutencao", Vector3(15.5, 0, 11.4))
	marker("DasCaldeiras", Vector3(6.95, 0, -1.55), -PI / 2)
	_apply_state()
	WorldState.flag_changed.connect(_on_flag_changed)
	super()


# --- Montagem -------------------------------------------------------------------------

func _build_doors(world: Node3D, present: bool) -> void:
	area(DOOR, world, "ParaCaldeiras", Vector3(6.95, 1.2, -2.82), Vector3(1.32, 2.4, 0.24), {
		"target_scene": "res://scenes/rooms/caldeiras_3d.tscn",
		"target_spawn": "DoArquivo",
		"prompt_text": "Descer às caldeiras",
		"required_flag": ARCHIVE,
	})
	area(DOOR, world, "ParaSaguao", Vector3(9, 1.2, 12.65), Vector3(1.6, 2.4, 0.3), {
		"target_scene": "res://scenes/rooms/saguao_3d.tscn",
		"target_spawn": "DaBiblioteca",
		"prompt_text": "Voltar ao Saguão",
	})
	# Retorno pelo corredor de serviço: mantém o trajeto da Lia reversível.
	box(world, Vector3(16, 1.2, 12.91), Vector3(1.2, 2.4, 0.08), "dark_wood", present)
	var service_label := label(world, "SERVIÇO", Vector3(16, 2.25, 12.8))
	service_label.rotation.y = PI
	area(DOOR, world, "ParaManutencao", Vector3(16, 1.2, 12.68), Vector3(1.2, 2.4, 0.35), {
		"target_scene": "res://scenes/rooms/manutencao_3d.tscn",
		"target_spawn": "DaBiblioteca",
		"prompt_text": "Corredor de serviço",
		"available_in": Interactable3D.Availability.PRESENT_ONLY,
	})


## Quatro volumes na prateleira do passado; hoje só os contornos que o sol deixou.
func _build_shelf_volumes(world: Node3D, present: bool) -> void:
	for i in 4:
		var at := Vector3(3.45 + i * 0.55, 1.39, 0.86)
		if present:
			var id: int = ORDER[i] - 1
			box(world, at + Vector3(0, HEIGHTS[id] / 2, -0.34), Vector3(0.24, HEIGHTS[id], 0.015), ROLES[id], true)
			label(world, "%s" % (i + 1), at + Vector3(0, -0.15, 0.15), 20)
			continue
		var holder := Node3D.new()
		holder.position = at
		world.add_child(holder)
		_books.append(holder)
		var action := area(ACTION, world, "Volume%d" % i, at + Vector3(0, 0.3, 0.13), Vector3(0.43, 0.65, 0.48), {
			"prompt_text": "Selecionar / trocar volume",
			"available_in": Interactable3D.Availability.PAST_ONLY,
			"done_flag": ORDERED,
		})
		action.interacted.connect(_swap_book.bind(i))


func _build_clues(world: Node3D, present: bool) -> void:
	if present:
		area(NOTE, world, "MarcasDeSol", Vector3(4.3, 1.75, 1.12), Vector3(2.6, 0.8, 0.1), {
			"title": "Marcas na prateleira",
			"text": "Os livros desapareceram, mas quatro silhuetas escaparam do sol, cada uma de uma altura.",
			"prompt_text": "Examinar marcas",
			"available_in": Interactable3D.Availability.PRESENT_ONLY,
		})
		# O carimbo mostra um único par gasto; o resto do alfabeto o jogador deduz.
		box(world, Vector3(13, 1.03, 6.7), Vector3(0.22, 0.08, 0.15), "iron", true)
		area(NOTE, world, "Carimbo", Vector3(13, 1.09, 6.9), Vector3(0.5, 0.28, 0.5), {
			"title": "Carimbo de devolução",
			"text": "DEVOLVIDO AO ACERVO\n\nNa base, quase apagado pelo uso: A → D",
			"prompt_text": "Examinar carimbo",
			"available_in": Interactable3D.Availability.PRESENT_ONLY,
		})
		return
	area(NOTE, world, "BilheteCifrado", Vector3(4.3, 1.16, 1.06), Vector3(0.7, 0.24, 0.4), {
		"title": "Gaveta do bibliotecário",
		"text": "DEUD R DWODV\n\nDevolver o livro ao abrigo da luz.\nNão deixar o registro na mesa.",
		"prompt_text": "Ler bilhete",
		"required_flag": ORDERED,
		"available_in": Interactable3D.Availability.PAST_ONLY,
	})
	_drawer = Node3D.new()
	_drawer.position = Vector3(4.3, 1.15, 0.72)
	world.add_child(_drawer)
	box(_drawer, Vector3.ZERO, Vector3(0.8, 0.15, 0.4), "mahogany", false)
	box(_drawer, Vector3(0, 0.085, 0), Vector3(0.3, 0.01, 0.2), "paper", false)


## Quatro livros na mesa de leitura. Em 1923, qualquer um pode ser levado.
func _build_table(world: Node3D, present: bool) -> void:
	for i in 4:
		var at := Vector3(4.05 + i * 0.6, 1.025, 6.8)
		var holder := Node3D.new()
		holder.name = "LivroMesa%d" % i
		holder.position = at
		world.add_child(holder)
		box(holder, Vector3.ZERO, Vector3(0.44, 0.07, 0.6), ROLES[i], present)
		label(holder, TITLES[i], Vector3(0, 0.055, 0.31), 20)
		_table_books[int(present)].append(holder)
		if not present:
			var action := area(ACTION, world, "Titulo%d" % i, at + Vector3(0, 0.12, 0.28), Vector3(0.5, 0.25, 0.7), {
				"prompt_text": "Examinar " + TITLES[i],
				"available_in": Interactable3D.Availability.PAST_ONLY,
			})
			action.interacted.connect(_use_table_book.bind(i))


## Registro de encadernações escavado por dentro, sob o peitoril seco: um livro dentro de outro.
func _build_register(world: Node3D, present: bool) -> void:
	box(world, Vector3(2.23, 1.325, 10.91), Vector3(0.65, 0.025, 0.82), "dark_wood", present)
	for z: float in [10.52, 11.3]:
		box(world, Vector3(2.23, 1.38, z), Vector3(0.65, 0.09, 0.035), "paper", present)
	box(world, Vector3(1.92, 1.38, 10.91), Vector3(0.03, 0.09, 0.82), "mahogany", present)
	var inside := box(world, Vector3(2.23, 1.38, 10.91), Vector3(0.5, 0.09, 0.65), "mahogany", present)
	_register_views.append(inside)
	var spot := Vector3(2.65, 1.4, 10.9)
	var size := Vector3(0.5, 0.4, 0.75)
	if present:
		var page := area(ACTION, world, "RegistroPreservado", spot, size, {
			"prompt_text": "Examinar registro",
			"required_flag": REGISTER,
			"available_in": Interactable3D.Availability.PRESENT_ONLY,
		})
		page.interacted.connect(_read_register)
	else:
		var action := area(ACTION, world, "GuardarAtlas", spot, size, {
			"prompt_text": "Examinar registro",
			"available_in": Interactable3D.Availability.PAST_ONLY,
		})
		action.interacted.connect(_use_register)


## Estante móvel: desenho e corpo pertencem ao mesmo nó e se movem juntos.
func _build_secret_shelf(world: Node3D, present: bool) -> void:
	var secret := Node3D.new()
	secret.name = "EstanteSecreta"
	secret.position = Vector3(9, 0, 0.4)
	world.add_child(secret)
	_secret_shelves.append(secret)
	box(secret, Vector3(0, 1.6, 0), Vector3(2, 3.2, 0.7), "mahogany", present)
	for row in 5:
		box(secret, Vector3(0, 0.3 + row * 0.6, 0.39), Vector3(1.8, 0.07, 0.12), "brass", present)
		for i in 9:
			box(secret, Vector3(-0.75 + i * 0.18, 0.54 + row * 0.6, 0.39), Vector3(0.12, 0.4, 0.18), ROLES[(i + row) % 4], present)
	var body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 3.2, 0.7)
	var collision := CollisionShape3D.new()
	collision.position.y = 1.6
	collision.shape = shape
	body.add_child(collision)
	secret.add_child(body)
	if not present:
		area(LOCK, secret, "FechaduraArquivo", Vector3(0, 1.15, 0.52), Vector3(0.4, 0.4, 0.25), {
			"code": EXIT_CODE,
			"flag_key": ARCHIVE,
			"prompt_text": "Fechadura da estante",
			"required_flag": ATLAS_STORED,
			"available_in": Interactable3D.Availability.PAST_ONLY,
		})
		box(secret, Vector3(0, 1.15, 0.46), Vector3(0.3, 0.22, 0.05), "brass", false)


## No arquivo, o dossiê de desaparecimento encerra o capítulo.
func _build_archive(world: Node3D, present: bool) -> void:
	box(world, Vector3(9, 1.025, -1.55), Vector3(0.5, 0.05, 0.4), "paper", present)
	var at := Vector3(9, 1.1, -1.25)
	var size := Vector3(0.65, 0.3, 0.65)
	if present:
		var final_note := area(NOTE, world, "DossieCaio", at, size, {
			"title": "Arquivo de hóspedes — Dr. Caio Ferraz",
			"text": "1951. Quarto ocupado, pertences intactos.\n\nO médico não foi visto deixando o hotel. Nenhum funcionário registrou sua saída.\n\nGrampos prendem uma ampliação ao dossiê. No verso, a letra de Marta Siqueira: «Oficina das caldeiras, 1979. Três cortes na quina. F-2». A câmera nunca foi devolvida.\n\nEntre as folhas há uma ficha recente, ainda sem nome.",
			"prompt_text": "Ler dossiê",
			"required_flag": ARCHIVE,
			"available_in": Interactable3D.Availability.PRESENT_ONLY,
		})
		final_note.photograph = preload("res://art/biblioteca/marta_f2_1979.jpg")
		final_note.interacted.connect(func(_by: FirstPersonMotor) -> void: WorldState.set_flag("biblioteca.concluida"))
	else:
		area(NOTE, world, "LivroDoArquivo", at, size, {
			"title": "Registro reservado — 1923",
			"text": "Relação de quartos e documentos recolhidos.\n\nVários nomes foram raspados. Sob a última coluna, alguém começou a escrever uma palavra e parou: saída.",
			"prompt_text": "Ler registro",
			"available_in": Interactable3D.Availability.PAST_ONLY,
		})


# --- Enigmas ----------------------------------------------------------------------------

func _swap_book(by: FirstPersonMotor, slot: int) -> void:
	if _selected < 0:
		_selected = slot
		by.velocity = Vector3.ZERO
		_say("Volume selecionado. Examine outro para trocar os dois.")
		_draw_books()
		return
	var first := _volume(_selected)
	var second := _volume(slot)
	WorldState.set_flag("biblioteca.volume.%d" % _selected, second)
	WorldState.set_flag("biblioteca.volume.%d" % slot, first)
	_selected = -1
	var correct := true
	for i in 4:
		correct = correct and _volume(i) == ORDER[i]
	if correct:
		WorldState.set_flag(ORDERED)
		_say("Um trinco cede na gaveta abaixo da estante.")
	_draw_books()


## Pegar, devolver ou só examinar um livro da mesa. Antes da gaveta abrir, nada sai dali.
func _use_table_book(by: FirstPersonMotor, index: int) -> void:
	var item: String = BOOK_ITEMS[index]
	var hand := by.get_held_item()
	if hand == item:
		by.set_held_item("")
		if index == ATLAS:
			WorldState.set_flag(ATLAS_TAKEN, false)
		_say("Helena devolve o volume à mesa.")
		return
	if not WorldState.is_set(ORDERED):
		var description := "Cartas antigas, mapas e folhas em branco entre os cadernos." if index == ATLAS \
			else "Índice de assuntos e páginas numeradas. A capa tem marcas de uso."
		NoteUI.open(get_tree(), TITLES[index].capitalize(), description)
		return
	if not _on_table(index):
		_say("O lugar do volume está vazio.")
	elif hand != "":
		_say("A mão está ocupada.")
	else:
		by.set_held_item(item)
		if index == ATLAS:
			WorldState.set_flag(ATLAS_TAKEN)
		_say("Helena pega o volume de %s." % TITLES[index].capitalize())


## Guardar um livro no registro oco, ou tirá-lo de lá para trocar.
func _use_register(by: FirstPersonMotor) -> void:
	var stored := _stored()
	var hand := by.get_held_item()
	var book := BOOK_ITEMS.find(hand)
	if stored == 0 and book >= 0:
		by.set_held_item("")
		WorldState.set_flag(REGISTER, book + 1)
		if book == ATLAS:
			WorldState.set_flag(CIPHER)
			WorldState.set_flag(ATLAS_STORED)
		_say("O volume coube dentro do registro oco, protegido da luz e da umidade.")
	elif stored > 0 and hand == "":
		if WorldState.is_set(ARCHIVE):
			_say("O registro fica onde está, sob o peitoril.")
			return
		by.set_held_item(BOOK_ITEMS[stored - 1])
		WorldState.set_flag(REGISTER, 0)
		WorldState.set_flag(ATLAS_STORED, false)
		_say("Helena tira o volume de dentro do registro.")
	elif stored > 0:
		_say("Já há um volume dentro do registro.")
	elif hand != "":
		_say("Isso não cabe no registro.")
	else:
		_say("Um registro de encadernações oco por dentro, guardado sob o peitoril seco.")


## Hoje: o livro que Helena deixou no registro, cem anos depois.
func _read_register(_by: FirstPersonMotor) -> void:
	var stored := _stored()
	if stored == ATLAS + 1:
		WorldState.set_flag("biblioteca.pagina.lida")
		NoteUI.open(get_tree(), "Anotações de Caio Ferraz — 1951", "Encontrei este atlas protegido sob o peitoril. Quem o guardou antes de mim?\n\nAlgarismos nas fichas:\nAtlas — 6\nBotânica — 7\nCrônicas — 4\nDiários — 2\n\nA combinação não segue o catálogo. Segue os volumes como estavam antes do sol levar suas cores.\n\nSe eu não voltar, procurem no arquivo reservado.")
	elif stored > 0:
		var title: String = TITLES[stored - 1].capitalize()
		NoteUI.open(get_tree(), "Dentro do registro oco", "Um volume de %s, seco e intacto depois de cem anos.\n\nNinguém escreveu nada nele." % title)


# --- Estado -----------------------------------------------------------------------------

func _volume(slot: int) -> int:
	return int(WorldState.get_flag("biblioteca.volume.%d" % slot, slot + 1))


func _stored() -> int:
	return clampi(int(WorldState.get_flag(REGISTER, 0)), 0, 4)


## O livro está na mesa se não está no registro nem na mão da Helena.
func _on_table(index: int) -> bool:
	return _stored() != index + 1 and str(WorldState.get_flag("helena.mao", "")) != BOOK_ITEMS[index]


func _on_flag_changed(_key: String, _value: Variant) -> void:
	_apply_state()


func _apply_state() -> void:
	if _books.size() == 4:
		_draw_books()
	if is_instance_valid(_drawer):
		_drawer.position.z = 1.1 if WorldState.is_set(ORDERED) else 0.72
	var stored := _stored()
	# _register_views[0] é o de 1923, [1] o de hoje (ordem de montagem)
	for era in _register_views.size():
		var view := _register_views[era]
		view.visible = stored > 0
		if stored > 0:
			view.material_override = HotelMaterials.get_material(ROLES[stored - 1], era == 1)
	for era_books: Array in _table_books:
		for i in era_books.size():
			(era_books[i] as Node3D).visible = _on_table(i)
	for shelf in _secret_shelves:
		shelf.position.x = 11.3 if WorldState.is_set(ARCHIVE) else 9.0


func _draw_books() -> void:
	for i in _books.size():
		var holder := _books[i]
		for child in holder.get_children():
			holder.remove_child(child)
			child.queue_free()
		var id := clampi(_volume(i) - 1, 0, 3)
		box(holder, Vector3(0, HEIGHTS[id] / 2, 0), Vector3(0.23, HEIGHTS[id], 0.34), ROLES[id], false)
		label(holder, TITLES[id], Vector3(0, HEIGHTS[id] / 2, 0.18), 16)
		box(holder, Vector3(0, 0.07, 0.175), Vector3(0.2, 0.012, 0.01), "brass", false)
		holder.position.y = 1.43 if i == _selected else 1.39


func _say(message: String) -> void:
	get_tree().call_group("hud", "show_message", message)
