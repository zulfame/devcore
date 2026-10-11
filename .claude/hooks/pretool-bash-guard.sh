#!/usr/bin/env bash
# PreToolUse(Bash): blokir perintah destruktif / akses secret / administrasi OS. Exit 2 = blokir; stderr dikirim ke agent.
# Aturan terkait: AG-06, AG-07, DP-06, OS-01, AG-12, AG-15.
#
# Analisis utama oleh lib/bash-analyzer.py (tokenisasi shell, keputusan dari argv, bukan teks mentah).
# Bila python3 tidak ada atau perintah tidak dapat diparse, dipakai penjaga regex lama di bawah (fallback,
# bukan allow). Ini pagar pengaman, bukan sandbox: lihat docs/enforcement-map.md untuk batasnya.
set -u

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

here=$(cd "$(dirname "$0")" && pwd -P)

block() {
  echo "DIBLOKIR [$1]: $2. Hentikan, jelaskan ke pengguna, dan minta konfirmasi eksplisit di chat. Jangan mencari jalan pintas." >&2
  exit 2
}
ask() { # alasan
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
  exit 0
}

# ---------- fallback: penjaga regex atas teks mentah (perilaku lama) ----------
legacy_guard() {
  set -f
  local lc t
  lc=$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')

  printf '%s' "$lc" | grep -Eq '(^|[;&|(`[:space:]])rm[[:space:]]+(-[a-z]*r|--recursive)' && block AG-06 "rm rekursif"
  printf '%s' "$lc" | grep -Eq 'git[[:space:]]+reset[[:space:]]+--hard' && block AG-06 "git reset --hard"
  printf '%s' "$lc" | grep -Eq 'git[[:space:]]+push[^;&|]*([[:space:]]-f([[:space:]]|$)|--force)' && block AG-06 "git push --force"
  printf '%s' "$lc" | grep -Eq 'git[[:space:]]+clean[[:space:]]+-[a-z]*f' && block AG-06 "git clean -f"
  printf '%s' "$lc" | grep -Eq 'git[[:space:]]+branch[[:space:]]+-d([[:space:]]|$)' && block AG-06 "git branch -D"
  printf '%s' "$lc" | grep -Eq 'git[[:space:]]+(checkout|restore)[[:space:]]+(--[[:space:]]+)?\.([[:space:]]|$)' && block AG-06 "membuang seluruh perubahan lokal"
  printf '%s' "$lc" | grep -Eq '(drop|truncate)[[:space:]]+(table|database|schema)' && block AG-06 "DROP/TRUNCATE"
  printf '%s' "$lc" | grep -Eq '(curl|wget)[^|;&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh' && block DP-06 "mengeksekusi skrip unduhan langsung (curl | sh)"
  printf '%s' "$lc" | grep -Eq '(^|[;&|(`[:space:]])sudo[[:space:]]' && block OS-01 "sudo bukan tugas agent"

  for t in $cmd; do
    t=${t//\"/}; t=${t//\'/}
    case "$t" in
      *.env.example|*.env.sample|*.env.template) continue ;;
      .env|*/.env|.env.*|*/.env.*|*.pem|*.key|*/id_rsa|*/id_ed25519)
        block AG-07 "akses file secret ($t)" ;;
    esac
  done
  exit 0
}

# ---------- analisis utama ----------
analyzer="$here/lib/bash-analyzer.py"
if command -v python3 >/dev/null 2>&1 && [ -f "$analyzer" ]; then
  decision=$(printf '%s' "$input" | python3 -I "$analyzer" 2>/dev/null)
  kind=$(printf '%s' "$decision" | jq -r '.decision // empty' 2>/dev/null)
  case "$kind" in
    allow) exit 0 ;;
    block) block "$(printf '%s' "$decision" | jq -r '.rule')" "$(printf '%s' "$decision" | jq -r '.reason')" ;;
    ask)   ask "$(printf '%s' "$decision" | jq -r '"[" + .rule + "] " + .reason')" ;;
  esac
fi
legacy_guard
