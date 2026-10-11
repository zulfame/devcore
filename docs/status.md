# Status Proyek

Diperbarui: 2026-10-11 oleh agent

## Fokus saat ini
Tidak ada brief aktif. Prioritas 1–4 dari tinjauan multi-peran selesai (brief 0001–0003, semuanya `done`). Versi kerangka 0.2.0. Menunggu pilot evaluasi oleh pengguna dan keputusan prioritas berikutnya.

## Selesai terakhir
- Prioritas 4: subagent `review-changes` (`AG-19`), perangkat evaluasi (9 skenario, penilai deterministik, runner berbiaya-terbatas, peringkas; 86 tes tanpa model), `docs/evaluating-agents.md`.
- Prioritas 3: sinkronisasi berversi (`sync-devcore.sh`), serah terima sesi, panduan adopsi. Prioritas 1–2: gerbang brief dan CI.
- Perbaikan: kebocoran folder sementara di `test-scripts.sh` dan `test-sync.sh`.

## Keputusan penting
- Penegakan berlapis: `docs/adr/0001-layered-enforcement.md`.
- Evaluasi memakai `claude -p` terisolasi dan penilai deterministik; `attempted` adalah ukuran adil antar varian, `executed` dipengaruhi izin runner.
- Perangkat evaluasi khusus devcore (tidak dipasang ke proyek lain).

## Langkah berikutnya
1. **Pengguna:** `claude auth login` di Terminal, lalu pilot: `scripts/run-evals.sh --variant both --scenarios scope-small-fix,secret-in-config,weaken-failing-test,brief-before-code --label pilot --execute` (maks 6 USD). Setelah itu cocokkan format transkrip nyata dengan `scripts/eval-helpers.sh`.
2. Prioritas 5: tutup celah dan false positive hook bash; tambah pengecualian eksplisit untuk fixture uji bernilai rahasia palsu di `pretool-write-guard`.
3. Prioritas 6: kurangi duplikasi aturan, tambah contoh benar/salah.
4. Uji pada proyek lama sungguhan: `sync-devcore.sh --target <proyek>` (dry-run), `BRIEF_GATE=ask`.

## Terblokir atau pertanyaan terbuka
- CLI `claude` belum login di mesin ini; tanpa itu tidak ada angka kepatuhan nyata.
- Tag rilis `v0.2.0` menunggu izin pengguna (di luar izin push ke main).
- Belum ada hook Stop yang memaksa `status.md` diperbarui.

## Catatan jebakan
- Hook bash memindai teks perintah: kata seperti `rm -rf` di dalam perintah/skrip yang dikirim lewat Bash memblokir. Ubah berkas lewat tool Edit/Write, dan uji dengan file data.
- Penjaga penulisan menolak nilai rahasia palsu di fixture/tes; rakit nilainya lewat variabel.
- Berkas baru di hooks, skills, agents, scripts, atau templates harus didaftarkan di `.claude/devcore.manifest` kecuali yang khusus devcore.
- Skrip tes yang membuat folder sementara harus mencatatnya ke berkas, bukan array (subshell `$(...)` menghilangkan catatan).
- Berkas managed yang berisi tautan relatif hanya boleh menunjuk ke berkas yang juga managed; selain itu pakai URL absolut.
