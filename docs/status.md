# Status Proyek

Diperbarui: 2026-10-11 oleh agent

## Fokus saat ini
Brief 0002 (`docs/briefs/0002-adoption-sync-and-handoff.md`): adopsi proyek lama, sinkronisasi dan versi kerangka, serah terima sesi. Sedang membangun `sync-devcore.sh` dan tesnya.

## Selesai terakhir
- Prioritas 1–2: gerbang brief (AG-15) dan pemeriksa otomatis di CI (brief 0001, done).
- Penamaan file diseragamkan (DC-05) dan diperiksa otomatis.
- Izin auto commit/push dipindah ke `CLAUDE.local.md` agar tidak ikut tersalin.

## Keputusan penting
- Penegakan berlapis: lihat `docs/adr/0001-layered-enforcement.md`.
- Aturan generik dipisah ke `.claude/devcore-rules.md` dan diimpor `CLAUDE.md`, supaya `CLAUDE.md` proyek lama tidak perlu ditimpa.
- `sync-devcore.sh`: dry-run bawaan, wajib git bersih, tidak melakukan commit.

## Langkah berikutnya
1. Selesaikan `sync-devcore.sh` dan `test-sync.sh`, lalu uji instalasi nyata dari GitHub ke proyek percobaan sementara.
2. Prioritas 4–6 dari tinjauan: evaluasi agent, celah hook bash, kurangi duplikasi aturan.

## Terblokir atau pertanyaan terbuka
- Tag rilis v0.1.0 menunggu izin pengguna (di luar izin push ke main).

## Catatan jebakan
- Hook bash memindai teks perintah: kata seperti `rm -rf` di dalam perintah (mis. pesan commit) bisa memblokir. Simpan teks uji di file data.
- Berkas baru di hooks, skills, scripts, atau templates harus didaftarkan di `.claude/devcore.manifest`.
