# Changelog

Semua perubahan penting pada kerangka devcore dicatat di sini. Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/) dan versi mengikuti [Semantic Versioning](https://semver.org/lang/id/).

Arti versi untuk kerangka ini:
- **MAJOR**: perubahan yang memaksa proyek mengubah cara kerja atau konfigurasinya (aturan dihapus/diubah artinya, struktur berkas berubah).
- **MINOR**: kemampuan atau aturan baru yang kompatibel.
- **PATCH**: perbaikan bug hook/skrip dan perbaikan dokumen.

Selama versi masih `0.x`, kerangka belum teruji di proyek nyata dan perubahan MINOR dapat memuat penyesuaian.

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
