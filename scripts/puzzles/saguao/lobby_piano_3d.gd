extends Node
## Piano do Saguão: em 1923, Helena toca a introdução da «Valsa da Aurora» (3 · 1 · 5 · 6 a
## partir do dó de latão) e a lingueta do painel atrás do piano se solta. O Sr. Amaral ligou o
## painel ao mecanismo do piano: é a entrada da escada de serviço da torre, em caracol. Hoje, o
## painel ficou destrancado e Lia também passa. A torre vem na próxima etapa; por enquanto a
## escada só sobe no escuro.

const ACTION := preload("res://scripts/interaction3d/interactable_3d.gd")
const MESSAGE := preload("res://scripts/interaction3d/message_interactable_3d.gd")
const WALTZ_PLAYED := "saguao.piano.valsa"
const WALTZ := [3, 1, 5, 6]
## Painel na parede leste, atrás do piano: dobradiça ao norte, abre para dentro do Saguão.
const PANEL_Z := Vector2(6.6, 7.6)
const PANEL_TOP: float = 2.2
const KEYBOARD := Vector3(LobbyRoom3D.PIANO.x - 1.4, 0.95, LobbyRoom3D.PIANO.z)
const STAIR_TEXT := "Uma escada de ferro em caracol sobe por dentro da parede, no escuro. Lá do alto vem um tique-taque."

var _leaves: Array[Node3D] = []
var _openings: Array[Node3D] = []


func install(room: ChapterRoom3D) -> void:
	for present: bool in [false, true]:
		var world := room.get_node("WorldToday" if present else "World1923") as Node3D
		_build_panel(room, world, present)
	var past := room.get_node("World1923") as Node3D
	var today := room.get_node("WorldToday") as Node3D
	var keys := room.area(ACTION, past, "TocarPiano", KEYBOARD, Vector3(0.24, 0.24, 1.4), {
		"prompt_text": "Tocar piano", "available_in": 0})
	keys.interacted.connect(_play)
	room.area(MESSAGE, today, "LonaPiano", KEYBOARD + Vector3(-0.08, 0, 0), Vector3(0.24, 0.5, 1.5), {
		"prompt_text": "Levantar a lona", "available_in": 1,
		"message": "Debaixo da lona, o teclado amarelou e várias teclas afundaram. Na frente do primeiro dó, uma plaquinha de latão.",
	})
	_restore()
	WorldState.flag_changed.connect(_on_flag)


func _build_panel(room: ChapterRoom3D, world: Node3D, present: bool) -> void:
	var face := LobbyRoom3D.EAST
	var width := PANEL_Z.y - PANEL_Z.x
	var wood := "panel" if not present else "plank"
	# Vão escuro atrás do painel (aparece aberto) e o corrimão da escada em caracol
	var opening := Node3D.new()
	opening.name = "VaoTorre"
	world.add_child(opening)
	room.box(opening, Vector3(face - 0.012, PANEL_TOP / 2.0, (PANEL_Z.x + PANEL_Z.y) / 2.0), Vector3(0.01, PANEL_TOP, width), "dark", present)
	room.box(opening, Vector3(face - 0.02, 1.0, PANEL_Z.x + 0.7), Vector3(0.012, 2.0, 0.03), "iron", present)
	for i in 3:
		var step := room.box(opening, Vector3(face - 0.025, 0.25 + i * 0.45, PANEL_Z.x + 0.3 + i * 0.15), Vector3(0.012, 0.04, 0.5), "iron", present)
		step.rotation_degrees.x = 10.0 * (i - 1)
	# Uma luz fraca que desce pela escada deixa ver o vão aberto atrás do piano
	var glow := OmniLight3D.new()
	glow.position = Vector3(face - 0.4, 1.6, PANEL_Z.x - 0.2)
	glow.light_color = Color("#F2D49B") if not present else Color("#8FA6BE")
	glow.light_energy = 0.9
	glow.omni_range = 2.6
	opening.add_child(glow)
	_openings.append(opening)
	# Folha do painel: colisão própria, que acompanha a folha quando ela abre
	var hinge := Node3D.new()
	hinge.name = "Painel"
	hinge.position = Vector3(face, 0, PANEL_Z.x)
	world.add_child(hinge)
	var leaf := StaticBody3D.new()
	hinge.add_child(leaf)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.05, PANEL_TOP, width)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(-0.035, PANEL_TOP / 2.0, width / 2.0)
	leaf.add_child(collision)
	room.box(leaf, collision.position, shape.size, wood, present)
	# Molduras de lambri, iguais às da parede: sem maçaneta nem fechadura
	for y: float in [0.55, 1.55]:
		room.box(leaf, Vector3(-0.065, y, width / 2.0), Vector3(0.012, 0.7, width - 0.25), "dark_wood" if not present else "plank", present)
	_leaves.append(hinge)
	var label := "PainelHoje" if present else "Painel1923"
	var spot := Vector3(face - 0.12, 1.1, (PANEL_Z.x + PANEL_Z.y) / 2.0)
	var examine := room.area(ACTION, world, label, spot, Vector3(0.12, 1.8, width), {
		"prompt_text": "Examinar painel", "available_in": 1 if present else 0})
	examine.interacted.connect(_use_panel.bind(present))


func _play(_by: FirstPersonMotor) -> void:
	var ui := PianoUI.open(get_tree(), WALTZ)
	ui.solved.connect(func() -> void:
		if not WorldState.is_set(WALTZ_PLAYED):
			WorldState.set_flag(WALTZ_PLAYED)
			_say("Atrás do piano, a parede estala. Um painel do lambri se solta e abre."))


func _use_panel(_by: FirstPersonMotor, present: bool) -> void:
	if WorldState.is_set(WALTZ_PLAYED):
		_say(STAIR_TEXT)
	elif present:
		_say("Um painel do lambri, inchado de umidade. Sem maçaneta, sem fechadura. Bate oco.")
	else:
		_say("Um painel do lambri, sem maçaneta nem fechadura. Bate oco. Do outro lado, um tique-taque distante.")


func _restore() -> void:
	var open := WorldState.is_set(WALTZ_PLAYED)
	for hinge: Node3D in _leaves:
		hinge.rotation_degrees.y = -95.0 if open else 0.0
	for opening: Node3D in _openings:
		opening.visible = open


func _on_flag(key: String, _value: Variant) -> void:
	if key == WALTZ_PLAYED:
		_restore()


func _say(message: String) -> void:
	get_tree().call_group("hud", "show_message", message)
