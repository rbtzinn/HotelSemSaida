class_name LoadingScreen
extends Control
## Tela de carregamento (pedido do Roberto, 09/11/2026): ao abrir uma sala, em vez de a imagem
## congelar, aparece o sol art déco da recepção girando, o nome da sala e a barra do carregamento.
## O RoomManager a mostra antes de abrir a cena e a esconde depois do primeiro quadro da sala nova.
## A sala é montada por código no _ready (trava o jogo um instante): nessa hora a tela fica parada,
## mas continua dizendo "Carregando", então ninguém pensa que o jogo travou.

const FONT := preload("res://art/fonts/interface_font.tres")
const SIGN := preload("res://art/fonts/sign_font.tres")
const BACKGROUND := Color("#120d0f")
const INK := Color("#eae2cf")
const GOLD := Color("#d6b272")
const COLD := Color("#9fb6c4")
## Nome de cada cena (pelo nome do arquivo) para mostrar embaixo do "Carregando".
const NAMES := {
	"entrada": "Recepção",
	"saguao_3d": "Saguão",
	"cozinha_3d": "Cozinha",
	"manutencao_3d": "Manutenção",
	"biblioteca_3d": "Biblioteca",
	"caldeiras_3d": "Casa das caldeiras",
	"quartos_3d": "Quartos · 2º andar",
	"salao_3d": "Salão de baile · 3º andar",
	"torre_3d": "Torre do relógio",
}
const RAYS := 11

## 0..1 do carregamento em segundo plano (a montagem da sala vem depois e não tem medida).
var progress := 0.0
var _title := ""
var _turn := 0.0
var _dots := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


static func title_for(scene_path: String) -> String:
	return NAMES.get(scene_path.get_file().get_basename(), "")


func begin(scene_path: String) -> void:
	_title = title_for(scene_path)
	progress = 0.0
	visible = true
	queue_redraw()


func end() -> void:
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_turn = fmod(_turn + delta*0.6, TAU)
	_dots = fmod(_dots + delta*2.5, 4.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	var past := EraManager.current_era == Era.Id.PAST_1923
	var accent := GOLD if past else COLD
	var unit := minf(size.x, size.y)/360.0
	var center := Vector2(size.x*0.5, size.y*0.44)
	var radius := 46.0*unit
	# Sol nascente da recepção: meio arco e raios que giram devagar
	draw_arc(center, radius, PI, TAU, 48, accent, maxf(1.0, unit), true)
	for i in RAYS:
		var angle := PI + (i + 0.5)*PI/RAYS + _turn
		var direction := Vector2.from_angle(angle)
		if direction.y > 0.05:
			continue  # só a metade de cima, como na fachada
		var color := accent
		color.a = 0.35 + 0.65*absf(sin(angle*2.0 - _turn*3.0))
		draw_line(center + direction*radius*0.3, center + direction*radius*0.88, color, maxf(1.0, unit), true)
	draw_line(center + Vector2(-radius*1.15, 0), center + Vector2(radius*1.15, 0), accent, maxf(1.0, unit), true)
	var text := "Carregando" + ".".repeat(int(_dots))
	var y := center.y + 34.0*unit
	draw_string(FONT, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, int(12*unit), INK)
	if _title != "":
		draw_string(SIGN, Vector2(0, y + 22.0*unit), _title.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x,
				int(15*unit), accent)
	# Barra do carregamento
	var bar := Rect2(center.x - radius*1.15, y + 34.0*unit, radius*2.3, maxf(1.0, unit))
	draw_rect(bar, Color(accent, 0.2))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x*clampf(progress, 0.0, 1.0), bar.size.y)), accent)
