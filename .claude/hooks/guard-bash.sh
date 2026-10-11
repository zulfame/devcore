#!/usr/bin/env bash
# PreToolUse(Bash): blokir perintah destruktif / berisiko. Exit 2 = blokir; stderr dikirim ke agent.
# Aturan terkait: AG-06, AG-07, DP-06. Ini guardrail, bukan sandbox.
set -u
set -f

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

block() {
  echo "DIBLOKIR [$1]: $2. Hentikan, jelaskan ke pengguna, dan minta konfirmasi eksplisit di chat. Jangan mencari jalan pintas." >&2
  exit 2
}

lc=$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')

printf '%s' "$lc" | grep -Eq '(^|[;&|(`[:space:]])rm[[:space:]]+(-[a-z]*r|--recursive)' \
  && block AG-06 "rm rekursif"
printf '%s' "$lc" | grep -Eq 'git[[:space:]]+reset[[:space:]]+--hard' \
  && block AG-06 "git reset --hard"
printf '%s' "$lc" | grep -Eq 'git[[:space:]]+push[^;&|]*([[:space:]]-f([[:space:]]|$)|--force)' \
  && block AG-06 "git push --force"
printf '%s' "$lc" | grep -Eq 'git[[:space:]]+clean[[:space:]]+-[a-z]*f' \
  && block AG-06 "git clean -f"
printf '%s' "$lc" | grep -Eq 'git[[:space:]]+branch[[:space:]]+-d([[:space:]]|$)' \
  && block AG-06 "git branch -D"
printf '%s' "$lc" | grep -Eq 'git[[:space:]]+(checkout|restore)[[:space:]]+(--[[:space:]]+)?\.([[:space:]]|$)' \
  && block AG-06 "membuang seluruh perubahan lokal"
printf '%s' "$lc" | grep -Eq '(drop|truncate)[[:space:]]+(table|database|schema)' \
  && block AG-06 "DROP/TRUNCATE"
printf '%s' "$lc" | grep -Eq '(curl|wget)[^|;&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh' \
  && block DP-06 "mengeksekusi skrip unduhan langsung (curl | sh)"

# Akses file secret lewat shell (.env asli; .env.example/sample/template diizinkan)
for t in $cmd; do
  t=${t//\"/}; t=${t//\'/}
  case "$t" in
    *.env.example|*.env.sample|*.env.template) continue ;;
    .env|*/.env|.env.*|*/.env.*|*.pem|*.key|*/id_rsa|*/id_ed25519)
      block AG-07 "akses file secret ($t)" ;;
  esac
done

exit 0
