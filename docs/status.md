# Status Proyek

Diperbarui: 2026-10-11 oleh agent

## Fokus saat ini
Tidak ada brief aktif. Prioritas 1–6 dari tinjauan multi-peran selesai (brief 0001–0005), dan perangkat evaluasi agent dicabut atas permintaan pengguna (brief 0006). Versi kerangka 0.4.1. Kerangka lengkap dan siap dicoba di proyek lama.

## Selesai terakhir
- Brief 0006: perangkat evaluasi dicabut (`evals/`, 5 skrip, `docs/evaluating-agents.md`) karena menjalankannya memakai jatah akun dan di luar inti proyek. Tetap ada di riwayat git (commit sebelum 0.4.1).
- Prioritas 6: aturan inti satu sumber (tabel di standar → `scripts/build-rules.sh`), `check-rule-refs.sh`, DoD satu rumah di `verify-done`, contoh salah→benar.
- Prioritas 5: penjaga bash berbasis analisis struktur perintah. Prioritas 3–4: sinkronisasi berversi, serah terima sesi, subagent peninjau. Prioritas 1–2: gerbang brief, CI.

## Keputusan penting
- Penegakan berlapis: `docs/adr/0001-layered-enforcement.md`.
- **Tidak ada pengukuran kepatuhan otomatis** (sengaja): efektivitas aturan diamati dari pemakaian nyata dan alur koreksi (perbaiki → sebut aturan → naikkan penegakan ke mesin → catat di peta penegakan).
- Aturan inti: **edit tabel di `docs/engineering-standard.md`, lalu `scripts/build-rules.sh`**. Jangan edit `devcore-rules.md` (bagian inti) atau `devcore-reminder.txt` manual; CI gagal bila basi.
- Penjaga bash = pagar pengaman, bukan sandbox; batasnya di `docs/enforcement-map.md`.

## Langkah berikutnya
1. Uji pada proyek lama sungguhan: `scripts/sync-devcore.sh --target <proyek>` (dry-run dulu), lalu `BRIEF_GATE=ask` pada minggu pertama.
2. Laporkan perintah sah yang terblokir keliru agar masuk `.claude/hooks/lib/bash-guard-cases.tsv` sebagai kasus `allow`; laporkan pelanggaran agent agar penegakannya dinaikkan.

## Terblokir atau pertanyaan terbuka
- Tag rilis `v0.4.1` menunggu izin pengguna (di luar izin push ke main).
- Belum ada hook Stop yang memaksa `status.md` diperbarui.

## Catatan jebakan
- Mengubah aturan inti: tabel di standar → `scripts/build-rules.sh`. ID di tabel harus terdefinisi sebagai butir `- \`ID\`` di standar; aturan kritis wajib punya contoh Salah dan Benar.
- Penjaga bash membaca struktur perintah: teks `rm -rf` di pesan commit/heredoc/grep lolos, tetapi `rm -r` sungguhan diblokir (juga untuk folder sementara). Untuk menghapus banyak berkas atas persetujuan pengguna, hapus satu per satu (`git rm` tanpa `-r`) agar tetap dapat dipulihkan.
- Penjaga tulis menolak (secret di src) atau meminta konfirmasi (di `tests/`, `fixtures/`, `evals/`) nilai mirip rahasia; rakit nilai palsu lewat variabel di skrip uji.
- Berkas baru di hooks (termasuk `lib/`), skills, agents, scripts, atau templates harus didaftarkan di `.claude/devcore.manifest` kecuali yang khusus devcore (`devonly` di `test-sync.sh`).
- Skrip tes yang membuat folder sementara harus mencatatnya ke berkas, bukan array (subshell `$(...)` menghilangkan catatan).
- Berkas managed yang berisi tautan relatif hanya boleh menunjuk ke berkas yang juga managed; selain itu pakai URL absolut.
