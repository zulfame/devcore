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
| AG-06 tindakan destruktif | Keras | `pretool-bash-guard.sh` → `lib/bash-analyzer.py` (tokenisasi shell, keputusan dari argv), `permissions.deny` | Menembus pembungkus (`bash -c`, `eval`, `env`, `timeout`, `xargs`, `find -exec/-delete`, heredoc ke shell), `rm -r`, `.git`, git destruktif (`reset --hard`, `clean -f`, force/`+ref`/`:ref` push, `checkout --`, `restore`, `stash drop`, `branch -D`, `rm -r`, `filter-branch`, `reflog expire`, `gc --prune`), SQL/migrasi destruktif, one-liner interpreter. Teks di pesan commit, heredoc dokumen, dan pola grep **tidak** lagi memicu blokir. Batas: lihat "Batas yang jujur" |
| AG-07 / SC-07 secret | Keras | `pretool-write-guard.sh` (pola di `lib/secret-patterns.txt`), analisis argv di `bash-analyzer.py`, `deny Read` | Berkas secret lewat argumen/redirect/`@file`/`source`, dump environment (`env`, `printenv`, `export -p`), penulisan secret ke berkas lewat shell **dan** tool (termasuk `NotebookEdit`). Nilai mirip rahasia di `tests/`, `fixtures/`, `evals/` memicu `ask`, bukan blokir; pola kuat (kunci AWS, private key, token) tetap blokir di mana pun. Tidak menangkap semua format secret |
| OS-01 di luar cakupan: administrasi host | Keras | `bash-analyzer.py` | `sudo`/`su`/`doas`, `systemctl`, `ufw`, `iptables`, `crontab`, `dd of=/dev/…`, dan sejenisnya diblokir; pemasangan paket sistem (`apt`, `brew`, …) meminta konfirmasi |
| AG-09 melemahkan pemeriksaan | Keras + Terverifikasi | `pretool-write-guard.sh` (tamper `.claude/`), CI `scripts/check-weakened-tests.sh` | CI memindai pola teks pada diff (skip/only/noqa/eslint-disable/`any` TS/continue-on-error). Pengecualian lewat `devcore-allow: <alasan>` agar terlihat saat review. Test yang dihapus hanya diberi peringatan |
| AG-15 brief tugas | Keras | `pretool-brief-gate.sh` (mode di `.claude/devcore.conf`), `pretool-write-guard.sh` (persetujuan `approved` minta konfirmasi pengguna), skill `write-brief` | Gerbang hanya memeriksa **keberadaan dan keterisian** brief, bukan kualitas kriteria. Brief `approved` yang basi membuka gerbang untuk tugas lain → ubah ke `done`. Penulisan berkas lewat shell (`>`, `>>`, `tee`, `cp`/`mv`, `sed -i`, `dd of=`) kini melewati gerbang yang sama; yang tidak terbaca (variabel/glob pada jalur, kode interpreter yang menulis berkas) masih lolos |
| AG-12 dependency baru | Keras | `permissions.ask` + `bash-analyzer.py` (`npm`/`yarn`/`pnpm`/`pip`/`python -m pip`/`poetry`/`uv`/`composer`/`gem`/`cargo`/`go get`, termasuk di dalam `bash -c`/`cd x && …`) | Meminta konfirmasi bila ada paket yang disebut; `npm install` tanpa argumen dan `pip install -r` tidak diganggu |
| AG-13 commit/push | Terpandu + prompt izin | Bawaan: hanya atas permintaan; izin berkelanjutan hanya di `CLAUDE.local.md` (gitignored, tidak disalin) | Force push/reset tetap Keras (diblokir hook) |
| DP-01 lockfile manual | Keras | `pretool-write-guard.sh` | |
| DP-06 unduh-lalu-eksekusi | Keras | `bash-analyzer.py` | `curl`/`wget` yang dialirkan ke shell atau interpreter, `bash <(curl …)`, `sh -c "$(curl …)"`, dan dekode-lalu-eksekusi (`base64 -d \| sh`) |
| DC-05 penamaan, tautan dokumen | Terverifikasi | CI `scripts/check-naming.sh`, `scripts/check-links.sh` | Penamaan hanya diperiksa pada area kerangka (dokumen, `.claude/`, `scripts/`), bukan folder kode |
| AG-16 proyek lama: baseline | Terpandu + Terverifikasi (diff) | `docs/adopting-devcore.md`, skill `profile-project`, `docs/project-profile.md`; CI memeriksa **hanya diff** sehingga kondisi lama tidak menggagalkan build | Kualitas profil dan utang teknis bergantung pada agent dan tinjauan pengguna |
| AG-17 serah terima sesi | Terpandu (konteks otomatis) | Hook `session-status-loader.sh` memuat `docs/status.md` + brief approved; `verify-done` langkah 6 | Hook hanya **membaca**; tidak ada yang memaksa `status.md` diperbarui di akhir sesi (belum ada hook Stop) |
| AG-18 versi dan pembaruan kerangka | Terverifikasi | `scripts/sync-devcore.sh`, `.claude/devcore.lock`, `scripts/test-sync.sh` (termasuk uji mutasi dan normalisasi matcher hook) | Berkas managed yang diubah lokal dilewati, bukan ditolak; tidak ada pemeriksaan otomatis atas pengeditan langsung di proyek |
| AG-19 tinjauan independen | Terpandu | Subagent `review-changes`, skill `verify-done` langkah 3a | Tidak ada mesin yang memaksa pemanggilan; agent bisa melewatkannya atau menyatakan "sudah ditinjau" tanpa memanggil. Efektivitas peninjau belum diukur |
| Efektivitas aturan perilaku (semua `AG-*` terpandu) | Terukur (bila dijalankan) | `scripts/run-evals.sh` + 9 skenario; dasar penilai diuji tanpa model di `scripts/test-evals.sh` | **Belum ada angka nyata**: pilot menunggu login CLI. Hasil n kecil adalah indikasi, bukan bukti |
| CI-07 pemeriksaan di luar agent | Terverifikasi | `.github/workflows/devcore-checks.yml` → `scripts/run-checks.sh` | Berlaku untuk semua commit; branch protection (memaksa CI lulus sebelum merge) adalah pengaturan platform, di luar cakupan proyek |
| AG-01..05, AG-08, AG-10, AG-11, AG-14 | Terpandu | `CLAUDE.md`, `prompt-rules-reminder.sh`, skill `change-function`, `verify-done` | Tidak bisa diotomatisasi sepenuhnya: perilaku dan penilaian |
| VL-*, SC-01..04, API-*, DB-* | Terpandu → Terverifikasi | Skill `check-security`; test kontrak **saat kode ada** | Menjadi Terverifikasi setelah proyek punya tes |
| CD-01, CD-03, TS-*, SC-14, DP-03 | **Belum aktif** | Perlu lint/test/CI/scan | Proyek ini belum punya kode. Aktifkan saat proyek nyata dibuat (lihat daftar tugas) |
| AR-03 (hindari overengineering), CD-09 | Review manusia | — | Subjektif, tidak bisa diblokir mesin |
| Bagian 18 (OS/server) | Di luar cakupan | — | Dicatat sebagai prasyarat lingkungan |

