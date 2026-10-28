class_name UIUtil
extends RefCounted
## Utilidades das telas que pausam o jogo (leitura, cadeado, menu de pausa).


## Espera soltar as teclas de confirmar antes de despausar. Sem isso, o mesmo E
## (ou Espaço) que fechou a tela vira interação (ou pulo) no jogo.
static func unpause_after_release(tree: SceneTree) -> void:
	while Input.is_action_pressed("interact") or Input.is_action_pressed("ui_accept") \
			or Input.is_action_pressed("jump"):
		await tree.process_frame
	await tree.process_frame
	tree.paused = false
