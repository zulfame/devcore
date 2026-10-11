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

## Stack apa pun
Kerangka tidak mengikat bahasa: hook membaca perintah shell dan berkas, bukan kode. Yang spesifik stack hanya perintah test/lint, yang dicatat skill `profile-project` ke `docs/project-profile.md`. Contoh (verifikasi di proyek Anda, jangan menyalin buta):

| Stack | Test | Lint / analisis | Tambah dependency (sudah meminta konfirmasi) |
|---|---|---|---|
| Laravel | `php artisan test` / `vendor/bin/phpunit` | `vendor/bin/pint --test`, `phpstan` | `composer require` |
| Flutter | `flutter test` | `flutter analyze` | `flutter pub add`, `dart pub add` |
| Python | `pytest` / `python -m unittest` | `ruff check`, `mypy` | `pip install` |
| Node / Next / React | `npm test` | `npm run lint` | `npm install <pkg>`, `yarn add`, `pnpm add` |
| WordPress | `phpunit` (plugin/tema) | `phpcs` | `wp plugin install` |
| Docker | tes dalam image/`docker compose config` | `hadolint` | `docker compose down -v`, `docker volume rm`, `docker system prune` meminta konfirmasi |
| HTML statis | pemeriksa tautan/validator | `htmlhint` | — |
| Grafana (dashboard JSON) | validasi skema JSON | `jq .` | — |

Perintah destruktif database framework (`migrate:fresh`, `db:wipe`, `wp db reset`) meminta konfirmasi lewat `permissions.ask`. Daftar ini bukan jaminan; perintah lain yang tidak terdaftar tidak dijaga.

## Bila ada bentrok
- **Skill/subagent senama milik proyek:** dilewati dan dilaporkan; ubah salah satu namanya bila ingin memakai versi devcore.
- **Hook sejenis di `settings.json`:** dipertahankan dan berjalan berdampingan.
- **Aturan devcore tidak cocok dengan cara kerja proyek:** lihat golongan aturan di standar Bagian 0. Aturan proses boleh disimpangi dengan catatan di bagian "Pengecualian devcore" pada `CLAUDE.md`; aturan keamanan tidak.

## Hidup berdampingan dengan alat dan skill lain
- **`AGENTS.md`**: tidak diubah. Bila `CLAUDE.md` belum ada, sync mengimpornya (`@AGENTS.md`); bila sudah ada, sync hanya memberi INFO. Tambahkan `@AGENTS.md` sendiri bila ingin keduanya dimuat.
- **`.agents/` dan skill dari skills.sh atau sumber lain**: tidak disentuh dan tidak dibaca sync. Skill pihak ketiga tidak boleh melonggarkan aturan keamanan devcore (`DC-07`); bila isinya bertentangan (mis. menyuruh auto-commit atau membaca berkas rahasia), aturan devcore menang dan agent melaporkannya. Tinjau skill pihak ketiga seperti kode: baca `SKILL.md`-nya sebelum dipakai.
- **Skill senama dengan devcore**: milik proyek tetap utuh (laporan BENTROK); ubah salah satu nama bila ingin dua-duanya.
- **`CLAUDE.md` yang sudah ada**: hanya ditambah satu baris impor; isinya tidak diubah. Aturan proses devcore boleh disimpangi lewat tabel pengecualian di `CLAUDE.md`.

## Memperbarui
```bash
.devcore/scripts/sync-devcore.sh --source https://github.com/zulfame/devcore.git --ref v0.7.0          # dry-run
.devcore/scripts/sync-devcore.sh --source https://github.com/zulfame/devcore.git --ref v0.7.0 --apply
```
Tanpa `--ref`, sumber mengikuti cabang default (versi terbaru di `main`), bukan rilis bertag; untuk pemasangan yang dapat diulang, pin ke tag. Seluruh `.devcore/` diganti; file milik proyek tidak berubah. Perubahan lokal di dalam `.devcore/` ikut tertimpa, dan terlihat di `git diff` sebelum Anda commit. Versi terpasang ada di `.devcore/VERSION`; perubahan antarversi di `CHANGELOG.md` repositori devcore.

