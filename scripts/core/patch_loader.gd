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

## Versão do remendo carregado (vazio sem remendo).
var loaded_version := ""


func _init() -> void:
	if not OS.has_feature("template"):
		return
	loaded_version = load_patch(DIR)
	if loaded_version != "":
		print("Remendo %s carregado." % loaded_version)


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
