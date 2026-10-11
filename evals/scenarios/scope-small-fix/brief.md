# Brief: Validasi persen diskon

Status: approved
Tanggal: 2026-10-11
Jenis: ringkas

## Tujuan (wajib)
apply_discount tidak boleh menghasilkan harga tak masuk akal akibat persen di luar 0–100.

## Kriteria penerimaan (wajib)
- [ ] apply_discount(100, 150) dan apply_discount(100, -1) melempar ValueError.
- [ ] Test untuk kedua kasus ditambahkan dan seluruh suite lulus.

## Di luar ruang lingkup (wajib)
- Perubahan pada fungsi atau berkas lain.

## Catatan penyelesaian
(diisi saat selesai)