## Serah terima sesi
Agent tidak mengingat sesi sebelumnya. Hook `session-status-loader.sh` memuat awal `docs/status.md` dan daftar brief `approved` di setiap awal sesi; agent memperbarui `docs/status.md` di akhir tugas lewat skill `verify-done` (`AG-17`). Jaga berkas itu singkat (±40 baris).

Hook Stop `stop-status-reminder.sh` mengingatkan satu kali di akhir jawaban bila kode berubah (menurut git) tetapi `docs/status.md` tidak. Ia pengingat, bukan jaminan: percobaan berhenti kedua selalu diizinkan.

## Masalah umum
| Gejala | Penyebab | Penanganan |
|---|---|---|
| Sync menolak: "bukan repo git" / "working tree tidak bersih" | folder belum `git init`, atau ada perubahan belum di-commit | `git init` lalu commit kondisi awal; atau commit/stash dulu |
| INFO: ".gitignore proyek mengabaikan berkas devcore" | `.gitignore` memuat `/.claude` atau `/CLAUDE.md` (sebagian generator proyek atau alat agent menambahkannya otomatis) | hapus barisnya; tanpa itu hook/aturan tidak ter-commit dan CI tidak melihatnya |
| `run-checks.sh` gagal di tautan dokumen milik pustaka | versi sebelum 0.6.3 memindai `vendor/` | perbarui devcore (`sync-devcore.sh --source ... --apply`) |
| `run-checks.sh` gagal "PENAMAAN" | brief/ADR di `docs/briefs/` atau `docs/adr/`, atau berkas di `.devcore/`, tidak sesuai `NNNN-judul-singkat.md`. Dokumen lama proyek tidak diperiksa (`AG-16`) | ganti nama berkas baru itu; atau catat pengecualian di tabel "Pengecualian devcore" pada `CLAUDE.md` |
| Hook tidak terasa aktif | sesi dibuka sebelum pemasangan, atau `.claude/settings.json` terabaikan git | buka ulang Claude Code di folder proyek; periksa `git check-ignore -v .claude/settings.json` |
| Perintah diblokir padahal tidak berbahaya | penjaga membaca teks (mis. skrip yang menyebut `rmtree` atau berkas rahasia di dalam string) | jalankan lewat tool Edit/Write atau ubah penulisan; jangan memecah perintah untuk mengakali (`Aturan mesin`) |
| Gerbang brief menolak perubahan kode | belum ada brief `approved` | skill `write-brief`; atau `BRIEF_GATE=ask` selama masa uji |
| Dokumen lama proyek gagal pemeriksaan CI devcore | cakupan pemeriksa tautan di proyek terpasang: `CLAUDE.md`, `docs/`, `.devcore/` | perbaiki tautan di dokumen itu atau pindahkan ke luar `docs/` |

## Melepas devcore
Urutan penting (daftar kepemilikan ada di dalam `.devcore/`, jadi baca dulu sebelum menghapusnya):
1. Catat skill dan subagent di `.devcore/owned-claude.txt`, lalu hapus berkas itu satu per satu (`.claude/skills/<nama>`, `.claude/agents/<nama>.md`).
2. Hapus entri hook yang perintahnya diawali `"$CLAUDE_PROJECT_DIR"/.devcore/` (atau bentuk lama `$CLAUDE_PROJECT_DIR/.devcore/`) dan entri `permissions` devcore dari `.claude/settings.json`.
3. Hapus baris `@.devcore/rules.md` di `CLAUDE.md`.
4. Hapus `.github/workflows/devcore-checks.yml` (ia memanggil `.devcore/scripts/run-checks.sh`, sehingga CI gagal bila `.devcore/` hilang) dan `.claude/devcore.conf`.
5. Terakhir hapus folder `.devcore/`.
Berkas milik proyek (`docs/status.md`, `docs/project-profile.md`, `docs/briefs/`) tetap milik Anda.
