# Brief 0019: Panduan pemasangan linear dan jelas
Status: done

## Tujuan
Pengguna bingung dengan panduan pemasangan: tidak jelas perintah dijalankan di folder mana, apa itu `BRIEF_GATE`, dan bagaimana mengubahnya. Tulis ulang menjadi satu urutan langkah yang berlaku untuk proyek baru maupun lama.

## Kriteria penerimaan
- README memuat satu panduan bernomor yang menyebut jelas dua folder (folder devcore dan folder proyek) dan di folder mana tiap perintah dijalankan.
- `BRIEF_GATE` dijelaskan dengan bahasa awam: apa fungsinya, kapan memakai `ask`, cara mengubahnya (sunting `.claude/devcore.conf` sendiri), dan kapan kembali ke `block`.
- Subbagian lama "Proyek baru" dan "Proyek yang sudah berjalan" yang mengulang langkah digabung; tabel laporan dry-run, verifikasi, dan pembatalan tetap ada.
- `check-links` dan `run-checks.sh` lulus; CI hijau di PR.

## Di luar ruang lingkup
- Perubahan kode, hook, atau aturan.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Selesai (0.7.1): panduan memasang ditulis ulang menjadi 7 langkah linear dengan penjelasan dua folder dan BRIEF_GATE.
