# Changelog

Semua perubahan penting pada kerangka devcore dicatat di sini. Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/) dan versi mengikuti [Semantic Versioning](https://semver.org/lang/id/).

Arti versi untuk kerangka ini:
- **MAJOR**: perubahan yang memaksa proyek mengubah cara kerja atau konfigurasinya (aturan dihapus/diubah artinya, struktur berkas berubah).
- **MINOR**: kemampuan atau aturan baru yang kompatibel.
- **PATCH**: perbaikan bug hook/skrip dan perbaikan dokumen.

Selama versi masih `0.x`, kerangka belum teruji di proyek nyata dan perubahan MINOR dapat memuat penyesuaian.

## [0.4.0] - 2026-10-11

Satu sumber untuk aturan inti, dan contoh salah→benar. Pengukuran duplikasi (brief 0005) menunjukkan **nol** klausa persis sama dan nol ID menggantung; risiko nyatanya adalah parafrase yang melenceng, jadi yang dibangun adalah satu sumber + penjaga, bukan penghapusan ringkasan.

### Diubah
- **Aturan inti kini dibangun dari satu tabel** "Aturan Inti untuk Agent" di `docs/engineering-standard.md` (ID, judul, ringkasan, penanda Kritis, contoh Salah/Benar). `scripts/build-rules.sh` menulis daftar inti di `.claude/devcore-rules.md` dan `.claude/devcore-reminder.txt`; `--check` gagal bila basi. Daftar inti bertambah satu butir (`AG-14`, gagal berulang → berhenti) dan naik dari 15 ke 16.
- `prompt-rules-reminder.sh` tidak lagi memuat teks aturan sendiri: ia membaca `.claude/devcore-reminder.txt` (turunan).
- Bagian 3 standar (Definition of Done) menunjuk ke skill `verify-done` sebagai satu-satunya definisi kanonik; daftar tidak lagi disalin di dua tempat.
- `devcore-rules.md` memuat contoh Salah/Benar untuk 8 aturan kritis (72 baris, batas 110).

### Ditambahkan
- Contoh salah→benar di skill: `write-brief` (kriteria buruk/baik), `verify-done` (laporan menyesatkan vs jujur), `change-function` (ganti nama, field baru, hapus), `check-security` (pasangan pseudo-kode SC-01/03/05/12, VL-03), `profile-project` (baris utang teknis).
- `scripts/check-rule-refs.sh` (dipasang ke proyek): ID aturan yang dirujuk harus terdefinisi di standar; batas ukuran untuk berkas yang selalu dimuat (`devcore-rules.md` 110, `CLAUDE.md` 200, pengingat 15 baris); melaporkan ID yang tidak pernah dirujuk. Hanya memindai berkas kerangka agar ID/nomor tiket milik proyek tidak memicu galat palsu.
- `scripts/test-rules.sh` (29 kasus, khusus devcore, termasuk uji mutasi) dan 9 kasus baru `check-rule-refs` di `test-scripts.sh`. Pemeriksa tidak memindai skrip `test-*.sh` karena memuat ID palsu sebagai data uji (ditemukan oleh pemeriksa itu sendiri saat pertama dijalankan).
- Peringatan risiko kontaminasi ("mengajar untuk tes") di `docs/evaluating-agents.md`.

### Catatan
- Proyek yang sudah terpasang menerima berkas baru `.claude/devcore-reminder.txt` dan `scripts/check-rule-refs.sh` lewat `sync-devcore.sh`. Dampak pada kepatuhan agent **belum diukur** (menunggu pilot evaluasi).

## [0.3.0] - 2026-10-11

Penjaga bash ditulis ulang. **Perubahan perilaku hook** (lebih ketat di beberapa hal, lebih longgar pada teks yang bukan perintah); bacalah sebelum memperbarui proyek yang sudah terpasang.

### Diubah
- `pretool-bash-guard.sh` kini memanggil `lib/bash-analyzer.py`: tokenisasi shell (kutip, escape, operator, `$(...)`, backtick, `<(...)`, heredoc, here-string) dan keputusan dari **argv**, bukan regex atas teks mentah. Membuka pembungkus `bash -c`, `eval`, `env`, `nohup`, `time`, `timeout`, `command`, `xargs`, `find -exec`, dan heredoc/here-string/pipa `echo` yang dialirkan ke shell.
- Penulisan berkas lewat shell (`>`, `>>`, `tee`, `cp`/`mv`/`install`, `sed -i`, `perl -i`, `dd of=`, `truncate`, `touch`) memakai kebijakan yang sama dengan tool Write/Edit: gerbang brief (AG-15), berkas secret dan lockfile, berkas aturan mesin (ask), pemindaian konten untuk secret, dan persetujuan brief (ask).
- `pretool-write-guard.sh` membaca pola dari `lib/secret-patterns.txt`; nilai mirip rahasia di `tests/`, `fixtures/`, `evals/`, `*.test.*` memicu **ask** (bukan blokir); pola kuat tetap blokir di mana pun. Pola `assign` kini mencakup gaya JSON/YAML (`"api_key": "nilai"`). Penjaga tulis dan gerbang brief juga menjaga `NotebookEdit`.
- `sync-devcore.sh` memindahkan hook milik kerangka dari grup bermatcher lama saat matcher berubah, sehingga tidak terpasang dua kali.

### Ditambahkan
- Terblokir: `sudo`/`su`/`doas` dan perintah administrasi OS (OS-01); dump environment (`env`, `printenv`, `export -p`); `git stash drop|clear`, `git restore`/`checkout --` yang membuang perubahan, `git rm -r`, hapus ref remote (`:ref`, `--delete`), force push varian `+ref`; `filter-branch`, `filter-repo`, `reflog expire`, `gc --prune`; `find -delete`; `mv`/`rm` pada `.git`; SQL/migrasi destruktif (`DROP`, `TRUNCATE`, `FLUSHALL`, `DELETE` tanpa WHERE, `prisma migrate reset`, dst.); unduh-lalu-eksekusi (`curl | sh`, `bash <(curl …)`, `sh -c "$(curl …)"`, `base64 -d | sh`); one-liner/heredoc interpreter yang menghapus berkas atau membaca secret.
- Meminta konfirmasi (ask): one-liner interpreter yang menjalankan perintah lain, `eval` dengan variabel, nama perintah dinamis (`$X -rf y`), `mv` ke luar proyek, pemasangan dependency baru dan paket sistem.
- `lib/bash-guard-cases.tsv`: ±250 kasus uji (block/ask/allow) dijalankan ujung ke ujung; `test-hooks.sh` naik dari 55 ke 300+ kasus, termasuk jalur fallback dan uji mutasi.

### Diperbaiki
- False positive: kata `rm -rf`/`reset --hard` di pesan `git commit -m`, isi heredoc teks, dan pola `grep` tidak lagi memblokir.
- Celah: `bash -c 'rm -rf …'`, `sh -c`, `python3 -c "…rmtree…"`, `find -delete`, `git push origin +main`, `git push origin :main`, `echo <kunci> > file`, `mv .git …`, `echo $(cat .env)`, dan penulisan kode lewat shell yang melewati gerbang brief.

### Prasyarat baru
- `python3` 3.6+ disarankan. Tanpa itu (atau bila perintah tidak dapat diparse) hook memakai penjaga regex lama sebagai fallback: lebih kasar, memberi false positive pada teks, tetapi tidak membiarkan lolos.

### Diketahui belum selesai
- Batas yang tidak terjangkau penjaga (skrip dari berkas, variabel tak terselesaikan, fungsi/alias, Windows) tercatat di `docs/enforcement-map.md`; ini pagar pengaman, bukan sandbox.

## [0.2.0] - 2026-10-11

### Ditambahkan
- Subagent `review-changes` (peninjau independen berkonteks bersih) dan aturan `AG-19`; skill `verify-done` memanggilnya untuk tugas non-trivial dan melaporkan verdict apa adanya.
- Perangkat evaluasi kepatuhan agent (khusus devcore, tidak dipasang ke proyek lain): fixture proyek, 9 skenario jebakan dengan penilai deterministik (`evals/`), `scripts/run-evals.sh` (dry-run bawaan, batas biaya, konfigurasi terisolasi), `grade-eval.sh`, `summarize-evals.sh`, dan `test-evals.sh` (86 kasus, tanpa memanggil model; termasuk `claude` palsu dan uji mutasi). Panduan: `docs/evaluating-agents.md`.
- `check-naming.sh` memeriksa subagent dan skenario evaluasi.

### Diubah
- `check-weakened-tests.sh` tidak lagi memindai folder `evals/`.
- `run-checks.sh` menjalankan `test-evals.sh` bila ada.

### Diperbaiki
- `test-scripts.sh` (dipasang ke proyek lain) dan `test-sync.sh` membocorkan folder sementara karena pencatatan di dalam subshell; sekarang dibersihkan.

### Diketahui belum selesai
- Belum ada angka kepatuhan nyata: pilot dengan agent sungguhan menunggu login CLI `claude` (`claude auth login`). Parsing transkrip mengikuti dokumentasi resmi dan belum diuji terhadap keluaran run nyata.
- Efektivitas subagent peninjau belum diukur.

## [0.1.0] - 2026-10-11

Rilis terversi pertama. Merangkum seluruh pekerjaan awal.

### Ditambahkan
- Standar rekayasa untuk agent (`docs/engineering-standard.md`) dengan aturan ber-ID, cakupan hanya proyek, dan Bagian 18 untuk hal di luar proyek (OS/server).
- Penegakan berlapis (ADR-0001) dan peta penegakan (`docs/enforcement-map.md`).
- Hook penjaga: `pretool-bash-guard`, `pretool-write-guard`, `pretool-brief-gate`, `prompt-rules-reminder`, beserta tes.
- Skill: `write-brief`, `change-function`, `verify-done`, `check-security`.
- Gerbang brief tugas (`AG-15`): templat, mode `block|ask|off`, persetujuan `approved` meminta konfirmasi pengguna.
- Pemeriksa otomatis untuk CI: penamaan, tautan dokumen, deteksi pelemahan test.
- Konvensi penamaan (`DC-05`).
- Pemisahan izin per proyek lewat `CLAUDE.local.md`.
- Versi kerangka (`VERSION`, `CHANGELOG.md`) dan `scripts/sync-devcore.sh` untuk memasang/memperbarui kerangka di proyek lain: dry-run bawaan, wajib git bersih, tidak commit, tidak menimpa perubahan lokal, menggabungkan `.claude/settings.json`, hanya menambah baris impor ke `CLAUDE.md` (dan menangani `AGENTS.md`), mencatat `.claude/devcore.lock`. Dengan tes `scripts/test-sync.sh`.
- `.claude/devcore-rules.md` (aturan generik, diimpor `CLAUDE.md`) dan `.claude/devcore.manifest` (daftar berkas managed/seed).
- Panduan adopsi bertahap proyek lama (`docs/adopting-devcore.md`), skill `profile-project`, templat `project-profile.md`, aturan baseline `AG-16`.
- Serah terima sesi: `docs/status.md`, hook `session-status-loader` (SessionStart), aturan `AG-17`; `verify-done` ikut memperbarui status.
- `scripts/run-checks.sh` sebagai satu pintu pemeriksaan lokal dan CI; workflow diganti nama menjadi `devcore-checks.yml`.

### Diketahui belum selesai
- Hook bash masih bisa dilewati varian perintah dan memberi false positive pada teks (lihat peta penegakan).
- Belum teruji pada proyek berkode nyata.
