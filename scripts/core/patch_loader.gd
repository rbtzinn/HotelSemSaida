extends Node
## Primeiro autoload: carrega o remendo baixado pelo botão Atualizar antes de qualquer outro script.
## Precisa rodar no _init: o Godot carrega e cria os autoloads um por um, então os seguintes (e as
## cenas) já saem da versão do remendo. Este arquivo nunca vale num remendo (já rodou quando o
## remendo carrega); mudar aqui só num ZIP novo.
## Só no jogo exportado: no editor, os arquivos do projeto já são a versão atual.

const DIR := "user://atualizacao/"
const PACK := "remendo.pck"
const INFO := "remendo.json"
## O Updater baixa com estes nomes; aqui eles viram os de cima (o .pck carregado fica aberto,
## então não dá para trocá-lo com o jogo rodando).
const NEW_PACK := "remendo-novo.pck"
const NEW_INFO := "remendo-novo.json"
## Existe enquanto o jogo abre com um remendo; a recepção o apaga (confirm). Se ele ainda existir na
## abertura seguinte, o remendo impediu o jogo de chegar à recepção e é descartado.
const OPENING := "remendo.abrindo"

## Versão do remendo carregado (vazio sem remendo).
var loaded_version := ""


func _init() -> void:
	if not OS.has_feature("template"):
		return
	loaded_version = startup(DIR)
	if loaded_version != "":
		print("Remendo %s carregado." % loaded_version)


## A recepção abriu: o remendo carregado funciona.
func confirm() -> void:
	DirAccess.remove_absolute(DIR + OPENING)


## Abertura do jogo: descarta o remendo que não deixou o jogo chegar à recepção da última vez, carrega o
## atual e marca que o jogo está abrindo com ele.
static func startup(folder: String) -> String:
	if FileAccess.file_exists(folder + OPENING):
		push_warning("O remendo não deixou o jogo abrir da última vez; voltando à versão instalada.")
		DirAccess.remove_absolute(folder + PACK)
		DirAccess.remove_absolute(folder + INFO)
		DirAccess.remove_absolute(folder + OPENING)
	var version := load_patch(folder)
	if version != "":
		FileAccess.open(folder + OPENING, FileAccess.WRITE).close()
	return version


## Instala o remendo novo, se houver, e carrega o atual. Devolve a versão carregada ou "".
static func load_patch(folder: String) -> String:
	if FileAccess.file_exists(folder + NEW_PACK) and FileAccess.file_exists(folder + NEW_INFO):
		DirAccess.remove_absolute(folder + PACK)
		DirAccess.remove_absolute(folder + INFO)
		DirAccess.rename_absolute(folder + NEW_PACK, folder + PACK)
		DirAccess.rename_absolute(folder + NEW_INFO, folder + INFO)
	if not FileAccess.file_exists(folder + PACK):
		return ""
	var info: Variant = JSON.parse_string(FileAccess.get_file_as_string(folder + INFO))
	var base := str(ProjectSettings.get_setting("application/config/version", ""))
	# Remendo de outro ZIP (instalaram uma versão completa nova por cima): não serve mais
	if not info is Dictionary or str(info.get("base", "")) != base \
			or not ProjectSettings.load_resource_pack(folder + PACK):
		DirAccess.remove_absolute(folder + PACK)
		DirAccess.remove_absolute(folder + INFO)
		return ""
	return str(info.get("version", ""))
