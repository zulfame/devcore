#!/usr/bin/env bash
# Periksa bahwa tautan relatif pada dokumen markdown menunjuk ke berkas/folder yang ada.
# Tautan http(s), mailto, dan anchor murni dilewati.
# Pakai: scripts/check-links.sh [root]
set -u
root=${1:-$(cd "$(dirname "$0")/.." && pwd)}
cd "$root" || { echo "root tidak ditemukan: $root"; exit 2; }
fail=0

while IFS= read -r f; do
  dir=$(dirname "$f")
  while IFS= read -r link; do
    target=${link%%#*}
    target=${target%% *}
    case "$target" in ""|http://*|https://*|mailto:*|tel:*) continue ;; esac
    case "$target" in /*) path="$root$target" ;; *) path="$dir/$target" ;; esac
    if [ ! -e "$path" ]; then
      echo "TAUTAN RUSAK: ${f#./} -> $link"
      fail=1
    fi
  done < <(grep -oE '\]\([^)]+\)' "$f" | sed -e 's/^\](//' -e 's/)$//')
done < <(find . -type f -name '*.md' -not -path './.git/*' -not -path './node_modules/*' | sort)

[ "$fail" -eq 0 ] && echo "Tautan: OK"
exit "$fail"
