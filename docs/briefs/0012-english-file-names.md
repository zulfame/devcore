# Brief 0012: Nama berkas berbahasa Inggris (DC-05)
Status: done

## Tujuan
Menyeragamkan nama berkas dan folder buatan saya yang masih berbahasa Indonesia sesuai DC-05 (nama berkas Inggris, isi Indonesia).

## Kriteria penerimaan
- `docs/riwayat.md` → `docs/history.md`; `docs/uji-buta/` → `docs/blind-test/` (`hasil`→`results`, `rubrik*`→`rubric*`, `kunci.sha256`→`hashes.sha256`); slug brief 0007–0011 berbahasa Inggris.
- Semua rujukan jalur ikut diperbarui; `run-checks.sh` dan `test-sync.sh` lulus; isi berkas rubrik tidak berubah (hash sama, `shasum -c` lulus).

## Di luar ruang lingkup
- Mengubah isi/bahasa dokumen, menambah pemeriksa bahasa nama berkas, mengganti nama berkas milik alat.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Selesai (0.6.2). Catatan: isi rubrik terkunci tidak diubah (hash cocok); rujukan nama lama di dalam rubric-round2.md sengaja dibiarkan.
