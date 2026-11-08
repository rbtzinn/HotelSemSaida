extends Node
## Substituto local da Epic para os testes da dupla: a "sala" do código é um ENet em 127.0.0.1.
## Mesma interface de scripts/online/epic_online.gd.

const CODE := "TESTE2"
var port := 0


func open_room(_player_name: String) -> Dictionary:
	await get_tree().process_frame
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(port, 1) != OK:
		return {"error": "porta ocupada"}
	return {"peer": peer, "code": CODE}


func enter_room(code: String, _player_name: String) -> Dictionary:
	await get_tree().process_frame
	if code != CODE:
		return {"error": "Nenhuma sala com o código %s." % code}
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client("127.0.0.1", port) != OK:
		return {"error": "sem conexão"}
	return {"peer": peer}


func close_room() -> void:
	pass
