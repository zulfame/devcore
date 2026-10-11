# devcore

Kerangka kerja untuk membangun sistem bersama agent AI (Claude Code): **standar** rekayasa, **aturan kerja agent**, dan **penegakan otomatis** supaya aturan tidak hanya ditulis tetapi dipatuhi. Cakupannya proyek (kode, test, skema, konfigurasi, dokumentasi); hal yang dikelola server/OS hanya dicatat sebagai prasyarat lingkungan.

Versi: [.devcore/VERSION](.devcore/VERSION) · Perubahan: [CHANGELOG.md](CHANGELOG.md) · Latar belakang keputusan: [docs/history.md](docs/history.md)

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
Syarat: `git`, `jq`, Claude Code; `python3` 3.6+ disarankan. Target harus repo git dengan working tree bersih. Skrip **tidak pernah commit** dan **tidak pernah menimpa** berkas milik proyek Anda. Mulai dengan klon devcore:
```bash
git clone https://github.com/zulfame/devcore.git && cd devcore
```

### Proyek baru
```bash
git init /jalur/proyek-baru                                        # bila belum ada
.devcore/scripts/sync-devcore.sh --target /jalur/proyek-baru --apply
```
Lalu di proyek: isi `CLAUDE.md` (konteks dan perintah test), jalankan `.devcore/scripts/run-checks.sh`, commit.

### Proyek yang sudah berjalan
1. Buat cabang: `git checkout -b chore/adopsi-devcore` (working tree harus bersih).
2. **Dry-run dulu** (tidak menulis apa pun) dan baca laporannya:
   ```bash
   .devcore/scripts/sync-devcore.sh --target /jalur/proyek
   ```
3. Bila laporan sudah wajar, terapkan: tambahkan `--apply`, lalu tinjau `git diff`.
4. Set `BRIEF_GATE=ask` di `.claude/devcore.conf` selama minggu pertama; naikkan ke `block` setelah terbiasa.
5. Di Claude Code jalankan skill `profile-project`: mencatat perintah proyek dan kondisi awal tanpa mengubah kode.
6. Commit sebagai satu commit terpisah, lalu merge cabangnya.

### Cara membaca laporan dry-run
| Label | Arti | Yang perlu Anda lakukan |
|---|---|---|
| `BARU` | berkas akan ditambah | tidak ada |
| `GANTI` | `.devcore/` (milik kerangka) akan diganti utuh | tidak ada |
| `GABUNG` | `.claude/settings.json` digabung; pengaturan dan hook Anda dipertahankan | periksa `git diff` |
| `TAMBAH` | `CLAUDE.md` hanya ditambah satu baris impor; `.gitignore` ditambah baris | tidak ada |
| `BENTROK` | skill/subagent senama milik Anda: **dilewati**, tetap utuh | ubah salah satu nama bila ingin memakai versi devcore |
| `INFO` | catatan (mis. `AGENTS.md` belum diimpor, workflow CI lain, hook proyek berdampingan) | baca, putuskan sendiri |

### Membatalkan
Sebelum commit: `git stash -u` menyimpan semua perubahan adopsi (dan bisa dibuang atau dikembalikan nanti); atau cukup tinggalkan cabang adopsi tanpa merge. Sesudah commit: `git revert` commit adopsinya. Melepas devcore sepenuhnya: lihat bagian "Melepas devcore" di [adopting.md](.devcore/docs/adopting.md).

### Bila proyek sudah punya `CLAUDE.md`, `AGENTS.md`, `.claude/`, atau skill lain
Tidak ditimpa dan tidak dihapus. Aturan, kesesuaian dengan alat lain, dan pembaruan versi: [.devcore/docs/adopting.md](.devcore/docs/adopting.md).

## Bekerja di repo ini
- Pemeriksaan sebelum push: `.devcore/scripts/run-checks.sh`.
- Konvensi penamaan (`DC-05`): dokumen peran baku `HURUF_BESAR.md`, lainnya `kebab-case`; skill/subagent `kata-kerja-objek`; hook `event-tujuan.sh`; nama file berbahasa Inggris, isi Indonesia.
- Izin khusus satu proyek (mis. auto commit/push) hanya di `CLAUDE.local.md` proyek itu (tidak di-commit, tidak disalin).
- Aturan main perubahan: lihat [CLAUDE.md](CLAUDE.md).
