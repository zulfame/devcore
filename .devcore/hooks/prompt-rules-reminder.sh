#!/usr/bin/env bash
# UserPromptSubmit: setiap pesan pengguna, sisipkan pengingat singkat aturan inti ke konteks agent.
# Tujuan: aturan tidak "tenggelam" di konteks panjang atau hilang setelah compaction.
# Teks pengingat TIDAK ditulis di sini: dibaca dari .devcore/reminder.txt (judul aturan kritis di
# .devcore/rules.md, yang menjadi satu-satunya tempat ringkasan aturan inti).
here=$(cd "$(dirname "$0")" && pwd -P)
reminder="$here/../reminder.txt"
[ -f "$reminder" ] || exit 0
cat "$reminder"
exit 0
