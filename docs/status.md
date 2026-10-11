# Status Proyek

Diperbarui: 2026-10-11 oleh agent

## Fokus saat ini
Tidak ada brief aktif. Prioritas 1–3 dari tinjauan multi-peran selesai (brief 0001 dan 0002, keduanya `done`). Menunggu keputusan pengguna untuk prioritas berikutnya.

## Selesai terakhir
- Prioritas 3: versi kerangka (`VERSION` 0.1.0, `CHANGELOG.md`), `sync-devcore.sh` + `test-sync.sh` (69 kasus), panduan adopsi, skill `profile-project`, serah terima sesi (`AG-17`), `run-checks.sh`.
- Prioritas 1–2: gerbang brief (`AG-15`) dan pemeriksa otomatis di CI.
- Instalasi nyata dari GitHub ke proyek percobaan berhasil; CI hijau di `de4d8a4`.

## Keputusan penting
- Penegakan berlapis: `docs/adr/0001-layered-enforcement.md`.
- Aturan generik di `.claude/devcore-rules.md`, diimpor `CLAUDE.md`, agar `CLAUDE.md` proyek lama tidak ditimpa.
- `sync-devcore.sh`: dry-run bawaan, wajib git bersih, tidak commit, tidak menimpa perubahan lokal.

## Langkah berikutnya
1. Prioritas 4: skenario evaluasi agent (ukur tingkat pelanggaran) dan subagent reviewer.
2. Prioritas 5: tutup celah dan false positive hook bash (lihat peta penegakan).
3. Prioritas 6: kurangi duplikasi aturan (CLAUDE.md, pengingat hook, skill, standar), tambah contoh benar/salah.
4. Uji pada proyek lama sungguhan: `sync-devcore.sh --target <proyek>` (dry-run), `BRIEF_GATE=ask`.

## Terblokir atau pertanyaan terbuka
- Tag rilis `v0.1.0` menunggu izin pengguna (di luar izin push ke main).
- Belum ada hook Stop yang memaksa `status.md` diperbarui; apakah mau ditambahkan?

## Catatan jebakan
- Hook bash memindai teks perintah: kata seperti `rm -rf` di dalam perintah (mis. pesan commit) memblokir; `rm -rf` pada folder sementara juga diblokir. Pakai folder scratchpad dan file data untuk uji.
- Berkas baru di hooks, skills, scripts, atau templates harus didaftarkan di `.claude/devcore.manifest`.
- Berkas managed yang berisi tautan relatif harus hanya menunjuk ke berkas yang juga managed; selain itu pakai URL absolut.
