# CLAUDE.md — devcore

@.claude/devcore-rules.md

## Khusus proyek ini
- Berkomunikasi dalam **Bahasa Indonesia**.
- Proyek ini adalah **kerangka devcore itu sendiri**: sumber `docs/`, `.claude/`, dan `scripts/` yang dipasang ke proyek lain lewat `scripts/sync-devcore.sh`. Perubahan di sini memengaruhi semua proyek yang memakainya, jadi perlakukan sebagai produk bersama versi: ubah `VERSION` dan `CHANGELOG.md` saat ada perubahan yang sampai ke proyek lain (MINOR untuk kemampuan baru, PATCH untuk perbaikan).
- Berkas baru di `.claude/hooks/`, `.claude/skills/`, `.claude/agents/`, `scripts/`, atau `docs/templates/` wajib didaftarkan di `.claude/devcore.manifest`, **kecuali** yang khusus devcore; tes `scripts/test-sync.sh` akan gagal bila lupa (daftar pengecualian `devonly` ada di tes itu).
- Berkas khusus devcore yang tidak dipasang ke proyek lain: `README.md`, `CHANGELOG.md`, `VERSION`, `CLAUDE.md`, `CLAUDE.local.md`, `docs/briefs/`, `docs/adr/`, `docs/status.md`, dan skrip `test-sync`.
- **Mengubah aturan inti:** edit ringkasannya langsung di `.claude/devcore-rules.md` (satu-satunya tempat ringkasan; aturan lengkap ber-ID tetap di standar). Bila makna sebuah aturan berubah, ubah juga butir bernomornya di standar dan `.claude/devcore-reminder.txt` bila judulnya berubah. Contoh baru tidak boleh disalin dari skenario uji.
- Tidak ada perangkat otomatis yang mengukur kepatuhan agent (sengaja dicabut: menjalankan agent memakai jatah akun pengguna). Efektivitas aturan diamati dari pemakaian nyata: setiap pelanggaran → perbaiki, sebut aturannya, naikkan penegakannya ke mesin, catat di peta penegakan.
