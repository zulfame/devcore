#!/usr/bin/env bash
# Menjaga rujukan aturan dan ukuran berkas yang selalu dimuat ke konteks agent.
#   1. Setiap ID aturan yang dirujuk (AG-06, SC-07, ...) harus terdefinisi sebagai butir di docs/engineering-standard.md.
#   2. Berkas yang dimuat tiap sesi tidak boleh melewati batas ukuran (kepatuhan menurun pada berkas panjang).
#   3. Bila scripts/build-rules.sh ada (devcore): hasil bangun aturan inti tidak boleh basi.
# ID yang tidak pernah dirujuk di luar standar hanya dilaporkan sebagai informasi.
# Pakai: scripts/check-rule-refs.sh [root]
# Batas bawaan (dapat diubah lewat lingkungan): MAX_RULES_LINES=110 MAX_CLAUDE_LINES=200 MAX_REMINDER_LINES=15
set -u
root=${1:-$(cd "$(dirname "$0")/.." && pwd -P)}
cd "$root" || { echo "root tidak ditemukan: $root"; exit 2; }
std=docs/engineering-standard.md
[ -f "$std" ] || { echo "RUJUKAN: $std tidak ada"; exit 2; }

fail=0
PREFIX='(AG|SC|VL|TS|CD|AR|DB|API|PF|ER|LG|CF|DP|CI|DC|UX|OS)'
ID_RE="${PREFIX}-[0-9]{2}"

defined=$(grep -oE "^- \`${ID_RE}\`" "$std" | grep -oE "$ID_RE" | sort -u)

# Berkas yang dipindai: hanya berkas KERANGKA. Berkas milik proyek (README, CLAUDE.md, docs/status.md, briefs, adr, ...)
# tidak dipindai agar nomor tiket/ID milik proyek sendiri tidak memicu galat palsu. Di repo devcore
# (ditandai adanya scripts/build-rules.sh) README.md, CLAUDE.md, dan skenario evaluasi ikut dipindai.
scan_files() {
  local extra=""
  [ -x scripts/build-rules.sh ] && extra="CLAUDE.md README.md evals/scenarios/*/grade.sh"
  for f in docs/enforcement-map.md docs/adopting-devcore.md docs/evaluating-agents.md docs/templates/*.md \
           .claude/devcore-rules.md .claude/devcore-reminder.txt .claude/skills/*/SKILL.md .claude/agents/*.md \
           .claude/hooks/*.sh .claude/hooks/lib/* scripts/*.sh $extra; do
    [ -f "$f" ] || continue
    # skrip tes dan data uji sengaja memuat ID palsu sebagai fixture
    case "$(basename "$f")" in test-*.sh|bash-guard-cases.tsv) continue ;; esac
    echo "$f"
  done
}

refs_tmp=$(mktemp); trap 'rm -f "$refs_tmp"' EXIT
while IFS= read -r f; do
  [ "$f" = "$std" ] && continue
  grep -ohE "(^|[^A-Za-z0-9_-])${ID_RE}([^0-9]|$)" "$f" 2>/dev/null | grep -oE "$ID_RE" | sort -u | while IFS= read -r id; do
    echo "$id $f"
  done
done < <(scan_files) > "$refs_tmp"

# 1. rujukan menggantung
while IFS=' ' read -r id f; do
  if ! printf '%s\n' "$defined" | grep -qx "$id"; then
    echo "RUJUKAN: $id dirujuk di $f tetapi tidak terdefinisi di $std"
    fail=1
  fi
done < "$refs_tmp"

# 2. batas ukuran
cap() { # berkas batas keterangan
  [ -f "$1" ] || return 0
  local n; n=$(wc -l < "$1" | tr -d ' ')
  if [ "$n" -gt "$2" ]; then echo "UKURAN: $1 $n baris melewati batas $2 ($3)"; fail=1; fi
}
cap .claude/devcore-rules.md "${MAX_RULES_LINES:-110}" "dimuat ke setiap sesi"
cap CLAUDE.md "${MAX_CLAUDE_LINES:-200}" "dimuat ke setiap sesi"
cap .claude/devcore-reminder.txt "${MAX_REMINDER_LINES:-15}" "disisipkan di setiap pesan"

# 3. hasil bangun aturan inti (hanya di devcore)
if [ -x scripts/build-rules.sh ]; then
  scripts/build-rules.sh --check "$root" || fail=1
fi

# informasi: ID tak pernah dirujuk di luar standar
total=$(printf '%s\n' "$defined" | grep -c .)
used=$(cut -d' ' -f1 "$refs_tmp" | sort -u | grep -c .)
echo "Info: $used dari $total ID aturan dirujuk di luar standar."

[ "$fail" -eq 0 ] && echo "Rujukan aturan: OK"
exit "$fail"
