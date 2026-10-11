# devcore

Standar rekayasa perangkat lunak dan aturan kerja untuk agent (Claude) — dengan penegakan otomatis agar aturan tidak hanya ditulis, tetapi dipatuhi.

## Struktur
```
devcore/
├── CLAUDE.md                      Aturan inti, dimuat otomatis tiap sesi (ringkas)
├── README.md
├── docs/
│   ├── standards/
│   │   └── production-ready-software-engineering-standard.md   Standar lengkap (ID aturan)
│   ├── enforcement-map.md         Aturan mana dijaga oleh mekanisme apa
│   └── decisions/
│       └── 0001-layered-enforcement.md   ADR: mengapa penegakan berlapis
└── .claude/
    ├── settings.json              Izin (deny/ask) + pendaftaran hook
    ├── hooks/
    │   ├── guard-bash.sh          Blokir perintah destruktif / akses secret
    │   ├── guard-write.sh         Blokir secret di file, lockfile manual, ubah aturan mesin
    │   ├── inject-rules.sh        Pengingat aturan inti tiap pesan pengguna
    │   └── test-hooks.sh          Tes untuk hook (jalankan setelah mengubah hook)
    └── skills/
        ├── change-function/       Prosedur tambah/ubah/hapus fungsi & kontrak
        ├── verify-done/           Verifikasi & laporan sebelum "selesai"
        └── security-check/        Pemeriksaan keamanan perubahan
```

## Cara pakai
- Mulai sesi Claude Code di folder ini; `CLAUDE.md`, hook, dan skill aktif otomatis.
- Menyalin ke proyek lain: salin `CLAUDE.md`, `.claude/`, dan `docs/`, lalu sesuaikan bagian "Git" di `CLAUDE.md`.
- Setelah mengubah hook: `.claude/hooks/test-hooks.sh`.
