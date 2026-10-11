---
name: change-function
description: Gunakan SEBELUM menambah, mengubah, mengganti nama, atau menghapus fungsi, method, endpoint, field, skema, atau kontrak apa pun. Memastikan dampak dicari, kontrak disinkronkan di semua lapisan, dan perubahan diuji.
---

# Mengubah fungsi / kontrak

Jalankan urutan ini. Jangan lompat ke penulisan kode.

## 1. Pahami (AG-01, AG-02)
- Baca file target dan file yang memanggilnya.
- Cari penggunaan: nama fungsi/field di seluruh repositori (kode, test, dokumen, konfigurasi, UI, API, migrasi).
- Cari implementasi serupa yang sudah ada; pakai ulang atau ikuti polanya.

## 2. Klasifikasikan perubahan
| Jenis | Pertanyaan wajib |
|---|---|
| **Tambah** | Sudah ada yang setara? Kontrak input/output/error apa? Siapa pemanggilnya? |
| **Ubah** | Apakah signature, perilaku, atau error berubah? Siapa yang terdampak? Breaking change? (API-05) |
| **Hapus** | Masih dipakai di mana? Ada pemakai eksternal? Perlu masa deprecation? Hapus = konfirmasi pengguna bila publik/destruktif (AG-06) |
| **Ganti nama** | Semua referensi ikut diperbarui, termasuk string, konfigurasi, dan dokumen? |

Jika ada ketidakjelasan berisiko tinggi atau breaking change, **tanya pengguna sebelum lanjut** (AG-03).

## 3. Rencana singkat
Tulis 3–6 baris: apa yang diubah, file terdampak, cara verifikasi. Untuk perubahan >1 file atau menyentuh kontrak/keamanan, tampilkan rencana dulu.

## 4. Kerjakan minimal (AG-05)
- Ubah hanya yang perlu. Tidak ada refactor, rename massal, atau format ulang di luar tugas.
- Jika menyentuh input: kontrak validasi diperbarui di **semua** lapisan (VL-01, VL-02).
- Jika menyentuh skema: lewat file migrasi (DB-03).
- Hapus kode mati yang **Anda** timbulkan (CD-08).

## 5. Sinkronkan
- Test: tambah/ubah untuk kasus normal, negatif, batas; regression test bila memperbaiki bug (TS-07).
- Dokumentasi, contoh, OpenAPI, changelog yang terdampak.
- Semua pemanggil yang ditemukan pada langkah 1.

## 6. Verifikasi dan lapor
Jalankan skill `verify-done`. Laporkan: apa yang berubah, pemanggil yang terdampak, bukti tes, asumsi, risiko.