## Batas yang jujur
- Hook adalah **pagar pengaman, bukan sandbox**. Agent yang gigih bisa menemukan varian perintah yang lolos; karena itu aturan tetap ditulis, dan perubahan pada hook butuh persetujuan.
- **Penjaga bash (sejak 0.3.0) membaca struktur perintah, bukan teks mentah,** tetapi bukan parser shell penuh. Yang **tidak** dapat dinilainya dan karena itu **lolos**:
  - isi skrip yang dijalankan dari berkas (`python3 script.py`, `./build.sh`, `make`, `npm run …`) dan program yang diam-diam memuat `.env`;
  - jalur/argumen berisi variabel atau glob yang tidak terselesaikan (`rm -rf $DIR`, `> $OUT`): perintah `rm -r` tetap diblokir, tetapi tujuan penulisan yang tak terbaca tidak diperiksa gerbang brief;
  - fungsi dan alias shell, `cd` dinamis, `source` skrip yang mendefinisikan perintah;
  - kode interpreter yang menulis atau menghapus lewat jalur tak terduga (hanya pola umum yang dikenali), dan kebocoran non-berkas seperti `echo $TOKEN | curl …`;
  - Windows (PowerShell/cmd).
- **Nama perintah dinamis** (`$X -rf y`, `$(echo rm) …`) meminta konfirmasi, tidak diblokir.
- **Mode terdegradasi:** bila `python3` tidak ada atau perintah tidak dapat diparse, penjaga regex lama (atas teks mentah) dipakai. Ia lebih kasar dan **memberi false positive pada teks** (mis. `rm -rf` di pesan commit), tetapi tidak membiarkan lolos. `python3` 3.6+ sebaiknya tersedia.
- **Pengecualian fixture uji** bersifat `ask`, bukan lolos otomatis: kata sandi palsu di `tests/`, `fixtures/`, `evals/` tetap membutuhkan persetujuan pengguna.
- Aturan yang bersifat penilaian (ruang lingkup, kejujuran laporan, kesederhanaan) **tidak bisa** dipaksa mesin. Pengamannya: skill, laporan format tetap, dan review pengguna.
- Hook yang gagal tidak melindungi apa pun. Tes ada di `.claude/hooks/test-hooks.sh`; jalankan setelah mengubah hook.

## Tugas penegakan yang belum dikerjakan
Dikerjakan saat proyek nyata (dengan kode) dibuat dari standar ini:
- [ ] Pre-commit / CI untuk kode proyek: formatter, linter, type check, test, secret scan, dependency scan. (Sudah aktif untuk kerangka: tes hook, tes skrip, penamaan, tautan, deteksi pelemahan test.)
- [ ] Hook `PostToolUse`: jalankan formatter/lint pada file yang baru diubah.
- [ ] Hook `Stop`: tolak "selesai" bila test terakhir gagal.
- [ ] Contract test validasi UI–backend (VL-09).
- [x] Deteksi `skip`/`ignore`/`any` baru di diff (AG-09, CD-03) — `scripts/check-weakened-tests.sh`, dijalankan di CI.
