#!/usr/bin/env bash
# Stop: ingatkan memperbarui docs/status.md bila kode berubah tetapi status tidak (AG-17).
# Mengingatkan satu kali per upaya berhenti: pada percobaan kedua (stop_hook_active) selalu diizinkan.
set -u

input=$(cat)
root=${CLAUDE_PROJECT_DIR:-$(pwd)}
root=${root%/}

active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)
[ "$active" = "true" ] && exit 0
[ -f "$root/docs/status.md" ] || exit 0
git -C "$root" rev-parse --git-dir >/dev/null 2>&1 || exit 0

changes=$(git -C "$root" status --porcelain 2>/dev/null | cut -c4-)
[ -z "$changes" ] && exit 0

# status.md ikut berubah -> sudah dicatat
printf '%s\n' "$changes" | grep -qx 'docs/status.md' && exit 0

# hanya perubahan kode: abaikan dokumen dan berkas konfigurasi kerangka
code=$(printf '%s\n' "$changes" | grep -vE '^(docs/|\.claude/|\.devcore/|\.github/)|\.md$|\.gitignore$' || true)
[ -z "$code" ] && exit 0

reason="Kode berubah tetapi docs/status.md belum diperbarui (AG-17). Perbarui status singkat: fokus, yang selesai, keputusan, langkah berikutnya. Setelah itu selesaikan jawaban."
jq -n --arg r "$reason" '{decision:"block", reason:$r}'
exit 0
