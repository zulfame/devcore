#!/usr/bin/env bash
# Pagar ukuran: bash-analyzer.py tidak boleh tumbuh tanpa disengaja.
# Menghitung baris berkode (bukan kosong, bukan komentar). Untuk menaikkan batas, ubah MAX_LINES
# di bawah, dan catat alasannya di CHANGELOG.md serta peta penegakan.
set -u
MAX_LINES=960

root=$(cd "$(dirname "$0")/../.." && pwd)
f="$root/.devcore/hooks/lib/bash-analyzer.py"
[ -f "$f" ] || { echo "Ukuran analyzer: berkas tidak ada, dilewati"; exit 0; }

n=$(grep -cvE '^[[:space:]]*(#|$)' "$f")
if [ "$n" -gt "${ANALYZER_MAX_LINES:-$MAX_LINES}" ]; then
  echo "Ukuran analyzer: $n baris berkode melebihi batas ${ANALYZER_MAX_LINES:-$MAX_LINES}. Pangkas, atau naikkan MAX_LINES dengan catatan alasan."
  exit 1
fi
echo "Ukuran analyzer: OK ($n dari ${ANALYZER_MAX_LINES:-$MAX_LINES} baris berkode)"
