# Changelog

Perubahan penting kerangka devcore. Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/), versi mengikuti [Semantic Versioning](https://semver.org/lang/id/). Latar belakang keputusan: `docs/riwayat.md`.

- **MAJOR**: perubahan yang memaksa proyek mengubah cara kerja atau konfigurasinya.
- **MINOR**: kemampuan atau aturan baru yang kompatibel.
- **PATCH**: perbaikan hook/skrip/dokumen.

Selama `0.x`, kerangka belum teruji di proyek nyata.

## [0.5.0] - dalam pengerjaan
Pemangkasan dan satu jejak. Rinciannya diisi saat batch selesai.
- **Dicabut:** generator aturan inti, pemeriksa rujukan, dan tabel sumber di standar (ringkasan aturan inti kini ditulis langsung di aturan inti); 6 brief lama dan CHANGELOG panjang (dilebur ke `docs/riwayat.md`).

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
