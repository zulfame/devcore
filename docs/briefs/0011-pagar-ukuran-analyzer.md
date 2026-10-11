# Brief 0011: Pagar ukuran analyzer
Status: done

## Tujuan
Mencegah `bash-analyzer.py` tumbuh tanpa disadari: pemeriksaan otomatis gagal bila baris berkode melewati batas, sehingga penambahan harus disengaja dan dicatat.

## Kriteria penerimaan
- `run-checks.sh` punya bagian "Ukuran analyzer" yang menghitung baris non-kosong dan non-komentar `bash-analyzer.py` dan gagal bila melebihi batas (batas = ukuran sekarang + ±10%, tertulis di satu variabel dengan komentar cara menaikkannya).
- Lulus pada keadaan sekarang; gagal bila batas diturunkan (dibuktikan sekali secara manual).
- Peta penegakan dan CHANGELOG (0.6.1) mencatatnya.

## Di luar ruang lingkup
- Memangkas analyzer, mekanisme lain, perubahan perilaku hook.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Selesai (0.6.1): check-analyzer-size.sh, batas 960 baris berkode (sekarang 871), dua tes, masuk run-checks.
