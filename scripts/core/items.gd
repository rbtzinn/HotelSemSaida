class_name Items
extends RefCounted
## Catálogo dos objetos que uma personagem pode segurar na mão.

const DATA: Dictionary = {
	"chave_quadro": {"name": "Chave da recepção", "color": Color("#C9973B")},
	"pinhao_f2": {"name": "Pinhão da F-2", "color": Color("#B9864C")},
	"coroa_f2": {"name": "Coroa da F-2", "color": Color("#B59966")},
	"chave_portaria": {"name": "Chave miúda da portaria", "color": Color("#9A8A6A")},
	"chave_entrada": {"name": "Chave da porta principal", "color": Color("#C9973B")},
	"cunha": {"name": "Cunha de madeira", "color": Color("#7A5230")},
	"cabide": {"name": "Cabide de arame", "color": Color("#8A8A88")},
	"diario": {"name": "Diário de Helena", "color": Color("#573526")},
	"chave_mestra": {"name": "Chave mestra do 2º andar", "color": Color("#C9973B")},
	"chave_gerente": {"name": "Chave da gerência", "color": Color("#C9973B")},
	"partitura": {"name": "Partitura da Valsa da Aurora", "color": Color("#E8DCC0")},
	"chave_biblioteca": {"name": "Chave da Biblioteca", "color": Color("#C9973B")},
	"atlas": {"name": "Atlas do Aurora", "color": Color("#5A1E16")},
	"livro_botanica": {"name": "Botânica", "color": Color("#2A5A42")},
	"livro_cronicas": {"name": "Crônicas", "color": Color("#7A5230")},
	"livro_diarios": {"name": "Diários", "color": Color("#7A2230")},
	"fermento": {"name": "Fermento", "color": Color("#E8D9B0")},
	"gelo": {"name": "Bloco de gelo", "color": Color("#BFE3F0")},
}


static func display_name(item_id: String) -> String:
	return DATA[item_id]["name"] if DATA.has(item_id) else item_id


static func color(item_id: String) -> Color:
	return DATA[item_id]["color"] if DATA.has(item_id) else Color.WHITE


static func texture(item_id: String) -> Texture2D:
	var files := {"fermento": "res://art/sprites/fermento.png", "gelo": "res://art/sprites/gelo.png"}
	return load(files[item_id]) if files.has(item_id) else null
