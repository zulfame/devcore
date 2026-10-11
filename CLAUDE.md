# CLAUDE.md — devcore

@.claude/devcore-rules.md

## Khusus proyek ini
- Berkomunikasi dalam **Bahasa Indonesia**.
- Proyek ini adalah **kerangka devcore itu sendiri**: sumber `docs/`, `.claude/`, dan `scripts/` yang dipasang ke proyek lain lewat `scripts/sync-devcore.sh`. Perubahan di sini memengaruhi semua proyek yang memakainya, jadi perlakukan sebagai produk bersama versi: ubah `VERSION` dan `CHANGELOG.md` saat ada perubahan yang sampai ke proyek lain (MINOR untuk kemampuan baru, PATCH untuk perbaikan).
- Berkas baru di `.claude/hooks/`, `.claude/skills/`, `.claude/agents/`, `scripts/`, atau `docs/templates/` wajib didaftarkan di `.claude/devcore.manifest`, **kecuali** yang khusus devcore; tes `scripts/test-sync.sh` akan gagal bila lupa (daftar pengecualian `devonly` ada di tes itu). Berkas turunan `.claude/devcore-reminder.txt` dan blok aturan inti dibangun oleh `scripts/build-rules.sh`, bukan ditulis tangan.
- Berkas khusus devcore yang tidak dipasang ke proyek lain: `README.md`, `CHANGELOG.md`, `VERSION`, `CLAUDE.md`, `CLAUDE.local.md`, `docs/briefs/`, `docs/adr/`, `docs/status.md`, `docs/evaluating-agents.md`, `evals/`, dan skrip `test-sync`, `test-evals`, `test-rules`, `build-rules`, `run-evals`, `grade-eval`, `summarize-evals`, `eval-helpers`.
- **Mengubah aturan inti:** edit tabel "Aturan Inti untuk Agent" di `docs/engineering-standard.md` (sumber tunggal: ringkasan, penanda Kritis, contoh Salah/Benar), lalu jalankan `scripts/build-rules.sh`. **Jangan** mengedit daftar aturan inti di `.claude/devcore-rules.md` atau `.claude/devcore-reminder.txt` secara manual; `run-checks.sh` dan CI gagal bila hasil bangun basi. Contoh baru tidak boleh disalin dari skenario evaluasi (lihat `docs/evaluating-agents.md`).
- Perubahan aturan, hook, atau skill yang memengaruhi perilaku agent sebaiknya diukur dengan `scripts/run-evals.sh` (lihat `docs/evaluating-agents.md`). Menjalankannya **berbiaya**: selalu dry-run dulu dan jangan `--execute` tanpa izin pengguna.
