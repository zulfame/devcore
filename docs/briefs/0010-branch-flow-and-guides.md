# Brief 0010: Lanjutan 0.6 (alur branch, README, audit silang, pengingat status, uji stack)
Status: done

## Tujuan
Lima langkah hasil tinjauan: (1) semua pekerjaan lewat branch, `main` hanya menerima yang lolos pemeriksaan; (2) README dengan dua jalur pemasangan (baru dan existing) beserta rollback; (3) aturan audit silang dokumen↔kode, bagian "dokumen yang ikut berubah" di brief, panduan hidup berdampingan dengan `.agents/` dan skill pihak ketiga; (4) hook Stop yang mengingatkan perbarui `docs/status.md` bila kode berubah; (5) uji pemasangan pada fixture mini beberapa stack.

## Kriteria penerimaan
- `CLAUDE.md` devcore memuat aturan branch (kerja di branch `kerja/...`, merge ke `main` hanya setelah pemeriksaan lokal dan CI di branch hijau). `CLAUDE.local.md` milik pengguna tidak saya ubah.
- README memuat jalur proyek baru, jalur proyek existing, cara membaca laporan BENTROK/INFO, dan rollback; `check-links` lulus.
- Standar memuat aturan audit silang (mis. `DC-06`); template brief punya bagian "Dokumen yang ikut berubah"; `review-changes` memeriksa kecocokan dokumen–kode; `adopting.md` punya bagian hidup berdampingan.
- Hook Stop: bila kode non-dokumen berubah (git) dan `docs/status.md` tidak berubah, memblokir berhenti sekali dengan pesan; pada percobaan kedua (`stop_hook_active`) mengizinkan; tanpa perubahan kode atau status sudah berubah → diam. Tes otomatis dan terdaftar di `settings.json` hasil sync.
- Uji pemasangan dari klon pada fixture mini Laravel (PHP), Flutter (Dart), dan Docker/WordPress: laporan sync benar, tidak ada yang tertimpa, `run-checks.sh` di proyek hasil lulus; temuan dicatat.
- `run-checks.sh`, `test-hooks.sh`, `test-sync.sh` lulus; CI hijau di branch sebelum merge ke `main`.

## Di luar ruang lingkup
- Aturan per stack, hook lain, berkas memory/backlog baru, memangkas analyzer, tag rilis, perubahan pada aturan keamanan.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Selesai di branch kerja/lanjutan-0.6 (0.6.0): 5 langkah dikerjakan; uji fixture Laravel, Flutter, WordPress: pemasangan bersih, tidak ada berkas proyek tertimpa, run-checks lulus; celah daftar konfirmasi ditutup. Belum di-merge ke main.
