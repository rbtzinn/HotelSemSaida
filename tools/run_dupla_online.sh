#!/usr/bin/env bash
# Roda o teste da dupla online em dois processos (anfitrião e visitante), cada um com
# sua própria pasta de dados (APPDATA), primeiro numa partida nova e depois retomando
# o save da dupla. Uso (Git Bash, na raiz do projeto):
#   GODOT="/c/.../Godot_v4.7.2-stable_win64_console.exe" tools/run_dupla_online.sh
set -u
GODOT="${GODOT:-/c/Users/roberto.gabriel/Ferramentas/Godot/Godot_v4.7.2-stable_win64_console.exe}"
DATA="$(mktemp -d)"
mkdir -p "$DATA/host" "$DATA/guest"
status=0
for mode in "" "retomar"; do
	port=$((7790 + RANDOM % 100))
	APPDATA="$(cygpath -w "$DATA/host")" timeout 90 "$GODOT" --headless --path . --fixed-fps 60 \
		--script res://tools/test_dupla_online.gd -- host "$port" $mode > "$DATA/host.log" 2>&1 &
	sleep 1
	APPDATA="$(cygpath -w "$DATA/guest")" timeout 90 "$GODOT" --headless --path . --fixed-fps 60 \
		--script res://tools/test_dupla_online.gd -- guest "$port" $mode > "$DATA/guest.log" 2>&1
	wait
	for side in host guest; do
		if grep -q "^PASS" "$DATA/$side.log"; then
			grep "^PASS" "$DATA/$side.log"
		else
			echo "FALHOU ($side ${mode:-nova}):"
			grep -E "FAIL|SCRIPT ERROR|Assertion" "$DATA/$side.log" | head -5
			status=1
		fi
	done
done
rm -rf "$DATA"
exit $status
