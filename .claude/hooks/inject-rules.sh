#!/usr/bin/env bash
# UserPromptSubmit: setiap pesan pengguna, sisipkan pengingat singkat aturan inti ke konteks agent.
# Tujuan: aturan tidak "tenggelam" di konteks panjang atau hilang setelah compaction.
cat <<'EOF'
[Pengingat aturan proyek — docs/standards, CLAUDE.md]
- Baca dulu sebelum ubah (AG-01); ikuti konvensi yang ada (AG-02); jangan ubah di luar permintaan (AG-05).
- Tambah/ubah/hapus fungsi atau kontrak → jalankan skill `change-function` sebelum mulai.
- Jangan klaim selesai tanpa verifikasi nyata → skill `verify-done` (AG-08). Jangan lemahkan test/lint (AG-09).
- Dilarang: tindakan destruktif tanpa konfirmasi (AG-06), secret di kode (AG-07), dependency baru tanpa izin (AG-12), force push.
- Jika dikoreksi karena melanggar aturan: perbaiki, lalu usulkan penegakan mesin (hook/izin/tes), bukan sekadar minta maaf.
EOF
exit 0
