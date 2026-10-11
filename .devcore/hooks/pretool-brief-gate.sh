#!/usr/bin/env bash
# PreToolUse(Write|Edit|MultiEdit): file kode hanya boleh diubah bila ada brief tugas berstatus approved
# dengan bagian Tujuan, Kriteria penerimaan, dan Di luar ruang lingkup terisi. Aturan: AG-15.
# Mode di .claude/devcore.conf -> BRIEF_GATE=block (bawaan) | ask | off. Exit 2 = blokir.
set -u

input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -z "$path" ] && exit 0

root=${CLAUDE_PROJECT_DIR:-$(pwd)}
root=${root%/}

# Normalisasi jalur (buang ./ dan ../, jalur relatif dihitung dari cwd) agar pengecualian tidak bisa dilewati
norm() { # jalur basis
  local p=$1 res="" seg old=$IFS
  case "$p" in /*) ;; *) p="$2/$p" ;; esac
  IFS=/; set -f
  for seg in $p; do
    case "$seg" in ''|.) ;; ..) res=${res%/*} ;; *) res="$res/$seg" ;; esac
  done
  set +f; IFS=$old
  printf '%s' "${res:-/}"
}
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
path=$(norm "$path" "${cwd:-$root}")

mode=block
conf="$root/.claude/devcore.conf"
if [ -f "$conf" ]; then
  m=$(grep -E '^BRIEF_GATE=' "$conf" | tail -1 | cut -d= -f2 | tr -d '[:space:]')
  [ -n "$m" ] && mode=$m
fi
case "$mode" in off) exit 0 ;; block|ask) ;; *) mode=block ;; esac

# Di luar proyek -> bukan urusan gerbang
case "$path" in "$root"/*) rel=${path#"$root"/} ;; *) exit 0 ;; esac

# Dikecualikan: dokumen, konfigurasi agent, berkas lokal
case "$rel" in
  docs/*|.claude/*|.devcore/*|*.md|.gitignore|LICENSE) exit 0 ;;
esac

# Bagian brief terisi = ada baris selain kosong / placeholder <...>
section_filled() { # file heading
  awk -v h="$2" '
    /^## / { insec = (index($0, "## " h) == 1); next }
    insec && $0 !~ /^[[:space:]]*$/ \
          && $0 !~ /^[[:space:]]*([-*][[:space:]]+)?(\[[ xX]\][[:space:]]+)?<[^>]*>[[:space:]]*$/ { found = 1 }
    END { exit !found }' "$1"
}

ok=0
for f in "$root"/docs/briefs/*.md; do
  [ -f "$f" ] || continue
  grep -iqE '^Status:[[:space:]]*approved[[:space:]]*$' "$f" || continue
  section_filled "$f" "Tujuan" || continue
  section_filled "$f" "Kriteria penerimaan" || continue
  section_filled "$f" "Di luar ruang lingkup" || continue
  ok=1; break
done
[ "$ok" -eq 1 ] && exit 0

msg="Belum ada brief tugas berstatus 'approved' di docs/briefs/ dengan bagian Tujuan, Kriteria penerimaan, dan Di luar ruang lingkup terisi (AG-15). Jalankan skill write-brief, minta persetujuan pengguna di chat, lalu lanjutkan. Tugas kecil cukup brief ringkas."

if [ "$mode" = ask ]; then
  jq -n --arg m "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$m}}'
  exit 0
fi
echo "DIBLOKIR [AG-15]: $msg" >&2
exit 2
