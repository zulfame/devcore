# Peta Penegakan Aturan

Menjawab: *aturan ini dijaga oleh apa?* Aturan di markdown hanya **saran** bagi model; yang benar-benar menjamin adalah mekanisme yang dijalankan sistem, bukan ingatan model. Lihat [ADR-0001](https://github.com/zulfame/devcore/blob/main/docs/adr/0001-layered-enforcement.md).

## Tingkat penegakan
| Tingkat | Arti | Mekanisme |
|---|---|---|
| **Keras** | Mesin menolak/menahan tindakan, apa pun yang "diingat" model | Hook `PreToolUse`, `permissions.deny/ask` |
| **Terverifikasi** | Pelanggaran terdeteksi otomatis setelah ditulis | Lint, type check, test, CI, scan (butuh tooling proyek) |
| **Terpandu** | Prosedur dan pengingat memengaruhi perilaku, tidak menjamin | `CLAUDE.md`, skill, hook `UserPromptSubmit` |
| **Review manusia** | Hanya manusia yang bisa menilai | Code review, pengguna |

## Status per aturan
| Aturan | Tingkat | Mekanisme | Catatan |
|---|---|---|---|
| AG-06 tindakan destruktif | Keras | `pretool-bash-guard.sh` → `lib/bash-analyzer.py` (tokenisasi shell, keputusan dari argv), `permissions.deny` | Menembus pembungkus (`bash -c`, `eval`, `env`, `timeout`, `xargs`, `find -exec/-delete`, heredoc ke shell), `rm -r`, `.git`, git destruktif (`reset --hard`, `clean -f`, force/`+ref`/`:ref` push, `checkout --`/`checkout <berkas>`, `switch -f`, `worktree remove --force`, `restore`, `stash drop`, `branch -D`, `rm -r`, `filter-branch`, `reflog expire`, `gc --prune`). Teks di pesan commit, heredoc dokumen, dan pola grep **tidak** lagi memicu blokir. Kode one-liner/heredoc interpreter (`python -c`, `node -e`) diperiksa hanya untuk penghapusan berkas dan akses secret (pola umum; dikembalikan di 0.5.2; skrip yang sekadar menyebut kata `rmtree` di string juga ikut terblokir). Batas (sengaja tidak dijaga hook): SQL/migrasi destruktif, `mv` ke luar proyek; ditahan oleh review manusia dan CI. Ukuran analyzer dijaga `check-analyzer-size.sh` di CI (batas 960 baris berkode sejak 0.6.1). Lihat "Batas yang jujur" |
| AG-07 / SC-07 secret | Keras | `pretool-write-guard.sh` (pola di `lib/secret-patterns.txt`), analisis argv di `bash-analyzer.py`, `deny Read` | Berkas secret lewat argumen/redirect/`@file`/`source`, dump environment (`env`, `printenv`, `export`), `git show REF:.env`, penulisan secret ke berkas lewat shell **dan** tool (termasuk `NotebookEdit`). Nilai mirip rahasia di `tests/`, `fixtures/`, `evals/` memicu `ask`, bukan blokir; pola kuat (kunci AWS, private key, token) tetap blokir di mana pun. Tidak menangkap semua format secret |
| OS-01 di luar cakupan: administrasi host | Keras | `bash-analyzer.py` | `sudo`/`su`/`doas`, `systemctl`, `ufw`, `iptables`, `crontab`, `dd of=/dev/…`, dan sejenisnya diblokir (subperintah hanya-baca seperti `systemctl status`, `crontab -l`, `nginx -t` diizinkan) (pemasangan paket sistem tidak lagi dijaga hook; itu urusan lingkungan) |
| AG-09 melemahkan pemeriksaan | Keras + Terverifikasi | `pretool-write-guard.sh` (konfirmasi pengguna untuk `.claude/settings*.json`, `devcore.conf`, `skills/`, `agents/`, `.devcore/`, `CLAUDE.local.md`; jalur dinormalisasi), CI `.devcore/scripts/check-weakened-tests.sh` | CI memindai pola teks pada diff (skip/only/noqa/eslint-disable/`any` TS/continue-on-error). Pengecualian lewat `devcore-allow: <alasan>` agar terlihat saat review. Test yang dihapus hanya diberi peringatan |
| AG-15 brief tugas | Keras | `pretool-brief-gate.sh` (mode di `.claude/devcore.conf`), `pretool-write-guard.sh` (persetujuan `approved` minta konfirmasi pengguna), skill `write-brief` | Gerbang hanya memeriksa **keberadaan dan keterisian** brief, bukan kualitas kriteria. Brief `approved` yang basi membuka gerbang untuk tugas lain → ubah ke `done`. Penulisan berkas lewat shell (`>`, `>>`, `tee`, `cp`/`mv`, `sed -i`, `dd of=`, `curl -o`, `wget -O`, `patch`, `git apply`) kini melewati gerbang yang sama; yang tidak terbaca (variabel/glob pada jalur, kode interpreter yang menulis berkas) masih lolos |
| AG-12 dependency baru | Keras | `permissions.ask` (`npm install`/`yarn add`/`pnpm add`/`pip install`/`composer require`/`flutter pub add`/`dart pub add`/`wp plugin install`; perintah merusak data `docker compose down -v`, `docker volume rm`, `docker system prune`, `artisan migrate:fresh|reset`/`db:wipe`, `wp db reset` juga; hook tidak lagi memeriksa, sehingga manajer paket lain dan pembungkus `bash -c` tidak tercakup) | Meminta konfirmasi bila ada paket yang disebut; `npm install` tanpa argumen dan `pip install -r` tidak diganggu |
| AG-13 commit/push | Terpandu + prompt izin | Bawaan: hanya atas permintaan; izin berkelanjutan hanya di `CLAUDE.local.md` (gitignored, tidak disalin) | Force push/reset tetap Keras (diblokir hook) |
| DP-01 lockfile manual | Keras | `pretool-write-guard.sh` | |
| DP-06 unduh-lalu-eksekusi | Keras | `bash-analyzer.py` | `curl`/`wget` yang dialirkan ke shell atau interpreter, `bash <(curl …)`, `sh -c "$(curl …)"`, dan dekode-lalu-eksekusi (`base64 -d \| sh`) |
| DC-05 penamaan, tautan dokumen | Terverifikasi | CI `.devcore/scripts/check-naming.sh`, `.devcore/scripts/check-links.sh` | Di repo devcore: dokumen root, `docs/`, `.devcore/docs/`. Di proyek terpasang hanya yang dibuat kerangka (`docs/briefs/`, `docs/adr/`, `.devcore/`, skill/subagent milik kerangka); dokumen dan kode lama proyek tidak diperiksa (AG-16). Bahasa nama berkas tidak ditegakkan mesin |
| AG-16 proyek lama: baseline | Terpandu + Terverifikasi (diff) | `.devcore/docs/adopting.md`, skill `profile-project`, `docs/project-profile.md`; CI memeriksa **hanya diff** sehingga kondisi lama tidak menggagalkan build | Kualitas profil dan utang teknis bergantung pada agent dan tinjauan pengguna |
| AG-17 serah terima sesi | Terpandu (konteks otomatis) | Hook `session-status-loader.sh` memuat `docs/status.md` + brief approved; `verify-done` langkah 6 | Hook Stop `stop-status-reminder.sh` (sejak 0.6.0) mengingatkan **satu kali** bila kode berubah (git) tetapi `docs/status.md` tidak; percobaan berhenti kedua selalu diizinkan, jadi ini pengingat, bukan jaminan. Tidak mendeteksi perubahan yang sudah di-commit tanpa status, dan tidak menilai isi status |
| AG-18 satu jejak, versi, dan pembaruan kerangka | Terverifikasi | `.devcore/scripts/sync-devcore.sh` (mengganti seluruh `.devcore/`, kepemilikan `.claude/` dicatat di `owned-claude.txt`, laporan BENTROK), `.devcore/VERSION`, `scripts/test-sync.sh` (repo baru, repo existing penuh bentrokan, pembaruan, penolakan) | Perubahan lokal di `.devcore/` tertimpa saat pembaruan (terlihat di `git diff`); penyimpangan **semantik** terhadap proyek (mis. aturan tidak cocok) tidak terdeteksi mesin, hanya dicatat sebagai pengecualian tertulis di `CLAUDE.md` |
| Keselarasan ringkasan aturan inti ↔ standar | Review manusia | Ringkasan hanya di `.devcore/rules.md` (satu tempat); pengingat hanya judul. Tidak ada pemeriksa otomatis | Bila makna sebuah aturan berubah, ringkasan dan butir bernomor di standar harus diubah bersama. Pemeriksa otomatis (generator, pemeriksa rujukan) pernah ada dan dicabut karena mesinnya lebih besar daripada masalahnya |
| AG-19 tinjauan independen | Terpandu | Subagent `review-changes`, skill `verify-done` langkah 3a | Tidak ada mesin yang memaksa pemanggilan; agent bisa melewatkannya atau menyatakan "sudah ditinjau" tanpa memanggil. Efektivitas peninjau belum diukur |
| Efektivitas aturan perilaku (semua `AG-*` terpandu) | Tidak diukur otomatis | Diamati dari pemakaian nyata: setiap pelanggaran → perbaiki, sebut aturannya, naikkan penegakannya ke mesin, catat di peta ini | Perangkat pengukuran otomatis sengaja dicabut (0.4.1) karena menjalankan agent memakai jatah akun pengguna. Akibatnya **tidak ada angka kepatuhan**; klaim bahwa aturan atau contoh membantu agent patuh bersifat dugaan |
| CI-07 pemeriksaan di luar agent | Terverifikasi | `.github/workflows/devcore-checks.yml` → `.devcore/scripts/run-checks.sh` | Berlaku untuk semua commit; branch protection (memaksa CI lulus sebelum merge) adalah pengaturan platform, di luar cakupan proyek |
| AG-01..05, AG-08, AG-10, AG-11, AG-14 | Terpandu | `CLAUDE.md`, `prompt-rules-reminder.sh`, skill `change-function`, `verify-done` | Tidak bisa diotomatisasi sepenuhnya: perilaku dan penilaian |
| VL-*, SC-01..04, API-*, DB-* | Terpandu → Terverifikasi | Skill `check-security`; test kontrak **saat kode ada** | Menjadi Terverifikasi setelah proyek punya tes |
| CD-01, CD-03, TS-*, SC-14, DP-03 | **Belum aktif** | Perlu lint/test/CI/scan | Proyek ini belum punya kode. Aktifkan saat proyek nyata dibuat (lihat daftar tugas) |
| DC-06 dokumen dan kode paralel, audit silang | Terpandu | Aturan inti 17, `reminder.txt`, bagian "Dokumen yang ikut berubah" di template brief, `verify-done`, subagent `review-changes` | Kesesuaian dokumen–kode bersifat semantik; tidak ada pemeriksa mesin, hanya prosedur dan review. Belum teruji lewat perilaku agent |
| DC-07 hidup berdampingan dengan alat dan skill lain | Terpandu | `sync-devcore.sh` tidak menyentuh berkas milik alat lain (laporan BENTROK/INFO); `adopting.md` | Isi skill pihak ketiga tidak diperiksa mesin; aturan keamanan devcore tetap ditegakkan hook terlepas dari sumber instruksinya |
| AR-03 (hindari overengineering), CD-09 | Review manusia | — | Subjektif, tidak bisa diblokir mesin |
| Bagian 18 (OS/server) | Di luar cakupan | — | Dicatat sebagai prasyarat lingkungan |

## Batas yang jujur
- Hook adalah **pagar pengaman, bukan sandbox**. Agent yang gigih bisa menemukan varian perintah yang lolos; karena itu aturan tetap ditulis, dan perubahan pada hook butuh persetujuan.
- **Penjaga bash (sejak 0.3.0) membaca struktur perintah, bukan teks mentah,** tetapi bukan parser shell penuh. Yang **tidak** dapat dinilainya dan karena itu **lolos**:
  - isi skrip yang dijalankan dari berkas (`python3 script.py`, `./build.sh`, `make`, `npm run …`) dan program yang diam-diam memuat `.env`;
  - jalur/argumen berisi variabel atau glob yang tidak terselesaikan (`rm -rf $DIR`, `> $OUT`): perintah `rm -r` tetap diblokir, tetapi tujuan penulisan yang tak terbaca tidak diperiksa gerbang brief;
  - fungsi dan alias shell, `cd` dinamis, `source` skrip yang mendefinisikan perintah;
  - kode interpreter yang menghapus/membaca secret lewat jalur tak umum (hanya pola umum dikenali), SQL/migrasi destruktif, dan kebocoran non-berkas seperti `echo $TOKEN | curl …`;
  - Windows (PowerShell/cmd).
- **Nama perintah dinamis** (`$X -rf y`, `$(echo rm) …`, `{rm,-rf,x}`) meminta konfirmasi, tidak diblokir.
- **Diterima sebagai batas (audit final):**
  - penghapusan yang dibungkus program lain: `ssh host 'rm -rf …'`, `docker run … rm -rf`, `rsync --delete`; `git -C <dir> rebase|merge` melewati `permissions.ask` (pencocokan prefiks);
  - git lokal yang tidak diblokir: `commit --amend`, `reset` non-hard, `tag -d`, `branch -d` (hanya `-D`/paksa yang diblokir);
  - akses secret yang tidak dijaga: `/proc/*/environ`, `gh auth token`, `~/.docker/config.json`, `.git/config`; `permissions.deny` Read hanya mencakup jalur yang tertulis di `settings.json` dan belum terverifikasi apakah Grep/Glob menghormatinya;
  - gerbang brief (AG-15): satu brief `approved` membuka gerbang untuk seluruh kode (cakupan "Di luar ruang lingkup" tidak ditegakkan mesin), berkas kode di bawah `docs/` ikut dikecualikan, dan gerbang tidak membedakan ukuran perubahan (typo di kode pun butuh brief ringkas); `patch` dan `git apply` dinilai sebagai penulisan kode umum karena berkas sasarannya tidak diketahui;
  - OS-01 hanya melonggarkan subperintah hanya-baca yang terdaftar (`systemctl status`, `crontab -l`, `nginx -t`, …); selebihnya diblokir;
  - pola secret dapat digugurkan oleh kata placeholder di baris yang sama dan tidak menangkap semua format (mis. URL berisi kata sandi);
  - AG-13 (commit/push hanya atas permintaan) tidak punya penjaga mesin; hanya prompt izin bawaan.
- **Mode terdegradasi:** bila `python3` tidak ada atau perintah tidak dapat diparse, penjaga regex lama (atas teks mentah) dipakai. Ia lebih kasar dan **memberi false positive pada teks** (mis. `rm -rf` di pesan commit), tetapi tidak membiarkan lolos. `python3` 3.6+ sebaiknya tersedia.
- **Pengecualian fixture uji** bersifat `ask`, bukan lolos otomatis: kata sandi palsu di `tests/`, `fixtures/`, `evals/` tetap membutuhkan persetujuan pengguna.
- Aturan yang bersifat penilaian (ruang lingkup, kejujuran laporan, kesederhanaan) **tidak bisa** dipaksa mesin. Pengamannya: skill, laporan format tetap, dan review pengguna.
- Hook yang gagal tidak melindungi apa pun. Tes ada di `.devcore/hooks/test-hooks.sh`; jalankan setelah mengubah hook.

## Tugas penegakan yang belum dikerjakan
Dikerjakan saat proyek nyata (dengan kode) dibuat dari standar ini:
- [ ] Pre-commit / CI untuk kode proyek: formatter, linter, type check, test, secret scan, dependency scan. (Sudah aktif untuk kerangka: tes hook, tes skrip, penamaan, tautan, deteksi pelemahan test.)
- [ ] Hook `PostToolUse`: jalankan formatter/lint pada file yang baru diubah.
- [ ] Hook `Stop`: tolak "selesai" bila test terakhir gagal.
- [ ] Contract test validasi UI–backend (VL-09).
- [x] Deteksi `skip`/`ignore`/`any` baru di diff (AG-09, CD-03) — `.devcore/scripts/check-weakened-tests.sh`, dijalankan di CI.
