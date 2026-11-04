class_name LibraryLevel3D
extends ChapterRoom3D
## Quatro enigmas: volumes trocados, cifra, livro preservado e arquivo secreto.
## As ações de Lia só registram leitura/progresso; os mecanismos pertencem a Helena.
const TITLES := ["ATLAS", "BOTÂNICA", "CRÔNICAS", "DIÁRIOS"]
const HEIGHTS := [0.46,0.58,0.36,0.28]
const ROLES := ["mahogany","green_velvet","oak","velvet"]
const ORDER := [2,4,1,3]
const EXIT_CODE := "7264"
var _selected: int = -1
var _books: Array[Node3D] = []
var _secret_shelves: Array[Node3D] = []
var _hidden_book: Node3D
var _drawer: Node3D

func _ready() -> void:
	for present: bool in [false,true]:
		var world := make_world(preload("res://scripts/puzzles/biblioteca/library_room_3d.gd"),present)
		_build_interactions(world,present)
	marker("DoSaguao",Vector3(9,0,11.5))
	marker("DaManutencao",Vector3(15.5,0,11.4))
	_apply_state()
	WorldState.flag_changed.connect(_on_flag_changed)
	super()

func _build_interactions(world: Node3D, present: bool) -> void:
	area(preload("res://scripts/interaction3d/door_3d.gd"),world,"ParaSaguao",Vector3(9,1.2,12.65),Vector3(1.6,2.4,0.3),{"target_scene":"res://scenes/rooms/saguao_3d.tscn","target_spawn":"DaBiblioteca","prompt_text":"Voltar ao Saguão"})
	# Retorno pelo corredor de serviço: mantém o trajeto da Lia reversível.
	box(world,Vector3(16,1.2,12.91),Vector3(1.2,2.4,0.08),"dark_wood",present)
	var service_label := label(world,"SERVIÇO",Vector3(16,2.25,12.8))
	service_label.rotation.y = PI
	area(preload("res://scripts/interaction3d/door_3d.gd"),world,"ParaManutencao",Vector3(16,1.2,12.68),Vector3(1.2,2.4,0.35),{"target_scene":"res://scenes/rooms/manutencao_3d.tscn","target_spawn":"DaDespensa","prompt_text":"Corredor de serviço","available_in":1})
	# Quatro volumes na prateleira do passado; os contornos correspondentes ficaram hoje.
	for i in 4:
		var at := Vector3(3.45+i*0.55,1.39,0.86)
		if present:
			var id: int = ORDER[i]-1
			box(world,at+Vector3(0,HEIGHTS[id]/2,-0.34),Vector3(0.24,HEIGHTS[id],0.015),ROLES[id],true)
			label(world,"%s" % (i+1),at+Vector3(0,-0.15,0.15),20)
		else:
			var holder := Node3D.new()
			holder.position = at
			world.add_child(holder)
			_books.append(holder)
			var action := area(preload("res://scripts/interaction3d/interactable_3d.gd"),world,"Volume%d" % i,at+Vector3(0,0.3,0.13),Vector3(0.43,0.65,0.48),{"prompt_text":"Selecionar / trocar volume","available_in":0,"done_flag":"biblioteca.estante.ordenada"})
			action.interacted.connect(_swap_book.bind(i))
	if present:
		area(preload("res://scripts/interaction3d/note_interactable_3d.gd"),world,"MarcasDeSol",Vector3(4.3,1.75,1.12),Vector3(2.6,0.8,0.1),{"title":"Marcas na prateleira","text":"Os livros desapareceram, mas quatro silhuetas escaparam do sol.\n\nDa esquerda para a direita: um volume alto; um pequeno; um médio-alto; um médio-baixo. As alturas das marcas ainda podem ser comparadas às capas antigas.","prompt_text":"Examinar marcas","available_in":1})
		# A chave da cifra está no carimbo preservado, e não num texto de tutorial.
		box(world,Vector3(13,1.03,6.7),Vector3(0.22,0.08,0.15),"iron",true)
		area(preload("res://scripts/interaction3d/note_interactable_3d.gd"),world,"Carimbo",Vector3(13,1.09,6.9),Vector3(0.5,0.28,0.5),{"title":"Carimbo de devolução","text":"DEVOLVIDO AO ACERVO\n\nNa base do carimbo: A → D · B → E · C → F.\nO restante do alfabeto segue a mesma distância.","prompt_text":"Examinar carimbo","available_in":1})
	else:
		area(preload("res://scripts/interaction3d/note_interactable_3d.gd"),world,"BilheteCifrado",Vector3(4.3,1.16,1.06),Vector3(0.7,0.24,0.4),{"title":"Gaveta do bibliotecário","text":"DEUD R DWODV\n\nDevolver o livro ao abrigo da luz.\nNão deixar o registro na mesa.","prompt_text":"Ler bilhete","required_flag":"biblioteca.estante.ordenada","available_in":0})
		_drawer = Node3D.new()
		_drawer.position = Vector3(4.3,1.15,0.72)
		world.add_child(_drawer)
		box(_drawer,Vector3.ZERO,Vector3(0.8,0.15,0.4),"mahogany",false)
		box(_drawer,Vector3(0,0.085,0),Vector3(0.3,0.01,0.2),"paper",false)
	# Quatro títulos na mesa: a cifra identifica qual deles deve ser preservado.
	for i in 4:
		var at := Vector3(4.05+i*0.6,1.025,6.8)
		var visual := box(world,at,Vector3(0.44,0.07,0.6),ROLES[i],present)
		var title_label := label(world,TITLES[i],at+Vector3(0,0.055,0.31),20)
		if present and i==0:
			visual.hide()
			title_label.hide()
		if not present:
			if i==0:
				visual.name = "AtlasNaMesa"
				title_label.name = "AtlasLegenda"
			var action := area(preload("res://scripts/interaction3d/interactable_3d.gd"),world,"Titulo%d" % i,at+Vector3(0,0.12,0.28),Vector3(0.5,0.25,0.7),{"prompt_text":"Examinar " + TITLES[i],"available_in":0,"done_flag":"biblioteca.livro.pego" if i==0 else ""})
			action.interacted.connect(_choose_title.bind(i))
	# Um registro de encadernações foi escavado por dentro. O atlas cabe nele,
	# sob o peitoril seco: um livro dentro de outro, preservado da luz e da umidade.
	box(world,Vector3(0.73,1.325,10.91),Vector3(0.65,0.025,0.82),"dark_wood",present)
	for z: float in [10.52,11.3]:
		box(world,Vector3(0.73,1.38,z),Vector3(0.65,0.09,0.035),"paper",present)
	box(world,Vector3(0.42,1.38,10.91),Vector3(0.03,0.09,0.82),"mahogany",present)
	if present:
		_hidden_book = box(world,Vector3(0.73,1.38,10.91),Vector3(0.5,0.09,0.65),"mahogany",true)
		var page := area(preload("res://scripts/interaction3d/note_interactable_3d.gd"),world,"RegistroPreservado",Vector3(1.15,1.4,10.9),Vector3(0.5,0.4,0.75),{"title":"Anotações de Caio Ferraz — 1951","text":"Encontrei este atlas protegido sob o peitoril. Quem o guardou antes de mim?\n\nAlgarismos nas fichas:\nAtlas — 6\nBotânica — 7\nCrônicas — 4\nDiários — 2\n\nA combinação não segue o catálogo. Segue os volumes como estavam antes do sol levar suas cores.\n\nSe eu não voltar, procurem no arquivo reservado.","prompt_text":"Ler registro","required_flag":"biblioteca.livro.guardado","available_in":1})
		page.interacted.connect(func(_by: FirstPersonMotor) -> void: WorldState.set_flag("biblioteca.pagina.lida"))
	else:
		area(preload("res://scripts/interaction3d/item_use_3d.gd"),world,"GuardarAtlas",Vector3(1.15,1.4,10.9),Vector3(0.5,0.4,0.75),{"accepted_item":"atlas","result_flag":"biblioteca.livro.guardado","success_message":"O atlas coube dentro do registro oco, protegido da luz e da umidade.","idle_message":"Um registro de encadernações oco por dentro, guardado sob o peitoril seco.","prompt_text":"Examinar livro oco","available_in":0})
	# Estante móvel: desenho e corpo pertencem ao mesmo nó e se movem juntos.
	var secret := Node3D.new()
	secret.name = "EstanteSecreta"
	secret.position = Vector3(9,0,0.4)
	world.add_child(secret)
	_secret_shelves.append(secret)
	box(secret,Vector3(0,1.6,0),Vector3(2,3.2,0.7),"mahogany",present)
	for row in 5:
		box(secret,Vector3(0,0.3+row*0.6,0.39),Vector3(1.8,0.07,0.12),"brass",present)
		for i in 9:
			box(secret,Vector3(-0.75+i*0.18,0.54+row*0.6,0.39),Vector3(0.12,0.4,0.18),ROLES[(i+row)%4],present)
	var body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2,3.2,0.7)
	var collision := CollisionShape3D.new()
	collision.position.y = 1.6
	collision.shape = shape
	body.add_child(collision)
	secret.add_child(body)
	if not present:
		area(preload("res://scripts/interaction3d/code_lock_3d.gd"),secret,"FechaduraArquivo",Vector3(0,1.15,0.52),Vector3(0.4,0.4,0.25),{"code":EXIT_CODE,"flag_key":"biblioteca.arquivo.aberto","prompt_text":"Fechadura da estante","required_flag":"biblioteca.livro.guardado","available_in":0})
		box(secret,Vector3(0,1.15,0.46),Vector3(0.3,0.22,0.05),"brass",false)
	# No arquivo, o registro de desaparecimento encerra o capítulo.
	box(world,Vector3(9,1.025,-1.55),Vector3(0.5,0.05,0.4),"paper",present)
	if present:
		var final_note := area(preload("res://scripts/interaction3d/note_interactable_3d.gd"),world,"DossieCaio",Vector3(9,1.1,-1.25),Vector3(0.65,0.3,0.65),{"title":"Arquivo de hóspedes — Dr. Caio Ferraz","text":"1951. Quarto ocupado, pertences intactos.\n\nO médico não foi visto deixando o hotel. Nenhum funcionário registrou sua saída.\n\nNo verso, uma anotação em tinta diferente: Marta Siqueira, levantamento fotográfico — 1979. A câmera não foi devolvida.\n\nEntre as fotografias, há uma ficha ainda sem nome. O papel é recente.","prompt_text":"Ler dossiê","required_flag":"biblioteca.arquivo.aberto","available_in":1})
		final_note.interacted.connect(func(_by: FirstPersonMotor) -> void: WorldState.set_flag("biblioteca.concluida"))
	else:
		area(preload("res://scripts/interaction3d/note_interactable_3d.gd"),world,"LivroDoArquivo",Vector3(9,1.1,-1.25),Vector3(0.65,0.3,0.65),{"title":"Registro reservado — 1923","text":"Relação de quartos e documentos recolhidos.\n\nVários nomes foram raspados. Sob a última coluna, alguém começou a escrever uma palavra e parou: saída.","prompt_text":"Ler registro","available_in":0})

