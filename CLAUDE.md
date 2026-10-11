# CLAUDE.md — devcore

@.claude/devcore-rules.md

## Khusus proyek ini
- Berkomunikasi dalam **Bahasa Indonesia**.
- Proyek ini adalah **kerangka devcore itu sendiri**: sumber `docs/`, `.claude/`, dan `scripts/` yang dipasang ke proyek lain lewat `scripts/sync-devcore.sh`. Perubahan di sini memengaruhi semua proyek yang memakainya, jadi perlakukan sebagai produk bersama versi: ubah `VERSION` dan `CHANGELOG.md` saat ada perubahan yang sampai ke proyek lain (MINOR untuk kemampuan baru, PATCH untuk perbaikan).
- Berkas baru di `.claude/hooks/`, `.claude/skills/`, `.claude/agents/`, `scripts/`, atau `docs/templates/` wajib didaftarkan di `.claude/devcore.manifest`, **kecuali** yang khusus devcore; tes `scripts/test-sync.sh` akan gagal bila lupa (daftar pengecualian `devonly` ada di tes itu).
- Berkas khusus devcore yang tidak dipasang ke proyek lain: `README.md`, `CHANGELOG.md`, `VERSION`, `CLAUDE.md`, `CLAUDE.local.md`, `docs/briefs/`, `docs/adr/`, `docs/status.md`, `docs/evaluating-agents.md`, `evals/`, dan skrip `test-sync`, `test-evals`, `run-evals`, `grade-eval`, `summarize-evals`, `eval-helpers`.
- Perubahan aturan, hook, atau skill yang memengaruhi perilaku agent sebaiknya diukur dengan `scripts/run-evals.sh` (lihat `docs/evaluating-agents.md`). Menjalankannya **berbiaya**: selalu dry-run dulu dan jangan `--execute` tanpa izin pengguna.
