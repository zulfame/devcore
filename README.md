# devcore

Standar rekayasa perangkat lunak dan aturan kerja untuk agent (Claude) — dengan penegakan otomatis agar aturan tidak hanya ditulis, tetapi dipatuhi. Versi saat ini: lihat [VERSION](VERSION) dan [CHANGELOG.md](CHANGELOG.md).

## Struktur
```
devcore/
├── CLAUDE.md                          Khusus proyek devcore; mengimpor .claude/devcore-rules.md
├── CLAUDE.local.md                    Izin khusus proyek ini (lokal, gitignored, TIDAK disalin)
├── README.md · VERSION · CHANGELOG.md · .gitignore
├── .github/workflows/
│   └── devcore-checks.yml             CI: menjalankan scripts/run-checks.sh
├── scripts/
│   ├── run-checks.sh                  Satu pintu semua pemeriksaan (lokal dan CI)
│   ├── check-naming.sh                Penamaan sesuai DC-05
│   ├── check-links.sh                 Tautan relatif dokumen tidak rusak
│   ├── check-weakened-tests.sh        Deteksi skip/ignore/any baru pada diff (AG-09)
│   ├── check-rule-refs.sh             ID aturan yang dirujuk harus terdefinisi; batas ukuran berkas yang selalu dimuat
│   ├── build-rules.sh                 Bangun aturan inti + pengingat dari tabel di standar (khusus devcore)
│   ├── test-rules.sh                  Tes pembangun aturan inti (khusus devcore)
│   ├── test-scripts.sh                Tes untuk tiga pemeriksa di atas
│   ├── sync-devcore.sh                Pasang / perbarui kerangka di proyek lain
│   └── test-sync.sh                   Tes sync-devcore.sh (khusus devcore, tidak dipasang)
├── docs/
│   ├── engineering-standard.md        Standar lengkap (aturan ber-ID)
│   ├── enforcement-map.md             Aturan mana dijaga oleh mekanisme apa
│   ├── adopting-devcore.md            Panduan memasang & memperbarui di proyek yang sudah berjalan
│   ├── status.md                      Serah terima sesi (milik proyek; di sini milik devcore)
│   ├── adr/                           Keputusan arsitektur (milik proyek)
│   ├── briefs/                        Brief tugas (milik proyek)
│   └── templates/                     task-brief.md · status.md · project-profile.md
└── .claude/
    ├── devcore-rules.md               Aturan inti generik (dikelola kerangka; daftar inti DIBANGUN dari tabel di standar)
    ├── devcore-reminder.txt           Pengingat per pesan (DIBANGUN; dibaca hook pengingat)
    ├── devcore.manifest               Daftar berkas managed / seed untuk sync
    ├── devcore.conf                   Mode gerbang brief: block | ask | off
    ├── devcore.lock                   (di proyek lain) versi terpasang + hash berkas
    ├── settings.json                  Izin (deny/ask) + pendaftaran hook
    ├── agents/
    │   └── review-changes.md          Subagent peninjau independen (konteks bersih, baca-saja; AG-19)
    ├── hooks/
    │   ├── lib/
    │   │   ├── bash-analyzer.py       Penganalisis perintah shell (tokenisasi, keputusan dari argv)
    │   │   ├── secret-patterns.txt    Pola secret bersama (penjaga tulis)
    │   │   └── bash-guard-cases.tsv   Data uji penjaga bash (block/ask/allow, ±250 kasus)
    │   ├── pretool-bash-guard.sh      Blokir/konfirmasi perintah destruktif, secret, OS-admin, unduh-lalu-eksekusi (fallback regex bila tanpa python3)
    │   ├── pretool-write-guard.sh     Blokir secret di file, lockfile manual, ubah aturan mesin; konfirmasi saat brief di-approve
    │   ├── pretool-brief-gate.sh      Tolak ubah kode tanpa brief approved (AG-15)
    │   ├── prompt-rules-reminder.sh   Menyisipkan devcore-reminder.txt tiap pesan pengguna (tanpa teks aturan sendiri)
    │   ├── session-status-loader.sh   Muat docs/status.md + brief approved di awal sesi (AG-17)
    │   └── test-hooks.sh              Tes untuk hook
    └── skills/
        ├── write-brief/               Menyusun brief tugas dan meminta persetujuan
        ├── change-function/           Prosedur tambah/ubah/hapus fungsi & kontrak
        ├── verify-done/               Verifikasi, tutup brief, perbarui status
        ├── check-security/            Pemeriksaan keamanan perubahan
        └── profile-project/           Profil proyek lama: perintah, baseline, utang teknis
```

