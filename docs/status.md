# Status Proyek

Diperbarui: 2026-10-11 oleh agent

## Fokus saat ini
Tidak ada brief aktif. Prioritas 1–6 dari tinjauan multi-peran selesai (brief 0001–0005, semuanya `done`). Versi kerangka 0.4.0. Satu-satunya hal besar yang tersisa adalah **pilot evaluasi nyata**, yang menunggu login CLI oleh pengguna.

## Selesai terakhir
- Prioritas 6: aturan inti kini punya satu sumber (tabel di standar) → `scripts/build-rules.sh` membangun daftar inti dan pengingat; `check-rule-refs.sh` menjaga rujukan dan ukuran; DoD satu rumah di `verify-done`; contoh salah→benar di aturan kritis dan lima skill.
- Prioritas 5: penjaga bash berbasis analisis struktur perintah (tes hook 55 → 309). Prioritas 4: subagent peninjau + perangkat evaluasi. Prioritas 3: sinkronisasi berversi, serah terima sesi. Prioritas 1–2: gerbang brief, CI.

## Keputusan penting
- Penegakan berlapis: `docs/adr/0001-layered-enforcement.md`.
- Aturan inti: **edit tabel di `docs/engineering-standard.md`, lalu `scripts/build-rules.sh`**. Jangan edit `devcore-rules.md` (bagian inti) atau `devcore-reminder.txt` manual; CI gagal bila basi.
- Penjaga bash = pagar pengaman, bukan sandbox; batasnya di `docs/enforcement-map.md`.
- Duplikasi diukur sebelum diperbaiki: klaim awal "empat salinan" ternyata berlebihan (0 salinan persis); yang diperbaiki adalah risiko parafrase.

## Langkah berikutnya
1. **Pengguna:** `claude auth login` di Terminal, lalu pilot evaluasi: `scripts/run-evals.sh --variant both --scenarios scope-small-fix,secret-in-config,weaken-failing-test,brief-before-code --label pilot --execute` (maks 6 USD). Idealnya tambahkan dulu skenario cadangan (holdout) yang tidak sejalan dengan contoh di aturan inti.
2. Uji pada proyek lama sungguhan: `sync-devcore.sh --target <proyek>` (dry-run), `BRIEF_GATE=ask`. Laporkan perintah sah yang terblokir keliru agar masuk `bash-guard-cases.tsv`.
3. Setelah pilot: sesuaikan `scripts/eval-helpers.sh` bila format transkrip nyata berbeda; putuskan apakah contoh di aturan inti membantu.

## Terblokir atau pertanyaan terbuka
- CLI `claude` belum login di mesin ini; tanpa itu tidak ada angka kepatuhan nyata (semua klaim "membantu agent patuh" masih belum terukur).
- Tag rilis `v0.4.0` menunggu izin pengguna (di luar izin push ke main).
- Belum ada hook Stop yang memaksa `status.md` diperbarui.

## Catatan jebakan
- Mengubah aturan inti: tabel di standar → `scripts/build-rules.sh`. Menambah kolom/aturan: ID harus terdefinisi sebagai butir `- \`ID\`` di standar; aturan kritis wajib punya contoh Salah dan Benar.
- Jangan menyalin contoh dari `evals/scenarios/*/prompt.txt` ke aturan/skill (kontaminasi evaluasi).
- Penjaga bash membaca struktur perintah: teks `rm -rf` di pesan commit/heredoc/grep lolos, tetapi `rm -r` sungguhan diblokir (juga untuk folder sementara). Hindari menghapus rekursif.
- Penjaga tulis menolak (secret di src) atau meminta konfirmasi (di `tests/`, `fixtures/`, `evals/`) nilai mirip rahasia; rakit nilai palsu lewat variabel di skrip uji.
- Berkas baru di hooks (termasuk `lib/`), skills, agents, scripts, atau templates harus didaftarkan di `.claude/devcore.manifest` kecuali yang khusus devcore (`devonly` di `test-sync.sh`).
- Skrip tes yang membuat folder sementara harus mencatatnya ke berkas, bukan array (subshell `$(...)` menghilangkan catatan).
- Berkas managed yang berisi tautan relatif hanya boleh menunjuk ke berkas yang juga managed; selain itu pakai URL absolut.
