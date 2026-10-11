# Brief 0015: Rapikan bagian prompt di README
Status: done

## Tujuan
Bagian prompt di README terlalu banyak dan membingungkan. Tampilkan yang wajib dulu dan jelaskan kapan memakai tiap prompt.

## Kriteria penerimaan
- README memuat tabel "kapan memakai" untuk 7 prompt.
- Tiga prompt utama (verifikasi pasca-pasang, uji kepatuhan, tugas harian) tampil langsung di bawah judul "Mulai di sini"; empat sisanya dilipat dalam blok `<details>` "Prompt tambahan".
- Isi prompt tidak berubah; `run-checks.sh` lulus; CI hijau di PR.

## Di luar ruang lingkup
- Mengubah isi prompt, kode, atau aturan.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Selesai (0.6.5): tabel kapan memakai, prompt 1-3 sebagai "mulai di sini", prompt 4-7 dilipat.
