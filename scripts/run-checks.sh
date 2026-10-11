#!/usr/bin/env bash
# Satu pintu untuk semua pemeriksaan kerangka; dipakai lokal dan oleh CI.
# Pakai: scripts/run-checks.sh [base-ref]
#   base-ref dipakai deteksi pelemahan test (diff terhadap base). Kosong = origin/main bila ada, selain itu dilewati.
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 2

base=${1:-}
if [ -z "$base" ] && git rev-parse --verify -q origin/main >/dev/null 2>&1; then base=origin/main; fi

fail=0
step() { # judul perintah...
  local title=$1; shift
  echo
  echo "== $title"
  "$@" || { echo "GAGAL: $title"; fail=1; }
}

step "Tes hook penjaga"          .claude/hooks/test-hooks.sh
step "Tes skrip pemeriksa"       scripts/test-scripts.sh
[ -x scripts/test-sync.sh ] && step "Tes sinkronisasi" scripts/test-sync.sh
[ -x scripts/test-evals.sh ] && step "Tes perangkat evaluasi agent" scripts/test-evals.sh
[ -x scripts/test-rules.sh ] && step "Tes pembangun aturan inti" scripts/test-rules.sh
step "Rujukan aturan dan ukuran konteks" scripts/check-rule-refs.sh
step "Penamaan (DC-05)"          scripts/check-naming.sh
step "Tautan dokumen"            scripts/check-links.sh
step "Pelemahan pemeriksaan (AG-09)" scripts/check-weakened-tests.sh "$base"

echo
if [ "$fail" -eq 0 ]; then echo "SEMUA PEMERIKSAAN LULUS"; else echo "ADA PEMERIKSAAN YANG GAGAL"; fi
exit "$fail"