func _swap_book(by: FirstPersonMotor, slot: int) -> void:
	if _selected < 0:
		_selected = slot
		by.velocity = Vector3.ZERO
		get_tree().call_group("hud","show_message","Volume selecionado. Examine outro para trocar os dois.")
		_draw_books()
		return
	var first: int = WorldState.get_flag("biblioteca.volume.%d" % _selected,_selected+1)
	var second: int = WorldState.get_flag("biblioteca.volume.%d" % slot,slot+1)
	WorldState.set_flag("biblioteca.volume.%d" % _selected,second)
	WorldState.set_flag("biblioteca.volume.%d" % slot,first)
	_selected = -1
	var correct := true
	for i in 4:
		correct = correct and int(WorldState.get_flag("biblioteca.volume.%d" % i,i+1)) == ORDER[i]
	if correct:
		WorldState.set_flag("biblioteca.estante.ordenada")
		get_tree().call_group("hud","show_message","Um trinco cede na gaveta abaixo da estante.")
	_draw_books()

func _choose_title(by: FirstPersonMotor, index: int) -> void:
	if index != 0:
		NoteUI.open(get_tree(),TITLES[index],"Índice de assuntos e páginas numeradas. A capa tem marcas de uso.")
		return
	if WorldState.is_set("biblioteca.livro.pego"):
		return
	if not WorldState.is_set("biblioteca.estante.ordenada"):
		NoteUI.open(get_tree(),"Atlas do Aurora","Cartas antigas, mapas e folhas em branco entre os cadernos.")
		return
	if by.get_held_item() != "":
		get_tree().call_group("hud","show_message","A mão está ocupada.")
		return
	WorldState.set_flag("biblioteca.cifra.resolvida")
	WorldState.set_flag("biblioteca.livro.pego")
	by.set_held_item("atlas")
	get_tree().call_group("hud","show_message","Pegou o atlas indicado pelo bilhete.")

