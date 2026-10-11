# devcore

Standar rekayasa perangkat lunak dan aturan kerja untuk agent (Claude) — dengan penegakan otomatis agar aturan tidak hanya ditulis, tetapi dipatuhi.

## Struktur
```
devcore/
├── CLAUDE.md                          Aturan inti, dimuat otomatis tiap sesi (ringkas)
├── CLAUDE.local.md                    Izin khusus proyek ini (lokal, gitignored, TIDAK disalin)
├── README.md
├── .gitignore
├── .github/workflows/
│   └── ci.yml                         CI: tes hook & skrip, penamaan, tautan, deteksi pelemahan test
├── scripts/                           Pemeriksa otomatis (dipakai CI dan bisa dijalankan lokal)
│   ├── check-naming.sh                Penamaan sesuai DC-05
│   ├── check-links.sh                 Tautan relatif dokumen tidak rusak
│   ├── check-weakened-tests.sh        Deteksi skip/ignore/any baru pada diff (AG-09)
│   └── test-scripts.sh                Tes untuk ketiga skrip di atas
├── docs/
│   ├── engineering-standard.md        Standar lengkap (aturan ber-ID)
│   ├── enforcement-map.md             Aturan mana dijaga oleh mekanisme apa
│   ├── adr/
│   │   └── 0001-layered-enforcement.md   ADR: mengapa penegakan berlapis
│   ├── briefs/                        Brief tugas (satu per tugas non-trivial)
│   │   └── 0001-brief-gate-and-ci.md
│   └── templates/
│       └── task-brief.md              Templat brief
└── .claude/
    ├── settings.json                  Izin (deny/ask) + pendaftaran hook
    ├── devcore.conf                   Mode gerbang brief: block | ask | off
    ├── hooks/
    │   ├── pretool-bash-guard.sh      Blokir perintah destruktif / akses secret
    │   ├── pretool-write-guard.sh     Blokir secret di file, lockfile manual, ubah aturan mesin; minta konfirmasi saat brief di-approve
    │   ├── pretool-brief-gate.sh      Tolak ubah kode tanpa brief approved (AG-15)
    │   ├── prompt-rules-reminder.sh   Pengingat aturan inti tiap pesan pengguna
    │   └── test-hooks.sh              Tes untuk hook (jalankan setelah mengubah hook)
    └── skills/
        ├── write-brief/SKILL.md       Menyusun brief tugas dan meminta persetujuan
        ├── change-function/SKILL.md   Prosedur tambah/ubah/hapus fungsi & kontrak
        ├── verify-done/SKILL.md       Verifikasi & laporan sebelum "selesai"
        └── check-security/SKILL.md    Pemeriksaan keamanan perubahan
```

## Alur kerja singkat
1. Tugas non-trivial → skill `write-brief` → brief `draft` → Anda setuju → `approved` (Anda akan diminta konfirmasi oleh hook).
2. Agent mengerjakan; hook menolak perubahan kode bila tidak ada brief `approved`.
3. Selesai → skill `verify-done` memeriksa tiap kriteria → brief menjadi `done`.
4. Setiap push: CI menjalankan semua pemeriksaan. Ini lapisan yang tetap berlaku untuk commit manual.

Gerbang brief tidak berlaku untuk dokumen (`docs/`, `*.md`) dan `.claude/`. Mode diatur di `.claude/devcore.conf`: `block` (bawaan), `ask` (tanya Anda tiap perubahan, cocok untuk adopsi bertahap di proyek lama), `off`.

## Konvensi penamaan
| Jenis | Aturan | Contoh |
|---|---|---|
| Dokumen dengan peran baku | `HURUF_BESAR.md` | `README.md`, `CLAUDE.md`, `CHANGELOG.md`, `SECURITY.md`, `ARCHITECTURE.md`, `TESTING.md`, `DEPLOYMENT.md` |
| Dokumen topik lainnya | `kebab-case.md`, huruf kecil | `engineering-standard.md`, `enforcement-map.md` |
| ADR dan brief | `docs/adr/` dan `docs/briefs/` + `NNNN-judul-singkat.md` (nomor 4 digit berurutan) | `0001-layered-enforcement.md` |
| Skill | folder `kata-kerja-objek` + `SKILL.md` | `write-brief`, `change-function`, `verify-done`, `check-security` |
| Hook | `event-tujuan.sh`, sejajar dengan nama event di `settings.json` | `pretool-bash-guard.sh`, `prompt-rules-reminder.sh` |
| Skrip pemeriksa | `kata-kerja-objek.sh` huruf kecil di `scripts/` | `check-naming.sh` |
| File dengan nama tetap dari alat | ikuti alatnya | `SKILL.md`, `settings.json`, `CLAUDE.local.md` |

Bahasa: **nama file dan folder berbahasa Inggris**; isi dokumen berbahasa Indonesia. Aturan ini tercatat sebagai `DC-05` di standar dan diperiksa otomatis oleh `scripts/check-naming.sh`.

## Cara pakai
- Mulai sesi Claude Code di folder ini; `CLAUDE.md`, hook, dan skill aktif otomatis.
- Menyalin ke proyek lain: salin `CLAUDE.md`, `.claude/`, `docs/templates/`, `docs/engineering-standard.md`, `docs/enforcement-map.md`, `scripts/`, `.github/`, dan `.gitignore`. **Jangan salin `CLAUDE.local.md`** (izin khusus proyek, mis. auto commit/push) maupun `docs/briefs/` milik devcore; di proyek baru, perilaku bawaannya commit/push hanya atas permintaan.
- Izin atau preferensi khusus satu proyek ditulis di `CLAUDE.local.md` proyek itu, bukan di `CLAUDE.md`.
- Setelah mengubah hook atau skrip: `.claude/hooks/test-hooks.sh` dan `scripts/test-scripts.sh`.
- Pemeriksaan lokal sebelum push: `scripts/check-naming.sh && scripts/check-links.sh`.
