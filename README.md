# devcore

Kerangka kerja untuk membangun sistem bersama agent AI (Claude Code): **standar** rekayasa, **aturan kerja agent**, dan **penegakan otomatis** supaya aturan tidak hanya ditulis tetapi dipatuhi. Cakupannya proyek (kode, test, skema, konfigurasi, dokumentasi); hal yang dikelola server/OS hanya dicatat sebagai prasyarat lingkungan.

Versi: [.devcore/VERSION](.devcore/VERSION) · Perubahan: [CHANGELOG.md](CHANGELOG.md) · Latar belakang keputusan: [docs/riwayat.md](docs/riwayat.md)

## Isi
```
.devcore/                       seluruh kerangka (satu folder; diganti utuh saat pembaruan)
├── rules.md                    aturan inti + contoh salah→benar (dimuat ke setiap sesi lewat CLAUDE.md)
├── reminder.txt                pengingat singkat tiap pesan pengguna
├── docs/                       standar lengkap, peta penegakan, panduan pasang, template
├── hooks/                      penjaga: bash, tulis, gerbang brief, pengingat, serah terima sesi (+ tes)
├── scripts/                    sync-devcore.sh dan pemeriksa CI (penamaan, tautan, pelemahan test)
└── VERSION · managed-claude.txt
.claude/                        skills/ (write-brief, change-function, verify-done, check-security,
                                profile-project), agents/ (review-changes), settings.json, devcore.conf
```

## Cara kerjanya
1. Tugas non-trivial → skill `write-brief` → Anda menyetujui brief → kode baru boleh diubah (hook menolak sebelum itu).
2. Hook menahan tindakan berbahaya: perintah destruktif, akses secret, `sudo`/administrasi OS, `curl | sh`.
3. Selesai → `verify-done`: periksa tiap kriteria, tinjauan independen oleh subagent `review-changes`, tutup brief, perbarui `docs/status.md`.
4. CI (`devcore-checks.yml`) menjalankan semua pemeriksaan untuk setiap commit, termasuk commit manual.

Penjaga adalah **pagar pengaman, bukan sandbox**; batasnya dicatat jujur di [.devcore/docs/enforcement-map.md](.devcore/docs/enforcement-map.md).

## Memasang di proyek lain
Dari klon repo ini (dry-run dulu, tidak menulis apa pun):
```bash
.devcore/scripts/sync-devcore.sh --target /jalur/proyek
.devcore/scripts/sync-devcore.sh --target /jalur/proyek --apply
```
Syarat: `git`, `jq`, repo target git dengan working tree bersih; `python3` 3.6+ disarankan. Perubahan tidak di-commit otomatis. Proyek baru vs existing, laporan bentrok, dan pembaruan: [.devcore/docs/adopting.md](.devcore/docs/adopting.md).

## Bekerja di repo ini
- Pemeriksaan sebelum push: `.devcore/scripts/run-checks.sh`.
- Konvensi penamaan (`DC-05`): dokumen peran baku `HURUF_BESAR.md`, lainnya `kebab-case`; skill/subagent `kata-kerja-objek`; hook `event-tujuan.sh`; nama file berbahasa Inggris, isi Indonesia.
- Izin khusus satu proyek (mis. auto commit/push) hanya di `CLAUDE.local.md` proyek itu (tidak di-commit, tidak disalin).
- Aturan main perubahan: lihat [CLAUDE.md](CLAUDE.md).
