#!/usr/bin/env bash
# SessionStart: muat serah terima sesi ke konteks agent (AG-17).
# Isi: awal docs/status.md + daftar brief berstatus approved yang belum ditutup.
# Stdout hook SessionStart masuk ke konteks; keluaran dibatasi agar jauh di bawah 10.000 karakter.
set -u

root=${CLAUDE_PROJECT_DIR:-$(pwd)}
root=${root%/}

status_text=""
if [ -f "$root/docs/status.md" ]; then
  if grep -q '<YYYY-MM-DD>' "$root/docs/status.md"; then
    status_text="docs/status.md masih berisi templat kosong. Isi setelah tugas pertama selesai (AG-17)."
  else
    status_text=$(head -n 40 "$root/docs/status.md" | cut -c1-200)
    # beri tahu bila ada yang terpotong (lebih dari 40 baris, atau baris lebih dari 200 karakter)
    if [ "$(wc -l < "$root/docs/status.md" | tr -d ' ')" -gt 40 ] || head -n 40 "$root/docs/status.md" | awk 'length($0) > 200 {f=1} END {exit !f}'; then
      status_text="$status_text"$'\n'"[docs/status.md dipotong saat dimuat (maks. 40 baris, 200 karakter per baris); baca berkasnya utuh bila perlu, dan singkatkan agar seluruhnya termuat.]"
    fi
  fi
fi

active=""
n=0
for f in "$root"/docs/briefs/*.md; do
  [ -f "$f" ] || continue
  if grep -iqE '^Status:[[:space:]]*approved[[:space:]]*$' "$f"; then
    n=$((n+1))
    [ "$n" -le 10 ] && active="${active}- docs/briefs/$(basename "$f")"$'\n'
  fi
done

[ -z "$status_text" ] && [ -z "$active" ] && exit 0

echo "[devcore] Serah terima sesi (AG-17) — konteks dari sesi sebelumnya"
[ -n "$status_text" ] && printf '%s\n' "$status_text"
if [ -n "$active" ]; then
  echo
  echo "Brief berstatus approved (belum ditutup):"
  printf '%s' "$active"
  echo "Tutup (Status: done) bila sudah selesai agar gerbang tidak terbuka untuk tugas lain."
fi
echo
echo "Perbarui docs/status.md di akhir tugas atau sesi."
exit 0
