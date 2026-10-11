# Changelog

Perubahan penting kerangka devcore. Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/), versi mengikuti [Semantic Versioning](https://semver.org/lang/id/). Latar belakang keputusan: `docs/riwayat.md`.

- **MAJOR**: perubahan yang memaksa proyek mengubah cara kerja atau konfigurasinya.
- **MINOR**: kemampuan atau aturan baru yang kompatibel.
- **PATCH**: perbaikan hook/skrip/dokumen.

Selama `0.x`, kerangka belum teruji di proyek nyata.

## [0.5.1] - 2026-10-11
- **Penjaga bash dipangkas** (`bash-analyzer.py` 1.069 → 969 baris; tokenizer dan penganalisis struktur sengaja dipertahankan karena itulah inti yang menutup 8 celah awal). Dicabut dari hook: SQL/migrasi destruktif, pemindaian kode one-liner interpreter, konfirmasi paket OS, konfirmasi `mv` ke luar proyek, konfirmasi paket proyek (sudah ada di `permissions.ask`). Konsekuensinya dicatat di peta penegakan; 293 tes hook lulus.

## [0.5.0] - 2026-10-11
**Perubahan MAJOR struktur (belum ada proyek terpasang yang diketahui, sehingga tanpa migrasi otomatis; pasang ulang dengan `sync-devcore.sh`).** Pemangkasan dan satu jejak.
- **Satu jejak `.devcore/`:** seluruh milik kerangka (aturan inti, pengingat, standar, peta penegakan, panduan, template, hook, skrip, `VERSION`) kini berada di satu folder; `.claude/` hanya memuat yang wajib di sana (skill, subagent, `settings.json`, `devcore.conf`). Folder `scripts/` dan `docs/` proyek tidak lagi dipakai kerangka, sehingga tidak ada tabrakan nama dengan proyek existing.
- **`sync-devcore.sh` ditulis ulang:** mengganti seluruh `.devcore/` (tanpa lock, hash, dan penghapusan berkas usang); hook milik kerangka dikenali dari prefix `.devcore/`; kepemilikan skill/subagent di `.claude/` dicatat di `.devcore/owned-claude.txt` sehingga skill senama milik proyek **tidak pernah ditimpa**; laporan BENTROK/INFO sebelum menulis; `CLAUDE.md` starter untuk proyek baru.
- **Aturan bila kerangka bertabrakan dengan proyek** (standar Bagian 0): keamanan tidak dapat diubah; aturan proses dapat disimpangi dengan pengecualian tertulis di `CLAUDE.md`; gaya kode dan alat sepenuhnya milik proyek. Template `claude-md-starter.md`.
- **Dicabut:** generator aturan inti, pemeriksa rujukan, dan tabel sumber di standar (ringkasan aturan inti kini ditulis langsung di `.devcore/rules.md`); 6 brief lama dan CHANGELOG panjang (dilebur ke `docs/riwayat.md`).
- Bug yang ditemukan tes dan diperbaiki sebelum rilis: daftar sumber yang disalin ke proyek membuat skill senama milik proyek tertimpa pada pemasangan kedua.

## [0.4.1] - 2026-10-11
- **Dicabut:** perangkat evaluasi kepatuhan agent (`evals/`, 5 skrip, dokumennya), karena menjalankannya memakai jatah akun dan di luar inti proyek. Efektivitas aturan tidak diukur otomatis.

## [0.4.0] - 2026-10-11
- Contoh salah→benar pada 8 aturan kritis dan pada skill `write-brief`, `verify-done`, `change-function`, `check-security`, `profile-project`.
- Definition of Done punya satu rumah (skill `verify-done`); aturan inti naik jadi 16 (`AG-14` ditambahkan).
- (Generator aturan inti dan pemeriksa rujukan ditambahkan di versi ini; dicabut di 0.5.0.)

## [0.3.0] - 2026-10-11
- **Penjaga bash ditulis ulang:** analisis struktur perintah (kutip, operator, `$(…)`, heredoc, pembungkus `bash -c`/`eval`/`xargs`/`find -exec`) dengan keputusan dari argumen, bukan teks mentah. Menutup 8 celah bypass; teks `rm -rf` di pesan commit/heredoc/grep tidak lagi memblokir.
- Penulisan berkas lewat shell mengikuti kebijakan Write/Edit (gerbang brief, secret, lockfile, aturan mesin → ask). `NotebookEdit` ikut dijaga.
- Aturan baru terblokir: `sudo`/administrasi OS (OS-01), dump environment, riwayat git, `curl | sh`, nama perintah dinamis (ask). Fallback ke penjaga regex bila `python3` tidak ada.
- `sync-devcore.sh` memindahkan hook dari grup bermatcher lama agar tidak terpasang dua kali.
- Prasyarat: `python3` 3.6+ disarankan.

## [0.2.0] - 2026-10-11
- Subagent `review-changes` (peninjau independen, `AG-19`); `verify-done` memanggilnya untuk tugas non-trivial.
- (Perangkat evaluasi ditambahkan di versi ini; dicabut di 0.4.1.)

## [0.1.0] - 2026-10-11
Rilis terversi pertama.
- Standar rekayasa untuk agent (aturan ber-ID, hanya cakupan proyek; hal OS/server dicatat sebagai prasyarat lingkungan).
- Penegakan berlapis: hook penjaga (bash, tulis, gerbang brief, pengingat, serah terima sesi), skill (`write-brief`, `change-function`, `verify-done`, `check-security`, `profile-project`), template, izin per proyek lewat `CLAUDE.local.md`.
- Gerbang brief tugas (`AG-15`), pemeriksa CI (penamaan, tautan, pelemahan test), `sync-devcore.sh` untuk memasang/memperbarui di proyek lain, panduan adopsi proyek lama.
