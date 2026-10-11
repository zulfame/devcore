# Brief 0017: Redaksi panduan tetap universal
Status: done

## Tujuan
Panduan pemasangan tidak boleh terkesan khusus satu stack. Hapus contoh yang menyebut satu framework di luar tabel multi-stack.

## Kriteria penerimaan
- README dan `adopting.md` tidak menyebut Laravel/`laravel new`/Laravel Boost kecuali pada baris Laravel di tabel stack `adopting.md` (daftar banyak stack).
- Maksud tidak berubah: folder belum repo git perlu `git init` + commit awal; `.gitignore` yang mengabaikan `/.claude` atau `/CLAUDE.md` perlu diperiksa.
- `run-checks.sh` lulus; CI hijau di PR.

## Di luar ruang lingkup
- Kode, aturan, tabel stack.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Selesai (0.6.7): tiga penyebutan Laravel di luar tabel stack diganti redaksi universal.
