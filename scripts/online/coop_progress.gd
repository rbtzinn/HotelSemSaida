extends RefCounted
## Só a época que produz um vestígio pode publicá-lo. Valores vindos da rede
## também passam pelos limites que as malhas e os enigmas esperam.

const PAST_SWITCHES := [
	"saguao.elevador.no_alto","cozinha.despensa.aberta","cozinha.fermento.pego",
	"cozinha.forno.massa","cozinha.gelo.posto","cozinha.piso.apodrecido",
	"cozinha.elevador.no_alto","cozinha.elevador.freio","cozinha.elevador.travado",
	"biblioteca.estante.ordenada","biblioteca.cifra.resolvida","biblioteca.livro.pego",
	"biblioteca.livro.guardado","biblioteca.arquivo.aberto",
]
const PRESENT_SWITCHES := [
	"saguao.bolsa.marta","cozinha.concluida","manutencao.chave.pega","biblioteca.porta.hoje",
	"biblioteca.pagina.lida","biblioteca.concluida","caldeiras.oficina.visitada",
	"caldeiras.f2.inspecao.aberta","caldeiras.limpeza.aberta","caldeiras.concluida",
]
const RANGES := {
	"saguao.quadro.gancho": Vector2i(0,12), "caldeiras.pressao.etapa": Vector2i(-1,3),
	"caldeiras.drenagem.ramais": Vector2i(0,7), "caldeiras.tiragem.admissao": Vector2i(0,3),
	"caldeiras.tiragem.chamine": Vector2i(0,3),
	"biblioteca.volume.0": Vector2i(1,4), "biblioteca.volume.1": Vector2i(1,4),
	"biblioteca.volume.2": Vector2i(1,4), "biblioteca.volume.3": Vector2i(1,4),
}

static func allowed(era: int, key: String, value: Variant) -> bool:
	if key == "helena.mao" or key == "lia.mao":
		var hand := "helena.mao" if era == Era.Id.PAST_1923 else "lia.mao"
		return key == hand and value is String and (value == "" or Items.DATA.has(value))
	if value is bool:
		var switches := PAST_SWITCHES if era == Era.Id.PAST_1923 else PRESENT_SWITCHES
		if key in switches:
			return true
		for gear: String in ["pinhao_f2","coroa_f2"]:
			var prefix := "caldeiras.f2.%s." % gear
			if key.begins_with(prefix):
				var actions := ["retirada","guardada"] if era == Era.Id.PAST_1923 else ["recuperada","montada"]
				return key.trim_prefix(prefix) in actions
	if era != Era.Id.PAST_1923:
		return false
	if key in ["cozinha.gelo.x","cozinha.gelo.z"]:
		return (value is float or value is int) and absf(value) < 1000
	if value is int and RANGES.has(key):
		var limits: Vector2i = RANGES[key]
		return value >= limits.x and value <= limits.y
	return false
