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
