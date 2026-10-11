# CLAUDE.md — devcore

@.devcore/rules.md

## Khusus proyek ini
- Berkomunikasi dalam **Bahasa Indonesia**.
- Proyek ini adalah **kerangka devcore itu sendiri**. Yang dipasang ke proyek lain: folder `.devcore/` (seluruhnya) dan skill/subagent di `.claude/` yang tercatat di `.devcore/managed-claude.txt`. Berkas baru di `.claude/skills/` atau `.claude/agents/` wajib didaftarkan di daftar itu (tes `scripts/test-sync.sh` akan gagal bila lupa).
- Khusus devcore, tidak dipasang: `README.md`, `CHANGELOG.md`, `CLAUDE.md`, `CLAUDE.local.md`, `docs/` (history, adr, briefs, status) dan `scripts/test-sync.sh`.
- Perubahan yang sampai ke proyek lain: naikkan `.devcore/VERSION` dan catat di `CHANGELOG.md` (MINOR kemampuan baru, PATCH perbaikan, MAJOR bila proyek harus mengubah cara kerjanya).
- Ringkasan aturan inti hanya ditulis di `.devcore/rules.md`. Bila makna sebuah aturan berubah, ubah juga butir bernomornya di `.devcore/docs/engineering-standard.md` dan judulnya di `.devcore/reminder.txt`.
- Tidak ada perangkat otomatis yang mengukur kepatuhan agent (sengaja dicabut). Efektivitas aturan diamati dari pemakaian nyata: setiap pelanggaran → perbaiki, sebut aturannya, naikkan penegakannya ke mesin, catat di peta penegakan.
- **Alur branch:** `main` hanya berisi yang sudah lolos. Pekerjaan dan pengujian lokal dilakukan di branch `kerja/<topik>`; merge ke `main` hanya setelah `run-checks.sh` lokal dan CI di branch hijau. Folder uji berada di luar repo.
- **Anti-melebar:** setelah pemangkasan, tidak ada mekanisme baru tanpa pelanggaran nyata yang teramati. Ide baru dicatat di bagian Backlog `docs/status.md`, tidak langsung dibangun.