## Alur kerja singkat
1. **Awal sesi:** status sesi sebelumnya dan brief aktif dimuat otomatis.
2. Tugas non-trivial → skill `write-brief` → brief `draft` → Anda setuju → `approved` (hook meminta konfirmasi Anda).
3. Agent mengerjakan; hook menolak perubahan kode bila tidak ada brief `approved`.
4. Selesai → `verify-done`: periksa tiap kriteria, minta tinjauan independen dari subagent `review-changes` (tugas non-trivial), tutup brief (`done`), perbarui `docs/status.md`.
5. Setiap push: CI menjalankan `scripts/run-checks.sh`. Ini lapisan yang tetap berlaku untuk commit manual.

Gerbang brief tidak berlaku untuk dokumen (`docs/`, `*.md`) dan `.claude/`. Mode diatur di `.claude/devcore.conf`: `block` (bawaan), `ask` (tanya Anda tiap perubahan, cocok untuk adopsi bertahap di proyek lama), `off`.

## Memasang di proyek lain
Dari klon devcore (dry-run dulu; tidak ada yang ditulis):
```bash
scripts/sync-devcore.sh --target /jalur/proyek
scripts/sync-devcore.sh --target /jalur/proyek --apply
```
Atau dari dalam proyek yang sudah terpasang, untuk memperbarui:
```bash
scripts/sync-devcore.sh --source https://github.com/zulfame/devcore.git
```
Syarat: `git` dan `jq`, proyek berupa repo git dengan working tree bersih. `python3` (3.6+) sangat disarankan untuk penjaga bash; tanpanya hook jatuh ke penjaga regex lama yang lebih kasar (lihat `docs/enforcement-map.md`). Perubahan **tidak** di-commit otomatis. Langkah lengkap, tabel milik kerangka vs milik proyek, dan penanganan konflik: [docs/adopting-devcore.md](docs/adopting-devcore.md).

## Konvensi penamaan
| Jenis | Aturan | Contoh |
|---|---|---|
| Dokumen dengan peran baku | `HURUF_BESAR.md` | `README.md`, `CLAUDE.md`, `CHANGELOG.md`, `SECURITY.md`, `ARCHITECTURE.md`, `TESTING.md`, `DEPLOYMENT.md` |
| Dokumen topik lainnya | `kebab-case.md`, huruf kecil | `engineering-standard.md`, `adopting-devcore.md` |
| ADR dan brief | `docs/adr/` dan `docs/briefs/` + `NNNN-judul-singkat.md` (nomor 4 digit berurutan) | `0001-layered-enforcement.md` |
| Skill | folder `kata-kerja-objek` + `SKILL.md` | `write-brief`, `profile-project` |
| Subagent | `.claude/agents/kata-kerja-objek.md`, `name` sama dengan nama berkas | `review-changes.md` |
| Hook | `event-tujuan.sh`, sejajar dengan event di `settings.json` | `pretool-bash-guard.sh`, `session-status-loader.sh` |
| Skrip | `kata-kerja-objek.sh` huruf kecil di `scripts/` | `check-naming.sh`, `sync-devcore.sh` |
| File dengan nama tetap dari alat | ikuti alatnya | `SKILL.md`, `settings.json`, `CLAUDE.local.md` |

Bahasa: **nama file dan folder berbahasa Inggris**; isi dokumen berbahasa Indonesia. Tercatat sebagai `DC-05` di standar dan diperiksa oleh `scripts/check-naming.sh`.

## Bekerja di devcore sendiri
- Izin atau preferensi khusus satu proyek ditulis di `CLAUDE.local.md` proyek itu, bukan di `CLAUDE.md`.
- Berkas baru di hooks, skills, agents, scripts, atau templates **wajib** didaftarkan di `.claude/devcore.manifest`, kecuali yang khusus devcore (tes `test-sync.sh` akan gagal bila lupa).
- Perubahan yang sampai ke proyek lain → naikkan `VERSION` dan catat di `CHANGELOG.md`.
- Mengubah aturan inti: edit tabel "Aturan Inti untuk Agent" di `docs/engineering-standard.md`, lalu `scripts/build-rules.sh`. Jangan mengedit `devcore-rules.md` (bagian daftar inti) atau `devcore-reminder.txt` manual.
- Sebelum push: `scripts/run-checks.sh`.