func _on_flag_changed(_key: String, _value: Variant) -> void:
	_apply_state()

func _apply_state() -> void:
	if _books.size()==4:
		_draw_books()
	if is_instance_valid(_drawer):
		_drawer.position.z = 1.1 if WorldState.is_set("biblioteca.estante.ordenada") else 0.72
	if is_instance_valid(_hidden_book):
		_hidden_book.visible = WorldState.is_set("biblioteca.livro.guardado")
	var atlas = get_node_or_null("World1923/AtlasNaMesa")
	if atlas:
		atlas.visible = not WorldState.is_set("biblioteca.livro.pego")
		get_node("World1923/AtlasLegenda").visible = atlas.visible
	for shelf in _secret_shelves:
		shelf.position.x = 11.3 if WorldState.is_set("biblioteca.arquivo.aberto") else 9.0

func _draw_books() -> void:
	for i in _books.size():
		var holder := _books[i]
		for child in holder.get_children():
			holder.remove_child(child)
			child.queue_free()
		var id: int = int(WorldState.get_flag("biblioteca.volume.%d" % i,i+1))-1
		id = clampi(id,0,3)
		box(holder,Vector3(0,HEIGHTS[id]/2,0),Vector3(0.23,HEIGHTS[id],0.34),ROLES[id],false)
		label(holder,TITLES[id],Vector3(0,HEIGHTS[id]/2,0.18),16)
		box(holder,Vector3(0,0.07,0.175),Vector3(0.2,0.012,0.01),"brass",false)
		holder.position.y = 1.43 if i == _selected else 1.39
