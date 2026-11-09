class_name GameVersion
## Versão do jogo. Suba VERSION a cada versão publicada (tools/publicar_versao.sh).
## A "base" é a versão do ZIP instalado (application/config/version no project.godot): ela só muda
## numa versão completa. Um remendo traz este arquivo novo, então VERSION mostra a versão com o remendo.

const VERSION := "1.1.0"


## Versão do ZIP instalado (o remendo não muda as configurações do projeto).
static func base() -> String:
	var version := str(ProjectSettings.get_setting("application/config/version", "")).strip_edges()
	return version if version != "" else VERSION


## -1 se a < b, 0 se iguais, 1 se a > b ("1.0.10" > "1.0.9").
static func compare(a: String, b: String) -> int:
	var left := a.split(".")
	var right := b.split(".")
	for i in maxi(left.size(), right.size()):
		var x := left[i].to_int() if i < left.size() else 0
		var y := right[i].to_int() if i < right.size() else 0
		if x != y:
			return 1 if x > y else -1
	return 0
