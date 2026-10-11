#!/usr/bin/env bash
# PreToolUse(Write|Edit|MultiEdit): cegah secret masuk file, edit file secret/lockfile,
# dan perubahan diam-diam pada aturan mesin itu sendiri.
# Juga dipanggil oleh lib/bash-analyzer.py untuk penulisan berkas lewat shell (satu sumber kebijakan).
# Aturan terkait: SC-07, AG-07, DP-01, AG-09, AG-15. Exit 2 = blokir.
set -u

input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -z "$path" ] && exit 0

here=$(cd "$(dirname "$0")" && pwd -P)
patterns="$here/lib/secret-patterns.txt"

block() {
  echo "DIBLOKIR [$1]: $2. Jelaskan ke pengguna dan minta konfirmasi eksplisit di chat." >&2
  exit 2
}
ask() { # alasan
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
  exit 0
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
  */.claude/settings.json|*/.claude/devcore.conf|*/.devcore/*)
    ask "Perubahan pada aturan mesin ($path) butuh persetujuan pengguna. Melonggarkan aturan agar pekerjaan lolos adalah pelanggaran AG-09." ;;
esac

# 4. Pindai konten yang akan ditulis
content=$(printf '%s' "$input" | jq -r '[.tool_input.content, .tool_input.new_string, .tool_input.new_source, (.tool_input.edits[]?.new_string)] | map(select(. != null)) | join("\n")')
[ -z "$content" ] && exit 0

# 4a. Persetujuan brief (AG-15) adalah keputusan pengguna: menulis "Status: approved" meminta konfirmasi
case "$path" in
  */docs/briefs/*.md)
    if printf '%s\n' "$content" | grep -iqE '^Status:[[:space:]]*approved[[:space:]]*$'; then
      ask "Brief diubah menjadi approved. Setujui hanya jika Anda memang menyetujui isi brief ini (AG-15)."
    fi ;;
esac

# 4b. Pola secret (dari berkas data bersama)
if [ ! -f "$patterns" ]; then
  ask "Berkas pola secret tidak ditemukan ($patterns); konten tidak dapat dipindai. Pasang ulang kerangka dengan sync-devcore.sh."
fi

hit=$(printf '%s\n' "$content" | grep -Eo -f <(awk -F'\t' '$1=="strong"{print $2}' "$patterns") | head -1)
[ -n "$hit" ] && block SC-07 "terdeteksi pola kredensial/secret pada konten (${hit:0:8}...)"

assign=$(awk -F'\t' '$1=="assign"{print $2; exit}' "$patterns")
placeholder=$(awk -F'\t' '$1=="placeholder"{print $2; exit}' "$patterns")
if [ -n "$assign" ]; then
  lit=$(printf '%s\n' "$content" | grep -Ei -e "$assign" | grep -Eiv -e "${placeholder:-ZZZ_TIDAK_ADA}" | head -1)
  if [ -n "$lit" ]; then
    # Berkas uji/fixture sering memuat nilai palsu: minta konfirmasi alih-alih memblokir
    test_re='(^|/)(tests?|__tests__|specs?|fixtures?|testdata|evals?|e2e)/|[._]test\.[A-Za-z]+$|[._]spec\.[A-Za-z]+$|(^|/)test_[^/]+$'
    if [[ "$path" =~ $test_re ]]; then
      ask "Nilai pada berkas uji/fixture terlihat seperti secret (SC-07). Setujui hanya jika nilainya palsu; secret asli tidak boleh ada di repositori."
    fi
    block SC-07 "terdeteksi penugasan secret literal; baca dari konfigurasi/lingkungan"
  fi
fi

exit 0
