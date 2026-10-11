#!/usr/bin/env bash
# Periksa bahwa tautan relatif pada dokumen markdown menunjuk ke berkas/folder yang ada.
# Tautan http(s), mailto, dan anchor murni dilewati; teks di dalam `kode inline` dan blok ``` tidak dianggap tautan.
# Pakai: .devcore/scripts/check-links.sh [root]
set -u
root=${1:-$(cd "$(dirname "$0")/../.." && pwd)}
cd "$root" || { echo "root tidak ditemukan: $root"; exit 2; }
fail=0

# Daftar markdown yang diperiksa. Di repo git: hanya berkas yang dilacak atau tidak diabaikan (vendor/ dan
# node_modules/ otomatis keluar). Di proyek terpasang (bukan repo devcore) cakupan dibatasi ke CLAUDE.md,
# docs/, dan .devcore/ agar dokumen lama proyek tidak membuat pemeriksaan gagal (AG-16).
list_md() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    if [ -f scripts/test-sync.sh ]; then
      git ls-files -co --exclude-standard -- '*.md'
    else
      git ls-files -co --exclude-standard -- 'CLAUDE.md' 'docs/*.md' 'docs/**/*.md' '.devcore/*.md' '.devcore/**/*.md'
    fi
  else
    find . -type f -name '*.md' -not -path './.git/*' -not -path './node_modules/*' -not -path './vendor/*'
  fi | sed 's#^\./##; s#^#./#' | sort -u
}

while IFS= read -r f; do
  dir=$(dirname "$f")
  while IFS= read -r link; do
    target=${link%%#*}
    target=${target%% *}
    case "$target" in ""|http://*|https://*|mailto:*|tel:*) continue ;; esac
    target=${target//%20/ }
    case "$target" in /*) path="$root$target" ;; *) path="$dir/$target" ;; esac
    if [ ! -e "$path" ]; then
      echo "TAUTAN RUSAK: ${f#./} -> $link"
      fail=1
    fi
  done < <(awk '/^```/{c=!c; next} !c' "$f" | sed -e 's/`[^`]*`//g' | grep -oE '\]\([^)]+\)' | sed -e 's/^\](//' -e 's/)$//')
done < <(list_md)

[ "$fail" -eq 0 ] && echo "Tautan: OK"
exit "$fail"
