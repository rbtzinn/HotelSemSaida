#!/usr/bin/env bash
# Publica uma versão do jogo no GitHub Releases (Git Bash, na raiz do projeto, com o gh logado).
#
#   tools/publicar_versao.sh completa ["notas"]   ZIP inteiro (.exe, .pck e DLLs da Epic)
#   tools/publicar_versao.sh remendo  ["notas"]   só o .pck com o que mudou desde o ZIP
#
# Antes: suba VERSION em scripts/core/game_version.gd e faça commit e push.
# Versão completa: a primeira, e sempre que mudar project.godot, addons/ ou a versão do Godot
# (o remendo não carrega isso). Nela, application/config/version (project.godot) = VERSION.
# Remendo: application/config/version continua a do ZIP (a "base"); o remendo leva tudo o que mudou
# desde ela, então quem pula versões baixa um só.
# O jogo lê o versao.json do último Release (scripts/core/updater.gd).
set -euo pipefail
GODOT="${GODOT:-/c/Users/roberto.gabriel/Ferramentas/Godot/Godot_v4.7.2-stable_win64_console.exe}"
REPO="rbtzinn/HotelSemSaida"
PRESET="Windows x64"
MODE="${1:-}"
NOTES="${2:-}"

VERSION=$(sed -n 's/^const VERSION := "\(.*\)"/\1/p' scripts/core/game_version.gd)
BASE=$(sed -n 's/^config\/version="\(.*\)"/\1/p' project.godot)
DOWNLOAD="https://github.com/$REPO/releases/download"
fail() { echo "ERRO: $*" >&2; exit 1; }

[ "$MODE" = completa ] || [ "$MODE" = remendo ] || fail "use: tools/publicar_versao.sh completa|remendo [\"notas\"]"
[ -n "$VERSION" ] && [ -n "$BASE" ] || fail "não achei VERSION (game_version.gd) ou config/version (project.godot)"
[ -f epic_credentials.cfg ] || fail "falta o epic_credentials.cfg (sem ele a sala por código não funciona no .exe)"
[ -z "$(git status --porcelain)" ] || fail "há mudanças sem commit; faça commit e push antes"
git fetch -q origin
[ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ] || fail "o commit atual não está no GitHub; faça push antes"
if gh release view "v$VERSION" --repo "$REPO" >/dev/null 2>&1; then
	fail "a versão $VERSION já foi publicada; suba VERSION em scripts/core/game_version.gd"
fi

OUT="build/$VERSION"
mkdir -p "$OUT"
manifest() {  # $1 = JSON do remendo ou null
	cat > "$OUT/versao.json" <<EOF
{
	"version": "$VERSION",
	"base": "$BASE",
	"patch": $1,
	"zip": "$DOWNLOAD/v$BASE/HotelSemSaida-$BASE-windows.zip",
	"page": "https://github.com/$REPO/releases/tag/v$VERSION"
}
EOF
}

if [ "$MODE" = completa ]; then
	[ "$VERSION" = "$BASE" ] || fail "numa versão completa, config/version do project.godot ($BASE) precisa ser igual a VERSION ($VERSION)"
	grep -q "^application/file_version=\"$VERSION.0\"" export_presets.cfg \n		|| fail "suba application/file_version e product_version no export_presets.cfg para $VERSION.0"
	GAME="$OUT/HotelSemSaida"
	mkdir -p "$GAME"
	"$GODOT" --headless --path . --export-release "$PRESET" "$GAME/HotelSemSaida.exe" 2>&1 \
		| grep -E "^ERROR" | grep -v "template_debug\|~libeosg" || true
	for file in HotelSemSaida.exe HotelSemSaida.pck libeosg.windows.template_release.x86_64.dll \
			EOSSDK-Win64-Shipping.dll xaudio2_9redist.dll; do
		[ -f "$GAME/$file" ] || fail "o export não gerou $file"
	done
	ZIP="$OUT/HotelSemSaida-$VERSION-windows.zip"
	python -c "import shutil, sys; shutil.make_archive(sys.argv[1][:-4], 'zip', sys.argv[2], 'HotelSemSaida')" \
		"$ZIP" "$OUT"
	manifest null
	gh release create "v$VERSION" "$ZIP" "$OUT/versao.json" --repo "$REPO" --target "$(git rev-parse HEAD)" \
		--title "Hotel Sem Saída $VERSION" --notes "${NOTES:-Versão completa. Baixe o ZIP, extraia a pasta inteira e abra HotelSemSaida.exe.}" --latest
else
	[ "$VERSION" != "$BASE" ] || fail "VERSION ($VERSION) é a do ZIP; suba VERSION para publicar um remendo"
	git rev-parse -q --verify "refs/tags/v$BASE" >/dev/null || git fetch -q origin "refs/tags/v$BASE:refs/tags/v$BASE" \
		|| fail "não achei a versão completa v$BASE"
	if ! git diff --quiet "v$BASE" HEAD -- project.godot addons/; then
		fail "project.godot ou addons/ mudaram desde a v$BASE: isso não vai num remendo; publique uma versão completa"
	fi
	BASE_PCK="build/$BASE/HotelSemSaida/HotelSemSaida.pck"
	if [ ! -f "$BASE_PCK" ]; then
		echo "Baixando o ZIP da v$BASE para comparar…"
		mkdir -p "build/$BASE"
		gh release download "v$BASE" --repo "$REPO" --pattern "*.zip" --dir "build/$BASE" --clobber
		python -c "import shutil, sys; shutil.unpack_archive(sys.argv[1], sys.argv[2])" \
			"build/$BASE/HotelSemSaida-$BASE-windows.zip" "build/$BASE"
	fi
	PATCH="$OUT/remendo-$VERSION.pck"
	"$GODOT" --headless --path . --export-patch "$PRESET" "$PATCH" --patches "$BASE_PCK" 2>&1 \
		| grep -E "^ERROR" | grep -v "template_debug\|~libeosg" || true
	[ -f "$PATCH" ] || fail "o export não gerou o remendo"
	SIZE=$(stat -c %s "$PATCH")
	SHA=$(sha256sum "$PATCH" | cut -d' ' -f1)
	manifest "{\"url\": \"$DOWNLOAD/v$VERSION/remendo-$VERSION.pck\", \"size\": $SIZE, \"sha256\": \"$SHA\"}"
	gh release create "v$VERSION" "$PATCH" "$OUT/versao.json" --repo "$REPO" --target "$(git rev-parse HEAD)" \
		--title "Hotel Sem Saída $VERSION" --latest \
		--notes "${NOTES:-Atualização. Quem já tem o jogo atualiza na recepção (botão Atualizar). Jogo completo: $DOWNLOAD/v$BASE/HotelSemSaida-$BASE-windows.zip}"
fi
echo "Publicada a versão $VERSION ($MODE)."
