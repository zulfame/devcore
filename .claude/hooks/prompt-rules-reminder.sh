#!/usr/bin/env bash
# UserPromptSubmit: setiap pesan pengguna, sisipkan pengingat singkat aturan inti ke konteks agent.
# Tujuan: aturan tidak "tenggelam" di konteks panjang atau hilang setelah compaction.
# Teks pengingat TIDAK ditulis di sini: dibaca dari .claude/devcore-reminder.txt, yang dibangun oleh
# scripts/build-rules.sh dari tabel "Aturan Inti untuk Agent" di docs/engineering-standard.md (sumber tunggal).
here=$(cd "$(dirname "$0")" && pwd -P)
reminder="$here/../devcore-reminder.txt"
[ -f "$reminder" ] || exit 0
cat "$reminder"
exit 0
