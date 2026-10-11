# Brief 0020: run-checks.sh menampilkan progres
Status: done

## Tujuan
Sejak 0.7.0 `run-checks.sh` menahan semua keluaran sampai satu langkah selesai, sehingga langkah panjang ("Tes hook penjaga") tampak macet. Tampilkan keluaran langsung (streaming) dan beri petunjuk bahwa langkah itu butuh waktu.

## Penyebab kedua (ditemukan saat diagnosis)
Tes hook, skrip, dan sync membuat repo git sementara dan menjalankan `git commit`. Konfigurasi git global pengguna (mis. `commit.gpgsign=true` dengan penanda tangan interaktif, hook global) dapat membuat commit itu menunggu tanpa batas atau gagal. Terbukti: dengan penanda tangan lambat, tes hook memakai 30 detik (normal 20) dan satu tes gagal.

## Kriteria penerimaan
- Ketiga skrip tes kedap terhadap konfigurasi git global dan sistem (`GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM`, tanpa prompt); terbukti lulus dengan konfigurasi global yang memakai penanda tangan lambat.
- Keluaran tiap langkah tampil bertahap, bukan sekaligus di akhir; deteksi pemeriksaan yang DILEWATI dan kode keluar tetap bekerja.
- Tes hook dan tes sync menampilkan penanda progres singkat agar jelas tidak macet.
- Perubahan tercakup tes (kode keluar gagal tetap menggagalkan `run-checks.sh`); `run-checks.sh` dan CI lulus.

## Di luar ruang lingkup
- Mempercepat tes, mengubah isi pemeriksaan.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Selesai (0.7.2). Tes kedap terhadap konfigurasi git global (terbukti dengan penanda tangan commit lambat: lulus 344, 20 detik); run-checks menampilkan keluaran langsung. Diagnosis dari laporan pengguna: 18 menit di langkah tes hook.
