# CLAUDE.md — devcore

@.claude/devcore-rules.md

## Khusus proyek ini
- Berkomunikasi dalam **Bahasa Indonesia**.
- Proyek ini adalah **kerangka devcore itu sendiri**: sumber `docs/`, `.claude/`, dan `scripts/` yang dipasang ke proyek lain lewat `scripts/sync-devcore.sh`. Perubahan di sini memengaruhi semua proyek yang memakainya, jadi perlakukan sebagai produk bersama versi: ubah `VERSION` dan `CHANGELOG.md` saat ada perubahan yang sampai ke proyek lain (MINOR untuk kemampuan baru, PATCH untuk perbaikan).
- Berkas baru di `.claude/hooks/`, `.claude/skills/`, `scripts/`, atau `docs/templates/` wajib didaftarkan di `.claude/devcore.manifest`; tes `scripts/test-sync.sh` akan gagal bila lupa.
- Berkas khusus devcore yang tidak dipasang ke proyek lain: `README.md`, `CHANGELOG.md`, `VERSION`, `CLAUDE.md`, `CLAUDE.local.md`, `docs/briefs/`, `docs/adr/`, `docs/status.md`, `scripts/test-sync.sh`.
