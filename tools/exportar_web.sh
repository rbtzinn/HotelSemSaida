#!/usr/bin/env bash
# Gera a versão de navegador (solo) em build/web/, sem tocar no project.godot do jogo de Windows.
# Copia o projeto para build/web_src/, tira o plugin da Epic (não existe no navegador), liga os
# ajustes do renderizador Compatibility e exporta com o preset de tools/web/export_presets.cfg.
# Uso: tools/exportar_web.sh [caminho do Godot] [--site]   (precisa dos modelos de exportação da Web)
# Com --site, copia o resultado para site/jogar/, que a Vercel publica junto com o site.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${1:-${GODOT:-godot}}"
SRC=build/web_src
OUT=build/web
fail() { echo "ERRO: $*" >&2; exit 1; }
command -v "$GODOT" >/dev/null 2>&1 || [ -x "$GODOT" ] || fail "não achei o Godot em '$GODOT' (passe o caminho)"

rm -rf "$SRC" "$OUT"
mkdir -p "$SRC" "$OUT"
# Só o que o jogo usa; addons/ (Epic) e as pastas de trabalho ficam de fora
for item in project.godot art scenes scripts shaders; do
	cp -r "$item" "$SRC/"
done
rm -rf "$SRC/art/previews" "$SRC/art/source" "$SRC/art/incoming" "$SRC/art/future/raw"
cp tools/web/export_presets.cfg "$SRC/export_presets.cfg"

# project.godot da cópia: sem os autoloads e o plugin da Epic, e com os ajustes da Web
python3 - "$SRC/project.godot" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
# Autoloads do plugin (apontam para uid:// de addons/)
text = re.sub(r'^[A-Za-z0-9]+="\*uid://[a-z0-9]+"\n', "", text, flags=re.M)
text = re.sub(r"\[editor_plugins\]\n\nenabled=.*\n\n", "", text)
text = text.replace("[rendering]\n", """[rendering]

renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
limits/opengl/max_lights_per_object=24
limits/opengl/max_renderable_lights=48
""", 1)
# Sem FSR neste renderizador (o jogo acerta a escala do 3D ao abrir)
text = text.replace("scaling_3d/mode=1\n", "scaling_3d/mode=0\n").replace(
	"anti_aliasing/quality/screen_space_aa=1\n", "")
open(path, "w", encoding="utf-8").write(text)
PY

echo "Importando a cópia do projeto..."
"$GODOT" --headless --path "$SRC" --import >"$OUT/../web_import.log" 2>&1 || true
echo "Exportando..."
"$GODOT" --headless --path "$SRC" --export-release "Web" "$(pwd)/$OUT/index.html" >"$OUT/../web_export.log" 2>&1 \
	|| { tail -20 "$OUT/../web_export.log"; fail "o export falhou (build/web_export.log)"; }
if grep -qE "SCRIPT ERROR|Parse Error" "$OUT/../web_export.log"; then
	grep -E "SCRIPT ERROR|Parse Error" -A3 "$OUT/../web_export.log" | head -20
	fail "o export acusou script com erro"
fi
[ -f "$OUT/index.wasm" ] && [ -f "$OUT/index.pck" ] || fail "o export não gerou index.wasm/index.pck"
ls -la "$OUT"
# Com --site, publica no site (Vercel serve a pasta site/): fica em <site>/jogar/
if [ "${2:-}" = "--site" ]; then
	rm -rf site/jogar
	cp -r "$OUT" site/jogar
	echo "Copiado para site/jogar (faça commit e push para a Vercel publicar)"
fi
echo "Pronto: $OUT (sirva a pasta por HTTP; abrir o index.html direto do disco não funciona)"
