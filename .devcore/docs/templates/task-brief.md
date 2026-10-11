# Brief: <judul singkat>

Status: draft
Tanggal: <YYYY-MM-DD>
Jenis: ringkas

<!-- Status: draft → approved (hanya setelah pengguna menyatakan setuju di chat) → done. Jenis ringkas = isi 3 bagian wajib saja; lengkap = isi semua. -->

## Tujuan (wajib)
<Satu-dua kalimat: masalah apa yang diselesaikan, untuk siapa, dan mengapa sekarang.>

## Kriteria penerimaan (wajib)
- [ ] <Kondisi yang dapat diuji. Contoh: "POST /users dengan email kosong mengembalikan 422 dan pesan 'email wajib diisi'". Hindari kata tanpa angka seperti "cepat" atau "mudah dipakai".>

## Di luar ruang lingkup (wajib)
- <Hal yang sengaja TIDAK dikerjakan di tugas ini.>

## Standar yang berlaku (wajib bila ada perubahan kode)
<ID aturan dari engineering-standard.md yang relevan dengan tugas ini, dipilih agent saat menyusun brief dan ditinjau pengguna saat menyetujui, mis. `SC-07`, `VL-02`, `API-03`, `TS-07`. Tiap ID di sini harus muncul lagi dengan hasilnya di bagian "Bagian standar yang diperiksa" sebelum brief ditutup.>

## Konteks dan batasan (lengkap)
<Kode/dokumen terkait, konvensi yang harus diikuti, kontrak yang tidak boleh berubah, batas performa/keamanan.>

## Contoh input dan output (lengkap)
<Minimal satu contoh normal dan satu contoh gagal.>

## Risiko dan asumsi (lengkap)
<Apa yang diasumsikan, apa yang bisa salah, dampak pada pemanggil lain.>

## Dokumen yang ikut berubah (lengkap)
<Daftar dokumen terdampak (README, API, ARCHITECTURE, CHANGELOG, dst.) dan perubahannya; "tidak ada" harus disebut eksplisit. DC-06.>

## Pertanyaan terbuka
<Harus kosong sebelum status approved.>

## Catatan penyelesaian
<Diisi saat selesai: bukti verifikasi per kriteria, penyimpangan dari brief, tindak lanjut.>

## Tinjauan independen
<Wajib sebelum Status: done. Tulis satu baris `Verdict: LAYAK | PERLU PERBAIKAN | TIDAK DAPAT DINILAI` dari subagent review-changes (AG-19), lalu temuan dan tindak lanjutnya. Hanya bila tugas tanpa perubahan kode: `Verdict: TIDAK DIPERLUKAN: <alasan>`.>

## Bagian standar yang diperiksa
<Wajib sebelum Status: done. Daftar ID/bagian standar yang relevan dengan perubahan beserta hasil, mis. `SC-07 sesuai`, `TS-07 test regresi ditambah`, `VL-02 selaras UI-backend`.>
