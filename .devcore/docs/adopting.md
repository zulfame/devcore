# Memasang devcore di Proyek Baru atau Proyek yang Sudah Berjalan

Sumber kerangka: https://github.com/zulfame/devcore

## Apa yang masuk ke proyek Anda
| Lokasi | Isi | Pemilik |
|---|---|---|
| `.devcore/` | standar, aturan inti, hook, skrip, template, `VERSION` | **kerangka** (diganti seluruhnya saat pembaruan; jangan diedit) |
| `.claude/skills/`, `.claude/agents/` | skill dan subagent devcore (wajib di sini agar dikenali Claude Code) | kerangka, hanya berkas yang tercatat di `.devcore/owned-claude.txt` |
| `.claude/settings.json` | entri hook dan izin devcore, digabung dengan milik proyek | digabung |
| `CLAUDE.md` | satu baris impor `@.devcore/rules.md` | proyek (hanya ditambah satu baris) |
| `.claude/devcore.conf`, `.github/workflows/devcore-checks.yml`, `docs/status.md`, `docs/project-profile.md` | disalin sekali bila belum ada | **proyek** sesudahnya |

Hanya itu. Folder `scripts/`, `docs/` (selain dua seed di atas), dan kode proyek tidak disentuh, sehingga tidak ada tabrakan nama dengan berkas Anda.

## Prasyarat
`git`, `jq`, Claude Code. `python3` (3.6+) disarankan untuk penjaga bash; tanpanya hook jatuh ke penjaga regex lama yang lebih kasar. Repositori harus git dengan working tree bersih.

## Proyek baru
1. Buat repo git kosong.
2. Dari klon devcore: `.devcore/scripts/sync-devcore.sh --target /jalur/proyek --apply`.
3. Isi `CLAUDE.md` (konteks, perintah, aturan khusus). Gerbang brief bawaan `block`.
4. `git diff`, jalankan `.devcore/scripts/run-checks.sh`, commit.

## Proyek yang sudah berjalan
1. Buat cabang, mis. `chore/adopsi-devcore`; `git status` harus bersih.
2. **Dry-run** (tidak menulis): `.devcore/scripts/sync-devcore.sh --target /jalur/proyek`. Baca rencana dan bagian **BENTROK/INFO** (skill senama, hook sejenis di `settings.json`, `AGENTS.md`, workflow CI lain, `CLAUDE.md` yang sudah panjang).
3. Terapkan dengan `--apply`, tinjau `git diff`.
4. Isi `BRIEF_GATE=ask` di `.claude/devcore.conf` untuk minggu pertama, lalu naikkan ke `block`.
5. Di sesi Claude Code jalankan skill `profile-project`: mencatat perintah proyek, baseline, dan utang teknis di `docs/project-profile.md` **tanpa mengubah kode** (`AG-16`: baseline, bukan refactor).
6. Tambahkan test/lint/build proyek Anda ke workflow CI Anda sendiri; `devcore-checks.yml` hanya memeriksa kerangka.
7. Commit sebagai satu commit terpisah.

## Bila ada bentrok
- **Skill/subagent senama milik proyek:** dilewati dan dilaporkan; ubah salah satu namanya bila ingin memakai versi devcore.
- **Hook sejenis di `settings.json`:** dipertahankan dan berjalan berdampingan.
- **Aturan devcore tidak cocok dengan cara kerja proyek:** lihat golongan aturan di standar Bagian 0. Aturan proses boleh disimpangi dengan catatan di bagian "Pengecualian devcore" pada `CLAUDE.md`; aturan keamanan tidak.

## Memperbarui
```bash
.devcore/scripts/sync-devcore.sh --source https://github.com/zulfame/devcore.git          # dry-run
.devcore/scripts/sync-devcore.sh --source https://github.com/zulfame/devcore.git --apply
```
Seluruh `.devcore/` diganti; file milik proyek tidak berubah. Perubahan lokal di dalam `.devcore/` ikut tertimpa, dan terlihat di `git diff` sebelum Anda commit. Versi terpasang ada di `.devcore/VERSION`; perubahan antarversi di `CHANGELOG.md` repositori devcore.

## Serah terima sesi
Agent tidak mengingat sesi sebelumnya. Hook `session-status-loader.sh` memuat awal `docs/status.md` dan daftar brief `approved` di setiap awal sesi; agent memperbarui `docs/status.md` di akhir tugas lewat skill `verify-done` (`AG-17`). Jaga berkas itu singkat (±40 baris).

## Melepas devcore
Hapus `.devcore/`, skill dan subagent yang tercatat di `.devcore/owned-claude.txt`, entri hook dengan prefix `$CLAUDE_PROJECT_DIR/.devcore/` di `.claude/settings.json`, dan baris impor di `CLAUDE.md`. Berkas milik proyek tetap milik Anda.
