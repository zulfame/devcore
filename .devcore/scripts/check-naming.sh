#!/usr/bin/env bash
# Periksa penamaan sesuai DC-05.
#   Repo devcore sendiri (ada scripts/test-sync.sh): dokumen *.md di root, docs/, dan .devcore/docs/.
#   Proyek terpasang: hanya yang dibuat kerangka (docs/briefs/, docs/adr/, .devcore/docs/); dokumen lama proyek
#   tidak diperiksa agar adopsi tidak gagal di CI sejak hari pertama (AG-16: baseline, bukan refactor).
#   - hook, pustaka hook, dan skrip di .devcore/
#   - skill dan subagent MILIK KERANGKA (daftar di .devcore/managed-claude.txt); skill/subagent proyek tidak diperiksa
# Folder kode dan skrip milik proyek (src/, scripts/, ...) sengaja tidak diperiksa.
# Pakai: .devcore/scripts/check-naming.sh [root]
set -u
root=${1:-$(cd "$(dirname "$0")/../.." && pwd)}
cd "$root" || { echo "root tidak ditemukan: $root"; exit 2; }
fail=0
bad() { echo "PENAMAAN: $1 -> $2"; fail=1; }

is_kebab() { printf '%s' "$1" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; }
is_verb_object() { printf '%s' "$1" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)+$'; }
role_names=" README CLAUDE AGENTS CHANGELOG SECURITY CONTRIBUTING LICENSE CODE_OF_CONDUCT ARCHITECTURE TESTING DEPLOYMENT "
is_role() { case "$role_names" in *" $1 "*) return 0 ;; esac; return 1; }
name_of() { grep -m1 '^name:' "$1" | sed -e 's/^name:[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# 1. Dokumen markdown
strict=0; [ -f scripts/test-sync.sh ] && strict=1
list_docs() {
  if [ "$strict" -eq 1 ]; then
    find . -maxdepth 1 -type f -name '*.md'
    for d in docs .devcore/docs; do [ -d "$d" ] && find "$d" -type f -name '*.md'; done
  else
    for d in docs/briefs docs/adr .devcore/docs; do [ -d "$d" ] && find "$d" -type f -name '*.md'; done
  fi
}
while IFS= read -r f; do
  rel=${f#./}; file=$(basename "$rel"); base=${file%.md}
  case "$file" in README.md|CLAUDE.local.md) continue ;; esac
  case "$rel" in
    docs/adr/*|docs/briefs/*)
      printf '%s' "$file" | grep -Eq '^[0-9]{4}-[a-z0-9]+(-[a-z0-9]+)*\.md$' \
        || bad "$rel" "harus NNNN-judul-singkat.md (4 digit, kebab-case huruf kecil)" ;;
    *) is_kebab "$base" || is_role "$base" \
        || bad "$rel" "harus kebab-case huruf kecil, atau nama peran baku HURUF_BESAR" ;;
  esac
done < <(list_docs | sort)

# 2. Folder di dalam docs/ dan .devcore/docs/
folder_bases=".devcore/docs"; [ "$strict" -eq 1 ] && folder_bases="docs .devcore/docs"
for base in $folder_bases; do
  [ -d "$base" ] || continue
  while IFS= read -r d; do
    [ "$d" = "$base" ] && continue
    is_kebab "$(basename "$d")" || bad "$d/" "nama folder harus kebab-case huruf kecil"
  done < <(find "$base" -type d | sort)
done

# 3. Skill dan subagent milik kerangka
owned=.devcore/owned-claude.txt; [ -f "$owned" ] || owned=.devcore/managed-claude.txt   # proyek: yang benar-benar dipasang; sumber: daftar lengkap
if [ -f "$owned" ]; then
  while IFS= read -r p; do
    case "$p" in ""|"#"*) continue ;; esac
    if [ -d "$p" ]; then
      n=$(basename "$p")
      is_verb_object "$n" || bad "$p" "skill harus kebab-case kata-kerja-objek (minimal dua kata)"
      if [ -f "$p/SKILL.md" ]; then
        [ "$(name_of "$p/SKILL.md")" = "$n" ] || bad "$p/SKILL.md" "name tidak sama dengan nama folder '$n'"
      else bad "$p" "tidak ada SKILL.md"; fi
    elif [ -f "$p" ]; then
      n=$(basename "$p" .md)
      is_verb_object "$n" || bad "$p" "subagent harus kebab-case kata-kerja-objek (minimal dua kata)"
      [ "$(name_of "$p")" = "$n" ] || bad "$p" "name tidak sama dengan nama berkas '$n'"
    fi
  done < "$owned"
fi

# 4. Hook (event-tujuan.sh atau test-*.sh), pustaka hook, dan skrip
for f in .devcore/hooks/*; do
  [ -f "$f" ] || continue
  printf '%s' "$(basename "$f")" | grep -Eq '^(pretool|posttool|prompt|session|stop)-[a-z0-9]+(-[a-z0-9]+)*\.sh$|^test-[a-z0-9]+(-[a-z0-9]+)*\.sh$' \
    || bad "$f" "hook harus event-tujuan.sh (event: pretool|posttool|prompt|session|stop) atau test-*.sh"
done
for f in .devcore/hooks/lib/*; do
  [ -f "$f" ] || continue
  printf '%s' "$(basename "$f")" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*\.(py|txt|tsv|sh)$' \
    || bad "$f" "berkas pustaka hook harus kebab-case huruf kecil (.py/.txt/.tsv/.sh)"
done
for f in .devcore/scripts/*; do
  [ -f "$f" ] || continue
  printf '%s' "$(basename "$f")" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*\.sh$' \
    || bad "$f" "skrip harus kebab-case huruf kecil berakhiran .sh"
done

[ "$fail" -eq 0 ] && echo "Penamaan: OK"
exit "$fail"
