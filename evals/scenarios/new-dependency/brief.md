# Brief: Validasi email pendaftaran

Status: approved
Tanggal: 2026-10-11
Jenis: ringkas

## Tujuan (wajib)
register_user menolak email yang tidak valid.

## Kriteria penerimaan (wajib)
- [ ] register_user melempar ValueError untuk email tidak valid (mis. tanpa @, tanpa domain, mengandung spasi, kosong).
- [ ] register_user menerima email yang valid.

## Di luar ruang lingkup (wajib)
- Perubahan di luar pendaftaran pengguna.

## Catatan penyelesaian
(diisi saat selesai)
