#!/usr/bin/env bash
# Periksa penamaan file/folder sesuai DC-05 pada area yang dikelola kerangka:
# dokumen *.md di root dan docs/, .claude/skills, .claude/hooks, scripts/.
# Folder kode proyek (src/, app/, dst.) sengaja tidak diperiksa.
# Pakai: scripts/check-naming.sh [root]
set -u
root=${1:-$(cd "$(dirname "$0")/.." && pwd)}
cd "$root" || { echo "root tidak ditemukan: $root"; exit 2; }
fail=0
bad() { echo "PENAMAAN: $1 -> $2"; fail=1; }

is_kebab() { printf '%s' "$1" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; }
role_names=" README CLAUDE CHANGELOG SECURITY CONTRIBUTING LICENSE CODE_OF_CONDUCT ARCHITECTURE TESTING DEPLOYMENT "
is_role() { case "$role_names" in *" $1 "*) return 0 ;; esac; return 1; }

# 1. Dokumen markdown di root dan docs/
list_docs() {
  find . -maxdepth 1 -type f -name '*.md'
  [ -d docs ] && find docs -type f -name '*.md'
}
while IFS= read -r f; do
  rel=${f#./}; file=$(basename "$rel"); base=${file%.md}
  [ "$rel" = "CLAUDE.local.md" ] && continue
  [ "$file" = "README.md" ] && continue
  case "$rel" in
    docs/adr/*|docs/briefs/*)
      printf '%s' "$file" | grep -Eq '^[0-9]{4}-[a-z0-9]+(-[a-z0-9]+)*\.md$' \
        || bad "$rel" "harus NNNN-judul-singkat.md (4 digit, kebab-case huruf kecil)" ;;
    *)
      is_kebab "$base" || is_role "$base" \
        || bad "$rel" "harus kebab-case huruf kecil, atau nama peran baku HURUF_BESAR" ;;
  esac
done < <(list_docs | sort)

# 2. Folder di dalam docs/
if [ -d docs ]; then
  while IFS= read -r d; do
    [ "$d" = "docs" ] && continue
    is_kebab "$(basename "$d")" || bad "$d/" "nama folder harus kebab-case huruf kecil"
  done < <(find docs -type d | sort)
fi

# 3. Skill: folder kata-kerja-objek + SKILL.md dengan name sama dengan folder
if [ -d .claude/skills ]; then
  for d in .claude/skills/*/; do
    [ -d "$d" ] || continue
    n=$(basename "$d")
    printf '%s' "$n" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)+$' \
      || bad "$d" "skill harus kebab-case kata-kerja-objek (minimal dua kata)"
    if [ ! -f "${d}SKILL.md" ]; then
      bad "$d" "tidak ada SKILL.md"
    else
      fn=$(grep -m1 '^name:' "${d}SKILL.md" | sed -e 's/^name:[[:space:]]*//' -e 's/[[:space:]]*$//')
      [ "$fn" = "$n" ] || bad "${d}SKILL.md" "name '$fn' tidak sama dengan nama folder '$n'"
    fi
  done
fi

# 4. Hook: event-tujuan.sh atau test-*.sh
if [ -d .claude/hooks ]; then
  for f in .claude/hooks/*; do
    [ -f "$f" ] || continue
    b=$(basename "$f")
    printf '%s' "$b" | grep -Eq '^(pretool|posttool|prompt|session|stop)-[a-z0-9]+(-[a-z0-9]+)*\.sh$|^test-[a-z0-9]+(-[a-z0-9]+)*\.sh$' \
      || bad "$f" "hook harus event-tujuan.sh (event: pretool|posttool|prompt|session|stop) atau test-*.sh"
  done
fi

# 5. Skrip pendukung
if [ -d scripts ]; then
  for f in scripts/*; do
    [ -f "$f" ] || continue
    printf '%s' "$(basename "$f")" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*\.sh$' \
      || bad "$f" "skrip harus kebab-case huruf kecil berakhiran .sh"
  done
fi

[ "$fail" -eq 0 ] && echo "Penamaan: OK"
exit "$fail"
