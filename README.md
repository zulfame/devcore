# devcore

Standar rekayasa perangkat lunak dan aturan kerja untuk agent (Claude) — dengan penegakan otomatis agar aturan tidak hanya ditulis, tetapi dipatuhi.

## Struktur
```
devcore/
├── CLAUDE.md                          Aturan inti, dimuat otomatis tiap sesi (ringkas)
├── CLAUDE.local.md                    Izin khusus proyek ini (lokal, gitignored, TIDAK disalin)
├── README.md
├── .gitignore
├── docs/
│   ├── engineering-standard.md        Standar lengkap (aturan ber-ID)
│   ├── enforcement-map.md             Aturan mana dijaga oleh mekanisme apa
│   └── adr/
│       └── 0001-layered-enforcement.md   ADR: mengapa penegakan berlapis
└── .claude/
    ├── settings.json                  Izin (deny/ask) + pendaftaran hook
    ├── hooks/
    │   ├── pretool-bash-guard.sh      Blokir perintah destruktif / akses secret
    │   ├── pretool-write-guard.sh     Blokir secret di file, lockfile manual, ubah aturan mesin
    │   ├── prompt-rules-reminder.sh   Pengingat aturan inti tiap pesan pengguna
    │   └── test-hooks.sh              Tes untuk hook (jalankan setelah mengubah hook)
    └── skills/
        ├── change-function/SKILL.md   Prosedur tambah/ubah/hapus fungsi & kontrak
        ├── verify-done/SKILL.md       Verifikasi & laporan sebelum "selesai"
        └── check-security/SKILL.md    Pemeriksaan keamanan perubahan
```

## Konvensi penamaan
| Jenis | Aturan | Contoh |
|---|---|---|
| Dokumen dengan peran baku | `HURUF_BESAR.md` | `README.md`, `CLAUDE.md`, `CHANGELOG.md`, `SECURITY.md`, `ARCHITECTURE.md`, `TESTING.md`, `DEPLOYMENT.md` |
| Dokumen topik lainnya | `kebab-case.md`, huruf kecil | `engineering-standard.md`, `enforcement-map.md` |
| ADR | `docs/adr/NNNN-judul-singkat.md` (nomor 4 digit berurutan) | `0001-layered-enforcement.md` |
| Skill | folder `kata-kerja-objek` + `SKILL.md` | `change-function`, `verify-done`, `check-security` |
| Hook | `event-tujuan.sh`, sejajar dengan nama event di `settings.json` | `pretool-bash-guard.sh`, `prompt-rules-reminder.sh` |
| File dengan nama tetap dari alat | ikuti alatnya | `SKILL.md`, `settings.json`, `CLAUDE.local.md` |

Bahasa: **nama file dan folder berbahasa Inggris**; isi dokumen berbahasa Indonesia. Aturan ini juga tercatat sebagai `DC-05` di standar.

## Cara pakai
- Mulai sesi Claude Code di folder ini; `CLAUDE.md`, hook, dan skill aktif otomatis.
- Menyalin ke proyek lain: salin `CLAUDE.md`, `.claude/`, `docs/`, dan `.gitignore`. **Jangan salin `CLAUDE.local.md`** (izin khusus proyek, mis. auto commit/push); di proyek baru, perilaku bawaannya commit/push hanya atas permintaan.
- Izin atau preferensi khusus satu proyek ditulis di `CLAUDE.local.md` proyek itu, bukan di `CLAUDE.md`.
- Setelah mengubah hook: `.claude/hooks/test-hooks.sh`.
