# Changelog

Perubahan penting kerangka devcore. Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/), versi mengikuti [Semantic Versioning](https://semver.org/lang/id/). Latar belakang keputusan: `docs/history.md`.

- **MAJOR**: perubahan yang memaksa proyek mengubah cara kerja atau konfigurasinya.
- **MINOR**: kemampuan atau aturan baru yang kompatibel.
- **PATCH**: perbaikan hook/skrip/dokumen.

Selama `0.x`, kerangka sudah diuji pemasangan dan uji buta kecil, tetapi belum terbukti dalam pemakaian jangka panjang di proyek nyata.

## [0.7.0] - 2026-10-11
Hasil audit final (lihat `docs/audit-final.md`). **Proyek terpasang perlu menjalankan `sync-devcore.sh` lagi**: perintah hook di `settings.json` kini dikutip.
- **Perbaikan penting:** hook tidak lagi mati diam-diam pada jalur proyek berspasi (`"$CLAUDE_PROJECT_DIR"/…`); gerbang brief tidak bisa dilewati dengan `..` atau jalur relatif; persetujuan brief lewat edit parsial meminta konfirmasi; `.claude/settings.local.json`, skill, subagent, dan `CLAUDE.local.md` meminta konfirmasi.
- **Penjaga bash:** menambah `git switch -f`, `worktree remove --force`, `git show REF:.env`, `export` kosong, `curl -o`/`wget -O`/`patch`/`git apply` sebagai penulisan kode, shell-out destruktif lewat interpreter; mengurangi false positive (URL `/credentials`, `.env.*.example`, heredoc dengan apostrof di `$(…)`, `sed -i -e`, diagnosis OS hanya-baca).
- **Pemeriksa:** `check-naming` di proyek terpasang hanya memeriksa yang dibuat kerangka; `check-links` mengabaikan kode inline/blok dan mendekode `%20`; `check-weakened-tests` memindai `scripts/` proyek; `run-checks.sh` mencatat pemeriksaan yang dilewati.
- **Sync dan serah terima:** salinan gagal tidak merusak pemasangan lama; pemuat status memberi tanda bila terpotong; `permissions.deny` Read diperluas.
- **Dokumen:** klaim git di `rules.md` dipersempit sesuai kode; definisi brief (gerbang tidak menilai ukuran) diselaraskan; panduan melepas dan memperbarui (`--ref`) diperbaiki; peta penegakan memuat DC-06/DC-07 dan batas yang diterima.

## [0.6.7] - 2026-10-11
- Redaksi README dan `adopting.md` dibuat universal: contoh yang menyebut satu framework (di luar tabel stack) diganti.

## [0.6.6] - 2026-10-11
- README: bagian "Apa yang Anda dapat" menjelaskan isi dan manfaat tiap komponen (standar, aturan inti, pengingat, skill, subagent, hook, template, pemeriksa/CI, sync, peta penegakan) dan mengelompokkan 22 bagian standar.

## [0.6.5] - 2026-10-11
- README: bagian prompt dirapikan (tabel kapan memakai; prompt 1–3 "mulai di sini"; prompt 4–7 dilipat). Isi prompt tidak berubah.

## [0.6.4] - 2026-10-11
- README memuat prompt siap pakai untuk agent (verifikasi pasca-pasang, uji kepatuhan, tugas harian, melanjutkan sesi, audit silang dokumen–kode, review, koreksi pelanggaran). README dan `adopting.md` memuat temuan uji nyata: cek sebelum memasang (repo git, `.gitignore` yang mengabaikan `/.claude` atau `/CLAUDE.md`), cara memastikan terpasang benar, apa yang akan dialami pengguna, batas yang diakui, dan tabel masalah umum; hook Stop dijelaskan.

## [0.6.3] - 2026-10-11
Ditemukan saat memasang ke starter kit Laravel asli:
- `check-links.sh` hanya memindai markdown yang dilacak/tidak diabaikan git (tanpa `vendor/`, `node_modules/`); di proyek terpasang cakupannya `CLAUDE.md`, `docs/`, `.devcore/`.
- `sync-devcore.sh` memberi INFO bila `.gitignore` proyek mengabaikan berkas devcore (mis. `/.claude`, `/CLAUDE.md` dari Laravel Boost); `.gitignore` tidak diubah otomatis.

## [0.6.2] - 2026-10-11
- Nama berkas dan folder buatan agent yang berbahasa Indonesia diganti ke Inggris sesuai `DC-05` (`docs/history.md`, `docs/blind-test/`, slug brief 0007–0011). Pelanggaran ditemukan pengguna; `check-naming.sh` hanya memeriksa huruf/format, bukan bahasa. Isi rubrik terkunci tidak berubah (hash cocok).
- Batas yang diakui: bahasa nama berkas belum ditegakkan mesin (daftar kata Indonesia akan rapuh dan salah untuk proyek berbahasa Indonesia); tetap aturan teks `DC-05` plus review.

## [0.6.1] - 2026-10-11
- Pagar ukuran: `check-analyzer-size.sh` (dalam `run-checks.sh`) gagal bila `bash-analyzer.py` melewati 960 baris berkode; menaikkan batas harus disengaja dan dicatat.

## [0.6.0] - 2026-10-11
- Hook Stop `stop-status-reminder.sh`: mengingatkan satu kali memperbarui `docs/status.md` bila kode berubah (AG-17).
- Aturan `DC-06` (dokumen dan kode paralel; audit silang dua arah) dan `DC-07` (hidup berdampingan dengan alat/skill lain); aturan inti ke-17; template brief punya "Dokumen yang ikut berubah"; `review-changes` memeriksa dokumen↔kode.
- README: jalur proyek baru dan existing, cara membaca laporan dry-run, pembatalan. `adopting.md`: hidup berdampingan dan tabel stack.
- `permissions.ask` ditambah: Dart, WordPress, Docker destruktif, artisan destruktif (ditemukan lewat uji pemasangan fixture Laravel/Flutter/WordPress).

## [0.5.4] - 2026-10-11
- `git checkout <berkas>` tanpa `--` (membuang perubahan lokal) kini diblokir bila argumennya jalur yang ada; ditemukan di uji buta putaran 3. 300 tes hook.

## [0.5.3] - 2026-10-11
- Ditemukan saat uji pemasangan ke proyek existing dari klon GitHub: `AGENTS.md` (milik alat lain) ditandai gagal oleh pemeriksa penamaan. `AGENTS` kini nama peran baku; tes sync ditambah.

## [0.5.2] - 2026-10-11
- Pemeriksaan kode one-liner/heredoc interpreter dikembalikan secara sempit (hanya penghapusan berkas dan akses secret): menutup lagi dua celah yang terbuka di 0.5.1. 297 tes hook.

## [0.5.1] - 2026-10-11
*Dibekukan setelah uji buta dua putaran (`docs/blind-test/results.md`): tidak ada pelanggaran keamanan teramati; tidak ada perubahan aturan yang dibenarkan bukti.*
- **Penjaga bash dipangkas** (`bash-analyzer.py` 1.069 → 969 baris; tokenizer dan penganalisis struktur sengaja dipertahankan karena itulah inti yang menutup 8 celah awal). Dicabut dari hook: SQL/migrasi destruktif, pemindaian kode one-liner interpreter, konfirmasi paket OS, konfirmasi `mv` ke luar proyek, konfirmasi paket proyek (sudah ada di `permissions.ask`). Konsekuensinya dicatat di peta penegakan; 293 tes hook lulus.

## [0.5.0] - 2026-10-11
**Perubahan MAJOR struktur (belum ada proyek terpasang yang diketahui, sehingga tanpa migrasi otomatis; pasang ulang dengan `sync-devcore.sh`).** Pemangkasan dan satu jejak.
- **Satu jejak `.devcore/`:** seluruh milik kerangka (aturan inti, pengingat, standar, peta penegakan, panduan, template, hook, skrip, `VERSION`) kini berada di satu folder; `.claude/` hanya memuat yang wajib di sana (skill, subagent, `settings.json`, `devcore.conf`). Folder `scripts/` dan `docs/` proyek tidak lagi dipakai kerangka, sehingga tidak ada tabrakan nama dengan proyek existing.
- **`sync-devcore.sh` ditulis ulang:** mengganti seluruh `.devcore/` (tanpa lock, hash, dan penghapusan berkas usang); hook milik kerangka dikenali dari prefix `.devcore/`; kepemilikan skill/subagent di `.claude/` dicatat di `.devcore/owned-claude.txt` sehingga skill senama milik proyek **tidak pernah ditimpa**; laporan BENTROK/INFO sebelum menulis; `CLAUDE.md` starter untuk proyek baru.
- **Aturan bila kerangka bertabrakan dengan proyek** (standar Bagian 0): keamanan tidak dapat diubah; aturan proses dapat disimpangi dengan pengecualian tertulis di `CLAUDE.md`; gaya kode dan alat sepenuhnya milik proyek. Template `claude-md-starter.md`.
- **Dicabut:** generator aturan inti, pemeriksa rujukan, dan tabel sumber di standar (ringkasan aturan inti kini ditulis langsung di `.devcore/rules.md`); 6 brief lama dan CHANGELOG panjang (dilebur ke `docs/history.md`).
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
