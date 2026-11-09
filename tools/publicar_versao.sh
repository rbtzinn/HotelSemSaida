#!/usr/bin/env bash
# Publica uma versão do jogo no GitHub Releases (Git Bash, na raiz do projeto, com o gh logado).
#
#   tools/publicar_versao.sh completa ["notas"]   jogo inteiro: ZIP (primeira instalação) e cada arquivo solto
#   tools/publicar_versao.sh remendo  ["notas"]   só o .pck com o que mudou desde a última completa
#
# Antes: suba VERSION em scripts/core/game_version.gd e faça commit e push.
# Versão completa: sempre que mudar project.godot, addons/ ou a versão do Godot (o remendo não carrega
# isso). Nela, application/config/version (project.godot) = VERSION. Quem já tem o jogo atualiza pelo
# próprio jogo e baixa só os arquivos que mudaram (em geral só o .pck); o ZIP é só para quem instala.
# Remendo: application/config/version continua a da última completa (a "base"); o remendo leva tudo o
# que mudou desde ela, então quem pula versões baixa um só.
# O jogo lê o versao.json do último Release (scripts/core/updater.gd).
set -euo pipefail
GODOT="${GODOT:-/c/Users/roberto.gabriel/Ferramentas/Godot/Godot_v4.7.2-stable_win64_console.exe}"
REPO="rbtzinn/HotelSemSaida"
PRESET="Windows x64"
MODE="${1:-}"
NOTES="${2:-}"
# Arquivos do jogo instalado (o que vai solto no Release e o que o jogo compara ao se atualizar)
GAME_FILES="HotelSemSaida.exe HotelSemSaida.pck libeosg.windows.template_release.x86_64.dll EOSSDK-Win64-Shipping.dll xaudio2_9redist.dll"

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
BASE_GAME="build/$BASE/HotelSemSaida"
BASE_ZIP="build/$BASE/HotelSemSaida-$BASE-windows.zip"

# Lista dos arquivos da base com tamanho e sha256 (o jogo baixa só os que não batem com os dele)
files_json() {
	local first=1
	printf '['
	for file in $GAME_FILES; do
		[ $first = 1 ] || printf ', '
		first=0
		printf '{"name": "%s", "size": %s, "sha256": "%s", "url": "%s"}' "$file" "$(stat -c %s "$BASE_GAME/$file")" \
			"$(sha256sum "$BASE_GAME/$file" | cut -d' ' -f1)" "$DOWNLOAD/v$BASE/$file"
	done
	printf ']'
}

manifest() {  # $1 = JSON do remendo ou null
	cat > "$OUT/versao.json" <<EOF
{
	"version": "$VERSION",
	"base": "$BASE",
	"patch": $1,
	"zip": "$DOWNLOAD/v$BASE/HotelSemSaida-$BASE-windows.zip",
	"zip_size": $(stat -c %s "$BASE_ZIP"),
	"zip_sha256": "$(sha256sum "$BASE_ZIP" | cut -d' ' -f1)",
	"files": $(files_json),
	"page": "https://github.com/$REPO/releases/tag/v$VERSION"
}
EOF
}

export_quiet() {  # o editor aberto prende a DLL de debug do plugin: o aviso não atrapalha o release
	"$GODOT" --headless --path . "$@" 2>&1 | grep -E "^ERROR" | grep -v "template_debug\|~libeosg" || true
}

if [ "$MODE" = completa ]; then
	[ "$VERSION" = "$BASE" ] || fail "numa versão completa, config/version do project.godot ($BASE) precisa ser igual a VERSION ($VERSION)"
	mkdir -p "$BASE_GAME"
	export_quiet --export-release "$PRESET" "$BASE_GAME/HotelSemSaida.exe"
	for file in $GAME_FILES; do
		[ -f "$BASE_GAME/$file" ] || fail "o export não gerou $file"
	done
	python -c "import shutil, sys; shutil.make_archive(sys.argv[1][:-4], 'zip', sys.argv[2], 'HotelSemSaida')" \
		"$BASE_ZIP" "build/$BASE"
	manifest null
	assets=("$BASE_ZIP" "$OUT/versao.json")
	for file in $GAME_FILES; do assets+=("$BASE_GAME/$file"); done
	gh release create "v$VERSION" "${assets[@]}" --repo "$REPO" --target "$(git rev-parse HEAD)" \
		--title "Hotel Sem Saída $VERSION" --latest \
		--notes "${NOTES:-Versão completa. Para instalar: baixe o ZIP, extraia a pasta inteira e abra HotelSemSaida.exe. Quem já tem o jogo atualiza pela recepção.}"
else
	[ "$VERSION" != "$BASE" ] || fail "VERSION ($VERSION) é a da última completa; suba VERSION para publicar um remendo"
	git rev-parse -q --verify "refs/tags/v$BASE" >/dev/null || git fetch -q origin "refs/tags/v$BASE:refs/tags/v$BASE" \
		|| fail "não achei a versão completa v$BASE"
	if ! git diff --quiet "v$BASE" HEAD -- project.godot addons/; then
		fail "project.godot ou addons/ mudaram desde a v$BASE: isso não vai num remendo; publique uma versão completa"
	fi
	if [ ! -f "$BASE_GAME/HotelSemSaida.pck" ] || [ ! -f "$BASE_ZIP" ]; then
		echo "Baixando o ZIP da v$BASE para comparar…"
		mkdir -p "build/$BASE"
		gh release download "v$BASE" --repo "$REPO" --pattern "*.zip" --dir "build/$BASE" --clobber
		python -c "import shutil, sys; shutil.unpack_archive(sys.argv[1], sys.argv[2])" "$BASE_ZIP" "build/$BASE"
	fi
	# Completas antigas (1.0.0, 1.0.1) só tinham o ZIP: põe os arquivos soltos nelas
	have=$(gh release view "v$BASE" --repo "$REPO" --json assets --jq '.assets[].name')
	for file in $GAME_FILES; do
		grep -qx "$file" <<< "$have" || gh release upload "v$BASE" "$BASE_GAME/$file" --repo "$REPO"
	done
	PATCH="$OUT/remendo-$VERSION.pck"
	export_quiet --export-patch "$PRESET" "$PATCH" --patches "$BASE_GAME/HotelSemSaida.pck"
	[ -f "$PATCH" ] || fail "o export não gerou o remendo"
	SIZE=$(stat -c %s "$PATCH")
	SHA=$(sha256sum "$PATCH" | cut -d' ' -f1)
	manifest "{\"url\": \"$DOWNLOAD/v$VERSION/remendo-$VERSION.pck\", \"size\": $SIZE, \"sha256\": \"$SHA\"}"
	gh release create "v$VERSION" "$PATCH" "$OUT/versao.json" --repo "$REPO" --target "$(git rev-parse HEAD)" \
		--title "Hotel Sem Saída $VERSION" --latest \
		--notes "${NOTES:-Atualização. Quem já tem o jogo atualiza na recepção (botão Atualizar). Para instalar: $DOWNLOAD/v$BASE/HotelSemSaida-$BASE-windows.zip}"
fi
echo "Publicada a versão $VERSION ($MODE)."
