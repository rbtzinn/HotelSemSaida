class_name GamePlatform
extends RefCounted
## Onde o jogo está rodando: navegador (versão web, só solo) e tela de toque (celular).
## `--toque` nos argumentos do usuário liga os controles de toque no PC, para testar.


static func is_web() -> bool:
	return OS.has_feature("web")


## Tela de toque: mostra os controles na tela e não prende o mouse.
static func is_touch() -> bool:
	return DisplayServer.is_touchscreen_available() or "--toque" in OS.get_cmdline_user_args()


## Renderizador Compatibility (navegador, ou PC sem Vulkan): sem FSR, SSAO nem névoa volumétrica.
static func is_compatibility() -> bool:
	return RenderingServer.get_current_rendering_method() == "gl_compatibility"


## Versão leve do visual: materiais com menos ruído por pixel (celular no navegador).
static func is_lite() -> bool:
	return is_web()


## O navegador deixa a página ir para tela cheia? (O Safari do iPhone não deixa: lá o caminho
## é "Adicionar à Tela de Início", que abre o jogo sem as barras do navegador.)
static func can_fullscreen() -> bool:
	if not is_web():
		return false
	return bool(JavaScriptBridge.eval(
		"!!(document.fullscreenEnabled || document.webkitFullscreenEnabled)", true))


static func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]


## Entra ou sai da tela cheia. No navegador só funciona chamado de dentro de um toque ou
## clique (o navegador recusa pedidos que não vêm de um gesto da pessoa).
static func toggle_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen()
		else DisplayServer.WINDOW_MODE_FULLSCREEN)
