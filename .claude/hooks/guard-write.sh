#!/usr/bin/env bash
# PreToolUse(Write|Edit|MultiEdit): cegah secret masuk file, edit file secret/lockfile,
# dan perubahan diam-diam pada aturan mesin itu sendiri.
# Aturan terkait: SC-07, AG-07, DP-01, AG-09. Exit 2 = blokir.
set -u

input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -z "$path" ] && exit 0

block() {
  echo "DIBLOKIR [$1]: $2. Jelaskan ke pengguna dan minta konfirmasi eksplisit di chat." >&2
  exit 2
}

base=$(basename "$path")

# 1. File secret asli
case "$base" in
  .env.example|.env.sample|.env.template) ;;
  .env|.env.*|*.pem|*.key|id_rsa|id_ed25519)
    block SC-07 "menulis ke file secret ($base); gunakan .env.example tanpa nilai asli" ;;
esac

# 2. Lockfile tidak diedit manual
case "$base" in
  package-lock.json|yarn.lock|pnpm-lock.yaml|composer.lock|poetry.lock|Pipfile.lock|Cargo.lock|go.sum|Gemfile.lock)
    block DP-01 "lockfile ($base) dihasilkan oleh package manager, bukan diedit manual" ;;
esac

# 3. Aturan mesin tidak boleh diubah agent tanpa persetujuan pengguna (minta konfirmasi, bukan blokir total)
case "$path" in
  */.claude/settings.json|*/.claude/hooks/*)
    jq -n --arg p "$path" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:("Perubahan pada aturan mesin (" + $p + ") butuh persetujuan pengguna. Melonggarkan aturan agar pekerjaan lolos adalah pelanggaran AG-09.")}}'
    exit 0 ;;
esac

# 4. Pindai konten yang akan ditulis untuk pola secret
content=$(printf '%s' "$input" | jq -r '[.tool_input.content, .tool_input.new_string, (.tool_input.edits[]?.new_string)] | map(select(. != null)) | join("\n")')
[ -z "$content" ] && exit 0

hit=$(printf '%s\n' "$content" | grep -Eo \
  -e 'AKIA[0-9A-Z]{16}' \
  -e '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----' \
  -e 'gh[pousr]_[A-Za-z0-9]{36,}' \
  -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
  -e 'sk-[A-Za-z0-9_-]{24,}' \
  -e 'AIza[0-9A-Za-z_-]{35}' | head -1)
[ -n "$hit" ] && block SC-07 "terdeteksi pola kredensial/secret pada konten (${hit:0:8}...)"

# Penugasan literal: password/secret/token/api_key = "nilai"
lit=$(printf '%s\n' "$content" \
  | grep -Ei '(password|passwd|secret|api[_-]?key|access[_-]?token|auth[_-]?token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'$<{ ]{8,}["'"'"']' \
  | grep -Eiv 'example|changeme|placeholder|your[_-]|xxx|dummy|sample|fake|test' | head -1)
[ -n "$lit" ] && block SC-07 "terdeteksi penugasan secret literal; baca dari konfigurasi/lingkungan"

exit 0
