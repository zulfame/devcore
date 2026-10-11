#!/usr/bin/env bash
# Satu pintu untuk semua pemeriksaan kerangka; dipakai lokal dan oleh CI.
# Pakai: .devcore/scripts/run-checks.sh [base-ref]
#   base-ref dipakai deteksi pelemahan test (diff terhadap base). Kosong = origin/main bila ada, selain itu dilewati.
set -u
root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root" || exit 2

base=${1:-}
if [ -z "$base" ] && git rev-parse --verify -q origin/main >/dev/null 2>&1; then base=origin/main; fi

fail=0
skipped=0
step() { # judul perintah...
  local title=$1 out rc; shift
  echo
  echo "== $title"
  out=$("$@" 2>&1); rc=$?
  printf '%s\n' "$out"
  case "$out" in *DILEWATI*) skipped=1 ;; esac
  [ "$rc" -eq 0 ] || { echo "GAGAL: $title"; fail=1; }
}

step "Tes hook penjaga"          .devcore/hooks/test-hooks.sh
step "Tes skrip pemeriksa"       .devcore/scripts/test-scripts.sh
[ -x scripts/test-sync.sh ] && step "Tes sinkronisasi" scripts/test-sync.sh
step "Penamaan (DC-05)"          .devcore/scripts/check-naming.sh
step "Ukuran analyzer"           .devcore/scripts/check-analyzer-size.sh
step "Tautan dokumen"           .devcore/scripts/check-links.sh
step "Pelemahan pemeriksaan (AG-09)" .devcore/scripts/check-weakened-tests.sh "$base"

echo
if [ "$fail" -eq 0 ]; then echo "SEMUA PEMERIKSAAN LULUS"; else echo "ADA PEMERIKSAAN YANG GAGAL"; fi
[ "$skipped" -eq 1 ] && echo "Catatan: ada pemeriksaan yang DILEWATI (lihat di atas); lulus tidak berarti semuanya dijalankan."
exit "$fail"
