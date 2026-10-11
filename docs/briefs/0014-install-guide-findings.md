# Brief 0014: Panduan pemasangan memuat temuan uji
Status: done

## Tujuan
Memperbarui README dan `adopting.md` dengan temuan uji nyata (starter kit Laravel, fixture stack, uji buta) agar pengguna repo tidak menemui masalah yang sudah diketahui: folder belum repo git, `.gitignore` yang mengabaikan berkas devcore, cara memastikan terpasang benar, hook Stop, dan masalah umum.

## Kriteria penerimaan
- README memuat: prasyarat sebelum memasang (repo git, tree bersih, cek `.gitignore`), cara memastikan terpasang benar sesudah memasang, apa yang terjadi saat hook memblokir/mengingatkan, dan batas yang diakui.
- `adopting.md` memuat bagian masalah umum (folder belum repo git, `.gitignore` mengabaikan `/.claude` atau `/CLAUDE.md` seperti Laravel Boost, `run-checks` di proyek terpasang, hook diblokir) dan catatan Stop hook di bagian serah terima.
- Label INFO di tabel README menjelaskan INFO `.gitignore`; `check-links` dan `run-checks.sh` lulus; CI hijau di PR.

## Di luar ruang lingkup
- Perubahan kode/hook, aturan baru, mengubah `.gitignore` otomatis.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Selesai (0.6.4): README dan adopting.md memuat prasyarat (repo git, cek .gitignore), cara memastikan terpasang benar, yang akan dialami pengguna, batas, dan tabel masalah umum.
