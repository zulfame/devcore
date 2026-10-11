# Status Proyek

Diperbarui: 2026-10-11 oleh agent

## Fokus saat ini
Tidak ada brief aktif. Prioritas 1–5 dari tinjauan multi-peran selesai (brief 0001–0004, semuanya `done`). Versi kerangka 0.3.0. Menunggu pilot evaluasi oleh pengguna dan keputusan prioritas berikutnya.

## Selesai terakhir
- Prioritas 5: penjaga bash ditulis ulang (`lib/bash-analyzer.py`, tokenisasi shell, keputusan dari argv). Celah dan false positive dari prioritas 4 tertutup; penulisan lewat shell memakai kebijakan Write/Edit; `NotebookEdit` dijaga; pola secret jadi berkas data; fixture uji → `ask`. Tes hook 55 → 309.
- Prioritas 4: subagent `review-changes`, perangkat evaluasi (9 skenario, 86 tes tanpa model). Prioritas 3: sinkronisasi berversi, serah terima sesi, panduan adopsi. Prioritas 1–2: gerbang brief dan CI.

## Keputusan penting
- Penegakan berlapis: `docs/adr/0001-layered-enforcement.md`.
- Penjaga bash = pagar pengaman, bukan sandbox; batasnya dicatat di `docs/enforcement-map.md`. Tanpa `python3` jatuh ke regex lama (lebih kasar).
- Penjaga bash mendelegasikan penulisan berkas ke penjaga tulis dan gerbang brief (satu sumber kebijakan).
- Perangkat evaluasi khusus devcore (tidak dipasang ke proyek lain).

## Langkah berikutnya
1. **Pengguna:** `claude auth login` di Terminal, lalu pilot evaluasi: `scripts/run-evals.sh --variant both --scenarios scope-small-fix,secret-in-config,weaken-failing-test,brief-before-code --label pilot --execute` (maks 6 USD). Setelah itu cocokkan format transkrip nyata dengan `scripts/eval-helpers.sh`.
2. Prioritas 6: kurangi duplikasi aturan (CLAUDE.md, pengingat hook, skill, standar), tambah contoh benar/salah.
3. Uji pada proyek lama sungguhan: `sync-devcore.sh --target <proyek>` (dry-run), `BRIEF_GATE=ask`. Laporkan perintah sah yang terblokir keliru agar masuk `bash-guard-cases.tsv`.

## Terblokir atau pertanyaan terbuka
- CLI `claude` belum login di mesin ini; tanpa itu tidak ada angka kepatuhan nyata.
- Tag rilis `v0.3.0` menunggu izin pengguna (di luar izin push ke main).
- Belum ada hook Stop yang memaksa `status.md` diperbarui.

## Catatan jebakan
- Penjaga bash kini membaca struktur perintah: teks `rm -rf` di pesan commit/heredoc/grep **lolos**, tetapi `rm -r` sungguhan (juga lewat `bash -c`, `xargs`, `find -exec`) diblokir; `rm -rf` pada folder sementara pun diblokir (AG-06). Hindari menghapus rekursif; pakai scratchpad atau minta pengguna.
- Penjaga tulis menolak (secret di src) atau meminta konfirmasi (di `tests/`, `fixtures/`, `evals/`) nilai mirip rahasia; rakit nilai palsu lewat variabel di skrip uji.
- Berkas baru di hooks (termasuk `lib/`), skills, agents, scripts, atau templates harus didaftarkan di `.claude/devcore.manifest` kecuali yang khusus devcore.
- Skrip tes yang membuat folder sementara harus mencatatnya ke berkas, bukan array (subshell `$(...)` menghilangkan catatan).
- Berkas managed yang berisi tautan relatif hanya boleh menunjuk ke berkas yang juga managed; selain itu pakai URL absolut.
- Mengubah `matcher` di `settings.json` kerangka aman: `sync-devcore.sh` memindahkan hook ke grup yang benar.
